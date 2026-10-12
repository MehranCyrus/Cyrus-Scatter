# Research and evidence

Research date: 12 October 2026. Status: source research and implementation proposal, not product qualification. See [baseline.json](baseline.json) for the inspected checkout and hashes. Facts, historical observations, and proposed behavior are distinguished below.

## Evidence method

- Re-read current source, README, architecture, backlog, workflow, and 0.79.5 coverage. The working tree contains substantial pre-existing changes; HEAD alone does not identify this baseline.
- Use current official Chaos/iToo documentation for documented behavior; use GitHub for inspectable open-source references. Searches did not establish an official public Chaos Scatter or Forest implementation repository. Unrelated search results are not implementation evidence.
- Read the repository's earlier Ghidra reports and their recorded limitations. All seven installed inputs listed in the 9 October native receipt still match their recorded SHA-256 hashes. This verifies input identity, not a fresh execution of the historical experiments.
- Neither Ghidra nor `knowledge_status`/`knowledge_search` is exposed as a connected tool in this session. Direct source inspection is the documented fallback. No new vendor decompilation or Max experiment was performed.
- Initial small-model research was superseded by independent Astra source/design audits at the user's request. Recommendations were checked against the original requirements; rejected recommendations are recorded below. Reviewer agreement is not a substitute for implementation tests.

## Current-source findings

Line numbers are navigation aids at the hashed baseline; use the named symbols after edits.

| Finding | Direct evidence | Consequence |
|---|---|---|
| Ordinary bands accumulate widths independently per path and side | [`lineInputs`, template ~1444](../../../AminScatter/tools/ui/templates/unified-core.ms); `showPath` ~4119 | Preserve authored consecutive intervals; changing an earlier width moves later intervals only |
| Empty selected source sets are omitted after their widths are accumulated | Same function, `choices.count>0` and seven-field ordinary-band payload | A successor receives only a cumulative end and can occupy the omitted interval; fix requires explicit lower bounds and explicit empty membership |
| Empty native source vector means group fallback | [`scatter.cpp`, band preparation ~265](../../../AminScatter/src/scatter.cpp) | An empty vector cannot represent an intentionally unassigned band without changing the membership contract |
| Rounded support uses side containment and nearest XY segment distance | `AreaMask::strokeBand`, same file ~128 | Convex external corners round naturally; this is geometry, not a display defect |
| Ordinary source assignment stops at first matching band | Main selection loop ~375 | Current ordered classification cannot blend two overlapping contributions |
| Band ownership is rediscovered during automatic movement | `scatter.cpp` ~406; [`final.inc` ~29](../../../AminScatter/src/final.inc) | New overlap semantics need retained owner provenance and one eligibility evaluator |
| Boundary orientation is currently invoked for Analyzer layout | Template `procPrepare` ~2673–2676; [`orientation.inc`](../../../AminScatter/src/orientation.inc) | Audit metadata transport and Analyzer regressions; ordinary spline orientation expansion is not required by this task |
| Instance/point data does not carry band identity | [`scatter.h`, `Instance` and `PreviewPoint`](../../../AminScatter/include/scatter.h) | Source-only coloring cannot distinguish the same source in two bands |
| Placement transport validates exactly two or five columns | [`placement_identity.inc`](../../../AminScatter/src/placement_identity.inc) | Extending a row ad hoc would break consumers; inventory and version the internal transport together |
| Advanced Accepted target replenishes missing ordinals toward the original budget | [`procedural.cpp` ~75–145](../../../AminScatter/src/procedural.cpp); [`receiver_plan.cpp`](../../../AminScatter/src/receiver_plan.cpp) | Fractional density can be replenished away. Count/plants-per-square-metre and Candidate budget/Accepted target are separate controls |
| Existing falloff and brush code use deterministic thinning | [`boundary_falloff.inc`](../../../AminScatter/src/boundary_falloff.inc); [`brush.cpp`](../../../AminScatter/src/brush.cpp) | Reuse sampled-curve conventions and keyed decisions, but do not reuse an Area owner as a Band owner |
| Source swatches already exist | [`colored-lists.cjs`](../../../AminScatter/tools/ui/colored-lists.cjs), `OwnerDrawFixed` | Extend this UI; do not rebuild an existing feature or add color names to row text |
| Band settings are indexed arrays; sources already have stable IDs | Template `strokeSettings`, `syncStrokes`, `setStrokeSelection`, copy registry | Add stable band/path identities and audit deletion, copying, persistence, callback selection, and cache signatures |
| Display colors and assignment groups have distinct meaning | Template `sourceColor`, `sourceIDColor`, `assignGroup`, `procStagePreview` | A group-color change can change assignment. A Band identification-color change must be display-only |
| Radius is currently one effective scalar | [`procedural_bridge.inc`, `cyrusProceduralRadii`](../../../AminScatter/src/procedural_bridge.inc); [`procedural.h`](../../../AminScatter/include/procedural.h) | Auto footprint and 3D bounds require explicit metric selection; do not feed a horizontal radius to every 3D rule |
| Spacing supports separate own/blocker radius arrays per external rule | [`procedural.cpp`](../../../AminScatter/src/procedural.cpp); [`group_spacing.h`](../../../AminScatter/include/group_spacing.h) | Two effective radii can be routed through existing rules without replacing the collision algorithm |
| Source evaluation can produce pivot-local geometry | [`max_bridge.cpp`, `meshOf` ~163](../../../AminScatter/src/max_bridge.cpp); [`geometry_preview.inc`](../../../AminScatter/src/geometry_preview.inc) | Reuse the coordinate convention for cached bounds; extraction stays on the host thread |
| Corona render prototypes can differ from viewport proxy meshes | Template render bridge ~4750: copied `CProxy` with `previzType=3` | Ordinary preview bounds are not automatically render-accurate proxy bounds |
| Z Offset tooltip says normal, calculation adds world Z | Template `sourceZSpin`; `max_bridge.cpp`, `cyrusApplySourceTransforms` ~110 | Correct the tooltip as a small scoped fix; changing offset semantics is a separate feature |

The user's earlier mixed-source screenshots do not prove width coupling. Per-band group/direct selections explain those observations, and the user confirmed the corrected assignment. Shared collision/cleanup can also change accepted counts without changing an inner band's geometric boundary.

## Existing viewport evidence and limits

[Current architecture](../../ARCHITECTURE.md), [0.79.5 coverage](../../Terrace_Workflow_0.79.5_2026-10-11/COVERAGE.md), and [the backlog](../../BACKLOG.md) describe layer-local preview preparation, published-state reconstruction in Manual mode, retained radius lines, and unchanged sibling buffer reuse. These are relevant foundations, not proof that new band overlays or colors are inexpensive.

Current source distinguishes two failure stages:

1. Script/CPU preparation stages changed layer previews before installation. A failed preparation can retain the preceding complete publication.
2. Native `PointDisplay::publish` disables/resets the old generation before constructing a successor; GPU `Realize` occurs later and can fail. Existing fallback and lifetime behavior need explicit allocation/realization tests. Do not describe atomic GPU replacement or device-loss recovery as already proven.

Current native reuse checks snapshot identity, group index, and style. Rebuilding a colored snapshot loses reuse within the changed layer even when triangles match. The plan therefore addresses geometry/transform/color resource separation only where band coloring requires it. It does not promise a general renderer rewrite.

Historical 0.79.5 measurements report 304.1 to 150.7 MB for the tested heavy-layer display edit after sibling reuse. That remaining changed-layer upload is a real design constraint. Scripted orbit timing is not presented FPS; neither it nor a native test pass qualifies physical interaction, device loss, or material fidelity.

## External references: useful behavior, with scope boundaries

The following pages were checked in this research pass. Web documentation may describe a different vendor version from the hash-pinned installed binaries.

| Reference | Verified useful behavior | Cyrus lesson / boundary |
|---|---|---|
| [Chaos Scatter, Corona for 3ds Max](https://docs-chaos.atlassian.net/wiki/spaces/CRMAX/pages/124525180/Chaos%2BScatter) | Area Near/Far ranges; separate scale/density curve editors; relative model frequency; collision spacing controls | Separate density from model choice. Documentation does not prove Cyrus-style overlapping source bands, Sharp joins, or internal cache rules |
| [Forest Areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas) | Area-specific model subsets, additional area scale randomization, density/scale falloff, ordered areas, and boundary-checking choices | Region settings and source settings can coexist. Area precedence is not evidence of additive independent band populations |
| [Forest Geometry](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry) | Source probability, scale, Z offset, and collision radius are distinct controls | Keep source ownership explicit; do not copy a percentage-radius UI into Cyrus's world-unit field |
| [Forest Image distribution](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode) | Collision removal uses bounding spheres; heavier candidate density can increase discarded work without increasing output | Record attempted, density-rejected, collision-rejected, accepted, and shown populations separately |
| [Forest Display](https://docs.itoosoft.com/forestpack/forest-plugin/display) | Bounded point-cloud preview and cached GPU updates; view-dependent options can force updates | Keep band overlays independent of camera-driven population changes and retain stable preview subsets |
| [ClipperOffset reference](https://www.angusj.com/clipper2/Docs/Units/Clipper.Offset/Classes/ClipperOffset/_Body.htm) | Closed-polygon offsets, hole orientation, intersection cleanup, and changed output path ordering | Normalize polygon topology before Sharp offsets. Never infer identity from offset contour order |
| [Clipper MiterLimit](https://www.angusj.com/clipper2/Docs/Units/Clipper.Offset/Classes/ClipperOffset/Properties/MiterLimit.htm) | Default limit 2 bounds acute spikes by square truncation | Label Sharp as bounded miter behavior; do not claim infinitely extended sharp tips |
| [Clipper2 source at inspected commit](https://github.com/AngusJohnson/Clipper2/blob/879e2e85041d2c29e0cbfa90d3ee0c5a87b3ddd8/CPP/Clipper2Lib/src/clipper.offset.cpp) | `OffsetPoint` dispatches Miter/Round/Bevel/Square; Miter falls back to `DoSquare` | The existing vendored 2.0.1 implementation has this branch. No library upgrade is required by this plan |

Only short behavioral summaries are retained here; the linked pages are the primary external references. No vendor implementation is proposed for copying into Cyrus.

## Existing native research reused

[9 October native research](../../Vendor_Native_Deep_Research_2026-10-09/README.md) and its [code map](../../Vendor_Native_Deep_Research_2026-10-09/CODE_MAP.md) record selected Chaos stroke/model paths and Forest source-sample cache behavior. [Earlier Forest findings](../../ForestPack_Research_2026-10-08/NATIVE_FINDINGS.md) record selected collision and display paths. The later report narrows/corrects the earlier unresolved cache interpretation; historical recommendations about retired paint ownership are not current instructions.

These reports describe Ghidra reconstruction, not recovered original repositories. They support prepared spatial queries, source sample reuse, bounded work, and distinct model-selection responsibilities. They do not establish the vendors' complete band falloff algorithms, overlap policies, or cache invalidation rules. The [Ghidra MCP repository](https://github.com/bethington/ghidra-mcp) was checked as the tooling reference; its availability on GitHub is not an active connection to the local analysis projects.

Fresh vendor disassembly is not a dependency for this implementation. A future narrowly scoped probe would be justified only by an unresolved Cyrus design question that public behavior and local tests cannot answer; it must identify the binary and query under examination.

## Corrections made during independent review

- Reject collapsing unassigned consecutive bands. Their authored intervals must remain reserved.
- Reject first-match selection for Independent mode. The requested Sphere/Box overlap requires both contributions.
- Correct the claim that swatches are absent: they already exist in generated owner-drawn lists.
- Correct the proposed blanket orientation rewrite: ordinary spline bands do not currently enter Analyzer orientation.
- Reject a frozen global density-adjusted accepted target as a supposedly complete solution: collision-driven replenishment can still redistribute density spatially.
- Reject scalar XY-only Auto Radius for mixed XY/3D scopes, and unqualified proxy-bound claims.
- Reject describing CPU staging evidence as proof of atomic GPU/device-loss behavior.
- Require movement to recheck the retained occupancy and owner decisions, not just nonzero support.
- Preserve copied random recipe keys while giving the copied layer a distinct address namespace.
- Bound aggregate Sharp contribution error across overlaps; per-Band error alone does not bound combined occupancy. Certify intermediate-contour bracketing as well as support boundaries.
- Pin sampled linear curve semantics, current-schema-55 initialization and Auto's empty/degenerate/required-source rules rather than leaving them to interpretation during coding.

## Remaining empirical questions

No new product test suite, Max build, native benchmark, GPU capture, or host scene was run during planning. Sharp field accuracy/cost, end-to-end metadata survival, dual-radius proxy behavior, color-only upload reduction, and physical UI operation remain measured implementation gates in [VALIDATION.md](VALIDATION.md). The plan must not be called flawless or release-certified before those gates pass.
