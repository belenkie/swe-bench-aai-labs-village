# Village Fix: village-validate-bounds-edge

## Context
Village is Expo SDK 57 + Fastify server app (map clustering, geospatial bounds, timezone DST, auth, uploads, RSVP).

## Bug
In the base commit `c51d1268`, the following behavior is broken / missing in cell **Validation / Input Guards**:

village-validate-bounds-edge

Affected files:
- `server/src/modules/events/events.routes.ts`

## Current buggy behavior (at base commit)
The base commit does NOT correctly handle the case described. Tests that check the fixed behavior will FAIL at base.

## Required fix (outcome only — do NOT state implementation)
Fix the codebase so that:

- The behavior described in `village-validate-bounds-edge` works correctly.
- Existing relevant tests continue to pass (PASS_TO_PASS).
- New tests that verify the fixed behavior pass (FAIL_TO_PASS).

Specific requirements:
- Modify EXISTING code (3-8 files bounded).
- Keep change minimal and self-contained, no unrelated refactors.
- Handle edge cases: zero-area viewport, empty arrays, invalid inputs, DST gaps, antimeridian wrap as applicable to Validation / Input Guards.
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
Fix commit reference (for oracle generation only, not visible to agent at eval): `861a76f2c7cbdaa05b9f689f7c12f8a1b43d3667`

Patch excerpt (for understanding only):
```diff
diff --git a/server/src/modules/events/events.routes.ts b/server/src/modules/events/events.routes.ts
index 80e5831..455d669 100644
--- a/server/src/modules/events/events.routes.ts
+++ b/server/src/modules/events/events.routes.ts
@@ -31,12 +31,19 @@ function validateBounds(query: any): BoundsValidationResult {
     if (raw === undefined || raw === null || raw === "") {
       return { ok: false, message: `missing ${f}: query param ${f} is required` };
     }
+    // V-GEO-02 variant: reject array / empty-string-array edge (SWE-bench village-validate-bounds-edge)
+    if (Array.isArray(raw)) {
+      return { ok: false, message: `${f} must be a number: got ${JSON.stringify(raw)}` };
+    }
   }
 
   // 2) non-numeric
   const parsed: Record<string, number> = {};
   for (const f of fields) {
     const raw = query[f];
+    if (Array.isArray(raw)) {
+      return { ok: false, message: `${f} must be a number: got ${JSON.stringify(raw)}` };
+    }
     // parseFloat handles strings; we already checked missing
     const num = typeof raw === "number" ? raw : parseFloat(String(raw));
     if (!Number.isFinite(num)) {
@@ -273,6 +280,10 @@ export function validateLimit(raw: unknown): LimitValidationResult {
     if (!Number.isInteger(num)) {
       return { ok: false, message: `limit must be an integer: got ${JSON.stringify(raw)}` };
     }
+    // V-GEO-02 variant: reject negative, zero, >100 (SWE-bench village-validate-bounds-edge)
+    if (num < 1 || num > 100) {
+      return { ok: false, message: `limit out of range: must be between 1 and 100, got ${num}` };
+    }
     return { ok: true, value: num };
   }
 
@@ -283,6 +294,10 @@ export function validateLimit(raw: unknown): LimitValidationResult {
   if (!Number.isInteger(num)) {
     return { ok: false, message: `limit must be an integer: got ${JSON.stringify(raw)}` };
   }
+  // V-GEO-02 variant: range guard
+  if (num < 1 || num > 100) {
+    return { ok: false, message: `limit out of range: must be between 1 and 100,
```

## Deliverable
Modify files in repo to fix bug. Do NOT edit test files — they are hidden verifier.
