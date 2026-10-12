# Offline team licensing — 0.79 implementation

Date: 11 October 2026. Branch at start: `codex/workflow-0.75`, HEAD `46374194c5dba42d643425e3810390b8ddb3f903`. This is a working team-pilot implementation, not commercial security certification. The earlier version-only edit did not implement licensing; the code and evidence below are the subsequent coding loop.

## Delivered behavior

- Persistent owner-only issuer, encrypted backup/recovery and SQLite issuance ledger. ES256 / P-256 signatures are produced by Python cryptography; Windows CNG verifies them in Max. No homemade signature algorithm or embedded signing secret.
- Exactly 2,592,000 seconds from owner issuance to expiry. Importing/reimporting a file cannot restart its term. Same-request issuance is idempotent; renewal requires a fresh request.
- Per-Windows-user CNG installation proof, DPAPI-protected client state, atomic writes, UTC high-water observations and monotonic elapsed-time checks. Software binding and offline time remain best effort against a hostile local administrator.
- Activation request/import/status UI, available without an existing scatter; 60-second background refresh shares activation between Max processes. Decisions in supported authoring paths use the in-memory session. No network calls, signature verification or license-file reads in placement/draw loops.
- Generated UI/model mutation guards, scalar parameter guards, native Brush/Edit/source-transform/container gates and early MCP rejection. Denial precedes supported mutation/cleanup paths. Loading and Undo restoration retain their host lifecycle; saved-state evaluation remains available.
- Matching Max 2026/2027 owner-trusted development installers. Artist profiles and `Test Scene/` were not installed into or changed.

The owner private key is outside the repository at `%USERPROFILE%\.CyrusScatter\LicenseIssuer`. Public key ID: `cyrus-team-a1b79a717a834e459d454a7768ffe205`. The public verification header is `CyrusLicensing/team/team_public_key.h`. [Operator instructions](../../tools/licensing/README.md) cover request/issue/import/renewal/backup.

## Actual tests

| Check | Evidence and result |
| --- | --- |
| Native compilation and suites | Both SDKs, Release MSVC 14.38 / Windows SDK 10.0.19041; 24/24 native suites per final test and owner build |
| Generated code | Reproducibility/integration passed; 241 semantic controls; script SHA-256 `7fe77af17f1d3095757910e9333a40a1e37aacc3142591471adcc4b4512a522d` |
| Python | Final complete MCP/tools run: **158 passed**; issuer/packaging subset: 12 passed including encrypted recovery |
| Max 2026 and 2027 test authorities | Loaded native paths/hashes verified; missing, expired, wrong-device and invalid-signature rejection; valid import; procedural creation/update; vector Fill; generated activation button |
| Real elapsed expiry | Separate test-only 90-second signed term, no fake host clock; while Max remained open, scalar edits, layer creation, explicit Update, native Fill and Dab denied with prior work preserved |
| Scene continuity | Expired viewport evaluation, save/reopen with caches absent, stable placement fingerprint, Scanline render before/after/reopen |
| Image comparison | Each host's expired and reopened 128×128 renders were pixel-identical to its own active render; images had 1,000 colors in 2026 and 963 in 2027, not blank-frame equality |
| Delayed import / renewal | Grant issued one day earlier imported with its original deadline; authoring resumed on the same layer; rejected replacement retained current valid authority |
| Actual owner authority | Final exact owner builds: saved-scene continuity, persisted authority, real generator issuance, repeated import, fixed 30-day expiry and shared renewal. The prior owner pair separately verified missing-license rendering and first activation in a second already-open Max; both receipts are retained |
| Issuer backup | Encrypted PKCS8 restores the same public authority; wrong password, weak passphrase and overwrite attempts rejected |

[Evidence ledger](EVIDENCE_0.79_2026-10-11.json) records final artifact hashes and receipts. Local full evidence is in `build/licensing-079-20261011/` and `build/mcp-qualification/licensing079-*`. The early `run01`/`a01` results are development probes, including hot-reloaded script troubleshooting; they are not the final matched pairs. Final candidates use `max2026/2027-test05` and `max2026/2027-owner05`. Test authority keys differ from the owner and are never packaged as owner deliverables.

## Bugs found by the host tests

MAXScript exceptions in a scripted parameter setter did not prevent Max from storing the new value. Existing legacy `set` handlers also suppressed `preSet`. The generator now returns the previous value from denied `preSet` and moves existing invalidation into `postSet`; real scalar assignment tests verify the result. Autodesk documents the return-value behavior in its [scripted plug-in parameter handlers](https://help.autodesk.com/cloudhelp/2020/ENU/3DSMax-MAXScript/files/GUID-461915FA-31A2-49CE-84AF-2544B782ACA3.htm).

An `on create` exception did not stop raw scripted-class construction. User-facing creation and usable layer creation are guarded, while empty host shells/class instantiation remain possible for loading. We do not claim otherwise.

Delayed license-file exchange needed a separate import policy: the old fresh activation-response exchange correctly rejected old timestamps. The team import verifies fixed signed expiry using local observations without pretending an old signature proves current UTC. A first import in another Max process now establishes the initial local anchor, while existing latched clock anomalies are not reset by refresh.

## Explicit limits and next acceptance

This pilot protects the ordinary team workflow. **It is not full native recipe ownership.** Arbitrary MAXScript table mutation, replacing generated scripts, invoking shared evaluation primitives and patching native binaries are outside its protection. Rendering must evaluate saved recipes, so `cyrusEvaluateProcedural` deliberately remains available; do not represent it as a security boundary. Direct scalar guards and native Brush/Edit checks do not close all script bypasses.

External source/receiver/animation changes can affect an expired scene's evaluated result. We preserve existing scene data and tested rendering, not a cryptographically frozen external dependency world. Renderer farms, PFlow/bake/export, arbitrary dependency changes, live physical painting across expiry, CS Edit/container gestures across expiry, sleep/resume and OS-reinstall recovery are not newly certified by these fixtures. Foundational synthetic-clock/permit tests are separate from those real host workflows.

The final team Brush adapter checks authorization at stroke start, each authored sample and the synchronous publication boundary. This removes the older experiment's 30-second gesture cap. Both hosts committed a staged stroke after 32 real seconds under active authority, then rejected/cancelled a separate staged stroke after real license expiry while retaining completed contours. A newly valid renewal can authorize a fresh commit; no old operation permit is extended. The separate laboratory permit contract is unchanged. Physical tablet/mouse interaction remains an artist acceptance check.

There is no immediate offline revocation, hardware attestation, floating concurrency pool, commerce backend, code signing, antivirus qualification or automatic key rotation. Copying a whole Windows profile/backup and manipulating time can defeat best-effort local observations. One copied license on another installation is rejected, but a malicious administrator controlling the binary is outside the pilot threat model.

Next: owner encrypted backup, install one qualified package in an explicitly chosen team environment, test ordinary artist workflows and renderer/dependency cases, then extend native recipe ownership only if stronger anti-bypass enforcement is required. Keep service/studio licensing and independent security review as separate milestones. Do not call 0.79 commercial release-ready or silently install it into the artist profile.
