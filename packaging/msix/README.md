# MSIX packaging

The MSIX channel is separate from the existing per-user EXE installer. It uses
the same compiled runtime but lets Microsoft Store own installation, signing,
updates, startup registration, and clean uninstall.

## Development package

Run from Windows PowerShell after building the normal runtime:

```powershell
$certificate = .\scripts\New-MsixDevelopmentCertificate.ps1

.\scripts\Build-Msix.ps1 -Clean -SkipRuntimeBuild `
  -CertificateThumbprint $certificate.Thumbprint
```

The certificate is self-signed and is only for local testing. Creating it and
signing do not require administrator rights. Windows App Installer checks the
Local Computer trust store, so installing a self-signed MSIX requires one
elevated test step.

Before that trust step, Windows may describe the Authenticode status as
`UnknownError`/untrusted even though the expected signature and signer
thumbprint are present. The elevated installation test is the end-to-end trust
and package-signature check; a Store submission does not use this certificate.

Open Windows PowerShell **as administrator**, then install, validate
package-aware storage, and remove the package:

```powershell
.\scripts\Test-Msix.ps1 `
  -PackagePath .\dist\msix\ReasonKey_1.0.4.0_x64_Dev.msix `
  -TrustDevelopmentCertificate
```

The script accepts only the exact development-certificate subject, adds that
certificate temporarily to Local Computer -> Trusted People, and removes it in
`finally`. The package is also removed unless `-KeepInstalled` is specified.
No Local Machine root certificate is added.

Use `-KeepInstalled` while doing interactive regression testing. Remove the
development package afterward with:

```powershell
Get-AppxPackage -Name RotorlashLabs.ReasonKey.Dev | Remove-AppxPackage
```

Remove only the development certificate created by this project with:

```powershell
.\scripts\Remove-MsixDevelopmentCertificate.ps1
```

If an elevated test was interrupted, also run the following from an elevated
PowerShell window to remove an exact matching temporary Trusted People entry:

```powershell
.\scripts\Remove-MsixDevelopmentCertificate.ps1 -LocalMachineTrust
```

Run the Windows App Certification Kit (WACK), packaged runtime validation, and
cleanup together from an elevated PowerShell window:

```powershell
.\scripts\Invoke-WindowsAppCertification.ps1 `
  -PackagePath .\dist\msix\ReasonKey_1.0.4.0_x64_Dev.msix
```

The report is written below `.build\msix\wack\`.

## Microsoft Store package

1. Reserve the app name in Partner Center.
2. Open **Product management -> Product identity** and copy the Package/Identity
   Name, Publisher ID, and Publisher display name.
3. Copy `StoreIdentity.example.json` to the gitignored `StoreIdentity.json` and
   replace all placeholder values with the exact Partner Center values.
4. Build the unsigned Store submission package:

   ```powershell
   .\scripts\Build-Msix.ps1 -Clean -Store `
     -IdentityFile packaging\msix\StoreIdentity.json
   ```

5. Upload the resulting non-`_Dev` `.msix` from `dist\msix\` to Partner Center.
   Microsoft signs the package after certification. Do not upload the local
   development package or its self-signed certificate.

The version defaults to the runtime `AppVersion` plus a fourth `.0` component.
For example, runtime version `1.0.4` becomes MSIX version `1.0.4.0`.

## Generated outputs

```text
dist/msix/*.msix
dist/msix/*.msix.sha256
dist/msix/*.msix.build.json
dist/store-assets/StoreLogo300x300.png
packaging/store/assets/StoreScreenshot-ReasonKey-QuickStart.png
```

The build metadata records the exact identity, version, runtime hash, package
hash, source-runtime hash, architecture, purpose, and signing state. The
packaged runtime receives the checked-in Per-Monitor V2 DPI manifest before its
final hash is recorded. Generated package and Store assets are intentionally
ignored by Git.

## Store-specific behavior

- Editable data is stored under the package's `LocalState` directory instead
  of the read-only WindowsApps installation directory.
- On first launch, an existing direct-install `presets.ini` is copied into the
  package data directory without changing the original. The migration accepts
  both the current `ReasonKey` path and the legacy `CodexModelHotkeys` path.
- The startup task is registered through the supported MSIX manifest extension
  and is disabled by default. The quick-start window links to Windows Startup
  Apps so the user can opt in.
- The Store and direct-installer runtimes acquire the same per-session named
  mutex. If both channels are installed, only the first current runtime remains
  active; a second channel launch exits before it creates hotkeys or a tray
  icon.
- The Store owns updates and uninstall. The MSIX does not install the project's
  PowerShell uninstaller or write its own Installed Apps registry entry.

## Required external values

The repository cannot invent the Partner Center identity. The final
submission package requires these exact values from **Product management ->
Product identity** after the product name is reserved:

- Package/Identity Name;
- Publisher ID;
- Publisher display name.

They belong only in the gitignored `StoreIdentity.json`; the example file is
safe to commit.
