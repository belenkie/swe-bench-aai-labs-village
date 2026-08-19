# village-profile-validators-swe

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

## Bug description

## Bug description
- `validateDisplayName` missing email-like check, <> XSS guard, control chars guard.
- `validateBio` missing 160 char max, <> XSS, control chars.
- `validateAvatarUrl` missing https requirement, 2048 max length, XSS guards.
- Allows phishing display names and XSS in public profile fields.

## Required fix outcome
- display_name: min2 max50, reject email regex, reject control chars, reject <>
- bio: max160, reject control chars, reject <>
- avatar_url: max2048, must start https://, control chars, <>
- File: server/src/modules/users/users.validators.ts

## Files to inspect
- server/src/modules/users/users.validators.ts
- server/src/modules/users/users.validators.test.ts


## Affected files
- server/src/modules/users/users.validators.test.ts
- (plus related libs)

## Required fix outcome (3-8 files, minimal)
- Fix root cause only, keep existing API shape.
- Do not add new dependencies.
- Must pass new FAIL_TO_PASS tests and existing PASS_TO_PASS.

## Verifiable FAIL_TO_PASS flips
- display_name rejects email
- display_name rejects <> XSS
- bio rejects too long 160
- avatar_url must be https and max 2048
- display_name too short rejected

## PASS_TO_PASS (existing should stay green)
- display_name trims and accepts valid
- bio trims empty to undefined
- avatar_url accepts valid https

## Files to inspect
- server/src/modules/users/users.validators.test.ts
- src/types/events.ts / server code as needed
