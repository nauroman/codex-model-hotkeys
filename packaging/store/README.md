# Microsoft Store submission materials

This directory contains the text and checked-in visual evidence needed to
prepare a Partner Center submission:

- `StoreListing.en-US.md` - product name, descriptions, features, requirements,
  search terms, URLs, and trademark disclaimer;
- `CertificationNotes.md` - first-launch instructions, functional dependency,
  `runFullTrust` justification, and data/network behavior;
- `SubmissionChecklist.md` - identity, build, validation, submission, and
  post-certification gates;
- `assets/StoreScreenshot-ReasonKey-QuickStart.png` - the actual compact
  application window, framed on a neutral 1600x900 canvas above the Store
  minimum. The canvas does not change or enlarge the application UI.

The 300x300 Store logo and manifest image variants are generated from
`assets/ReasonKey.png` by `scripts/Build-Msix.ps1`. They appear under
the ignored `dist/store-assets/` and inside the MSIX package.

## Regenerating the screenshot

Build the runtime, launch its Store-preview-only quick-start view, and capture
the complete compact application window:

```powershell
.\scripts\Build.ps1 -Clean
Start-Process .\dist\ReasonKey.exe `
  -ArgumentList '--preview-store-quick-start'
```

The preview flag shows the same Store first-run content in a compact window. It
does not create a package identity or change Startup Apps settings.
Capture the window and then build the Store-sized neutral canvas:

```powershell
.\scripts\Capture-StoreWindow.ps1 -ProcessId <preview-process-id>
.\scripts\Build-StoreScreenshot.ps1
```

Close the preview after the capture.

## Before upload

Re-read every field against the final product and current Microsoft Store form.
Do not upload the `_Dev.msix`, a self-signed certificate, the identity JSON, or
development logs. The final identity must come from Partner Center, and the
public privacy-policy URL must resolve before submission.
