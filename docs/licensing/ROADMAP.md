# Licensing implementation roadmap

**Updated:** 2026-10-05. Current sequence for the owned Cyrus service. **L0/L1 remain IN PROGRESS, with a tested native ownership slice and local foundation now implemented.** The [October 5 result](NATIVE_FOUNDATION_2026-10-05.md) adds immutable publication, bounded permits, real CNG installation identity, DPAPI state, signed activation/time anchoring, two-Max expiry/renewal, and shared CS Edit/Brush mutation gates. Whole-product ownership, recovery/lifecycle and B07/B08 remain open. L2 and commercial L3–L6 gates are not complete. The ordinary product build still has no licensing enforcement.

Continue from the demonstrated native slice to complete operation ownership and host lifecycle; then implement transactional assigned-seat issuance under the selected policy. The development issuer has no customer authentication or seat ledger. Release scope follows evidence, not elapsed coding time or native test counts.

## Milestones and dependencies

| ID | Deliverable | Dependencies | Exit gate |
| --- | --- | --- | --- |
| L0 | Native boundary feasibility and policy contract | Current source and disposable saved-scene fixtures | Direct-call and saved-evaluation behavior documented; render/bake limitations visible; proposed operation map is credible |
| L1 | Standalone LicenseCore and signed-permission harness | L0 contract; test-only policy values may remain configurable | Deterministic decision/parser/signature tests pass; ordinary feature extension needs no protocol rewrite |
| L2 | Owned service for individual and assigned studio seats | L1 profile; identity/signer choice; pilot-relevant B-decisions | Tenant isolation, assignment capacity, activation, issuance, credential and recovery tests pass |
| L3 | Isolated Max integration and manual-grant pilot candidate | L1/L2; operation/continuity policy frozen for candidate | Native coverage, scene/render fidelity, recovery, multi-process behavior and performance gates pass |
| L4 | Optional studio floating and bounded borrowing | L2/L3; B03–B05/B08 fixed for this offer | Cross-worker last-seat races, partitions, crash/retry and outstanding-authority accounting pass |
| L5 | Automated commerce and customer administration | Qualified seat models; approved offers and commercial arrangements | Purchases/seat additions/renewals/reversals are authenticated, idempotent, reconciled and supportable |
| L6 | Security, release and operating qualification | L3, L5 and every optional mode being sold | Independent review, final package/host tests, recovery drills and controlled beta evidence support the exact offer |

L4 is not required for an assigned-seat launch. Manual grants are sufficient for a controlled licensing pilot before L5. CI signing, backups, observability and security review start during development; L6 verifies them together rather than postponing their design.

## L0 — Prove the boundary first

1. Record the source revision and relevant uncommitted changes. Use an isolated experiment build and disposable scenes; keep the artist's live scene and viewport work intact.
2. Turn the [source audit and declaration inventory](CODEBASE_AUDIT.md) into an operation/caller contract. Reconcile all native primitives, UI/generator handlers, parameter setters, CS Edit callbacks, Analyzer dependencies, baking, load/evaluation, animation and renderer transport against the experiment build. The static declaration scan does not cover every SDK callback or script entry.
3. Trace a parameter changed through MAXScript followed by an evaluation callback. Determine whether the current controller can distinguish new authoring from saved-state recomputation without trusting caller flags. A process called `3dsmaxcmd.exe` is not proof of authority.
4. Use fake allowed/denied decisions in a bounded prototype. Exercise direct calls as well as buttons, then open/evaluate/save/reopen a scene with denied new authoring. Admit operations before preview/PFlow cleanup or CS Edit mutation; keep artist enable flags independent. Verify identity bookkeeping, balanced Undo/drag state and retained output on denial. Record expected versus actual state and outputs.
5. Compare any necessary native state ownership against cost and compatibility. If free evaluation can be reused for authoring, document the accepted limitation or revise worker/local-render policy. Do not claim the issue solved by a renamed function or script check.

Include the selected D09/D11 lifecycle in the fixture: authorized edits, offline expiry, denied new edits, save/reopen, successful rendering of existing work, and verified renewal followed by continued editing. Compare parameters and edit identities before/after. Separately vary a source object, distribution surface and animation frame while authoring is locked; record what changes and use the result to settle B07. The render permission is selected, while its precise evaluation boundary and any frozen-geometry promise need proof.

**Output:** `operation_contract` covering each entry path, a disposable fixture/reproduction, observed limitations, and an updated B07 recommendation. The [operation-family contract](OPERATION_CONTRACT.md) now distinguishes the original wrapper failures from the [native recipe/Edit/Brush slice](NATIVE_FOUNDATION_2026-10-05.md). That slice covers direct calls, load/Undo/render and expiry before commit; it does not establish complete operation coverage. Next extend complete layer/source recipes and PFlow/bake failure paths after fixing their continuity policy. Stop expanding the backend if its essential authority assumptions remain unresolved.

## L1 — Build the independent core

Create a host-independent C++ target, a small host-facing ABI, an immutable verified snapshot, a pure policy function, structured reasons and bounded operation permits. Separate rights, build eligibility, connectivity, capacity and time confidence. Keep fake service/clock dependencies in test targets.

The [independent components](../../CyrusLicensing/README.md) now supply pure policy, bounded Windows verification, immutable concurrent snapshots, native owner/session-bound permits and a real CNG/DPAPI/clock client. This is not a stable public ABI, production trust configuration or complete recovery/lifecycle implementation. Deterministic synthetic-clock fixtures and real-installation fixtures are separate build contexts; neither development issuer enters ordinary targets.

The [candidate profile](SIGNED_TOKEN_PROFILE.md) uses CNG/ES256, pinned nlohmann/json and a separate cryptography/OpenSSL issuer. The current 19 groups / 1,120 assertions per SDK and real-installation Max results are recorded in [the October 5 report](NATIVE_FOUNDATION_2026-10-05.md). Continue with production account context, protected signer, qualified release identity and trust/rotation/recovery. Real installation-key evidence is not physical hardware attestation, perfect offline time or a production security assessment.

Define immutable release metadata without changing persisted Max Class IDs. Product versions, service API, signed schema, ABI and commercial policy versions are different identifiers. Avoid redesigning installers merely to centralize one metadata file.

Use C08–C10 in the codebase audit for preparation: register new exposed operations, assert generator anchors, keep network lifecycle outside `DllMain`, and define one intended runtime identity. Existing source/package versions and fixed ZIP timestamps do not establish commercial update eligibility.

**Exit evidence:** E01–E04, E13 and a feature-extension fixture pass outside Max. Production configuration rejects test trust roots and cannot select a fake/unlocked backend through environment variables, configuration or UI. Negative tests exercise combinations, not just a list of flat states.

## L2 — Implement our smallest useful service

Use one codebase with clear auth, licensing, provisioning and administration modules, and one transactional database. Begin with audited manual entitlement grants. Integrate a maintained identity component with native browser login and PKCE; do not write a password system or put a shared client secret in the DLL.

Implement accounts/organizations, roles/invitations, product rights, grant lots, assigned seats, registered installations, issuance records, status/refresh and effective transfer/recovery. Treat one named person's assignment and their device allowance separately. Protect admin identities and the signing service from the first deployable candidate.

Model D13 as an activation limit, separate from person assignment and process count. Reconcile D12 full-term offline grants with B08 before issuing real grants or enabling transfers. A portal deactivation retains the old signed deadline in the ledger and cannot by itself justify capacity reuse. Use a toy two-device experiment with the first disconnected to demonstrate the tradeoff before choosing any overlap exception or shorter window.

Serialize assignment/capacity changes. Persist exact claims and reservation intent before returning signed authority. Specify idempotency scopes, unique constraints, failure/retry behavior and effective dates. Repeated requests must not silently extend deadlines or create duplicate grants.

**Exit evidence:** E05–E08 and E12–E14 for assigned seats. Demonstrate that one studio cannot read or mutate another's data; a signed login token alone cannot become a purchased license; server timeouts cannot cause double issuance. Restoration from stale state is part of this gate.

## L3 — Integrate without harming the product

Consume local decisions at the proven native operation boundaries. Generate status/login/recovery UI from generator inputs. Preserve source/scene schemas, IDs, stored edits, animation and renderer output. Use bounded background refresh and marshal host work safely to the appropriate Max context.

Apply the C01–C07 findings to the candidate: authorization is separate from `cyrusEnabled`; shared computation cannot infer intent from caller flags; denial precedes destructive preparation; selection, restore and edit-identity bookkeeping are classified separately from new authoring. Retaining a viewport cache alone does not prove render continuity.

Test Scatter plus Analyzer installed separately and together, their intended shared runtime identity, two Max processes, multiple supported Max versions and refresh-token rotation during crashes. A common DLL does not synchronize separate processes. Add a broker only if evidence shows a simpler synchronization/session approach inadequate.

Keep future credentials and verified caches outside replaceable plugin folders. Test account switching, repair/reinstall and mixed-version modules. Sign final binaries before generating their distributable hashes; qualify the resulting package, not an earlier unsigned staging copy.

Loading a plugin, opening a recovery panel or orbiting a viewport must not automatically acquire authoring capacity. A license failure must not look like a successful empty scatter. Expiry during an operation follows a bounded completion/checkpoint rule accounted for in reservation deadlines.

**Exit evidence:** E01, E08, E13, E15–E17. Compare licensed, absent, expired, offline and recovered states on the same fixtures. Existing native test results and SDK builds do not replace actual Max/runtime/render tests. Measure authorization cost and failed-refresh behavior against the same-build control.

## L4 — Add floating only with proved accounting

Implement atomic acquire/renew/release, child process sessions, bounded deadlines and status. Start with one authoritative writer. Test multiple API workers and more clients than capacity. Make allocation, renewal, release, capacity reduction and recovery follow one locking/order policy.

For each signed permission, record the latest time it can authorize work, including grace, accepted time uncertainty and permitted operation completion. That is the capacity reservation boundary. A missed heartbeat, process crash or reported local deletion cannot prove old authority unusable.

Explicit offline borrowing is optional. It must remove capacity from the online pool for the full accepted period and transition without double counting. Long-term offline use trades immediate transfer/revocation for convenience; the UI must show effective release timing honestly.

**Exit evidence:** E06–E10 and E13–E14 under the selected floating policy. Defer multi-region writers, customer-hosted servers and long air-gap support until a supported requirement justifies them.

## L5 — Connect purchases and self-service

Keep payment-provider details outside LicenseCore. Verify event origin, durably record ingestion, deduplicate business effects and reconcile unordered/missing events against authoritative order state. A processed-event table alone does not make out-of-order refunds or two distinct events about one purchase safe.

Map catalogue versions to grant lots with preserved quantities, term dates and build eligibility. Test 10 seats becoming 15 exactly once; different expiry terms must not be erased. Implement approved refund/reduction behavior without contradicting outstanding offline grants.

Provide role-scoped seat assignment, invitations, removal, installation recovery, purchase visibility and support audit records. Separate billing permissions from licensing administration and signing privileges.

**Exit evidence:** E05, E10–E12 and operational reconciliation examples. Prices, discounts, proration, trial policy and seller/payment arrangements must be recorded before real checkout. Using a payment processor does not outsource our licensing authority.

## L6 — Qualify the offer we will actually ship

Arrange an independent security assessment of the signed profile, native boundary limitations, tenant access, allocation races, administration and deployment. Resolve release blockers and explicitly record accepted residual risk. No claim of being uncrackable or “enterprise secure” follows from architecture documents alone.

Verify final code signatures, release metadata, dependency inventory, clean-host installation, restricted users, corporate proxies, upgrades, mixed modules and rollback for every advertised Max/renderer configuration. Production artifacts must contain neither test issuer trust nor private signing material.

Run normal key rotation, compromise response, service/signer outage, stale-backup restore, lost-machine and account-recovery drills. Name on-call/support owners and retention policies. A controlled beta needs exact build, scope, results and recovery contacts; launch follows evidence, not a completed checklist template.

## Acceptance experiments

The [October 5 foundation](NATIVE_FOUNDATION_2026-10-05.md) supplies stronger but still **bounded** evidence for E01–E04/E08/E09/E13/E15/E16/E17. E03's laboratory profile passes; production key configuration remains open. E08 has real key/DPAPI and two-process tests, but no cross-user/reinstall/hardware qualification. E13 has clock unit cases and actual expiry mid-Brush gesture, but no final recovery or scheduled host checkpoint lifecycle. E16 has memory-only permit measurements and real file-contention isolation, not whole-product performance qualification. E05–E07/E10–E12/E14 require an implemented service/policy and remain unqualified. The B08 overlap counterexample is evidence of a limit, not successful seat enforcement. No whole release gate is marked complete merely from these passing slices.

| ID | Experiment | Acceptance condition |
| --- | --- | --- |
| E01 | Native operation coverage | Direct primitives, exposed implementation methods, parameter changes and SDK callbacks obey the same contract as UI; classify new entries; saved-state evaluation has no caller-flag bypass claim |
| E02 | Feature and policy extension | A synthetic new same-product authoring command reuses rights; supported synthetic policy values can change without editing computation or signature checks; unknown rights/semantics cannot unlock access; incompatible changes are versioned |
| E03 | Signed data and parser | Modified/wrong-purpose/wrong-tenant/wrong-product/unknown-critical-schema/oversized/ambiguous input fails safely; test keys cannot authorize production |
| E04 | Fact combinations | Outage plus valid cache remains valid; maintenance expiry and old-build eligibility differ; subscription expiry preserves state and blocks new authoring; verified renewal restores covered operations; denials never change artist enable flags |
| E05 | Identity and tenant isolation | Roles and every read/write endpoint enforce membership, ownership and scope; login is not entitlement |
| E06 | Last-seat contention | More than N distinct eligible units across API workers cannot create more than N outstanding reservations; assigned allocation follows its separate invariant |
| E07 | Ambiguous issuance and retry | Dropped responses, signer failures and repeated requests recover the same authority/deadline without duplicate grant or unsafe capacity reuse |
| E08 | Processes and device identity | Intended seat counting holds across Max processes; closing one cannot release another's authority; credentials survive concurrent writes; qualify profile/reinstall/hardware changes and reject copying authority to an unregistered device under the binding model |
| E09 | Partition, borrow and return | Full-term offline simulation reaches the signed subscription deadline without routine refresh; outstanding disconnected permissions remain accounted for; online return cannot imply proof against backup replay |
| E10 | Reduction and reassignment | Portal transfer while A is offline does not erase its outstanding grant; B's activation follows the selected delay/overlap policy; refund, lost-machine and stale-backup cases preserve work and accounting |
| E11 | Commerce | Duplicate, reordered and distinct duplicate business events produce correct 10-to-15, refund and renewal outcomes; reconciliation repairs missing deliveries |
| E12 | Administration and recovery | Invitations, departed employees, lost machines, account recovery and support grants are least-privilege, scoped and audited |
| E13 | Time and operation lifetime | Restart, closed-app elapsed time, sleep/hibernate, UTC/timezone changes, backward/forward clock changes, missing/restored local state and prolonged Max uptime follow deadline/recovery policy; expiry mid-drag leaves Undo/locks balanced; no perfect offline-clock claim |
| E14 | Trust and database recovery | Normal rotation differs from compromise; stale restores do not forget live grants; production secrets and test authority remain isolated |
| E15 | Scene and render fidelity | D11 existing-work render succeeds after offline expiry while new edits deny; open/save/reopen without caches, identity recovery, Undo/Redo, animation and verified renewal preserve approved behavior; test dependent Analyzer/PFlow paths, renderability rollback and bake/export scope |
| E16 | Performance and outage | Zero licensing network/signature/storage work in draw/point loops; offline refresh cannot stall Max; operation decisions stay within the agreed measured budget |
| E17 | Packaging and hosts | Actual advertised Max versions, module install/load order, ordinary users, proxy setup, account switch, repair/upgrade/uninstall and rollback pass with final signed artifacts and explicit release identity |

## Immediate coding packet

- [x] Record the static source map, selected-file fingerprints and native declaration inventory in [CODEBASE_AUDIT.md](CODEBASE_AUDIT.md). This is discovery evidence only.
- [x] Freeze the first experiment's source snapshot and disposable fixture; reconcile Brush/group/MCP additions since the audit and preserve unrelated work.
- [x] Record a provisional operation-family contract and changed-parameter versus saved-evaluation counterexamples. Complete entry-path coverage remains L0 work.
- [x] Exercise wrapper denial before preview cleanup and selected CS Edit/Brush mutations; preserve enable controls, identities and the tested Undo paths.
- [x] Prototype native ownership of amount/seed; cover direct calls, real CS Edit mutation and the actual SDK Move callback. Extend shared admission to Brush history/gestures without duplicating the runtime.
- [ ] Extend native ownership to the complete procedural recipe and denial before PFlow/bake cleanup, including failure rollback and old-scene migration.
- [ ] Prove D09/D11 offline expiry/save/reopen/render/renewal behavior; resolve B07 dependency scope before claiming the selected rendering behavior is qualified.
- [x] Demonstrate that issuing B a new full-term grant leaves disconnected A's signed authority valid; present the B08 delay/overlap choice. This is a synthetic issuer counterexample, not an implemented portal.
- [x] Define `Operation`, independent facts and structured `Decision` in a host-independent test target.
- [x] Add immutable verified snapshot ownership and bounded, single-use operation lifetime; test wrong owner/session, replay, renewal and expiry before commit.
- [ ] Qualify immutable production release identity and old-build eligibility.
- [x] Add real installation-key proof, protected transactional state, fresh signed activation anchor and renewal; verify same-user concurrent processes and file contention.
- [x] Add background local checkpoint/refresh; prove renewal propagation without a refresh button and clean Max worker shutdown.
- [ ] Complete authenticated clock/device recovery and host fault qualification; qualify crash/restart, account/profile change, disk failures and lost-state behavior.
- [x] Document synthetic active/expired/renewed scenarios and term values as tests, not commercial policy.
- [x] Exercise policy allow/deny/continuity and distinct same-product Max wrappers; record limitations. Full E02 extension acceptance remains pending.
- [x] Select and compile a candidate verifier/profile; pass independent issuer, bounded parser/signature negative tests and a signed Max renewal fixture. See the second experiment's limited scope.
- [ ] Review the candidate and qualify production trust ownership, protected signer compatibility, real context and rotation/recovery. Do not ship lab keys or fake bridge inputs.
- [x] Record the first loop's actual evidence and incomplete qualification status.
- [ ] Confirm the smallest L2 service scope after L0's native boundary and L1's real verification contract are credible.

This packet implements no real checkout, customer migration or production enforcement. Those belong to later milestones with a concrete reviewed policy and tested candidate. Do not run a parallel provider-selection project or re-estimate the old vendor-based schedule.
