# Project context for continued Codex work

## Goal

Provide **ReasonKey**, an easy public Windows utility that switches model and
effort presets in both the Codex and ChatGPT Chat composers. The original Codex presets
are:

- F16: GPT-5.6 Luna High
- F17: GPT-5.6 Sol Light
- F18: GPT-5.6 Sol Extra High (`xhigh`)
- F19: GPT-5.6 Sol Max

Ctrl+Alt+mouse-wheel preset cycling was removed on 2026-08-28 because it was
unreliable and not needed. Existing installed `presets.ini` files remain
preserved during upgrades, but the runtime ignores the old `CycleUp` and
`CycleDown` keys.

The repository also maintains an MSIX/Microsoft Store channel under the
**ReasonKey** product name and **Rotorlash Labs** publisher. It shares the
compiled runtime, uses package `LocalState` for writable configuration/logs,
migrates but does not delete an existing direct-install configuration, and
registers an optional startup task disabled by default. Store identity values
must come exactly from Partner Center; never invent or commit them.

The public name changed from **Codex Model Hotkeys** to **ReasonKey** before
the first Store submission. New artifacts, paths, and application metadata use
`ReasonKey`; upgrade paths preserve `presets.ini` from the legacy
`CodexModelHotkeys` data directory.

## Local project

Canonical repository working directory:

```text
C:\Users\user\Documents\Codex\codexmodelhotkeys
```

The earlier development installation used:

```text
C:\Users\user\.codex\CodexModelWheel.ahk
C:\Users\user\.codex\lib\UIA-v2
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\CodexModelWheelLauncher.ahk
```

The public installer migrates away from the legacy startup launcher. Do not
delete unrelated AutoHotkey scripts such as the user's `arrowkeys.ahk`.

## Verified UI facts

Validated on 2026-08-28 against:

```text
OpenAI.Codex_26.825.4187.0_x64__2p2nqsd0c76g0
```

Accessible picker button examples:

```text
5.6 Luna High
5.6 Sol Light
5.6 Sol Extra High
5.6 Sol Max
```

Compact mode exposes:

```text
Show advanced options
```

Advanced mode exposes MenuItem controls:

```text
Show compact options
Model 5.6 Sol
Effort Extra High
Speed Standard
```

Model submenu options include `5.6 Sol`, `5.6 Terra`, and `5.6 Luna`. Effort
submenu options include `Light`, `Medium`, `High`, `Extra High`, `Max`, and
sometimes `Ultra` with additional descriptive text.

The 2026-08-29 Chat composer in desktop package
`OpenAI.Codex_26.825.5331.0_x64__2p2nqsd0c76g0` differs from Codex:

```text
Button: Select ChatGPT model
Advanced row: Model 5.6 Sol
Advanced row: Effort Instant
Compact visible value examples: Instant, Extra High
```

Chat exposes `Instant`, `Medium`, `High`, `Extra High`, and `Pro`, but the four
default hotkeys intentionally use an independent sequence: F16 → Instant,
F17 → Medium, F18 → High, and F19 → Pro. Their Codex selections remain Luna
High, Sol Light, Sol Extra High, and Sol Max. Both Chat screenshots confirmed
the expanded Advanced rows and the compact Power-slider state.

## Root causes already solved

1. Codex desktop did not honor an attempted `.codex/keybindings.json` solution.
2. The picker shortcut can be customized, so the runtime opens the accessible
   picker button directly instead of sending Ctrl+Shift+M.
3. UIA-v2 treats an array condition as a path, not an OR expression; the runtime
   has an explicit polling helper for multiple possible initial states.
4. Accessible names use `5.6 Sol`, not necessarily `GPT-5.6 Sol`.
5. A broad regex selected inner text instead of the clickable MenuItem. Selectors
   are constrained by control type.
6. Model and Effort are `FlyoutSubmenuItem` React controls. UIA `Click()` can
   report success without opening them. Use focus + Right Arrow.
7. The compact/advanced view toggle can also ignore a reported UIA click. Use
   focus + Enter.
8. React retains stale text nodes during transitions. Final verification must
   match the real Button control and wait for the exact target label.
9. Wait for the Model parent row to update before opening Effort; then wait for
   the Effort row to update before final verification.
10. Chat's Button has the stable accessible name `Select ChatGPT model`, so it
    cannot be discovered or verified with the Codex combined-label selector.
    Detect it explicitly, then bound final effort-text verification to that
    real Button. If its aria-label suppresses child Text controls, reopen the
    same Button and confirm the persisted Effort parent row.

## Last verified runtime evidence

The development script completed these end-to-end transitions with final
`selected=` log records:

```text
F18 -> 5.6 Sol Extra High
F19 -> 5.6 Sol Max
F16 -> 5.6 Luna High
F17 -> 5.6 Sol Light
```

It also completed compact/simple mode to Advanced to `5.6 Sol Max`, including:

```text
option-select=Show advanced options
submenu-open=Model 5.6 Sol
option-select=Max
selected=5.6 Sol Max
```

## Third-party dependency

UIA-v2 by Descolada is vendored at commit:

```text
2846a9b10518a95cf26a6c43671a9512b231ccb7
```

Upstream: https://github.com/Descolada/UIA-v2

License: MIT. Preserve `vendor/UIA-v2/LICENSE` and
`THIRD_PARTY_NOTICES.md` when updating it.

## Compatibility warning

Codex UI Automation labels are not a documented public API. When a desktop app
update breaks a selector, inspect the live UIA tree and the installed webview
source before changing behavior. Preserve support for both initial picker modes
and validate real state changes rather than compensating with delays alone.

## Store release boundary

The Partner Center product name **ReasonKey** is reserved under **Rotorlash
Labs**. Its exact Package/Identity Name, Publisher ID, and publisher display
name are stored only in the gitignored `packaging/msix/StoreIdentity.json`.
The repository contains the MSIX manifest template, generated-asset pipeline,
local signing/test scripts, privacy policy, English listing copy, certification
notes, and submission checklist. The unsigned Store-identity package has been
built. The elevated packaged-runtime test passed with exit code `0`. WACK
10.0.26100.8249 completed with overall `WARNING`, not `FAIL`: its optional
blocked-executable test detected generic AutoHotkey runtime strings/APIs, and
its DPI analyzer could not process the Ahk2Exe binary. The checked-in
certification notes explain both findings, while a runtime probe of the exact
manifest-updated packaged executable confirmed
`PROCESS_PER_MONITOR_DPI_AWARE` (`2`). The real Codex/ChatGPT regression
matrix, Partner Center listing entry, package upload, certification, and public
post-certification validation remain separate gates.
