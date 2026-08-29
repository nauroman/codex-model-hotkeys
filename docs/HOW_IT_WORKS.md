# How it works

## Purpose

ReasonKey selects a complete preset in either the Codex or ChatGPT Chat
composer. It exists because changing only the model is insufficient when a user
routinely switches between combinations such as Luna High, Sol Light, Sol Extra
High, and Sol Max.

## Runtime flow

1. A configured hotkey fires only when the active process is the Codex/ChatGPT
   Windows desktop app.
2. The script detects the visible picker button. Codex names this Button with
   the combined value, for example `5.6 Sol Extra High`; Chat names it
   `Select ChatGPT model` and exposes the visible effort inside the Button.
3. In ChatGPT Chat, the preset's independent `ChatEffort` selects a `5.6 Sol` option.
   The default F16-F19 values are Instant, Medium, High, and Pro. The preset's
   Codex Model and Effort are not changed or remapped.
4. The picker can be in one of two modes:
   - **Compact/simple:** a Power slider and `Show advanced options` are visible.
   - **Advanced:** `Model …`, `Effort …`, and `Speed …` rows are visible.
5. In compact mode the script focuses `Show advanced options` and presses
   `Enter`. In advanced mode this step is skipped.
6. `Model …` and `Effort …` are flyout submenu triggers. The script focuses each
   row and presses `Right Arrow` to open it.
7. The requested model and effort options are focused and selected with
   `Enter`.
8. After each choice, the parent row must update before the script proceeds.
9. The menu closes and the script verifies the actual picker **Button**. Codex
   must have the exact combined Button label; Chat must retain its specific
   Button and expose the selected effort as its current visible child.

## Why the keyboard path is intentional

The Codex picker uses Radix/React flyout components. A UI Automation `Click()`
can return success while the flyout remains closed. During development this
caused misleading logs such as “element click succeeded” followed by “Luna
option missing.”

The verified interaction is:

- view toggle and selectable options: `SetFocus()` + `Enter`;
- Model/Effort flyout rows: `SetFocus()` + `Right Arrow`;
- top-level picker button: UI Automation click.

This path also avoids moving the user's mouse pointer.

## Why final verification uses `Type=Button`

React can temporarily retain old descendant text nodes during transitions. An
untyped search once read a stale `Luna High` node after the real button had
already changed to `Sol Light`. The final selector is constrained to the actual
Button control. For Chat, the selected effort search is further bounded to the
real `Select ChatGPT model` Button rather than the entire window. If Chromium
makes that Button's text descendants presentational, the script reopens the
same Button and verifies the persisted `Effort …` parent row before succeeding.

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

## Boundaries

- No Codex or ChatGPT configuration file is modified.
- No OpenAI API key is used.
- No network request is made by the runtime.
- The installer/release downloader uses GitHub only to obtain release files.
- The Microsoft Store owns MSIX signing, installation, updates, and uninstall.
- Compatibility depends on accessible English labels exposed by the desktop UI.
