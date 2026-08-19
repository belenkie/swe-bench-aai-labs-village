# village-map-fallback-last-known-position

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

## Bug description

## Bug description
- Cold GPS start (fresh install, tunnel, emulator with no pushed location) makes `getCurrentPositionAsync` throw/timeout. Current buggy code duplicates mapping logic and shows error screen instead of using stale but usable last-known fix.
- Hook `useUserLocation.ts` calls `getCurrentPositionAsync` directly in two places (fetchLocation and useEffect), duplicating coords mapping.
- Expected fallback: try fresh fix, on failure call `getLastKnownPositionAsync`, if present return it.

## Required fix outcome
- Extract `toUserLocation(pos: LocationObject) => UserLocation` mapper.
- Extract `async function resolvePosition(): Promise<UserLocation>` that tries `getCurrentPositionAsync({ accuracy: Balanced })` then fallback to `getLastKnownPositionAsync`.
- Both call sites (fetchLocation callback and initial useEffect) must call `resolvePosition()`.
- Reduces duplication from 3 direct `pos.coords.latitude` mappings to ≤2 (one in `toUserLocation` + one in tracking hook).
- File count: 1 (src/components/map/useUserLocation.ts)

## Verifiable FAIL_TO_PASS flips
- source contains getLastKnownPositionAsync fallback
- source contains shared resolvePosition helper
- source contains toUserLocation mapper
- falls back to last known when fresh fix throws
- returns fresh fix when available

## Files to inspect
- src/components/map/useUserLocation.ts
- src/components/map/useUserLocation.fallback.test.ts (verifier)


## Affected files
- src/components/map/useUserLocation.fallback.test.ts
- (plus related libs)

## Required fix outcome (3-8 files, minimal)
- Fix root cause only, keep existing API shape.
- Do not add new dependencies.
- Must pass new FAIL_TO_PASS tests and existing PASS_TO_PASS.

## Verifiable FAIL_TO_PASS flips
- source contains getLastKnownPositionAsync fallback
- source contains shared resolvePosition helper
- source contains toUserLocation mapper to avoid duplication
- falls back to last known when fresh fix throws
- returns fresh fix when available, ignoring last known

## PASS_TO_PASS (existing should stay green)
- toUserLocation correctly maps fields and handles nulls
- throws when both fresh and last known fail
- both call sites use resolvePosition not duplicated getCurrentPosition mapping

## Files to inspect
- src/components/map/useUserLocation.fallback.test.ts
- src/types/events.ts / server code as needed
