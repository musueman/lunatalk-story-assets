param([string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = 'Stop'
$RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$sourceMapPath = Join-Path $RepositoryRoot 'greek/webp-map.json'
$sourceMap = Get-Content -Raw -LiteralPath $sourceMapPath | ConvertFrom-Json
if ($sourceMap.items.Count -ne 218) { throw 'Expected the existing 218-item source registry.' }

$sfwLabels = @('평온','미소','기쁨','웃음','수줍음','놀람','불신·걱정','짜증·질투','분노','격노','슬픔','비통','결의','안도','능청·장난')
$nsfwLabels = @('키스','가슴애무','밀착손길','손자극','구강','구강심화','가슴자극','정상위 시작','정상위 절정','후배위 시작','후배위 절정','기승위 시작','기승위 절정','측위 시작','측위 절정','대면착석 시작','대면착석 절정','들어올리기 절정')
$extras = @{
    '01' = @('들기절정','정면절정','측면절정','후면절정')
    '02' = @('정면절정','측면절정','후면절정')
    '06' = @('대면절정','후면절정')
    '07' = @('정면절정','후면절정')
}
$items = [System.Collections.Generic.List[object]]::new()
$destinations = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$sourcePaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)

# Preflight every source and destination before creating any copy. Never overwrite
# an existing different file; neither split folder is a mutation target.
foreach ($source in $sourceMap.items) {
    if ($source.path -cnotmatch '^greek/(sfw/C0[1-9]/S(?:0[1-9]|1[0-5])|nsfw/C(?:01|02|06|07)/N(?:0[1-9]|1[0-9]|2[0-2]))\.webp$') { throw "Unexpected source path: $($source.path)" }
    if (-not $sourcePaths.Add($source.path)) { throw 'Duplicate source path.' }
    $sourcePath = Join-Path $RepositoryRoot $source.path
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Missing source: $($source.path)" }
    $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($sourceHash -cne $source.webp_sha256) { throw "Source hash differs from registry: $($source.path)" }
    if ($source.path -ceq 'greek/nsfw/C01/N22.webp') { continue }
    $character = $source.character_code.Substring(1)
    $sourceNumber = [int]$source.situation_code.Substring(1)
    if ($source.safety_class -ceq 'SFW' -and $source.situation_code -cmatch '^S(?:0[1-9]|1[0-5])$') {
        $action = $sourceNumber
        $label = $sfwLabels[$action - 1]
    } elseif ($source.safety_class -ceq 'NSFW' -and $extras.ContainsKey($character)) {
        # Amphitrite has no missionary-peak source: N09 is rear-entry. All
        # following source numbers shift once; C01/N22 remains quarantined.
        $action = $sourceNumber + 15
        if ($character -ceq '01' -and $sourceNumber -ge 9) { $action++ }
        $label = if ($action -le 33) { $nsfwLabels[$action - 16] } else { $extras[$character][$action - 34] }
    } else { throw "Unsupported source class/code: $($source.asset_code)" }
    if ([string]::IsNullOrWhiteSpace($label)) { throw "No approved label for $($source.asset_code)" }
    $flatPath = 'greek/{0}/{1:D2}.webp' -f $character,$action
    if ($flatPath -cnotmatch '^greek/0[1-9]/(?:0[1-9]|[12][0-9]|3[0-7])\.webp$' -or -not $destinations.Add($flatPath)) { throw "Invalid/duplicate flat path: $flatPath" }
    $destination = Join-Path $RepositoryRoot $flatPath
    if (Test-Path -LiteralPath $destination) {
        if (-not (Test-Path -LiteralPath $destination -PathType Leaf) -or (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant() -cne $sourceHash) { throw "Refusing to overwrite different destination: $flatPath" }
    }
    $items.Add([pscustomobject][ordered]@{
        source_asset_code = $source.asset_code
        source_path = $source.path
        flat_path = $flatPath
        character_number = $character
        character_slug = $source.character_slug
        action_number = '{0:D2}' -f $action
        label = $label
        source_label = $source.situation_label
        safety_class = $source.safety_class
        sha256 = $sourceHash
    })
}
if ($items.Count -ne 217 -or @($items | Where-Object safety_class -eq 'SFW').Count -ne 135 -or @($items | Where-Object safety_class -eq 'NSFW').Count -ne 82) { throw 'Projection counts do not match 217 / 135 / 82.' }
foreach ($item in $items) {
    $destination = Join-Path $RepositoryRoot $item.flat_path
    if (-not (Test-Path -LiteralPath $destination)) {
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force
        Copy-Item -LiteralPath (Join-Path $RepositoryRoot $item.source_path) -Destination $destination -ErrorAction Stop
    }
}
$flatMap = [ordered]@{
    schema_version = 1
    source_registry = 'greek/webp-map.json'
    source_registry_commit = 'e79513d167a66f0d495dd50df1a1e596f0191cf0'
    source_registry_sha256 = (Get-FileHash -LiteralPath $sourceMapPath -Algorithm SHA256).Hash.ToLowerInvariant()
    path_template = 'greek/{character}/{action}.webp'
    raw_url_template = 'https://raw.githubusercontent.com/musueman/lunatalk-story-assets/main/greek/{character}/{action}.webp'
    counts = [ordered]@{ callable = 217; SFW = 135; NSFW = 82; legacy_preserved = 218 }
    guards = @('two_digit_numbers_only','registered_pairs_only','no_image_call_for_absent_pair','explicit_adult_consent_before_NSFW','images_do_not_establish_narrative_facts')
    excluded = @([ordered]@{
        source_asset_code = 'GRC-NSFW-C01-N22'
        source_path = 'greek/nsfw/C01/N22.webp'
        reason = 'Registered C01/amphitrite conflicts with Hera source label; identity unresolved; do not project or call.'
    })
    items = @($items | Sort-Object character_number,action_number)
}
$json = ($flatMap | ConvertTo-Json -Depth 8) + "`n"
[IO.File]::WriteAllText((Join-Path $RepositoryRoot 'greek/flat-map.json'), $json, [Text.UTF8Encoding]::new($false))
Write-Output 'BUILT GREEK_FLAT: 217 byte copies and flat-map.json; no legacy path modified.'
