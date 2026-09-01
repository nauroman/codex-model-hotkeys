# Development

## Repository layout

```text
src/ReasonKey.ahk               Runtime and UI Automation state machine
config/default-presets.ini      Default user configuration
installer/Setup.ahk             Per-user graphical installer source
installer/Uninstall.ps1         Installed uninstaller
assets/ReasonKey.ico            Multi-resolution application icon
scripts/Build.ps1               Reproducible local/CI build
scripts/Build-Msix.ps1          MakeAppx/SignTool MSIX build
scripts/Test-Msix.ps1           Packaged storage and launch validation
scripts/Test-SingleInstance.ps1 Cross-path runtime singleton validation
packaging/msix/                 Manifest, identity template, MSIX guide
packaging/store/                Store listing and certification materials
scripts/Invoke-WindowsAppCertification.ps1  WACK validation wrapper
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
dist/ReasonKey.exe
dist/ReasonKey-Setup.exe
dist/ReasonKey-Setup.exe.sha256
```

To exercise the local installer without its success dialog:

```powershell
.\scripts\Install-Latest.ps1 -Silent
```

## Run from source

With AutoHotkey v2 installed:

```powershell
& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' `
  '.\src\ReasonKey.ahk'
```

The source build reads `config/default-presets.ini`. The direct installed build
reads `%LOCALAPPDATA%\ReasonKey\presets.ini`. The MSIX build reads the
package's per-user `LocalState\ReasonKey\presets.ini`. Both channels migrate
the legacy `CodexModelHotkeys` configuration on first use.

## MSIX and Microsoft Store

The separate [MSIX packaging guide](../packaging/msix/README.md) covers local
signing/testing and the Partner Center identity build. `Build-Msix.ps1` creates
the manifest assets, packages with the installed Windows SDK `MakeAppx.exe`,
optionally signs with `SignTool.exe`, unpacks the result for structural
verification, and writes package/runtime hashes plus build metadata.

The Store package is intentionally unsigned when uploaded: Partner Center
signs it after certification. A signed local development package uses the
dedicated self-signed development certificate and must be trusted temporarily
in Local Computer -> Trusted People from an elevated PowerShell window.

## Required regression matrix

Test against an actual Codex/ChatGPT desktop window:

1. Codex, Advanced already enabled:
   - F16 → `5.6 Luna High`
   - F17 → `5.6 Sol Light`
   - F18 → `5.6 Sol Extra High`
   - F19 → `5.6 Sol Max`
2. Codex, compact/simple slider visible:
   - trigger any preset that requires a different value;
   - confirm `Show advanced options` is selected first;
   - confirm the final combined picker button.
3. Chat, Advanced already enabled with `Model 5.6 Sol`:
   - F16 → `5.6 Sol Instant`;
   - F17 → `5.6 Sol Medium`;
   - F18 → `5.6 Sol High`;
   - F19 → `5.6 Sol Pro`.
4. Chat, compact Power slider visible:
   - trigger any preset that requires a different value;
   - confirm `Show advanced options` is selected first;
   - confirm the final visible effort on the Chat picker button.
5. Reinstall over an existing version and confirm `presets.ini` is preserved.
6. Uninstall and confirm the runtime, startup shortcut, registry entry, presets,
   and log are removed.
7. MSIX channel:
   - run `Test-Msix.ps1` and confirm packaged validation exits with `0`;
   - confirm `presets.ini`, its reference, and the log use package `LocalState`;
   - confirm startup is disabled by default and can be enabled in Startup Apps;
   - uninstall and confirm package-owned data is removed.
8. Cross-channel singleton:
   - install or launch the direct and MSIX builds in both orders;
   - confirm exactly one `ReasonKey.exe` remains active;
   - confirm the second launch does not show another Quick Start window;
   - confirm the build-time copied-path probe reports
     `Cross-path singleton validation passed.`

Do not consider a UI Automation action successful only because it did not
throw. Verify the corresponding accessible state change.

## Release

1. Update `AppVersion` in runtime and installer.
2. Update `CHANGELOG.md`.
3. Run the regression matrix.
4. Tag `vX.Y.Z`.
5. Attach the setup executable and SHA-256 file to the GitHub release.
6. For a Store release, also complete
   `packaging/store/SubmissionChecklist.md` with the final Partner Center
   identity and Windows App Certification Kit report.

The setup asset name is stable because `Install.cmd` and the README link to the
latest release by that name.
