# village-timezone-invalid

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

Timezone helper `src/lib/timezone.ts` provides `getTimezoneOffsetMinutes(timeZone, date)` which uses Intl.DateTimeFormat to compute offset.

## Bug description
In base commit `c51d1268`, `getTimezoneOffsetMinutes` does NOT validate its `timeZone` argument:

- Passing invalid IANA zone like "Invalid/Zone" or empty string "" causes Intl to throw RangeError somewhere deep, but function does not have explicit guard and may return incorrect offset or throw uncontrolled error message.
- Expected: function should explicitly validate `timeZone` is non-empty string and valid IANA timezone via `new Intl.DateTimeFormat('en-US', { timeZone })` attempt, and if invalid, throw Error with message containing "Invalid timezone: <input>".

- Valid zones like "UTC" and "America/Los_Angeles" must still work and return finite numbers (UTC -> 0).

## Required fix outcome
- In `src/lib/timezone.ts`, at top of `getTimezoneOffsetMinutes`:
  - If typeof timeZone != 'string' or trimmed length==0, throw `new Error('Invalid timezone: <value>')`
  - Try `new Intl.DateTimeFormat('en-US', { timeZone })` to validate, catch and throw same "Invalid timezone: <zone>" error.
  - Keep existing offset calculation logic unchanged.

## Verifiable
- getTimezoneOffsetMinutes throws on invalid timezone (contains "Invalid timezone")
- throws on empty string
- accepts valid UTC (returns 0)
- accepts America/Los_Angeles (returns finite number)

## Files
- src/lib/timezone.ts
- src/lib/timezone.invalid.test.ts
