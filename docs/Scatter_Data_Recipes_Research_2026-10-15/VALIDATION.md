# Proposed validation campaign

These tests are **not executed by this research task**. Historical measurements are identified in the [report](README.md); this plan defines what future implementation must prove in owned disposable **Max 2027** profiles/scenes. Preserve artist sessions, original scenes, installed plugins and previous receipts. A stalled host test should be reported with its last completed stage, timeout and owned process identity, rather than replaced by an unsupported pass.

## Record once per run

Record branch/HEAD and dirty scope; source/generated script and native hashes; loaded paths/hashes; exact Max/SDK/renderer version; scene and external asset hashes; system units; time/frame rate; viewport mode and camera; candidate/accepted/shown counts; seeds; update mode; active filters/spacing/Relax. Freeze the actual tested pair before collecting results.

Instrument separately: host evaluations and mesh/map copies, geometry/field preparation, candidate generation, filter queries, source selection/transform preparation, collision checks, publication epochs, preview preparation, buffer uploads, draw submissions, wall/CPU time, cancellation latency and peak memory. Match IDs and full source/transform/anchor records, not just counts or pictures. Retained output with increased work counters is deterministic recalculation, not a cache hit.

Use cold and warmed runs. For performance, retain individual observations and median/p95 over a declared sample count, plus machine/context. A synchronous redraw timer is not presented FPS. Include recording overhead and competing processes. A host conversion/export can dominate cost; do not present its total as scatter solve time.

## Small fixtures with known answers

| ID | Reproducible fixture / action | Required result |
| --- | --- | --- |
| G01 Evaluated stack | 10 m plane with a modifier that raises a known region; scatter before/after and compare with the evaluated mesh | Anchors follow the evaluated result, not the unmodified base. Reverting settings restores the qualified output. |
| G02 Transforms | One sloped triangle under translation, rotation, scale `(2,1,0.5)`, reflection `(-1,1,1)`, object-offset transform and a parent transform; repeat with a WSM | World point/area/normal agree with independent math and the declared winding policy. No double transform. Singular scale is rejected without corrupting output. |
| G03 Normal modes | Two triangles sharing geometry but separated smoothing groups; then explicit corner normals | Geometric slope remains unchanged by shading-only edits. Any optional smooth orientation follows the correct corners and does not average the hard edge. |
| G04 Map seams | Two adjacent triangles whose shared geometric vertices have distinct map-corner values; set the selected component to known values | Correct face-corner barycentric interpolation. Test 0, 1, negative values, range remap, invert and nonlinear response. |
| G05 Display versus data | Keep Data Channel Vertex Output fixed; change display colors/Normalize Display. Then change actual output component | First action does not change numeric mask/placements; second invalidates the relevant field. Measure reads and recomputation separately. |
| G06 Topology | Change face count; then change connectivity/order without changing face count. Include existing paint/Edit anchors | Both incompatible bindings are detected; no stale face-index reuse. Same face count is insufficient as a topology identity. |
| G07 Final anchor | Move candidates across a channel seam, slope boundary, altitude threshold and Band edge, with Keep on surface | Eligibility uses the resulting anchor; source lift does not masquerade as terrain altitude. Relax/cleanup movement repeats required checks. |
| G08 Curvature | Plane, sphere, cylinder and saddle, each at two resolutions; add noise, an open boundary and skinny triangles | For authored DCM input, copied values match its actual output. For any future native estimator, compare declared analytic quantities/tolerances; no claim that DCM numbers equal physical mean curvature. |
| G09 Velocity | Static plane, translated plane, rigidly rotated plane, vertex-deforming plane, changing-topology mesh; separate animated source | Static velocity is zero; compare stable-anchor finite differences in seconds. Separate source shape motion. Topology mismatch produces an explicit unsupported/missing correspondence outcome. |

For G02, an independent normal oracle can use `normalize(cross(Bworld-Aworld,Cworld-Aworld))`. Compare a transformed authored normal using inverse transpose with the selected reflection convention. Test the convention itself, not just whether two implementations happen to make the same mistake.

## Ownership, deterministic results and avoided work

| ID | Procedure | Acceptance |
| --- | --- | --- |
| D01 Static idle | Warm one 20k-candidate layer, then 200k across two receivers. Observe 60 seconds without interaction | Zero additional Cyrus-caused geometry/map copies, solves, preparation and uploads; no publication change. Cheap timers may run. |
| D02 UI and unrelated selection | Open/switch every relevant panel 100 times; select an unrelated object 100 times; scrub unrelated animation | Static placements and solve/preparation/upload counters unchanged. Record cold UI construction independently. |
| D03 Independent layers | A/B/C have separate receivers and no pair rules. Change B density/mask/source settings | A/C IDs and full transforms unchanged; no A/C receiver generation. Shared validation/publication work is logged separately. |
| D04 Explicit dependency | Add A–B spacing; alter A radius/scale. Keep C independent | Reconsider B acceptance as needed; C remains independent. Compare with full reference acceptance, including chained conflicts. |
| D05 Density receiver add | Twenty equal 1 m² planes, 500/m², no caps/Relax/collisions. Add a distant 21st; remove it; reorder list | On unchanged receivers, original 10k candidate transforms/sources/IDs survive. Density should rise to 10.5k for this exact uncapped fixture. Measure each cache stage. |
| D06 Fixed Total add | Same fixture, fixed total 10k | Quotas redistribute; total stays 10k before any rejection. Compare each surviving local ordinal and source/transform. Do not demand retention of all original points. |
| D07 Mask independence | Capture unmasked rows, apply a known ramp, then change response curve only | Surviving IDs/source choices/random transforms match the baseline if no dependent motion/acceptance effect. At weights exactly 0 and 1 test exact exclusion/retention. |
| D08 Probability composition | Enumerate candidate IDs and their actual separate random channels for two constant masks | Current separate-gate result matches its reference. Do not require the exact same set as one combined threshold. Statistical expectation is separate from exact deterministic membership. |
| D09 Paint overlap | Two areas on one receiver; paint/erase overlap; remove and restore receiver; test unsupported projected geometry | One candidate per owner; current max-density/scale winner semantics hold. Missing receiver keeps authored document inactive. Unsupported paint projection fails clearly. |
| D10 Manual / Live | Warm output; change channel/paint/settings in Manual; browse/redraw; explicit Update. Repeat in Live | Manual keeps published rows until explicit action. Live schedules relevant work once after coalescing. Unrelated animation cannot consume Manual edits. |
| D11 Same-scene persistence | Save owned scene, close private host, reopen matching build; compare; test Undo/Redo/copy | Compare authored state, stable IDs and output under exact inputs. Test saved system units separately from unsupported Paint/Edit rescaling. |

Do not run D05/D06 with collisions or Relax and then blame legitimate changed acceptance on randomness. Add those as separately named tests with their own expected dependencies. Record capped Density separately because it shares quota redistribution behavior.

## Preset, recipe and storage tests

| ID | Procedure | Acceptance |
| --- | --- | --- |
| R01 Existing categories | Save/apply/capture each current supported category, including graph handles/sample-only curves | Exact typed field/domain round trip; scene references preserved; animated/wired destination rejection leaves state unchanged. |
| R02 Three-layer round trip | Save Everything for Canopy/Shrubs/Groundcover with actual Paint, import into a fresh controller | All authored fields, Paint bytes/holes, order, seeds, source weights, group/Band membership and pair rules preserved modulo supported ID remapping. No cached output IDs reused. |
| R03 Missing assets | Remove one required model, field channel, receiver, path and texture, one at a time; also test offline shared root | Resolver reports exact affected roles. Default blocks commit. Any explicit incomplete-import option keeps affected layers inactive and is tested separately. |
| R04 Name collisions | Two models with identical names; same-named incompatible terrain; repeated import | No automatic name-based retargeting. New display suffixes do not affect identity. All internal references remap correctly. |
| R05 Substitution | Replace one source role with different size/pivot and two rows referencing the same model | Preserve row settings/groups; update bounds and dependent spacing. Show expected source footprint/pivot change. Do not deduplicate intentional rows. |
| R06 Units | Identical physical fixtures in metre, centimetre and inch scenes | Distance and area/density conversions preserve physical intent; dimensionless values unchanged. Approximate float tolerances declared; no blanket bit-equality requirement. |
| R07 Coverage | Default Save Everything retains Paint; restore to compatible terrain, then try a different terrain/frame/units. Separately choose Portable planting rules with an omission | Complete mode never omits Paint. Compatible restore preserves original payload and coverage. Incompatible data is retained inactive or activation is blocked. Portable omission is explicit; paint-only layers never become full-surface scatter. |
| R08 Cancel and rollback | Cancel resolver; inject failure after creating one imported owner/asset; force late authored commit failure | No partial new scene state or modified pre-existing owners. One successful import creates one Undo; Undo/Redo restores all references. |
| R09 Calculation failure | After successful authored import, fail geometry/field admission, source preparation and late display staging | Last complete publication retained across owners. Pending authored state/error is clear. Test after the staging boundary, not only early validation. |
| R10 Files | Empty, truncated, duplicate-key, future-version, malformed UTF-8, oversized, invalid-number and missing-payload files | Each fails boundedly; healthy library entries remain usable; no execution or partial scene mutation. |
| R11 Atomic save | Read-only/locked directory, disk-full simulation, interrupted write, failed rename/replace, stale shared-library version | Original remains readable or recovery is explicitly available. No success reported before commit. Network/power-loss durability requires its own filesystem test. |
| R12 Browser | 512 and 2,000 metadata entries, mixed damaged files, bounded thumbnails; cold/warm local and disconnected network root | Paging/lazy loading works; cancel/close remains responsive; no Max geometry evaluation or scatter solve. Keep the current category browser's 512 cap unless deliberately expanded. |

The example JSON provided with this report can be checked for syntax, unique IDs and cross-references now. Those checks do **not** execute a recipe importer, validate a production JSON Schema or prove host behavior.

## Complete-save and Paint regressions

Added for the user's **Save Everything includes Paint** decision. These are required future implementation tests, not executions performed during this documentation revision. Build the actual full fixture from every supported field in [FIELD_MAP.md](FIELD_MAP.md); the illustrative JSON intentionally omits default fields and is not that fixture.

| ID | Procedure | Acceptance |
| --- | --- | --- |
| R13 Field and enum coverage | Compare the declaration inventory against current templates. Mutate each supported property, exercise every valid enum and invalid enum rejection; include native Paint/Edit/container records | Zero unclassified fields. Capture/import/capture preserves active and dormant values with declared units. Every unsupported nonempty authored record blocks complete export with its owner/property, rather than disappearing. |
| R14 Lossless Paint | Two islands and an Erase hole; two overlapping ordered areas; distinct layer/area density, inside/outside fades, density/scale flags, edge/inner scale, samples and editable handles; repeat with fading disabled | Native no-conversion payload hashes/bytes match, sampled signed distances/coverage and holes agree, curves remain editable, order/tie semantics remain unchanged. Imported documents are independent copies. |
| R15 Empty, disabled and orphan Paint | Save a disabled nonempty area, a cleared empty area, and an area whose receiver has been removed; save/reopen/import each | All documents/settings survive. Requested enabled state and unresolved state stay distinct. Empty does not mean missing; missing never means full surface. No data loss from a failed bind. |
| R16 Manual pending save | Warm output, alter density and Paint/fades in Manual without Update, then Save Everything and browse | File captures pending authored changes, not the published snapshot. Original rows/epoch and solve/preparation/upload counters stay unchanged. Active gestures require finish/cancel; save does not commit them implicitly. |
| R17 Stale owner and copy isolation | Change/delete captured owner or dependency while dialogs are open; import twice; edit Paint in one copy | Stale proposals cannot commit to a new owner by name/selection. Copies have independent native documents and remapped references; source scene/file and other import remain unchanged. |
| R18 Inactive import lifecycle | Choose Import inactive for incompatible Paint; save/reopen, Undo/Redo, supply a compatible binding and activate; fail a transfer | Original payload and requested state survive every step. No active output until required bindings resolve. Failed transfer preserves original and previous publication; unqualified transfer remains unavailable. |
| R19 Edit, radius and controllers | Include moved/deleted/copied instances, per-instance radius, inactive Edit modifier and a wired/animated parameter | Qualified adapter preserves authored records and correspondence. Unsupported cases block complete export and identify the exact limitation. No baked rows or silent snapshot substitute. Protected-edit behavior remains unchanged. |
| R20 Dormant values, roles and preferences | Nondefault unused transform ranges, disabled masks with maps, Auto with manual radius, all Band side/scale modes and inactive curves, container policy, external spacing partner; Add and Import setup | Full semantic graph retained. Missing external dependency is not dropped. Add preserves destination Manual/Live/budgets; new setup applies preferences after commit. No auto-started brush/overlay, unrequested asset mutation or extra Live solve. |

Use metre/centimetre/inch fixtures for typed fields. Until native Paint/Edit conversion is qualified, exact rejection/inactive preservation is the expected result for incompatible saved-unit context; a visually similar but altered footprint is a failure. Explicit later transfer requires independent area/holes/metric oracles and a loss report.

Audit aggregate limits with many small Paint documents and one maximum-size document, decoded byte limits, combined contour count, old/new/Undo memory and destination root admission. Files that exceed bounds fail without truncation. Test attachments with wrong hashes, path traversal, missing payloads and conflicting typed summaries. Interrupted multi-file save must not expose a manifest pointing to partially written Paint.

The [implementation plan](IMPLEMENTATION_PLAN.md#core-validation-versus-optional-studies) selects core tests. Curvature estimators, velocity, generic remesh transfer and asynchronous cancellation are separately authorized future studies, not features required merely to save Paint.

## Performance targets to negotiate and measure

Use targets as acceptance proposals, not claims about current performance:

- Warm metadata-only UI actions: aim for p95 under 100 ms on the agreed local fixture. Record cold panel creation separately; the current heavy controller-selection limitation is not erased by this target.
- Paint border feedback: aim for p95 below 50 ms from processed input to prepared feedback on a declared receiver/contour size. Actual presented latency and tablet feel require physical measurement, not just callback time.
- Native cancellation: aim to acknowledge cancellation within 100 ms of a numeric chunk boundary. Report host evaluation calls that prevent that target; never claim arbitrary modifiers are interruptible.
- Incremental edit: measure receiver copies, generated candidates, filtering, acceptance, publication and uploads independently against a full reference solve. Require exact qualified output and a meaningful avoided-work reduction before retaining complexity.
- Memory: report copied input, prepared geometry, candidate rows, source samples, old/new publication coexistence and display resources. Admission must fail before uncontrolled growth and preserve old output.

Stress levels: 20k, 200k and up to the current one-million root candidate bound, with simple boxes first and representative heavy assets second. Run each with Point Cloud and retained Mesh under identical shown subsets/cameras. A faster low-detail preview is not evidence that full rendering or placement solving improved.

## Vendor follow-up tests only if decision-critical

Use licensed capabilities and disposable profiles. Forest Lite cannot answer Pro-only curved terrain/library-editor questions. A new vendor campaign should pin installed/loaded bytes and use separate change/capture callbacks after the event loop has settled. Earlier single-callback Chaos exports were excluded because they could read stale results.

Priority gaps: Forest Pro painted coverage on curved/stacked geometry; Chaos same-face-count topology edits and nearby-sheet brush leakage; passive update observation without forcing a capture update; and the exact contents/limits of Chaos configuration I/O or a multi-owner exporter. Configuration save/load itself is documented in [the revised source register](SOURCES.md). None blocks a Cyrus recipe with explicit binding and complete Paint storage.

If a host stalls, preserve its logs and last completed request; inspect whether that request completed before retrying. Stop only a verified owned process if necessary. Report the unmeasured case and continue documentation/source work; never interact with the artist's working session to manufacture an answer.
