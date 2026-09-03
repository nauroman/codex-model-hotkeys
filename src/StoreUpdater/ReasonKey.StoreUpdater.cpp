#define WIN32_LEAN_AND_MEAN
#define NOMINMAX

#include <windows.h>
#include <appmodel.h>
#include <shellapi.h>
#include <shobjidl_core.h>
#include <wrl/client.h>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Services.Store.h>

#include <cstdio>
#include <string>
#include <string_view>
#include <vector>

namespace
{
    constexpr int NoUpdate = 0;
    constexpr int UpdateInstalled = 10;
    constexpr int SilentUpdateUnavailable = 11;
    constexpr int NotStorePackage = 12;
    constexpr int UpdateDeferred = 13;
    constexpr int UpdateError = 20;
    constexpr int InvalidArguments = 64;

    constexpr std::wstring_view StorePackageFamilyPrefix = L"RotorlashLabs.ReasonKey_";

    std::wstring g_logPath;

    std::vector<std::wstring> CommandLineArguments()
    {
        int argumentCount = 0;
        wchar_t** arguments = CommandLineToArgvW(GetCommandLineW(), &argumentCount);
        if (!arguments)
        {
            return {};
        }

        std::vector<std::wstring> result;
        result.reserve(static_cast<size_t>(argumentCount));
        for (int index = 0; index < argumentCount; ++index)
        {
            result.emplace_back(arguments[index]);
        }
        LocalFree(arguments);
        return result;
    }

    std::wstring ArgumentValue(
        const std::vector<std::wstring>& arguments,
        std::wstring_view name)
    {
        for (size_t index = 1; index + 1 < arguments.size(); ++index)
        {
            if (arguments[index] == name)
            {
                return arguments[index + 1];
            }
        }
        return {};
    }

    bool HasArgument(
        const std::vector<std::wstring>& arguments,
        std::wstring_view name)
    {
        for (size_t index = 1; index < arguments.size(); ++index)
        {
            if (arguments[index] == name)
            {
                return true;
            }
        }
        return false;
    }

    std::string Utf8(std::wstring_view value)
    {
        if (value.empty())
        {
            return {};
        }

        const int byteCount = WideCharToMultiByte(
            CP_UTF8,
            0,
            value.data(),
            static_cast<int>(value.size()),
            nullptr,
            0,
            nullptr,
            nullptr);
        if (byteCount <= 0)
        {
            return {};
        }

        std::string result(static_cast<size_t>(byteCount), '\0');
        WideCharToMultiByte(
            CP_UTF8,
            0,
            value.data(),
            static_cast<int>(value.size()),
            result.data(),
            byteCount,
            nullptr,
            nullptr);
        return result;
    }

    void AppendLog(std::wstring_view message)
    {
        if (g_logPath.empty())
        {
            return;
        }

        SYSTEMTIME now{};
        GetLocalTime(&now);
        wchar_t prefix[64]{};
        swprintf_s(
            prefix,
            L"%04u-%02u-%02u %02u:%02u:%02u store-update ",
            now.wYear,
            now.wMonth,
            now.wDay,
            now.wHour,
            now.wMinute,
            now.wSecond);

        std::wstring line(prefix);
        line.append(message);
        line.append(L"\r\n");
        const std::string bytes = Utf8(line);

        HANDLE file = CreateFileW(
            g_logPath.c_str(),
            FILE_APPEND_DATA,
            FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
            nullptr,
            OPEN_ALWAYS,
            FILE_ATTRIBUTE_NORMAL,
            nullptr);
        if (file == INVALID_HANDLE_VALUE)
        {
            return;
        }

        DWORD written = 0;
        WriteFile(
            file,
            bytes.data(),
            static_cast<DWORD>(bytes.size()),
            &written,
            nullptr);
        CloseHandle(file);
    }

    std::wstring CurrentPackageFamilyName()
    {
        UINT32 length = 0;
        const LONG firstResult = GetCurrentPackageFamilyName(&length, nullptr);
        if (firstResult != ERROR_INSUFFICIENT_BUFFER || length == 0)
        {
            return {};
        }

        std::wstring familyName(static_cast<size_t>(length), L'\0');
        LONG result = GetCurrentPackageFamilyName(&length, familyName.data());
        if (result != ERROR_SUCCESS)
        {
            return {};
        }
        if (!familyName.empty() && familyName.back() == L'\0')
        {
            familyName.pop_back();
        }
        return familyName;
    }

    bool IsStorePackageFamily(std::wstring_view familyName)
    {
        return familyName.size() >= StorePackageFamilyPrefix.size()
            && familyName.substr(0, StorePackageFamilyPrefix.size())
                == StorePackageFamilyPrefix;
    }

    int RelaunchAfterProcess(
        const std::vector<std::wstring>& arguments)
    {
        const std::wstring processIdText = ArgumentValue(arguments, L"--parent-pid");
        const std::wstring appUserModelId = ArgumentValue(arguments, L"--aumid");
        if (processIdText.empty() || appUserModelId.empty())
        {
            return InvalidArguments;
        }

        DWORD processId = 0;
        try
        {
            const unsigned long parsed = std::stoul(processIdText);
            if (parsed == 0)
            {
                return InvalidArguments;
            }
            processId = static_cast<DWORD>(parsed);
        }
        catch (...)
        {
            return InvalidArguments;
        }

        HANDLE process = OpenProcess(SYNCHRONIZE, FALSE, processId);
        if (!process)
        {
            AppendLog(L"relaunch-error=parent-open");
            return UpdateError;
        }
        const DWORD waitResult = WaitForSingleObject(process, 120000);
        CloseHandle(process);
        if (waitResult != WAIT_OBJECT_0)
        {
            AppendLog(L"relaunch-error=parent-timeout");
            return UpdateError;
        }

        Sleep(500);
        winrt::init_apartment(winrt::apartment_type::single_threaded);
        Microsoft::WRL::ComPtr<IApplicationActivationManager> activationManager;
        const HRESULT createResult = CoCreateInstance(
            CLSID_ApplicationActivationManager,
            nullptr,
            CLSCTX_INPROC_SERVER,
            IID_PPV_ARGS(&activationManager));
        if (FAILED(createResult))
        {
            AppendLog(L"relaunch-error=activation-manager");
            return UpdateError;
        }

        DWORD launchedProcessId = 0;
        const HRESULT activationResult = activationManager->ActivateApplication(
            appUserModelId.c_str(),
            L"--store-update-restart",
            AO_NONE,
            &launchedProcessId);
        if (FAILED(activationResult))
        {
            AppendLog(L"relaunch-error=activation");
            return UpdateError;
        }

        AppendLog(L"relaunch-requested=true");
        return NoUpdate;
    }

    int CheckForStoreUpdate()
    {
        const std::wstring familyName = CurrentPackageFamilyName();
        if (!IsStorePackageFamily(familyName))
        {
            AppendLog(L"result=not-store-package package-family="
                + (familyName.empty() ? std::wstring(L"none") : familyName));
            return NotStorePackage;
        }

        AppendLog(L"check-start package-family=" + familyName);

        try
        {
            winrt::init_apartment(winrt::apartment_type::multi_threaded);
            const auto context = winrt::Windows::Services::Store::StoreContext::GetDefault();
            const auto updates = context.GetAppAndOptionalStorePackageUpdatesAsync().get();
            if (updates.Size() == 0)
            {
                AppendLog(L"result=no-update");
                return NoUpdate;
            }

            AppendLog(L"available=" + std::to_wstring(updates.Size()));
            if (!context.CanSilentlyDownloadStorePackageUpdates())
            {
                AppendLog(L"result=silent-update-not-permitted");
                return SilentUpdateUnavailable;
            }

            const auto result = context
                .TrySilentDownloadAndInstallStorePackageUpdatesAsync(updates)
                .get();
            using winrt::Windows::Services::Store::StorePackageUpdateState;
            switch (result.OverallState())
            {
                case StorePackageUpdateState::Completed:
                    AppendLog(L"result=installed");
                    return UpdateInstalled;
                case StorePackageUpdateState::Canceled:
                case StorePackageUpdateState::ErrorLowBattery:
                case StorePackageUpdateState::ErrorWiFiRecommended:
                case StorePackageUpdateState::ErrorWiFiRequired:
                    AppendLog(L"result=deferred state="
                        + std::to_wstring(static_cast<int>(result.OverallState())));
                    return UpdateDeferred;
                default:
                    AppendLog(L"result=error state="
                        + std::to_wstring(static_cast<int>(result.OverallState())));
                    return UpdateError;
            }
        }
        catch (const winrt::hresult_error& error)
        {
            wchar_t message[96]{};
            swprintf_s(
                message,
                L"result=error hresult=0x%08X",
                static_cast<unsigned int>(error.code().value));
            AppendLog(message);
            return UpdateError;
        }
        catch (...)
        {
            AppendLog(L"result=error exception=unknown");
            return UpdateError;
        }
    }
}

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int)
{
    const auto arguments = CommandLineArguments();
    g_logPath = ArgumentValue(arguments, L"--log");

    if (HasArgument(arguments, L"--self-test"))
    {
        return IsStorePackageFamily(L"RotorlashLabs.ReasonKey_1234567890abc")
            && !IsStorePackageFamily(L"RotorlashLabs.ReasonKey.Dev_1234567890abc")
            ? NoUpdate
            : UpdateError;
    }
    if (HasArgument(arguments, L"--package-probe"))
    {
        return CurrentPackageFamilyName().empty() ? NotStorePackage : NoUpdate;
    }
    if (HasArgument(arguments, L"--relaunch-after"))
    {
        return RelaunchAfterProcess(arguments);
    }
    if (HasArgument(arguments, L"--check-store-update"))
    {
        return CheckForStoreUpdate();
    }
    return InvalidArguments;
}
