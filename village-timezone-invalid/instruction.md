# Village Fix: village-timezone-invalid

## Context
Village is Expo SDK 57 + Fastify server app (map clustering, geospatial bounds, timezone DST, auth, uploads, RSVP).

## Bug
In the base commit `c51d1268`, the following behavior is broken / missing in cell **Timezone / DST**:

village-timezone-invalid

Affected files:
- `src/lib/timezone.ts`

## Current buggy behavior (at base commit)
The base commit does NOT correctly handle the case described. Tests that check the fixed behavior will FAIL at base.

## Required fix (outcome only — do NOT state implementation)
Fix the codebase so that:

- The behavior described in `village-timezone-invalid` works correctly.
- Existing relevant tests continue to pass (PASS_TO_PASS).
- New tests that verify the fixed behavior pass (FAIL_TO_PASS).

Specific requirements:
- Modify EXISTING code (3-8 files bounded).
- Keep change minimal and self-contained, no unrelated refactors.
- Handle edge cases: zero-area viewport, empty arrays, invalid inputs, DST gaps, antimeridian wrap as applicable to Timezone / DST.
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
Fix commit reference (for oracle generation only, not visible to agent at eval): `7aef8078db90cf9c5bbdc707180ad5139b38fd48`

Patch excerpt (for understanding only):
```diff
diff --git a/src/lib/timezone.ts b/src/lib/timezone.ts
index bbd561f..f4fb15c 100644
--- a/src/lib/timezone.ts
+++ b/src/lib/timezone.ts
@@ -14,6 +14,17 @@
  */
 
 export function getTimezoneOffsetMinutes(timeZone: string, date: Date): number {
+  // V-TZ-02: explicit invalid timezone guard — throw controlled error for SWE-bench village-timezone-invalid
+  if (typeof timeZone !== 'string' || timeZone.trim().length === 0) {
+    throw new Error(`Invalid timezone: ${String(timeZone)}`);
+  }
+  try {
+    // Validate IANA timezone via Intl — throws RangeError for invalid zones
+    new Intl.DateTimeFormat('en-US', { timeZone });
+  } catch {
+    throw new Error(`Invalid timezone: ${timeZone}`);
+  }
+
   // Format date in timeZone and UTC, build UTC dates from parts, diff gives offset
   const formatter = new Intl.DateTimeFormat('en-US', {
     timeZone,
```

## Deliverable
Modify files in repo to fix bug. Do NOT edit test files — they are hidden verifier.
