# village-profile-location-finite

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

Profile location is stored fuzzed via `fuzzLocation` only if user opts in via `location_sharing_opt_in`. Validation happens in `server/src/modules/users/users.validators.ts` `validateLatLng` and `validateUpdateInput`.

## Bug description
In base commit `c51d1268`, `validateLatLng` checks `typeof lat !== "number"` and range `Math.abs(lat) > 90`, but does NOT reject `NaN`, `Infinity`, `-Infinity`:

- `typeof NaN === "number"` is true in JavaScript
- `Math.abs(NaN) > 90` is false, so NaN bypasses both type and range checks
- `Infinity` bypasses type check, but `Math.abs(Infinity) > 90` is true so it throws `invalid latitude` — however the error message is inconsistent and should be normalized to `location must be numbers` for non-finite values, and NaN must be rejected.

Without fix, storing NaN lat/lng causes PostGIS `ST_MakePoint` errors, fuzzing produces NaN, and T&S grid snap breaks.

## Required fix outcome
- In `server/src/modules/users/users.validators.ts`, function `validateLatLng`:
  - Add `Number.isFinite` guard: `if (typeof lat !== "number" || typeof lng !== "number" || !Number.isFinite(lat) || !Number.isFinite(lng)) validated("location must be numbers")`
  - Keep range checks but also guard finite: `if (!Number.isFinite(lat) || Math.abs(lat) > 90) validated("invalid latitude")`
  - Same for longitude: `if (!Number.isFinite(lng) || Math.abs(lng) > 180) validated("invalid longitude")`
  - Preserve existing: return `{}` when both undefined, require both when one present, valid finite in-range returns `{lat, lng}`.
- Only 1 file changed: `server/src/modules/users/users.validators.ts`
- No new dependencies.

## Verifiable FAIL_TO_PASS flips
- rejects NaN latitude → throws ValidationError containing "must be numbers" or "invalid"
- rejects NaN longitude → throws
- rejects NaN both lat lng → throws
- rejects Infinity latitude with must be numbers → throws containing "must be numbers"
- rejects -Infinity longitude with must be numbers → throws containing "must be numbers"

## PASS_TO_PASS (existing should stay green)
- accepts valid finite lat/lng (37.7749, -122.4194)
- missing both returns empty
- missing one throws "both location_lat and location_lng required"
- out-of-range latitude 91 throws "invalid latitude"
- out-of-range longitude 181 throws "invalid longitude"

## Files to inspect
- server/src/modules/users/users.validators.ts (validateLatLng, validateUpdateInput)
- server/src/modules/users/users.validators.test.ts (existing tests)
- src/types/profile.ts
