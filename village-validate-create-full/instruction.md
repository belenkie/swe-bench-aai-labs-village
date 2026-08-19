# Village Fix: village-validate-create-full

## Context
Village is Expo SDK 57 + Fastify server app (map clustering, geospatial bounds, timezone DST, auth, uploads, RSVP).

## Bug
In the base commit `c51d1268`, the following behavior is broken / missing in cell **Validation / Input Guards**:

village-validate-create-full

Affected files:
- `server/src/modules/events/events.routes.ts`

## Current buggy behavior (at base commit)
The base commit does NOT correctly handle the case described. Tests that check the fixed behavior will FAIL at base.

## Required fix (outcome only — do NOT state implementation)
Fix the codebase so that:

- The behavior described in `village-validate-create-full` works correctly.
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
Fix commit reference (for oracle generation only, not visible to agent at eval): `226f4b03d900f487466c386ab3b979f3c349bdd0`

Patch excerpt (for understanding only):
```diff
diff --git a/server/src/modules/events/events.routes.ts b/server/src/modules/events/events.routes.ts
index 80e5831..185376d 100644
--- a/server/src/modules/events/events.routes.ts
+++ b/server/src/modules/events/events.routes.ts
@@ -194,6 +194,21 @@ export function validateCreateEventInput(body: any): CreateValidationResult {
   if (rawPrice !== undefined && rawPrice !== null && typeof rawPrice !== "string") {
     return { ok: false, message: "price must be a string" };
   }
+  // V-VAL-02: price numeric guard — must be numeric or 'Free' (SWE-bench village-validate-create-full)
+  if (typeof rawPrice === "string" && rawPrice.trim().length > 0) {
+    const trimmed = rawPrice.trim();
+    const lower = trimmed.toLowerCase();
+    if (lower !== "free") {
+      const cleaned = trimmed.replace(/[$,\s]/g, "");
+      if (/[a-zA-Z]/.test(cleaned)) {
+        return { ok: false, message: "price must be a numeric string or 'Free'" };
+      }
+      const num = Number(cleaned);
+      if (!Number.isFinite(num)) {
+        return { ok: false, message: "price must be a numeric string or 'Free'" };
+      }
+    }
+  }
   if (rawAddr !== undefined && rawAddr !== null && typeof rawAddr !== "string") {
     return { ok: false, message: "address must be a string" };
   }
@@ -215,10 +230,10 @@ export function validateCreateEventInput(body: any): CreateValidationResult {
     timezone: rawTz,
     latitude: rawLat,
     longitude: rawLng,
-    address: typeof rawAddr === "string" && rawAddr.trim().length > 0 ? rawAddr : undefined,
-    venue: typeof rawVenue === "string" && rawVenue.trim().length > 0 ? rawVenue : undefined,
-    description: typeof rawDescription === "string" ? rawDescription : undefined,
-    price: typeof rawPrice === "string" ? rawPrice : undefined,
+    address: typeof rawAddr === "string" && rawAddr.trim().length > 0 ? rawAddr.trim() : undefined,
+    venue: typeof rawVenue === "string" && rawVenue.trim().length > 0 ? rawVenue.trim() : undefined,
+    descri
```

## Deliverable
Modify files in repo to fix bug. Do NOT edit test files — they are hidden verifier.
