# Changelog

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
