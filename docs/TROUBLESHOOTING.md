# Troubleshooting

## Nothing happens when I press a hotkey

1. Make sure the Codex desktop window is active. Hotkeys are deliberately scoped
   to Codex.
2. Check for the **Codex Model Hotkeys** tray icon.
3. Right-click it and choose **Open log**.
4. If the tray icon is missing, run:

   ```text
   %LOCALAPPDATA%\CodexModelHotkeys\CodexModelHotkeys.exe
   ```

## “Model picker trigger was not found”

The desktop app's accessible label probably changed, the composer is not
visible, or the picker is disabled while the current screen is in a special
state. Open a normal Codex task, place the composer on screen, and retry.

When reporting this problem, include:

- Codex app version;
- Windows version;
- display language;
- the relevant log lines;
- a screenshot of the open picker.

## “Advanced toggle was not found”

The script accepts both initial states: compact mode and already-expanded
Advanced mode. This error means neither the Advanced toggle nor the Model row
was exposed in the UI Automation tree before the timeout.

## A model or effort option is missing

Availability can vary by model, account, workspace policy, and Codex version.
Only configure combinations that the picker exposes manually.

## My F16–F19 keys do not exist

Many macro keyboards and mouse utilities can emit F13–F24. If yours cannot,
edit `presets.ini` and use ordinary combinations such as `^!1` through `^!4`
for Ctrl+Alt+1 through Ctrl+Alt+4.

## The installer shows a SmartScreen warning

The release executable is not code-signed. Verify that it came from the
`nauroman/codex-model-hotkeys` GitHub Releases page and compare its SHA-256 hash
with `CodexModelHotkeys-Setup.exe.sha256` before choosing **Run anyway**.

## Where is the log?

```text
%LOCALAPPDATA%\CodexModelHotkeys\CodexModelHotkeys.log
```

Useful terminal command:

```powershell
Get-Content "$env:LOCALAPPDATA\CodexModelHotkeys\CodexModelHotkeys.log" -Tail 100
```

If installation itself fails, its diagnostic log is stored at:

```text
%TEMP%\CodexModelHotkeys-Setup.log
```
