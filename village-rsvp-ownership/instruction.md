# village-rsvp-ownership

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

RSVP flow lives in `server/src/modules/events/events.repository.ts` (`rsvpEvent`) and routes in `events.routes.ts`.

## Bug description
In base commit `c51d1268`:

- `rsvpEvent` checks if `created_by` == `userId` and throws an error, but existing error message is generic and tests expect explicit message containing both "owner cannot rsvp own event" and "owner_cannot_rsvp" code preserved for backward compat.
- `GET /api/events/:id/attendees` should be owner-only: only the host (creator) can list attendees. If non-owner calls, server must return 403. Base implementation returned attendee list to anyone authenticated.

In `events.routes.ts` around `app.get("/api/events/:id/attendees")`, the handler must verify that `request.user.id` equals event's `created_by` / organizer. If not owner, reply with 403 and message indicating only host can see attendee list.

## Required fix outcome
- In `server/src/modules/events/events.repository.ts`: ensure error thrown when owner RSVPs own event contains message "owner cannot rsvp own event: owner_cannot_rsvp" (lowercase) and preserves code shape.
- In `server/src/modules/events/events.routes.ts`: for `GET /api/events/:id/attendees`, add guard:
  - Fetch event, if not found 404
  - If `event.created_by !== request.user.id`, return 403 with body containing "only the host can see the attendee list" or similar owner-only wording (tests check for "only the host can see the attendee list" and "403").
  - Otherwise return attendee list.

Keep existing auth preHandler.

## Verifiable FAIL_TO_PASS
- rejects owner RSVP (source file contains "owner cannot rsvp own event" and "owner_cannot_rsvp")
- allows non-owner RSVP (route file contains owner-only 403 logic)
- attendees owner-only 403 guard exists (contains "403")

## Files
- server/src/modules/events/events.repository.ts
- server/src/modules/events/events.routes.ts
- server/src/modules/events/events.rsvp-ownership.test.ts (verifier, installed via test_patch)
