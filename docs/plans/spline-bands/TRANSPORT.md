# Placement transport inventory and selected contract

P0 source inventory began at source 0.79.6. Current implementation targets source 0.80.0/schema 57 with one internal placement format. Keep raw candidate identity separate from edited output identity, Band identity, source-row identity and renderer source index.

## Selected v2 row

Use one exact eight-field internal row, with named host helpers:

| MAXScript field | Raw stage | Post-Edit stage |
| --- | --- | --- |
| 1 | Matrix3 placement | Edited Matrix3 placement |
| 2 | One-based source slot in this preparation/publication | Same source slot |
| 3 | Nonnegative Integer64 candidate identity | Stable String output identity, including clones |
| 4 | One-based base receiver face | Original base receiver face |
| 5 | Base barycentric Point3 | Original base barycentric Point3 |
| 6 | Positive local Band ID; zero only for non-Band layouts | Inherited Band ID |
| 7 | Boolean protected flag, initially false | Existing protection or authored transform/clone protection |
| 8 | Integer transport version 2 | Integer transport version 2 |

Do not reconstruct anchors from a moved placement or Band ownership from position. Receiver concatenation updates the base face exactly once. Candidate ID packing preserves the receiver-local random recipe; Band namespace and display order are not RNG inputs. A clone gets a new output ID and inherits provenance. Publication freezes its owner dictionary alongside rows, sources, paired radii and display metadata. Source index remapping preserves all other fields.

The user subsequently removed compatibility requirements. Current generation, receiver operations, filters and Edit consume/produce exactly eight fields; older two/five/four-field internal transports are rejected. Raw candidate identity is Integer64, post-Edit identity is String. Renderer/export boundary consumers may deliberately project transform/source fields without introducing an alternate internal representation. A missing required Band ID is an error, not Unbanded.

## Producers and consumers

All source paths below are under `AminScatter/`.

The table retains the original inventory as a baseline-to-target checklist. The as-built section below describes the current implementation; the old row layouts in the baseline column are no longer accepted.

| Stage | Source/symbol | Pre-0.80 baseline | Target v2 change |
| --- | --- | --- | --- |
| Generate and finalize | `src/max_bridge.cpp`, `appendIdentity`, `src/scatter.cpp`, `src/final.inc` | Native Instance plus 2/5-column rows | Native owner, complete row writer, retained owner during movement |
| Parse native transforms | `src/placement_identity.inc`, `placementInstance` | Exactly 2/5 columns | Stage-specific parser; retain owner/protection/anchors |
| Receiver candidate packing and concatenate | `tools/ui/templates/unified-core.ms`, `generateInstances`; `src/receiver_bridge.inc`, `cyrusReceiverOffsetRows` | Candidate ID replacement; exactly five fields copied | Preserve owner/version/protection and offset only field 4 |
| Source transforms | `src/max_bridge.cpp`, `cyrusApplySourceTransforms` | Validates then modifies Matrix3 in original rows | Validate v2; preserve remaining fields and source remap semantics |
| Whole Scale | `src/whole_scale_bridge.inc`, `cyrusWholeScale` | Stable mode requires five fields; copies tail | Accept validated raw v2 and keep keyed channel |
| Area falloff | `src/boundary_falloff_bridge.inc` | Strict five-field stable input; Instance roundtrip | Central parser/writer preserve owner |
| Vector coverage | `src/brush_host.cpp`, coverage primitive | Requires five fields; returns selected original rows | Validate raw v2 and read unchanged anchor slots |
| Transform copy | `src/brush_host.cpp`, row copying | Copies every tail field | Keep copy semantics; validate before edits |
| Analyzer orientation | `src/orientation_bridge.inc` | `placementInstance`/`appendIdentity` roundtrip | Central transport helpers; do not add ordinary spline orientation |
| Edit stack and clones | `src/cyrus_edit_stack.inc`, `EditInput`, `applyStable`, `cyrusEditStack` | Reduces to transform/source/output ID/protection | Carry anchors and owner through every modifier and clone |
| Edit publication | `src/cyrus_edit_stack.inc`, `cyrusEditPublish` | Reads output ID | Validate post-Edit stage; retain ID meaning |
| Group spacing | `src/group_spacing_bridge.inc`, `groupProtected` | Protection only at exactly four fields | Named protection accessor, exact stage validation |
| Procedural acceptance | `src/procedural_bridge.inc`, row identity and sample loop | Returns kept original rows | Preserve complete v2 and route XY/3D radius per rule |
| Radius overrides | `src/procedural_bridge.inc`, `cyrusProceduralRadii` | Source slot and keyed output ID; one scalar | Validated v2, unchanged override keys, published metric pair |
| Script preparation/filter/remapping | template `procPrepare`, `containerFilter`, source-policy filters | Mixture of original-row filters and explicit row construction | Audit each constructor; no implicit truncation of v2 |
| Publication/rollback | template `evaluateProcedural`, `procStagePublication`, `procPreviewState`, `procRestoreResult` | Complete root/leaf snapshots | Include frozen owner dictionary and radius pair in both install and restore |
| Read-only publication pages | template `procPlacementPage` | `row.count==4` protection predicate | Named protection access; keep external page contract deliberately versioned |
| Preview | `src/preview.cpp`, `src/geometry_preview.inc`, `src/scatter.cpp` pointCloud; template `procStagePreview` | Source/transform samples with no Band identity | Owner stream stays aligned through subsampling and material groups |
| Exact output/render/export | template `instances`, `outputSources`, render bridge | Matrix/source consumers | Explicit boundary projection; renderer geometry/material behavior unchanged |

## As-built status and remaining qualification

Current readers/writers share `include/placement_transport.h`: exact eight fields, raw Integer64 or post-Edit String identity, preserved owner/protection/anchors. Generation/finalization, receiver offsets, source transforms, Whole Scale, falloff, Brush, Analyzer orientation, Edit/clones, procedural acceptance and read-only pages have current-format handling and host transport witnesses. Point and mesh caches retain one owner slot per point/instance, addressing an immutable sorted Band dictionary. Source geometry remains shared across Band colors.

`cyrusFilterSourceRows` accepts both stages of this same current layout because
exact output groups published String-ID rows as well as raw candidates. It retains
anchors, ownership and protection while filtering/remapping sources. Retired row
widths and empty edited identities fail validation. The matched native primitive
is required; the script does not contain a substitute compatibility filter.

The generation bridge now accepts exactly 29 arguments, 11 current options and four Relax controls. There is no sampler opt-in flag, refill argument, retired cluster-distribution setting or generator-local collision branch. The prepared ordinary field and Analyzer rows are distinct contracts. Source 0.80.0/schema 57, native Band interface 8, placement transport 2 and procedural publication 2 must be matched; qualification is tracked in PROGRESS.

Analyzer uses one **11-field** row: paths, outer distance, explicit sources,
minimum/maximum scale, mode, start distance, edge mask, straight ends, facing
settings and edge-row settings. The unused ordinary-side Boolean is removed.
Only Analyzer modes 1–6 are accepted; ordinary splines require the immutable
prepared field. Both generation and orientation reject the retired 12-field
layout and mode zero. The native `AnalyzerBand` type contains no ordinary-side or
Band-owner fields. Analyzer placements have no ordinary Band owner.

Published metadata has five fields: source identities/colors; Band identities/colors/labels/Path IDs; the ordinary-Band requirement; face-referenced source geometry signatures/bounds; and the completed field revision key. Palette-only updates share CPU/GPU geometry and retain prior material values. Manual uncached representation changes check the published geometry signature; changed sources require Update. Unpublished copied layers keep an empty publication dictionary until Update. Current source-revision, palette, field and actual image witnesses pass in Max 2026/2027. The GPU API permits one final instance buffer, so transform and owner are separate logical fields within it. GPU failure checks also cover the combined inspection bundle. Final cost and physical acceptance gates remain open; see PROGRESS for exact identities.

The current radius implementation returns one `(XY, 3D)` pair per original selected row. `cyrusProceduralRadii` takes exactly five arguments: edited rows, source specifications, override IDs, override modes and override values. A source specification is `(mode, Manual radius, Follow Scale, pivot-local minimum, pivot-local maximum)`, with mode 1 Manual or 2 Auto. The six-argument scalar interface is removed. Self spacing and each external rule independently select both sides' appropriate metric. Absolute overrides set both values; multiplier overrides scale both.

Source inspection returns seven fields: status, node handle, content fingerprint, minimum, maximum, Auto capability and explanation. Status 0 is an uninspected placeholder, 1 usable face-referenced geometry, and 2 unavailable/empty geometry. Dormant sources have no fabricated bounds. The bounded 512-entry weak-reference metadata cache invalidates on SDK geometry/topology/transform notifications and validity-interval expiry; it retains no meshes or owning node references. `cyrusSourceGeometryStats` reports queries, extractions, cache hits and current cache entries. It is diagnostic, not a physical memory measurement. Current initial Auto capabilities are Mesh/Editable Mesh, Poly/Editable Poly, Box, Sphere, Cylinder, Plane, GeoSphere, Cone and Capsule. Other source types, including unqualified renderer proxies, keep Manual radius.

XY display is one ring and 3D display three orthogonal rings per chosen instance. Both read frozen published pairs. The per-layer display limit counts instances, while `radiusDisplayCount` and the native radius-cache count report actual rings. A 10,000-ring admission check runs before script point-array allocation. The new interface and source-cache behavior require the P5 host witnesses; earlier palette passes alone do not qualify them.

Use native owner tests plus actual SDK/Max raw-to-post-Edit transport, clone, source removal/remap, receiver offsets, Analyzer and Brush fixtures. Test protection in every consumer and fault rollback after a later layer installs. This inventory is a source checklist, not proof of a passing transport round trip. Inspect newly added consumers during integration and extend it rather than treating this table as exhaustive forever.

## Field display preparation and integration

`cyrusBuildFieldPreview(field, receivers, settings)` consumes the same immutable
field as generation. Settings are exactly `(selectedBandID, falloff, boundaries,
sampleLimit, displayOffset)`: identity zero selects combined occupancy, positive
identity selects that Band's contribution, both toggles are Boolean, sample limit
is an integer 1..20,000, and offset is finite and nonnegative in system units.
This creates a transient line cache only; it does not publish a population or
alter accepted counts. The saved display settings select visibility, contribution
or combined occupancy, sample allowance and stable Band identity. They are
excluded from placement keys and copied independently with the layer.

`cyrusBuildInspectionPreview(rings, fieldCacheOrUndefined)` replaces the old
radius-only primitive. It merges both line sources into one immutable cache;
field-only input reuses its cache. Every population still occupies at most two
retained slots. Main geometry, palette and inspection signatures are separate.
`cyrusFieldDependencyKey(nodes)` returns a bounded weak-reference revision key
for at most 544 receivers/Paths per call, with a process LRU of 1,024 entries.
Relevant SDK notifications and validity expiry advance it; this conservative
marker is not a content hash or a promise that a reverted edit recovers an old
revision. Unchanged field refresh does not resample receiver/Path geometry.

Manual preview stages current field inputs without replacing published plants,
radii or field metadata. Its exact pending label distinguishes the two states.
Timeline notifications schedule this feedback only when enabled; normal Live
publication continues to consume relevant animation. All changed layers stage
before installation, with field caches/keys/labels included in rollback state.

Samples lie on actual receiver triangles, apportioned by 3D area with at least
one sample per nonempty receiver. The display reports approximation rather than
claiming every face is sampled. Triangle glyphs encode 33 density bins; zero is
blue, 100% red, and boundary lines white. The exact scalar is evaluated before
the display offset. Outlines intersect a vertical curtain with every overlapping
receiver triangle, including stacked surfaces. A vertical face coincident with
that curtain displays its clipped perimeter. No Brush terrain restriction or
highest-surface ray is used.

Sharp outlines reuse their prepared start/end contours. Rounded outlines use
tubes around the original sampled segments, including internal segments of
self-overlaps, then combine them with the normalized parity region. This follows
the bundled Clipper2 [Joined-polyline behavior](https://www.angusj.com/clipper2/Docs/Units/Clipper/Types/EndType.htm)
and explicit [arc tolerance](https://www.angusj.com/clipper2/Docs/Units/Clipper.Offset/Classes/ClipperOffset/Properties/ArcTolerance.htm).
The chosen Cyrus display tolerance is the greater of four field quanta and
1/256 of the narrowest interval sharing an endpoint; the reported contour
uncertainty also adds four quanta. Receiver clipping drops only segments at
coordinate-relative double roundoff scale. This is display approximation;
generation's scalar interpretation is unchanged.

Admission stays within the existing resource domains: up to 512 receiver nodes,
200,000 copied faces, 20,000 samples, 32,768 outline segments and 100,000 final
line segments. Total numeric work is capped at 50 million units, divided before
execution between contour preparation and sampling/clipping. Queries receive
their remaining visit budget. Owned preparation uses the existing 64 MiB point
allowance and 128 MiB process budget; Rounded scratch reserves at most 128 MiB
against the existing 512 MiB field aggregate. The bridge reserves the maximum
admitted copied-face payload before extraction, avoiding repeated host conversions
just to count faces. Native display conversion, output snapshots and at most
1,000 diagnostic samples have separate simultaneous point reservations. Host
conversion, allocator and driver overhead still need physical measurement.

`cyrusFieldPreviewInfo(cache, witnessLimit)` is read-only, with limit 0..1,000.
Its 15-field version-1 response is: version, sample count, line count, boundary
line count, input faces, degenerate faces, nonempty receivers, sampled receivers,
sampled faces, numeric work, admitted preparation bytes, temporary numeric output
bytes, contour uncertainty, outline segments, and witness rows. Each witness is
`(position, barycentrics, receiver node handle, one-based face, value, scalar
error)`. At most 1,000 witnesses are retained, evenly selected from the sample
sequence. Temporary numeric output bytes are not the retained GPU allocation.
