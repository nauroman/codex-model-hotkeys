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
- [x] Submit the update and confirm Partner Center reports `In certification`.

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

## Version 1.0.4 update evidence

- Partner Center update submission ID: `1152921505701787888` (Submission 2,
  submitted to certification on 2026-09-01).
- Partner Center status after submission: `In certification`, with Submission
  complete and Pre-processing active (step 2 of 4).
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
- The older Store screenshot was removed before submission. The remaining
  screenshot matched the repository file SHA-256
  `2169550DFE049839D15581502149EB7C14EABE978EDEA488A93998244B22DAF2`.
- Elevated development-MSIX installation and packaged `LocalState` validation
  passed with exit code `0`. With direct first, MSIX exited; with MSIX first,
  direct exited. Each order left exactly one runtime and only the winning
  channel's Quick Start window.
- WACK 10.0.26100.8249 completed with overall `WARNING`, not `FAIL`. The report
  contains the same documented generic AutoHotkey blocked-executable and DPI
  analyzer warnings as 1.0.3. The dev package and temporary Local Machine
  Trusted People certificate were removed after validation.

## Version 1.0.5 update preparation

- Restored compatibility with the unified picker in Codex desktop package
  `OpenAI.Codex_26.901.1978.0_x64__2p2nqsd0c76g0`.
- The compiled runtime passed the real Codex F16-F19 matrix and the ChatGPT
  F16-F19 matrix. Already-open compact and model-radio starting states also
  passed against the source-equivalent runtime.
- Clean direct and Store builds completed on 2026-09-02. Direct installer
  SHA-256:
  `698853B0087DFEB2B3089735732F326FCD5A79AA7CBBF9D10FE6AC7E0BC0A910`.
- Store update package: `ReasonKey_1.0.5.0_x64.msix`. SHA-256:
  `C176B7DA8EDB0BD3FCA48FF0F3DCFC603A3896A445855309D08B79B480099A1D`.
- Build metadata confirms the Partner Center identity, x64 architecture,
  version `1.0.5.0`, Microsoft Store submission purpose, and `signed: false`.
- The updated Quick Start screenshot is a visually verified 1381x805 PNG with
  SHA-256
  `7F363AE1BBF79E041E06182BD2A12C4093214D0D1C25904BD8951E2CC3F1AEE9`.
- Partner Center upload, WACK rerun, submission ID, and public Store validation
  were superseded by the 1.0.6 update before submission.

## Version 1.0.6 update evidence

- Version 1.0.6 includes the unified Codex/ChatGPT picker fixes prepared for
  1.0.5 plus a packaged-only Microsoft Store update check and automatic
  post-update restart path.
- `scripts/Build.ps1 -Clean` completed successfully. Final direct installer
  SHA-256:
  `511672EE9B5F18AF9F19218143AA2C8EB1692945CF1F1C51F398041B06DB3A0F`.
- Reinstalling the final direct build returned exit code `0`, installed the
  exact final runtime, kept `DisplayVersion` at `1.0.6`, and preserved the
  existing `presets.ini` SHA-256 byte-for-byte:
  `BCCAE2F718A47EE930BFCD497F7428853BF2251D8F35F7D4A49F041EB01B7BDD`.
- Store update package: `ReasonKey_1.0.6.0_x64.msix`. Final SHA-256:
  `DBA8ABD0AEC0770456D8A5A19F348B8A2AAA06C3EA12942DC7E76CA766F7F76C`.
- Final Store updater SHA-256:
  `7D63F49E5F5E4B2D73B118384B4F9FE20CA7DF6B3B72EA49879E5BF9668C0BED`.
- Build metadata confirms the Partner Center identity, x64 architecture,
  version `1.0.6.0`, Microsoft Store submission purpose, `signed: false`, and
  matching package/runtime/updater hashes.
- The exact final updater passed its self-test and, when invoked inside the
  installed public `RotorlashLabs.ReasonKey` package identity, contacted the
  Store service and returned `result=no-update` on 2026-09-02.
- The final updater fallback waited for the old process, activated the Store
  AUMID, logged `relaunch-requested=true`, and started exactly one Store
  runtime. The direct runtime was restored afterward with exactly one active
  ReasonKey process.
- Direct-first and Store-first launch tests each left exactly one recognized
  ReasonKey runtime. The compiled copied-path singleton probe also passed as
  part of the clean build.
- WACK 10.0.26100.8249 completed with overall `WARNING`, not overall `FAIL`.
  The signed development package passed runtime validation with exit code `0`.
  The report contains the previously documented generic AutoHotkey
  blocked-executable and DPI analyzer findings; the new native Store updater
  was inventoried without a separate failure.
- The WACK development package and temporary Current User/Local Machine
  development certificates were removed after validation.
- The Quick Start window is content-sized at 701x534 logical pixels. The Store
  asset frames the real compact window on a neutral 1600x900 canvas without
  enlarging the app UI. Screenshot SHA-256:
  `205351780926B4041CD6FBED1D1B515F3E427770CC1A374CC84DA0843AC30A74`.
- Partner Center accepted `ReasonKey_1.0.6.0_x64.msix` as `Validated` in
  update Submission 3, ID `1152921505701800820`. The en-US listing uses the
  single updated 1600x900 Quick Start screenshot; the older 1.0.4 screenshot
  was removed. The update was submitted on 2026-09-02 (America/Vancouver), and
  Partner Center verified `Product update: In certification` with Publishing
  Status `Step 2 of 4` (`Pre-processing`). Publishing is configured to begin
  automatically after certification passes.

## After certification

- [ ] Install the public Store build on a clean Windows user profile.
- [ ] Verify first launch, tray discovery, configuration, optional startup,
      compact/Advanced switching, update behavior, and clean uninstall.
- [x] Add the final Microsoft Store URL to the README.
- [x] Ensure the direct installer and Store package cannot leave two active
      runtime instances on the same Windows session.
