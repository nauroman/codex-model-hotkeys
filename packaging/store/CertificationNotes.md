# Notes for Microsoft Store certification

ReasonKey is an open-source, full-trust Win32 tray utility packaged as MSIX. It
requires no test account, product key, payment, or administrator privileges to
launch and inspect its tray menu, configuration, privacy behavior, and
quick-start window. Network access is optional for its Microsoft Store package
update check; all core hotkey and UI Automation functionality works offline.

## First launch

1. Launch **ReasonKey** from Start or the Store.
2. A quick-start window appears on the first launch.
3. After closing it, the application remains available through the black key
   icon in the Windows notification area. The icon can be under the `^` hidden
   icons menu.
4. Right-click the icon to inspect presets, local configuration, configuration
   reference, local log, reload, startup settings, and exit commands.

The manifest declares a supported `windows.startupTask` extension, but it is
disabled by default. The user can opt in through the **Open Startup Apps
settings** tray command or quick-start button.

ReasonKey uses one per-session Windows named mutex across its Store package,
direct installer, package-redirected paths, and renamed legacy runtime. A
second current launch exits before registering hotkeys or creating another tray
icon. During the 1.0.3-to-1.0.4 migration, the new runtime terminates only exact
recognized ReasonKey and Codex Model Hotkeys product paths; it does not stop
unrelated AutoHotkey scripts.

## Functional dependency

Model switching requires the separately installed Codex/ChatGPT Windows
desktop app with English picker labels. It supports both the Codex composer
and ChatGPT Chat composer, and remains stable when the
desktop app is absent. For a complete functional test:

1. Install and open the official Codex/ChatGPT Windows desktop app.
2. Sign in with a tester-owned OpenAI account.
3. Keep a Codex composer active.
4. Press F16, F17, F18, or F19.
5. Confirm the combined model/effort label changes to the corresponding value.

The same shortcuts must also be tested in a ChatGPT Chat composer. They select
5.6 Sol with Light, Medium, High, and Max Power in the current unified picker.
Legacy Instant and Pro configuration values map to the current Light and Max
endpoints as documented in the public README.

No publisher-supplied Codex or OpenAI credentials are required or included.

## Restricted capability justification: runFullTrust

The package contains an AutoHotkey v2 Win32 desktop process and therefore
declares `runFullTrust`. Full trust is used only for:

- registering user-configured keyboard shortcuts while the Codex/ChatGPT app is active;
- using the documented Windows UI Automation API to locate the Codex or ChatGPT Chat
  model and reasoning-effort picker;
- opening the picker through its documented UI Automation ExpandCollapse
  pattern and sending keyboard-accessible Enter and Left/Right Arrow input to
  focused picker controls after a user presses a configured shortcut;
- maintaining a notification-area icon and user-invoked local files.
- launching the packaged native update helper, which uses
  `Windows.Services.Store` only for the current ReasonKey package.

The AutoHotkey runtime imports generic `CreateProcessW` and `ShellExecuteExW`
APIs and contains built-in interpreter strings such as `Reg`, which can trigger
the optional WACK **Blocked executables** test. This application does not invoke
`reg.exe` or modify the registry. Its source-level process launches are limited
to user-invoked opening of Notepad for its own configuration/log and the
Windows Startup Apps settings URI. The exact source is public for review.

The checked-in Win32 manifest declares `dpiAware=true/pm` and
`dpiAwareness=PerMonitorV2, PerMonitor`. WACK 10.0.26100.8249 can report
`Failed to process the binary` for the Ahk2Exe output and then emit a DPI
warning. The embedded manifest was extracted from the packaged executable for
verification, and a runtime `GetProcessDpiAwareness` probe returned
`PROCESS_PER_MONITOR_DPI_AWARE` (`2`). This is a WACK processing limitation,
not an unaware runtime process.

UI Automation is constrained to the active Codex/ChatGPT process and specific picker
control types/names. The application does not inspect task messages,
conversation content, credentials, tokens, API keys, or unrelated windows. It
does not modify Codex or ChatGPT files or settings outside the visible picker.

## Data and network behavior

The runtime contains no telemetry, advertising, analytics, account system, or
OpenAI network client. On each launch, the Store-only native helper asks the
Windows Microsoft Store service for updates to the current ReasonKey package.
It installs silently only when the user's Store auto-update and network policy
permit it; it does not contact Rotorlash Labs or GitHub. ReasonKey stores only
`presets.ini`, a configuration reference, and a diagnostic log (including the
update outcome) in package `LocalState`. Uninstalling the MSIX removes this
package-owned data.

Source code, build instructions, privacy policy, security policy, and
third-party notices are public at:

https://github.com/nauroman/codex-model-hotkeys
