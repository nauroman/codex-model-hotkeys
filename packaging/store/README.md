# Microsoft Store submission materials

This directory contains the text and checked-in visual evidence needed to
prepare a Partner Center submission:

- `StoreListing.en-US.md` - product name, descriptions, features, requirements,
  search terms, URLs, and trademark disclaimer;
- `CertificationNotes.md` - first-launch instructions, functional dependency,
  `runFullTrust` justification, and data/network behavior;
- `SubmissionChecklist.md` - identity, build, validation, submission, and
  post-certification gates;
- `assets/StoreScreenshot-ReasonKey-QuickStart.png` - actual application window captured
  at 1369x799, above the 1366x768 Store minimum.

The 300x300 Store logo and manifest image variants are generated from
`assets/ReasonKey.png` by `scripts/Build-Msix.ps1`. They appear under
the ignored `dist/store-assets/` and inside the MSIX package.

## Regenerating the screenshot

Build the runtime, launch its Store-preview-only quick-start view, and capture
the complete application window at 1366x768 or larger:

```powershell
.\scripts\Build.ps1 -Clean
Start-Process .\dist\ReasonKey.exe `
  -ArgumentList '--preview-store-quick-start'
```

The preview flag shows the same Store first-run content in a large capture
window. It does not create a package identity or change Startup Apps settings.
Close the preview after capturing it.

## Before upload

Re-read every field against the final product and current Microsoft Store form.
Do not upload the `_Dev.msix`, a self-signed certificate, the identity JSON, or
development logs. The final identity must come from Partner Center, and the
public privacy-policy URL must resolve before submission.
