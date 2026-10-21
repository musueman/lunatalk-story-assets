# Apocalypse Flat Image Addresses Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the multi-folder Apocalypse image call path with stable numeric character and action addresses.

**Architecture:** Copy existing WebPs into `apoc/01`, `apoc/02`, and `apoc/03` without changing pixels. Rewrite the local registry and global LunaTalk rule so generated Markdown only uses `apoc/{character}/{action}.webp`.

**Tech Stack:** Git, PowerShell, JSON, GitHub Raw, LunaTalk lorebook.

**Spec:** `docs/superpowers/specs/2026-10-21-apoc-flat-image-addresses-design.md`

## Global Constraints

- `01` is 강도윤 and exposes only `01`-`40`.
- `02` is 한서경 and `03` is 윤채린; both expose `01`-`61`.
- NSFW actions use `44`-`61`; 후배위 시작/절정 are `53`/`54`.
- Generated URLs never contain `chars`, `nsfw`, or descriptive filenames.
- Preserve source WebP pixels and validate both GitHub availability and live rendering.

## Review Focus

- Character `01` must not receive `41`-`61`.
- Every `02`/`03` number through `61` must have one file and one registry label.
- `53` and `54` must resolve to 후배위 start/climax, not the previous normal-position files.
- No global rule may reference a manifest that the model cannot read.
- A live response must render two distinct valid URLs before the status block.

---

### Task 1: Build the flat asset registry

**Files:**
- Create: `apoc/01/*.webp`, `apoc/02/*.webp`, `apoc/03/*.webp`
- Modify: `apoc/map.json`

**Interfaces:**
- Consumes: current `apoc/chars/*` and `apoc/nsfw/*` WebPs.
- Produces: `apoc/{01|02|03}/{01..61}.webp` and an exact numeric `map.json`.

- [ ] Copy the 40 existing 도윤 SFW images to `apoc/01/01.webp` through `40.webp`.
- [ ] Copy the 43 서경/채린 SFW images to `apoc/02` and `apoc/03` with their existing numbers.
- [ ] Copy each 18-slot NSFW set to `44`-`61`, with doggy start/climax mapped to `53`/`54`.
- [ ] Rewrite `apoc/map.json` to list the numeric folder and action labels.
- [ ] Run a PowerShell check that asserts the expected file counts, no number gaps, JSON parseability, and `53`/`54` labels.
- [ ] Commit the migration.

### Task 2: Publish and verify canonical URLs

**Files:**
- Modify: GitHub `main` branch through the existing remote.

**Interfaces:**
- Consumes: Task 1 canonical files.
- Produces: live GitHub Raw URLs for each numeric address.

- [ ] Push the Task 1 commit.
- [ ] Request `HEAD` for all 162 canonical URLs and assert `200` responses.
- [ ] Record the push commit and any failed address before proceeding.

### Task 3: Replace the LunaTalk global image rule

**Files:**
- Modify: LunaTalk lorebook item `외부이미지출력` in the Apocalypse character lorebook.

**Interfaces:**
- Consumes: Task 1 numbering registry.
- Produces: a copyable rule using only `apoc/{character}/{action}.webp` plus a compact number-to-action table.

- [ ] Replace descriptive-path instructions and the inaccessible `nsfw-map.json` reference.
- [ ] State character folders `01`/`02`/`03`, the SFW range, unavailable 도윤 range, and the `44`-`61` action map.
- [ ] Save and visually confirm the lorebook item shows the new numeric contract.

### Task 4: End-to-end runtime check

**Files:**
- Create: a fresh LunaTalk test chat.

**Interfaces:**
- Consumes: GitHub Raw addresses and the updated global lorebook.
- Produces: one debugged response with two distinct rendered numeric image URLs.

- [ ] Start a fresh chat after the lorebook save.
- [ ] Use a naturally phrased adult-consensual scenario that should select `03/53.webp` then `03/54.webp`.
- [ ] Inspect the chat debug output and confirm both Raw URLs, HTTP availability, and display before the status block.
- [ ] Capture the successful test result and report any model noncompliance separately from asset availability.
