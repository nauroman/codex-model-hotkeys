# Microsoft Store submission checklist

## Partner Center identity

- [x] Create or verify a Partner Center developer account.
- [x] Reserve the final product name.
- [x] Copy the exact Package/Identity Name.
- [x] Copy the exact Publisher ID.
- [x] Copy the exact Publisher display name.
- [x] Put those values in the gitignored
      `packaging/msix/StoreIdentity.json`.

## Build and validation

- [x] Update runtime and installer `AppVersion` values together.
- [x] Run `scripts/Build.ps1 -Clean`.
- [x] Run the real compact and Advanced picker regression matrix.
- [x] Build with `scripts/Build-Msix.ps1 -Clean -Store -IdentityFile ...`.
- [x] Confirm the build metadata says `Microsoft Store submission` and
      `signed: false`.
- [x] Confirm the package Identity and Publisher exactly match Partner Center.
- [x] Run Windows App Certification Kit against the final package.
- [x] Review the generated WACK XML/HTML report, resolve every applicable
      failure, and document tool/runtime false positives.
- [x] If the AutoHotkey blocked-executable/DPI warnings recur, include the
      explanations and runtime DPI evidence from `CertificationNotes.md`.
- [x] Retain the generated MSIX SHA-256 and build metadata with release
      evidence.

## Store submission

- [x] Set the product to free unless monetization is intentionally added.
- [x] Select PC/Desktop and x64 only.
- [x] Complete the age-rating questionnaire.
- [x] Declare and justify the `runFullTrust` restricted capability.
- [x] Paste the English listing text from `StoreListing.en-US.md`.
- [x] Upload `dist/store-assets/StoreLogo300x300.png`.
- [x] Upload `packaging/store/assets/StoreScreenshot-ReasonKey-QuickStart.png` and any
      additional 1366x768-or-larger PNG screenshots.
- [x] Use the public `PRIVACY.md` URL.
- [x] Use the GitHub repository as website and support URL.
- [x] Paste `CertificationNotes.md` into the certification notes field.
- [x] State clearly that the utility is unofficial and requires the
      Codex/ChatGPT Windows desktop app.
- [x] Upload the non-`_Dev` MSIX and wait for package validation.

## Submission evidence

- Submitted to Microsoft Store certification on 2026-08-29.
- Partner Center product ID: `9NLDRHX8Z0B1`.
- Submission ID: `1152921505701768947`.
- Submitted package: `ReasonKey_1.0.3.0_x64.msix`.
- Submitted package SHA-256:
  `005F62326F934BEC2CF4D1B04971024A6ECB88DF153116E14BCFEFA046F9BE9D`.
- Partner Center status after submission: `In certification`.
- Partner Center showed version 1.0.3 as `In the Microsoft Store` on
  2026-09-01 before the 1.0.4 update was started.

## Version 1.0.4 update preparation

- Partner Center update submission ID: `1152921505701787888` (Submission 2,
  created as a draft on 2026-09-01).
- The user confirmed the real Codex and ChatGPT compact/Advanced picker
  regression matrix on 2026-09-01 before release.
- Clean direct build completed with `scripts/Build.ps1 -Clean`.
- Direct installer SHA-256:
  `264927ED38022176AB234B881F6F3F9A78A62E75901867F31EF70481E45F3B32`.
- Store update package: `ReasonKey_1.0.4.0_x64.msix`.
- Store update package SHA-256:
  `86B1C0708A59EAB55B5AFAF877959275A9E7DCB388BFE425F518CF91D0EFFB07`.
- Build metadata confirms `Microsoft Store submission`, the Partner Center
  identity, x64 architecture, version `1.0.4.0`, and `signed: false`.
- Compiled cross-path singleton probe passed from two different executable
  directories in both launch orders.
- Reinstall preserved the active `presets.ini` SHA-256 byte-for-byte, removed
  the legacy startup shortcut and Installed Apps entry, and left the unrelated
  `arrowkeys.ahk` process running.
- The current Store 1.0.3.0 runtime was started first, then direct 1.0.4; direct
  1.0.4 terminated the recognized obsolete Store runtime and left exactly one
  active ReasonKey process.
- Updated `StoreScreenshot-ReasonKey-QuickStart.png` is a verified 1369x799 PNG
  showing the current Codex and ChatGPT Quick Start content.
- Elevated development-MSIX installation and packaged `LocalState` validation
  passed with exit code `0`. With direct first, MSIX exited; with MSIX first,
  direct exited. Each order left exactly one runtime and only the winning
  channel's Quick Start window.
- WACK 10.0.26100.8249 completed with overall `WARNING`, not `FAIL`. The report
  contains the same documented generic AutoHotkey blocked-executable and DPI
  analyzer warnings as 1.0.3. The dev package and temporary Local Machine
  Trusted People certificate were removed after validation.

## After certification

- [ ] Install the public Store build on a clean Windows user profile.
- [ ] Verify first launch, tray discovery, configuration, optional startup,
      compact/Advanced switching, update behavior, and clean uninstall.
- [x] Add the final Microsoft Store URL to the README.
- [ ] Ensure the direct installer and Store package cannot leave two active
      runtime instances on the same Windows session.
