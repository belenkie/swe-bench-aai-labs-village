# village-validate-create-full

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

Event creation validation in `server/src/modules/events/events.routes.ts`: `validateCreateEventInput`.

## Bug description
In base commit `c51d1268`, `validateCreateEventInput`:

- Price validation only checked typeof string, but allowed non-numeric strings like "abc" or "12abc". Expected: price must be numeric string (allow "$", "," trimming) or literal "Free" case-insensitive. If contains letters other than Free, must reject with message containing "price".
- Venue/address trimming: payload may contain location.venue with surrounding spaces "  Dolores Park  ". Existing code returned raw string without trim, so stored value had spaces. Expected: trim venue and address fields before returning in `value`.
- Existing tests: create.test.ts expects well-formed input accepted, invalid time format rejected, privileged fields stripped.

## Required fix outcome
- In `validateCreateEventInput`:
  - If price is non-empty string and lower !== "free", strip $ , and spaces, check if remaining contains [a-zA-Z] -> reject `price must be a numeric string or 'Free'`. Also if Number(cleaned) not finite -> reject same.
  - For address, venue, description, ensure trimming: `typeof rawAddr === "string" && rawAddr.trim().length>0 ? rawAddr.trim() : undefined` similarly for venue, etc.
  - Keep existing required checks: name, picture, categories, time, timezone, location latitude/longitude required.
  - Preserve error message wording containing "price" for price failures.

## Verifiable FAIL_TO_PASS
- rejects non-numeric price "abc" -> ok:false /price/
- trims venue "  Dolores Park  " -> value.venue == "Dolores Park"
- rejects price with letters "12abc" -> ok:false

## PASS_TO_PASS
- accepts numeric price "10" -> ok:true
- accepts Free price "Free" case-insensitive -> ok:true

## Files
- server/src/modules/events/events.routes.ts
- server/src/modules/events/events.create-full.test.ts
