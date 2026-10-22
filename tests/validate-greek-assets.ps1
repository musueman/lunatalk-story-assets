$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$greekRoot = Join-Path $root 'greek'
$manifestPath = Join-Path $greekRoot 'source-manifest.csv'
$mapPath = Join-Path $greekRoot 'webp-map.json'
$reportPath = Join-Path $greekRoot 'raw-url-report.csv'

foreach ($path in @($manifestPath, $mapPath, $reportPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "missing Greek asset contract file: $path" }
}

$manifest = @(Import-Csv -LiteralPath $manifestPath)
$map = Get-Content -Raw -LiteralPath $mapPath | ConvertFrom-Json
$report = @(Import-Csv -LiteralPath $reportPath)

if ($manifest.Count -ne 218) { throw "expected 218 source manifest rows, found $($manifest.Count)" }
if (($manifest | Select-Object -ExpandProperty source_media_id -Unique).Count -ne 218) { throw 'source media IDs must be unique' }
if (($manifest | Select-Object -ExpandProperty asset_code -Unique).Count -ne 218) { throw 'asset codes must be unique' }
if (($manifest | Where-Object { $_.source_sha256_before -notmatch '^[0-9a-f]{64}$' -or $_.source_sha256_after -ne $_.source_sha256_before }).Count) { throw 'source hash preservation evidence is incomplete' }
if (($manifest | Where-Object { $_.source_original_preserved -ne 'true' -or $_.webp_sha256 -notmatch '^[0-9a-f]{64}$' }).Count) { throw 'original preservation or WebP hash evidence is incomplete' }
if (($manifest | Where-Object { $_.safety_class -notin @('SFW', 'NSFW') }).Count) { throw 'each source item needs an explicit SFW or NSFW class' }

$sfw = @($manifest | Where-Object safety_class -eq 'SFW')
$nsfw = @($manifest | Where-Object safety_class -eq 'NSFW')
if ($sfw.Count -ne 135) { throw "expected 135 SFW rows, found $($sfw.Count)" }
if ($nsfw.Count -ne 83) { throw "expected 83 NSFW rows, found $($nsfw.Count)" }

if ($map.source_inventory.local_png_total -ne 218) { throw 'map must declare the 218 local PNG inventory' }
if ($map.source_inventory.crack_observed_total -ne 222) { throw 'map must preserve the historical Crack total separately' }
if ($map.source_inventory.unresolved_difference -ne 4) { throw 'map must declare four unresolved source items' }
if ($map.items.Count -ne 218) { throw "expected 218 map items, found $($map.items.Count)" }
if (($map.items | Where-Object { $_.asset_code -notmatch '^GRC-(SFW|NSFW)-C\d{2}-(S|N)\d{2}$' }).Count) { throw 'map contains a malformed explicit asset code' }
if (($map.items | Where-Object { $_.missing_or_unmapped_code_rule -ne 'no_image_call' }).Count) { throw 'each item must preserve the no-image-call fallback' }
if ($map.character_registry.Count -ne 9) { throw 'map must expose all nine explicit character codes' }

foreach ($item in $map.items) {
    $webp = Join-Path $root $item.path
    if (-not (Test-Path -LiteralPath $webp -PathType Leaf)) { throw "mapped WebP is missing: $($item.path)" }
}

if ($report.Count -ne 218) { throw "expected 218 Raw URL report rows, found $($report.Count)" }
$rawStatuses = @($report | Select-Object -ExpandProperty check_status -Unique)
if ($rawStatuses.Count -ne 1 -or $rawStatuses[0] -notin @('pending_push', 'verified')) { throw 'Raw report must be wholly pending_push or wholly verified' }

Write-Output 'PASS: Greek local asset conversion contract is complete before publication verification.'
