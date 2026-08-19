# village-validate-limit

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

## Bug description

## Bug description
- `validateLimit` in events.routes.ts was lenient: parseInt non-numeric -> NaN, Math.max/min fallback to clamp, empty array handling missing, <1 >100 silently clamped not rejected per new API contract (400 with field-named message).
- Missing guards: <1, >100, non-integer, empty string, array.

## Required fix outcome
- Return ok:false with message containing "limit" and "must be a number" / "must be an integer" / "between 1 and 100" for violations.
- Reject explicitly: <1, >100, empty "", array, non-integer like "10.5".
- Accept 1..100 inclusive, default 50.
- File: server/src/modules/events/events.routes.ts

## Verifiable
- rejects 0, 101, 10.5, "", array
- accepts 50, undefined default, 1 and 100

## Files to inspect
- server/src/modules/events/events.routes.ts
- server/src/modules/events/events.limit.test.ts


## Affected files
- server/src/modules/events/events.limit.test.ts
- (plus related libs)

## Required fix outcome (3-8 files, minimal)
- Fix root cause only, keep existing API shape.
- Do not add new dependencies.
- Must pass new FAIL_TO_PASS tests and existing PASS_TO_PASS.

## Verifiable FAIL_TO_PASS flips
- validateLimit rejects limit 0
- validateLimit rejects limit 101
- validateLimit rejects non-integer 10.5
- validateLimit rejects empty string
- validateLimit rejects array

## PASS_TO_PASS (existing should stay green)
- validateLimit accepts 50
- validateLimit defaults to 50 when undefined
- validateLimit accepts 1 and 100 boundaries

## Files to inspect
- server/src/modules/events/events.limit.test.ts
- src/types/events.ts / server code as needed
