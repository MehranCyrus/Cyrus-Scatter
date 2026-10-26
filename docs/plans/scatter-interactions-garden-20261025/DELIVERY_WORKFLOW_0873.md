# Source workflow and contact repair — 0.87.3

26 October 2026. **Scoped Max 2027 trial delivery**, native Interactions 5,
saved schema 61. The user requested the same product version. Previous 0.87.3
packages and their qualification remain unchanged. [Artist workflow](ARTIST_WORKFLOW_0873.md),
[machine-readable qualification](QUALIFICATION_WORKFLOW_0873.json),
[ownership and acceptance](WORKFLOW_REPAIR_0873.md).

## What caused the two errors

**Missing custom collider.** A sphere needs only its original closed mesh. The old
workflow allowed an incomplete separate-mesh mode, and picking the visual source
itself did not satisfy that mode. The revised UI starts with the existing source,
maps a self-pick back to Original closed mesh, and validates custom assignments
before changing the working configuration. Cancelling a pick changes nothing.
An open custom mesh is rejected while retaining the previous valid collider.

**IterationBudget.** In the reproduced case, a leaf attachment inflated a short
guide span's isotropic collision envelope to about **26.36 mm**. That conservative
envelope could not fit beside the sphere with its root fixed, even though the
actual bound geometry had a valid arrangement. Increasing iterations or changing
scene units was not the appropriate repair. The fallback now evaluates the full
delivered stem/foliage geometry, with fixed anchors and the original clearance,
before accepting a bounded hinge candidate. Unresolved cases still fail and retain
the complete previous publication. It does not shrink the sphere or hide failures.

The supplied file uses **1 cm per world unit**, a 17.985 cm radius sphere and a
22,032-vertex / 27,501-triangle grass source. It predates the screenshots: it saves
one grass placement, no accepted definition and old trunk assignments. The test
reconstructs 50 grass placements and reproduces the **same failure class**, not
the screenshot's exact guide 50 or 210. This case did not need a lower-poly plant.

## Workflow changes

- One **Layer role** control: Off, Collider, React to colliders.
- **Analyze source model** and **Show source guides** operate at the original
  source. Accepted local definitions are reused by its transformed instances.
  Hidden sources get transient review copies; their visibility is preserved.
- **Accept guides and enable** activates a prepared reacting layer automatically.
  Unprepared sources remain ordinary scatter with an explicit pending status.
- **Show collider** and **Show source guides** are on/off toggles. Collider review
  uses a fresh, frozen geometry overlay without borrowed render/picking caches.
- Contact settings update automatically. **Retry contact update** and the full
  mesh audit are Advanced diagnostics. Manual Amount edits still wait for Update.
- Blade preview is **1–100%** in the primary panel and reuses accepted inference.
  Retained covered roots are reported when Hide roots is off.
- Derived native references/render nodes do not enter authored Undo. Contact-gap
  and individual collider Undo/Redo now round-trip. Save cleanup also visits
  non-node layer objects, removing their review helpers before serialization.

## Package and saved trial

- [Max 2027 MZP](../../../dist/CyrusScatter-0.87.3-20261026-workflow-r2/CyrusScatter-0.87.3-Max2027.mzp)
- [Prepared close-up trial](../../../dist/CyrusScatter-0.87.3-20261026-workflow-r2/Trials/New_Plants_Interaction_Workflow_0.87.3.max)

Run the MZP through **Scripting > Run Script**, then restart Max before opening
the trial. This is a matched native/script update; copying only the script is
insufficient. No EXE or older-host package is part of this delivery. The trial
has 50 grass placements, full blade preview, a nearby sphere using Original
closed mesh, Live mode and reviewed shared guides. Use Cyrus Edit to move the
scattered sphere; use Frame source to inspect the original plant.

Archive SHA-256: `142e4fd53f5efcbaccc2a7194439a84f6dfbfe630a684c71f8bd31c7106f53af`.
Trial SHA-256: `2cd7a109fe54c161392d3f3ce1366f01568dad7cb3aae51e717f78c85ab364f8`.
The original `Test Scene/New Plants test.max` retains SHA-256
`62af55f1b9f8c826aa0b07261e11b706e71aaa6cc2ffa87b5e1a7e9d41c75399`.

## Executed evidence

Final producer: `build/interactions0873-workflow-20261026-01/native-06`.
Final owned host: `host-06`, loading modules extracted from the delivered MZP.
Archive CRC, every manifest payload hash, host/version guards, generated script
identity and loaded-module hashes were verified. No artist installation occurred.

| Check | Observed result |
| --- | --- |
| Max 2027 SDK build and native CTest | **59/59** pass |
| Generator/layout/semantic consistency | Pass; 361 controls |
| Numeric sphere replay on captured source | Before 23/24; after **24/24** |
| Mounted generated control/shared-handler checks | **37 assertions** pass, including source position, toggles, pending preparation, 1/25/100%, custom/self-pick logic and Manual pending edits |
| Multi-source, failure retention, save/reopen | **9 assertions** pass |
| Four separately authored Cyrus Edit moves | Four correct target positions and four independent full-visible-mesh audits pass |
| Undo/Redo | Contact gap and individual collider restore both directions |
| Physical viewport input | A packaged-build axis drag changed collider Z from 28 to 81.0809 cm with no contact error; no held-pointer FPS claim |
| Final close-up trial | Saved/reopened with definitions, 100% preview and complete contacts |

The four recorded command durations are about **0.20–0.32 seconds**, including
host update and redraw requests; they are not presented FPS. Consult
[contacts.json](evidence-workflow-0873/contacts.json) for numeric fit timings and
affected-instance counts. Full-mesh audits use complete visible triangles in
double precision. The close-up trial checks 40,409 nearby visible triangles, with
zero penetrating vertex pairs, zero touching triangle pairs and zero root drift.
Its maximum measured stem edge change is about **17.1%**; natural appearance still
needs artist judgement. Renderer float delivery is a separate qualification.

## Failure history and remaining acceptance

Early candidates exposed a native collider-overlay crash and Undo/Redo pollution.
The overlay now owns fresh display geometry; transient native references and
output changes suspend Undo. Later overlay repetition and final Undo/Redo tests
pass. Those scoped passes are not a long-session crash guarantee. Candidate 05
also exposed leaf-owned review helpers surviving save; the final recursive cleanup
passes save/reopen. The superseded save failure is retained in the evidence folder.

Removing a source and immediately deleting its scene node **before updating the
retained placement result** can still produce a deleted-object error. The tested
sequence removes the source, updates Scatter, then deletes the node. This separate
publication-lifetime edge case remains open; it is not silently marked fixed.

The exact fallback admits at most 50k vertices / 100k triangles for one guide and
2M geometry work units per plant fit. Shared correspondence arrays are included in
source accounting; temporary points add at most about 1.15 MiB per fitting worker,
plus bounded guide candidates. These are payload bounds, not measured process peak
memory. Larger contact workloads, other topology families, renderer-specific
materials/float output, prolonged dragging and long-session stability remain open.
The isolated standard-plugin profile does not qualify original Corona/Forest
materials. Exposed-root collider generation remains on hold.

Navigation and artist docs were updated; the knowledge index was not rebuilt and
its older retrieved evidence must not substitute for the current originals. No
Git push, website publish, EXE or unrelated product change is included.
