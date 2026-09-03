[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $repositoryRoot 'src\StoreUpdater\ReasonKey.StoreUpdater.vcxproj'
$outputDirectory = Join-Path $repositoryRoot '.build\store-updater'
$outputPath = Join-Path $outputDirectory 'ReasonKey.StoreUpdater.exe'
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'

if (-not (Test-Path -LiteralPath $vswhere)) {
    throw 'Visual Studio Build Tools were not found. Install the Desktop development with C++ workload.'
}

$installations = @(& $vswhere -all -products * `
    -requires Microsoft.Component.MSBuild Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath)
$buildEnvironment = $null
foreach ($installation in $installations) {
    $msbuild = Join-Path $installation 'MSBuild\Current\Bin\MSBuild.exe'
    $toolsetsRoot = Join-Path $installation 'MSBuild\Microsoft\VC\v170\Platforms\x64\PlatformToolsets'
    if (-not (Test-Path -LiteralPath $msbuild) -or -not (Test-Path -LiteralPath $toolsetsRoot)) {
        continue
    }

    $toolset = Get-ChildItem -LiteralPath $toolsetsRoot -Directory |
        Where-Object { $_.Name -match '^v\d+$' } |
        Sort-Object Name -Descending |
        Select-Object -First 1 -ExpandProperty Name
    if ($toolset) {
        $buildEnvironment = [pscustomobject]@{
            MsBuild = $msbuild
            Toolset = $toolset
        }
        break
    }
}
if ($null -eq $buildEnvironment) {
    throw 'MSBuild with an x64 Visual C++ platform toolset was not found.'
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
& $buildEnvironment.MsBuild $projectPath `
    /nologo /m /t:Rebuild `
    /p:Configuration=Release /p:Platform=x64 `
    "/p:PlatformToolset=$($buildEnvironment.Toolset)"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $outputPath)) {
    throw 'Failed to build ReasonKey.StoreUpdater.exe.'
}

$validation = Start-Process -FilePath $outputPath -ArgumentList '--self-test' `
    -PassThru -Wait -WindowStyle Hidden
if ($validation.ExitCode -ne 0) {
    throw "The Store updater self-test failed with exit code $($validation.ExitCode)."
}

Write-Host "Built Store updater: $outputPath"
Write-Host "SHA256: $((Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash)"

[pscustomobject]@{
    Path = $outputPath
    Sha256 = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
    Toolset = $buildEnvironment.Toolset
}
