# Cyrus licensing native foundation

These are development components for [licensing roadmap L0/L1](../docs/licensing/ROADMAP.md). The default target contains only pure policy. Optional Windows targets provide bounded ES256 verification, immutable grants/permits and real installation-key/DPAPI/clock handling. Private Max targets exercise native recipe/Edit/Brush ownership; ordinary product builds leave enforcement off. This is not a deployed customer licensing system. See [current evidence and limits](../docs/licensing/NATIVE_FOUNDATION_2026-10-05.md).

`decide()` accepts independently established authority, product rights, build eligibility, device match, capacity and time observations. It returns a permission and a reason. Authoring is denied by default; an authorized term uses the half-open UTC interval `[not_before, authoring_end)`. Inspection, preservation and recovery remain available. Rendering existing work requires separate state evidence; how the real host establishes that evidence remains an open L0 boundary.

The pure `decide()` implementation performs no allocation, network request, clock read, storage access, signature verification or Max call. Connectivity is absent from its inputs: a service outage cannot by itself invalidate otherwise valid authority. The caller supplies a new immutable-by-convention facts value for renewal; no mutable global license status exists in the policy core.

## Build and test

Use an x64 C++17 compiler in a configured shell:

```powershell
cmake -S CyrusLicensing -B build/licensing-policy -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release
cmake --build build/licensing-policy
ctest --test-dir build/licensing-policy --output-on-failure
```

Six test groups cover default denial, lifecycle, continuity, combinations of independent facts, deadline boundaries and configurable policy values. The separate [Max lab](../tools/licensing_lab/README.md) checks several actual host operations and exposes bypasses that a script wrapper cannot prevent.

## Optional signature experiment

`CYRUS_BUILD_TOKEN_PROTOTYPE=ON` adds `cyrus_license_token` on Windows. It uses Windows CNG for P-256/SHA-256, Windows Crypt32 for base64 conversion and the pinned MIT-licensed nlohmann/json header for JSON syntax. Application code enforces the [bounded signed profile](../docs/licensing/SIGNED_TOKEN_PROFILE.md). See the [component selection and notices](../docs/licensing/IMPLEMENTATION_COMPONENTS.md).

`verifyLicense()` verifies exact signed bytes and claims. `LicenseSession::install()` additionally matches the trusted application context; a rejected import preserves the previous grant. Decisions acquire immutable claims without repeating signature verification. Importing an authentic expired token reports `verified`, while the subsequent authoring decision reports `expired`. Optional targets require C++20 for atomic shared snapshot publication. Native-local move-only permits are session/owner/operation-bound, single-use and capped at 30 seconds or the signed expiry, whichever is earlier. Renewal cannot extend an in-flight permit.

`cyrus_license_local` adds per-user CNG P-256 installation proof, bounded DPAPI transactions and calendar/monotonic observations. `LocalLicenseClient` verifies separate fresh-nonce activation responses before trusting an initial time anchor. Renewal and refresh never accept account/device context from a token. Disk/key work serializes separately from short in-memory decisions. The private Max adapter's worker performs periodic refresh/checkpoint and is explicitly joined before DLL unload; it never accesses Max nodes/UI from its thread. OS I/O failure/recovery and customer lifecycle still require release qualification.

Only the explicitly enabled lab targets compile an ephemeral test issuer's public key. The reusable library has no embedded issuer keys. The [lab reproduction](../tools/licensing_lab/README.md#signed-license-experiment) generates signatures with Python cryptography/OpenSSL and verifies them with CNG; the private test key is never exported. A production trust configuration, protected signer and rotation/recovery remain separate work.

## Trust boundary

`Authority::Verified`, `ClockObservation::trusted`, `capacity_reserved` and `StateEvidence::ApprovedExistingState` are **inputs, not proofs** to the pure policy. Do not deserialize arbitrary customer input into these structures or publish this function as a production MAXScript unlock command. The original synthetic lab bridge deliberately does so for testing and must never ship. The signed session establishes signature/claim validity, but its laboratory account/device context, time and scene evidence remain synthetic; it trusts the issuer's seat-reservation assertion without implementing a database.

The current API/profile is a development boundary, not a stable ABI or production protocol. Complete operation coverage, recovery policy, release identity, service issuance and deployment remain unfinished. Software keys are not physical hardware attestation; offline rollback resistance is best effort, including whole-backup replay. Unknown operations deny and the signed profile rejects unknown rights/semantics. The private experiment gates selected real mutation paths; ordinary product primitives remain unlicensed until the complete continuity/enforcement contract is implemented.
