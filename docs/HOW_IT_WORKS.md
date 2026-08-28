# How it works

## Purpose

Codex Model Hotkeys selects a complete preset: a model and its reasoning effort.
It exists because changing only the model is insufficient when a user routinely
switches between combinations such as Luna High, Sol Light, Sol Extra High, and
Sol Max.

## Runtime flow

1. A configured hotkey fires only when the active process is the Codex Windows
   desktop app.
2. The script finds the visible picker button, whose accessible name contains
   the current combined value, for example `5.6 Sol Extra High`.
3. If that value already matches the target, the menu is closed and the
   operation succeeds without redundant selections.
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
9. The menu closes and the script verifies the actual picker **Button** has the
   exact final combined label.

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
Button control and waits for the target label.

## Configuration

The installed `presets.ini` is loaded at startup. Each preset becomes a dynamic
AutoHotkey hotkey. Invalid sections are skipped and invalid hotkey expressions
are written to the log. If no valid presets remain, the built-in defaults are
used.

New installations receive the fully commented default file as `presets.ini`.
Every installation also receives `presets-reference.ini`, which is refreshed
on upgrades and can be opened from the tray menu. The active `presets.ini` is
never overwritten during an upgrade.

## Boundaries

- No Codex configuration file is modified.
- No OpenAI API key is used.
- No network request is made by the runtime.
- The installer/release downloader uses GitHub only to obtain release files.
- Compatibility depends on accessible English labels exposed by the desktop UI.
