# Receiving winding and constrained packing — investigation

Status: preserved investigation. Subsequent [packing recovery](PACKING_RECOVERY_0.3.2.md)
and [native receiving preparation](RECEIVING_PREPARATION_0.3.2.md) now pass the
complete original Table06 device scenario. The failures and disposable corrections
below retain their original diagnostic scope; they do not independently qualify
that later production fix. The full fourteen-item goal and final release remain
active. Current evidence is linked from [the complete-device report](DEVICE_IMPORTED_0.3.2.md).

## Actual evidence

`build/host-032-device-imported10` uses the exact 177-input native10 pair and passes
thirty assertions before Table06 publishes zero of two devices. All five loaded
module/private-profile guards pass. Query construction now preserves 1,520 real
triangles, omitting only 84 zero-area faces from its derived representation.
Original model files, face topology, materials and maps are not edited.

The exported table has a closed twelve-face glass shell and an open 1,508-face
frame assembly. The glass's authored underside at z241.672mm faces upward; its
upper side at z260.904mm faces downward. Its independently measured signed volume
is negative. Object transform parity was separately checked in Max: determinant
+1, so this is not an unaccounted mirrored object-to-world transform. Existing
native capture already compensates negative transform parity.

`build/host-032-device-imported10/independent-reversed-glass-capacity-witness.json`
binds the actual input, settings, verifier and constructed-pose proof by hash.
Reversing only the twelve glass faces in a diagnostic data copy makes two
460×500×560mm appliances at x2750/x3250, y0, z260.903931 physically valid. Full
support coverage is 1, separation is 40mm, all 802 source vertices/1,508 faces
transform correctly, and every conservative envelope of the 24 complete appliance
parts clears actual receiving triangles and closed-solid containment.

`build/host-032-receiver-winding-diag10` is a separate build-only cause diagnostic,
not a successful source-fixture qualification. It loads only the owned failed
witness, exports native inspection, and flips those twelve faces on a disposable
copied table using MAXScript. The authored native support is z241.672mm with
19.231mm clearance. The copied support is z260.904mm with open overhead. Generation
then publishes one original-size appliance at about [3034.249,-39.115,260.904],
yaw90. That central placement leaves insufficient side strips for another complete
appliance, although the independently proved two-copy layout exists. The diagnostic
fails its two-copy assertion. No original scene/model is saved over or repaired;
no production normal logic is changed by this diagnostic.

The subsequent focused portable diagnostic
`build/receiver-winding-packing-repro10/receipt.json` links the complete captured
800-vertex/1,604-face receiver and 802-vertex/1,508-face source to the preserved
native10 libraries. Its precise native query rejects the authored glass's top.
After reversing only the twelve closed glass faces in an owned data copy, both
literal original-size poses pass native support/clearance, including the second
with the first as an accepted obstacle and 15mm spacing. The ordinary solver
underfills seven of sixteen seeds (7712033–7712048). Both physical poses and the
old search failure are therefore reproduced in C++ before a packing edit.

The portable case uses its own region IDs. Seed7712033 happens to place both there;
the Max diagnostic with its saved region identities places one. Do not claim
bit-identical requests or compare those two layouts directly. The seven portable
failures provide separate reproducible seeds for regression. This is a focused
counterexample, not a full SDK/source-fixture acceptance pass or a production fix.

The subsequent recovery implementation passes all sixteen captured-model seeds,
twenty native suites and 64 actual Max checks on outward geometry, with five
independent actual-mesh cases and five rejected invalid controls. The exact
180-input recovery checkpoint retains the older failed poses and receipts. Its
native captured-mesh diagnostic corrects only an owned glass data copy; the
original imported inward glass still requires production preparation before the
complete device scenario can pass. See the recovery report for current evidence
and the preserved artist-profile guard failures.

## Research and implementation constraints

[CGAL's orientation documentation](https://doc.cgal.org/5.6/Polygon_mesh_processing/group__PMP__orientation__grp.html)
requires closed triangulated geometry for its outward-orientation predicate.
[Its mesh-processing manual](https://doc.cgal.org/6.0/Polygon_mesh_processing/index.html)
distinguishes orienting individual connected components from orienting boundaries
to enclose volumes. This supports component-level investigation rather than
reversing every downward face. Nested cavity boundaries, open sheets, inconsistent
winding and intersecting shells must not be blindly reinterpreted as solid boxes.
No CGAL dependency is currently added.

[Autodesk's face methods](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Editable-Meshes-Splines-Patches/Editable_Mesh-and-TriMesh/GUID-EF78FA1A-A382-4BED-BA10-7C856A7551A5.html)
document `meshop.flipNormals`; it is used only to isolate the cause on the
disposable copy. Production preparation, component analysis, containment and
packing belong in C++, preserving original authored geometry, appearance and UVs.

Before an orientation implementation, establish a shared native topology owner
for inspector and precise query. Reuse current bounded welding/DSU/edge machinery
and exact-coordinate fallback; avoid building parallel complete topology maps.
Any orientation decision must be derived and transient, shared consistently by
support qualification and occupied-volume crossing logic. Barycentric ray
determinants must retain actual vertex order; orientation for crossing events is
a separate sign. Declare transient/retained peak storage, aggregate work, invalid
inputs, cache invalidation and failure recovery before editing. Ambiguous open,
nested or intersecting geometry requires explicit conservative behavior.

The portable two-copy counterexample and both native-validated literal poses are
now preserved. Before packing recovery, promote its literal conditions into the
maintained native regression suite without losing the old underfilled result.
Repair may rearrange unlocked choices;
protected placements and explicit obstacles must remain untouched. Any alternate
search uses deterministic domains and the same aggregate work/placement limits,
publishing only a complete better validated result. Prefer original dimensions
before permitted fit fallback. Do not conceal underfill by shrinking with Fit off
or silently lowering the requested quantity.

## Required acceptance

Test outward/inward closed components, hard-edge duplicate vertices, mixed
polarity components, open sheets, ambiguous/nested boundaries, zero/near-zero
geometry and work/admission failures. Prove inspector and query agree, and source
meshes/materials/UVs remain unchanged. Add translated and mirrored-host cases.

For packing, require the actual two-device original-size Table06 result, repeat
seeds, protected/external-obstacle behavior, valid support/separation, bounded
performance, Undo and reopen. Complete the original six-case independent device
proof and intended original-material Corona preview. Then refresh the full Max
regression campaign and exact source snapshot. The unidentified earlier startup
crash, legacy book-row/minimum behavior and final installer/autostart qualification
remain separate open work.
