# Terraces landscape and performance campaign

User-authorized scope: build an art-directed landscape on an owned copy of
`Test Scene/Terraces_Final.max`, using the real plant library and supplied
`Rock_Boulder_10/Rock_10.max`; fix Point/Bands labels and panel-opening hitches;
measure and improve interactions and navigation without losing the endorsed
0.87.5.6 artistic Bend/Trim response.

Starting delivery: 0.87.6, repository HEAD
`75c60d54dbfd736ffef135d211863516a63543a7`. The installer-r2 Max 2027 MZP is the
baseline payload. Other agents' changes, original scenes and artist profiles
are outside this campaign. Development and qualification use Max 2027 only.

User-selected successor: **0.87.6.1** (overrides the initial proposed 0.87.7).
This combines UI/performance fixes and the landscape campaign, without an
intended scene-schema or independent-product bump. Deliver matched payloads
for **Max 2024, 2026 and 2027 in one EXE**, plus the Max 2027 MZP. Development,
landscape and performance validation remain Max 2027; older hosts receive
distinct SDK builds and packaging verification. No artist installation or live
website deployment. The initial build folder's `0877` is only a run label.

## Design

Preserve the house, stepped landform, lake and walking route. Use trees to frame
views rather than hide the architecture, drifts of meadow grass and flowers
along selected terraces, quieter open areas between them, and detailed boulder
and waterside planting for close views. Create overview, house and lake cameras.
Keep high-density stress variants separate from the comfortable artist scene.

## Checklist and evidence

- [x] Verify baseline payload, original scene hashes and owned Max profile.
- [x] Inventory terrain, dimensions, materials, cameras and available models.
- [x] Capture empty-scene views/inventory. Empty-scene FPS was not qualified;
      final navigation comparisons use three budgets on the same planted scene.
- [x] Reproduce and fix Point/Bands label staleness through the real UI handler.
- [x] Measure warm rollout binding/layout and reuse unchanged mounted views.
      Cold/physical flicker remains outside the measured improvement claim.
- [x] Establish the real-asset landscape and save checkpoints.
- [x] Fixed base / zero Bend: skip only work that cannot affect the result;
      preserve independent Trim and root hiding.
- [x] Guide eligibility gate and moving-parent regression. Finer spatial hierarchy
      remains a follow-up, not an implemented change.
- [x] Compare collider representations; box proxy showed no speed gain. Preserve
      explicit custom shapes for openings rather than automatic convex filling.
- [x] Distant vegetation: verify accepted populations and local work separately.
- [x] Record drag slow percentiles and held-input presentation for scene/Edit;
      test two colliders and Scale after Edit. All-allocation/long-soak work remains.
- [x] Navigation: prove unchanged placement/contact and upload counters.
- [x] Compare dense scenes at three practical display budgets.
- [x] Keep measured improvements and record rejected shortcuts and limits.
- [x] Save the designed scene, four cameras and benchmark/limitations report.
- [x] Qualify the final Max 2027 pair; package separate 2024/2026/2027 MZPs in EXE.

## Boundaries

Relevant contracts: F01/F03 layer and collision ownership; F04 Manual/Live;
F05 atomic publication; F06 bounded memory; F07 workers use copied host data;
F08 unchanged presentation reuse; F09/F10 geometry, units and persistence.
UI fixes bind the existing authored model and do not cause placement rebuilds.
Native optimizations preserve stable identities, Undo, independent Trim/hiding,
and the previous complete result on failure. Record cold preparation, warm fit,
GPU readiness, redraw and presentation separately. Scripted movement timings
are not automatically physical mouse latency or production FPS.

F: has approximately 7 GB free at campaign start. Avoid duplicate asset copies
and unnecessary full builds; preserve originals and unrelated build folders.

Status: implementation and scoped qualification complete. See [delivery](DELIVERY.md),
[measurements](MEASUREMENTS.md) and [receipt](QUALIFICATION.json). The original
0.87.5.6 artist endorsement is preserved; this patch has its own evidence.
