[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$Validate
)

$ErrorActionPreference = 'Stop'
$appName = 'Codex Model Hotkeys'
$expectedInstallDirectory = [IO.Path]::GetFullPath(
    (Join-Path $env:LOCALAPPDATA 'CodexModelHotkeys')
).TrimEnd([IO.Path]::DirectorySeparatorChar)
$scriptInstallDirectory = [IO.Path]::GetFullPath(
    (Split-Path -Parent $PSCommandPath)
).TrimEnd([IO.Path]::DirectorySeparatorChar)
$startupShortcut = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\CodexModelHotkeys.lnk'
$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\CodexModelHotkeys'

$runtimePath = Join-Path $expectedInstallDirectory 'CodexModelHotkeys.exe'
$packagesPrefix = ([IO.Path]::GetFullPath(
    (Join-Path $env:LOCALAPPDATA 'Packages')
).TrimEnd([IO.Path]::DirectorySeparatorChar)) + [IO.Path]::DirectorySeparatorChar
$codexPackagesPrefix = $packagesPrefix + 'OpenAI.Codex_'
$redirectedInstallSuffix = '\LocalCache\Local\CodexModelHotkeys'
$redirectedRuntimeSuffix = '\LocalCache\Local\CodexModelHotkeys\CodexModelHotkeys.exe'

function Test-IsExpectedInstallDirectory {
    param([string]$DirectoryPath)

    if ([string]::IsNullOrWhiteSpace($DirectoryPath)) {
        return $false
    }

    $candidate = [IO.Path]::GetFullPath($DirectoryPath).TrimEnd(
        [IO.Path]::DirectorySeparatorChar
    )
    if ($candidate.Equals($expectedInstallDirectory, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    return $candidate.StartsWith($codexPackagesPrefix, [StringComparison]::OrdinalIgnoreCase) -and
        $candidate.EndsWith($redirectedInstallSuffix, [StringComparison]::OrdinalIgnoreCase)
}

function Test-IsInstalledRuntimePath {
    param([string]$ProcessPath)

    if ([string]::IsNullOrWhiteSpace($ProcessPath)) {
        return $false
    }

    $candidate = [IO.Path]::GetFullPath($ProcessPath)
    if ($candidate.Equals($runtimePath, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    return $candidate.StartsWith($codexPackagesPrefix, [StringComparison]::OrdinalIgnoreCase) -and
        $candidate.EndsWith($redirectedRuntimeSuffix, [StringComparison]::OrdinalIgnoreCase)
}

if ($Validate) {
    $redirectedSample = Join-Path $packagesPrefix `
        'OpenAI.Codex_Test\LocalCache\Local\CodexModelHotkeys\CodexModelHotkeys.exe'
    if (-not (Test-IsInstalledRuntimePath $runtimePath)) {
        throw 'Runtime path validation rejected the installed path.'
    }
    if (-not (Test-IsInstalledRuntimePath $redirectedSample)) {
        throw 'Runtime path validation rejected the package-redirected path.'
    }
    if (Test-IsInstalledRuntimePath (Join-Path $env:LOCALAPPDATA 'Other\CodexModelHotkeys.exe')) {
        throw 'Runtime path validation accepted an unrelated path.'
    }
    $unrelatedPackageSample = Join-Path $packagesPrefix `
        'Other.Package_Test\LocalCache\Local\CodexModelHotkeys\CodexModelHotkeys.exe'
    if (Test-IsInstalledRuntimePath $unrelatedPackageSample) {
        throw 'Runtime path validation accepted another package path.'
    }
    $redirectedInstallSample = Join-Path $packagesPrefix `
        'OpenAI.Codex_Test\LocalCache\Local\CodexModelHotkeys'
    if (-not (Test-IsExpectedInstallDirectory $expectedInstallDirectory)) {
        throw 'Install directory validation rejected the canonical path.'
    }
    if (-not (Test-IsExpectedInstallDirectory $redirectedInstallSample)) {
        throw 'Install directory validation rejected the package-redirected path.'
    }
    if (Test-IsExpectedInstallDirectory (Join-Path $env:LOCALAPPDATA 'Other\CodexModelHotkeys')) {
        throw 'Install directory validation accepted an unrelated path.'
    }
    $unrelatedInstallSample = Join-Path $packagesPrefix `
        'Other.Package_Test\LocalCache\Local\CodexModelHotkeys'
    if (Test-IsExpectedInstallDirectory $unrelatedInstallSample) {
        throw 'Install directory validation accepted another package path.'
    }
    exit 0
}

if (-not $scriptInstallDirectory.Equals(
        $expectedInstallDirectory,
        [StringComparison]::OrdinalIgnoreCase
    )) {
    throw 'Refusing to remove an unexpected installation directory.'
}

if (-not $Silent) {
    Add-Type -AssemblyName PresentationFramework
    $choice = [Windows.MessageBox]::Show(
        'Remove Codex Model Hotkeys, its presets, and its logs?',
        $appName,
        [Windows.MessageBoxButton]::YesNo,
        [Windows.MessageBoxImage]::Question
    )
    if ($choice -ne [Windows.MessageBoxResult]::Yes) {
        exit 0
    }
}

Get-CimInstance Win32_Process -Filter "Name = 'CodexModelHotkeys.exe'" -ErrorAction SilentlyContinue |
    Where-Object { Test-IsInstalledRuntimePath $_.ExecutablePath } |
    ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        Wait-Process -Id $_.ProcessId -Timeout 3 -ErrorAction SilentlyContinue
    }

$installDirectoriesToRemove = @()
$packagesDirectory = $packagesPrefix.TrimEnd([IO.Path]::DirectorySeparatorChar)
if (Test-Path -LiteralPath $packagesDirectory) {
    foreach ($packageDirectory in Get-ChildItem -LiteralPath $packagesDirectory `
            -Directory -Filter 'OpenAI.Codex_*' -ErrorAction SilentlyContinue) {
        $candidate = Join-Path $packageDirectory.FullName `
            'LocalCache\Local\CodexModelHotkeys'
        if ((Test-Path -LiteralPath $candidate) -and
            (Test-IsExpectedInstallDirectory $candidate)) {
            $installDirectoriesToRemove += [IO.Path]::GetFullPath($candidate)
        }
    }
}
$installDirectoriesToRemove += $expectedInstallDirectory

foreach ($installDirectory in $installDirectoriesToRemove | Select-Object -Unique) {
    if (-not (Test-IsExpectedInstallDirectory $installDirectory)) {
        throw "Refusing to remove an unexpected installation directory: $installDirectory"
    }
    if (Test-Path -LiteralPath $installDirectory) {
        Remove-Item -LiteralPath $installDirectory -Recurse -Force
    }
}
if (Test-Path -LiteralPath $startupShortcut) {
    Remove-Item -LiteralPath $startupShortcut -Force
}
if (Test-Path -LiteralPath $uninstallKey) {
    Remove-Item -LiteralPath $uninstallKey -Recurse -Force
}

if (-not $Silent) {
    [Windows.MessageBox]::Show(
        'Codex Model Hotkeys was removed.',
        $appName,
        [Windows.MessageBoxButton]::OK,
        [Windows.MessageBoxImage]::Information
    ) | Out-Null
}
