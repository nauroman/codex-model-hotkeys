[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$PackagePath,
    [string]$IdentityName = 'RotorlashLabs.ReasonKey.Dev',
    [switch]$TrustDevelopmentCertificate,
    [switch]$Launch,
    [switch]$KeepInstalled
)

$ErrorActionPreference = 'Stop'
$resolvedPackagePath = (Resolve-Path -LiteralPath $PackagePath).Path
$developmentCertificateSubject = 'CN=Rotorlash Labs Development'
$trustedCertificateAdded = $false
$trustedCertificate = $null
$installedPackage = $null

try {
    if ($TrustDevelopmentCertificate) {
        $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw '-TrustDevelopmentCertificate requires an elevated PowerShell window.'
        }

        $signature = Get-AuthenticodeSignature -LiteralPath $resolvedPackagePath
        $trustedCertificate = $signature.SignerCertificate
        if ($null -eq $trustedCertificate -or
            $trustedCertificate.Subject -ne $developmentCertificateSubject) {
            throw 'The package is not signed by the expected development certificate.'
        }

        $trustedPeople = [Security.Cryptography.X509Certificates.X509Store]::new(
            'TrustedPeople',
            [Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
        )
        $trustedPeople.Open([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        try {
            $alreadyTrusted = @($trustedPeople.Certificates | Where-Object {
                $_.Thumbprint -eq $trustedCertificate.Thumbprint
            })
            if ($alreadyTrusted.Count -eq 0) {
                $trustedPeople.Add($trustedCertificate)
                $trustedCertificateAdded = $true
            }
        }
        finally {
            $trustedPeople.Close()
        }
    }

    $existingPackages = @(Get-AppxPackage -Name $IdentityName -ErrorAction SilentlyContinue)
    foreach ($existingPackage in $existingPackages) {
        if ($existingPackage.Name -ne $IdentityName) {
            throw "Refusing to remove an unexpected package: $($existingPackage.Name)"
        }
        Remove-AppxPackage -Package $existingPackage.PackageFullName
    }

    Add-AppxPackage -Path $resolvedPackagePath
    $installedPackage = Get-AppxPackage -Name $IdentityName
    if ($null -eq $installedPackage) {
        throw "The package was not installed: $IdentityName"
    }

    $runtimePath = Join-Path $installedPackage.InstallLocation 'ReasonKey.exe'
    if (-not (Test-Path -LiteralPath $runtimePath)) {
        throw "The packaged runtime was not found: $runtimePath"
    }

    $validation = Start-Process -FilePath $runtimePath `
        -ArgumentList '--validate-package' -PassThru -Wait -WindowStyle Hidden
    if ($validation.ExitCode -ne 0) {
        throw "The packaged runtime validation failed with exit code $($validation.ExitCode)."
    }

    if ($Launch) {
        Start-Process 'explorer.exe' `
            -ArgumentList "shell:AppsFolder\$($installedPackage.PackageFamilyName)!ReasonKey"
    }

    [pscustomobject]@{
        Name = $installedPackage.Name
        PackageFullName = $installedPackage.PackageFullName
        PackageFamilyName = $installedPackage.PackageFamilyName
        InstallLocation = $installedPackage.InstallLocation
        RuntimeValidationExitCode = $validation.ExitCode
        TrustedDevelopmentCertificate = [bool]$TrustDevelopmentCertificate
        Launched = [bool]$Launch
        KeptInstalled = [bool]$KeepInstalled
    }
}
finally {
    if (-not $KeepInstalled) {
        $installedPackage = Get-AppxPackage -Name $IdentityName -ErrorAction SilentlyContinue
        if ($null -ne $installedPackage -and $installedPackage.Name -eq $IdentityName) {
            Remove-AppxPackage -Package $installedPackage.PackageFullName
        }
    }

    if ($trustedCertificateAdded -and $null -ne $trustedCertificate) {
        $trustedPeople = [Security.Cryptography.X509Certificates.X509Store]::new(
            'TrustedPeople',
            [Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
        )
        $trustedPeople.Open([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        try {
            $matchingCertificates = @($trustedPeople.Certificates | Where-Object {
                $_.Thumbprint -eq $trustedCertificate.Thumbprint -and
                $_.Subject -eq $developmentCertificateSubject
            })
            foreach ($matchingCertificate in $matchingCertificates) {
                $trustedPeople.Remove($matchingCertificate)
            }
        }
        finally {
            $trustedPeople.Close()
        }
    }
}
