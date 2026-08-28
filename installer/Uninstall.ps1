[CmdletBinding()]
param(
    [switch]$Silent
)

$ErrorActionPreference = 'Stop'
$appName = 'Codex Model Hotkeys'
$expectedInstallDirectory = [IO.Path]::GetFullPath(
    (Join-Path $env:LOCALAPPDATA 'CodexModelHotkeys')
).TrimEnd([IO.Path]::DirectorySeparatorChar)
$startupShortcut = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\CodexModelHotkeys.lnk'
$uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\CodexModelHotkeys'

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

$runtimePath = Join-Path $expectedInstallDirectory 'CodexModelHotkeys.exe'
Get-CimInstance Win32_Process -Filter "Name = 'CodexModelHotkeys.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.ExecutablePath -eq $runtimePath } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

if (Test-Path -LiteralPath $startupShortcut) {
    Remove-Item -LiteralPath $startupShortcut -Force
}
if (Test-Path -LiteralPath $uninstallKey) {
    Remove-Item -LiteralPath $uninstallKey -Recurse -Force
}

if ($expectedInstallDirectory -ne [IO.Path]::GetFullPath(
        (Join-Path $env:LOCALAPPDATA 'CodexModelHotkeys')
    ).TrimEnd([IO.Path]::DirectorySeparatorChar)) {
    throw 'Refusing to remove an unexpected installation directory.'
}

if (Test-Path -LiteralPath $expectedInstallDirectory) {
    Remove-Item -LiteralPath $expectedInstallDirectory -Recurse -Force
}

if (-not $Silent) {
    [Windows.MessageBox]::Show(
        'Codex Model Hotkeys was removed.',
        $appName,
        [Windows.MessageBoxButton]::OK,
        [Windows.MessageBoxImage]::Information
    ) | Out-Null
}
