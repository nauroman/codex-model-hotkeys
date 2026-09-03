# How it works

## Purpose

ReasonKey selects a complete preset in either the Codex or ChatGPT Chat
composer. It exists because changing only the model is insufficient when a user
routinely switches between combinations such as Luna High, Sol Light, Sol Extra
High, and Sol Max.

## Runtime flow

1. A configured hotkey fires only when the active process is the Codex/ChatGPT
   Windows desktop app.
2. The script reads the visible mode switch to distinguish Codex from ChatGPT;
   the current app uses the same combined picker Button label in both modes,
   for example `5.6 Sol Extra High`.
3. The top-level Button is opened with its UI Automation `ExpandCollapse`
   pattern. The current Radix popup lives outside the main window's UIA tree,
   so ReasonKey follows keyboard focus to the popup instead of scanning the
   whole desktop.
4. In the current unified picker, `Select model` opens the model radio view
   with focus + `Enter`. The model option is also chosen with focus + `Enter`.
   The compact `Power` row is focused, clamped with `Left Arrow`, then advanced
   to the requested stop with `Right Arrow`.
5. If the current compact picker or model view is already open, its focused
   popup is used directly; the missing top-level trigger is not treated as a
   failure.
6. Older builds remain supported. Their compact `Show advanced options` toggle
   uses focus + `Enter`, while Advanced `Model …` and `Effort …` flyout rows
   use focus + `Right Arrow`; the requested options use focus + `Enter`.
7. In ChatGPT, the preset's independent legacy `ChatEffort` remains compatible:
   Instant, Medium, High, and Pro map to the current Light, Medium, High, and
   Max Power labels while selecting 5.6 Sol.
8. The menu closes and the script verifies the actual picker **Button** and its
   exact model/Power label before reporting success.

## Why the keyboard path is intentional

The picker uses Radix/React flyout components. A generic UI Automation
`Click()` can report success while the flyout remains closed. In 26.901 it can
also invoke multiple fallback patterns before React updates. ReasonKey now uses
the Button's direct `ExpandCollapse` pattern and confirms that it expanded.

The verified interaction is:

- top-level picker Button: direct `ExpandCollapse` (legacy click fallback);
- view toggles and selectable options: `SetFocus()` + `Enter`;
- current Power row: `SetFocus()` + `Left/Right Arrow`;
- legacy Model/Effort flyout rows: `SetFocus()` + `Right Arrow`.

This path also avoids moving the user's mouse pointer.

## Why final verification uses `Type=Button`

React can temporarily retain old descendant text nodes during transitions. An
untyped search once read a stale `Luna High` node after the real button had
already changed to `Sol Light`. The final selector is constrained to the actual
Button control and strips only the optional `Fast` suffix before comparing the
model and Power label. On older Chat builds whose Button is named
`Select ChatGPT model`, ReasonKey retains the bounded descendant/Advanced-row
verification path.

## Configuration

The installed `presets.ini` is loaded at startup. Each preset becomes a dynamic
AutoHotkey hotkey. Invalid sections are skipped and invalid hotkey expressions
are written to the log. If no valid presets remain, the built-in defaults are
used.

New installations receive the fully commented default file as `presets.ini`.
Every installation also receives `presets-reference.ini`, which is refreshed
on upgrades and can be opened from the tray menu. The active `presets.ini` is
never overwritten during an upgrade.

The direct installer stores editable files under
`%LOCALAPPDATA%\ReasonKey`. The MSIX runtime detects its package
identity and instead uses its per-user package
`LocalState\ReasonKey` directory because the WindowsApps installation
directory is read-only. On its first Store launch, it copies an existing direct
install `presets.ini` into `LocalState` without changing the original. Both
the direct installer and Store build also migrate `presets.ini` from the
legacy `%LOCALAPPDATA%\CodexModelHotkeys` location used before the ReasonKey
rename.

The Store manifest registers a disabled-by-default startup task. The user can
enable it through Windows Startup Apps from the first-run guide or tray menu;
the package does not create its own Startup-folder shortcut.

## Microsoft Store updates

The public Store package includes a small native helper that uses the official
`Windows.Services.Store` API. Whenever the active Store runtime starts, the
helper checks for updates associated with the current ReasonKey package
identity. If an update is available and Windows permits silent Store updates,
the helper asks Windows to download and install it. The direct EXE build does
not contain or launch this helper.

Before the check begins, the packaged runtime calls
`RegisterApplicationRestart` with update restart enabled and crash, hang, and
reboot restarts disabled. Package deployment normally terminates the running
app while replacing it; Windows Restart Manager then returns ReasonKey to the
notification area. A separate bounded activation fallback covers the path in
which the Store operation completes without terminating the runtime.

Silent installation remains governed by the user's Microsoft Store
auto-update setting, metered-network policy, battery state, and Store service
availability. ReasonKey records only the outcome in its local diagnostic log,
does not bypass those policies, and checks again on the next launch.

## One runtime across both installation channels

The direct installer, Microsoft Store package, Codex-package-redirected path,
and renamed legacy product all represent the same runtime. ReasonKey 1.0.4 and
later acquire the same per-session Windows named mutex before initializing
configuration, hotkeys, the tray icon, or Quick Start. A launch from another
path exits immediately when that mutex already exists.

During the 1.0.3-to-1.0.4 transition, the first new runtime also terminates only
recognized ReasonKey or `CodexModelHotkeys.exe` product paths. It never stops
unrelated AutoHotkey scripts. The direct installer uses the runtime's own Quick
Start window, so Store and EXE installations no longer maintain separate copies
of the onboarding text.

## Boundaries

- No Codex or ChatGPT configuration file is modified.
- No OpenAI API key is used.
- The direct runtime makes no network request. The public Store package uses
  Windows Store services only to check for and install ReasonKey updates.
- The installer/release downloader uses GitHub only to obtain release files.
- Microsoft Store owns MSIX signing, package delivery, update policy, and
  uninstall; ReasonKey only requests its own Store update through the supported
  Windows API.
- Compatibility depends on accessible English labels exposed by the desktop UI.
