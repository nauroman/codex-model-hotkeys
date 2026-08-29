[CmdletBinding()]
param(
    [string]$Subject = 'CN=Rotorlash Labs Development'
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$certificateDirectory = Join-Path $repositoryRoot '.tools\Msix'
$friendlyName = 'ReasonKey MSIX Development'

$certificate = Get-ChildItem -Path Cert:\CurrentUser\My |
    Where-Object {
        $_.Subject -eq $Subject -and
        $_.FriendlyName -eq $friendlyName -and
        $_.NotAfter -gt (Get-Date).AddDays(30)
    } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

if ($null -eq $certificate) {
    $certificate = New-SelfSignedCertificate `
        -Type Custom `
        -Subject $Subject `
        -FriendlyName $friendlyName `
        -CertStoreLocation 'Cert:\CurrentUser\My' `
        -KeyUsage DigitalSignature `
        -KeyExportPolicy NonExportable `
        -NotAfter (Get-Date).AddYears(2) `
        -TextExtension @(
            '2.5.29.37={text}1.3.6.1.5.5.7.3.3',
            '2.5.29.19={text}'
        )
}

New-Item -ItemType Directory -Path $certificateDirectory -Force | Out-Null
$cerPath = Join-Path $certificateDirectory 'ReasonKey-Development.cer'
Export-Certificate -Cert $certificate -FilePath $cerPath -Force | Out-Null

[pscustomobject]@{
    Subject = $certificate.Subject
    Thumbprint = $certificate.Thumbprint
    NotAfter = $certificate.NotAfter
    PublicCertificatePath = $cerPath
}
