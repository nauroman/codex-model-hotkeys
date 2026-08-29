[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$PackagePath,
    [string]$IdentityName = 'RotorlashLabs.ReasonKey.Dev',
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$resolvedPackagePath = (Resolve-Path -LiteralPath $PackagePath).Path

$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Windows App Certification Kit validation requires an elevated PowerShell window.'
}

$appCertificationKit = Join-Path ${env:ProgramFiles(x86)} `
    'Windows Kits\10\App Certification Kit\appcert.exe'
if (-not (Test-Path -LiteralPath $appCertificationKit)) {
    throw 'Windows App Certification Kit was not found. Install it with the Windows SDK.'
}

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $reportDirectory = Join-Path $repositoryRoot '.build\msix\wack'
    New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
    $ReportPath = Join-Path $reportDirectory 'ReasonKey-WACK.xml'
}
else {
    $ReportPath = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $ReportPath))
    New-Item -ItemType Directory -Path (Split-Path -Parent $ReportPath) -Force | Out-Null
}

if (Test-Path -LiteralPath $ReportPath) {
    Remove-Item -LiteralPath $ReportPath -Force
}

$installedPackage = $null
try {
    $installation = & (Join-Path $PSScriptRoot 'Test-Msix.ps1') `
        -PackagePath $resolvedPackagePath `
        -IdentityName $IdentityName `
        -TrustDevelopmentCertificate `
        -KeepInstalled
    $installedPackage = Get-AppxPackage -Name $IdentityName

    & $appCertificationKit reset
    if ($LASTEXITCODE -ne 0) {
        throw 'Windows App Certification Kit reset failed.'
    }

    & $appCertificationKit test `
        -packagefullname $installedPackage.PackageFullName `
        -reportoutputpath $ReportPath
    if ($LASTEXITCODE -ne 0) {
        throw "Windows App Certification Kit exited with code $LASTEXITCODE."
    }
    if (-not (Test-Path -LiteralPath $ReportPath)) {
        throw 'Windows App Certification Kit did not create its XML report.'
    }

    [xml]$report = Get-Content -LiteralPath $ReportPath -Raw
    $overallResult = $report.DocumentElement.GetAttribute('OVERALL_RESULT')
    if ([string]::IsNullOrWhiteSpace($overallResult)) {
        $overallResultNode = $report.SelectSingleNode('//*[local-name()="OverallResult"]')
        if ($null -ne $overallResultNode) {
            $overallResult = $overallResultNode.InnerText
        }
    }
    if ($overallResult -eq 'FAIL') {
        throw 'Windows App Certification Kit reported an overall failure.'
    }

    [pscustomobject]@{
        PackageFullName = $installation.PackageFullName
        RuntimeValidationExitCode = $installation.RuntimeValidationExitCode
        WackExitCode = 0
        WackOverallResult = if ([string]::IsNullOrWhiteSpace($overallResult)) { 'See report' } else { $overallResult }
        WackReportPath = $ReportPath
    }
}
finally {
    if ($null -eq $installedPackage) {
        $installedPackage = Get-AppxPackage -Name $IdentityName -ErrorAction SilentlyContinue
    }
    if ($null -ne $installedPackage -and $installedPackage.Name -eq $IdentityName) {
        Remove-AppxPackage -Package $installedPackage.PackageFullName
    }
    & (Join-Path $PSScriptRoot 'Remove-MsixDevelopmentCertificate.ps1') `
        -LocalMachineTrust
}
