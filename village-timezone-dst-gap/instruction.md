# village-timezone-dst-gap

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

## Bug description

## Bug description
- `convertLocalWallToTimezone` implements iterative solve U = wall - offset(U). For DST spring-forward gap (e.g. 2026-03-08 02:30 America/Los_Angeles does not exist), the solver oscillates or returns a time that doesn't render as desired wall. No fallback.
- Expected: detect gap by checking if result formatted back in target tz mismatches desired wall, then fallback to next valid wall time (advance 1h until valid, max 3h).
- Without fix, events created during 2am-3am DST gap have wrong UTC instant or throw.

## Required fix
- After iterative solve, format result back in target tz via Intl.DateTimeFormat parts, compare year/month/day/hour/minute to desired wall. If mismatch, assume gap, try forward 1h,2h,3h until valid (return first candidate).
- Keep existing iterative logic, add gap detection + fallback.
- File: src/lib/timezone.ts

## Verifiable
- Handles DST gap forward fallback (02:30 on DST start day doesn't stay 02:30)
- Normal time still works (18:00 July)
- Fall-back ambiguous still returns valid
- getTimezoneOffsetMinutes UTC=0

## Files to inspect
- src/lib/timezone.ts


## Affected files
- src/lib/timezone.test.ts
- (plus related libs)

## Required fix outcome (3-8 files, minimal)
- Fix root cause only, keep existing API shape.
- Do not add new dependencies.
- Must pass new FAIL_TO_PASS tests and existing PASS_TO_PASS.

## Verifiable FAIL_TO_PASS flips
- convertLocalWallToTimezone handles DST gap forward fallback
- convertLocalWallToTimezone normal time still works
- convertLocalWallToTimezone DST fall-back ambiguous still returns valid
- getTimezoneOffsetMinutes works for UTC

## PASS_TO_PASS (existing should stay green)
- convertLocalWallToTimezone iterative solve converges
- formatInTimeZone returns string
- formatEventDateTime returns string

## Files to inspect
- src/lib/timezone.test.ts
- src/types/events.ts / server code as needed
