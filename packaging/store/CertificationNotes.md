# Notes for Microsoft Store certification

ReasonKey is an open-source, full-trust Win32 tray utility packaged as
MSIX. It requires no test account, product key, payment, network connection, or
administrator privileges to launch and inspect its tray menu, configuration,
privacy behavior, and quick-start window.

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

The same shortcuts must also be tested in a ChatGPT Chat composer. They select 5.6 Sol
and map configured effort levels to Chat's Instant, Medium, High, Extra High,
or Pro labels as documented in the public README.

No publisher-supplied Codex or OpenAI credentials are required or included.

## Restricted capability justification: runFullTrust

The package contains an AutoHotkey v2 Win32 desktop process and therefore
declares `runFullTrust`. Full trust is used only for:

- registering user-configured keyboard shortcuts while the Codex/ChatGPT app is active;
- using the documented Windows UI Automation API to locate the Codex or ChatGPT Chat
  model and reasoning-effort picker;
- sending keyboard-accessible Enter and Right Arrow input to the focused picker
  controls after a user presses a configured shortcut;
- maintaining a notification-area icon and user-invoked local files.

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
network client. It stores only `presets.ini`, a configuration reference, and a
diagnostic log in package `LocalState`. Uninstalling the MSIX removes this
package-owned data.

Source code, build instructions, privacy policy, security policy, and
third-party notices are public at:

https://github.com/nauroman/codex-model-hotkeys
