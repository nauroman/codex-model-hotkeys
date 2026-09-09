# ReasonKey implementation map

Source/navigation context, not a second product specification or a release log.
Read the [product core](product-spec.md) and affected owners first.
Snapshot: 2026-09-08; working-tree runtime and installer declare AppVersion 1.0.10.
Source support includes Astra; this snapshot does not establish publication.

## Repository

Checkout: C:\Users\user\Documents\Codex\codexmodelhotkeys.
Public product: ReasonKey; repository: nauroman/codex-model-hotkeys.
Historical product names are migration inputs, not current branding.

| Responsibility | Source / entry points | Contract |
|---|---|---|
| Preset parsing and registration | [src/ReasonKey.ahk](../src/ReasonKey.ahk): LoadPresets, DefaultPresets, RegisterConfiguredHotkeys; [default INI](../config/default-presets.ini) | [Configuration](product-spec/configuration.md) |
| Active-window selection and UIA | ReasonKey.ahk: IsSupportedAppWindow, SelectPreset, SelectCombinedPreset, SelectModernPickerPreset, SelectChatPreset, OpenPickerTrigger, GetPickerSearchRoot, WaitSelectedTriggerLabel | [Picker](product-spec/picker.md) |
| Data, lifecycle and onboarding | ReasonKey.ahk: GetApplicationDataDirectory, InitializeConfigurationFiles, AcquireRuntimeMutex, StopOtherReasonKeyRuntimes, ShowQuickStart | [Installation](product-spec/installation.md) |
| Direct setup/removal | [Setup.ahk](../installer/Setup.ahk), [Uninstall.ps1](../installer/Uninstall.ps1), [Install-Latest.ps1](../scripts/Install-Latest.ps1) | [Installation](product-spec/installation.md) |
| Store update/restart | ReasonKey.ahk: StartStoreUpdateCheck, CheckStoreUpdateProcess; [native helper](../src/StoreUpdater/ReasonKey.StoreUpdater.cpp) | [Store updates](product-spec/store-updates.md) |
| Package identity/startup/DPI | [MSIX manifest](../packaging/msix/AppxManifest.xml.template), [EXE manifest](../packaging/msix/ReasonKey.exe.manifest) | [MSIX guide](../packaging/msix/README.md) |
| Icon and screenshots | [icon](../assets/ReasonKey.ico), [source artwork](../assets/ReasonKey.png), [Store materials](../packaging/store/README.md) | [Installation](product-spec/installation.md) |
| Dependency | [UIA-v2](../vendor/UIA-v2/Lib/UIA.ahk) | [Pinned provenance/license](../THIRD_PARTY_NOTICES.md) |

## Validation entry points

| Change | Entry point / what it establishes |
|---|---|
| Documentation | [Test-Documentation.ps1](../scripts/Test-Documentation.ps1): local links, structure, routing |
| Direct build | [Build.ps1](../scripts/Build.ps1): compile, built-in validation, copied-path singleton and uninstaller guards |
| Native helper | [Build-StoreUpdater.ps1](../scripts/Build-StoreUpdater.ps1): compile/self-test |
| Package structure | [Build-Msix.ps1](../scripts/Build-Msix.ps1): manifest/package/hash metadata |
| Packaged runtime/storage | [Test-Msix.ps1](../scripts/Test-Msix.ps1) |
| Isolated singleton | [Test-SingleInstance.ps1](../scripts/Test-SingleInstance.ps1) |
| Certification tools | [Invoke-WindowsAppCertification.ps1](../scripts/Invoke-WindowsAppCertification.ps1) |
| Real picker/install/update | [Development regression matrix](DEVELOPMENT.md) |

The [CI workflow](../.github/workflows/build.yml) builds direct and unsigned MSIX
artifacts. It does not operate a real signed-in Codex/ChatGPT window or establish
public Store delivery.

## Evidence boundaries

The source map above comes from source inspection. Current release evidence is
in [1.0.10 validation](diagnostics/release-1.0.10.md), including actual Codex,
ChatGPT Work and ordinary Chat results and the remaining external gates.
[Picker history](diagnostics/picker-validation-history.md) records earlier app
versions and transitions. [Store history](diagnostics/store-release-history.md)
records builds, hashes, confirmations and submission states through 1.0.6.
Read either only for a matching investigation.

[Astra development evidence](diagnostics/astra-validation-20260905.md) records
1.0.7 build checks; the actual picker matrix was not marked complete.

The old 1.0.6 submission state is historical; fresh publication,
clean-profile installation and actual update/restart are separate
[submission gates](../packaging/store/SubmissionChecklist.md). Do not infer current
Store status from a built package, checked historical box or README link.
