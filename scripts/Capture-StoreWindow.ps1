[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [int]$ProcessId,
    [string]$OutputPath = '.build\ReasonKey-QuickStart-window.png'
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$destinationPath = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $OutputPath))
$resolvedRepository = [System.IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\') + '\'
if (-not $destinationPath.StartsWith(
    $resolvedRepository,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Refusing to write outside the repository: $destinationPath"
}

$process = Get-Process -Id $ProcessId -ErrorAction Stop
$process.WaitForInputIdle(5000) | Out-Null
$process.Refresh()
if ($process.MainWindowHandle -eq [IntPtr]::Zero) {
    throw "Process $ProcessId does not have a visible main window."
}

Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class ReasonKeyStoreScreenshotNative
{
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("dwmapi.dll")]
    public static extern int DwmGetWindowAttribute(
        IntPtr hwnd,
        int attribute,
        out RECT value,
        int valueSize);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdc, uint flags);
}
'@

$bounds = [ReasonKeyStoreScreenshotNative+RECT]::new()
$result = [ReasonKeyStoreScreenshotNative]::DwmGetWindowAttribute(
    $process.MainWindowHandle,
    9,
    [ref]$bounds,
    [Runtime.InteropServices.Marshal]::SizeOf($bounds)
)
if ($result -ne 0) {
    throw "DwmGetWindowAttribute failed with HRESULT 0x$('{0:X8}' -f $result)."
}

$width = $bounds.Right - $bounds.Left
$height = $bounds.Bottom - $bounds.Top
if ($width -le 0 -or $height -le 0) {
    throw "Invalid window bounds: ${width}x${height}."
}

$bitmap = [System.Drawing.Bitmap]::new(
    $width,
    $height,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
)
try {
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $deviceContext = $graphics.GetHdc()
        try {
            $captured = [ReasonKeyStoreScreenshotNative]::PrintWindow(
                $process.MainWindowHandle,
                $deviceContext,
                2
            )
        }
        finally {
            $graphics.ReleaseHdc($deviceContext)
        }
        if (-not $captured) {
            $graphics.CopyFromScreen(
                $bounds.Left,
                $bounds.Top,
                0,
                0,
                [System.Drawing.Size]::new($width, $height),
                [System.Drawing.CopyPixelOperation]::SourceCopy
            )
        }
    }
    finally {
        $graphics.Dispose()
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $destinationPath) `
        -Force | Out-Null
    $bitmap.Save($destinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $bitmap.Dispose()
}

$hash = (Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash
Write-Host "Captured Store preview window: $destinationPath"
Write-Host "Dimensions: ${width}x${height}"
Write-Host "SHA256: $hash"

[pscustomobject]@{
    Path = $destinationPath
    Width = $width
    Height = $height
    Sha256 = $hash
}
