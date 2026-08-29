# Changelog

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
