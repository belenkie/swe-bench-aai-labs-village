# village-clustering-antimeridian-fix

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Map clustering in `src/lib/clustering.ts` groups nearby events into clusters for display. Functions: `haversineMeters`, `metersPerPixel`, `metersPerPixelFromViewport`, `clusterEvents`, `getClusterCentroid`. Source at `/app` in container. Node 20, `tsx@4.23.1`.

## Bug description
In base commit `4c695a5f915cadf87be1ffd198cc55575e22ea4d`, clustering does NOT handle antimeridian wrap:

- `metersPerPixelFromViewport` computes centerLng as `(east+west)/2` and width via haversine between west/east at centerLat. When viewport crosses 180° meridian (west=179, east=-179), naive width is 358° (~40,000km) instead of 2° (~222km). Should detect `east < west` as antimeridian crossing.
- `getClusterCentroid` averages longitudes arithmetic mean: (179 + -179)/2 = 0, but correct circular mean should be ~180°.
- `clusterEvents` recomputes centroid via arithmetic mean of lat/lng after adding event and during merge pass, propagating same error.

Without fix:
- Events at 179 and -179 should cluster with large radius (200km) but don't because distance calculated correctly by haversine (which uses sin, works) but centroid drifts to 0.
- Centroid of 179 and -179 should be ~180 (or -180), not 0.

## Required fix outcome
- Add `normalizeLongitude(lng)` helper: normalize to [-180,180] via ((lng+180)%360+360)%360-180, returning 180 when input positive and normalized is -180.
- Add `averageLongitudes(longitudes)` using circular mean: convert to rad, sum sin/cos, atan2, normalize.
- In `metersPerPixelFromViewport`: if `east < west`, adjust eastAdj = east+360, centerAdj = (west+eastAdj)/2, centerLng = normalizeLongitude(centerAdj). Keep haversine width calculation (haversine already handles short great-circle, so 179 to -179 distance = 2° distance).
- In `getClusterCentroid`: instead of arithmetic lng average, use `averageLongitudes`.
- In `clusterEvents`: when nearest found, push event then recompute centroid via `getClusterCentroid(nearest.events)`. Similarly for merge pass: combine events array and recompute centroid via `getClusterCentroid`.

Keep existing API shape, no new dependencies.

## Verifiable FAIL_TO_PASS
- centroid of 179 and -179 should be 180 not 0
- centroid of 170 and -170 should be 180
- centroid of three points crossing antimeridian near 180
- clusters across antimeridian with large radius (e.g., 200km)
- clusters near antimeridian keep correct centroid after merge

## PASS_TO_PASS (regression)
- haversineMeters SF to nearby ~100m, identical 0
- metersPerPixel equator zoom 0 ~156km, SF zoom15 ~3-4m
- metersPerPixelFromViewport responsive, viewport+bounds radius = mpp*markerPx
- clusterEvents core: zero events empty, identical coords cluster, just outside threshold not clustered, centroid average, merge pass, stable keys sorted, singletons sorted
- getClusterCentroid average
- metersPerPixelFromViewport handles antimeridian width

## Files
- src/lib/clustering.ts
- src/lib/clustering.test.ts
- src/lib/clustering.antimeridian.test.ts
