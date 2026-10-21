# Apocalypse flat image address design

## Goal

Give LunaTalk one copyable GitHub Raw address format so the model never has
to infer directory names or long filenames. Images are addressed only by a
character number and an action number.

## Public address contract

`https://raw.githubusercontent.com/musueman/lunatalk-story-assets/main/apoc/{character}/{action}.webp`

| Character | Folder | Available actions |
| --- | --- | --- |
| 강도윤 | `01` | `01`-`40` |
| 한서경 | `02` | `01`-`61` |
| 윤채린 | `03` | `01`-`61` |

The `chars/` and `nsfw/` directories are not part of the new call path.
Existing paths may remain as repository history, but all generated output and
the canonical `map.json` must use the flat contract.

## Action numbering

- `01`-`40`: existing SFW state/action order.
- `41`: 문틈 엿보기.
- `42`: 문틈 당황.
- `43`: 문틈 긴장.
- `44`: 키스.
- `45`: 가슴 애무.
- `46`: 손 자극.
- `47`: 손길.
- `48`: 구강.
- `49`: 구강 심화.
- `50`: 가슴 자극.
- `51`/`52`: 정상위 시작/절정.
- `53`/`54`: 후배위 시작/절정.
- `55`/`56`: 기승위 시작/절정.
- `57`/`58`: 측위 시작/절정.
- `59`/`60`: 대면 착석 시작/절정.
- `61`: 들어올리기 절정.

Only folders `02` and `03` provide actions `41`-`61`. Folder `01` is not an
eligible target for those actions.

## Migration and verification

1. Copy each existing WebP into its canonical flat destination without
   changing pixels or source filenames elsewhere.
2. Rewrite `apoc/map.json` as the canonical character/action registry.
3. Replace the global LunaTalk image rule with the simple address format and
   the action-number table; do not mention a JSON file that the model cannot
   read.
4. Commit and push the asset migration.
5. Verify every canonical URL returns `200`, then create a new chat and verify
   two distinct images render before the status block.

## Failure handling

If an action number is unavailable for a character, omit the image rather than
guessing another number or a different character. A valid image URL is not
evidence for events, relationships, consent, or survival state.
