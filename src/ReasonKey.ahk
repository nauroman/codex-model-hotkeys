#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_ScriptDir%\..\vendor\UIA-v2\Lib\UIA.ahk

; Ahk2Exe launches the source with /iLib to discover library dependencies.
; The explicit UIA include is already resolved by the preprocessor, so the
; runtime must exit before its persistent auto-execute section starts.
global RawCommandLine := DllCall("GetCommandLine", "Str")
if InStr(RawCommandLine, " /iLib ")
    ExitApp(0)

if HasCommandLineArgument("--validate")
{
    ultraPattern := GetEffortOptionPattern("Ultra")
    if !RegExMatch("Ultra Available on selected plans", ultraPattern)
        ExitApp(1)
    if RegExMatch("Max", ultraPattern)
        ExitApp(1)

    expectedChatEfforts := ["Instant", "Medium", "High", "Pro"]
    for index, expectedChatEffort in expectedChatEfforts
    {
        if GetDefaultChatEffortForPreset(index) != expectedChatEffort
            ExitApp(1)
        if NormalizeChatEffortName(expectedChatEffort) != expectedChatEffort
            ExitApp(1)
    }
    if NormalizeChatEffortName("Extra High") != ""
        ExitApp(1)

    for chatEffort in expectedChatEfforts
    {
        if !MatchesAnyPattern(
            chatEffort,
            GetChatEffortOptionPatterns(chatEffort)
        )
            ExitApp(1)
    }

    proPatterns := GetChatEffortOptionPatterns("Pro")
    if !RegExMatch("Pro", proPatterns[1])
        ExitApp(1)
    if RegExMatch("Extra High", proPatterns[1])
        ExitApp(1)
    if !RegExMatch("5.6 Sol", GetChatModelOptionPattern())
        ExitApp(1)
    if !RegExMatch("Model 5.6 Sol", GetChatModelRowPattern())
        ExitApp(1)
    if RegExMatch("5.6 Terra", GetChatModelOptionPattern())
        ExitApp(1)

    if GetRuntimeMutexName() != "Local\RotorlashLabs.ReasonKey.Runtime"
        ExitApp(52)

    localAppData := EnvGet("LOCALAPPDATA")
    programFiles := EnvGet("ProgramFiles")
    productRuntimeSamples := [
        localAppData "\ReasonKey\ReasonKey.exe",
        localAppData "\CodexModelHotkeys\CodexModelHotkeys.exe",
        localAppData "\Packages\OpenAI.Codex_Test\LocalCache\Local"
            . "\ReasonKey\ReasonKey.exe",
        localAppData "\Packages\OpenAI.Codex_Test\LocalCache\Local"
            . "\CodexModelHotkeys\CodexModelHotkeys.exe",
        programFiles "\WindowsApps\RotorlashLabs.ReasonKey_1.0.4.0_x64__test"
            . "\ReasonKey.exe",
        programFiles "\WindowsApps\RotorlashLabs.ReasonKey.Dev_1.0.4.0_x64__test"
            . "\ReasonKey.exe"
    ]
    for productRuntimeSample in productRuntimeSamples
    {
        if !IsReasonKeyProductRuntimePath(productRuntimeSample)
            ExitApp(53)
    }

    unrelatedRuntimeSamples := [
        localAppData "\Other\ReasonKey.exe",
        localAppData "\Packages\Other.Package_Test\LocalCache\Local"
            . "\ReasonKey\ReasonKey.exe",
        programFiles "\WindowsApps\RotorlashLabs.ReasonKey.Tools_1.0.4.0_x64__test"
            . "\ReasonKey.exe"
    ]
    for unrelatedRuntimeSample in unrelatedRuntimeSamples
    {
        if IsReasonKeyProductRuntimePath(unrelatedRuntimeSample)
            ExitApp(54)
    }
    ExitApp(0)
}

if HasCommandLineArgument("--singleton-probe")
{
    probeToken := GetCommandLineArgumentValue("--singleton-probe")
    if !RegExMatch(probeToken, "^[0-9A-Fa-f]{32}$")
        ExitApp(71)

    global RuntimeMutexHandle := 0
    probeMutexName := GetRuntimeMutexName() ".Test." probeToken
    if !AcquireRuntimeMutex(probeMutexName)
        ExitApp(73)
    Sleep(5000)
    ExitApp(0)
}

global RuntimeMutexHandle := 0
global StoppedObsoleteRuntimeCount := 0
if !HasCommandLineArgument("--validate-package")
{
    if !AcquireRuntimeMutex(GetRuntimeMutexName())
        ExitApp(0)
    StoppedObsoleteRuntimeCount := StopOtherReasonKeyRuntimes()
}

UIA.SetMaximumDPIAwareness()
Persistent true

global AppName := "ReasonKey"
global AppVersion := "1.0.4"
global PackageFamilyName := GetPackageFamilyName()
global DataDirectory := GetApplicationDataDirectory(PackageFamilyName)
global ConfigPath := A_IsCompiled
    ? DataDirectory "\presets.ini"
    : A_ScriptDir "\..\config\default-presets.ini"
global GuidePath := A_IsCompiled
    ? DataDirectory "\presets-reference.ini"
    : A_ScriptDir "\..\config\default-presets.ini"
global LogPath := DataDirectory "\ReasonKey.log"
global QuickStartMarkerPath := DataDirectory "\quick-start-complete.txt"
global LegacyQuickStartMarkerPath := DataDirectory "\store-first-run-complete.txt"

DirCreate(DataDirectory)
InitializeConfigurationFiles()

if HasCommandLineArgument("--validate-package")
    ExitApp(ValidatePackagedRuntime())

global Presets := LoadPresets(ConfigPath)

OnError(LogUnhandledError)

RegisterConfiguredHotkeys()
SetApplicationIcon()
BuildTrayMenu()
LogMessage(
    "script-start version=" AppVersion
    " pid=" DllCall("GetCurrentProcessId")
    " packaged=" (PackageFamilyName != "" ? "true" : "false")
    " stopped-obsolete=" StoppedObsoleteRuntimeCount
)

if HasCommandLineArgument("--preview-store-quick-start")
    ShowQuickStart(true, true)
else if HasCommandLineArgument("--show-quick-start")
    ShowQuickStart(true)
else if PackageFamilyName != "" && !HasCompletedQuickStart()
    ShowQuickStart(true)

GetRuntimeMutexName()
{
    return "Local\RotorlashLabs.ReasonKey.Runtime"
}

AcquireRuntimeMutex(mutexName)
{
    global RuntimeMutexHandle
    static ErrorAlreadyExists := 183

    handle := DllCall(
        "kernel32\CreateMutexW",
        "Ptr", 0,
        "Int", false,
        "Str", mutexName,
        "Ptr"
    )
    lastError := A_LastError
    if !handle
        throw Error(
            "Could not create the ReasonKey runtime mutex. Windows error "
            . lastError "."
        )
    if lastError = ErrorAlreadyExists
    {
        DllCall("kernel32\CloseHandle", "Ptr", handle)
        return false
    }

    RuntimeMutexHandle := handle
    OnExit(ReleaseRuntimeMutex)
    return true
}

ReleaseRuntimeMutex(*)
{
    global RuntimeMutexHandle
    if !RuntimeMutexHandle
        return

    DllCall("kernel32\CloseHandle", "Ptr", RuntimeMutexHandle)
    RuntimeMutexHandle := 0
}

IsReasonKeyProductRuntimePath(processPath)
{
    if processPath = ""
        return false

    candidate := StrLower(StrReplace(processPath, "/", "\"))
    localAppData := StrLower(EnvGet("LOCALAPPDATA"))
    directRuntimePaths := [
        localAppData "\reasonkey\reasonkey.exe",
        localAppData "\codexmodelhotkeys\codexmodelhotkeys.exe"
    ]
    for directRuntimePath in directRuntimePaths
    {
        if candidate = directRuntimePath
            return true
    }

    codexPackagesPrefix := localAppData "\packages\openai.codex_"
    redirectedRuntimeSuffixes := [
        "\localcache\local\reasonkey\reasonkey.exe",
        "\localcache\local\codexmodelhotkeys\codexmodelhotkeys.exe"
    ]
    if InStr(candidate, codexPackagesPrefix) = 1
    {
        for redirectedRuntimeSuffix in redirectedRuntimeSuffixes
        {
            if RegExMatch(candidate, "\Q" redirectedRuntimeSuffix "\E$")
                return true
        }
    }

    windowsAppsPrefix := StrLower(EnvGet("ProgramFiles") "\WindowsApps\")
    if InStr(candidate, windowsAppsPrefix) != 1
        return false
    packageRelativePath := SubStr(candidate, StrLen(windowsAppsPrefix) + 1)
    return RegExMatch(
        packageRelativePath,
        "^rotorlashlabs\.reasonkey(?:\.dev)?_[^\\]+\\reasonkey\.exe$"
    )
}

StopOtherReasonKeyRuntimes()
{
    if !A_IsCompiled
        return 0

    stoppedCount := 0
    currentProcessId := DllCall("GetCurrentProcessId")
    try
    {
        service := ComObjGet("winmgmts:")
        query := "SELECT ProcessId, ExecutablePath FROM Win32_Process "
            . "WHERE Name = 'ReasonKey.exe' OR Name = 'CodexModelHotkeys.exe'"
        for process in service.ExecQuery(query)
        {
            if process.ProcessId = currentProcessId
                continue
            try candidate := process.ExecutablePath
            catch
                candidate := ""
            if !IsReasonKeyProductRuntimePath(candidate)
                continue

            processId := process.ProcessId
            try terminationResult := process.Terminate()
            catch
                terminationResult := -1
            if terminationResult != 0
                continue
            stoppedCount += 1
            try ProcessWaitClose(processId, 3)
        }
    }
    return stoppedCount
}

HasCompletedQuickStart()
{
    global QuickStartMarkerPath, LegacyQuickStartMarkerPath
    return FileExist(QuickStartMarkerPath)
        || FileExist(LegacyQuickStartMarkerPath)
}

GetPackageFamilyName()
{
    static ErrorInsufficientBuffer := 122
    static AppModelErrorNoPackage := 15700

    length := 0
    try result := DllCall(
        "kernel32\GetCurrentPackageFamilyName",
        "UInt*", &length,
        "Ptr", 0,
        "UInt"
    )
    catch
        return ""

    if result = AppModelErrorNoPackage
        return ""
    if result != ErrorInsufficientBuffer || length = 0
        return ""

    packageFamilyBuffer := Buffer(length * 2, 0)
    try result := DllCall(
        "kernel32\GetCurrentPackageFamilyName",
        "UInt*", &length,
        "Ptr", packageFamilyBuffer.Ptr,
        "UInt"
    )
    catch
        return ""

    return result = 0
        ? StrGet(packageFamilyBuffer.Ptr, length, "UTF-16")
        : ""
}

GetApplicationDataDirectory(packageFamilyName)
{
    localAppData := EnvGet("LOCALAPPDATA")
    return packageFamilyName != ""
        ? localAppData "\Packages\" packageFamilyName "\LocalState\ReasonKey"
        : localAppData "\ReasonKey"
}

InitializeConfigurationFiles()
{
    global ConfigPath, GuidePath, PackageFamilyName

    if !A_IsCompiled
        return

    if !FileExist(ConfigPath)
    {
        ; Preserve configuration across both the product rename and a move
        ; from the direct installer to the Microsoft Store package.
        migrationCandidates := []
        if PackageFamilyName != ""
        {
            packageLocalState := EnvGet("LOCALAPPDATA")
                . "\Packages\" PackageFamilyName "\LocalState"
            migrationCandidates.Push(
                packageLocalState "\CodexModelHotkeys\presets.ini"
            )
            migrationCandidates.Push(
                EnvGet("LOCALAPPDATA") "\ReasonKey\presets.ini"
            )
        }
        migrationCandidates.Push(
            EnvGet("LOCALAPPDATA") "\CodexModelHotkeys\presets.ini"
        )

        for legacyConfigPath in migrationCandidates
        {
            if !FileExist(legacyConfigPath)
                continue
            try FileCopy(legacyConfigPath, ConfigPath, false)
            if FileExist(ConfigPath)
                break
        }
    }

    if !FileExist(ConfigPath)
        FileInstall("..\config\default-presets.ini", ConfigPath, false)

    ; Refresh the reference guide while preserving the active configuration.
    FileInstall("..\config\default-presets.ini", GuidePath, true)
}

ValidatePackagedRuntime()
{
    global PackageFamilyName, DataDirectory, ConfigPath, GuidePath

    if PackageFamilyName = ""
        return 21

    expectedDirectory := EnvGet("LOCALAPPDATA")
        . "\Packages\" PackageFamilyName
        . "\LocalState\ReasonKey"
    if StrLower(DataDirectory) != StrLower(expectedDirectory)
        return 22
    if !FileExist(ConfigPath)
        return 23
    if !FileExist(GuidePath)
        return 24

    validationPath := DataDirectory "\package-validation.tmp"
    try
    {
        FileAppend("ok", validationPath, "UTF-8")
        FileDelete(validationPath)
    }
    catch
    {
        return 25
    }

    return 0
}

DefaultPresets()
{
    return [
        CreatePreset("F16", "Luna High", "Luna", "High", "Instant"),
        CreatePreset("F17", "Sol Light", "Sol", "Light", "Medium"),
        CreatePreset("F18", "Sol Extra High", "Sol", "Extra High", "High"),
        CreatePreset("F19", "Sol Max", "Sol", "Max", "Pro")
    ]
}

LoadPresets(configPath)
{
    if !FileExist(configPath)
        return DefaultPresets()

    presets := []
    try presetCount := Integer(IniRead(configPath, "General", "PresetCount", "4"))
    catch
        presetCount := 4

    presetCount := Max(1, Min(presetCount, 20))
    loop presetCount
    {
        section := "Preset" A_Index
        hotkeyName := Trim(IniRead(configPath, section, "Hotkey", ""))
        modelName := NormalizeModelName(IniRead(configPath, section, "Model", ""))
        effortName := NormalizeEffortName(IniRead(configPath, section, "Effort", ""))
        defaultChatEffort := GetDefaultChatEffortForPreset(A_Index)
        chatEffortName := NormalizeChatEffortName(
            IniRead(configPath, section, "ChatEffort", defaultChatEffort)
        )
        displayName := Trim(IniRead(configPath, section, "Name", modelName " " effortName))

        if hotkeyName = "" || modelName = "" || effortName = ""
            continue

        presets.Push(CreatePreset(
            hotkeyName,
            displayName,
            modelName,
            effortName,
            chatEffortName
        ))
    }

    return presets.Length ? presets : DefaultPresets()
}

CreatePreset(hotkeyName, displayName, modelName, effortName, chatEffortName)
{
    return {
        Hotkey: hotkeyName,
        Name: displayName,
        TriggerLabel: "5.6 " modelName " " effortName,
        ChatEffort: chatEffortName
    }
}

NormalizeModelName(value)
{
    switch StrLower(Trim(value))
    {
        case "luna": return "Luna"
        case "terra": return "Terra"
        case "sol": return "Sol"
        default: return ""
    }
}

NormalizeEffortName(value)
{
    switch StrLower(Trim(value))
    {
        case "light", "low": return "Light"
        case "medium": return "Medium"
        case "high": return "High"
        case "extra high", "xhigh": return "Extra High"
        case "max": return "Max"
        case "ultra": return "Ultra"
        default: return ""
    }
}

NormalizeChatEffortName(value)
{
    switch StrLower(Trim(value))
    {
        case "instant": return "Instant"
        case "medium": return "Medium"
        case "high": return "High"
        case "pro": return "Pro"
        default: return ""
    }
}

GetDefaultChatEffortForPreset(index)
{
    switch index
    {
        case 1: return "Instant"
        case 2: return "Medium"
        case 3: return "High"
        case 4: return "Pro"
        default: return ""
    }
}

HasCommandLineArgument(expected)
{
    for argument in A_Args
    {
        if argument = expected
            return true
    }
    return false
}

GetCommandLineArgumentValue(expected)
{
    for index, argument in A_Args
    {
        if argument = expected && index < A_Args.Length
            return A_Args[index + 1]
    }
    return ""
}

RegisterConfiguredHotkeys()
{
    global Presets

    HotIf((*) => IsSupportedAppWindow())
    for index, preset in Presets
    {
        try Hotkey(preset.Hotkey, SelectPreset.Bind(index))
        catch as err
            LogMessage("invalid-hotkey=" preset.Hotkey " error=" err.Message)
    }
    HotIf()
}

SetApplicationIcon()
{
    iconPath := A_IsCompiled
        ? A_ScriptFullPath
        : A_ScriptDir "\..\assets\ReasonKey.ico"

    if FileExist(iconPath)
        TraySetIcon(iconPath)
}

BuildTrayMenu()
{
    global Presets, AppName, AppVersion, PackageFamilyName

    A_TrayMenu.Delete()
    for index, preset in Presets
        A_TrayMenu.Add(preset.Hotkey "  " preset.Name, SelectPreset.Bind(index))

    A_TrayMenu.Add()
    A_TrayMenu.Add("Quick start", OpenQuickStart)
    A_TrayMenu.Add("Open presets.ini", OpenConfiguration)
    A_TrayMenu.Add("Open configuration guide", OpenConfigurationGuide)
    if PackageFamilyName != ""
        A_TrayMenu.Add("Open Startup Apps settings", OpenStartupAppsSettings)
    A_TrayMenu.Add("Open log", OpenLog)
    A_TrayMenu.Add("Reload", ReloadApplication)
    A_TrayMenu.Add("Exit", ExitApplication)
    A_IconTip := AppName " " AppVersion
}

OpenQuickStart(*)
{
    ShowQuickStart(false)
}

ShowQuickStart(isFirstRun := false, previewStoreFeatures := false)
{
    global AppName, AppVersion, PackageFamilyName, QuickStartMarkerPath

    isStoreRuntime := PackageFamilyName != "" || previewStoreFeatures
    contentWidth := previewStoreFeatures ? 1110 : 650
    contentOptions := "w" contentWidth
    titleFont := previewStoreFeatures ? "s20 Bold" : "s14 Bold"
    sectionFont := previewStoreFeatures ? "s14 Bold" : "s10 Bold"
    bodyFont := previewStoreFeatures ? "s12 Norm" : "s9 Norm"
    sectionOptions := (previewStoreFeatures ? "y+18 " : "y+14 ") contentOptions
    bodyOptions := (previewStoreFeatures ? "y+6 " : "y+4 ") contentOptions

    guideGui := Gui("+OwnDialogs", AppName " " AppVersion)
    guideGui.MarginX := previewStoreFeatures ? 128 : 24
    guideGui.MarginY := previewStoreFeatures ? 96 : 20

    guideGui.SetFont(titleFont, "Segoe UI")
    guideGui.AddText(contentOptions, isFirstRun
        ? "ReasonKey is ready"
        : "ReasonKey quick start")

    guideGui.SetFont(bodyFont, "Segoe UI")
    guideGui.AddText(
        "y+8 " contentOptions,
        "The utility is running in the Windows notification area. "
        . "Its shortcuts are active only while a Codex or ChatGPT composer "
        . "is active."
    )

    guideGui.SetFont(sectionFont, "Segoe UI")
    guideGui.AddText(sectionOptions, "Default Codex shortcuts")
    guideGui.SetFont(bodyFont, "Segoe UI")
    guideGui.AddText(
        bodyOptions,
        "F16  -  Luna High        F17  -  Sol Light`n"
        . "F18  -  Sol Extra High   F19  -  Sol Max"
    )

    guideGui.SetFont(sectionFont, "Segoe UI")
    guideGui.AddText(sectionOptions, "ChatGPT Chat shortcuts")
    guideGui.SetFont(bodyFont, "Segoe UI")
    guideGui.AddText(
        bodyOptions,
        "The same F16-F19 keys select 5.6 Sol with Instant, Medium, High, "
        . "and Pro effort respectively. Codex and Chat use independent "
        . "effort settings."
    )

    guideGui.SetFont(sectionFont, "Segoe UI")
    guideGui.AddText(sectionOptions, "How to use it")
    guideGui.SetFont(bodyFont, "Segoe UI")
    guideGui.AddText(
        bodyOptions,
        "Activate a Codex or ChatGPT Chat composer, then press a configured "
        . "shortcut. ReasonKey selects the model and reasoning effort and "
        . "shows a small confirmation."
    )

    guideGui.SetFont(sectionFont, "Segoe UI")
    guideGui.AddText(sectionOptions, "Configuration and tray menu")
    guideGui.SetFont(bodyFont, "Segoe UI")
    guideGui.AddText(
        bodyOptions,
        "Right-click the black key icon near the Windows clock to edit "
        . "presets.ini, open the log, reload settings, or exit. If the icon "
        . "is hidden, click the ^ arrow in the notification area."
    )

    guideGui.SetFont(sectionFont, "Segoe UI")
    guideGui.AddText(sectionOptions, "Start automatically after sign-in")
    guideGui.SetFont(bodyFont, "Segoe UI")
    if isStoreRuntime
        startupDescription :=
            "The Store version leaves startup disabled until you choose it. "
            . "Open Windows Startup Apps and enable ReasonKey if "
            . "you want it to start automatically."
    else
        startupDescription :=
            "The direct installer enables per-user startup automatically. "
            . "Use Windows Startup Apps if you want to disable or enable it."
    guideGui.AddText(bodyOptions, startupDescription)

    guideGui.SetFont(bodyFont, "Segoe UI")
    startupButtonOptions := previewStoreFeatures ? "y+20 w220 h38" : "y+16 w180 h30"
    presetsButtonOptions := previewStoreFeatures ? "x+12 w190 h38" : "x+10 w150 h30"
    finishButtonOptions := previewStoreFeatures
        ? "x+12 w130 h38 Default"
        : "x+10 w110 h30 Default"
    startupButton := guideGui.AddButton(startupButtonOptions, "Open Startup Apps")
    presetsButton := guideGui.AddButton(presetsButtonOptions, "Open presets.ini")
    finishButton := guideGui.AddButton(finishButtonOptions, "Finish")
    startupButton.OnEvent("Click", OpenStartupAppsSettings)
    presetsButton.OnEvent("Click", OpenConfiguration)
    finishButton.OnEvent("Click", (*) => guideGui.Destroy())
    guideGui.OnEvent("Close", (*) => guideGui.Destroy())

    guideGui.Show(previewStoreFeatures ? "w1366 h768 Center" : "AutoSize Center")
    WinWaitClose("ahk_id " guideGui.Hwnd)

    if isFirstRun && !previewStoreFeatures && !FileExist(QuickStartMarkerPath)
        FileAppend(
            "completed=" FormatTime(, "yyyy-MM-dd HH:mm:ss"),
            QuickStartMarkerPath,
            "UTF-8"
        )
}

OpenStartupAppsSettings(*)
{
    Run("ms-settings:startupapps")
}

OpenConfiguration(*)
{
    global ConfigPath
    Run('notepad.exe "' ConfigPath '"')
}

OpenConfigurationGuide(*)
{
    global GuidePath
    Run('notepad.exe "' GuidePath '"')
}

OpenLog(*)
{
    global LogPath
    if !FileExist(LogPath)
        FileAppend("", LogPath, "UTF-8")
    Run('notepad.exe "' LogPath '"')
}

ReloadApplication(*)
{
    Reload()
}

ExitApplication(*)
{
    ExitApp(0)
}

LogMessage(message)
{
    global LogPath
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " " message "`n", LogPath, "UTF-8")
}

ShowStatus(message, duration := 1800)
{
    ToolTip(message)
    SetTimer(HidePresetToolTip, -duration)
}

LogUnhandledError(err, mode)
{
    LogMessage("unhandled-error mode=" mode " message=" err.Message)
    ShowStatus("ReasonKey error: " err.Message, 5000)
    return true
}

IsSupportedAppWindow()
{
    try
    {
        processPath := WinGetProcessPath("A")
        return InStr(processPath, "\WindowsApps\OpenAI.Codex_") > 0
            && StrLower(WinGetProcessName("A")) = "chatgpt.exe"
    }
    catch
    {
        return false
    }
}

SelectPreset(index, *)
{
    global Presets, LogPath
    static switching := false

    if switching || index < 1 || index > Presets.Length
        return

    preset := Presets[index]
    LogMessage("hotkey=" preset.TriggerLabel)

    if !IsSupportedAppWindow()
    {
        ShowStatus("ReasonKey: Codex/ChatGPT window is not active", 2500)
        LogMessage("ignored-not-codex=" preset.TriggerLabel)
        return
    }

    switching := true
    ShowStatus("ReasonKey: selecting preset...", 5000)
    LogMessage("requested=" preset.TriggerLabel)

    try
    {
        selectedLabel := SelectCombinedPreset(
            preset.TriggerLabel,
            preset.ChatEffort
        )
        if !selectedLabel
        {
            ShowStatus("ReasonKey: could not apply preset (see " LogPath ")", 3500)
            LogMessage("failed=" preset.TriggerLabel)
            return
        }

        ShowStatus("ReasonKey: " selectedLabel)
        LogMessage("selected=" selectedLabel)
    }
    catch as err
    {
        try Send("{Escape}")
        ShowStatus("ReasonKey error: " err.Message, 4000)
        LogMessage("error=" err.Message)
    }
    finally
    {
        switching := false
    }
}

SelectCombinedPreset(targetLabel, targetChatEffort)
{
    if !RegExMatch(targetLabel, "^5\.6 (Luna|Terra|Sol) (.+)$", &targetMatch)
    {
        LogMessage("invalid target label=" targetLabel)
        return false
    }

    targetModel := targetMatch[1]
    targetEffort := targetMatch[2]
    windowHandle := WinExist("A")
    windowElement := UIA.ElementFromHandle(windowHandle)

    ; Open the picker through Codex's own accessible trigger. This does not
    ; depend on the user's current keyboard-shortcut assignment.
    modelPickerTrigger := FindCodexPickerTrigger(windowElement)
    pickerKind := "codex"

    if !modelPickerTrigger
    {
        modelPickerTrigger := FindChatPickerTrigger(windowElement)
        pickerKind := "chat"
    }

    if !modelPickerTrigger
    {
        LogMessage("model picker trigger was not found")
        return false
    }

    LogMessage("model picker trigger=" modelPickerTrigger.Name)

    try modelPickerTrigger.Click()
    catch as err
    {
        LogMessage("model picker trigger click failed=" err.Message)
        return false
    }

    pickerElement := WaitAnyVisibleElement(windowElement, [
        "^Show advanced options$",
        "^Show compact options$",
        "^Model ",
        "^Effort "
    ], 2200)

    if WinExist("A") != windowHandle
    {
        LogMessage("active window changed while opening model picker")
        return false
    }

    if !pickerElement
    {
        LogMessage("model picker did not open")
        try Send("{Escape}")
        return false
    }

    LogMessage("picker-kind=" pickerKind)
    if pickerKind = "chat"
        return SelectChatPreset(windowElement, targetChatEffort)

    currentLabel := GetSelectedTriggerLabel(windowElement)
    LogMessage("picker-open current=" currentLabel)
    if currentLabel = targetLabel
    {
        Send("{Escape}")
        Sleep(200)
        return GetSelectedTriggerLabel(windowElement) = targetLabel
            ? targetLabel
            : false
    }

    ; The compact Power slider intentionally omits Luna and Sol Max. Use the
    ; app's own Advanced -> Model -> Effort controls for every preset.
    modelRow := FindVisibleElement(windowElement, "^Model ", "MenuItem")
    if !modelRow
    {
        advancedToggle := FindVisibleElement(windowElement, "^Show advanced options$", "MenuItem")
        if !advancedToggle || !SelectMenuOption(advancedToggle)
        {
            LogMessage("advanced toggle was not found")
            try Send("{Escape}")
            return false
        }

        Sleep(300)
        modelRow := WaitVisibleElement(windowElement, "^Model ", 2500, "MenuItem")

        ; In this Electron build the Advanced state can be committed before
        ; its replacement rows enter the UIA tree. Reopen once so the saved
        ; Advanced view is exposed reliably.
        if !modelRow
        {
            LogMessage("advanced view delayed; reopening picker")
            try Send("{Escape}")
            Sleep(300)

            try reopenedTrigger := windowElement.FindElement({
                Type: "Button",
                Name: "^5\.6 (Luna|Terra|Sol) (Light|Medium|High|Extra High|Max|Ultra)( Fast)?$",
                mm: "RegEx",
                IsOffscreen: 0
            })
            catch
                reopenedTrigger := false

            if reopenedTrigger
            {
                reopenedTrigger.Click()
                Sleep(450)
                modelRow := WaitVisibleElement(windowElement, "^Model ", 2500, "MenuItem")
            }
        }
    }

    ; Model and Effort are flyout submenu triggers. Their React component
    ; doesn't open from UIA Invoke/Click; focus + ArrowRight is its supported
    ; keyboard path and does not move the user's mouse pointer.
    if !modelRow || !OpenSubmenu(modelRow)
    {
        LogMessage("model row was not found")
        try Send("{Escape}")
        return false
    }

    Sleep(250)
    modelOption := WaitVisibleElement(
        windowElement,
        "^(?:GPT-)?5\.6 " targetModel "$",
        2200,
        "MenuItem"
    )
    if !modelOption || !SelectMenuOption(modelOption)
    {
        LogMessage("model option was not found=" targetModel)
        try Send("{Escape}")
        return false
    }

    ; Do not open Effort against stale React state. Confirm that the parent
    ; row reflects the newly selected model first.
    updatedModelRow := WaitVisibleElement(
        windowElement,
        "^Model (?:GPT-)?5\.6 " targetModel "$",
        3000,
        "MenuItem"
    )

    ; Some option variants close the parent picker immediately. Reopen its
    ; persisted Advanced view, then verify the new model on the real parent
    ; row before attempting to open Effort.
    if !updatedModelRow
    {
        pickerTrigger := FindVisibleElement(
            windowElement,
            "^5\.6 (Luna|Terra|Sol) (Light|Medium|High|Extra High|Max|Ultra)( Fast)?$",
            "Button"
        )
        if pickerTrigger
        {
            LogMessage("reopening picker after model selection")
            pickerTrigger.Click()
            Sleep(450)
            updatedModelRow := WaitVisibleElement(
                windowElement,
                "^Model (?:GPT-)?5\.6 " targetModel "$",
                2500,
                "MenuItem"
            )
        }
    }

    if !updatedModelRow
    {
        LogMessage("model row did not update=" targetModel)
        try Send("{Escape}")
        return false
    }

    Sleep(200)
    effortRow := WaitVisibleElement(windowElement, "^Effort ", 1800, "MenuItem")

    ; Some model-option variants close the parent picker after selection.
    ; Reopen its persisted Advanced view before selecting effort.
    if !effortRow
    {
        try currentTrigger := windowElement.FindElement({
            Type: "Button",
            Name: "^5\.6 (Luna|Terra|Sol) (Light|Medium|High|Extra High|Max|Ultra)( Fast)?$",
            mm: "RegEx",
            IsOffscreen: 0
        })
        catch
            currentTrigger := false

        if currentTrigger
        {
            LogMessage("reopening picker for effort")
            currentTrigger.Click()
            Sleep(450)
            effortRow := WaitVisibleElement(windowElement, "^Effort ", 2200, "MenuItem")
        }
    }
    if !effortRow || !OpenSubmenu(effortRow)
    {
        LogMessage("effort row was not found")
        try Send("{Escape}")
        return false
    }

    Sleep(250)
    effortOptionPattern := GetEffortOptionPattern(targetEffort)
    effortOption := WaitVisibleElement(
        windowElement,
        effortOptionPattern,
        1800,
        "MenuItem"
    )
    if !effortOption || !SelectMenuOption(effortOption)
    {
        LogMessage("effort option was not found=" targetEffort)
        try Send("{Escape}")
        return false
    }

    if !WaitVisibleElement(
        windowElement,
        "^Effort " targetEffort "$",
        3000,
        "MenuItem"
    )
    {
        LogMessage("effort row did not update=" targetEffort)
        try Send("{Escape}")
        return false
    }

    Sleep(250)
    Send("{Escape}")
    Sleep(250)

    selectedLabel := WaitSelectedTriggerLabel(windowElement, targetLabel, 3000)
    LogMessage("advanced-selected=" selectedLabel)
    return selectedLabel = targetLabel ? selectedLabel : false
}

SelectChatPreset(windowElement, targetChatEffort)
{
    if targetChatEffort = ""
    {
        LogMessage("Chat effort is not configured for this preset")
        try Send("{Escape}")
        return false
    }

    LogMessage("chat-target=5.6 Sol " targetChatEffort)

    modelRow := FindVisibleElement(windowElement, "^Model ", "MenuItem")
    effortRow := FindVisibleElement(windowElement, "^Effort ", "MenuItem")
    if !modelRow || !effortRow
    {
        advancedToggle := FindVisibleElement(
            windowElement,
            "^Show advanced options$",
            "MenuItem"
        )
        if !advancedToggle || !SelectMenuOption(advancedToggle)
        {
            LogMessage("Chat advanced toggle was not found")
            try Send("{Escape}")
            return false
        }

        Sleep(300)
        modelRow := WaitVisibleElement(windowElement, "^Model ", 2500, "MenuItem")
        effortRow := WaitVisibleElement(windowElement, "^Effort ", 2500, "MenuItem")

        ; The view preference can be saved before the replacement rows enter
        ; the UIA tree. Reopen once and validate the actual Advanced rows.
        if !modelRow || !effortRow
        {
            LogMessage("Chat advanced view delayed; reopening picker")
            try Send("{Escape}")
            Sleep(300)

            reopenedTrigger := FindChatPickerTrigger(windowElement)
            if reopenedTrigger
            {
                reopenedTrigger.Click()
                Sleep(450)
                modelRow := WaitVisibleElement(
                    windowElement,
                    "^Model ",
                    2500,
                    "MenuItem"
                )
                effortRow := WaitVisibleElement(
                    windowElement,
                    "^Effort ",
                    2500,
                    "MenuItem"
                )
            }
        }
    }

    if !modelRow || !effortRow
    {
        LogMessage("Chat Advanced Model/Effort rows were not found")
        try Send("{Escape}")
        return false
    }

    ; Chat currently exposes 5.6 Sol plus Chat-specific effort labels. Accept
    ; both the visible label and rollout variants that include the GPT prefix.
    if !RegExMatch(modelRow.Name, GetChatModelRowPattern())
    {
        if !OpenSubmenu(modelRow)
        {
            LogMessage("Chat model row could not be opened")
            try Send("{Escape}")
            return false
        }

        Sleep(250)
        modelOption := WaitVisibleElement(
            windowElement,
            GetChatModelOptionPattern(),
            2200,
            "MenuItem"
        )
        if !modelOption || !SelectMenuOption(modelOption)
        {
            LogMessage("Chat model option was not found=5.6 Sol")
            try Send("{Escape}")
            return false
        }

        modelRow := WaitVisibleElement(
            windowElement,
            GetChatModelRowPattern(),
            1500,
            "MenuItem"
        )
        if !modelRow
        {
            reopenedTrigger := FindChatPickerTrigger(windowElement)
            if reopenedTrigger
            {
                LogMessage("reopening Chat picker after model selection")
                reopenedTrigger.Click()
                Sleep(450)
                modelRow := WaitVisibleElement(
                    windowElement,
                    GetChatModelRowPattern(),
                    2500,
                    "MenuItem"
                )
            }
        }

        if !modelRow
        {
            LogMessage("Chat model row did not update=5.6 Sol")
            try Send("{Escape}")
            return false
        }

        effortRow := WaitVisibleElement(windowElement, "^Effort ", 1800, "MenuItem")
    }

    if !effortRow
    {
        reopenedTrigger := FindChatPickerTrigger(windowElement)
        if reopenedTrigger
        {
            LogMessage("reopening Chat picker for effort")
            reopenedTrigger.Click()
            Sleep(450)
            effortRow := WaitVisibleElement(windowElement, "^Effort ", 2200, "MenuItem")
        }
    }

    effortPatterns := GetChatEffortOptionPatterns(targetChatEffort)
    currentEffortName := effortRow
        ? RegExReplace(effortRow.Name, "^Effort ")
        : ""
    if MatchesAnyPattern(currentEffortName, effortPatterns)
    {
        LogMessage("chat-current=5.6 Sol " currentEffortName)
        Send("{Escape}")
        Sleep(250)
        selectedValue := WaitSelectedChatTriggerValue(
            windowElement,
            currentEffortName,
            3000
        )
        return selectedValue = currentEffortName
            ? "5.6 Sol " selectedValue
            : false
    }

    if !effortRow || !OpenSubmenu(effortRow)
    {
        LogMessage("Chat effort row was not found")
        try Send("{Escape}")
        return false
    }

    Sleep(250)
    effortOption := WaitAnyVisibleElementOfType(
        windowElement,
        effortPatterns,
        2200,
        "MenuItem"
    )
    if !effortOption
    {
        LogMessage("Chat effort option was not found=" targetChatEffort)
        try Send("{Escape}")
        return false
    }

    selectedEffortName := effortOption.Name
    if !SelectMenuOption(effortOption)
    {
        LogMessage("Chat effort option could not be selected=" selectedEffortName)
        try Send("{Escape}")
        return false
    }

    updatedEffortRow := WaitVisibleElement(
        windowElement,
        "^Effort " selectedEffortName "$",
        1500,
        "MenuItem"
    )
    if !updatedEffortRow
    {
        reopenedTrigger := FindChatPickerTrigger(windowElement)
        if reopenedTrigger
        {
            LogMessage("reopening Chat picker after effort selection")
            reopenedTrigger.Click()
            Sleep(450)
            updatedEffortRow := WaitVisibleElement(
                windowElement,
                "^Effort " selectedEffortName "$",
                2500,
                "MenuItem"
            )
        }
    }

    if !updatedEffortRow
    {
        LogMessage("Chat effort row did not update=" selectedEffortName)
        try Send("{Escape}")
        return false
    }

    Sleep(250)
    Send("{Escape}")
    Sleep(250)

    selectedValue := WaitSelectedChatTriggerValue(
        windowElement,
        selectedEffortName,
        3000
    )
    LogMessage("chat-selected=5.6 Sol " selectedValue)
    return selectedValue = selectedEffortName
        ? "5.6 Sol " selectedValue
        : false
}

GetChatModelOptionPattern()
{
    return "^(?:GPT-)?5\.6(?: Sol)?$"
}

GetChatModelRowPattern()
{
    return "^Model (?:GPT-)?5\.6(?: Sol)?$"
}

GetChatEffortOptionPatterns(chatEffort)
{
    switch chatEffort
    {
        case "Instant": return ["^Instant$"]
        case "Medium": return ["^Medium$", "^Thinking - Standard$"]
        case "High": return ["^High$", "^Thinking - Extended$", "^Thinking$"]
        case "Extra High": return ["^Extra High$", "^Thinking - Heavy$"]
        ; Prefer the strongest legacy Pro variant when the simplified Pro
        ; label has not reached an account or managed workspace yet.
        case "Pro": return ["^Pro$", "^Pro Extended$", "^Pro Standard$"]
        default: return []
    }
}

MatchesAnyPattern(value, patterns)
{
    for pattern in patterns
    {
        if RegExMatch(value, pattern)
            return true
    }
    return false
}

FindCodexPickerTrigger(windowElement)
{
    return FindVisibleElement(
        windowElement,
        "^5\.6 (Luna|Terra|Sol) (Light|Medium|High|Extra High|Max|Ultra)( Fast)?$",
        "Button"
    )
}

FindChatPickerTrigger(windowElement)
{
    return FindVisibleElement(
        windowElement,
        "^Select ChatGPT model$",
        "Button"
    )
}

WaitSelectedChatTriggerValue(windowElement, targetValue, timeout)
{
    textDeadline := A_TickCount + Min(timeout, 700)
    loop
    {
        trigger := FindChatPickerTrigger(windowElement)
        if trigger
        {
            try selectedText := trigger.FindElement({
                Type: "Text",
                Name: "^" targetValue "$",
                mm: "RegEx",
                IsOffscreen: 0
            })
            catch
                selectedText := false

            if selectedText
                return targetValue
        }

        if A_TickCount >= textDeadline
            break

        Sleep(75)
    }

    ; Chromium can make a Button's descendants presentational when aria-label
    ; is set. In that case the visible effort is not a separate UIA Text node.
    ; Reopen through the verified Chat Button and confirm the persisted parent
    ; row instead of trusting a click that merely returned without throwing.
    trigger := FindChatPickerTrigger(windowElement)
    if !trigger
        return ""

    try trigger.Click()
    catch as err
    {
        LogMessage("Chat final trigger click failed=" err.Message)
        return ""
    }

    effortRow := WaitVisibleElement(
        windowElement,
        "^Effort " targetValue "$",
        Max(300, timeout - 700),
        "MenuItem"
    )
    if !effortRow
    {
        advancedToggle := FindVisibleElement(
            windowElement,
            "^Show advanced options$",
            "MenuItem"
        )
        if advancedToggle && SelectMenuOption(advancedToggle)
        {
            effortRow := WaitVisibleElement(
                windowElement,
                "^Effort " targetValue "$",
                2200,
                "MenuItem"
            )
        }
    }

    if effortRow
    {
        LogMessage("chat-final-row=" effortRow.Name)
        Send("{Escape}")
        Sleep(200)
        return targetValue
    }

    try Send("{Escape}")
    return ""
}

GetEffortOptionPattern(targetEffort)
{
    return targetEffort = "Ultra"
        ? "^Ultra(?:\s+.+)?$"
        : "^" targetEffort "$"
}

FindVisibleElement(windowElement, namePattern, controlType := "")
{
    condition := {
        Name: namePattern,
        mm: "RegEx",
        IsOffscreen: 0
    }
    if controlType != ""
        condition.Type := controlType

    try return windowElement.FindElement(condition)
    catch
    {
        return false
    }
}

WaitVisibleElement(windowElement, namePattern, timeout, controlType := "")
{
    condition := {
        Name: namePattern,
        mm: "RegEx",
        IsOffscreen: 0
    }
    if controlType != ""
        condition.Type := controlType

    try return windowElement.WaitElement(condition, timeout)
    catch
    {
        return false
    }
}

WaitAnyVisibleElement(windowElement, namePatterns, timeout)
{
    deadline := A_TickCount + timeout

    loop
    {
        for namePattern in namePatterns
        {
            if element := FindVisibleElement(windowElement, namePattern)
                return element
        }

        if A_TickCount >= deadline
            return false

        Sleep(60)
    }
}

WaitAnyVisibleElementOfType(
    windowElement,
    namePatterns,
    timeout,
    controlType
)
{
    deadline := A_TickCount + timeout

    loop
    {
        for namePattern in namePatterns
        {
            if element := FindVisibleElement(
                windowElement,
                namePattern,
                controlType
            )
                return element
        }

        if A_TickCount >= deadline
            return false

        Sleep(60)
    }
}

OpenSubmenu(element)
{
    try
    {
        elementName := element.Name
        element.SetFocus()
        Sleep(100)
        Send("{Right}")
        LogMessage("submenu-open=" elementName)
        return true
    }
    catch as err
    {
        LogMessage("submenu open failed=" err.Message)
        return false
    }
}

SelectMenuOption(element)
{
    try
    {
        elementName := element.Name
        element.SetFocus()
        Sleep(100)
        Send("{Enter}")
        LogMessage("option-select=" elementName)
        return true
    }
    catch as err
    {
        LogMessage("option select failed=" err.Message)
        return false
    }
}

WaitSelectedTriggerLabel(windowElement, targetLabel, timeout)
{
    deadline := A_TickCount + timeout
    lastLabel := ""

    loop
    {
        lastLabel := GetSelectedTriggerLabel(windowElement)
        if lastLabel = targetLabel
            return lastLabel

        if A_TickCount >= deadline
            return lastLabel

        Sleep(75)
    }
}

GetSelectedTriggerLabel(windowElement)
{
    try
    {
        ; Match the actual picker button, not a stale descendant text node
        ; retained by React during a menu transition.
        trigger := windowElement.FindElement({
            Type: "Button",
            Name: "^5\.6 (Luna|Terra|Sol) (Light|Medium|High|Extra High|Max|Ultra)( Fast)?$",
            mm: "RegEx",
            IsOffscreen: 0
        })

        if trigger
            return RegExReplace(trigger.Name, " Fast$")
    }
    catch as err
    {
        LogMessage("trigger read error=" err.Message)
    }

    return ""
}

HidePresetToolTip()
{
    ToolTip()
}
