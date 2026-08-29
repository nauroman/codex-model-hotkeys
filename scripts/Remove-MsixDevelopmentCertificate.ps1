[CmdletBinding()]
param(
    [switch]$LocalMachineTrust
)

$ErrorActionPreference = 'Stop'
$certificateIdentities = @(
    @{ FriendlyName = 'ReasonKey MSIX Development'; Subject = 'CN=Rotorlash Labs Development' },
    @{ FriendlyName = 'Codex Model Hotkeys MSIX Development'; Subject = 'CN=Codex Model Hotkeys Development' }
)
$storeSpecifications = @(
    @{ Name = 'Root'; Location = [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser },
    @{ Name = 'TrustedPeople'; Location = [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser },
    @{ Name = 'My'; Location = [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser }
)

if ($LocalMachineTrust) {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw '-LocalMachineTrust requires an elevated PowerShell window.'
    }
    $storeSpecifications += @{
        Name = 'TrustedPeople'
        Location = [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
    }
}

$thumbprints = @(
    foreach ($storeSpecification in $storeSpecifications) {
        $store = [System.Security.Cryptography.X509Certificates.X509Store]::new(
            $storeSpecification.Name,
            $storeSpecification.Location
        )
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
        try {
            foreach ($certificate in $store.Certificates) {
                foreach ($identity in $certificateIdentities) {
                    if ($certificate.Subject -eq $identity.Subject -and
                        ($certificate.FriendlyName -eq $identity.FriendlyName -or $LocalMachineTrust)) {
                        $certificate.Thumbprint
                        break
                    }
                }
            }
        }
        finally {
            $store.Close()
        }
    }
) | Sort-Object -Unique

$removedCount = 0
foreach ($storeSpecification in $storeSpecifications) {
    $store = [System.Security.Cryptography.X509Certificates.X509Store]::new(
        $storeSpecification.Name,
        $storeSpecification.Location
    )
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    try {
        $matchingCertificates = @(
            foreach ($certificate in $store.Certificates) {
                if ($thumbprints -contains $certificate.Thumbprint) {
                    $certificate
                }
            }
        )
        foreach ($certificate in $matchingCertificates) {
            $store.Remove($certificate)
            $removedCount++
        }
    }
    finally {
        $store.Close()
    }
}

Write-Host "Removed $removedCount ReasonKey/legacy development certificate store entries."
