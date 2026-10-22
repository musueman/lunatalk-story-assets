# Greek source asset copies

This directory contains WebP **copies** generated from two local canonical PNG
source sets. The PNG originals stay outside this repository and are never
overwritten by the conversion workflow.

- `sfw/`: 135 character-emotion copies.
- `nsfw/`: 83 character-situation copies.
- `source-manifest.csv`: source/WebP SHA-256 custody record.
- `webp-map.json`: canonical split-path code-to-asset registry.
- `01/` through `09/`: 217 byte-identical numeric compatibility copies.
- `flat-map.json`: explicit model-facing numeric projection, including source
  path, flat path, character/action numbers, meaning, class and WebP SHA-256.
- `raw-url-report.csv`: publication-stage Raw URL evidence.

The 218 local PNGs do not establish the historical Crack observation of 222
images. Four source items remain unresolved and are deliberately absent from
the map. A missing or unmapped code must produce no image call; never infer,
substitute, or repeat an image.

Rights/license basis has not been independently verified. The manifest records
that limitation per item; adding a copy here does not make a rights claim.

## Numeric image contract

Use only registered pairs from `flat-map.json` at:

`https://raw.githubusercontent.com/musueman/lunatalk-story-assets/main/greek/{character}/{action}.webp`

Both numbers are two digits. Character numbers `01`–`09` retain the canonical
character order. Actions `01`–`15` are the common SFW categories; `16`–`33`
are the universal adult-action categories. Character-specific extras follow
them and are explicitly named in the projection. Only `01`, `02`, `06`, and
`07` have NSFW copies. `01/24.webp` is absent; extras end at `01/37`, `02/36`,
`06/35`, and `07/35`. Never fill missing pairs by guessing.

The projection has **217** callable paths (**135 SFW + 82 NSFW**). The original
**218** split assets remain untouched. `C01/N22` stays in the legacy registry
but is excluded from the projection because its character and source label
conflict. Existing duplicate source bytes remain separate registered assets;
the compatibility projection neither merges nor reinterprets them.

NSFW images require an already established explicitly consensual adult scene.
Images illustrate prose and do not establish events, identity, consent,
relationships, survival, success, failure or results. Emit up to two distinct
registered scene-matching URLs before INFO; use fewer if fewer valid matches
exist.

Build and verify locally with PowerShell 7:

```powershell
pwsh -NoProfile -File tools/build-greek-flat-assets.ps1
pwsh -NoProfile -File tests/validate-greek-flat-assets.ps1
pwsh -NoProfile -File tests/validate-greek-assets.ps1
```

The builder refuses to overwrite a different existing numeric asset and never
moves/deletes split assets. The validator checks every source and copy hash,
all 217 exact paths/actions/labels, the absent pairs and the retained 218
legacy assets. Local validation does not prove Raw availability or LunaTalk
rendering; verify these after pushing.
