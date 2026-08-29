# Development

## Repository layout

```text
src/CodexModelHotkeys.ahk       Runtime and UI Automation state machine
config/default-presets.ini      Default user configuration
installer/Setup.ahk             Per-user graphical installer source
installer/Uninstall.ps1         Installed uninstaller
assets/CodexModelHotkeys.ico    Multi-resolution application icon
scripts/Build.ps1               Reproducible local/CI build
scripts/Install-Latest.ps1      Checksum-verifying release downloader
vendor/UIA-v2/                  Pinned third-party UIA library
docs/PROJECT_CONTEXT.md         Exact history and continuation context
```

## Build

Run from PowerShell:

```powershell
.\scripts\Build.ps1 -Clean
```

The script uses an installed AutoHotkey v2 when available. Otherwise it
downloads the official portable AutoHotkey v2 release. It also downloads the
official Ahk2Exe compiler when needed. Temporary build dependencies live in
`.tools/` and are ignored by Git.

Outputs:

```text
dist/CodexModelHotkeys.exe
dist/CodexModelHotkeys-Setup.exe
dist/CodexModelHotkeys-Setup.exe.sha256
```

To exercise the local installer without its success dialog:

```powershell
.\scripts\Install-Latest.ps1 -Silent
```

## Run from source

With AutoHotkey v2 installed:

```powershell
& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' `
  '.\src\CodexModelHotkeys.ahk'
```

The source build reads `config/default-presets.ini`. The installed build reads
`%LOCALAPPDATA%\CodexModelHotkeys\presets.ini`.

## Required regression matrix

Test against an actual Codex desktop window:

1. Advanced already enabled:
   - F16 → `5.6 Luna High`
   - F17 → `5.6 Sol Light`
   - F18 → `5.6 Sol Extra High`
   - F19 → `5.6 Sol Max`
2. Compact/simple slider visible:
   - trigger any preset that requires a different value;
   - confirm `Show advanced options` is selected first;
   - confirm the final combined picker button.
3. Reinstall over an existing version and confirm `presets.ini` is preserved.
4. Uninstall and confirm the runtime, startup shortcut, registry entry, presets,
   and log are removed.

Do not consider a UI Automation action successful only because it did not
throw. Verify the corresponding accessible state change.

## Release

1. Update `AppVersion` in runtime and installer.
2. Update `CHANGELOG.md`.
3. Run the regression matrix.
4. Tag `vX.Y.Z`.
5. Attach the setup executable and SHA-256 file to the GitHub release.

The setup asset name is stable because `Install.cmd` and the README link to the
latest release by that name.
