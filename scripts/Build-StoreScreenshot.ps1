[CmdletBinding()]
param(
    [string]$WindowScreenshot = '.build\ReasonKey-QuickStart-window.png',
    [string]$OutputPath = 'packaging\store\assets\StoreScreenshot-ReasonKey-QuickStart.png',
    [int]$CanvasWidth = 1600,
    [int]$CanvasHeight = 900
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $WindowScreenshot))
$destinationPath = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $OutputPath))

if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Quick Start window screenshot was not found: $sourcePath"
}
if ($CanvasWidth -lt 1366 -or $CanvasHeight -lt 768) {
    throw 'The Store screenshot canvas must be at least 1366x768.'
}

$resolvedRepository = [System.IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\') + '\'
if (-not $destinationPath.StartsWith(
    $resolvedRepository,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Refusing to write outside the repository: $destinationPath"
}

Add-Type -AssemblyName System.Drawing
$source = [System.Drawing.Image]::FromFile($sourcePath)
try {
    $bitmap = [System.Drawing.Bitmap]::new(
        $CanvasWidth,
        $CanvasHeight,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.Clear([System.Drawing.Color]::FromArgb(255, 17, 24, 39))
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

            $availableWidth = $CanvasWidth - 240
            $availableHeight = $CanvasHeight - 160
            $scale = [Math]::Min(
                $availableWidth / $source.Width,
                $availableHeight / $source.Height
            )
            $drawWidth = [int][Math]::Round($source.Width * $scale)
            $drawHeight = [int][Math]::Round($source.Height * $scale)
            $x = [int][Math]::Floor(($CanvasWidth - $drawWidth) / 2)
            $y = [int][Math]::Floor(($CanvasHeight - $drawHeight) / 2)

            $shadowBrush = [System.Drawing.SolidBrush]::new(
                [System.Drawing.Color]::FromArgb(95, 0, 0, 0)
            )
            try {
                $graphics.FillRectangle(
                    $shadowBrush,
                    $x + 18,
                    $y + 22,
                    $drawWidth,
                    $drawHeight
                )
            }
            finally {
                $shadowBrush.Dispose()
            }

            $graphics.DrawImage($source, $x, $y, $drawWidth, $drawHeight)
        }
        finally {
            $graphics.Dispose()
        }

        $destinationDirectory = Split-Path -Parent $destinationPath
        New-Item -ItemType Directory -Path $destinationDirectory -Force |
            Out-Null
        $bitmap.Save(
            $destinationPath,
            [System.Drawing.Imaging.ImageFormat]::Png
        )
    }
    finally {
        $bitmap.Dispose()
    }
}
finally {
    $source.Dispose()
}

$output = Get-Item -LiteralPath $destinationPath
$hash = (Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash
Write-Host "Built Store screenshot: $destinationPath"
Write-Host "Dimensions: ${CanvasWidth}x${CanvasHeight}"
Write-Host "SHA256: $hash"

[pscustomobject]@{
    Path = $destinationPath
    Width = $CanvasWidth
    Height = $CanvasHeight
    Sha256 = $hash
    Bytes = $output.Length
}
