#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

global AppName := "ReasonKey"
global AppVersion := "1.0.3"
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
    try RegDelete(legacyUninstallKey)

    ; The new installation and migrated configuration are now durable. Remove
    ; the obsolete product directory so Installed Apps exposes one product.
    if FileExist(ConfigPath)
        RemoveLegacyInstallationDirectory()

    Run('"' RuntimePath '"', InstallDirectory)
    try FileAppend(
        FormatTime(, "yyyy-MM-dd HH:mm:ss") " install-complete path=" InstallDirectory "`n",
        SetupLogPath,
        "UTF-8"
    )
    if !SilentInstall
        ShowInstallationGuide()
    ExitApp(0)
}

ShowInstallationGuide()
{
    global AppName, AppVersion

    guideGui := Gui("+OwnDialogs", AppName " " AppVersion)
    guideGui.MarginX := 24
    guideGui.MarginY := 20

    guideGui.SetFont("s14 Bold", "Segoe UI")
    guideGui.AddText("w680", "Installation completed successfully")

    guideGui.SetFont("s9 Norm", "Segoe UI")
    guideGui.AddText("y+8 w680", "ReasonKey is now running in the background and will start automatically when you sign in to Windows.")

    guideGui.SetFont("s10 Bold", "Segoe UI")
    guideGui.AddText("y+14 w680", "Default shortcuts")
    guideGui.SetFont("s9 Norm", "Segoe UI")
    guideGui.AddText("y+4 w680", "F16  -  Luna High        F17  -  Sol Light        F18  -  Sol Extra High        F19  -  Sol Max")
    guideGui.AddText("y+3 w680", "If your keyboard does not have F16-F19 keys, use the customization steps below to assign combinations such as Ctrl+Alt+1 through Ctrl+Alt+4.")

    guideGui.SetFont("s10 Bold", "Segoe UI")
    guideGui.AddText("y+14 w680", "How to use it")
    guideGui.SetFont("s9 Norm", "Segoe UI")
    guideGui.AddText("y+4 w680", "1. Open or activate the Codex/ChatGPT desktop app and use either a Codex or ChatGPT Chat composer.`n2. Press one of the shortcuts above.`n3. ReasonKey selects the configured model and effort for that composer. A small status message confirms the result.")

    guideGui.SetFont("s10 Bold", "Segoe UI")
    guideGui.AddText("y+14 w680", "Where to find the tray icon")
    guideGui.SetFont("s9 Norm", "Segoe UI")
    guideGui.AddText("y+4 w680", "1. Look in the Windows notification area at the bottom-right of the screen, near the clock.`n2. If the icon is hidden, click the ^ arrow to show hidden icons.`n3. Find the black key icon with green-and-white chevrons. Hover over it to see '" AppName " " AppVersion "'.`n4. Right-click that icon to open the utility menu. It contains the presets, configuration files, log, Reload, and Exit.")

    guideGui.SetFont("s10 Bold", "Segoe UI")
    guideGui.AddText("y+14 w680", "How to customize shortcuts, models, or effort")
    guideGui.SetFont("s9 Norm", "Segoe UI")
    guideGui.AddText("y+4 w680", "1. Right-click the black key tray icon and choose Open presets.ini.`n2. Follow the detailed instructions at the top of the file, then save it with Ctrl+S.`n3. Right-click the key icon again and choose Reload to apply your changes.`n4. Open configuration guide shows an always-current commented example. Upgrades never overwrite your active presets.ini.`n5. If something does not work, choose Open log from the same tray menu.")

    guideGui.SetFont("s9 Norm", "Segoe UI")
    finishButton := guideGui.AddButton("y+18 w110 h30 Default", "Finish")

    finishButton.OnEvent("Click", (*) => guideGui.Destroy())
    guideGui.OnEvent("Close", (*) => guideGui.Destroy())

    guideGui.Show("AutoSize Center")
    WinWaitClose("ahk_id " guideGui.Hwnd)
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
    if InStr(candidate, codexPackagesPrefix) != 1
        return false
    for redirectedSuffix in redirectedSuffixes
    {
        if RegExMatch(candidate, "\Q" redirectedSuffix "\E$")
            return true
    }
    return false
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
