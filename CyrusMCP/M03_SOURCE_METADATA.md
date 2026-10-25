# Native source measurements and real planting assets

24 October 2026. Internal M02/M03 foundation with a partial M04 workflow.
Max 2027 only. The complete milestones and operation matrix remain open.

## Contract and implementation

`scene_measure_objects` retains its default `receiver_and_bounds` purpose and
10,000-triangle / 12,000-vertex aggregate admission. Its explicit `source` purpose
accepts one to three locally shared static baked Editable Mesh nodes with native
source API 1, bounded together to 2,000,000 triangles / 1,000,000 vertices. It does
not evaluate receiving topology or report planting area. Other source classes
retain the former bounded path; proxies, modifier stacks and animated sources
are not silently converted or admitted.

The new native reader borrows the baked mesh on the host thread. It streams
every vertex and indexed face through fixed buffers, returns eleven scalar/small
array fields, and does not create a converted mesh, a triangle vector or Python
vertex/face arrays. It reports node-local bounds with object offsets retained,
world bounds, height, pivot XY/XYZ radii and separate SHA-256 geometry identities
under `cyrus.source-measurement/1.0`. Both native and adapter validate admission,
finite coordinates/transforms, invertibility, indices and output format. Runtime
enrollment and relevant source freshness reuse this native path. Receiver
inspection still uses its existing smaller geometry contract.

The local fingerprint uses the existing native asset-capture policy: exactly
equal node/object matrices cancel to identity. A moved node with no object offset
preserves the qualified local hash and changes the world hash. Nonzero offsets
remain measured, but general floating-point transform invariance is not claimed.
These geometry identities do not cover UVs, normals, material graphs, texture
files, imported unit provenance, proxy readiness or renderer compatibility.

Relevant contracts: F05 failure retention, F06 bounded work, F07 host access,
F10 physical units and F11 state/provenance. This adds a metadata API, not a new
placement engine. Existing cached `cyrusSourceGeometryInfo` / Auto Radius and
portable mesh codecs retain their separate semantics.

Source: `AminScatter/include/source_measurement.h`,
`AminScatter/src/source_measurement_bridge.inc`, its bridge inclusion and native
test; `cyrus_mcp/source_metadata.py`, `max_host.py`, `service.py`, `server.py`,
capability/help text and focused metadata/fingerprint tests. The source server
still exposes eighteen tools and seven resources. This is distinct from the
older installed client and frozen 0.86.9.2 delivery.

## Executed evidence

- `build/mcp-source-metadata-20261024-03/receipt.json`: clean Max 2027 SDK build,
  58 native tests pass in 24.36 s, including thirteen pure source-metadata checks.
  Input manifest SHA-256:
  `bed512c161c6ccc642f202a0118ab3cfe27aa212928dbac484fa76f5c5f489b8`.
  `AminScatter.dlx`:
  `511b196856851b69e17881df14d701907b7f28b77a0203f49dfb94163ecd6f55`.
- `build/mcp-source-use-20261024-01/offline-final.xml`: 469 Python tests pass,
  37.079 s. This supersedes its earlier two fake-fixture failures without erasing
  those receipts. Python/runtime bytes are frozen independently from native
  production.
- `build/mcp-source-use-20261024-02/host01/source-use-results.json`: owned PID
  41908, now closed. A 14,160-triangle / 7,082-vertex baked source rejects the
  default measurement budget and succeeds through `purpose=source`. A guard
  rejects any attempt to copy it through `Host.mesh`. Inspection preserves clean
  flag, objects, transforms, selection and Undo. A vertex edit changes its local
  hash; movement with zero object offset preserves local and changes world hash.
  Same-task design enrollment and SDK native creation publish 152 accepted rows
  from 160 candidates, with matching export. Artifact:
  `76e51af4bca29b3a5ff7b5d67af7f05af0f69b357d255edfa8d2b92831912dec`.
- Actual installed A069 grass and A062 flowers measure 4,360 / 17,110 triangles
  and 4,444 / 10,922 vertices. Physical bounding sizes are respectively
  0.145245835 × 0.144931316 × 0.049943503 m and
  0.280828670 × 0.272772744 × 0.097936034 m. Scoped catalog dimensions in cm,
  divided by 100, match these observations; this is not universal asset-unit
  validation or material qualification.
- `build/mcp-source-use-20261024-03/host01/planting-sources.json`: a real SDK
  task uses those two source objects, two native layers and a picked central
  convex flower patch. Native verification/export match 85 grass and 2 flower
  placements from candidate budgets 100 and 40. Artifact:
  `8fc8941fbe74a28069fc3ba3836ee3054fe01348d2da4c9275fa37f6e28129ca`.
  The strong flower shortfall illustrates the current whole-receiver candidate
  budget filtered by a smaller region. Counts are not exact regional targets or
  density. This behavior must be visible in M04 proposals and refinement.
- Run 03 `planting-refinement.json`: typed `configure_and_update` changes only
  the flower candidate budget 40→700. Flowers increase 2→19; all 85 grass rows
  remain exactly equal, both layer IDs and regional bindings remain unchanged,
  and the export matches 104 published rows. Artifact:
  `a206a059599b798cce42dc01a3a875cfb7a69aaeed0d171473f2fb9f4235ad76`.
- Run 03 `increment-receipt.json`: all 28 frozen runtime Python/JSON files match
  current source, and all five actually loaded native module hashes match the
  matched staged payload. PID 31072 is closed. Final identity artifact:
  `50a18b1ce8565b756ad46b6fead3832c9a879714863422af6805070096f21fee`.

The actual library merges above occurred only in disposable local fixture
preparation before scene sharing. They were not MCP import operations. Approvals
are scripted local test actions, not physical artist consent. Neither these
campaigns nor the source-only limits qualify sustained maximum-size latency,
renderer output, arbitrary sources, or a complete artist workflow.

## Import-history finding and implementation decision

The existing local `CyrusModelMerge` path is unsuitable for MCP's preservation
contract. In owned Max 2027 probes of A027 Standard, A069 grass and A062 flowers,
`getMAXFileObjectNames` clears earlier Undo history. Direct `mergeMAXFile` without
that header call also clears history. An explicit Undo block and the library's
hold label do not make the imported node disappear on Undo. A prior sentinel
move cannot subsequently be undone. Direct MAXScript cases reproduce this
outside pymxs, so a Python Undo-context change alone is not a solution.

Receipts: `host01/import-probe-A027.json`, `import-probe-A069.json`,
`import-probe-A062.json` and `merge-boundary-{library,raw,undo_block,raw_noheader,
undo_noheader}.txt` under run 02. The production template already acknowledges
incomplete merge rollback, but its manual deletion fallback does not restore
earlier history. No production importer repair is claimed here. Do not expose
header reading as a harmless artist-scene preflight or advertise approved `.max`
import as transactional.

Use the existing portable package/mesh/material pipeline for a qualified MCP use
path. Prepare supported installed assets outside the artist document, pin their
package hashes and finite renderer adapters, and create scene nodes through the
existing native authored transaction. The proposal must state asset revision,
source units/scale, destination, reuse versus new nodes, materials, resource
budget and Undo effects. Keep package preparation, approval and scene commit
separate; a new storage service or the independent shared-library redesign is
not required by this decision. Before enabling use, prove prior-history
preservation, Undo/Redo without package reread, failed-stage rollback, dependency
denial and stale/tampered admission using the actual supported materials.

### Actual portable staging proof

Run 03's existing native capture/export pipeline prepared those two plant assets
as one local portable package: two source nodes, twelve materials, 61 maps and
48 files. It did not create a new asset format or storage service. Private
content remains under ignored `build/`; it is not distributed or committed.

`build/mcp-portable-source-20261024-01/host01/portable-sources.json` records
separate host callbacks for preparation, an unrelated prior edit, staging,
Undo/Redo and a failed successor in owned Max 2027 PID 41024. The existing
`CyrusAssetStage` / prepared native mesh creation preserve the prior Undo entry.
One Undo removes only the two imported nodes; the next Undo restores the prior
sentinel move. Two Redos restore their exact vertex/index geometry fingerprints,
world bounds, node handles and observed Multi/Sub material classes. The native
preparation handle is released and the original package path is unavailable
throughout Undo/Redo. The fixture then restores that owned path, prepares again,
injects a failure after complete staging and verifies the original nodes,
geometry, material classes, sentinel and Undo history remain equal.

Campaign artifact:
`d1ed436f1f5ad66e637278ffe23f29081f0290942823ae2d0331c81c7421a002`.
Each callback retains its own bound artifact identity, including the deliberately
moved package. This is scoped native API evidence, not a public MCP asset-use
operation, complete recipe import, UV/material equivalence, renderer-output
qualification, dependency-denial test or artist approval. The staged source
geometry fingerprints match the measured original grass/flower meshes. Next
compose this existing engine into a typed, locally approved operation with
explicit asset revisions, destination and failure/Undo receipts.

Its `increment-receipt.json` verifies all 28 frozen runtime files against current
source and all five actually loaded native hashes against the staged payload.
The final identity uses the campaign artifact above. PID 41024 is closed, as
recorded in `closed.json`; all hosts used by this increment are closed. Artist
sessions were not used for these tests. Private drivers pass Python compilation,
and tracked diff whitespace checks pass (Git emits existing CRLF normalization
warnings). These checks add no renderer or artist acceptance.

## Preserved failures and open acceptance

Native build 01 failed on a missing test include. Build 02 passed offline tests
but its class-ID guard incorrectly rejected Max's Editable TriObject subclass;
build 03 accepts both baked SDK IDs and is the live-tested successor. Earlier
case-sensitive fixture checks and raw-debug errors remain in run 01 history.
Run 02 planting fixture attempts failed around nested MAXScript/Python execution
and an active test hold; the failing protocol/listener receipts are retained.
The fresh run 03 fixture executes locally on the Qt host thread under an
explicit Python Undo context. Product busy-state checks were not weakened.

The first portable combined-callback probes had private fixture errors: a node
passed where the recipe needs its base object, expecting `complete` instead of
the documented preparation `ready` state, and attempting to inspect nested Undo
history before the outer callback finished. Their scripts/results remain in run
03 history. The separate-callback campaign initially asserted oldest-first Undo
names, while Max reports newest first. Its original staged receipt is preserved
as `portable-sources-attempt01.json`; the corrected driver compares the live
state with that exact staged result and resumes without reimporting. These are
fixture corrections, not production engine fixes or extra feature passes.

M03 still requires presets, asset unit/dependency readiness and approved portable
asset/recipe use. M04 still requires a complete refinement/returning-task flow,
native task-panel interaction, HTML demonstration and artist acceptance. M09
cold restoration and broader M01 lifecycle gates remain open. No new release
label, artist installation/restart, commit/push or published package is claimed.
