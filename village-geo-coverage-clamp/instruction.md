# village-geo-coverage-clamp

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

## Bug description

## Bug description
- `boundsCoverage` computes `1 - uncovered/total`. Floating rounding or duplicate subtraction can produce uncovered negative -> coverage >1, or remaining > total -> coverage negative. No clamp, so caller "Search this area" visibility logic gets >1 or <0.
- Also when viewport total=0 (zero-area degenerate bounds), returns 0 correctly but other edge paths produce NaN.

## Required fix outcome
- Clamp return: `Math.max(0, Math.min(1, coverage))` ensuring result always 0..1.
- Keep total==0 early return 0.
- Single file: src/lib/geo.ts

## Verifiable FAIL_TO_PASS
- clamps to 1 when super-cover
- clamps to 0 when zero area
- partial overlap 0..1
- exact 1 when fully covered

## Files to inspect
- src/lib/geo.ts


## Affected files
- src/lib/geo.test.ts
- (plus related libs)

## Required fix outcome (3-8 files, minimal)
- Fix root cause only, keep existing API shape.
- Do not add new dependencies.
- Must pass new FAIL_TO_PASS tests and existing PASS_TO_PASS.

## Verifiable FAIL_TO_PASS flips
- boundsCoverage clamps to 1 when areas exceed viewport super-cover
- boundsCoverage clamps to 0 when viewport zero area
- boundsCoverage returns 0..1 for partial overlap
- boundsCoverage exact 1 when fully covered

## PASS_TO_PASS (existing should stay green)
- boundsArea positive
- boundsCoverage returns fraction covered
- boundsFromCenter clamps latitude

## Files to inspect
- src/lib/geo.test.ts
- src/types/events.ts / server code as needed
