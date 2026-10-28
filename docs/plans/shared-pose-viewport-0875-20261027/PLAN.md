# CyrusScatter 0.87.5 — shared pose viewport

User-authorized 27 October2026: integrate the standalone concept into CyrusScatter,
use real models, keep the workflow simple, improve demonstrated weak code and deliver
0.87.5 for testing. Max2027 development/qualification only. No other-host builds,
artist-profile installation, Git push or unrelated library rewrite is authorized.

## Baseline and version

README's scoped interaction baseline is0.87.4.3 (native11/schema63). The working
tree also contains0.87.4.4 recipe9/Edit3 work; preserve it. Branch
`codex/workflow-0.75`, HEAD`d24b880816ab367874f417f79d1253aafa9a60f5`.
Extensive preexisting modifications are recorded under the owned build run.
The other observed project chat is idle/read-only. No messages were sent to it.
Knowledge generation637cdc… is stale (41/64 sources); use current original source.

0.87.5 is the user's selected feature version. New compact-pose graphics behavior
and matched native/script requirements justify the feature step. Keep existing
scene schema63, prepared intent/envelope and independent product versions unless
an actual persistent-format change proves necessary; transient GPU data is not saved.

## Chosen scope and contracts

Preserve existing source preparation, authored repairs, exact collider mesh queries,
local neighborhood selection, fixed-root behavior and CPU render/export geometry.
The first concrete improvement is viewport delivery: replace expanded posed-triangle
batches for Mesh/Textured mesh with shared source bindings plus per-instance poses.
Reuse the original shader material/opacity data and identification controls. Keep
Point Cloud/proxy behavior and pending Manual placements independent.

F04/F08: camera, browsing, F3 and unrelated animation reuse placements, preparation
and source/pose buffers. F05–F07: copied numerical data, finite resource admission,
generation-owned leases, atomic publication and prior-result retention on failure.
F09/F10: source fingerprint/corner correspondence, metric/core-to-host conversion,
positive uniform transforms, exact fixed/anchor/follower/stem behavior. F11: derived
GPU buffers are rebuildable; Undo/save/load refer to original CPU/authored identities.

## Data, ownership and failure design

- Prepare immutable GPU bindings once per unique source/settings/preview definition.
  Each corner records rest position, source-local binding, node references and
  whole-face visibility roots. Preserve source face/UV order and duplicate corners.
- Pack positions/frames for nearby posed plants. Unchanged source guides retain rest
  data and flags; fixed anchors and rigid followers use the existing CPU semantics.
  CPU poses remain canonical for collision validation, renderer/Bake and recovery.
- The host builds complete numerical successors. Nitrous owns public graphics handles;
  draw/realize uses no Max scene evaluation or scripting. Reuse immutable source
  buffers; create generation-owned changed-pose streams rather than overwrite data
  that older publications may still read.
- Charge source bindings, active poses, staging, device/system buffers and old/new
  overlap separately. Record payload accounting limits; do not label it total VRAM.
  Float indices must remain exactly representable. Exhaustion retains the previous
  complete result and reports the actual cause.
- First prove documented HLSL buffer lookup through public handles in an owned Max
  host. A public float-texture alternative is permissible if the exact buffer path
  fails. Do not cast internal graphics pointers or add CUDA to this delivery.

## Acceptance checklist

- [x] Native reference tests and three real-model HLSL readbacks cover source position
  and visibility equivalence, including anchors, followers and fixed geometry. Basal
  frame smoothing follows the canonical CPU formula; no separate coverage count was logged.
- [x] Public buffer proof and 200/1,000-instance traces exercise source sharing and poses.
- [x] Grass, large fern and authored broad-leaf/fixed-base sources pass scoped natural
  contact and complete visible-mesh audits in owned Max2027 profiles.
- [x] Final-package Cyrus Edit pointer dragging publishes multiple updates per gesture.
- [x] Mesh/Textured mesh F3, split wire/shaded views, per-source ownership and unchanged
  camera activity pass. Production renderer/material-graph qualification remains separate.
- [x] CPU full-visible audits, GPU math correspondence and CPU Bake triangle-count
  comparison pass; no production-renderer frame was claimed.
- [x] Undo/Redo, save/reopen, source/preparation switching, invalid-setting retention
  and Manual pending amount changes pass. Arbitrary vertex-edit scenarios remain broader work.
- [x] Paired producer traces record callback, kernel, redraw, event waits and SDK logical
  upload bytes separately; none is labelled presented FPS or physical PCIe traffic.
- [x] 61 native tests, generated/catalog checks and source/package/installed-host identity
  checks pass; the matching Max2027 MZP and preserved-scene copies are delivered.
- [x] Maintained navigation, architecture, artist instructions and dated scope are updated.

Final evidence: [delivery](DELIVERY_0875.md) and [qualification](QUALIFICATION_0875.json).
Dense/deep stress retains the CPU solver's guide-strain warnings. Integration and
natural-model acceptance do not close that visual-quality limitation or general FPS,
renderer, arbitrary-topology, older-host or GPU-compute acceptance.

The standalone geometric sphere fitter is evidence for architecture, not a drop-in
replacement for the existing arbitrary-mesh contact solver. Improve preparation or
fitting only where real-model measurements expose a cause; do not sacrifice contact
correctness for a convincing preview or expand into unrelated roadmap work.
