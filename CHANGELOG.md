# Changelog

## 1.0.10 - 2026-09-09

- Recognize the 26.903 open-picker Select effort / Select model Button beside
  a Codex or ChatGPT Work editor, retaining exact final model/effort verification.
- Bound popup discovery to keyboard focus and the target window; remove the
  full-desktop fallback when popup focus is lost.
- Clarify Astra Light/Medium/High/Extra High presets for Codex and ChatGPT Work,
  ordinary Chat's separate Sol catalog, and preserved Store versus EXE settings.
- Show the active installation channel in Quick Start's configuration guidance.

## 1.0.9 - 2026-09-05

- Set the final Codex F19 default to Astra Extra High per the updated user
  selection; F16-F18 remain Light/Medium/High and Chat retains its own presets.
- Restore ordinary Chat's independent Instant/Medium/High/Pro presets on Sol.
  Verify the selected model radio and the stable Chat Button's effort text,
  with a persisted Power-status fallback when descendants are hidden.
- Detect the actual composer before the sidebar mode so Work/Codex selections
  remain independent from ordinary Chat settings.
- Verify keyboard focus before selecting options or changing Power. Normalize
  an already-open Codex popup through its actual Button, with a bounded retry
  if the reopened selection fails final verification.
- Update onboarding and configuration guidance for both Chat picker variants.
- Fix reinstall's already-exited-process race: check process existence after
  waiting instead of treating a zero wait return as a failure.

## 1.0.8 - 2026-09-05

- Fix the real `GPT-6 Astra` Button label: accept the GPT prefix and normalize
  it before exact model/effort verification.
- Set new-install defaults to Astra Light, Medium, High and Max on F16-F19.
  Existing installed presets remain preserved by upgrades.
- Show the loaded Codex presets in Quick Start instead of hard-coded defaults.
- Wait for the old runtime to stop and for the new version/PID to confirm
  startup before the installer reports completion. Log the active config path.

## 1.0.7 - 2026-09-05

- Add `Model=Astra` for GPT-6 Astra, including model options, legacy Advanced
  rows, and opening/reopening/verifying the `6 Astra` picker Button.
- Recognize Astra when switching back to Luna, Terra, or Sol. Preserve existing
  presets, ChatEffort mappings, and keyboard-accessible picker interactions.
- Extend build-time validation across all four models and six effort labels,
  including Fast labels and rejection of mismatched model generations.

## 1.0.6 - 2026-09-02

- Check Microsoft Store for an updated ReasonKey package whenever the active
  Store runtime starts, using the official `Windows.Services.Store` API.
- Download and install an available Store update silently when Windows permits
  it under the user's Microsoft Store auto-update and network settings.
- Register the packaged runtime with Windows Restart Manager before applying an
  update, and add a bounded activation fallback so ReasonKey returns to the
  notification area after a successful package replacement.
- Keep the direct EXE channel offline: the Store updater is built and packaged
  only in MSIX, and never runs without the exact public ReasonKey package
  identity.

## 1.0.5 - 2026-09-02

- Restore compatibility with Codex desktop 26.901's unified model/Power picker
  by opening the top-level Button through its `ExpandCollapse` pattern and
  following focus into the desktop-level accessibility popup.
- Support both the compact view and an already-open model radio view without
  relying on the picker trigger remaining in the main window UIA tree.
- Detect ChatGPT from the app's visible mode switch now that Chat and Codex use
  the same combined picker Button labels. Preserve existing Instant/Pro
  `ChatEffort` configuration by mapping it to the current Light/Max endpoints.
- Avoid the multi-second full-desktop UIA scan introduced by the new popup and
  continue verifying the final model/Power Button before reporting success.
- Update Quick Start, configuration guidance, Store copy, and regression notes
  for the current picker labels while retaining the legacy Advanced path.

## 1.0.4 - 2026-09-01

- Prevent the Microsoft Store, direct-installer, package-redirected, and legacy
  runtime paths from running more than one ReasonKey instance in the same
  Windows session by using one shared named mutex. The new runtime also stops
  an already-running 1.0.3 process from either channel during the upgrade.
- Use the runtime's current Quick Start window after a direct installation as
  well as on the first Store launch, removing the duplicated installer guide
  that still described the pre-ChatGPT product.
- Add compiled cross-path singleton validation that launches two copies from
  different directories and requires the second copy to exit.

- Rename the product, executable, installer, MSIX application, data directory,
  logs, and release artifacts from Codex Model Hotkeys to ReasonKey under the
  Rotorlash Labs publisher name. Preserve existing `presets.ini` during the
  direct-installer and Store migration.
- Support both Chat picker layouts, including its `Select ChatGPT model`
  trigger, `5.6 Sol` model row, compact Power slider, Advanced rows, and
  Instant/Medium/High/Extra High/Pro effort names. Default Chat hotkeys use an
  independent Instant/Medium/High/Pro sequence while Codex presets stay intact.
- Add a reproducible x64 MSIX build with generated manifest assets, package and
  runtime hashes, local development signing, packaged-runtime validation, and a
  Windows App Certification Kit wrapper.
- Store writable configuration and logs in package `LocalState`, preserve an
  existing direct-install configuration on first Store launch, and register an
  optional startup task disabled by default.
- Add a first-run quick-start window, privacy policy, Store listing copy,
  certification notes, identity template, submission checklist, and CI MSIX
  artifact.

## 1.0.3 - 2026-08-28

- Replace the default AutoHotkey tray icon with the custom black key and
  green-and-white effort chevrons in the runtime, installer, shortcuts, and
  Windows app listing.
- Remove both canonical and Codex package-redirected per-user files during
  uninstall while retaining strict path validation.

## 1.0.2 - 2026-08-28

- Replace the terse installer success message with a beginner-friendly guide
  covering shortcuts, tray icon discovery, configuration, reload, and logs.
- Add comprehensive inline documentation to the default `presets.ini`.
- Install an always-current `presets-reference.ini` and expose it in the tray
  menu without overwriting the user's active configuration during upgrades.

## 1.0.1 - 2026-08-28

- Remove configurable Ctrl+Alt+mouse-wheel preset cycling.
- Remove the obsolete mouse-wheel cycling claim from the installer success
  message and published default configuration.
- Recover when a model option closes the parent picker and accept descriptive
  `Ultra` accessibility labels.
- Restrict upgrade/uninstall process termination to the installed runtime,
  including Codex package-redirected paths, and validate those path rules.

## 1.0.0 - 2026-08-28

- Add complete model + reasoning-effort presets for F16–F19.
- Add configurable Ctrl+Alt+wheel preset cycling.
- Support both compact/simple and Advanced Codex picker modes.
- Use verified keyboard-accessible interaction for React flyout menus.
- Add per-user one-click installer, startup integration, tray menu, logs, and
  Windows uninstaller.
- Add configurable `presets.ini`, public documentation, build tooling, and
  vendored UIA-v2 attribution.
