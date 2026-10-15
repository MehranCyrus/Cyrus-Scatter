# Recipe implementation plan — documentation only

15 October 2026. Planning baseline: Scatter **0.82.4**, scene schema **58**, `CyrusUnified1`, branch `codex/workflow-0.75`, HEAD `604e3aa3fd1c84c5ef128dc564f4abaf6f4978e4` plus existing dirty work. This plan implements the user's selected design: **Save Everything includes Paint**. It does not authorize coding, tests in Max, packaging, installation or Git publication now. **Phase 6 remains paused.** Work packages below are recipe planning units, not a renumbering or resumption of the eleven-phase program.

Use the [preset contract](PRESET_CONTRACT.md) for normative behavior, [field map](FIELD_MAP.md) and [parameter inventory](PARAMETER_INVENTORY.csv) for source correspondence, and [validation plan](VALIDATION.md) for evidence. Required contracts: F01/F03 ownership and dependencies; F02 stable randomness; F04/F08 scheduling and reuse; F05–F07 bounds/publication/threading; F09–F11 geometry, units and persistence.

## Intended artist workflow

1. Select one or more layers; **Save selected layers** opens a captured-owner dialog. **Save Everything** is the default. **Select all layers** is a shortcut. Show layers, Paint areas/holes, sources, Paths/Bands and external relationships before saving.
2. Give a name/tags and optional thumbnail. Save authored values, including pending Manual changes, disabled settings and original Paint. List dependencies that remain external. Report unsupported fields before writing; never silently downgrade to Portable rules.
3. Open the shared Library browser. Categories and recipes share navigation but retain separate formats. Selecting an entry only reads metadata/thumbnail. Choose **Add layers** or **Import setup** to start resolution.
4. Bind receiver/model/map/path/Analyzer/container/external-layer roles. Show actual field channel/component/range. Paint is already saved; display whether its receiver frame, geometry and units permit restore. Missing or incompatible data blocks activation, with a separate **Import inactive for later binding** choice where implemented.
5. Review one complete proposal. Commit one Undo; Manual waits for Update and Live coalesces the new work. Keep previous publication if calculation fails. The summary distinguishes saved data, imported authored state and successfully calculated output.

The browser is reached from the Layer manager and existing category buttons. The Layer manager continues to own scene order/selection; it is not duplicated in another application. No separate EXE, service or automatic background library scanning is needed.

## Delivery boundaries

**Required core:** full static authored capture; native Paint preservation and compatible restore; explicit retained unresolved state; ordered multi-layer roles/membership/spacing; source substitution; category preset compatibility; one Undo/rollback; bounded local storage/browser; exact field/default/error contracts; Max 2027 validation and a matched installer when a future implementation is authorized for delivery.

Full authored capture includes disabled values and supported per-instance Edit/radius work. If a setup contains a controller or native record without a safe adapter, its complete save is blocked with a field-specific explanation. A subset prototype cannot be presented as finished Save Everything. Stage R2 explicitly resolves these adapters or retains a disclosed unsupported capability gate.

**Separate follow-ups:** asset collection, arbitrary controller graphs, transfer to a different Paint coordinate domain, source/group merge, full setup replacement, typed parameter interpolation, density-field blending, snapshot/cache restructuring, smooth normals, native curvature and velocity. These do not delay preserving original Paint data. Existing object evaluation and placement semantics remain the reference.

## Work packages and dependencies

| Package | Depends on | Concrete output | Completion gate |
| --- | --- | --- | --- |
| R0 Contract and field inventory | Current source | Frozen mapping, all enum meanings, capture rules and unsupported capability list; fixture definitions | No unclassified parameter or native authored record. Design changes reviewed before implementation. |
| R1 Data model and bounded codec | R0 | Separate recipe codec, semantic validation, attachment manifest and canonical field comparison | Malformed/unknown/missing fields fail without scene access; round trips preserve all serialized values. |
| R2 Authored capture, Paint and Edit adapters | R1 | Complete selected-layer capture; lossless native Paint and supported Edit/radius capture; controller/reference audit | No save-time solve; payload byte preservation; all omissions explicit only in Portable rules. |
| R3 Dependency resolver and import proposal | R1/R2 | Bound roles, units, candidate/source requirements, compatibility report, fresh identity map and inactive-state plan | No scene mutation before commit; same names cannot hijack roles; invalid geometry/units cannot activate Paint. |
| R4 Transactional import and lifecycle | R3 | Add layers/new setup, staged native documents, one Undo, scheduling guard and rollback journal | Late commit/solve failure and Undo/Redo/save/reopen pass; independent siblings retained. |
| R5 Local library and artist UI | R2/R4 | Shared browser, Save Everything default, distinct Portable rules, bounded paging/thumbnails, overwrite protection | Browsing causes no evaluation/solve/upload; missing/offline/bad entries remain understandable. |
| R6 Qualification and delivery | R1–R5 | Matched source/native/scripts, reproducible Max 2027 receipts, docs and runnable MZP | Core acceptance matrix passes with explicit limits; artist testing delivered without installation. |
| R7 Optional asset/transfer operations | Core qualified; separate authorization | Host dependency collection, qualified frame transfer, replace/merge operations as individually scoped changes | No data loss, no silent retargeting; independent fixtures per operation. |
| R8 Measured engine improvements | Profiling demonstrates need; separate authorization | Shared snapshots or filter caches, followed only if needed by advanced fields/jobs | Reference parity plus reduced work counters; no idle/UI regression. |

R0's design inventory is supplied by this revision. Its executable enforcement and all implementation/host gates below remain unchecked. No release number is assigned to a work package; follow the small-step version policy when actual future delivery is authorized.

## R0 — freeze meaning before an importer

- [ ] Recheck current branch/HEAD, dirty source and handoff at implementation start; compare every declaration with the inventory and classify additions.
- [ ] Turn the field map into an executable allowlist of authored/captured-preference/remapped/derived/unsupported fields. Do not generate a generic `getPropNames` dump.
- [ ] Freeze recipe v1 records, units, enum tokens, graph domains, ordered arrays, reference namespaces, native payload headers and mandatory fields. No silent defaults from a later host class.
- [ ] Define exact partial-export omissions and the two independent completeness flags: authored setup versus bundled assets.
- [ ] Define `resolved`, `unresolved`, `unsupported` and `corrupt` states. Inactive import preserves requested enabled state and the original record; it is not successful activation.
- [ ] Define unsupported animated/wired/native cases individually. Preserve original files; no old scene-schema compatibility work is implied.
- [ ] Freeze the synthetic three-layer fixture and the full field-mutation fixture, including Paint holes, a disabled area, an orphan area and dormant curves.

**Touchpoints:** authoritative `unified-core.ms`, `presets.ms`, `container-node.ms`; `brush.h`, `brush.cpp`, `brush_host.cpp`; `cyrus_edit.cpp`, storage/stack includes; current engine validators. The exact [source map](FIELD_MAP.md) provides links. Existing `AminScatterCopyLayer` helps locate fields but copies host references and clears some radius records elsewhere; it is not the export contract.

## R1 — typed data and storage codec

- [ ] Add a separate native recipe codec using the existing JSON library/strict parser pattern. Preserve `cyrus.settings-preset` v1 and the category browser path.
- [ ] Parse bounded UTF-8, reject duplicates/nonfinite values/path escapes/unknown versions and validate every cross-reference before allocating host objects.
- [ ] Encode explicit enums/units, inactive values, curves with graph handles and source-row membership. Store role IDs rather than array positions or Max handles.
- [ ] Validate Paint attachment byte count/hash/version before decoding. Keep native payload values authoritative; reject conflicting manifest summaries.
- [ ] Implement semantic comparison independent of newly allocated scene IDs; compare floating conversions using declared tolerances, and no-conversion native Paint by exact bytes.
- [ ] Add atomic manifest/attachment save: stage payload folder, read back, verify, publish manifest last, then update index. Preserve an existing recipe on failure/conflict.
- [ ] Implement explicit copy-to-new-format upgrades only if a later recipe version requires them. No upgrade on read and no retired scene migration.

**Native acceptance:** R10/R11, F01–F03 field accounting fixtures below; corrupt attachment, duplicate ID, wrong curve domain, malformed UTF-8, invalid enum, incomplete complete-export and aggregate-limit cases. Native tests do not qualify host import.

## R2 — complete capture with Paint in the first useful delivery

- [ ] Capture selected owners/order on the host thread and verify those owners still exist. Capture pending Manual authored settings without evaluating placements.
- [ ] Snapshot numeric/static controllers with exact field policies; enumerate and report unsupported animated/wired data before writing.
- [ ] Capture sources, Point/Empty rows, dormant rows/radii, group colors and identification values separately. Preserve shared asset references without deduplicating intentional rows.
- [ ] Capture all Paths/Bands: side, arrangement, both range representations, order, memberships, density/scale modes, curves/handles, transforms and Analyzer-specific semantics.
- [ ] Capture every Paint Area, including disabled/empty/orphan documents, order, layer/area density, both fades and editable graphs. Add a bounded native read/stage interface that preserves doubles and the original vector payload. Finish/cancel a live gesture before capture.
- [ ] Capture receiver frame, saved unit scale and binding fingerprint, including the distinction between a missing receiver and a cleared document. Do not serialize receiver mesh caches as Paint.
- [ ] Capture source containers as explicit dependency roles/policies. Snapshot membership is a different, explicitly lossy operation.
- [ ] Implement a safe adapter for supported authored Edit/radius records or identify each unsupported record as a complete-export blocker. Never use copied output transforms as a replacement for authored edits.
- [ ] Record complete and portable modes separately. Portable omissions require a named user choice and cannot overwrite the original complete recipe without explicit replacement.

**Gate:** capture leaves authored scene, publication epoch and solve/preparation/upload counters unchanged. Round-trip a Paint document with two islands and a hole, disabled scale fading with nondefault saved values, a sample-only curve and an editable graph. Different-area documents cannot become shared mutable instances.

## R3 — resolve the complete dependency graph

- [ ] Build a detached import proposal, listing source models, receiver roles, texture maps, mesh fields, Paths, area splines, Analyzers, containers and unselected collision partners.
- [ ] Selection and names propose candidates only. Check model type/pivot/up-axis/bounds policy, field channel/component/range, and Analyzer freshness. Multiple receivers must satisfy the layer's actual single mask-channel setting; incompatible per-receiver requirements are a conflict, not a new unsupported behavior.
- [ ] Preserve file-local sharing for repeated references. Provide explicit source substitution without losing row weights/group identity.
- [ ] Check actual Paint compatibility: evaluated local geometry/topology, units, object frame and projection. Byte/hash equality alone is insufficient. Retain incompatible originals inactive or block; no automatic reclip or full-surface fallback.
- [ ] Validate destination capacity including old layers/retries/protected state. Inspect source bounds where required during explicit preparation, not metadata browsing.
- [ ] Construct one consistent identity/remap table. Preserve seeds while using existing receiver sampling semantics; do not promise exact cross-scene positions. Qualified Edit restore must establish locator correspondence or remain inactive.
- [ ] Revalidate destination/role revision before commit; stale proposals require resolution again. Cancellation leaves no scene records.

**Gate:** missing/same-name/reordered roles, changed target during dialog, unknown enum, map mismatch, external spacing dependency and invalid Paint frame all produce bounded actionable results without mutation.

## R4 — transactional apply, Undo and failure retention

- [ ] Stage fresh layer/native document objects and any explicitly requested asset nodes with evaluation suppressed. Keep a journal of objects created by this operation.
- [ ] Apply authored values and graph edges by captured owner IDs, then install the complete graph as one Undo. Do not keep callbacks referring to controls rebuilt during commit.
- [ ] Preserve existing global Manual/Live/presentation options on Add. For a new setup, restore captured options only at transaction completion; no intermediate Live solves.
- [ ] Persist unresolved Paint/Edit data and requested enabled state. Inactive layers cannot produce full-surface output. Binding later is a separate validated Undo action.
- [ ] After commit, issue one scoped invalidation. Manual waits; Live coalesces. Do not conflate a successful authored import with successful calculation.
- [ ] Roll back authored transaction failures fully, including assets/preferences/references. For later calculation failures retain the prior complete output under F05 and leave authored pending state/error visible.
- [ ] Exercise Undo/Redo, layer removal/copy/reorder, repeated imports, destination deletion, source replacement and cold scene save/reopen. Verify native documents and external relationships are not aliased or lost.

**Gate:** R02–R09 and R13–R20, with both early parse and late staging failures. A result-count match alone is insufficient: compare complete authored graph, native Paint bytes, IDs/transforms and counters.

## R5 — browser and persistence UX

- [ ] Reuse the existing category preset workflow and captured-owner behavior. Add recipe browsing as a separate type in one shared UI.
- [ ] Add Save Everything/Portable rules controls with a field/coverage/dependency summary. A thumbnail is optional; never solve solely to generate one.
- [ ] Default recipe storage to Documents known folder plus `CyrusScatter\Library`; configurable root, read-only bundled library, explicit network refresh. Keep existing `getDir #plugcfg` category files in place.
- [ ] Bound list paging/metadata/image loading and show individual corrupt/offline entries. Do not scan a network tree on idle ticks or redraw.
- [ ] Show completeness, unresolved dependencies, engine requirements and pending versus calculated status. Import into a different terrain must explain Paint status beside its owner.
- [ ] Detect overwrite conflicts; support Save a copy for bundled entries; make failed save/import messages identify exact owners/fields without exposing unrelated paths/secrets.
- [ ] Preserve captured owner validity across selection/dialog changes and control reconstruction. Keep browsing independent from Live calculations.

**Gate:** current category behavior and bounds retained; 512/2,000-entry proposed recipe browser fixture, owner deletion, disconnected root and rapid open/close with zero geometry/solve/upload work. The existing 512 category cap is not silently lifted.

## R6 — qualification and delivery after coding is authorized

- [ ] Regenerate MAXScript/catalog only when affected; inspect generated results and run focused generation/codec/native tests.
- [ ] Freeze source/script/native identities, launch an owned disposable **Max 2027** profile and record loaded paths/hashes. Preserve artist profiles and `Test Scene/` originals.
- [ ] Run the required core subset below, including late failure, idle counters, Manual/Live and cold reopen. Keep source and loaded bytes fixed during a run.
- [ ] Run a full field-mutation fixture: nondefault active and dormant settings, both Band arrangements, all supported side/scale modes, source kinds, area falloffs, Paint holes/empty/orphan records and spacing relations.
- [ ] Run representative 20k/200k scenes and admission-limit rejection; measure actual avoided work and peak memory, cold/warm separately. Do not claim presented FPS from synchronous redraw timing.
- [ ] Update actual artist docs/backlog/current handoff with passed scenarios and open restrictions. Documentation or executable fixture counts are not runtime passes.
- [ ] Choose the next small-step version under the then-current authorized release scope; independent Analyzer/MCP versions remain separate.
- [ ] Build and verify a runnable Max 2027 `.mzp` from the exact qualified pair: archive integrity, version/host guards and payload hashes. Deliver package path, Scripting > Run Script and restart instructions. Do not install or restart the user's host unless explicitly requested.
- [ ] Commit/push only when authorized. Phase 6 stays paused unless separately resumed by the user.

## Core validation versus optional studies

Required core gates: **R01–R20**, declaration coverage and **D01/D02/D03/D04/D07/D09/D10/D11** on the imported fixture. **G02/G04/G06** apply to compatibility/units/channel seams; retain current behavior and reject unsupported correspondence rather than inventing an algorithm. D05/D06 are regression checks if identity/sampling paths change. G08/G09 and asynchronous cancellation targets are optional future engine studies, not mandatory new curvature/velocity implementations.

The first accepted delivery must demonstrate: Save Everything preserves Paint and all supported authored settings; incompatible data is retained or blocked honestly; importing multiple layers remaps relationships; failure/Undo/reopen preserve work; static idle, selection and browser activity cause no scatter calculation. Existing physical tablet, device-loss, arbitrary renderer and extreme-unit acceptance limits remain explicit.

## Later work, with a reason to start it

| Follow-up | Trigger / bounded implementation | Required evidence |
| --- | --- | --- |
| Asset collection / native controllers | Users need a self-contained package. Enumerate explicit host dependencies and supported plugin types, stage/import in one transaction. | Asset sharing, missing textures/proxies, material/renderer compatibility, controller graphs, file conflicts and rollback. |
| Paint transfer | Users need deliberate reuse on a different terrain frame. Add one declared transform/projection at a time; keep originals. | Analytic coverage/holes/units, clipping-loss summary, unsupported surfaces rejected, Undo/reopen. |
| Replace / source-group merge | Artist workflow justifies it. Define target IDs, weight/group conflicts and external relationship changes. | No same-name deduplication, complete Undo, retained Paint and external links. |
| Shared receiver snapshots | Counters show repeated extraction is material. Copy one coherent evaluated snapshot for its dependency set; release host data before workers. | Reference parity, actual reduced copies, conservative validity for unknown modifiers, bounded old/new memory. |
| Filter-only cache | Curve edits spend meaningful time generating unchanged candidates. Separate raw samples/response/acceptance without changing existing independent random gates. | Full transform/anchor/source/ID parity, collision/refill/Relax sensitivity, saved Edit compatibility, measured avoided generation. |
| Fields / async jobs | A measured need remains after simpler changes. Individually specify density blending, smooth orientation, curvature estimator, motion or cooperative cancellation. | Domain/units, analytical oracle, deterministic policy, host-thread boundaries and stale-result rejection. |

These follow-ups require their own implementation scope. The plan is complete enough to identify work and acceptance; it is not a claim that every future API choice has already been proven in Max.
