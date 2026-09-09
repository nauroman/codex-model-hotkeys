# Picker interaction and verification

Canonical owner of active-app targeting, composer detection, picker interaction
and selection success. Values belong to [configuration](configuration.md).
Read through the [product core](../product-spec.md).

## Rules

- Hotkeys operate only in the active supported desktop app. Tray-triggered
  selection must apply the same active-window guard. Do not overlap selections.
- Prefer the actual composer surface: the stable Select ChatGPT model Button
  identifies ordinary Chat; the Do anything / Work with ChatGPT editor
  identifies Work or Codex. Otherwise retain mode-switch detection for older
  Chat builds with combined model/effort Buttons.
- Preserve the unified picker, already-open compact/model-radio views, older
  compact Power view and already-expanded Advanced picker.
- Open the top-level Button with direct ExpandCollapse and verify expansion;
  retain the legacy fallback. Do not depend on a configurable picker shortcut.
- Follow keyboard focus to the popup's ancestor Menu when it is outside the main
  window UIA tree. Do not scan the full desktop tree.
- Use focus + Enter for view toggles and selectable options, focus + Left/Right
  Arrow for Power, and focus + Right Arrow for legacy Model/Effort flyout rows.
  Preserve this keyboard-accessible path without moving the mouse pointer.
- Wait for the Model parent row to update before opening Effort; wait for Effort
  to update before final verification. A UIA call returning without throwing
  proves nothing about the resulting UI.
- Final unified/Codex verification targets the actual Button and exact requested
  model/Power label, normalizing the optional GPT- prefix and Fast suffix. Do not accept stale
  descendant text. Keep bounded descendant/Advanced-row verification for the
  legacy stable Select ChatGPT model Button.
- Missing choices and failed transitions produce failure, not a substituted
  preset or a success log.

## Current implementation

Source inspection: 2026-09-08, working-tree [ReasonKey.ahk](../../src/ReasonKey.ahk) 1.0.10.

| Area | Source entry points / current accessible surface |
|---|---|
| Target process | IsSupportedAppWindow: chatgpt.exe under WindowsApps/OpenAI.Codex_ |
| Selection guard/result | SelectPreset: switching guard, requested/failed/selected log records |
| Composer | IsChatComposer: actual Chat/Work composer, then sidebar mode fallback |
| Unified popup | OpenPickerTrigger, GetPickerSearchRoot, SelectModernPickerPreset |
| Model view | Select model MenuItem; model RadioButton; focus + Enter |
| Power | Power MenuItem; clamp left, advance right, close and verify Button |
| Legacy Codex | SelectCombinedPreset; Show advanced options / Model / Effort rows |
| Legacy Chat | SelectChatPreset; Select ChatGPT model trigger and bounded verification |
| Exact result | WaitSelectedTriggerLabel, WaitSelectedChatTriggerValue |

FocusPickerElement confirms the focused accessible name before keyboard input.
Already-open Codex compact popups are closed with Escape and reopened only
after finding the actual Button. Recovery is bounded and every attempt retains
final model/effort verification.

The 26.903 unified picker can keep its Button in the tree with the placeholder
Select effort or Select model. FindCodexPickerTrigger accepts those names only
beside an actual Work/Codex editor; final verification still requires the exact
combined model/effort Button. GetPickerSearchRoot returns failure when neither
the focused popup nor a supplied target-window fallback is available, without
falling back to a desktop-wide scan.

Selectors recognize 5.6 Luna/Terra/Sol and GPT-6 Astra (also 6 Astra) through GetModelLabel,
GetModelOptionPattern and GetPickerTriggerPattern, including reopening the
picker and returning from Astra to a 5.6 model. This records source support,
not a claim that every account or desktop version exposes those
models. Labels are English and are not a public compatibility API.

## Validation and investigation

Ordinary Chat's unified picker retains a stable Button name. Verify its chosen
model via SelectionItemIsSelected on the model radio, then its independent
ChatEffort through the final Button's Text descendants or persisted Power
status. Do not require a combined Codex Button label on this surface.

Use the [real-window matrix](../DEVELOPMENT.md) for all supported starting states
and both composers. Record the desktop package version, runtime/source identity,
initial state, expected/actual Button or legacy row and matching log evidence.
Restore the diagnostic conversation's original mode/preset afterward.

When compatibility breaks, inspect the live UIA tree and available installed
webview source before changing selectors. Constrain searches by control type;
UIA-v2 array conditions are paths, not OR expressions. Use explicit polling for
alternative starting states. Delays alone do not establish correctness.

[Historical picker evidence](../diagnostics/picker-validation-history.md) contains
the earlier version-specific observations; it is not proof of the current build.
The [Astra validation report](../diagnostics/astra-validation-20260905.md)
separates earlier failures from 1.0.9 live selection and direct-upgrade evidence.
