[CmdletBinding()]
param(
    [switch]$Silent
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$localSetup = Join-Path $repositoryRoot 'dist\ReasonKey-Setup.exe'

if (Test-Path -LiteralPath $localSetup) {
    $setupPath = $localSetup
    $temporaryDirectory = $null
}
else {
    $temporaryDirectory = Join-Path $env:TEMP ('ReasonKey-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
    $setupPath = Join-Path $temporaryDirectory 'ReasonKey-Setup.exe'
    $checksumPath = Join-Path $temporaryDirectory 'ReasonKey-Setup.exe.sha256'
    $releaseBase = 'https://github.com/nauroman/codex-model-hotkeys/releases/latest/download'

    Write-Host 'Downloading the latest ReasonKey installer...'
    Invoke-WebRequest -UseBasicParsing -Uri "$releaseBase/ReasonKey-Setup.exe" -OutFile $setupPath
    Invoke-WebRequest -UseBasicParsing -Uri "$releaseBase/ReasonKey-Setup.exe.sha256" -OutFile $checksumPath

    $expectedHash = ((Get-Content -LiteralPath $checksumPath -Raw).Trim() -split '\s+')[0]
    $actualHash = (Get-FileHash -LiteralPath $setupPath -Algorithm SHA256).Hash
    if ($actualHash -ne $expectedHash) {
        throw 'The downloaded installer checksum does not match the published checksum.'
    }
}

try {
    Unblock-File -LiteralPath $setupPath -ErrorAction SilentlyContinue
    # Wait only for the installer itself. Start-Process -Wait also waits for
    # the runtime launched by Setup.exe, which is intentionally persistent.
    $startParameters = @{
        FilePath = $setupPath
        PassThru = $true
    }
    if ($Silent) {
        $startParameters.ArgumentList = '--silent'
    }
    $process = Start-Process @startParameters
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) {
        throw "The installer exited with code $($process.ExitCode)."
    }
}
finally {
    if ($null -ne $temporaryDirectory -and (Test-Path -LiteralPath $temporaryDirectory)) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
    }
}
