# Native arrangement engine

The 0.1.1 foundation introduced an independent C++20 arrangement engine above the sampled inspector. Candidate generation and styling live in `arrangement.cpp`; every accepted or retained placement must pass a supplied native `PlacementQuery`. The concrete furniture query owns support-polygon operations, furniture collision/accessibility checks and precision tolerances. Sampled cells alone never certify object fit. Neither engine nor query calls Max from numerical work.

Version 0.1.3 adds [bounded numerical support for imported level boards](NUMERICAL_SUPPORT.md). Eligible original triangle height ranges must fit the explicit contact tolerance of the candidate base; nearby eligible height bins unite before edge inset. Native46 passes twelve executables and 117 cases, including unchanged golden results. Its actual imported workflow/render trial and sixteen functional host suites pass; [release validation](RELEASE_VALIDATION_0.1.3.md) records the separate measurement and delivery gates. Earlier milestones below retain their original scope and test counts.

## Contract and transforms

Canonical `Asset` metadata comes from `assets.h`: stable numeric ID, full evaluated mesh and exact full bounds, category/eligibility masks, contact anchor and convex contact polygon, discrete yaw poses, weighted selection, permitted uniform scales and an optional authored top support polygon/height. All geometry is physical millimetres in the inspected, translated, Z-up frame.

A `Placement` records stable ID, asset ID, parent stack ID (zero means furniture support), region ID, contact-anchor position, yaw in degrees, uniform scale and lock state. A canonical asset point is transformed by:

`world = placement.position + Rz(yaw) * (asset_point - asset.anchor) * scale`

The same transform is used for contact footprint, authored top patch, full geometry instancing and the collision box. `placement_bounds()` encloses the complete asset mesh bounds; it does not reduce collision to the contact base. This initial collider is conservative for concave/porous assets and can reject arrangements that detailed mesh collision would allow. The engine does not claim detailed mesh-to-mesh contact or stability simulation.

`ArrangementRequest` borrows spans synchronously. No input memory, query spans or pointers are retained. `ArrangementResult` owns typed placement rows, requested/accepted/kept/candidate/underfill counts, rejection counts and warnings. Success publishes a complete result; exceptions leave the caller's arrays untouched so the host can retain its previous completed result. The host owns actual atomic document/scene publication and Undo.

## Geometry query boundary

For every proposed placement the engine supplies:

- The complete transformed contact footprint, support Z and inspected region ID.
- The full-bounds oriented collision box.
- Every already accepted/retained placement as a stable-ID collision obstacle.
- For stacks, the parent ID and its exact authored, transformed top polygon.
- Edge clearance, prop spacing, and remaining work allowance.
- An optional authored front direction for the region. An absent override inherits the query default.

The callback returns a rejection reason (`Unsupported`, `Boundary`, `Obstacle`, `Spacing`, `Stack`, or `Category`) and charged work. It must stop or throw before exceeding the allowance. The engine charges that work and rejects invalid result codes. A callback failure propagates; no partial result escapes. The initial precise implementation is responsible for support coverage/edge inset, collision with captured furniture, existing generated props and accessibility; an always-accept test double establishes engine behavior only.

Parent/child contact is authorized solely on the authored top patch. A child is positioned at parent anchor Z plus scaled stack height. Stack edge margin is zero to allow equally sized flat books to align edge-to-edge; complete support containment remains required. Other furniture/prop collision checks remain active. The query must distinguish permissible contact with the support parent from penetration or unrelated spacing violations.

`FurniturePlacementQuery` validates and normalizes global and per-probe horizontal front vectors with length in `[1e-9, 1e6]`. A probe override replaces the direction, while query-level `require_front_access` still enables or disables the furniture insertion sweep. Invalid overrides are rejected even when the sweep is disabled. The sweep checks captured furniture; it does not establish an artist-preferred viewing direction or a physical manipulation path around other props.

## Independent collision obstacles

`FurniturePlacementQuery(furniture_bodies, settings, obstacle_bodies)` accepts an optional third span of independent scene meshes. Existing two-argument calls retain their behavior. Numeric body IDs must be nonzero and unique across both spans. All meshes already use the same translated physical-mm frame; the query does not apply node transforms or retain input pointers. It copies the triangle geometry needed for its immutable index, so caller buffers can be released after construction.

Only `furniture_bodies` contribute upward horizontal support polygons. Obstacle tops, bottoms and open horizontal sheets never create placement support, even when a proposed footprint fits them completely. The host must likewise inspect and reconcile only furniture, then capture independent obstacles separately for the query. Obstacle movement may change accepted poses or produce underfill without changing the identity of the underlying furniture support. A source intentionally serving as both support and obstacle belongs in the furniture span once; duplicate IDs are rejected.

Both spans contribute to the collision BVH, per-body connected-component topology, closed-component containment and enabled front-access sweep. Static full-bounds OBB/triangle penetration rejects; a prop wholly inside a recognized closed solid also rejects. Open obstacles are two-sided triangle barriers, including thin screens, but their unspecified interiors are not classified as filled solids. No closed-mesh SDF or watertightness assumption is applied to open meshes. Existing contact tolerance permits touching and ignores penetration within that tolerance. The native prop-spacing parameter applies between accepted generated/retained prop boxes; it does not add a separate clearance envelope around external mesh obstacles.

Front access remains a straight horizontal translation from the proposed pose beyond the combined geometry bounds. Independent obstacles participate in that sweep, including regional direction overrides. Globally disabling access leaves static collision and containment active. The sweep does not establish a full insertion order around accepted prop boxes, vertical access or a robot motion path. Exposed table/counter workflows may require access checking to be disabled at the host level; adding chairs or lamps to the collision scope does not infer that preference.

Combined furniture and obstacle admission is at most 4,096 bodies, 1,000,000 triangles and 3,000,000 vertices, checked across both spans before welding/topology buffers. `QuerySettings::max_vertices` can lower the vertex ceiling. Build work is capped at 200,000,000 charged units and support outlines at 32,768 vertices; obstacle meshes consume collision budgets without consuming the support-outline budget. Coordinates remain within 10 km of the translated origin. These are explicit numerical/cardinality limits, not measured process-memory or interactive-latency guarantees.

## Deterministic candidate search

Assets sort by stable ID; regions sort by region ID; eligible cell pointers sort by XYZ. A fixed integer hash/generator derives independent per-region/per-attempt streams from the authored seed. The engine does not use library-dependent random distributions or worker completion order. Stable placement IDs derive from seed, region, attempt, asset and optional parent. No pointer, Max node handle or output array index becomes a saved placement identity.

Usable cells suggest contact anchors and local jitter. Sampled usable area estimates desired population. Both are search heuristics: actual footprint coverage and full collision must still pass the query. An explicit cell with `usable=true` and zero clearance is invalid input.

The target per selected region is the ceiling of:

`usable_area * density * region_density_multiplier * (1 - empty_space) * style_factor / weighted_mean_slot_area`

Slot area is `(sqrt(contact_area * midpoint_scale^2) + spacing_mm)^2`. Style factors are Minimal 0.55, Balanced 1.0 and Layered 1.35. Kept placements subtract from that region's target; they are never removed just because a lower density would prefer fewer props. A zero density or empty-space value of one creates no new props. Category caps and physical rejection can leave a reported underfill.

The five furniture presets (TV console, open shelf, coffee table, kitchen counter and dining table) whitelist categories and supply category weights, maximum counts per region and stacking eligibility. Asset furniture masks further restrict eligibility. Effective selection weight is category weight multiplied by asset weight. An empty eligible library returns retained props with a warning; it does not substitute unrelated categories. Preset occupancy/margins are available to caller/UI defaults; explicit engine settings own active density and clearance values.

## Authored region policies

`ArrangementRequest::region_rules` optionally supplies up to 4,096 `RegionPlacementRule` rows. IDs must be unique and belong to the current input regions. Missing rows preserve neutral policy: all otherwise eligible categories, density multiplier one, stacks permitted, no exclusion and the geometry query's default front. Present rows carry allowed category mask, density multiplier `[0,4]`, stacking permission, exclusion and an authored front vector. Rules and their array order do not become random seed inputs.

The mask intersects furniture category rules and asset furniture eligibility; it cannot enable a forbidden category. Weighted mean slot area is computed separately from the assets allowed in each region. Density is multiplied without silently clamping the effective value to one; ordinary target, placement and work limits still apply. Multiplier zero prevents new props while preserving valid protected rows. A zero category mask forbids every category, including protected props.

`allow_stacking=false` blocks every placement with a nonzero parent ID while still allowing stackable assets directly on furniture. Every accepted base and child is checked against its region policy. Excluded regions remain in the current region input and retain identity but produce no new candidates. Full or selected regeneration drops their unprotected previous props. Conflicting locked rows, support-connected protected stacks, or unselected rows abort atomically with a policy error; they are never silently dropped. To clear an excluded occupied region, include it in regeneration and unlock its protected stack, or revise the policy.

Region policy currently owns the **placement anchor**, not every point of its footprint. Membership is established from the recorded region's sampled cells. Full contact-footprint containment and edge clearance are separately tested against the global union of captured furniture support polygons at that height, at the query's 0.001 mm quantization. The concrete query does not clip that union by `region_id`, category mask or exclusion. Consequently, an excluded region cannot receive a new anchor, but exclusion does not turn its physical surface into an unsupported or collidable area.

For example, where distinct region records A and B cover touching coplanar areas X=0..100 mm and X=100..200 mm, a 20 mm wide footprint anchored at X=95 mm in A can extend to X=105 mm into excluded B if its entire footprint and requested edge clearance fit the global union and all collision checks pass. An unsupported gap or hole between the areas still rejects any footprint spanning that gap; regional policy does not weaken whole-footprint support or collision validation. Stack children instead require full containment on their parent's authored transformed top patch and inherit its region policy.

For a physical keep-clear zone, author an explicit independent collision obstacle volume rising above the support plane and include it in the setup's collision scope. Static collision remains subject to the documented contact tolerance; a flat coplanar sheet or a region label alone does not reserve a volume. Exact per-region footprint masks/insets would require separate region-to-polygon query binding and qualification. They are future work if required, not implemented semantics of the current exclusion/category controls.

## Styling settings that change actual placements

- `density`, `empty_space`, spacing and style change desired population; spacing also reaches real collision validation.
- `cluster_strength` chooses positions around accepted props at a radius based on their full horizontal bounds and physical spacing. The geometry query can reject a proposed cluster. Zero uses independent sampled anchors. This is a local cluster recipe, not a learned aesthetic score.
- `height_variation` varies uniform scale within each asset's authored interval around its midpoint. Zero uses the midpoint; one uses the full interval. It never adds arbitrary floating Z offsets or exceeds authored scale ranges.
- Assets with valid stacking metadata create real parented groups, including flat-book stacks and ornaments on authored tray tops. Clustered Layered style has the strongest stacking preference; Balanced and Minimal reduce its probability. Children must be accepted on the parent's top mask and allowed on stacks by the furniture recipe. A new Book child must also have height at most 0.75 times the smaller horizontal dimension. This initial heuristic keeps upright book models out of flat-book stacks.
- Stack depth, remaining population target, category count and geometry validation bound every stack. Parents are accepted before children. A failed child stops that stack; it does not invalidate an already valid parent.

## Locks and selective regeneration

The request can identify explicitly locked stable IDs and selected region IDs. An empty selected-region list means all regions. Previous rows outside selected regions are retained exactly. Existing `locked` rows and explicit lock IDs retain their poses; explicit IDs set the saved lock flag. A lock on any stack member protects its entire support-connected stack, including ancestors and descendants, so regeneration cannot leave a floating child.

Protected rows validate in depth then stable-ID order, with parents available before children. Missing assets/regions/parents, cycles, invalid transforms, incompatible top metadata, conflicting furniture/region rules or failed protected geometry abort the successor. Full regeneration drops unprotected previous rows even if their old regions or assets no longer exist; selective regeneration protects every unselected row and therefore fails if one has lost its binding. The caller's previous rows remain intact. Protected counts consume regional category caps once and subtract from the desired population. Lower density alone does not remove protected rows.

Before geometric fit validation, protected bases, row members and ordinary bases displaced by clustering must lie within a current cell of their recorded region, using half the inferred cell size plus 0.01 mm in XY and 0.01 mm at support height. Every scanned cell consumes work. Ordinary anchors constructed directly from a sampled cell plus at most 0.4 cell widths of jitter on either axis are already within that square and need no redundant scan. A displaced new anchor outside its recorded region receives a Boundary rejection; a protected mismatch aborts the successor. Another same-height support passing global geometric fit cannot override regional exclusion/category rules. Stack children inherit their validated parent's region and authored top height. The engine does not infer persistent surface identity: the host remaps inspector IDs through `region_registry` before arrangement. Conservative identity matching and this membership guard remain independent of exact footprint/collision validation; sampling changes can require explicit rebinding.

Selective regeneration is exact for unselected rows. Generated IDs/choices are deterministic for unchanged relevant inputs in the same floating-point environment. Collisions, changed geometry, locks, category weights, seed or algorithm version can alter accepted candidates. Cross-version/platform bit identity and unchanged acceptance under every parameter edit are not promised.

## Bounds and publication lifetime

Absolute ceilings are 256 assets, 1,000,000 total asset vertices and triangles, 4,096 regions and regional rule rows, 1,000,000 input support cells, 10,000 placements, 200,000 query candidates, stack depth eight and 50,000,000 charged work units. Caller settings may reduce placement/candidate/depth/work ceilings. Individual assets also obey asset-library limits. Count checks happen before expensive array growth; geometry-query work and per-region eligibility calculations share the engine allowance.

Search tries at most `max(32, 24 * desired_new_count)` base attempts per region. Exhausting this finite recipe search reports underfill. Hitting a hard candidate/work/output limit throws and retains the old caller-owned result. Requested population above the configured output limit also throws; it is not silently clamped. Scratch consists of sorted pointer/index tables, transformed polygons, accepted collision boxes and staged output. Input assets/mesh, old document output and successor can coexist; these cardinality limits are not measured Max process-memory or interactive-latency guarantees.

## Verification and remaining gates

`arrangement_tests.cpp` has sixteen suites independently checking deterministic output under reordered assets/regions/cells and independent region selection, seed changes, analytically known target counts, density/empty-space/styles, anchor/yaw/scale/full-bounds transforms, geometry refusal and footprint spacing, authored height variation, actual changed cluster positions, real parented flat-book stacks and ornament-on-tray stacks, protected ancestry and failure retention, selective regeneration, removed regions versus protected bindings, current sampled-region membership, category/mask/weight choices, malformed protected graphs and hard budgets. Regional cases use independently known 400/1,600 mm2 footprints for counts, multiplier changes, mask precedence, exclusion, protected/selective counts, stack prohibition, rule order and malformed/bounded policies. Its fixture query has analytic rectangular support and box spacing. Concrete precision/collision query suites separately prove holes, mesh obstacles, per-source interior classification and access sweeps.

`integrated_arrangement_tests.cpp` has four suites connecting the real furniture query to generation on a TV console with a separately captured television-foot obstacle, and three open-shelf layers with a closed divider. Known rectangular dimensions provide independent footprint, edge, spacing and divider collision oracles. It checks actual accepted rerolls, book stacks, protected failure, locks and selective regeneration. Regional cases remove unlocked stacks, preserve excluded identities, restrict categories and demonstrate actual accepted/blocked placements for opposite front directions on a board with a known rear wall, including protected revalidation. Admission regressions cover finite yaw of 1e308 degrees, legal high spacing, accepted-obstacle counts up to 10,000, rejection above that ceiling and excessive build-work settings. These are procedural box fixtures; they do not establish general imported-furniture quality.

The numerical milestone does not establish production renderer support, large asset-library performance, visually preferred arrangements, true dynamic stability, arbitrary furniture recognition or Max persistence/Undo/UI quality. Those remain distinct host and artist acceptance gates. No Max or computer-use action is needed to run native tests through `tools/build.py --core-only` after the arrangement targets are present.

The pinned native build `python tools/build.py --core-only --output build/core-region-policies-agent-02` compiled without warnings and passed all six CTest targets, including sixteen arrangement, thirteen furniture-query and four integrated arrangement suites. Host bridge/UI publication and frozen SDK qualification remain separate checks.

The subsequent query-only pinned MSVC `/W4 /permissive-` build in `build/query-obstacles-agent-01` compiled without warnings and passed seventeen query suites. Four added suites independently verify obstacle-top support rejection, static collision, closed-solid containment, two-sided open-screen access, regional front override, caller-applied rotation/translation, input-buffer independence, combined vertex/triangle/body limits and duplicate IDs across scopes. The host must separately bind, persist and invalidate its independent obstacle references; this query change alone does not capture the rest of a Max scene automatically.

## Regional and round-offset admission correction

The native24 before-probe receipt in `build/quality-admission-before/` pins matching headers, libraries and the two unmodified regression probes. Its seed-1 clustered fixture accepted an A-tagged accessory on excluded same-height B and failed the subsequent locked Generate. The corrected integrated suite checks both excluded and category-masked B across 32 seeds, independently checks all 20 × 20 mm physical footprints against A's 30 × 30 mm board, locks every result and regenerates, and exercises the charged work limit.

Rounded inward clearance still uses `ceil(clearance_mm * 1000)` integer units and arc tolerance 0.25 integer units (0.00025 mm). Before Clipper offset tessellation, a charged preflight follows the pinned `Group`, `OffsetPoint` and `DoRound` branches: inward convex corners generate three cleanup points; actual rounded concave/hole corners use the radius/arc-tolerance/turn-angle step count, with one extra vertex reserved for rounding. It rejects an estimated raw join output above 65,536 vertices, combined subject/join complexity above that limit, or a conservative quadratic polygon cost above the remaining work. No reduced clearance or coarser arc fallback is substituted. The ordinary post-offset result admission remains active.

This is a bound on admitted raw join tessellation, **not a proof that every Clipper finishing-union temporary or allocator is capped by that vertex count**. A conservative preflight may reject geometry that cleanup would have simplified. The query regression distinguishes a giant ring's excessive rounded-hole expansion from the same clearance on an admitted convex rectangle, checks reversed parent-patch orientation, remaining work, unchanged boundary rejection and an analytically valid/invalid rounded concave gap.

The incremental native retest in `build/core-quality-admission-agent-01/all-corrected-tests.log` passes nine CTest targets and 92 PASS suites. That directory preserves the initial failed test/policy iteration; its original receipt is not a fresh frozen-source qualification. The identical two-probe harness subsequently passes in `build/quality-admission-after/`. Matched fresh SDK/host qualification remains the root integration owner's separate gate.
