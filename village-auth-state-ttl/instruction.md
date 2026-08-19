# Village Fix: village-auth-state-ttl

## Context
Village is Expo SDK 57 + Fastify server app (map clustering, geospatial bounds, timezone DST, auth, uploads, RSVP).

## Bug
In the base commit `c51d1268`, the following behavior is broken / missing in cell **Security / Auth / Allowlist**:

village-auth-state-ttl

Affected files:
- `server/src/modules/auth/state.ts`

## Current buggy behavior (at base commit)
The base commit does NOT correctly handle the case described. Tests that check the fixed behavior will FAIL at base.

## Required fix (outcome only — do NOT state implementation)
Fix the codebase so that:

- The behavior described in `village-auth-state-ttl` works correctly.
- Existing relevant tests continue to pass (PASS_TO_PASS).
- New tests that verify the fixed behavior pass (FAIL_TO_PASS).

Specific requirements:
- Modify EXISTING code (3-8 files bounded).
- Keep change minimal and self-contained, no unrelated refactors.
- Handle edge cases: zero-area viewport, empty arrays, invalid inputs, DST gaps, antimeridian wrap as applicable to Security / Auth / Allowlist.
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
Fix commit reference (for oracle generation only, not visible to agent at eval): `d0b6d4b90728a0b1b425eb2ddfe0934eee8a1b5c`

Patch excerpt (for understanding only):
```diff
diff --git a/server/src/modules/auth/state.ts b/server/src/modules/auth/state.ts
index 02ca361..91dbf23 100644
--- a/server/src/modules/auth/state.ts
+++ b/server/src/modules/auth/state.ts
@@ -21,6 +21,30 @@ export type StatePayload = {
 
 export const STATE_TTL_MS = 10 * 60 * 1000;
 
+// V-AUTH-01: nonce replay protection — LRU cache of 1000 recent nonces to prevent reuse
+const MAX_NONCE_CACHE = 1000;
+const seenNonces = new Set<string>();
+const nonceQueue: string[] = [];
+
+function isNonceReplay(nonce: string): boolean {
+  return seenNonces.has(nonce);
+}
+
+function markNonceUsed(nonce: string): void {
+  if (seenNonces.has(nonce)) return;
+  seenNonces.add(nonce);
+  nonceQueue.push(nonce);
+  if (nonceQueue.length > MAX_NONCE_CACHE) {
+    const oldest = nonceQueue.shift()!;
+    seenNonces.delete(oldest);
+  }
+}
+
+export function clearNonceCacheForTesting(): void {
+  seenNonces.clear();
+  nonceQueue.length = 0;
+}
+
 // Bump the version suffix to rotate the derived key independently of JWT_SECRET.
 const STATE_KEY_INFO = "village:oauth-state:v1";
 const STATE_KEY_BYTES = 32;
@@ -80,5 +104,11 @@ export function verifyState(token: string, secret: string): StatePayload {
   if (now - payload.iat > STATE_TTL_MS) throw new Error("[state] Expired");
   if (payload.iat > now + 60_000) throw new Error("[state] Invalid iat (future)");
 
+  // V-AUTH-01: nonce reuse guard — prevent replay attacks
+  if (isNonceReplay(payload.nonce)) {
+    throw new Error("[state] Nonce already used");
+  }
+  markNonceUsed(payload.nonce);
+
   return payload;
 }
```

## Deliverable
Modify files in repo to fix bug. Do NOT edit test files — they are hidden verifier.
