# village-clustering-antimeridian-fix

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

## Bug description

## Bug description
- `metersPerPixelFromViewport` comment says "does NOT handle antimeridian wrap (west=179, east=-179 → width 2° not 358°)". When bounds cross antimeridian (e.g. Fiji, Pacific), width is computed as 358° instead of 2°, making mpp ~100x larger and clustering breaks.
- `getClusterCentroid` averages longitudes arithmetically: avg(179, -179)=0 instead of 180, centroid snapped wrong side of globe.
- Missing `normalizeLongitude` helper to wrap any lng into [-180,180).

## Required fix outcome
- Add `export function normalizeLongitude(lng: number): number` returning ((((lng+180)%360)+360)%360)-180
- Add `export function averageLongitudes(lngs: number[]): number` using circular mean (atan2 avg sin/cos) then normalize
- Update `metersPerPixelFromViewport` to detect east<west and add 360 to east for width calc, normalize centerLng
- Update `getClusterCentroid` to use `averageLongitudes` instead of arithmetic mean
- Keep existing haversine, marker logic intact; only 1 file changed ideally but up to 3 files allowed.

## Verifiable FAIL_TO_PASS flips
- `normalizeLongitude wraps 190 to -170` — now passes
- `averageLongitudes circular mean across antimeridian 179 and -179` — avg ~±180 not 0
- `metersPerPixelFromViewport handles east<west antimeridian` — small mpp not huge
- `clusterEvents antimeridian close points cluster` — 0.2° across date line clusters with 50km radius

## Files to inspect
- src/lib/clustering.ts
- src/types/events.ts (EventBounds shape)


## Affected files
- src/lib/clustering.test.ts
- (plus related libs)

## Required fix outcome (3-8 files, minimal)
- Fix root cause only, keep existing API shape.
- Do not add new dependencies.
- Must pass new FAIL_TO_PASS tests and existing PASS_TO_PASS.

## Verifiable FAIL_TO_PASS flips
- normalizeLongitude wraps 190 to -170
- normalizeLongitude wraps -190 to 170
- averageLongitudes circular mean across antimeridian 179 and -179
- metersPerPixelFromViewport handles east<west antimeridian
- clusterEvents antimeridian close points cluster

## PASS_TO_PASS (existing should stay green)
- haversineMeters — known distances > SF to nearby ~100m
- getResponsiveClusterRadius — mpp * markerPx > viewport + bounds produces radius
- clusterEvents — core > identical coords always cluster

## Files to inspect
- src/lib/clustering.test.ts
- src/lib/geo.test.ts
- src/types/events.ts / server code as needed
