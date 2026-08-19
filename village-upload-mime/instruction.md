# village-upload-mime

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

## Bug description

## Bug description
- `detectMimeFromBuffer` missing WebP detection: WebP file signature is RIFF at 0-3 and WEBP at 8-11. Without it, WebP uploads rejected despite ALLOWED_MIME including image/webp.
- `processImageAndStripExif` must use `sharp(...).rotate()` to auto-rotate based on EXIF Orientation and strip EXIF (GPS, etc.) by not calling withMetadata(). Missing rotate leads to sideways images and EXIF GPS leak.
- Need both: magic byte detection for WebP + sharp rotate EXIF strip pipeline.

## Required fix
- In detectMimeFromBuffer, check buf.length >=12, then if buf[0]==0x52(R) 1==0x49(I) 2==0x46(F) 3==0x46(F) and buf[8]==0x57(W) 9==0x45(E) 10==0x42(B) 11==0x50(P) => webp.
- In processImageAndStripExif, use sharp(input).rotate().jpeg({quality:85}) etc for each mime, ensuring EXIF stripped.
- File: server/src/modules/uploads/uploads.routes.ts

## Files
- server/src/modules/uploads/uploads.routes.ts
- server/src/modules/uploads/uploads.test.ts (verifier)


## Affected files
- server/src/modules/uploads/uploads.test.ts
- (plus related libs)

## Required fix outcome (3-8 files, minimal)
- Fix root cause only, keep existing API shape.
- Do not add new dependencies.
- Must pass new FAIL_TO_PASS tests and existing PASS_TO_PASS.

## Verifiable FAIL_TO_PASS flips
- detectMimeFromBuffer detects WebP RIFF WEBP
- detectMimeFromBuffer detects JPEG
- detectMimeFromBuffer detects PNG
- processImageAndStripExif rotates and strips EXIF JPEG
- processImageAndStripExif handles WebP

## PASS_TO_PASS (existing should stay green)
- detectMimeFromBuffer returns null for unknown
- detectMimeFromBuffer detects GIF
- processImageAndStripExif handles PNG

## Files to inspect
- server/src/modules/uploads/uploads.test.ts
- src/types/events.ts / server code as needed
