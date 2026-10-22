param([string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = 'Stop'
$RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$flatMapPath = Join-Path $RepositoryRoot 'greek/flat-map.json'
if (-not (Test-Path -LiteralPath $flatMapPath -PathType Leaf)) {
    throw 'FLAT_MAP_MISSING: expected the 217-item Greek numeric projection.'
}
$flat = Get-Content -Raw -LiteralPath $flatMapPath | ConvertFrom-Json
$legacy = Get-Content -Raw -LiteralPath (Join-Path $RepositoryRoot 'greek/webp-map.json') | ConvertFrom-Json
if ($flat.schema_version -ne 1 -or $flat.path_template -cne 'greek/{character}/{action}.webp') { throw 'Wrong flat-map contract.' }
if ($flat.raw_url_template -cne 'https://raw.githubusercontent.com/musueman/lunatalk-story-assets/main/greek/{character}/{action}.webp') { throw 'Wrong approved Raw URL template.' }
if ($flat.source_registry_commit -cne 'e79513d167a66f0d495dd50df1a1e596f0191cf0') { throw 'Wrong immutable source registry commit.' }
if ($legacy.items.Count -ne 218) { throw 'Legacy registry must remain at 218 items.' }
if ($flat.items.Count -ne 217) { throw "Expected 217 projected records, got $($flat.items.Count)." }
if (@($flat.items | Where-Object safety_class -eq 'SFW').Count -ne 135) { throw 'Expected 135 projected SFW records.' }
if (@($flat.items | Where-Object safety_class -eq 'NSFW').Count -ne 82) { throw 'Expected 82 projected NSFW records.' }

$quarantine = @($flat.excluded | Where-Object { $_.source_path -ceq 'greek/nsfw/C01/N22.webp' })
if ($flat.excluded.Count -ne 1 -or $quarantine.Count -ne 1 -or -not $quarantine[0].reason) { throw 'Exactly C01/N22 must be explicitly quarantined.' }
foreach ($property in @('source_asset_code', 'source_path', 'flat_path')) {
    if (@($flat.items.$property | Select-Object -Unique).Count -ne 217) { throw "Duplicate or missing $property." }
}

# Literal specification expectations, independent of the builder's arithmetic.
$allowedNsfw = @{
    '01' = @(16,17,18,19,20,21,22,23,25,26,27,28,29,30,31,32,33,34,35,36,37)
    '02' = @(16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36)
    '06' = @(16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35)
    '07' = @(16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35)
}
$sfwLabels = @('평온','미소','기쁨','웃음','수줍음','놀람','불신·걱정','짜증·질투','분노','격노','슬픔','비통','결의','안도','능청·장난')
$nsfwLabels = @('키스','가슴애무','밀착손길','손자극','구강','구강심화','가슴자극','정상위 시작','정상위 절정','후배위 시작','후배위 절정','기승위 시작','기승위 절정','측위 시작','측위 절정','대면착석 시작','대면착석 절정','들어올리기 절정')
$extras = @{
    '01' = @('들기절정','정면절정','측면절정','후면절정')
    '02' = @('정면절정','측면절정','후면절정')
    '06' = @('대면절정','후면절정')
    '07' = @('정면절정','후면절정')
}
$characterSlugs = @('amphitrite','aphrodite','ares','hades','hephaestus','hera','persephone','poseidon','zeus')
$expectedPaths = [System.Collections.Generic.List[string]]::new()
for ($character = 1; $character -le 9; $character++) {
    $number = '{0:D2}' -f $character
    foreach ($action in 1..15) { $expectedPaths.Add(('greek/{0}/{1:D2}.webp' -f $number,$action)) }
    foreach ($action in $allowedNsfw[$number]) { $expectedPaths.Add(('greek/{0}/{1:D2}.webp' -f $number,$action)) }
}
if (@(Compare-Object @($expectedPaths) @($flat.items.flat_path)).Count) { throw 'Flat paths differ from the approved callable set.' }

$legacyFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'greek/sfw') -Recurse -File -Filter '*.webp'
    Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'greek/nsfw') -Recurse -File -Filter '*.webp'
)
if ($legacyFiles.Count -ne 218) { throw 'Legacy split folders must retain all 218 WebPs.' }
$sourceByCode = @{}
foreach ($source in $legacy.items) {
    if ($source.path -cnotmatch '^greek/(sfw/C[0-9]{2}/S[0-9]{2}|nsfw/C[0-9]{2}/N[0-9]{2})\.webp$') { throw 'Unsafe legacy path.' }
    $path = Join-Path $RepositoryRoot $source.path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing legacy path: $($source.path)" }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $source.webp_sha256) { throw "Legacy hash changed: $($source.path)" }
    $sourceByCode[$source.asset_code] = $source
}
foreach ($item in $flat.items) {
    $source = $sourceByCode[$item.source_asset_code]
    if (-not $source -or $source.path -cne $item.source_path -or $source.situation_label -cne $item.source_label -or $source.safety_class -cne $item.safety_class) { throw "Lost provenance: $($item.flat_path)" }
    if ($source.path -ceq 'greek/nsfw/C01/N22.webp') { throw 'Quarantined source must never be copied.' }
    $number = $source.character_code.Substring(1)
    if ($item.character_number -cne $number -or $item.character_slug -cne $characterSlugs[[int]$number - 1]) { throw 'Wrong character identity.' }
    if ($source.safety_class -ceq 'SFW') {
        $expectedAction = [int]$source.situation_code.Substring(1)
        $expectedLabel = $sfwLabels[$expectedAction - 1]
    } elseif ($source.safety_class -ceq 'NSFW' -and $allowedNsfw.ContainsKey($number)) {
        $expectedAction = $allowedNsfw[$number][[int]$source.situation_code.Substring(1) - 1]
        $expectedLabel = if ($expectedAction -le 33) { $nsfwLabels[$expectedAction - 16] } else { $extras[$number][$expectedAction - 34] }
    } else { throw 'Unknown safety class or absent NSFW character.' }
    if ($item.action_number -cne ('{0:D2}' -f $expectedAction) -or $item.label -cne $expectedLabel -or $item.flat_path -cne ('greek/{0}/{1:D2}.webp' -f $number,$expectedAction)) { throw "Wrong action mapping: $($source.asset_code)" }
    $projected = Join-Path $RepositoryRoot $item.flat_path
    if (-not (Test-Path -LiteralPath $projected -PathType Leaf)) { throw "Missing projected WebP: $($item.flat_path)" }
    $hash = (Get-FileHash -LiteralPath $projected -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -cne $source.webp_sha256 -or $item.sha256 -cne $source.webp_sha256) { throw "Byte/hash mismatch: $($item.flat_path)" }
}
$actualFlat = @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'greek') -Directory | Where-Object Name -Match '^0[1-9]$' | ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Recurse -File })
$actualPaths = @($actualFlat | ForEach-Object { [IO.Path]::GetRelativePath($RepositoryRoot, $_.FullName).Replace('\','/') })
if ($actualFlat.Count -ne 217 -or @(Compare-Object @($expectedPaths) $actualPaths).Count) { throw 'Unexpected/missing files in numeric folders.' }
Write-Output 'PASS GREEK_FLAT: 217 byte-identical copies; 135 SFW; 82 NSFW; 218 legacy hashes preserved; exact universal actions and C01/N22 exclusion.'
