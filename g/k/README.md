# Greek NSFW stage-1 delivery

7,215 images covering 195 adult-female character identities and 37 registered poses.
This delivery contains v28 stage-1 redaction and Q85/method 6 WebP publication copies: 7,141 at 1024x768 and the 74-image 2026-11-14 additional-character update at 1080x1080.
Original canonical PNGs, working WebPs and lossless stage-1 results remain outside this repository.
The manifest records their hash chain and the publication hashes.

## Image mapping contract

- Repository and branch: `musueman/lunatalk-story-assets`, `main`.
- Stable path: `g/k/{GR-ID}/{pose_###}.webp`.
- Example: `https://raw.githubusercontent.com/musueman/lunatalk-story-assets/main/g/k/GR-001/pose_039.webp`.
- Keep the established GR ID and the original three-digit pose number.
- The production suffix `_00001_` is omitted from publication filenames.
- `map.json` is the explicit ID/pose registry. `manifest.json` records each exact path, hash and review status.
- Missing pose numbers are intentionally absent. There is no default pose or substitute image.
- This namespace is separate from the older nine-character `greek/` numeric registry.
- Existing emotion files, emotion maps and their URLs are unchanged.
- Future stage-1 corrections retain this path contract. Redactor version is metadata, separate from the image key.

## Review state

All files passed automatic processing and technical verification.
2,200 files retain additional visual-review flags in `manual-review.csv` and the manifest.
These flags include 1,193 files with no detected anatomy, which can include images without visible target regions.
The other 4,941 files have no automatic review flag. This status is not a claim of completed human visual review.
Stage 1 targets genital and anal regions. Stage 2 is not included in this delivery.
Uploading these files does not change the chatbot configuration or deploy the website.
