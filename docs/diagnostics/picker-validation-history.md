# Picker validation history

Historical evidence copied from PROJECT_CONTEXT.md during the 2026-09-05 documentation reorganization. These recorded observations are not a fresh test of the current source or installed desktop app. Current contracts live in [picker.md](../product-spec/picker.md); rerun [Development](../DEVELOPMENT.md) for release proof.

## Verified UI facts

Legacy Advanced-picker path validated on 2026-08-28 against:

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

The 2026-09-02 desktop update
`OpenAI.Codex_26.901.1978.0_x64__2p2nqsd0c76g0` unified the Codex and ChatGPT
picker accessibility surface:

```text
Button: 5.6 Sol Max
Menu: Select effort
MenuItem: Select model
MenuItem: Power (AcceleratorKey: ArrowLeft ArrowRight)
RadioButton: 5.6 Sol / 5.6 Terra / 5.6 Luna
```

The popup is attached to the desktop UIA root rather than the Codex window,
but opening it moves focus into the popup. Follow that focused element's
ancestors to the `Menu`; do not scan the full desktop accessibility tree.
`Select model` opens the radio view with focus + Enter. Selecting a model
returns to compact view, where Power is set with Left/Right arrows. The mode
switch Button (`Switch mode, current mode: Codex|ChatGPT`) now determines the
active composer because both modes use the same combined picker Button name.

Chat's existing `ChatEffort` configuration values remain Instant, Medium,
High, and Pro for backward compatibility. In the unified picker they map to
Light, Medium, High, and Max respectively.

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
10. Legacy Chat builds use the stable Button name `Select ChatGPT model`; keep
    that selector and bounded final-effort verification as a fallback.
11. Current Chat and Codex use identical combined picker labels. Detect Chat
    from `Switch mode, current mode: ChatGPT`, not from the picker Button.
12. In 26.901 the generic UIA-v2 `Click()` races the Button's new
    `ExpandCollapse` implementation. Call `Expand()` directly and confirm its
    state before reading the focused popup.
13. The 26.901 popup disappears from the main window UIA tree and removes the
    trigger while open. Follow focus to its ancestor Menu so both compact and
    already-open model views remain valid starting states.

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

On 2026-09-02, the updated development script completed the current unified
picker matrix in a real idle task:

```text
Codex: F16 Luna High, F17 Sol Light, F18 Sol Extra High, F19 Sol Max
Chat:  F16 Sol Light, F17 Sol Medium, F18 Sol High, F19 Sol Max
Already-open compact view -> Sol Max
Already-open model radio view -> Luna High
```

