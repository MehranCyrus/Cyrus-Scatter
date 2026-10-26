# Shared library 0.87.1 — implementation and qualification

**26 October final successor:** [Delivered for artist testing](DELIVERY_0871.md)
with the [exact qualification manifest](QUALIFICATION_0871.json). The dated
in-progress notes below preserve the investigation; they are not the current
delivery status.

25 October 2026. **In progress.** The user authorizes implementation of the
shared-library plan, new-model/recipe tests in separate scenes, full affected
testing, a 0.87.1 delivery with Max 2024/2026/2027 payloads and EXE, documentation
updates and knowledge-base refresh. This supersedes the earlier coding/test
deferral. No artist installation, session restart or Git publication is requested.

Baseline: `codex/workflow-0.75`, HEAD
`588abff0ce211d7dc63798b8c5310631895465c7`, with existing 0.87.0 Interactions,
MCP and unrelated product changes. Owned baseline/status and initial file hashes
are in `build/shared-library-0871-20261025/baseline.json` and
`baseline-status.txt`. Preserve the original artist scenes/profiles and all
unrelated changes. Use owned profiles for each authorized host.

## Implementation decisions

- Keep the current native typed capture and package validators. Add a data-only
  native verification inlet for the managed file worker; it must never touch Max.
- Extract immutable byte/link primitives into `shared/ContentObjects.cs`, used by
  installer and personal library. One `content.lock` coordinates publication.
- Keep recipe 8's authored payload and current finite shader adapters. A shared
  catalog pins immutable recipe/asset revisions. Complete catalog generations
  publish through one atomic pointer; bounded hard-link views let existing
  independent native readers consume the same model without a second parser.
- Add graph 4 for Standard-material static meshes using the existing `CYRUSM02`
  encoding and plant mesh admission. Renderer graph 3 keeps its explicit host/
  adapter restrictions. New shared captures use one geometry representation
  independently of the material; old explicit package exporters keep their
  qualified formats.
- Shared package references resolve only within their owning marked store.
  Texture paths use stable `resolved` links. Existing external package caches and
  saved-scene paths remain available; migration is explicit.
- First delivery retains the plan's static-planting scope and explicit rejection
  of unsupported Interactions/Edit/radius authoring. It must never drop those
  fields to label a recipe complete.

## Evidence so far

- Initial Max 2027 SDK development build compiled; **59/59 native tests pass**
  (26.63 seconds), under `native-dev`. This is intermediate source evidence,
  not final package qualification. The generated script/managed integration
  is still being implemented.
- First managed transaction campaign correctly rejected its model-catalog
  assertion because automatic model registration used a generic source-purpose
  name instead of the actual `sources`/`procSourceNodes` contract. The failed
  receipt is retained in `managed-tests-01`; correction and successor pending.
- No new host test or installer qualification is claimed yet. Final receipts
  will pin exact payloads after implementation stabilizes.

## Remaining work

Complete and verify model/recipe UI integration, snapshot views, shared save/
metadata publication, collection transport, migration/storage management,
native import Undo preservation, current reader/lease regressions, ten-look
physical-allocation tests and new-model cross-scene host workflows. Build and
qualify all three matched SDK/managed payloads and installers, update maintained
documentation and publish/verify a reviewed knowledge successor. Track actual
failures and limits rather than treating this checklist as executed evidence.

## 26 October implementation continuation (still under qualification)

The original view-folder adapter was measured to create 444 compatibility files
for eleven recipes. It was replaced with a direct native reader of the immutable
catalog head and verified recipe paths. Independent MCP catalog owners retain
their own bounded scans; no generation of per-existing-recipe view folders occurs.

The managed store now includes atomic complete save/metadata updates, hash-based
model/image/mesh reuse, collection transport, conflict-copy recipe import,
legacy recipe migration, same-volume consolidation with per-file recovery
journals, retained relocation, scene-copy relink, prior-catalog restoration,
explicit backup repair/quarantine, usage and abandoned-stage recovery. Native
validation is data-only, bounded and cancellable; its DLL is process-pinned and
shutdown retires validation before native library teardown. SDK creation stays in
one host-thread transaction.

Selected-model exports were audited separately. The initial implementation
referenced the source recipe package and would export unrelated sources. That
intermediate design is superseded: `SharedLibrary.Models.cs` builds one normalized
model graph and stores mesh/material/map definitions independently by hash.
`models/<revision>` contains only that model's dependency views and a closed
`cyrus.model-package/1` manifest. Complete recipes retain their original source
bindings/context. Model graphs preserve distinct-versus-instanced shader
occurrences while sharing immutable definition bytes. Model-only saves do not
publish a hidden receiver/recipe package. Catalog `modelRevisions` are immutable
pins; model-card pointers and collection memberships are separate metadata.

Graph 4's Standard bitmap interpretation now carries explicit input/effective
gamma. Shared PNG (including the existing bounded 16-bit path) and JPEG capture
use their typed native preflight and bounded host decoder. Renderer graph 3 keeps
its exact adapter requirements. Native model preparation reads the new one-source
package rather than preparing all the sources of its original scene.

Intermediate observations (not final installer qualification):

- `native-dev04`: 59/59 native tests, including direct shared catalog checks.
- `candidate-01-max2024`, `-max2026`, `-max2027`: 59/59 each. These precede the
  independent gamma/model-package refinements and are not final payloads.
- `native-dev05`: 59/59 including shared gamma schema checks.
- `managed-tests-21`: 244 file-transaction checks pass, using an explicitly
  injected fixture boundary instead of claiming real native mesh validation.
  The campaign kills owned helper processes after promotion/before catalog commit
  and after catalog commit/before a completion receipt, verifies restart/retry,
  archive integrity/reuse, single-model dependency isolation, migration,
  consolidation, repair/quarantine, relocation and history.
- `host-workflow-08`: Max 2027's earlier 88-check ten-look workflow passes. Three
  imported models (tree above 100k vertices), six textures and one receiver share
  four mesh allocations and six image allocations. Ten independently loaded
  recipient scenes and a reopened scene work after original inputs/archive are
  unavailable. This precedes the latest model-package changes.
- `host-extended-04`: earlier 41-check Max 2027 model/Undo/variant/browser/relink
  campaign passes. The personal native route preserves prior meaningful Undo,
  Undo/Redo and rollback after injected staging failure. Repeated equal-font
  assignment caused disposed-font red-cross painting in simulated scale captures;
  the corrected equal-font no-op passed the successor captures.
- Full Python regression `pytest-02.log`: 573 passed after fixing strict standalone
  installer compilation and the MCP development-version entry.
- Generated-source check `generated-02`: passes; this is not a Max compilation.

Failed owned runs and snapshots remain in the campaign directory. Early host
runs exposed script declaration/path/admission issues and test-driver .NET-array
and startup-hold issues. The driver now closes only its own startup hold; disabling
Undo would also disable the transaction being tested. The newest JPEG fixture
attempt correctly rejected saving an input-open bitmap; its replacement uses an
owned writable bitmap. `native-dev06-compiler-failure-01.log` preserves the
C++20 JSON comparison compile error. `native-dev06-fixture-failure-01.log`
preserves a fixture that assumed a material in an untextured baseline graph;
its correction is under rerun. No such failed run is qualification.

Remaining: complete the current native/model host successors, exact setting and
render/gamma checks, add-to-layer and owner/reset failures, matched three-host
final builds and runtime/installer tests, package integrity/EXE checks, maintained
docs and a reviewed knowledge successor. Original scenes/profiles and unrelated
changes remain preserved. No artist installation, restart, Git commit or push.


## Final static delivery — 26 October 2026

Final producers are `build/sl871-final03/max2024`, `max2026` and `max2027`; all 59 native tests pass per SDK. Package work is `build/sl871-package03`; the final EXE and three MZPs are under `dist/CyrusScatter-0.87.1-20261026`. Earlier candidate-01 and candidate-02 folders are retained and superseded. Final loaded module paths/hashes and generated fingerprints match the package payloads.

Every host passes 126 ten-look and 67 model/revision/Undo/ownership/relocation/relink checks. Final actual native migration passes 14 checks; the exact Max 2027 Corona profile passes 18, including independent model packages, canonical re-save, complete recipe sharing and an actual two-pass render. The exact EXE passes 58 owned installation/repair/cancellation/retry checks; each host also starts automatically from its owned installed release and passes the ten-look workflow. Managed file transactions pass 244 checks with their fixture/native boundary stated; Python regression passes 573. Generated source verification passes. No artist profile or running artist session is modified.

The campaign exposed and corrected two additional issues: destination-unit float rounding created duplicate encoded meshes on unchanged re-save, and canonical numeric JSON spelling caused a false renderer readback failure. Reuse now requires hash verification and exact native SDK-representation equality, never provenance alone. Shader readback compares the exact typed decoded SDK value, retaining native field validation and introducing no epsilon. The new reuse hint also rejects nonlocal/reparse/overlong paths before reading.

Max 2024's owned legacy Gamma startup is deliberately rejected by the pre-existing portable texture contract. Explicit supported OCIO selection after each test scene reset is recorded in its launch receipts; no silent colour conversion or artist preference edit is introduced. An older Max 2024 PyMXS high-bit lease roundtrip was a test-driver marshalling issue: the harness now keeps the true Integer64 lease in MAXScript, as the scripted consumer does. Original failed runs remain.

SL01–SL09 are implemented for supported static planting. The wider original T/A matrix is not blanket-certified: complete Interactions serialization, arbitrary proxies/shaders/scenes, all renderer/variation/Paint combinations, physical DPI, power loss and long-soak remain separate acceptance. Exact limits, installer instructions and knowledge routing are maintained in the delivery/artist guide. Knowledge publication and actual consumer verification are recorded independently in `tools/rag/CURRENT_REFRESH_0871_20261026.md`. No commit/push, artist installation/restart or website publication was requested.
