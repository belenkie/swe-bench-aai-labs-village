# Village Fix: village-rsvp-ownership

## Context
Village is Expo SDK 57 + Fastify server app (map clustering, geospatial bounds, timezone DST, auth, uploads, RSVP).

## Bug
In the base commit `c51d1268`, the following behavior is broken / missing in cell **Bug-Fix / RSVP Ownership**:

village-rsvp-ownership

Affected files:
- `server/src/modules/events/events.repository.ts`
- `server/src/modules/events/events.routes.ts`

## Current buggy behavior (at base commit)
The base commit does NOT correctly handle the case described. Tests that check the fixed behavior will FAIL at base.

## Required fix (outcome only — do NOT state implementation)
Fix the codebase so that:

- The behavior described in `village-rsvp-ownership` works correctly.
- Existing relevant tests continue to pass (PASS_TO_PASS).
- New tests that verify the fixed behavior pass (FAIL_TO_PASS).

Specific requirements:
- Modify EXISTING code (3-8 files bounded).
- Keep change minimal and self-contained, no unrelated refactors.
- Handle edge cases: zero-area viewport, empty arrays, invalid inputs, DST gaps, antimeridian wrap as applicable to Bug-Fix / RSVP Ownership.
- Preserve exact validation error messages expected by tests (copy from existing validators).

## Verifiable outcome
- Before fix: at least one FAIL_TO_PASS test fails.
- After fix: FAIL_TO_PASS tests flip to PASS, PASS_TO_PASS stays PASS.
- Run `npx tsx --test <selected_test_files>` to verify locally.

## Files to inspect
Start by reading:
- `src/lib/geo.ts` (boundsFromCenter, boundsArea, boundsCoverage)
- `src/lib/clustering.ts` (haversineMeters, metersPerPixelFromViewport, clusterEvents)
- `src/lib/timezone.ts` (getTimezoneOffsetMinutes, convertLocalWallToTimezone)
- `server/src/modules/events/events.routes.ts` (validateBounds, validateLimit, validateCreateEventInput)
- `server/src/modules/auth/state.ts`, `allowlist.ts`
- `server/src/modules/uploads/uploads.routes.ts` (detectMimeFromBuffer)
- `server/src/modules/events/events.repository.ts` (rsvpEvent, rowToEvent)

Base commit: `c51d1268118d1d5673fb274d8b648fbcd1ce8678`
Fix commit reference (for oracle generation only, not visible to agent at eval): `2e4675367bce59c49c4248b081aa50047dcaeda9`

Patch excerpt (for understanding only):
```diff
diff --git a/server/src/modules/events/events.repository.ts b/server/src/modules/events/events.repository.ts
index cf1cd7e..9e394c1 100644
--- a/server/src/modules/events/events.repository.ts
+++ b/server/src/modules/events/events.repository.ts
@@ -351,8 +351,9 @@ export async function rsvpEvent(eventId: string, userId: string): Promise<{ resu
       return null;
     }
     // Owner/host cannot RSVP to their own event — uses created_by as owner identifier (unified from owner_id)
+    // V-RSVP-01: owner cannot RSVP own event — 400 with explicit message for SWE-bench task village-rsvp-ownership
     if (exists.rows[0].created_by && exists.rows[0].created_by === userId) {
-      const err = new Error("owner_cannot_rsvp: hosts cannot RSVP to their own event") as Error & {
+      const err = new Error("owner cannot rsvp own event: owner_cannot_rsvp") as Error & {
         code?: string;
         statusCode?: number;
       };
diff --git a/server/src/modules/events/events.routes.ts b/server/src/modules/events/events.routes.ts
index 80e5831..e3d8998 100644
--- a/server/src/modules/events/events.routes.ts
+++ b/server/src/modules/events/events.routes.ts
@@ -501,6 +501,7 @@ export async function registerEventRoutes(app: FastifyInstance) {
 
   // GET /api/events/:id/attendees — owner-only attendee list (uses created_by as owner)
   // Merged from feature/event-ownership — previously used owner_id, now unified to created_by/organizerId per main's PR
+  // V-RSVP-01: owner-only 403 guard — only host can list attendees (SWE-bench village-rsvp-ownership)
   app.get("/api/events/:id/attendees", { preHandler: [app.authenticate] }, async (request, reply) => {
     const { id } = request.params as { id: string };
```

## Deliverable
Modify files in repo to fix bug. Do NOT edit test files — they are hidden verifier.
