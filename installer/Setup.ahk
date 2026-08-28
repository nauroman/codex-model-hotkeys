#Requires AutoHotkey v2.0
#SingleInstance Force
#NoTrayIcon

global AppName := "Codex Model Hotkeys"
global AppVersion := "1.0.0"
global InstallDirectory := EnvGet("LOCALAPPDATA") "\CodexModelHotkeys"
global RuntimePath := InstallDirectory "\CodexModelHotkeys.exe"
global ConfigPath := InstallDirectory "\presets.ini"
global StartupShortcut := A_Startup "\CodexModelHotkeys.lnk"
global RepositoryUrl := "https://github.com/nauroman/codex-model-hotkeys"
global SilentInstall := HasArgument("--silent")
global SetupLogPath := A_Temp "\CodexModelHotkeys-Setup.log"

if InStr(DllCall("GetCommandLine", "Str"), " --validate")
    ExitApp(0)

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
    global AppName, AppVersion, InstallDirectory, RuntimePath, ConfigPath
    global StartupShortcut, RepositoryUrl, SilentInstall, SetupLogPath

    try FileAppend(
        FormatTime(, "yyyy-MM-dd HH:mm:ss") " install-start version=" AppVersion "`n",
        SetupLogPath,
        "UTF-8"
    )

    StopInstalledRuntime()
    StopLegacyRuntime()
    DirCreate(InstallDirectory)

    FileInstall("..\dist\CodexModelHotkeys.exe", RuntimePath, true)
    if !FileExist(ConfigPath)
        FileInstall("..\config\default-presets.ini", ConfigPath, false)
    FileInstall("Uninstall.ps1", InstallDirectory "\Uninstall.ps1", true)
    FileInstall("..\LICENSE", InstallDirectory "\LICENSE.txt", true)
    FileInstall("..\THIRD_PARTY_NOTICES.md", InstallDirectory "\THIRD_PARTY_NOTICES.md", true)

    ; Remove the launcher used by the early development build, if present.
    legacyLauncher := A_Startup "\CodexModelWheelLauncher.ahk"
    if FileExist(legacyLauncher)
        FileDelete(legacyLauncher)

    if FileExist(StartupShortcut)
        FileDelete(StartupShortcut)
    FileCreateShortcut(RuntimePath, StartupShortcut, InstallDirectory, "", AppName)

    uninstallKey := "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\CodexModelHotkeys"
    uninstallCommand := Format(
        'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{1}\Uninstall.ps1"',
        InstallDirectory
    )
    quietUninstallCommand := uninstallCommand " -Silent"

    RegWrite(AppName, "REG_SZ", uninstallKey, "DisplayName")
    RegWrite(AppVersion, "REG_SZ", uninstallKey, "DisplayVersion")
    RegWrite("Codex Model Hotkeys contributors", "REG_SZ", uninstallKey, "Publisher")
    RegWrite(RuntimePath, "REG_SZ", uninstallKey, "DisplayIcon")
    RegWrite(InstallDirectory, "REG_SZ", uninstallKey, "InstallLocation")
    RegWrite(RepositoryUrl, "REG_SZ", uninstallKey, "URLInfoAbout")
    RegWrite(uninstallCommand, "REG_SZ", uninstallKey, "UninstallString")
    RegWrite(quietUninstallCommand, "REG_SZ", uninstallKey, "QuietUninstallString")
    RegWrite(1, "REG_DWORD", uninstallKey, "NoModify")
    RegWrite(1, "REG_DWORD", uninstallKey, "NoRepair")
    RegWrite(2500, "REG_DWORD", uninstallKey, "EstimatedSize")

    Run('"' RuntimePath '"', InstallDirectory)
    try FileAppend(
        FormatTime(, "yyyy-MM-dd HH:mm:ss") " install-complete path=" InstallDirectory "`n",
        SetupLogPath,
        "UTF-8"
    )
    if !SilentInstall
        MsgBox(
            "Installed successfully.`n`n"
            "F16  Luna High`n"
            "F17  Sol Light`n"
            "F18  Sol Extra High`n"
            "F19  Sol Max`n`n"
            "Ctrl+Alt+mouse wheel cycles the same presets.`n"
            "Right-click the tray icon to edit presets or open the log.",
            AppName,
            "Iconi"
        )
    ExitApp(0)
}

StopInstalledRuntime()
{
    processId := ProcessExist("CodexModelHotkeys.exe")
    if !processId
        return

    try ProcessClose(processId)
    try ProcessWaitClose(processId, 3)
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
