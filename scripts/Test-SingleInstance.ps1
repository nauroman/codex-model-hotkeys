[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$RuntimePath
)

$ErrorActionPreference = 'Stop'
$resolvedRuntimePath = (Resolve-Path -LiteralPath $RuntimePath).Path
$temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$testDirectory = Join-Path $temporaryRoot (
    'ReasonKey-SingleInstance-' + [guid]::NewGuid().ToString('N')
)
$testDirectory = [IO.Path]::GetFullPath($testDirectory)
if (-not $testDirectory.StartsWith(
        $temporaryRoot,
        [StringComparison]::OrdinalIgnoreCase
    )) {
    throw "Refusing to use a singleton test directory outside the temporary root: $testDirectory"
}

$firstProcess = $null
$secondProcess = $null
try {
    $directDirectory = Join-Path $testDirectory 'direct'
    $storeDirectory = Join-Path $testDirectory 'store'
    New-Item -ItemType Directory -Path $directDirectory, $storeDirectory -Force |
        Out-Null

    $directRuntimePath = Join-Path $directDirectory 'ReasonKey.exe'
    $storeRuntimePath = Join-Path $storeDirectory 'ReasonKey.exe'
    Copy-Item -LiteralPath $resolvedRuntimePath -Destination $directRuntimePath
    Copy-Item -LiteralPath $resolvedRuntimePath -Destination $storeRuntimePath

    $probeToken = [guid]::NewGuid().ToString('N')
    $probeArguments = @('--singleton-probe', $probeToken)
    $mutexName = "Local\RotorlashLabs.ReasonKey.Runtime.Test.$probeToken"

    $firstProcess = Start-Process -FilePath $directRuntimePath `
        -ArgumentList $probeArguments -PassThru -WindowStyle Hidden

    $mutexReady = $false
    $deadline = [DateTime]::UtcNow.AddSeconds(5)
    while ([DateTime]::UtcNow -lt $deadline) {
        try {
            $mutex = [Threading.Mutex]::OpenExisting($mutexName)
            $mutex.Dispose()
            $mutexReady = $true
            break
        }
        catch [Threading.WaitHandleCannotBeOpenedException] {
            Start-Sleep -Milliseconds 50
        }
    }
    if (-not $mutexReady) {
        throw 'The first copied runtime did not publish its singleton mutex.'
    }

    $secondProcess = Start-Process -FilePath $storeRuntimePath `
        -ArgumentList $probeArguments -PassThru -Wait -WindowStyle Hidden
    if ($secondProcess.ExitCode -ne 73) {
        throw "The second copied runtime was not rejected. Exit code: $($secondProcess.ExitCode)"
    }

    if (-not $firstProcess.WaitForExit(10000)) {
        throw 'The first copied runtime did not finish its singleton probe.'
    }
    if ($firstProcess.ExitCode -ne 0) {
        throw "The first copied runtime singleton probe failed. Exit code: $($firstProcess.ExitCode)"
    }

    Write-Host 'Cross-path singleton validation passed.'
}
finally {
    foreach ($process in @($secondProcess, $firstProcess)) {
        if ($null -ne $process -and -not $process.HasExited) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            Wait-Process -Id $process.Id -Timeout 3 -ErrorAction SilentlyContinue
        }
    }
    if (Test-Path -LiteralPath $testDirectory) {
        Remove-Item -LiteralPath $testDirectory -Recurse -Force
    }
}
