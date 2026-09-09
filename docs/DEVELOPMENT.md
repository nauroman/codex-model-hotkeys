# Development

Canonical owner of build commands, regression requirements and release evidence.
Read the [product core](product-spec.md), affected owners and
[source map](PROJECT_CONTEXT.md) before changing behavior.

## Repository layout

```text
src/ReasonKey.ahk               Runtime and UI Automation state machine
config/default-presets.ini      Default user configuration
installer/Setup.ahk             Per-user graphical installer source
installer/Uninstall.ps1         Installed uninstaller
assets/ReasonKey.ico            Multi-resolution application icon
scripts/Build.ps1               Local/CI build (toolchain is not pinned)
scripts/Build-Msix.ps1          MakeAppx/SignTool MSIX build
scripts/Build-StoreUpdater.ps1  Native Windows Store update helper build
scripts/Test-Msix.ps1           Packaged storage and launch validation
scripts/Test-SingleInstance.ps1 Cross-path runtime singleton validation
packaging/msix/                 Manifest, identity template, MSIX guide
packaging/store/                Store listing and certification materials
scripts/Invoke-WindowsAppCertification.ps1  WACK validation wrapper
scripts/Install-Latest.ps1      Checksum-verifying release downloader
vendor/UIA-v2/                  Pinned third-party UIA library
docs/product-spec.md            Product core and owner routing
docs/PROJECT_CONTEXT.md         Concise source and validation map
docs/diagnostics/               Historical, version-specific evidence
scripts/Test-Documentation.ps1  Static documentation validation
```

## Proportional validation

| Change | Required evidence |
|---|---|
| Documentation only | Test-Documentation.ps1 and git diff --check; no runtime build required |
| Presets or selectors | Source/compiled validation plus affected real-window matrix cases |
| Installation or singleton | Clean build plus actual preservation, removal and cross-channel checks |
| Store helper or packaging | Clean direct/MSIX builds, helper/package checks, affected real update/restart gates |
| Release | Clean build and complete applicable matrix below; Store submission checklist when applicable |

Run from the repository root:

```powershell
.\scripts\Test-Documentation.ps1
git diff --check
```

Record source commit/dirty state, runtime/package hashes, desktop app version,
date, starting state, expected/actual result and log/report location. Separate
source inspection, isolated validation and real UI/install/update proof. Mark
unavailable gates unverified; historical checks do not validate a new release.

## Build

Run from PowerShell:

```powershell
.\scripts\Build.ps1 -Clean
```

The script uses an installed AutoHotkey v2 when available. Otherwise it
downloads the official portable AutoHotkey v2 release. It also downloads the
official Ahk2Exe compiler when needed. Temporary build dependencies live in
`.tools/` and are ignored by Git.

Toolchain versions are not pinned, so rebuilds need not be byte-identical to a
published asset. Build.ps1 runs compiled runtime/installer --validate checks,
the isolated copied-path singleton probe and uninstaller -Validate path guards,
then writes the installer SHA-256. It does not test the picker or install/remove
the actual product.

Outputs:

```text
dist/ReasonKey.exe
dist/ReasonKey-Setup.exe
dist/ReasonKey-Setup.exe.sha256
```

After a successful build, exercise the local installer without requesting Quick
Start (this installs the utility and starts its runtime):

```powershell
.\scripts\Install-Latest.ps1 -Silent
```

The script prefers dist/ReasonKey-Setup.exe; if absent, it downloads and verifies
the latest public installer. Confirm the local artifact exists when testing this
checkout; see [installation](product-spec/installation.md).

## Run from source

With AutoHotkey v2 installed:

```powershell
& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' `
  '.\src\ReasonKey.ahk'
```

Source mode reads config/default-presets.ini. Other writable paths and migration
precedence belong to [installation](product-spec/installation.md). Append
--validate to the command above for built-in source checks only. Normal source
launch participates in the runtime singleton and writes local diagnostics.

## MSIX and Microsoft Store

The separate [MSIX packaging guide](../packaging/msix/README.md) covers local
signing/testing and the Partner Center identity build. `Build-Msix.ps1` creates
the native Store update helper with MSVC, creates the manifest assets, packages
with the installed Windows SDK `MakeAppx.exe`, optionally signs with
`SignTool.exe`, unpacks the result for structural verification, and writes
package/runtime/helper hashes plus build metadata. MSIX builds therefore need
Visual Studio Build Tools with the Desktop development with C++ workload and
Windows SDK 10.0.26100.0; the direct EXE build does not.

The Store package is intentionally unsigned when uploaded: Partner Center
signs it after certification. A signed local development package uses the
dedicated self-signed development certificate and must be trusted temporarily
in Local Computer -> Trusted People from an elevated PowerShell window.

## Required regression matrix

Test against an actual Codex/ChatGPT desktop window:

The values below are acceptance fixtures for the
[configuration contract](product-spec/configuration.md). Preserve the active
user INI and restore any deliberately changed composer mode/preset afterward.

1. Current unified picker in Codex, starting closed:
   - F16 → `GPT-6 Astra Light`
   - F17 → `GPT-6 Astra Medium`
   - F18 → `GPT-6 Astra High`
   - F19 → `GPT-6 Astra Extra High`
2. Current unified picker in Codex, starting already open:
   - from compact `Select model` / `Power`, trigger a different preset;
   - from the model radio view, trigger a different preset;
   - confirm the final combined picker Button in both cases.
   - with a temporary `Model=Astra` preset, exercise Light, Medium, High,
     Extra High, Max, and Ultra (where available); expect `6 Astra <effort>`;
   - repeat Astra selection from compact and model radio views, then switch
     back to Luna or Sol, confirming the actual Button after each transition.
3. Current unified picker in ChatGPT:
   - distinguish ordinary Chat from ChatGPT Work; Work uses the Codex Astra
     fixtures above, while ordinary Chat must expose the separate Sol catalog;
   - F16 → `5.6 Sol Instant` (or Light on older combined-label pickers);
   - F17 → `5.6 Sol Medium`;
   - F18 → `5.6 Sol High`;
   - F19 → `5.6 Sol Pro` (or Max on older combined-label pickers);
   - confirm the ordinary Chat composer is detected independently from Work and is
     restored to Codex after any diagnostic test.
4. Legacy picker compatibility (when an older supported app build is
   available):
   - compact `Show advanced options` uses focus + Enter;
   - Advanced `Model …` / `Effort …` rows use focus + Right Arrow;
   - legacy Chat maps F16-F19 to Instant, Medium, High, and Pro;
   - confirm the final Button/parent-row state rather than trusting a UIA call.
5. Reinstall over an existing version and confirm `presets.ini` is preserved.
   Compare SHA-256 before/after; confirm the reference guide refreshes.
6. Uninstall and confirm the runtime, startup shortcut, registry entry, presets,
   and log are removed.
7. MSIX channel:
   - run `Test-Msix.ps1` and confirm packaged validation exits with `0`;
   - confirm `presets.ini`, its reference, and the log use package `LocalState`;
   - confirm startup is disabled by default and can be enabled in Startup Apps;
   - confirm `ReasonKey.StoreUpdater.exe --package-probe` succeeds inside the
     installed package and that a public Store launch logs an update check;
   - for a real Store update, confirm the old process is replaced and ReasonKey
     returns to the notification area on the new package version;
   - uninstall and confirm package-owned data is removed.
8. Cross-channel singleton:
   - install or launch the direct and MSIX builds in both orders;
   - confirm exactly one `ReasonKey.exe` remains active;
   - confirm the second launch does not show another Quick Start window;
   - confirm the build-time copied-path probe reports
     `Cross-path singleton validation passed.`
9. Failure and input boundaries:
   - shortcuts do not act in another application;
   - unavailable model/effort reports failure without a false selected record;
   - invalid hotkey syntax logs invalid-hotkey; distinguish parsing fallback
     from registration failure using the configuration owner;
   - unrelated AutoHotkey scripts survive migration/removal.

Do not consider a UI Automation action successful only because it did not
throw. Verify the corresponding accessible state change.

## Release

Recorded [1.0.10 release evidence](diagnostics/release-1.0.10.md) and earlier
[Astra development evidence](diagnostics/astra-validation-20260905.md) are
separate from these reusable release gates.

### Release steps

1. Update `AppVersion` in runtime and installer.
2. Update `CHANGELOG.md`.
3. Run scripts/Build.ps1 -Clean, then the regression matrix against the final
   artifacts. Retain matching evidence and record unavailable gates explicitly.
4. Tag `vX.Y.Z`.
5. Attach the setup executable and SHA-256 file to the GitHub release.
6. For a Store release, also complete
   `packaging/store/SubmissionChecklist.md` with the final Partner Center
   identity and Windows App Certification Kit report.

The setup asset name is stable because `Install.cmd` and the README link to the
latest release by that name.
