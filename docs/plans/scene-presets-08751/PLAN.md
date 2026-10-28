# Scene presets — 0.87.5.1

User-authorized scope: add a simple native scene preset to the existing Library,
retain portable recipes, keep artist text minimal, validate in an owned Max 2027
profile and deliver a matched Max 2027 MZP. The explicit requested patch label
0.87.5.1 supersedes the usual feature-minor recommendation. Preserve 0.87.5's
shared-pose viewport and independently versioned products.

## Contract and implementation boundary

- F01/F02/F11: save the selected Scatter setup and its node dependencies through
  Max serialization. Restore an independent editable setup, preserving ordered
  layers, Paint, preparation and the entire Edit stack. Preserve generated
  candidate variation; coordinate fresh owner/source/clone identities.
  Receiver slots/domains remain local to the independent new owner; retaining
  them preserves candidate variation and saved radius geometry proofs.
- F04/F08: browsing reads small metadata only. Saving must not Update pending
  Manual placements or change the original setup, materials, selection or file.
- F05/F07: serialize/read host state on the Max thread. File workers own copied
  descriptors and bytes, verify hashes, collect assets and atomically publish
  the shared catalog after every attachment is ready. Cancellation before that
  commit leaves the previous card intact. No host APIs on file workers.
- F06: bound nodes/reference traversal, attachment count/size, descriptor bytes
  and queued jobs; reuse existing store admission and content-addressed objects.
  File staging is owned, temporary and removed after completion/cancellation.
- F09/F10/F11: use Max's saved asset metadata to repath only a staged scene file.
  Preserve material/controller/plugin state. Missing files/plugins and unsupported
  units must fail clearly before publishing an incomplete setup.
- Undo: the user explicitly chose **standard merge with a short notice** after
  owned probes reproduced history clearing in MAXScript, the public SDK and
  object-XRef import. This overrides the proposed transactional-merge criterion
  for scene presets. Keep the portable transaction unchanged. Do not claim scene
  merge is Undoable or relabel an accepted hold as transactional qualification.

## Artist surface

One save-type selector: **Scene preset**, **Portable preset**, **Settings only**.
Scene presets save the complete setup and collected assets. Loading restores a
new setup in its saved arrangement. Terrain adaptation remains the portable
workflow. Reuse thumbnails, collections, search, sharing and revisions.

## Acceptance checklist

- [x] Native save, catalog/card and import with minimal UI.
- [x] Ordered layers, receivers, preparation, native Paint and authored Edit state.
- [x] Independent repeat imports, clones and radius history across Edit stacks.
- [x] Original setup/paths and pending Manual publication retained by Save.
- [x] Collected texture works with its original unavailable; archive transfer.
- [x] Standard merge notice; missing-payload/cancellation retention; portable unaffected.
- [x] Saved-unit admission and native metadata/path/file-count bounds.
- [x] Save/reopen; existing portable format-9 import unaffected.
- [x] Exact current-source Max 2027 build, owned host evidence and verified MZP.

Executed scope and outstanding limits are in [the delivery](DELIVERY_08751.md).
This does not qualify arbitrary third-party plugin graphs, other hosts, other
colour configurations, scene-wide animation or production renderer frames.
Original-file unavailability was exercised on an owned collected PNG; the
entire vendor texture tree was not removed. Interaction tests use one Edit;
two authored Edits plus radius/history were exercised with interactions off.

Official API references: [saveNodes and standard merge](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/File-Access/3ds-Max-Scene-Files-Access/GUID-624D3D05-B15D-4A97-9F15-DA35CDB0DDD2.html),
[saved asset metadata](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/File-Access/3ds-Max-Scene-Files-Access/GUID-2AF2AFE0-1B22-4DA2-B0F9-CA3ADABCB6C6.html).

Investigation and execution receipts: `build/scene-presets-08751-20261027-01/`.
Historical 0.87.5 and research receipts retain their original identities/scopes.
