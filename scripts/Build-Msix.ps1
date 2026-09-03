[CmdletBinding()]
param(
    [switch]$Clean,
    [switch]$SkipRuntimeBuild,
    [switch]$Store,
    [string]$IdentityFile,
    [string]$IdentityName = 'RotorlashLabs.ReasonKey.Dev',
    [string]$Publisher = 'CN=Rotorlash Labs Development',
    [string]$PublisherDisplayName = 'Rotorlash Labs',
    [string]$PackageDisplayName = 'ReasonKey',
    [string]$Version,
    [string]$CertificateThumbprint
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$distDirectory = Join-Path $repositoryRoot 'dist'
$msixOutputDirectory = Join-Path $distDirectory 'msix'
$storeAssetsDirectory = Join-Path $distDirectory 'store-assets'
$buildDirectory = Join-Path $repositoryRoot '.build\msix'
$stagingDirectory = Join-Path $buildDirectory 'staging'
$verificationDirectory = Join-Path $buildDirectory 'verification'
$manifestTemplatePath = Join-Path $repositoryRoot 'packaging\msix\AppxManifest.xml.template'
$runtimeManifestPath = Join-Path $repositoryRoot 'packaging\msix\ReasonKey.exe.manifest'
$runtimeSourcePath = Join-Path $repositoryRoot 'src\ReasonKey.ahk'
$runtimeOutputPath = Join-Path $distDirectory 'ReasonKey.exe'
$storeUpdaterPath = Join-Path $repositoryRoot '.build\store-updater\ReasonKey.StoreUpdater.exe'
$sourceImagePath = Join-Path $repositoryRoot 'assets\ReasonKey.png'

function Assert-PathInsideRepository([string]$Path) {
    $resolvedRepository = [System.IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\') + '\'
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    if (-not $resolvedPath.StartsWith($resolvedRepository, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify a path outside the repository: $resolvedPath"
    }
}

function Remove-RepositoryDirectory([string]$Path) {
    Assert-PathInsideRepository $Path
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

function ConvertTo-XmlText([string]$Value) {
    return [System.Security.SecurityElement]::Escape($Value)
}

function Get-WindowsSdkTool([string]$ToolName) {
    $sdkRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
    if (-not (Test-Path -LiteralPath $sdkRoot)) {
        throw 'Windows 10/11 SDK was not found.'
    }

    $candidate = Get-ChildItem -LiteralPath $sdkRoot -Directory |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+\.\d+$' } |
        Sort-Object { [version]$_.Name } -Descending |
        ForEach-Object { Join-Path $_.FullName "x64\$ToolName" } |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
    if ($null -eq $candidate) {
        throw "$ToolName was not found in the Windows SDK."
    }
    return $candidate
}

function Save-PngAsset(
    [string]$SourcePath,
    [string]$DestinationPath,
    [int]$Width,
    [int]$Height
) {
    Add-Type -AssemblyName System.Drawing
    $source = [System.Drawing.Image]::FromFile($SourcePath)
    try {
        $bitmap = [System.Drawing.Bitmap]::new(
            $Width,
            $Height,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([System.Drawing.Color]::Transparent)
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

                $scale = [Math]::Min($Width / $source.Width, $Height / $source.Height)
                $drawWidth = [int][Math]::Round($source.Width * $scale)
                $drawHeight = [int][Math]::Round($source.Height * $scale)
                $x = [int][Math]::Floor(($Width - $drawWidth) / 2)
                $y = [int][Math]::Floor(($Height - $drawHeight) / 2)
                $graphics.DrawImage($source, $x, $y, $drawWidth, $drawHeight)
            }
            finally {
                $graphics.Dispose()
            }
            $bitmap.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $bitmap.Dispose()
        }
    }
    finally {
        $source.Dispose()
    }
}

function Write-PackageAssets([string]$AssetsDirectory) {
    New-Item -ItemType Directory -Path $AssetsDirectory -Force | Out-Null

    $assets = @(
        @{ Name = 'StoreLogo.png'; Width = 50; Height = 50 },
        @{ Name = 'StoreLogo.scale-100.png'; Width = 50; Height = 50 },
        @{ Name = 'StoreLogo.scale-200.png'; Width = 100; Height = 100 },
        @{ Name = 'StoreLogo.scale-400.png'; Width = 200; Height = 200 },
        @{ Name = 'Square44x44Logo.png'; Width = 44; Height = 44 },
        @{ Name = 'Square44x44Logo.scale-100.png'; Width = 44; Height = 44 },
        @{ Name = 'Square44x44Logo.scale-200.png'; Width = 88; Height = 88 },
        @{ Name = 'Square44x44Logo.scale-400.png'; Width = 176; Height = 176 },
        @{ Name = 'Square150x150Logo.png'; Width = 150; Height = 150 },
        @{ Name = 'Square150x150Logo.scale-100.png'; Width = 150; Height = 150 },
        @{ Name = 'Square150x150Logo.scale-200.png'; Width = 300; Height = 300 },
        @{ Name = 'Square150x150Logo.scale-400.png'; Width = 600; Height = 600 },
        @{ Name = 'Square310x310Logo.png'; Width = 310; Height = 310 },
        @{ Name = 'Square310x310Logo.scale-100.png'; Width = 310; Height = 310 },
        @{ Name = 'Square310x310Logo.scale-200.png'; Width = 620; Height = 620 },
        @{ Name = 'Square310x310Logo.scale-400.png'; Width = 1240; Height = 1240 },
        @{ Name = 'Wide310x150Logo.png'; Width = 310; Height = 150 },
        @{ Name = 'Wide310x150Logo.scale-100.png'; Width = 310; Height = 150 },
        @{ Name = 'Wide310x150Logo.scale-200.png'; Width = 620; Height = 300 },
        @{ Name = 'Wide310x150Logo.scale-400.png'; Width = 1240; Height = 600 }
    )
    foreach ($asset in $assets) {
        Save-PngAsset -SourcePath $sourceImagePath `
            -DestinationPath (Join-Path $AssetsDirectory $asset.Name) `
            -Width $asset.Width -Height $asset.Height
    }

    foreach ($targetSize in @(16, 24, 32, 48, 256)) {
        Save-PngAsset -SourcePath $sourceImagePath `
            -DestinationPath (Join-Path $AssetsDirectory "Square44x44Logo.targetsize-$targetSize.png") `
            -Width $targetSize -Height $targetSize
        Save-PngAsset -SourcePath $sourceImagePath `
            -DestinationPath (Join-Path $AssetsDirectory "Square44x44Logo.targetsize-$targetSize`_altform-unplated.png") `
            -Width $targetSize -Height $targetSize
    }
}

if ($IdentityFile) {
    $identityFilePath = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $IdentityFile))
    if (-not (Test-Path -LiteralPath $identityFilePath)) {
        throw "Identity file was not found: $identityFilePath"
    }
    $identity = Get-Content -LiteralPath $identityFilePath -Raw | ConvertFrom-Json
    foreach ($propertyName in @(
        'IdentityName',
        'Publisher',
        'PublisherDisplayName',
        'PackageDisplayName'
    )) {
        $value = $identity.$propertyName
        if ([string]::IsNullOrWhiteSpace($value)) {
            throw "Identity file property is missing: $propertyName"
        }
        Set-Variable -Name $propertyName -Value $value
    }
}

if ($Store -and $IdentityName -eq 'RotorlashLabs.ReasonKey.Dev') {
    throw 'A Store build requires Partner Center identity values. Use -IdentityFile or explicit identity parameters.'
}
if ($IdentityName -notmatch '^[A-Za-z0-9.-]{3,50}$' -or $IdentityName.EndsWith('.')) {
    throw "Invalid MSIX Identity Name: $IdentityName"
}

$runtimeSource = Get-Content -LiteralPath $runtimeSourcePath -Raw
$appVersionMatch = [regex]::Match($runtimeSource, 'global AppVersion := "(?<version>\d+\.\d+\.\d+)"')
if (-not $appVersionMatch.Success) {
    throw 'Could not read AppVersion from the runtime source.'
}
if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = $appVersionMatch.Groups['version'].Value + '.0'
}

$versionParts = $Version -split '\.'
if ($versionParts.Count -ne 4) {
    throw 'MSIX Version must contain four numeric components.'
}
foreach ($part in $versionParts) {
    $parsedPart = 0
    if (-not [int]::TryParse($part, [ref]$parsedPart) -or $parsedPart -lt 0 -or $parsedPart -gt 65535) {
        throw "Invalid MSIX Version: $Version"
    }
}

if (-not $SkipRuntimeBuild) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'Build.ps1') -Clean
    if ($LASTEXITCODE -ne 0) {
        throw 'The runtime build failed.'
    }
}
if (-not (Test-Path -LiteralPath $runtimeOutputPath)) {
    throw "Compiled runtime was not found: $runtimeOutputPath"
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot 'Build-StoreUpdater.ps1')
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $storeUpdaterPath)) {
    throw 'The Store updater build failed.'
}

Assert-PathInsideRepository $buildDirectory
Assert-PathInsideRepository $msixOutputDirectory
Assert-PathInsideRepository $storeAssetsDirectory
if ($Clean) {
    Remove-RepositoryDirectory $buildDirectory
    Remove-RepositoryDirectory $msixOutputDirectory
    Remove-RepositoryDirectory $storeAssetsDirectory
}
else {
    Remove-RepositoryDirectory $stagingDirectory
    Remove-RepositoryDirectory $verificationDirectory
}

New-Item -ItemType Directory -Path $stagingDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $msixOutputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $storeAssetsDirectory -Force | Out-Null

Copy-Item -LiteralPath $runtimeOutputPath `
    -Destination (Join-Path $stagingDirectory 'ReasonKey.exe')
Copy-Item -LiteralPath $storeUpdaterPath `
    -Destination (Join-Path $stagingDirectory 'ReasonKey.StoreUpdater.exe')
$packagedRuntimePath = Join-Path $stagingDirectory 'ReasonKey.exe'
$manifestTool = Get-WindowsSdkTool 'mt.exe'
& $manifestTool -nologo -manifest $runtimeManifestPath `
    "-outputresource:$packagedRuntimePath;#1"
if ($LASTEXITCODE -ne 0) {
    throw 'Manifest Tool failed to apply the packaged runtime manifest.'
}
$packagedRuntimeValidation = Start-Process -FilePath $packagedRuntimePath `
    -ArgumentList '--validate' -PassThru -Wait -WindowStyle Hidden
if ($packagedRuntimeValidation.ExitCode -ne 0) {
    throw 'The manifest-updated packaged runtime failed validation.'
}
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'LICENSE') `
    -Destination (Join-Path $stagingDirectory 'LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'THIRD_PARTY_NOTICES.md') `
    -Destination (Join-Path $stagingDirectory 'THIRD_PARTY_NOTICES.md')
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'PRIVACY.md') `
    -Destination (Join-Path $stagingDirectory 'PRIVACY.md')

$manifest = Get-Content -LiteralPath $manifestTemplatePath -Raw
$manifest = $manifest.Replace('{{IDENTITY_NAME}}', (ConvertTo-XmlText $IdentityName))
$manifest = $manifest.Replace('{{PUBLISHER}}', (ConvertTo-XmlText $Publisher))
$manifest = $manifest.Replace('{{VERSION}}', (ConvertTo-XmlText $Version))
$manifest = $manifest.Replace('{{PACKAGE_DISPLAY_NAME}}', (ConvertTo-XmlText $PackageDisplayName))
$manifest = $manifest.Replace('{{PUBLISHER_DISPLAY_NAME}}', (ConvertTo-XmlText $PublisherDisplayName))
Set-Content -LiteralPath (Join-Path $stagingDirectory 'AppxManifest.xml') `
    -Value $manifest -Encoding utf8

Write-PackageAssets (Join-Path $stagingDirectory 'Assets')
Save-PngAsset -SourcePath $sourceImagePath `
    -DestinationPath (Join-Path $storeAssetsDirectory 'StoreLogo300x300.png') `
    -Width 300 -Height 300

if ($Store) {
    $purposeSuffix = ''
    $buildPurpose = 'Microsoft Store submission'
}
else {
    $purposeSuffix = '_Dev'
    $buildPurpose = 'local development'
}
$packageFileName = "ReasonKey_${Version}_x64${purposeSuffix}.msix"
$packagePath = Join-Path $msixOutputDirectory $packageFileName
if (Test-Path -LiteralPath $packagePath) {
    Remove-Item -LiteralPath $packagePath -Force
}

$makeAppx = Get-WindowsSdkTool 'makeappx.exe'
& $makeAppx pack /d $stagingDirectory /p $packagePath /o
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $packagePath)) {
    throw 'MakeAppx failed to create the MSIX package.'
}

$signed = $false
$signatureStatus = 'Not signed'
if (-not [string]::IsNullOrWhiteSpace($CertificateThumbprint)) {
    $signTool = Get-WindowsSdkTool 'signtool.exe'
    & $signTool sign /fd SHA256 /sha1 $CertificateThumbprint $packagePath
    if ($LASTEXITCODE -ne 0) {
        throw 'SignTool failed to sign the MSIX package.'
    }
    $signature = Get-AuthenticodeSignature -LiteralPath $packagePath
    if ($null -eq $signature.SignerCertificate -or
        $signature.SignerCertificate.Thumbprint -ne $CertificateThumbprint -or
        $signature.SignatureType -ne 'Authenticode' -or
        $signature.Status.ToString() -notin @('Valid', 'UnknownError', 'NotTrusted')) {
        throw "The MSIX package signature is missing or invalid: $($signature.Status)."
    }
    $signed = $true
    $signatureStatus = $signature.Status.ToString()
}

New-Item -ItemType Directory -Path $verificationDirectory -Force | Out-Null
& $makeAppx unpack /p $packagePath /d $verificationDirectory /o
if ($LASTEXITCODE -ne 0) {
    throw 'MakeAppx could not unpack the generated package for verification.'
}
foreach ($requiredPath in @(
    'AppxManifest.xml',
    'ReasonKey.exe',
    'ReasonKey.StoreUpdater.exe',
    'Assets\Square44x44Logo.png',
    'Assets\Square150x150Logo.png'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $verificationDirectory $requiredPath))) {
        throw "Generated package is missing: $requiredPath"
    }
}

$packageHash = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath ($packagePath + '.sha256') `
    -Value "$packageHash  $packageFileName" -Encoding ascii

$metadata = [ordered]@{
    purpose = $buildPurpose
    identityName = $IdentityName
    publisher = $Publisher
    publisherDisplayName = $PublisherDisplayName
    packageDisplayName = $PackageDisplayName
    version = $Version
    architecture = 'x64'
    applicationId = 'ReasonKey'
    signed = $signed
    signatureStatus = $signatureStatus
    sha256 = $packageHash
    runtimeSha256 = (Get-FileHash -LiteralPath $packagedRuntimePath -Algorithm SHA256).Hash.ToLowerInvariant()
    storeUpdaterSha256 = (Get-FileHash -LiteralPath $storeUpdaterPath -Algorithm SHA256).Hash.ToLowerInvariant()
    sourceRuntimeSha256 = (Get-FileHash -LiteralPath $runtimeOutputPath -Algorithm SHA256).Hash.ToLowerInvariant()
    packagePath = $packagePath
}
Set-Content -LiteralPath ($packagePath + '.build.json') `
    -Value ($metadata | ConvertTo-Json) -Encoding utf8

Write-Host "Built MSIX: $packagePath"
Write-Host "Purpose: $($metadata.purpose)"
Write-Host "Identity: $IdentityName"
Write-Host "Publisher: $Publisher"
Write-Host "Signed: $signed"
if ($signed) {
    Write-Host "Signature status before local trust: $signatureStatus"
}
Write-Host "SHA256: $packageHash"

[pscustomobject]@{
    Purpose = $metadata.purpose
    IdentityName = $IdentityName
    Publisher = $Publisher
    Version = $Version
    Signed = $signed
    SignatureStatus = $signatureStatus
    Sha256 = $packageHash
    PackagePath = $packagePath
    HashPath = $packagePath + '.sha256'
    MetadataPath = $packagePath + '.build.json'
    StoreLogoPath = Join-Path $storeAssetsDirectory 'StoreLogo300x300.png'
}
