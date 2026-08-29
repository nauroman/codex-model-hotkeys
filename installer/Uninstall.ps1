[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$Validate
)

$ErrorActionPreference = 'Stop'
$appName = 'ReasonKey'
$expectedInstallDirectory = [IO.Path]::GetFullPath(
    (Join-Path $env:LOCALAPPDATA 'ReasonKey')
).TrimEnd([IO.Path]::DirectorySeparatorChar)
$legacyInstallDirectory = [IO.Path]::GetFullPath(
    (Join-Path $env:LOCALAPPDATA 'CodexModelHotkeys')
).TrimEnd([IO.Path]::DirectorySeparatorChar)
$scriptInstallDirectory = [IO.Path]::GetFullPath(
    (Split-Path -Parent $PSCommandPath)
).TrimEnd([IO.Path]::DirectorySeparatorChar)
$startupShortcut = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\ReasonKey.lnk'
$legacyStartupShortcut = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\CodexModelHotkeys.lnk'
$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ReasonKey'
$legacyUninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\CodexModelHotkeys'

$runtimePath = Join-Path $expectedInstallDirectory 'ReasonKey.exe'
$legacyRuntimePath = Join-Path $legacyInstallDirectory 'CodexModelHotkeys.exe'
$packagesPrefix = ([IO.Path]::GetFullPath(
    (Join-Path $env:LOCALAPPDATA 'Packages')
).TrimEnd([IO.Path]::DirectorySeparatorChar)) + [IO.Path]::DirectorySeparatorChar
$codexPackagesPrefix = $packagesPrefix + 'OpenAI.Codex_'
$redirectedInstallSuffixes = @(
    '\LocalCache\Local\ReasonKey',
    '\LocalCache\Local\CodexModelHotkeys'
)
$redirectedRuntimeSuffixes = @(
    '\LocalCache\Local\ReasonKey\ReasonKey.exe',
    '\LocalCache\Local\CodexModelHotkeys\CodexModelHotkeys.exe'
)

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
    if ($candidate.Equals($legacyInstallDirectory, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    if (-not $candidate.StartsWith($codexPackagesPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }
    foreach ($suffix in $redirectedInstallSuffixes) {
        if ($candidate.EndsWith($suffix, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
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
    if ($candidate.Equals($legacyRuntimePath, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    if (-not $candidate.StartsWith($codexPackagesPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }
    foreach ($suffix in $redirectedRuntimeSuffixes) {
        if ($candidate.EndsWith($suffix, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

if ($Validate) {
    $redirectedSample = Join-Path $packagesPrefix `
        'OpenAI.Codex_Test\LocalCache\Local\ReasonKey\ReasonKey.exe'
    if (-not (Test-IsInstalledRuntimePath $runtimePath)) {
        throw 'Runtime path validation rejected the installed path.'
    }
    if (-not (Test-IsInstalledRuntimePath $redirectedSample)) {
        throw 'Runtime path validation rejected the package-redirected path.'
    }
    if (-not (Test-IsInstalledRuntimePath $legacyRuntimePath)) {
        throw 'Runtime path validation rejected the legacy installed path.'
    }
    if (Test-IsInstalledRuntimePath (Join-Path $env:LOCALAPPDATA 'Other\ReasonKey.exe')) {
        throw 'Runtime path validation accepted an unrelated path.'
    }
    $unrelatedPackageSample = Join-Path $packagesPrefix `
        'Other.Package_Test\LocalCache\Local\ReasonKey\ReasonKey.exe'
    if (Test-IsInstalledRuntimePath $unrelatedPackageSample) {
        throw 'Runtime path validation accepted another package path.'
    }
    $redirectedInstallSample = Join-Path $packagesPrefix `
        'OpenAI.Codex_Test\LocalCache\Local\ReasonKey'
    if (-not (Test-IsExpectedInstallDirectory $expectedInstallDirectory)) {
        throw 'Install directory validation rejected the canonical path.'
    }
    if (-not (Test-IsExpectedInstallDirectory $redirectedInstallSample)) {
        throw 'Install directory validation rejected the package-redirected path.'
    }
    if (-not (Test-IsExpectedInstallDirectory $legacyInstallDirectory)) {
        throw 'Install directory validation rejected the legacy path.'
    }
    if (Test-IsExpectedInstallDirectory (Join-Path $env:LOCALAPPDATA 'Other\ReasonKey')) {
        throw 'Install directory validation accepted an unrelated path.'
    }
    $unrelatedInstallSample = Join-Path $packagesPrefix `
        'Other.Package_Test\LocalCache\Local\ReasonKey'
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
        'Remove ReasonKey, its presets, and its logs?',
        $appName,
        [Windows.MessageBoxButton]::YesNo,
        [Windows.MessageBoxImage]::Question
    )
    if ($choice -ne [Windows.MessageBoxResult]::Yes) {
        exit 0
    }
}

Get-CimInstance Win32_Process -Filter "Name = 'ReasonKey.exe' OR Name = 'CodexModelHotkeys.exe'" -ErrorAction SilentlyContinue |
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
        foreach ($relativeDirectory in @('LocalCache\Local\ReasonKey', 'LocalCache\Local\CodexModelHotkeys')) {
            $candidate = Join-Path $packageDirectory.FullName $relativeDirectory
            if ((Test-Path -LiteralPath $candidate) -and
                (Test-IsExpectedInstallDirectory $candidate)) {
                $installDirectoriesToRemove += [IO.Path]::GetFullPath($candidate)
            }
        }
    }
}
$installDirectoriesToRemove += $expectedInstallDirectory
$installDirectoriesToRemove += $legacyInstallDirectory

foreach ($installDirectory in $installDirectoriesToRemove | Select-Object -Unique) {
    if (-not (Test-IsExpectedInstallDirectory $installDirectory)) {
        throw "Refusing to remove an unexpected installation directory: $installDirectory"
    }
    if (Test-Path -LiteralPath $installDirectory) {
        Remove-Item -LiteralPath $installDirectory -Recurse -Force
    }
}
foreach ($shortcut in @($startupShortcut, $legacyStartupShortcut)) {
    if (Test-Path -LiteralPath $shortcut) {
        Remove-Item -LiteralPath $shortcut -Force
    }
}
foreach ($key in @($uninstallKey, $legacyUninstallKey)) {
    if (Test-Path -LiteralPath $key) {
        Remove-Item -LiteralPath $key -Recurse -Force
    }
}

if (-not $Silent) {
    [Windows.MessageBox]::Show(
        'ReasonKey was removed.',
        $appName,
        [Windows.MessageBoxButton]::OK,
        [Windows.MessageBoxImage]::Information
    ) | Out-Null
}
