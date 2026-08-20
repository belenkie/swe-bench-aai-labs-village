# village-validate-create-timezone

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

Event creation validation lives in `server/src/modules/events/events.routes.ts` — `validateCreateEventInput`. It validates name, picture, categories, time, timezone, location, etc. At base commit `c51d126`, timezone is only checked for non-empty string, not for valid IANA timezone.

## Bug description
- `validateCreateEventInput` checks `timezone` is present and non-empty string, but does NOT validate it is a recognized IANA timezone (e.g., "America/Los_Angeles", "UTC").
- Passing invalid IANA zone like "Invalid/Zone" or "Foo/Bar" passes validation, is stored in DB, and later causes `getTimezoneOffsetMinutes(timeZone, date)` and `Intl.DateTimeFormat` with that zone to throw `RangeError` at render time or in conversion logic, leading to 500 errors instead of 400 validation_error.
- Client-side `buildCreateEventInput` has a hardcoded list? No, it trusts user picker, but server should be authoritative.
- Expected behavior: server should explicitly validate timezone is a valid IANA zone via `new Intl.DateTimeFormat('en-US', { timeZone })` attempt, and if invalid, return `{ ok: false, message: "Invalid timezone: <input> is not a recognized IANA zone" }` (must contain "Invalid timezone" to match tests).
- Also should trim surrounding whitespace and store trimmed value.
- Similar validation already exists in `server/src/modules/users/users.validators.ts` `validateTimezone` — reuse same pattern.

## Required fix outcome
- In `server/src/modules/events/events.routes.ts`, function `validateCreateEventInput`:
  - After checking timezone is non-empty string, trim it: `const trimmedTz = rawTz.trim()`
  - Try `Intl.DateTimeFormat(undefined, { timeZone: trimmedTz })` to validate; if throws, return `{ ok: false, message: "Invalid timezone: <trimmed> is not a recognized IANA zone" }` (message must contain "Invalid timezone").
  - If valid, use `trimmedTz` in the returned `value.timezone` instead of raw.
  - Keep existing missing and empty checks.
- Only 1 file change: `server/src/modules/events/events.routes.ts`
- No new dependencies.

## Verifiable FAIL_TO_PASS flips
- rejects invalid timezone "Invalid/Zone" -> ok:false, message contains "Invalid timezone"
- rejects invalid timezone "Foo/Bar" -> ok:false, message contains "Invalid timezone"
- rejects invalid timezone "Not/A_Real_Zone" -> ok:false, 400 validation_error
- trims timezone with surrounding spaces "  America/Los_Angeles  " -> ok:true and stored value equals trimmed "America/Los_Angeles"
- (valid cases below are PASS_TO_PASS, must stay green)

## PASS_TO_PASS (existing should stay green)
- accepts valid timezone UTC -> ok:true
- accepts valid timezone America/Los_Angeles -> ok:true
- rejects invalid time format -> ok:false
- accepts well-formed input -> ok:true
- strips privileged fields -> id/attendees/isFeatured undefined
- rejects missing timezone -> ok:false
- rejects empty timezone "" -> ok:false, message contains "non-empty" or "timezone"

## Files to inspect
- server/src/modules/events/events.routes.ts (validateCreateEventInput)
- server/src/modules/users/users.validators.ts (validateTimezone reference impl)
- server/src/modules/events/events.create.test.ts
- src/lib/timezone.ts (getTimezoneOffsetMinutes IANA validation context)

## References
Original similar fix for user profile timezone:
> feat(profile): MVP minimal design per figma — includes IANA validation via Intl.DateTimeFormat

For events create, the missing validation causes 500 when later formatting event time in invalid zone.
