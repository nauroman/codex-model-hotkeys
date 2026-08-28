#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_ScriptDir%\..\vendor\UIA-v2\Lib\UIA.ahk

; Ahk2Exe launches the source with /iLib to discover library dependencies.
; The explicit UIA include is already resolved by the preprocessor, so the
; runtime must exit before its persistent auto-execute section starts.
global RawCommandLine := DllCall("GetCommandLine", "Str")
if InStr(RawCommandLine, " /iLib ")
    ExitApp(0)

if InStr(RawCommandLine, " --validate")
{
    ultraPattern := GetEffortOptionPattern("Ultra")
    if !RegExMatch("Ultra Available on selected plans", ultraPattern)
        ExitApp(1)
    if RegExMatch("Max", ultraPattern)
        ExitApp(1)
    ExitApp(0)
}

UIA.SetMaximumDPIAwareness()
Persistent true

global AppName := "Codex Model Hotkeys"
global AppVersion := "1.0.2"
global ConfigPath := A_IsCompiled
    ? A_ScriptDir "\presets.ini"
    : A_ScriptDir "\..\config\default-presets.ini"
global GuidePath := A_IsCompiled
    ? A_ScriptDir "\presets-reference.ini"
    : A_ScriptDir "\..\config\default-presets.ini"
global DataDirectory := EnvGet("LOCALAPPDATA") "\CodexModelHotkeys"
global LogPath := DataDirectory "\CodexModelHotkeys.log"
global Presets := LoadPresets(ConfigPath)

DirCreate(DataDirectory)
OnError(LogUnhandledError)

RegisterConfiguredHotkeys()
BuildTrayMenu()
LogMessage("script-start version=" AppVersion " pid=" DllCall("GetCurrentProcessId"))

DefaultPresets()
{
    return [
        CreatePreset("F16", "Luna High", "Luna", "High"),
        CreatePreset("F17", "Sol Light", "Sol", "Light"),
        CreatePreset("F18", "Sol Extra High", "Sol", "Extra High"),
        CreatePreset("F19", "Sol Max", "Sol", "Max")
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
        displayName := Trim(IniRead(configPath, section, "Name", modelName " " effortName))

        if hotkeyName = "" || modelName = "" || effortName = ""
            continue

        presets.Push(CreatePreset(hotkeyName, displayName, modelName, effortName))
    }

    return presets.Length ? presets : DefaultPresets()
}

CreatePreset(hotkeyName, displayName, modelName, effortName)
{
    return {
        Hotkey: hotkeyName,
        Name: displayName,
        TriggerLabel: "5.6 " modelName " " effortName
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

HasCommandLineArgument(expected)
{
    for argument in A_Args
    {
        if argument = expected
            return true
    }
    return false
}

RegisterConfiguredHotkeys()
{
    global Presets

    HotIf((*) => IsCodexWindow())
    for index, preset in Presets
    {
        try Hotkey(preset.Hotkey, SelectPreset.Bind(index))
        catch as err
            LogMessage("invalid-hotkey=" preset.Hotkey " error=" err.Message)
    }
    HotIf()
}

BuildTrayMenu()
{
    global Presets, AppName, AppVersion

    A_TrayMenu.Delete()
    for index, preset in Presets
        A_TrayMenu.Add(preset.Hotkey "  " preset.Name, SelectPreset.Bind(index))

    A_TrayMenu.Add()
    A_TrayMenu.Add("Open presets.ini", OpenConfiguration)
    A_TrayMenu.Add("Open configuration guide", OpenConfigurationGuide)
    A_TrayMenu.Add("Open log", OpenLog)
    A_TrayMenu.Add("Reload", ReloadApplication)
    A_TrayMenu.Add("Exit", ExitApplication)
    A_IconTip := AppName " " AppVersion
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
    ShowStatus("Codex Model Hotkeys error: " err.Message, 5000)
    return true
}

IsCodexWindow()
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

    if !IsCodexWindow()
    {
        ShowStatus("Codex Model Hotkeys: Codex window is not active", 2500)
        LogMessage("ignored-not-codex=" preset.TriggerLabel)
        return
    }

    switching := true
    ShowStatus("Codex: selecting " preset.Name "...", 5000)
    LogMessage("requested=" preset.TriggerLabel)

    try
    {
        if !SelectCombinedPreset(preset.TriggerLabel)
        {
            ShowStatus("Codex: could not select " preset.Name " (see " LogPath ")", 3500)
            LogMessage("failed=" preset.TriggerLabel)
            return
        }

        ShowStatus("Codex: " preset.Name)
        LogMessage("selected=" preset.TriggerLabel)
    }
    catch as err
    {
        try Send("{Escape}")
        ShowStatus("Codex Model Hotkeys error: " err.Message, 4000)
        LogMessage("error=" err.Message)
    }
    finally
    {
        switching := false
    }
}

SelectCombinedPreset(targetLabel)
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
    try modelPickerTrigger := windowElement.FindElement({
        Type: "Button",
        Name: "^5\.6 (Luna|Terra|Sol) (Light|Medium|High|Extra High|Max|Ultra)( Fast)?$",
        mm: "RegEx",
        IsOffscreen: 0
    })
    catch
        modelPickerTrigger := false

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

    currentLabel := GetSelectedTriggerLabel(windowElement)
    LogMessage("picker-open current=" currentLabel)
    if currentLabel = targetLabel
    {
        Send("{Escape}")
        Sleep(200)
        return GetSelectedTriggerLabel(windowElement) = targetLabel
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
    return selectedLabel = targetLabel
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
