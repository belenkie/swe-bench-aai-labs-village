# village-validate-endtime

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

## Bug description

## Bug description
- `validateCreateEventInput` in `server/src/modules/events/events.routes.ts` validates that `endTime` (if present) is a valid ISO string, but does NOT verify it is after `time`. Client-side `buildCreateEventInput` has check `if (endTime <= time) error`, but server bypass allows creation of negative/zero duration events via direct API call.
- Creates events where endTime before start, breaking UI duration display and sorting.

## Required fix outcome
- In server validator, after parsing rawEndTime and rawTime, if both are valid ISO, ensure Date.parse(endTime) > Date.parse(time). Return `{ ok:false, message:"endTime must be after time" }` otherwise.
- Keep existing validations: missing time reject, invalid ISO reject, privileged fields stripped.
- Only 1 file change: `server/src/modules/events/events.routes.ts`

## Verifiable FAIL_TO_PASS flips
- rejects endTime before start -> 400 validation_error containing "after time"
- rejects equal endTime -> 400
- accepts valid endTime after start -> 200/ok
- accepts missing endTime -> ok (optional field)

## Files to inspect
- server/src/modules/events/events.routes.ts (validateCreateEventInput)
- src/lib/create-event.ts (client-side mirror, already has guard)


## Affected files
- server/src/modules/events/events.create.test.ts
- (plus related libs)

## Required fix outcome (3-8 files, minimal)
- Fix root cause only, keep existing API shape.
- Do not add new dependencies.
- Must pass new FAIL_TO_PASS tests and existing PASS_TO_PASS.

## Verifiable FAIL_TO_PASS flips
- validateCreateEventInput rejects endTime before start
- validateCreateEventInput rejects endTime equal to start
- validateCreateEventInput accepts valid endTime after start
- validateCreateEventInput accepts missing endTime

## PASS_TO_PASS (existing should stay green)
- validateCreateEventInput rejects invalid time format
- validateCreateEventInput accepts well-formed input
- validateCreateEventInput strips privileged fields

## Files to inspect
- server/src/modules/events/events.create.test.ts
- src/types/events.ts / server code as needed
