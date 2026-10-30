# Licensing and security boundary

## What exists

This is the implemented **offline team licensing pilot**, with a native foundation for signed claims, device/installation binding, clocks, permits and local persistence. It is not evidence of a deployed customer billing, activation, revocation, floating-seat or account-management service.

The product contains public trust. The separate owner signer holds issuance authority. Native authoring admission binds a short-lived permit to operation, session and owner and consumes it at commit; unknown/stale/reused permits must fail. Source inspection follows `license_boundary.h`, `team_license.cpp`, `client.cpp`, `signed_license.cpp`, `operation_permit.cpp` and script/managed authoring entry points. The restricted MCP license boundary has separate mock/service checks.

Recovery, inspection, rendering and saving existing work must remain distinct from licensed authoring. Denying recovery is not an optimization or a security improvement. The existing team-pilot guidance explicitly does not claim that every arbitrary script parameter assignment or scene manipulation is a cryptographically protected ownership boundary. That acknowledged scope is not reported as a newly discovered bypass.

## Test isolation

No real owner private key or license token was read/exported. No real activation endpoint, billing service or production grant was exercised. The baseline was compiled with the existing public trust only; compiling does not open a user's license store.

For host tests, an ephemeral P-256 issuer key existed only in a separate Python process's memory. A unique `review-08763-*` public trust ID was compiled into a separate native build, giving those hosts a separate installation key and local state namespace. A synthetic 30-minute grant authorized only that test installation. The signer was stopped after testing. Test licenses, requests and installation state are excluded from the report archive. The script/native pair used in each private host is hashed in its loaded-identity receipt.

This distinction matters: the current source was tested in Max, but these were **not** the shipped owner-trust binaries. The shipped package's bytes and trust/configuration identity were checked statically. The alternate trust header is test configuration, not a product source edit or deliverable.

## Fresh results

| Group | Assertions |
|---|---:|
| Token/profile grammar | 109 |
| Signature | 285 |
| Claims | 169 |
| Product/build/device scope | 33 |
| Lifecycle/expiry | 19 |
| Session isolation | 261 |
| Single-use operation permits | 19 |
| Publication | 4 |
| Transfer | 6 |
| Activation proof/nonce fixtures | 49 |
| **Total** | **954** |

All ten groups passed using generated synthetic vectors. Existing native policy and local clock/key/store suites also passed as part of the 62-test build. Python issuer tests use temporary authorities/stores. The private Max host started denied, rejected a malformed import without becoming authorized, then admitted its correct synthetic installation grant and completed authored fixture work. This is narrower than freshly testing every direct product primitive under expired authorization.

The activation/transfer tests validate local logic and signed fixture protocol. They do not verify a real service, real subscription renewal, online seat contention or remote revocation.

## Hot-path cost and lifetime

`LocalLicenseClient::admit/consume` use in-memory verified state, clock observation and mutexes. They do not perform network requests, file hashing or signature verification on each drag/orbit operation. Constructor/import/activation/refresh may do storage and cryptography. `team_license.cpp` performs periodic maintenance on a 60-second worker; that worker touches no Max API and is joined on shutdown/unload. Four private host runs exited normally.

The isolated 100,000-iteration, nine-trial microbenchmark measured medians of **8.201 ns** for pure policy, **27.259 ns** for verified-session decision and **35.315 ns** for admit+consume. These numbers exclude MaxScript, the product client's clock/mutex wrapper and maintenance contention. They are not artist frame timings. Removing authorization checks would trade away correctness for an unproven benefit.

## Remaining security acceptance

- Native Scene content is still loaded by Max; immutable hashes and safe extraction are integrity mechanisms, not a `.max` sandbox.
- The test-only issuer grants are deliberately excluded from the ZIP. No production credentials should appear in crash/support bundles either.
- Cross-process refresh/checkpoint races, real offline clock recovery under diverse system changes, hostile ACL/reparse changes and service behavior need their own bounded campaigns before customer-service claims.
- FS-02's obsolete license wording should be corrected without mixing the independent foundation version with the Scatter product version.
- Steady-state behavior is favorable; no audit here proves every external renderer or arbitrary script path participates in the same authorization contract.
