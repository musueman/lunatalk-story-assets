$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$assetRoot = Join-Path $root 'apoc'
$expectedCounts = @{ '01' = 40; '02' = 61; '03' = 61 }

foreach ($character in $expectedCounts.Keys) {
  $dir = Join-Path $assetRoot $character
  if (-not (Test-Path $dir -PathType Container)) { throw "missing character folder: $character" }
  $expected = 1..$expectedCounts[$character] | ForEach-Object { '{0:D2}.webp' -f $_ }
  $actual = Get-ChildItem $dir -File -Filter '*.webp' | ForEach-Object Name | Sort-Object
  $missing = $expected | Where-Object { $_ -notin $actual }
  $extra = $actual | Where-Object { $_ -notin $expected }
  if ($missing) { throw "missing files for ${character}: $($missing -join ', ')" }
  if ($extra) { throw "unexpected files for ${character}: $($extra -join ', ')" }
}

$map = Get-Content -Raw (Join-Path $assetRoot 'map.json') | ConvertFrom-Json
if ($map.version -ne 2) { throw "map version must be 2" }
if ($map.pathTemplate -ne '{character}/{action}.webp') { throw "unexpected path template" }

$doyoon = $map.characters | Where-Object code -eq '01'
if ($doyoon.images.Count -ne 40) { throw '강도윤 must expose exactly 40 actions' }
foreach ($character in @('02', '03')) {
  $entry = $map.characters | Where-Object code -eq $character
  if ($entry.images.Count -ne 61) { throw "character $character must expose 61 actions" }
  if (($entry.images | Where-Object id -eq '53').label -ne '후배위 시작') { throw "character $character action 53 must be 후배위 시작" }
  if (($entry.images | Where-Object id -eq '54').label -ne '후배위 절정') { throw "character $character action 54 must be 후배위 절정" }
}

Write-Output 'PASS: Apocalypse flat image contract is complete.'
