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
- [ ] Run the real compact and Advanced picker regression matrix.
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

- [ ] Set the product to free unless monetization is intentionally added.
- [ ] Select PC/Desktop and x64 only.
- [ ] Complete the age-rating questionnaire.
- [ ] Declare and justify the `runFullTrust` restricted capability.
- [ ] Paste the English listing text from `StoreListing.en-US.md`.
- [ ] Upload `dist/store-assets/StoreLogo300x300.png`.
- [ ] Upload `packaging/store/assets/StoreScreenshot-ReasonKey-QuickStart.png` and any
      additional 1366x768-or-larger PNG screenshots.
- [ ] Use the public `PRIVACY.md` URL.
- [ ] Use the GitHub repository as website and support URL.
- [ ] Paste `CertificationNotes.md` into the certification notes field.
- [ ] State clearly that the utility is unofficial and requires the
      Codex/ChatGPT Windows desktop app.
- [ ] Upload the non-`_Dev` MSIX and wait for package validation.

## After certification

- [ ] Install the public Store build on a clean Windows user profile.
- [ ] Verify first launch, tray discovery, configuration, optional startup,
      compact/Advanced switching, update behavior, and clean uninstall.
- [ ] Add the final Microsoft Store URL to the README.
- [ ] Ensure the direct installer and Store package cannot leave two active
      runtime instances on the same Windows session.
