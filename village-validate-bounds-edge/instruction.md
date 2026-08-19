# village-validate-bounds-edge

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

Bounds validation in `server/src/modules/events/events.routes.ts` includes `validateBounds` (query params north/south/east/west) and `validateLimit`.

## Bug description
In base commit `c51d1268`, `validateLimit` only checked integer and clamped via Math.max/min, but did not reject out-of-range values per new API contract. Also `validateBounds` did not reject array inputs (e.g., `?north=1&north=2` parsed as array by Fastify) which should be 400.

Expected per new contract:
- `validateLimit`:
  - Accept default 50 when undefined, accept 1..100 inclusive.
  - Reject <1, >100 with message containing "between 1 and 100".
  - Reject non-integer (e.g., "10.5") with message containing "integer".
  - Reject empty string "" and array inputs with message containing "must be a number" or "limit".
- `validateBounds`:
  - If any of north/south/east/west is Array.isArray, return ok:false with message containing "<field> must be a number".
  - Keep existing missing and non-finite checks.

## Required fix outcome
- In `server/src/modules/events/events.routes.ts`:
  - In `validateBounds`, early check: if raw query value is array, return `{ ok:false, message: "<field> must be a number: got ..." }`.
  - In `validateLimit`, after parsing integer, check if num <1 or >100 -> return `{ ok:false, message: "limit out of range: must be between 1 and 100, got ..." }`.
  - Also handle array, empty string, non-numeric via existing Number.isFinite checks plus explicit array guard.

## Verifiable FAIL_TO_PASS
- validateLimit rejects negative limit (-5) -> ok:false, message /between 1 and 100/
- rejects 0
- rejects 101
- rejects array [10,20] -> ok:false
- rejects empty string ""
- rejects non-integer 10.5 -> message /integer/

## PASS_TO_PASS
- accepts 50 (value 50)
- accepts 1 and 100 boundaries

## Files
- server/src/modules/events/events.routes.ts
- server/src/modules/events/events.bounds-edge.test.ts
