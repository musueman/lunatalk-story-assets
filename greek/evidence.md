# Greek asset import evidence

## Source observation

| Source root ID | Local source root | PNG count | Use |
| --- | --- | ---: | --- |
| `canonical_emotion_assets` | `D:\ComfyUI_Qwen21\이미지 생성\2026-10-20\GreekEmotionCanonical_20261020\canonical_emotion_assets` | 135 | SFW character-emotion copies |
| `canonical_nsfw_assets` | `D:\ComfyUI_Qwen21\이미지 생성\2026-10-20\GreekNSFW_GoddessCanonical_20261020\canonical_nsfw_assets` | 83 | NSFW character-situation copies |

The two confirmed local roots provide 218 PNGs. This is **not** an assertion
that the Crack source has 218 images: the separately observed Crack count was
222. The difference is four unresolved source items, which are neither copied
nor mapped here.

`source-manifest.csv` records a SHA-256 before and after each conversion.
Every `source_original_preserved` value must be `true`; a mismatch aborts the
builder. The source paths are read-only inputs and no original PNG is stored
or overwritten in this repository.

## Conversion and map contract

- Tool: ImageMagick 7.1.2 Q16-HDRI.
- Command options: `-strip -quality 95 -define webp:method=6`.
- Output: WebP copies under `greek/sfw/Cxx/Sxx.webp` or
  `greek/nsfw/Cxx/Nxx.webp`.
- `webp-map.json` assigns the nine source folders an explicit `C01` through
  `C09` registry and assigns an explicit, per-character `S01…` or `N01…`
  situation number. The original filename remains the map label and source
  relative path; it is never normalized into the public code.
- A missing or unmapped code means `no_image_call`; a consumer may not infer,
  substitute, or repeat an image.
- Per-item rights/license status is
  `user_directed_local_canonical_source_rights_not_independently_verified`.
  This is provenance context, not an independent rights finding.

## Reproducible failures and corrections

| Stage | Reproduction / error | Root cause | Correction | Result |
| --- | --- | --- | --- | --- |
| Initial builder parse | `& .\tools\build-greek-assets.ps1 -EmotionSource <root1> -NsfwSource <root2>` → `Variable reference is not valid. ':' was not followed by a valid variable name character.` | `$rootId:` in an interpolated PowerShell string. | Delimited it as `${rootId}`. | Parser proceeded. |
| First builder call | same command → `Cannot bind argument to parameter 'Manifest' because it is an empty collection.` | The initially empty generic `List` parameters were marked mandatory without allowing empty collections. | Added `AllowEmptyCollection` to the three list parameters. | The converter accepted a zero-row accumulator. |
| Background launcher | unquoted `Start-Process -ArgumentList` → NSFW path treated as a positional argument. | The source path contains a space in `이미지 생성`. | Passed one fully quoted argument string. | Both source roots reached the builder. |
| Background default path | background host → `Split-Path ... Path ... empty string`. | `$PSScriptRoot` was evaluated while binding a default parameter in that host. | Resolve `Destination` after parameter binding; pass `-Destination` explicitly. | Builder used `greek/`. |
| Background runtime | `powershell.exe` host → `Get-FileHash ... not recognized`. | The background host differed from the PowerShell 7 session. | Launch the resolved `pwsh.exe` PowerShell 7 runtime. | SHA-256 generation proceeded. |
| Code collision guard | builder → `Asset code collision detected`. | Korean NSFW filenames normalized to the same ASCII suffix. | Replace filename-derived public codes with explicit `Cxx` and `Sxx`/`Nxx` registry codes; preserve filenames only as labels. | 218 unique codes created. |
| Final local run | `& .\tests\validate-greek-assets.ps1` | N/A | N/A | Pass: 218 manifest rows, 135 SFW, 83 NSFW, 218 map entries, 9 character codes, 218 pending-push Raw rows. |

## Publication state

The asset commit `8789ab616a3ebdb10e5116d287b916f520d5cdd5` was pushed to
`origin/main`; `git ls-remote origin refs/heads/main` returned the same SHA.
At `2026-10-22T09:25:52+09:00`, all 218 URL rows in
`raw-url-report.csv` were checked with `HEAD` and recorded `200` plus an
`image/webp` content type. This establishes Raw delivery for that asset
commit only.

LunaTalk save/reopen and live-chat image rendering are separate, unstarted
gates. No claim in this repository establishes either one.
