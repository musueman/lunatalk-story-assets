param(
    [Parameter(Mandatory)]
    [string]$EmotionSource,
    [Parameter(Mandatory)]
    [string]$NsfwSource,
    [string]$Destination
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($Destination)) {
    $Destination = Join-Path (Split-Path -Parent (Split-Path -Parent $PSCommandPath)) 'greek'
}

function Get-ImageSize {
    param([Parameter(Mandatory)][string]$Path)

    $size = & magick identify -format '%w,%h' -- $Path
    if ($LASTEXITCODE -ne 0 -or $size -notmatch '^\d+,\d+$') { throw "Could not read image dimensions: $Path" }
    $width, $height = $size -split ','
    return [PSCustomObject]@{ width = [int]$width; height = [int]$height }
}

function Convert-SourceSet {
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][ValidateSet('SFW', 'NSFW')][string]$SafetyClass,
        [Parameter(Mandatory)][hashtable]$CharacterCodes,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Manifest,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$MapItems,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$RawReport
    )

    $sourceRootResolved = (Resolve-Path -LiteralPath $SourceRoot).Path
    $rootId = Split-Path -Leaf $sourceRootResolved
    $pngs = @(Get-ChildItem -LiteralPath $sourceRootResolved -Recurse -File -Filter '*.png' | Sort-Object FullName)
    if ($pngs.Count -eq 0) { throw "No PNG files found in $sourceRootResolved" }
    $situationSequences = @{}

    foreach ($png in $pngs) {
        $relative = $png.FullName.Substring($sourceRootResolved.Length).TrimStart('\')
        $segments = $relative -split '[\\/]'
        if ($segments.Count -ne 2) { throw "Expected one character directory below ${rootId}: $relative" }
        $characterSlug = $segments[0].ToLowerInvariant()
        $characterCode = $CharacterCodes[$characterSlug]
        if ([string]::IsNullOrWhiteSpace($characterCode)) { throw "No explicit character code registered for: $characterSlug" }
        $fileName = $segments[1]
        $baseName = [IO.Path]::GetFileNameWithoutExtension($fileName)
        if (-not $situationSequences.ContainsKey($characterSlug)) { $situationSequences[$characterSlug] = 0 }
        $situationSequences[$characterSlug]++
        $situationPrefix = if ($SafetyClass -eq 'SFW') { 'S' } else { 'N' }
        $situationCode = '{0}{1:D2}' -f $situationPrefix, $situationSequences[$characterSlug]

        $assetCode = "GRC-$SafetyClass-$characterCode-$situationCode"
        $sourceMediaId = "local-$SafetyClass-$characterSlug-$baseName"
        $destinationRelative = "greek/$($SafetyClass.ToLowerInvariant())/$characterCode/$situationCode.webp"
        $destinationPath = Join-Path $Destination ($destinationRelative.Substring('greek/'.Length).Replace('/', '\\'))
        $destinationDirectory = Split-Path -Parent $destinationPath
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null

        $beforeHash = (Get-FileHash -LiteralPath $png.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $sourceSize = Get-ImageSize -Path $png.FullName
        & magick $png.FullName -strip -quality 95 -define webp:method=6 $destinationPath
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $destinationPath -PathType Leaf)) { throw "WebP conversion failed: $relative" }
        $afterHash = (Get-FileHash -LiteralPath $png.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($afterHash -ne $beforeHash) { throw "Source PNG changed during conversion: $relative" }
        $webpSize = Get-ImageSize -Path $destinationPath
        if ($webpSize.width -ne $sourceSize.width -or $webpSize.height -ne $sourceSize.height) { throw "Dimension mismatch after conversion: $relative" }
        $webpHash = (Get-FileHash -LiteralPath $destinationPath -Algorithm SHA256).Hash.ToLowerInvariant()

        $mappingKind = if ($SafetyClass -eq 'SFW') { 'character_emotion' } else { 'character_situation' }
        $rawUrl = "https://raw.githubusercontent.com/musueman/lunatalk-story-assets/main/$destinationRelative"
        $row = [PSCustomObject]@{
            asset_code = $assetCode
            source_set = $rootId
            source_media_id = $sourceMediaId
            source_relative_path = $relative.Replace('\\', '/')
            source_filename = $fileName
            source_sha256_before = $beforeHash
            source_sha256_after = $afterHash
            source_original_preserved = 'true'
            source_width = $sourceSize.width
            source_height = $sourceSize.height
            source_format = 'PNG'
            rights_or_license_basis = 'user_directed_local_canonical_source_rights_not_independently_verified'
            conversion_tool = 'ImageMagick'
            conversion_options = 'strip;quality=95;webp:method=6'
            webp_relative_path = $destinationRelative
            webp_sha256 = $webpHash
            webp_width = $webpSize.width
            webp_height = $webpSize.height
            mapping_kind = $mappingKind
            character_code = $characterCode
            character_slug = $characterSlug
            safety_class = $SafetyClass
            situation_code = $situationCode
            situation_label = $baseName
            conversion_status = 'converted_local_not_published'
        }
        $Manifest.Add($row)
        $MapItems.Add([PSCustomObject]@{
            asset_code = $assetCode
            source_media_id = $sourceMediaId
            mapping_kind = $mappingKind
            character_code = $characterCode
            character_slug = $characterSlug
            safety_class = $SafetyClass
            situation_code = $situationCode
            situation_label = $baseName
            missing_or_unmapped_code_rule = 'no_image_call'
            path = $destinationRelative
            raw_url = $rawUrl
            source_sha256 = $beforeHash
            webp_sha256 = $webpHash
        })
        $RawReport.Add([PSCustomObject]@{
            asset_code = $assetCode
            repository = 'musueman/lunatalk-story-assets'
            branch = 'main'
            repository_commit = 'pending_push'
            path = $destinationRelative
            raw_url = $rawUrl
            http_method = 'HEAD'
            http_status = ''
            content_type = ''
            checked_at_kst = ''
            check_status = 'pending_push'
            notes = 'not_published_when_generated'
        })
    }
}

if (-not (Test-Path -LiteralPath $EmotionSource -PathType Container)) { throw "Emotion source is missing: $EmotionSource" }
if (-not (Test-Path -LiteralPath $NsfwSource -PathType Container)) { throw "NSFW source is missing: $NsfwSource" }

New-Item -ItemType Directory -Path $Destination -Force | Out-Null
$manifest = [System.Collections.Generic.List[object]]::new()
$mapItems = [System.Collections.Generic.List[object]]::new()
$rawReport = [System.Collections.Generic.List[object]]::new()
$characterSlugs = @(
    (Get-ChildItem -LiteralPath $EmotionSource -Directory | Select-Object -ExpandProperty Name) +
    (Get-ChildItem -LiteralPath $NsfwSource -Directory | Select-Object -ExpandProperty Name) |
    ForEach-Object { $_.ToLowerInvariant() } |
    Sort-Object -Unique
)
$characterCodes = @{}
$characterRegistry = [System.Collections.Generic.List[object]]::new()
for ($index = 0; $index -lt $characterSlugs.Count; $index++) {
    $code = 'C{0:D2}' -f ($index + 1)
    $characterCodes[$characterSlugs[$index]] = $code
    $characterRegistry.Add([PSCustomObject]@{ code = $code; slug = $characterSlugs[$index] })
}
Convert-SourceSet -SourceRoot $EmotionSource -SafetyClass 'SFW' -CharacterCodes $characterCodes -Manifest $manifest -MapItems $mapItems -RawReport $rawReport
Convert-SourceSet -SourceRoot $NsfwSource -SafetyClass 'NSFW' -CharacterCodes $characterCodes -Manifest $manifest -MapItems $mapItems -RawReport $rawReport

if ($manifest.Count -ne 218) { throw "Expected 218 local source PNGs, found $($manifest.Count)" }
if (($manifest | Where-Object safety_class -eq 'SFW').Count -ne 135) { throw 'Expected 135 SFW PNGs' }
if (($manifest | Where-Object safety_class -eq 'NSFW').Count -ne 83) { throw 'Expected 83 NSFW PNGs' }
if (($manifest.asset_code | Select-Object -Unique).Count -ne 218) { throw 'Asset code collision detected' }

$manifest | Export-Csv -LiteralPath (Join-Path $Destination 'source-manifest.csv') -NoTypeInformation -Encoding utf8BOM
$rawReport | Export-Csv -LiteralPath (Join-Path $Destination 'raw-url-report.csv') -NoTypeInformation -Encoding utf8BOM
$map = [PSCustomObject]@{
    schema_version = '1.0'
    source_inventory = [PSCustomObject]@{
        local_png_total = 218
        local_sfw_png_total = 135
        local_nsfw_png_total = 83
        crack_observed_total = 222
        unresolved_difference = 4
        unresolved_difference_status = 'not_found_in_the_two_confirmed_local_canonical_source_roots'
    }
    destination = [PSCustomObject]@{
        repository = 'musueman/lunatalk-story-assets'
        branch = 'main'
        required_prefix = 'greek/'
        delivery_format = 'WebP'
    }
    call_contract = [PSCustomObject]@{
        selection = 'Use only an exact asset_code in this map. Never infer a path from character, myth, filename, prior project, or chat context.'
        missing_or_unmapped_code = 'no_image_call'
        publication_state = 'local_conversion_complete_raw_validation_pending_push'
    }
    character_registry = $characterRegistry
    items = $mapItems
}
$map | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $Destination 'webp-map.json') -Encoding utf8BOM
Write-Output "BUILT_GREEK_ASSETS: total=$($manifest.Count) sfw=135 nsfw=83 destination=$Destination"
