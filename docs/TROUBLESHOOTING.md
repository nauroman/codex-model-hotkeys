# Troubleshooting

## Nothing happens when I press a hotkey

1. Make sure the Codex/ChatGPT desktop window is active with a Codex or Chat
   composer visible. Hotkeys are deliberately scoped to that application.
2. Check for the **ReasonKey** tray icon.
3. Right-click it and choose **Open log**.
4. If the tray icon is missing, run:

   ```text
   %LOCALAPPDATA%\ReasonKey\ReasonKey.exe
   ```

   That path is for the direct installation. For Microsoft Store, launch
   ReasonKey from Start or its Store page. With both channels installed, the
   first current runtime owns the tray icon; see [lifecycle](product-spec/installation.md).

## “Model picker trigger was not found”

The desktop app's accessible label probably changed, the composer is not
visible, or the picker is disabled while the current screen is in a special
state. Open a normal Codex task or Chat conversation, place the composer on
screen, and retry.

When reporting this problem, include:

- Codex/ChatGPT desktop app version;
- Windows version;
- display language;
- the relevant log lines;
- a screenshot of the open picker.

## “Advanced toggle was not found”

This is a legacy-picker error: neither the Advanced toggle nor the Model row
appeared before timeout. Unified pickers use Select model and Power instead.
Both paths and already-open views are supported; include the starting view in
your report. See the [picker contract](product-spec/picker.md).

## A model or effort option is missing

Availability can vary by composer, model, account, workspace policy, and app version.
Only configure combinations that the picker exposes manually.

## My F16–F19 keys do not exist

Many macro keyboards and mouse utilities can emit F13–F24. If yours cannot,
edit `presets.ini` and use ordinary combinations such as `^!1` through `^!4`
for Ctrl+Alt+1 through Ctrl+Alt+4.

## The installer shows a SmartScreen warning

The release executable is not code-signed. Verify that it came from the
`nauroman/codex-model-hotkeys` GitHub Releases page and compare its SHA-256 hash
with `ReasonKey-Setup.exe.sha256` before choosing **Run anyway**.

## Where is the log?

```text
%LOCALAPPDATA%\ReasonKey\ReasonKey.log
```

Useful terminal command:

```powershell
Get-Content "$env:LOCALAPPDATA\ReasonKey\ReasonKey.log" -Tail 100
```

These paths are for the direct install. Store logs use the package's per-user
LocalState/ReasonKey directory; **Open log** selects the active channel's file.
Review logs for private paths before sharing. Full path ownership is documented
in [installation](product-spec/installation.md).

If installation itself fails, its diagnostic log is stored at:

```text
%TEMP%\ReasonKey-Setup.log
```
