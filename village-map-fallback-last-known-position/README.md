# codimango/village-map-fallback-last-known-position

## Authoring policy

Before authoring, read the [Model usage policy v2](https://codimango.internalmeta.com/tracks/t-bench#model-usage-policy) and the [Workplace v2 post](https://fb.workplace.com/groups/aaitaskquality/posts/1074223732270508). The policy page is the source of truth.

- The task seed must be human; any model may be a thought partner.
- Third-party models (including Codex, Claude, and Gemini) must not author instructions or multi-step prompts, model-visible content, tests, grading rubrics, test/grading configuration, test fixtures, or imported/traced grading inputs.
- Reviewed first-party drafting is allowed; a human must review, own, and remain responsible for the result.
- Never forward third-party-generated findings, summaries, candidate assertions, code, briefs, recommendations, or other context into a first-party session authoring protected content.
- Other hidden, non-test, non-grading files may use any model with human review.

## Task summary
Fix `useUserLocation` hook to fall back to `getLastKnownPositionAsync` when `getCurrentPositionAsync` fails (cold GPS / emulator). Harvested from commit b6c9806.

- base_commit: 0eed4c7a9ae61b7bc6c3c545e8ebc756902f2cbd (before fix)
- fix commit: b6c980667aeeb57b10e194fa554ec7b91561a411
- Difficulty levers: reliability trap, state (stale vs fresh), failure mode (error screen vs stale position), coupling (DRY two call sites via resolvePosition), hidden edge case.

## Validation
- FAIL_TO_PASS: 4 source checks that assert fallback logic exists
- PASS_TO_PASS: 24 existing tests (clustering + location + runtime behavior)
- Locally verified: `tsx --test` passes on fixed, fails on base for FAIL_TO_PASS; full village suite 114 PASS.

## Automation provenance
- Harvester V1 recipe: commits seam (prompts/05), difficulty lever evaluation (prompts/06), oracle-scaffolder (07/08)
- benchwarmer.repository onboard used for Village: `meta benchwarmer.repository onboard --task-repository /Users/ebelenki/swe-bench-pro-ebelenki`
- Tags: harvester-v1, human-reviewed

## Submission
Task dir ready for `harbor run -d . -a oracle` and `harbor run -d . -a no-op` once docker daemon up, or via Codimango MSL ingestion (config.json with patch/test_patch).
