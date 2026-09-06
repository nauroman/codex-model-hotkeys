[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$paths = @(git -C $projectRoot ls-files --cached --others --exclude-standard -- '*.md')
if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate repository documentation.' }
$paths = @($paths | Where-Object { $_ -and $_ -notmatch '^vendor/' } | Sort-Object -Unique)
$issues = [Collections.Generic.List[string]]::new()
$routerPath = Join-Path $projectRoot 'docs/product-spec.md'
if (-not (Test-Path -LiteralPath $routerPath)) { throw 'Missing product specification router.' }
$router = Get-Content -LiteralPath $routerPath -Raw
$checkedCount = 0

foreach ($relativePath in $paths) {
    $fullPath = Join-Path $projectRoot $relativePath
    # A tracked deletion remains in git ls-files until committed.
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) { continue }
    $checkedCount++
    $lines = @(Get-Content -LiteralPath $fullPath)
    $fence = ''
    $headingLevel = 0
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        $location = '{0}:{1}' -f $relativePath, ($index + 1)
        if ($line -match '[ \t]+$') { $issues.Add("Trailing whitespace: $location") }
        if ($line -match '^\s*(\x60{3,}|~{3,})') {
            $marker = $Matches[1]
            if (-not $fence) { $fence = $marker }
            elseif ($marker[0] -eq $fence[0] -and $marker.Length -ge $fence.Length) { $fence = '' }
            continue
        }
        if ($fence) { continue }
        if ($line -match '^(#{1,6})\s+') {
            $level = $Matches[1].Length
            if ($headingLevel -gt 0 -and $level -gt ($headingLevel + 1)) {
                $issues.Add("Skipped heading level: $location")
            }
            $headingLevel = $level
            if ($index -gt 0 -and -not [string]::IsNullOrWhiteSpace($lines[$index - 1])) {
                $issues.Add("Missing blank line before heading: $location")
            }
            if ($index + 1 -lt $lines.Count -and -not [string]::IsNullOrWhiteSpace($lines[$index + 1])) {
                $issues.Add("Missing blank line after heading: $location")
            }
        }
        # Validate local file targets, not external URLs or heading fragments.
        foreach ($match in [regex]::Matches($line, '\[[^\]]*\]\(([^)]+)\)')) {
            $target = $match.Groups[1].Value.Trim().Trim('<', '>')
            if ($target -match '^(?:[a-z][a-z0-9+.-]*:|#)') { continue }
            $targetPath = ($target -split '#', 2)[0]
            if (-not $targetPath) { continue }
            try {
                $decoded = [Uri]::UnescapeDataString($targetPath)
                $resolved = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $fullPath) $decoded))
                if (-not (Test-Path -LiteralPath $resolved)) {
                    $issues.Add("Broken relative link: $location -> $target")
                }
            }
            catch { $issues.Add("Invalid relative link: $location -> $target") }
        }
    }
    if ($fence) { $issues.Add("Unclosed code fence: $relativePath") }

    if ($relativePath -match '^docs/product-spec/(.+\.md)$') {
        $ownerPath = $Matches[1]
        $header = ($lines | Select-Object -First 8) -join [Environment]::NewLine
        if ($lines.Count -eq 0 -or $lines[0] -notmatch '^# ') {
            $issues.Add("Missing owner title: $relativePath")
        }
        if ($header -notmatch 'Canonical owner|Canonical router') {
            $issues.Add("Missing owner declaration: $relativePath")
        }
        if (-not $router.Contains('(product-spec/' + $ownerPath + ')')) {
            $issues.Add("Specification missing from core routing: $relativePath")
        }
        if ((Get-Item -LiteralPath $fullPath).Length -gt 12KB) {
            Write-Warning "Review ownership/context size: $relativePath exceeds 12 KiB. Split by responsibility; preserve rules."
        }
    }
}

foreach ($required in @('README.md', 'AGENTS.md', 'docs/HOW_IT_WORKS.md', 'docs/PROJECT_CONTEXT.md', 'docs/DEVELOPMENT.md')) {
    $fullPath = Join-Path $projectRoot $required
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        $issues.Add("Missing entry point: $required")
    }
    elseif ((Get-Content -LiteralPath $fullPath -Raw) -notmatch '\]\((?:docs/)?product-spec\.md\)') {
        $issues.Add("Entry point must link the product core: $required")
    }
}
if ($issues.Count -gt 0) {
    throw ("Documentation validation failed:" + [Environment]::NewLine +
        (($issues | Sort-Object -Unique) -join [Environment]::NewLine))
}
Write-Host "STATIC_DOCUMENTATION_VALIDATION=PASS files=$checkedCount"
