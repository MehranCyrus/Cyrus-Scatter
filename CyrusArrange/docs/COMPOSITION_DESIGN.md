# Native book rows and height balance

Status: **0.1.2 native implementation and focused tests are complete; matched SDK/host qualification remains separate.** The contract below was designed against immutable 0.1.1 and is now implemented in the native composition types, arrangement engine and fit query. It is not a feature claim for the archived 0.1.1 payload. See the scoped implementation evidence at the end of this document; earlier release receipts do not qualify this successor.

## What the current controls do

The implementation in `arrangement.h/.cpp`, `assets.h/.cpp`, `placement_queries.h/.cpp`, `arrange_document.h/.cpp` and `ArrangeWorkflow.ms` establishes these distinctions:

| Existing behavior | Actual meaning | Composition still missing |
| --- | --- | --- |
| Grouping / `cluster_strength` | Sometimes chooses a point near an accepted prop; also changes stack probability | No persistent adjacent-book relationship or common facing |
| Scale variation / `height_variation` | Uniform scale within the asset's minimum/maximum; fixed-size assets remain unchanged | No height-profile or visual hierarchy score |
| Minimal / Balanced / Layered | Changes population factor and stack preference | Balanced is not a measured left/right height-balance objective |
| Authored stacking | Separate placements with real `parent_stack_id`, compatible top patches and validated support | Not a side-by-side book row |
| Registered Max source group | Captured as one asset with complete geometry/bounds; generated as one placement | Its constituent source objects are not independently selected or arranged |

For example, the starter three-book stack is a prebuilt model, even though its source factory creates three book groups. Generating three independent upright placements, recording their ordered membership, common facing and pair spacing would be a genuinely generated composition relationship. The initial extension should make this distinction visible.

## Smallest useful scope

Implement **BookRow** for TV consoles and open shelves only: two to six independently selected upright Book assets, front-aligned, side by side, with an authored internal gap. Every member remains a normal placement/output node. A native group record describes their relationship; no Max group head is necessary.

Add a final, optional **Row height balance** pass. It translates newly generated, unprotected rows among at most eight alternative anchors in their current region. Standalone props, existing stacks and protected rows stay fixed. The score considers their actual heights, so a row can move away from an already tall side. It does not resize assets to invent height diversity.

Defer leaning books, bookends, alternating upright/flat recipes, arbitrary accessory graphs, cross-compartment compositions, dining place settings, dynamic stability and learned aesthetic evaluation. Those require separate semantics and acceptance tests. Existing ordinary props and authored stacks remain useful alongside rows.

## Proposed portable contract

The public types are in `include/cyrus_arrange/composition_types.h` and `arrangement.h`. Fields/spans append with defaults rather than reordering existing aggregates. `Placement` and the existing `ArrangeSettings` fields are unchanged.

| Type / location | Proposed addition | Contract |
| --- | --- | --- |
| `Asset` | Optional `BookRowProfile` containing a cardinal local spine face: −X, +X, −Y or +Y | Explicit author intent; absent means ineligible for rows. Only category Book is admitted. The local Z-up contact frame still applies. |
| New `CompositionOptions` | `book_rows=false`, `minimum_books=2`, `maximum_books=6`, `row_gap_mm=3`, `row_height_balance=0` | Min/max in 2..6, finite gap in 0..1,000,000 mm, finite balance in 0..1. Enabled features require TVConsole/OpenShelf. |
| New `CompositionGroup` | Nonzero stable ID, kind BookRow, region ID, ordered member placement IDs, saved front vector and saved internal gap | Two to six unique members, one group per placement, one region/support plane, all members directly furniture-supported. |
| `ArrangementRequest` | `CompositionOptions composition` and `span<const CompositionGroup> previous_groups` | Borrowed synchronous inputs; empty/default preserves the existing branch. |
| `ArrangementResult` | `vector<CompositionGroup> groups` and bounded composition counters | Member placements remain in `placements`; no hidden objects or host handles. |
| `PlacedObstacle` | Default-zero composition group ID | Derived from validated group records; not a new field on every saved Placement. |
| `PlacementProbe` | Optional same-group spacing descriptor: group ID and gap | Uses the saved row gap only when the accepted obstacle has that same nonzero group ID. All other pair spacing uses the ordinary setting. |

Use existing regional front directions as the row-facing basis. An enabled composition region must have an explicit `RegionPlacementRule`; the current host already supplies a rule for every active registry record. This avoids guessing a query implementation's private default direction. Keep regional exclusions/category masks/stack permissions authoritative. Do not infer upright eligibility from a name, Book category or bounding-box aspect ratio: the current library deliberately contains both upright and flat Book assets.

Spine-face metadata selects an orientation; it does not certify physical stability. Only existing allowed yaws that align the authored spine side to the regional front are eligible. If none align within the documented angular tolerance, report no compatible row orientation. Do not silently add rotations. Initial row poses remain upright with yaw only.

Saved internal gap is a property of an existing relationship. Changing the generation gap affects new rows; protected rows retain and validate their saved gap. Turning Book rows off stops new rows but preserves valid protected row records. Changing the regional front or removing a protected member's row capability must fail explicitly if its retained relationship can no longer be validated.

## Row generation and real fit

1. Preserve the current weighted asset/category selection. When its selected Book has row capability and at least the minimum member/count/target capacity remains, attempt a row. Choose its size within min/max and remaining capacity; select other eligible upright books using existing weights, stable sorted asset IDs and a row-specific random stream. Repetition of the same asset is allowed.
2. Choose allowed facing yaws and ordinary authored scales. Project each complete collision box onto the region's lateral/front axes. Compute total row width as the sum of projected widths plus `(count - 1) * gap`. Align spine-side envelope faces to one front line; variable book depths extend behind it. This aligns conservative envelopes, not inferred printed spines.
3. Place the row about a deterministic sampled anchor. Derive each member's contact anchor from its full-box offsets, including off-center source pivots. All contacts share the region's support height. Require each member anchor to belong to that current sampled region, in addition to precise support checks.
4. Validate every full footprint, edge margin, furniture/external-obstacle collision, access rule and accepted-prop collision. Append already validated siblings to scratch obstacles with the row ID and saved gap. Never substitute the row's aggregate box or sampled center for member fit validation.
5. Commit the entire row to the staged result only after every member passes. A failed last member discards its siblings, category counters and group record together. Query attempts, rejection diagnostics and work already spent remain charged. After bounded row attempts, an ordinary eligible single-book attempt may fill the slot; report unsuccessful row attempts rather than claiming a row was made.

The present query checks static overlap with every accepted box before applying spacing. Preserve that order: same-row spacing overrides **only spacing**, including when gap is zero; it does not disable collision. Test both a 3 mm book gap under ordinary 20 mm prop spacing and a penetrating pair. Unrelated props and other rows must still maintain ordinary spacing.

Each row book consumes one population slot and one Book category count. A five-book row is five props, not one item against density/category caps. Existing density remains an approximate target derived from sampled area and asset footprints; this extension does not promise a physical coverage percentage. The ordinary maximum count and all regional masks may prevent a row entirely.

Initial row members cannot be stack children or support generated stack children. Ordinary flat-book/tray stacks continue outside rows. Do not overload `parent_stack_id` to create sideways relationships or to obtain its spacing exception. This restriction keeps the new relationship model small and avoids implying that a narrow upright book top is a useful support.

## Explicit height-profile objective

Run the balance pass after all ordinary generation, so it observes final standalone props and stacks. Process only newly generated rows in selected regions, sorted by group stable ID, once each. Protected rows are immutable obstacles and contributors to the score. Retained rows outside selective scope never move.

For each supported region with one horizontal support height `z_r`, derive a horizontal lateral axis from its authored front vector. The implementation uses the minimum sampled-cell Z as its canonical reference and admits at most 0.01 mm cell-height variation; reordering cells cannot change the reference. Divide the projected sampled region extent into sixteen fixed bins. For bin `i`, let `H_i` be the maximum full collision-box top above `z_r` among props whose projected intervals overlap it; an empty bin is zero. Include stack children at their actual world top. Taking a maximum prevents double-counting overlapping parent/child silhouettes. This is a conservative front-profile proxy; sampled region extents guide scoring, not fit.

With normalized bin centers `t_i` in [−1,1], define:

`B = abs(sum(H_i * t_i)) / sum(H_i)`, or zero when the denominator is zero.

This measures the lateral first moment of a height envelope. It is not object mass, support stability, a camera-specific rendered silhouette, height diversity, or a claim that symmetry is always artistically best. A central tall object can score well. It is initially per region, not a whole-console balance score across separate shelf compartments. Regions without a coherent horizontal support plane reject this optional feature rather than selecting an arbitrary base height.

For each movable row, keep its member assets, scales, yaw, internal geometry and height fixed. Remove only its own boxes from scratch obstacles. Include its original already-valid pose plus at most eight deterministic alternative translations sampled from the same region, with every member revalidated. Choose the minimum:

`S(q) = (1 - b) * D(q, original) + b * B(profile including q)`.

Here `b` is Row height balance; `D` is nonnegative normalized translation distance, capped at one using the sampled region's horizontal diagonal. The original has `D=0`. Keep the original on equal scores; resolve other ties by proposal index. With `b>0`, selecting against the original makes the measured `B` non-worsening for each accepted move. At `b=0`, bypass the pass entirely. This is a local bounded search with a movement penalty, not a global aesthetic optimizer.

Score only legal candidates; failure of all alternatives keeps the original. A hard budget exception still aborts the successor. Use the same sixteen-bin construction and stable iteration order for every comparison. Work to construct profiles and evaluate proposals must be charged. The original arrangement remains valid even if it is already the best candidate. Fixed-size assets remain physically unchanged. Additional authored book heights improve variety; the 0.1.1 single upright starter model cannot produce different physical book heights by itself.

## Determinism, locks and selective regeneration

Use separate hash domains for row generation, row group IDs, ordered member IDs and the balance pass. Include seed, persistent region ID, row attempt and member slot as appropriate. Sort input identities and check nonzero/duplicate IDs explicitly; a hash is not a uniqueness proof. Preserve the current document GUID namespace when resolving group/output identities, including clone remapping behavior.

Default options with no previous groups must execute the current solver path without extra random draws. Require a golden native comparison proving identical existing placement IDs/poses, stats and warnings in that case. With composition enabled, changes in obstacles, eligibility, policy, seed, work limits or algorithm version can change output; do not promise unrelated global edits never affect acceptance.

Extend the existing protection closure to include complete composition groups as well as complete support-connected stacks. Locking one row member therefore protects its whole row. First milestone rows cannot have stack edges, but reject a malformed saved graph rather than quietly detaching it. Validate protected groups and all their member poses before generating successors. A missing member, stale support identity, changed incompatible asset/front, overlap or broken front alignment/adjacency rejects the successor and preserves previous output.

Structural group validation applies to all input records. Full regeneration drops unprotected old groups and their old members, including groups on removed regions; selective regeneration protects all unselected members and therefore fails if their current bindings are missing. Do not validate discarded groups against deleted current regions before deciding protection. There must be no dangling group records after selective regeneration.

Explicitly moving one member does not automatically redefine its row. Native lock/synchronization must capture and validate all affected output poses before accepting a protected group; an invalid relationship reports that the row must be unlocked/regenerated. No automatic member nudging, hidden Max grouping, partial row lock or Detach command is needed for this first milestone.

## Persistence, preview, Undo and UI

The preceding 0.1.1 document codec is schema 3, its asset-library codec schema 1, and its registry codec schema 1. The 0.1.2 successor uses versioned document composition data and asset-library schema 2 for row profiles, with explicit old-format admission owned by their respective codecs. Registry schema stays unchanged because composition settings are setup-wide. No unversioned struct dump or silent modification of an existing saved file is needed.

Validate group counts and all referenced member IDs during bounded decode, then again against captured current data during Generate. Extend immutable `DocumentState` with composition options/groups. Profiles live with native Asset metadata and portable `.cyalib` records. Rebinding must revalidate the profile and retain authored intent only when valid. Imported library IDs and group/member IDs are separate concerns: library import remaps asset identities, not historical output groups.

Generation, profile/settings edits, locking and full group publication must use the existing complete-successor and single Undo transaction. Publish individual member nodes plus native group state atomically; a failure must leave no partial row or stale output references. Save/reload, Undo/Redo and cloning retain group membership without relying on node names. Clone/merge reference ownership stays with the native document layer.

Preview must run the identical row/balance solver and capture all new settings/profile/group freshness through the native revision/input epoch. Commit must reproduce that staged result using the same registry override. It must not consume an extra RNG stream or perform a second nondeterministic layout search. Preview can show ordinary member boxes; dedicated row overlays are optional later.

Minimal UI additions:

- Asset Library: explicit Upright book row eligibility and Spine side; existing scale/yaw controls stay authoritative. Show that a prebuilt grouped source is still one asset.
- Composition: Book rows, Books per row min/max, Within-row gap (mm), and **Row height balance** with a tooltip explaining translation of unlocked rows and physical-size preservation. Enable for TV console/open shelf; unsupported furniture does not acquire hidden behavior.
- Selection/lock feedback: show row membership/count and explain whole-row protection when one member is locked. Existing selected-region regeneration is sufficient; no separate group editor is required.

Keep Grouping's current proximity meaning and Scale variation's current physical-range meaning. Do not rename existing Balanced style into a promise that its zero-default new balance control is active. Native code owns all recipe generation, relationships, scoring, validation and serialization; MAXScript supplies controls and typed command arguments only.

## Work and memory admission

Retain existing hard ceilings: 256 assets, 4,096 regions, 10,000 placements, 200,000 queried candidates and 50,000,000 solver work units, reducible by caller settings. Bound groups by `floor(max_placements / 2)` and at most 5,000; total member references cannot exceed the placement ceiling. Enforce one-group-per-member and two-to-six membership before allocation.

Use one reusable scratch obstacle buffer with at most the accepted output plus six pending row members. The balance pass needs at most sixteen profile bins and eight alternative row transforms plus the original, not eight copies of the entire scene/asset geometry. Charge candidate/work for every tested member, including discarded and balance candidates. Charge profile scans, closure, sorting, membership checks and pair tests. No nested unbounded recipe search or generic constraint-graph optimizer is needed.

Existing finite base-attempt limits still apply. Row formation, exact checks and balance can exhaust budgets sooner than simple scatter; expose requested rows, successful rows, discarded row attempts, alternative anchors tested and rows moved. Measured latency/memory needs fresh native and isolated Max fixtures; existing gallery timing is not evidence for this extension.

## Required acceptance tests before a feature claim

| Area | Independent test or gate |
| --- | --- |
| Genuine composition | Three separately selected assets produce three placement IDs/nodes and one ordered row record; a three-book prefab remains one placement with no generated row record. |
| Metadata/orientation | Flat Book without row profile is never selected into a row; off-center anchors and all four authored spine sides align correctly; no compatible allowed yaw produces a clear bounded failure/fallback. |
| Fit | Analytic narrow shelf, hole, divider and external TV obstacle; every member's full footprint and box fit. Last-member failure commits zero row members/counts. Repeat with a member spanning an excluded/disconnected region. |
| Spacing | Internal 3 mm gap is allowed under global 20 mm spacing; static penetration fails even at zero row gap; unrelated props/other rows retain global spacing. |
| Counts/limits | Rows consume N density/category slots, respect caps/masks/exclusions and cannot exceed remaining targets; extreme/malformed profiles/groups and hard budget exhaustion preserve caller state. |
| Determinism | Reordered assets/cells/regions/group records, repeat seed, changed seed, group/member IDs and default-disabled exact baseline comparison. No extra random draws from an unused balance pass. |
| Balance | Crafted independent 100/200/300 mm box assets at scale 1, a known tall prop on one side and eight known alternative anchors. Compute expected sixteen-bin score independently; verify an available better row move is chosen, original wins ties, score never worsens and no scales/standalone/stack/protected poses change. |
| Relationship retention | Lock any member, retain entire row unchanged; invalid moved member, missing parent/member/region, front/profile edits and protected collisions fail atomically. All-unlocked removed regions drop cleanly; selective regeneration preserves unselected rows. |
| Native codec | Bounded new document/library round trips, malformed version/count/membership/reference rejection, authored profile import/rebind. Prior baseline files remain preserved on unsupported input. |
| Max lifecycle | Real per-member output nodes, Preview/Commit identity, source edits, whole-row lock capture, Undo/Redo, save/reload, clone/merge, deleted outputs and injected publication failure with no partial nodes/state. |
| Artist evidence | Original full-size multi-height book sources on TV/open-shelf fixtures, fixed seed comparison with rows/balance off/on, actual unchanged-output renders and measured process/command timing. No hand-positioned props to illustrate a claimed generated relationship. |

## Native implementation evidence and limits

Implementation began after the qualified immutable 0.1.1-r3 archive snapshot. Native source ownership for this work covers `composition_types.h`, `arrangement.h/.cpp`, `placement_queries.cpp`, `tests/composition_tests.cpp`, `tests/composition_golden_tests.cpp` and its golden data. Asset metadata/library codecs, document persistence, SDK bridge and UI are integrated by their separate owners and need their own matched evidence.

Before changing the numerical core, the golden harness was compiled using headers extracted from `dist/CyrusArrange-0.1.1-r3/CyrusArrange-0.1.1-Source-and-Examples.zip` and linked to the frozen native21 core/Clipper libraries. `build/composition-baseline-011-agent/receipt.json` pins the archive, extracted headers, frozen libraries, harness and golden hashes. The 6,609-byte `tests/data/composition_disabled_011.golden` has SHA256 `4ad61e2c4dfe313fabce484e81c92a4a5a4a66139c35c3c8c5a54d375758752b`. Six scenarios compare exact member IDs, double bit patterns, counts, rejection/work counters and warnings: open shelf, layered stacks, locked selective regeneration, TV console, refused/underfilled output and the real furniture query. Existing assertion suites remain intact.

The focused build/retest logs under `build/core-composition-agent-01/` show ten passing composition suites plus passing baseline/golden/document targets. Their cases include an independent quarter-turn box oracle; native footprint/collision checks around an 80 × 100 mm furniture hole and external TV foot; independent low overhead; zero-gap penetration; third-member rollback; category caps; all four authored spine faces/off-center anchors; disallowed yaw; seed/order invariance; tolerated plane-height reorder; protected profile/front/adjacency failures; removed unlocked versus locked regions; exclusions/masks; selective retention; mixed row/stack closure; malformed input and hard-budget failures.

The final fresh command `python tools/build.py --core-only --output build/core-composition-agent-02` has a **passed 0.1.2 receipt**, all nine CTest targets passing, all 90 reported PASS lines, no compiler warnings and unchanged hashed sources throughout the run. The golden target reports its six immutable scenarios as one suite. This is native-only evidence; no Max process was launched by this work.

The height oracle independently builds the sixteen-bin profile from known fixed-size boxes and records complete legal row candidate boxes through the real fit query. It verifies the final balance equals the minimum legal candidate score, original zero mode issues no balance attempts, protected props/scales stay unchanged, and an actual translation improves the metric. Its reproducible witness uses region ID 1, a 1,000 × 400 mm board at Z 0/grid 25 mm, upright assets IDs 1/2/3 with sizes 20 × 100 × 100/200/300 mm, and a locked 80 × 80 × 400 mm Plant (asset 4, placement 777) at (−350, −100, 0). Equal category weights, Book cap 3, Plant cap 1, density 0.05, empty space 0, spacing 20 mm, edge 10 mm, grouping/scale variation 0, three books per row and seed 1 produce metric 0.3828125 before balance and 0.2890625 at strength 1. Hashes depend on actual asset/region IDs; a host fixture with different IDs should search a bounded seed range rather than promise identical poses.

All geometry/query work shares the original hard budgets. Round inset outlines around holes can produce many polygon vertices; repeated rejected candidates can exhaust the work allowance even on a modest scene. That aborts the complete successor rather than silently reducing clearance or publishing a partial row. This implementation does not add a query/geometry cache or a latency guarantee.

SDK compilation, real node publication, Preview/Commit, Undo/Redo, save/load, source edits, clone/merge and actual artist renders remain separate matched qualification gates. Measured row behavior and this defined profile score do not establish broader visual taste, physical book stability or general interior-design quality.

## Explicit qualification of the immutable golden after regional admission repair

The original golden bytes and SHA256 above remain unchanged. Subsequent independent review found that its always-accept test double admitted three ordinary base anchors outside their sampled regions; one such base has two stack children. The regional membership correction intentionally changes that old invalid behavior even with composition disabled. It does not activate book rows or height balance by default.

The golden test now proves exact old stable IDs, asset/parent/region fields, position/yaw/scale bits, lock flags and relative publication order for **every valid old placement**. Requested/accepted/kept/underfill counts and warnings remain exact in all six scenarios. Locked-selective, refused and real-query scenarios retain every placement and every logical counter. Only charged work can rise due to membership scans or round-offset preflight; it stays within the hard limit, and the refused path retains its exact work count.

The deliberate corrections are enumerated rather than silently recapturing a new golden:

| Scenario | Invalid old placement IDs removed | Candidate/Boundary increments | Corrected replacement count |
| --- | --- | --- | --- |
| Open shelf | `07ce6ec83e7f9e8f` | +1 / +1 | 1 |
| Layered | `c525e73b7b4db988`, `b6d356eca73321dc`, `b0c0fbcb9b86f9e0` | +3 / +3 | 3 |
| TV console | `2d3e6ac95cc66f2f` | +7 / +7 | 1 |

Each removed anchor is independently outside the old fixture's known XY region bounds. Each new output is independently inside its recorded region; deterministic replacement records are exact, and all six corrected captures repeat bit-for-bit. The original 90-suite fresh receipt remains historical evidence for the earlier core. The corrected incremental retest passes 92 suites; fresh frozen-source SDK/host qualification must establish the revised successor separately. See `PLACEMENT.md` for offset-admission scope and the paired failing-before/passing-after probes.
