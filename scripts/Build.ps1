[CmdletBinding()]
param(
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$distDirectory = Join-Path $repositoryRoot 'dist'
$toolsDirectory = Join-Path $repositoryRoot '.tools\Ahk2Exe'
$autoHotkeyToolsDirectory = Join-Path $repositoryRoot '.tools\AutoHotkey'

if ($Clean -and (Test-Path -LiteralPath $distDirectory)) {
    Get-ChildItem -LiteralPath $distDirectory -Force | Remove-Item -Recurse -Force
}
New-Item -ItemType Directory -Path $distDirectory -Force | Out-Null

$baseCandidates = @(
    (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey64.exe')
)
$baseExecutable = $baseCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($null -eq $baseExecutable) {
    $downloadedBase = Get-ChildItem -LiteralPath $autoHotkeyToolsDirectory `
        -Filter AutoHotkey64.exe -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
    if ($null -eq $downloadedBase) {
        Write-Host 'Downloading the official AutoHotkey v2 portable release...'
        $release = Invoke-RestMethod -Headers @{ 'User-Agent' = 'CodexModelHotkeys-Build' } `
            -Uri 'https://api.github.com/repos/AutoHotkey/AutoHotkey/releases/latest'
        $asset = $release.assets | Where-Object { $_.name -like 'AutoHotkey_2*.zip' } |
            Select-Object -First 1
        if ($null -eq $asset) {
            throw 'Could not find the AutoHotkey v2 portable release archive.'
        }

        $archivePath = Join-Path $env:TEMP ('AutoHotkey-' + [guid]::NewGuid().ToString('N') + '.zip')
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $asset.browser_download_url -OutFile $archivePath
            New-Item -ItemType Directory -Path $autoHotkeyToolsDirectory -Force | Out-Null
            Expand-Archive -LiteralPath $archivePath -DestinationPath $autoHotkeyToolsDirectory -Force
        }
        finally {
            if (Test-Path -LiteralPath $archivePath) {
                Remove-Item -LiteralPath $archivePath -Force
            }
        }
        $downloadedBase = Get-ChildItem -LiteralPath $autoHotkeyToolsDirectory `
            -Filter AutoHotkey64.exe -Recurse | Select-Object -First 1 -ExpandProperty FullName
    }
    $baseExecutable = $downloadedBase
}

$compilerCandidates = @(
    (Join-Path $env:ProgramFiles 'AutoHotkey\Compiler\Ahk2Exe.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\Compiler\Ahk2Exe.exe'),
    (Join-Path $toolsDirectory 'Ahk2Exe.exe')
)
$compiler = $compilerCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if ($null -eq $compiler) {
    Write-Host 'Downloading the official Ahk2Exe compiler...'
    $release = Invoke-RestMethod -Headers @{ 'User-Agent' = 'CodexModelHotkeys-Build' } `
        -Uri 'https://api.github.com/repos/AutoHotkey/Ahk2Exe/releases/latest'
    $asset = $release.assets | Where-Object { $_.name -like 'Ahk2Exe*.zip' } | Select-Object -First 1
    if ($null -eq $asset) {
        throw 'Could not find the Ahk2Exe release archive.'
    }

    $archivePath = Join-Path $env:TEMP ('Ahk2Exe-' + [guid]::NewGuid().ToString('N') + '.zip')
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $asset.browser_download_url -OutFile $archivePath
        New-Item -ItemType Directory -Path $toolsDirectory -Force | Out-Null
        Expand-Archive -LiteralPath $archivePath -DestinationPath $toolsDirectory -Force
    }
    finally {
        if (Test-Path -LiteralPath $archivePath) {
            Remove-Item -LiteralPath $archivePath -Force
        }
    }
    $compiler = Get-ChildItem -LiteralPath $toolsDirectory -Filter Ahk2Exe.exe -Recurse |
        Select-Object -First 1 -ExpandProperty FullName
}

$runtimeSource = Join-Path $repositoryRoot 'src\CodexModelHotkeys.ahk'
$runtimeOutput = Join-Path $distDirectory 'CodexModelHotkeys.exe'
$setupSource = Join-Path $repositoryRoot 'installer\Setup.ahk'
$setupOutput = Join-Path $distDirectory 'CodexModelHotkeys-Setup.exe'

$runtimeCompileArguments = '/in "{0}" /out "{1}" /base "{2}" /compress 0 /silent verbose' -f `
    $runtimeSource, $runtimeOutput, $baseExecutable
$runtimeCompile = Start-Process -FilePath $compiler -ArgumentList $runtimeCompileArguments `
    -PassThru -Wait -WindowStyle Hidden
if ($runtimeCompile.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $runtimeOutput)) {
    throw 'Failed to compile CodexModelHotkeys.exe.'
}

$runtimeValidation = Start-Process -FilePath $runtimeOutput -ArgumentList '--validate' `
    -PassThru -Wait -WindowStyle Hidden
if ($runtimeValidation.ExitCode -ne 0) {
    throw 'The compiled runtime failed validation.'
}

$setupCompileArguments = '/in "{0}" /out "{1}" /base "{2}" /compress 0 /silent verbose' -f `
    $setupSource, $setupOutput, $baseExecutable
$setupCompile = Start-Process -FilePath $compiler -ArgumentList $setupCompileArguments `
    -PassThru -Wait -WindowStyle Hidden
if ($setupCompile.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $setupOutput)) {
    throw 'Failed to compile CodexModelHotkeys-Setup.exe.'
}

$setupValidation = Start-Process -FilePath $setupOutput -ArgumentList '--validate' `
    -PassThru -Wait -WindowStyle Hidden
if ($setupValidation.ExitCode -ne 0) {
    throw 'The compiled installer failed validation.'
}

$hash = (Get-FileHash -LiteralPath $setupOutput -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath ($setupOutput + '.sha256') `
    -Value "$hash  CodexModelHotkeys-Setup.exe" -Encoding ascii

Write-Host "Built: $runtimeOutput"
Write-Host "Built: $setupOutput"
Write-Host "SHA256: $hash"
