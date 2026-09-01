#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

global AppName := "ReasonKey"
global AppVersion := "1.0.4"
global InstallDirectory := EnvGet("LOCALAPPDATA") "\ReasonKey"
global RuntimePath := InstallDirectory "\ReasonKey.exe"
global ConfigPath := InstallDirectory "\presets.ini"
global GuidePath := InstallDirectory "\presets-reference.ini"
global StartupShortcut := A_Startup "\ReasonKey.lnk"
global LegacyInstallDirectory := EnvGet("LOCALAPPDATA") "\CodexModelHotkeys"
global LegacyRuntimePath := LegacyInstallDirectory "\CodexModelHotkeys.exe"
global LegacyStartupShortcut := A_Startup "\CodexModelHotkeys.lnk"
global RepositoryUrl := "https://github.com/nauroman/codex-model-hotkeys"
global SilentInstall := HasArgument("--silent")
global SetupLogPath := A_Temp "\ReasonKey-Setup.log"

if InStr(DllCall("GetCommandLine", "Str"), " --validate")
{
    redirectedRuntimePath := EnvGet("LOCALAPPDATA")
        . "\Packages\OpenAI.Codex_Test\LocalCache\Local"
        . "\ReasonKey\ReasonKey.exe"
    if !IsInstalledRuntimePath(RuntimePath)
        ExitApp(11)
    if !IsInstalledRuntimePath(redirectedRuntimePath)
        ExitApp(12)
    if !IsInstalledRuntimePath(LegacyRuntimePath)
        ExitApp(13)
    if IsInstalledRuntimePath(EnvGet("LOCALAPPDATA") "\Other\ReasonKey.exe")
        ExitApp(14)
    unrelatedPackagePath := EnvGet("LOCALAPPDATA")
        . "\Packages\Other.Package_Test\LocalCache\Local"
        . "\ReasonKey\ReasonKey.exe"
    if IsInstalledRuntimePath(unrelatedPackagePath)
        ExitApp(15)
    storeRuntimePath := EnvGet("ProgramFiles")
        . "\WindowsApps\RotorlashLabs.ReasonKey_1.0.4.0_x64__test"
        . "\ReasonKey.exe"
    if !IsInstalledRuntimePath(storeRuntimePath)
        ExitApp(16)
    developmentStoreRuntimePath := EnvGet("ProgramFiles")
        . "\WindowsApps\RotorlashLabs.ReasonKey.Dev_1.0.4.0_x64__test"
        . "\ReasonKey.exe"
    if !IsInstalledRuntimePath(developmentStoreRuntimePath)
        ExitApp(17)
    unrelatedStoreRuntimePath := EnvGet("ProgramFiles")
        . "\WindowsApps\RotorlashLabs.ReasonKey.Tools_1.0.4.0_x64__test"
        . "\ReasonKey.exe"
    if IsInstalledRuntimePath(unrelatedStoreRuntimePath)
        ExitApp(18)
    ExitApp(0)
}

try InstallApplication()
catch as err
{
    try FileAppend(
        FormatTime(, "yyyy-MM-dd HH:mm:ss")
        " error=" err.Message
        " what=" err.What
        " file=" err.File
        " line=" err.Line
        " stack=" err.Stack
        "`n",
        SetupLogPath,
        "UTF-8"
    )
    if !SilentInstall
        MsgBox(
            "Installation failed.`n`n" err.Message,
            AppName,
            "Iconx"
        )
    ExitApp(1)
}

InstallApplication()
{
    global AppName, AppVersion, InstallDirectory, RuntimePath, ConfigPath, GuidePath
    global StartupShortcut, RepositoryUrl, SilentInstall, SetupLogPath
    global LegacyInstallDirectory, LegacyStartupShortcut

    try FileAppend(
        FormatTime(, "yyyy-MM-dd HH:mm:ss") " install-start version=" AppVersion "`n",
        SetupLogPath,
        "UTF-8"
    )

    StopInstalledRuntime()
    StopLegacyRuntime()
    DirCreate(InstallDirectory)
    MigrateLegacyConfiguration()

    FileInstall("..\dist\ReasonKey.exe", RuntimePath, true)
    if !FileExist(ConfigPath)
        FileInstall("..\config\default-presets.ini", ConfigPath, false)
    ; Always refresh the reference copy while preserving the user's active
    ; presets.ini byte-for-byte during upgrades.
    FileInstall("..\config\default-presets.ini", GuidePath, true)
    FileInstall("Uninstall.ps1", InstallDirectory "\Uninstall.ps1", true)
    FileInstall("..\LICENSE", InstallDirectory "\LICENSE.txt", true)
    FileInstall("..\THIRD_PARTY_NOTICES.md", InstallDirectory "\THIRD_PARTY_NOTICES.md", true)

    ; Remove the launcher used by the early development build, if present.
    legacyLauncher := A_Startup "\CodexModelWheelLauncher.ahk"
    if FileExist(legacyLauncher)
        FileDelete(legacyLauncher)

    if FileExist(StartupShortcut)
        FileDelete(StartupShortcut)
    if FileExist(LegacyStartupShortcut)
        FileDelete(LegacyStartupShortcut)
    FileCreateShortcut(RuntimePath, StartupShortcut, InstallDirectory, "", AppName)

    uninstallKey := "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\ReasonKey"
    legacyUninstallKey := "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\CodexModelHotkeys"
    uninstallCommand := Format(
        'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{1}\Uninstall.ps1"',
        InstallDirectory
    )
    quietUninstallCommand := uninstallCommand " -Silent"

    RegWrite(AppName, "REG_SZ", uninstallKey, "DisplayName")
    RegWrite(AppVersion, "REG_SZ", uninstallKey, "DisplayVersion")
    RegWrite("Rotorlash Labs", "REG_SZ", uninstallKey, "Publisher")
    RegWrite(RuntimePath, "REG_SZ", uninstallKey, "DisplayIcon")
    RegWrite(InstallDirectory, "REG_SZ", uninstallKey, "InstallLocation")
    RegWrite(RepositoryUrl, "REG_SZ", uninstallKey, "URLInfoAbout")
    RegWrite(uninstallCommand, "REG_SZ", uninstallKey, "UninstallString")
    RegWrite(quietUninstallCommand, "REG_SZ", uninstallKey, "QuietUninstallString")
    RegWrite(1, "REG_DWORD", uninstallKey, "NoModify")
    RegWrite(1, "REG_DWORD", uninstallKey, "NoRepair")
    RegWrite(2500, "REG_DWORD", uninstallKey, "EstimatedSize")
    try RegDeleteKey(legacyUninstallKey)

    ; The new installation and migrated configuration are now durable. Remove
    ; the obsolete product directory so Installed Apps exposes one product.
    if FileExist(ConfigPath)
        RemoveLegacyInstallationDirectory()

    runtimeCommand := '"' RuntimePath '"'
    if !SilentInstall
        runtimeCommand .= " --show-quick-start"
    Run(runtimeCommand, InstallDirectory)
    try FileAppend(
        FormatTime(, "yyyy-MM-dd HH:mm:ss") " install-complete path=" InstallDirectory "`n",
        SetupLogPath,
        "UTF-8"
    )
    ExitApp(0)
}

StopInstalledRuntime()
{
    try
    {
        service := ComObjGet("winmgmts:")
        query := "SELECT ProcessId, ExecutablePath FROM Win32_Process "
            . "WHERE Name = 'ReasonKey.exe' OR Name = 'CodexModelHotkeys.exe'"
        for process in service.ExecQuery(query)
        {
            try processPath := process.ExecutablePath
            catch
                processPath := ""
            if !IsInstalledRuntimePath(processPath)
                continue

            processId := process.ProcessId
            process.Terminate()
            try ProcessWaitClose(processId, 3)
        }
    }
}

IsInstalledRuntimePath(processPath)
{
    global RuntimePath, LegacyRuntimePath

    candidate := StrLower(StrReplace(processPath, "/", "\"))
    expected := StrLower(StrReplace(RuntimePath, "/", "\"))
    legacyExpected := StrLower(StrReplace(LegacyRuntimePath, "/", "\"))
    if candidate = expected || candidate = legacyExpected
        return true

    ; A process started from the packaged Codex app can report the Win32
    ; LOCALAPPDATA redirection path even though the installed file is the same
    ; per-user runtime. Accept only that exact redirected install suffix.
    codexPackagesPrefix := StrLower(EnvGet("LOCALAPPDATA") "\Packages\OpenAI.Codex_")
    redirectedSuffixes := [
        "\localcache\local\reasonkey\reasonkey.exe",
        "\localcache\local\codexmodelhotkeys\codexmodelhotkeys.exe"
    ]
    if InStr(candidate, codexPackagesPrefix) = 1
    {
        for redirectedSuffix in redirectedSuffixes
        {
            if RegExMatch(candidate, "\Q" redirectedSuffix "\E$")
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

MigrateLegacyConfiguration()
{
    global ConfigPath, LegacyInstallDirectory

    if FileExist(ConfigPath)
        return
    legacyConfigPath := LegacyInstallDirectory "\presets.ini"
    if FileExist(legacyConfigPath)
        FileCopy(legacyConfigPath, ConfigPath, false)
}

RemoveLegacyInstallationDirectory()
{
    global LegacyInstallDirectory, SetupLogPath

    cleanupError := ""
    loop 5
    {
        if !DirExist(LegacyInstallDirectory)
            return
        try
        {
            DirDelete(LegacyInstallDirectory, true)
        }
        catch as err
        {
            cleanupError := err.Message
        }
        if !DirExist(LegacyInstallDirectory)
            return
        Sleep(250)
    }

    try FileAppend(
        FormatTime(, "yyyy-MM-dd HH:mm:ss")
        " legacy-cleanup-warning=" cleanupError
        " path=" LegacyInstallDirectory "`n",
        SetupLogPath,
        "UTF-8"
    )
}

StopLegacyRuntime()
{
    try
    {
        service := ComObjGet("winmgmts:")
        query := "SELECT ProcessId, CommandLine FROM Win32_Process "
            . "WHERE Name = 'AutoHotkey64.exe'"
        for process in service.ExecQuery(query)
        {
            try commandLine := process.CommandLine
            catch
                commandLine := ""
            if InStr(commandLine, "\.codex\CodexModelWheel.ahk")
                process.Terminate()
        }
    }
}

HasArgument(expected)
{
    for argument in A_Args
    {
        if argument = expected
            return true
    }
    return false
}
