# village-auth-allowlist

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

## Bug description

## Bug description
- `isAllowedRedirectUri` allowed any scheme not explicitly blocked? Missing `exp://` rejection. Expo dev deep link `exp://` could be abused for open redirect if attacker controls Expo Go.
- Trailing slash handling was basic replace, but host case-insensitivity not considered.
- Need exact match after normalize (trim + trailing slash) plus lower host comparison, reject exp://.

## Required fix
- Reject if lower startsWith `exp://`
- Keep existing guards: fragment, javascript:, data:, file:, protocol-relative //, query on native scheme, credentials.
- Normalize trailing slash and do case-insensitive host compare for web origin; native `village://auth` exact.
- Single file: server/src/modules/auth/allowlist.ts

## Files
- server/src/modules/auth/allowlist.ts
- server/src/modules/auth/allowlist.test.ts


## Affected files
- server/src/modules/auth/allowlist.test.ts
- (plus related libs)

## Required fix outcome (3-8 files, minimal)
- Fix root cause only, keep existing API shape.
- Do not add new dependencies.
- Must pass new FAIL_TO_PASS tests and existing PASS_TO_PASS.

## Verifiable FAIL_TO_PASS flips
- allows native scheme exactly
- rejects different origin open-redirect
- rejects exp:// scheme
- allows origin with trailing slash normalized
- rejects javascript: scheme

## PASS_TO_PASS (existing should stay green)
- allows configured web origin
- rejects fragments
- rejects protocol-relative

## Files to inspect
- server/src/modules/auth/allowlist.test.ts
- src/types/events.ts / server code as needed
