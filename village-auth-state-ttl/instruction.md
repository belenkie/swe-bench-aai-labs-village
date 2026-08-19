# village-auth-state-ttl

## Context
Village Expo SDK57+ Fastify — Village is a community event discovery app (SF Bay). Source at `/app` in container. Node 20, `npm ci --ignore-scripts`, `tsx@4.23.1` global. Tests via `npx tsx --test`.

Village handles OAuth via `server/src/modules/auth/state.ts` which signs and verifies an opaque state payload containing provider, redirectUri, nonce, and iat. The module already checks TTL.

## Bug description
In base commit `c51d1268`, `verifyState` does NOT protect against nonce replay:

- An attacker who captures a valid state token can replay it to initiate a second OAuth flow with the same nonce, bypassing CSRF-like protection.
- There is no in-memory cache of recently seen nonces, and no exported helper to clear the cache for testing.
- Expected behavior: after a token is successfully verified, its nonce should be marked as used. A second verification of the same token (same nonce) should fail with "Nonce already used".
- The cache should be bounded (LRU of 1000 recent nonces) to avoid memory leak, evicting oldest entry when full.
- Existing TTL checks must stay: expired state (iat older than STATE_TTL_MS) should throw "Expired", future iat >60s should throw.

## Required fix outcome
- In `server/src/modules/auth/state.ts`:
  - Track recently verified nonces in a Set + queue capped at 1000 entries (LRU eviction).
  - In `verifyState`, after TTL checks but before returning payload, check if nonce was already seen — if yes, throw Error containing "Nonce already used".
  - If not seen, mark nonce as used.
  - Export `clearNonceCacheForTesting()` that clears the cache (so tests can isolate).

## Verifiable FAIL_TO_PASS
- rejects expired state (iat older than STATE_TTL_MS)
- rejects reused nonce (verify same token twice -> second throws /Nonce already used/)

## PASS_TO_PASS (existing should stay green)
- accepts valid state (fresh nonce, recent iat)
- accepts valid state second time with different nonce (different nonce should not trigger replay protection)

## Files to inspect
- server/src/modules/auth/state.ts
- server/src/modules/auth/state.test.ts
- server/src/modules/auth/state.nonce.test.ts (new verifier file installed via test_patch)
