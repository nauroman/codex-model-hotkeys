# Installation and runtime lifecycle

Canonical owner of writable storage, migration, startup, singleton, onboarding
and uninstall. Preset values belong to [configuration](configuration.md); helper
behavior belongs to [Store updates](store-updates.md).

## Rules

- Public installation and normal use are per-user and non-admin. Development
  certificate trust is a separate local test procedure in the
  [MSIX guide](../../packaging/msix/README.md).
- Preserve existing destination presets.ini byte-for-byte during upgrades.
  Refresh presets-reference.ini from the shipped example; never edit the active
  configuration merely to update its comments.
- Store migration copies existing direct-install configuration without changing
  the original. Migration must not overwrite an existing destination.
- One current runtime per Windows session across direct, Store, redirected and
  renamed product paths. Acquire the shared mutex before configuration, hotkeys,
  tray or Quick Start; a losing launch exits.
- Legacy-runtime cleanup must recognize product paths, not just an executable
  name. Never stop/delete unrelated AutoHotkey scripts such as arrowkeys.ahk.
- Direct installation registers startup for the current user. Store startup is
  disabled by default and enabled by the user through Windows Startup Apps;
  do not create a Store Startup-folder shortcut.
- Use the runtime's shared Quick Start content for both channels. Preserve the
  black-key icon with green-and-white chevrons and tray access to configuration,
  reference guide, logs, Reload and Exit.
- Quick Start displays the loaded Codex presets, including user customizations.
- Setup waits for recognized previous runtimes to exit, then replaces the EXE.
  Completion requires the new version and PID's startup log after hotkey
  registration; a spawned process alone is insufficient.
- Direct uninstall removes recognized product data, startup shortcuts and HKCU
  uninstall entries, with resolved path guards. Windows owns Store uninstall.

## Current implementation

Source inspection: 2026-09-05, working-tree runtime and installer AppVersion 1.0.9.

| Surface | Current location / implementation |
|---|---|
| Direct writable directory | %LOCALAPPDATA%/ReasonKey |
| Packaged writable directory | %LOCALAPPDATA%/Packages/<package-family>/LocalState/ReasonKey |
| Source configuration | config/default-presets.ini (source logs still use the data directory) |
| Active/reference/log | presets.ini, presets-reference.ini, ReasonKey.log |
| Onboarding marker | quick-start-complete.txt; accepts legacy store-first-run-complete.txt |
| Update watcher copy | ReasonKey.StoreUpdater.exe in package data, when copied successfully |
| Setup log | %TEMP%/ReasonKey-Setup.log |
| Direct startup | current user's Startup/ReasonKey.lnk |
| Direct registry | HKCU/Software/Microsoft/Windows/CurrentVersion/Uninstall/ReasonKey |
| Mutex | Local\\RotorlashLabs.ReasonKey.Runtime |

InitializeConfigurationFiles in [ReasonKey.ahk](../../src/ReasonKey.ahk) tries,
only when packaged destination configuration is absent: package
LocalState/CodexModelHotkeys/presets.ini, direct ReasonKey/presets.ini, then legacy
direct CodexModelHotkeys/presets.ini. The first successful copy wins; otherwise
embedded defaults are installed. Direct runtime migration uses the legacy direct
candidate. Existing destination files always win.

[Setup.ahk](../../installer/Setup.ahk) migrates the legacy direct configuration
before removing the obsolete product directory, replaces the legacy startup
launcher CodexModelWheelLauncher.ahk and old Installed Apps entry, then launches
the runtime. Legacy development source lived at
%USERPROFILE%/.codex/CodexModelWheel.ahk with UIA-v2 under .codex/lib/UIA-v2;
these historical locations are not blanket deletion authority.

[Uninstall.ps1](../../installer/Uninstall.ps1) accepts only canonical ReasonKey,
legacy CodexModelHotkeys and their Codex-package LocalCache/Local redirected
directories. It does not replace Windows package removal.

The [release downloader](../../scripts/Install-Latest.ps1) runs
dist/ReasonKey-Setup.exe if present. Otherwise it downloads the latest GitHub
installer and checksum and verifies the downloaded bytes. The local-artifact
branch does not perform that downloaded-checksum comparison. Wait for the setup
process itself; its persistent runtime child makes Start-Process -Wait unsuitable.

## Validation

Use [Development](../DEVELOPMENT.md) for reinstall hash preservation, actual
uninstall, real cross-channel launches and source/packaged paths. Copied-path
singleton probes are isolated checks, not proof of Store migration or UI behavior.
