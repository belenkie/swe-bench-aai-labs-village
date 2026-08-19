# Village: fix(map) fallback to last known position when no fresh fix is available

## Context
Village app centers the map on user's current location on mount via `useUserLocation()` hook (`src/components/map/useUserLocation.ts`). It uses `expo-location`.

Problem: `Location.getCurrentPositionAsync()` only resolves when OS produces a *new* fix. Cold GPS start can take tens of seconds, and Android/iOS emulator only emits a position when explicitly pushed via extended controls. In both cases the hook threw, causing `VillageMap` to render "Location Unavailable" error screen instead of centering.

## Expected behavior
- When a fresh fix cannot be obtained, fall back to `Location.getLastKnownPositionAsync()`.
- Only surface the error when there is no fix at all (both fresh and last-known fail).
- Both call sites (initial mount effect and `fetchLocation` refresh) should share one helper to avoid duplicating position-mapping logic.
- The helper should normalize `LocationObject` → `UserLocation` (latitude, longitude, accuracy, altitude).

## Bug to fix
In current buggy state (`base_commit` `0eed4c7a9ae61b7bc6c3c545e8ebc756902f2cbd`):
- `fetchLocation` directly calls `getCurrentPositionAsync` and maps coords inline, duplicated in the `useEffect` initial auto-fetch.
- If `getCurrentPositionAsync` throws (cold start, emulator with no push), the error propagates and UI shows error, never trying `getLastKnownPositionAsync`.

## Requirements
- Create helper `toUserLocation(pos: Location.LocationObject): UserLocation` mapping coords.
- Create async `resolvePosition(): Promise<UserLocation>` that:
  1. tries `Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced })` → `toUserLocation`
  2. on catch, tries `Location.getLastKnownPositionAsync()`, if non-null returns `toUserLocation(last)`
  3. otherwise re-throws original error
- Refactor both `fetchLocation` and the initial `useEffect` to use `resolvePosition()`, removing duplicated mapping.
- Keep permission handling intact: request foreground permission, handle denial.
- Keep loading/error state handling.

## Verification
- Unit tests in `src/components/map/useUserLocation.fallback.test.ts` check:
  - source file contains `getLastKnownPositionAsync`
  - source file contains shared `resolvePosition` helper
  - `resolvePosition` successfully falls back when fresh throws but last known exists
  - `resolvePosition` throws when both fresh and last-known fail
  - `toUserLocation` correctly maps LocationObject

Existing tests (`src/lib/clustering.test.ts`, `src/lib/location.test.ts`) must still pass (PASS_TO_PASS).

## References
Original fix commit: `b6c980667aeeb57b10e194fa554ec7b91561a411` message:
> fix(map): fall back to last known position when no fresh fix is available
> getCurrentPositionAsync only resolves once the OS produces a *new* fix...
> Fall back to getLastKnownPositionAsync and only surface the error when there is no fix at all.
