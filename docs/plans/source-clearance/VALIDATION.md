# Model clearance â€” validation and acceptance matrix

**Status:** Acceptance matrix with a scoped 0.86.8 campaign completed; the table is not a blanket pass claim. See [executed evidence and limits](DELIVERY_0868.md).

**Date:** 20 October 2026

**Design:** [Implementation plan](IMPLEMENTATION_PLAN.md).

The existing 0.86.7.2 receipts are baseline evidence only. The reported
Between layers failure is an artist observation with a source-mapped line,
reproduced in an isolated baseline profile. A separate corrected profile and final
0.86.8 cold profiles pass the actual dropdown sequence. The delivery report
records native/oracle/stress, lifecycle, real-model and installer evidence.
Physical tablet painting, all renderer combinations and million-row host timing
distributions remain unqualified. Use Max 2027 for new development/host work
under the repository's default testing rule.

## 1. Evidence required for every campaign

Record branch/HEAD, tracked and untracked scope, authoritative template hashes,
generated script hash/fingerprint, native and managed module hashes, loaded
paths, compiler/SDK/Max versions, fixture and asset identities, system/display
units, renderer dependencies, seed, receiver transforms, target/candidate
budgets, active rules, update mode and source/instance overrides.

Use fresh disposable profiles/scenes. A timeout is not success or permission
to issue another mutation into the same host; inspect completion state first.
Preserve failures and the input that produced them. Label test-driver mistakes
separately and retain their original output.

Compare IDs, full transforms, source/receiver correspondence, effective radii,
accepted/protected/rejected state and publication epoch. Counts alone cannot
detect a different winner or source-slot corruption.

A test receipt must distinguish:

- Static/source or generation check.
- Executed native unit/oracle test.
- Loaded host and actual control notification.
- Physical mouse/keyboard/tablet witness.
- Render/image check.
- Performance measurement.
- Archive/install qualification.

Do not promote one class into another. Code samples and an unchecked table
are not acceptance evidence.

## 2. Freeze the old behavior before extending it

| ID | Scenario | Required evidence |
| --- | --- | --- |
| BASE-01 | Supported schema-58 scene with no new policies | Frozen native result and authored-state snapshot; expected output for Defaults/Normal with inherited settlement |
| BASE-02 | Same layer: three model types with radii 20, 0, 0; factor 1, gap 0 | Aâ€“B and Aâ€“C require 20 units; Aâ€“A requires 40; Bâ€“C gets no radius separation |
| BASE-03 | Existing enabled/disabled layer-pair rules | Exact ordinary priority, protected exceptions, XY/3D and disabled-override behavior captured |
| BASE-04 | Manual pending Count/radius edit | Published IDs/transforms/radii remain until Update; passive reads do not apply pending inputs |
| BASE-05 | Accepted target, retry exhaustion and cleanup | Canonical prefixes/rounds/shortfall preserved when new features are unused |
| BASE-06 | Original Between layers bug | Actual dropdown notification in the reported script/native pair; owner/scope/lifetime trace and exact error |

Freeze the runtime identified by the artist separately from the corrected
Hide surface runtime. Their version captions are the same and do not prove
identical script bytes.

## 3. Native policy and distance tests

### 3.1 Footprint, units and exact predicates

| ID | Inputs | Expected result |
| --- | --- | --- |
| RAD-01 | Manual radius 20; scale 0.2; Follow Scale off | Effective radius stays 20 |
| RAD-02 | Same with uniform Follow Scale on | Effective radius 4; verify the actual existing numeric conversion |
| RAD-03 | Negative/nonuniform scale, rotation and shear | Existing conservative transform bound; finite nonnegative radius |
| RAD-04 | Auto on long, tall, mirrored and off-center geometry | All transformed bounding corners fit the appropriate XY/spatial radius |
| RAD-05 | Absolute and multiplier instance overrides | Correct post-source override; identity survives supported edits |
| RAD-06 | Zero radii with zero/nonzero gap | Separation comes only from the admitted effective rule; zero-radius source still respects the other footprint |
| RAD-07 | Distance just below, equal to and above threshold | Strict-less-than rejection; no newly introduced epsilon behavior |
| RAD-08 | Identical XY but different Z | XY rejects where applicable; 3D accepts when spatial clearance is satisfied |
| RAD-09 | System units mm/cm/m and inch-based scene | Physical radius/gap and recipe conversions agree; display units alone do not change physical output |
| RAD-10 | NaN, infinity, negative value, overflow or unavailable Auto bounds | Actionable validation failure; previous complete publication retained |
| RAD-11 | Same source with per-instance scale/radius variation | Each pair uses its actual effective radii, not one source-wide cached scalar |
| RAD-12 | Sphere, box, folded/stacked and curved receivers | Metric remains declared world XY or 3D; no implied surface-geodesic separation |

### 3.2 Policy matching and ownership

| ID | Scenario | Expected result |
| --- | --- | --- |
| RULE-01 | Both endpoints use Layer defaults; all sources Normal | Full baseline parity through the inherited settlement schedule and shared solver primitives |
| RULE-02 | A is Custom and targets B's layer; B uses defaults | A's custom numeric rule replaces the general rule for that pair |
| RULE-03 | A is Custom and excludes B; B uses defaults | No interaction for this pair, even if the general layer rule is enabled |
| RULE-04 | A excludes B but Custom B targets A | B's request enables interaction; an unchecked target is not a veto |
| RULE-05 | Both Custom endpoints request interaction with different factors/gaps | Maximum evaluated threshold for each metric; never separately maximize factor/gap or add gaps twice |
| RULE-06 | A requests XY and B requests 3D | Reject on violation of either constraint, using the matching radius pair for each |
| RULE-07 | Toggle Layer defaults â†’ Custom â†’ Defaults â†’ Custom | First initialization is explicit; later toggles preserve saved custom fields; defaults mode abstains from custom matching |
| RULE-08 | Own-copy, other-model-in-layer and selected-other-layer targets together | Each flag matches its intended pairs independently; no exclusive scope switch |
| RULE-09 | Selected layers versus All other layers; create a new layer | Only All other layers automatically includes the new layer; every source in a targeted layer participates |
| RULE-10 | Same geometry node in two layers | Model-entry settings remain independent |
| RULE-11 | Rename, display reorder, source replacement | Rules follow intended stable entry IDs; no silent rebinding by names or slots |
| RULE-12 | Empty, Point, parked source, hidden source scene node | Empty/parked candidates reserve nothing; Point uses Manual radius; source-node viewport visibility alone does not disable its scatter entry |
| RULE-13 | Controller/layer/source token belongs to another owner or revision | Reject command or stale completion; no write to currently selected replacement |
| RULE-14 | Model row deleted and new same-named row added | Old relationships do not attach to the new identity |
| RULE-15 | Same model across multiple receivers in one layer | Layer-scoped spacing includes its placements on all admitted receivers; no accidental per-receiver exemption |

Exact source-pair exceptions, explicit pair vetoes and directed model-to-model
preference graphs are deferred by this design and must not appear as required
first-delivery controls or claimed features.

### 3.3 Priority and acceptance

| ID | Scenario | Expected result |
| --- | --- | --- |
| PRI-01 | Interacting Aâ€“B with equal ordinary priority | Layer order, then existing candidate schedule decides |
| PRI-02 | A uses Prefer; B is Normal and has an earlier candidate ordinal | Eligible accepted A gets preference; overlapping B rejected |
| PRI-03 | A preferred over B but A fails coverage | B is not blocked by nonexistent A |
| PRI-04 | Preferred A conflicts with an earlier equal-priority C or protected C | Only accepted blockers reserve space; rejected A leaves no phantom reservation |
| PRI-05 | A and B have no effective interaction; A targets C's layer | A and B may overlap; priority alone creates no interaction |
| PRI-06 | Multiple preferred sources in several layers | Equal priority follows layer order and candidate ordinal; no source-list ordering bias |
| PRI-07 | Reciprocal or cyclic layer targets | Terminate deterministically using global rank; no directed-precedence graph or cycle rejection |
| PRI-08 | Equal-priority earlier-layer source versus later source | Earlier accepted placements block the relevant later candidates |
| PRI-09 | Later-layer Prefer versus earlier Normal; reorder layers | Prefer still wins; reordering affects equal-priority ties without creating a hierarchy error |
| PRI-10 | Protected placement in later layer versus earlier ordinary placement | Existing protected reservation contract retained under applicable rules |
| PRI-11 | Two conflicting protected placements | Both retained; conflict recorded, not silently resolved |
| PRI-12 | Protected count exceeds ordinary target | Preserve existing protected-edit policy; report requested/ordinary/protected totals distinctly |
| PRI-13 | Source-row display sort or different worker completion order | No priority change; deterministic result in the same qualified environment |
| PRI-14 | Zero positive-weight ordinary sources | Correct empty result or existing validation; no phantom fallback model |
| PRI-15 | Disconnected layers with no effective clearance/coverage dependency | Edit B retains A's IDs/transforms/radii; do not infer model independence inside a shared quota |
| PRI-16 | Activate a parked preferred source or enable a targeted layer | Recompile old/new dependency components; valid eligible candidates participate under the same total order |

### 3.4 Independent oracle

Use small deterministic and randomized scenes with mixed radii, metrics,
gaps, defaults/custom policies, target sets, source priorities and protected edits.

The oracle must enumerate all relevant accepted blockers and implement the
declared matching/order independently of production lookup, component compilation
and spatial indexes. Do not reuse those implementations and then call matching
results an independent oracle.

Compare full accepted ID sequences, rule/rejection categories, conflict IDs,
effective radii, per-source counts and target-shortfall semantics. Include
coincident candidates, exact boundary distances, disabled rules, large world
coordinates and large radius ratios. Record random seeds for every failure.

## 4. Refill, cleanup and publication

| ID | Scenario | Expected result |
| --- | --- | --- |
| PIPE-01 | Candidate-budget mode with preference | No hidden extra source population or attempts |
| PIPE-02 | Accepted-target mode with rare preferred source | Stable source lottery/prefix schedule; target respected; changed final mix explained |
| PIPE-03 | Extend prefix exposing later preferred candidates | Consistent final staged result; no intermediate publication or false prefix-stability guarantee |
| PIPE-04 | Impossible target | Stops at configured round/attempt/work limit with explicit shortfall |
| PIPE-05 | Cleanup removes an ordinary preferred blocker | Occupancy released; bounded refill can use newly available space |
| PIPE-06 | Cleanup would remove a protected edit | Protected placement retained under current contract |
| PIPE-07 | Cleanup/refill across interacting layers | Inherited settlement retains baseline order; ranked components replay permitted pools when necessary, use final blockers and charge all replays to shared limits |
| PIPE-08 | Failure during rule admission, bounds, solve or preview staging | Previous complete generation remains, with failure diagnosis |
| PIPE-09 | Injected failure during multi-view installation/transaction | No mixture of old/new layers, radii, source mapping, render data or Edit visibility |
| PIPE-10 | Inputs change after snapshot, before commit | Stale successor cannot publish |
| PIPE-11 | Valid empty successor | Old plants are removed and zero result is published; do not confuse empty with failure |
| PIPE-12 | Relax, Paint, Analyzer, source containers and new clearance combined | Preserve preparation order; no movement after final acceptance that violates clearance |

Use existing bounded fault facilities in private qualification builds where
available. Do not ship test fault endpoints or introduce a generic failure
framework solely for this feature.

## 5. UI and lifecycle acceptance

| ID | Interaction | Required observation |
| --- | --- | --- |
| UI-01 | Open Spacing; switch Within/Between repeatedly with 0, 1 and multiple layers | No free-thunk/handler error; peer list and help belong to current scope |
| UI-02 | Select model/layer, deselect/reselect controller, collapse/reopen panels | Lists, selections and authored rules remain consistent |
| UI-03 | Cold lazy mount, warm rebind and queued layout | No stale owner access; no unnecessary solve/upload |
| UI-04 | Add/remove/reorder layer while relationship UI is open | Captured command applies to intended owner or cancels cleanly |
| UI-05 | Change radius/factor/gap by keyboard and spinner drag | Correct final exact value; sensible Undo; coalesced Live update |
| UI-06 | Set own-copy/same-layer flags and selected external layers | Summary distinguishes requested targets from incoming effective interactions and warns that Prefer can outrank earlier layers |
| UI-07 | Reset a source to Layer defaults while another source targets it | Own saved custom fields remain dormant; incoming requests still apply and are explained; the other source's policy is not edited |
| UI-08 | Mixed source multi-selection | Mixed values shown; atomic bulk validation; no accidental first-source overwrite |
| UI-09 | Open dialog then delete owner/reset scene/change selection | Stale callback cannot update another owner or freed control |
| UI-10 | Manual pending edit and footprint overlay | Published versus pending state labeled; browsing does not apply the edit |
| UI-11 | Advanced/optional controls unopened | Their expensive construction is deferred; saved disclosure preferences preserved |
| UI-12 | Supported DPI, narrow/wide panel, multi-column placement | Controls readable/reachable; lists not hidden by cached-layout shortcuts |
| UI-13 | Library model import with model panel open | Success feedback, correct source correspondence and unchanged intended existing relationships |
| UI-14 | Invalid number, duplicate/foreign target, stale source mapping or work limit | Plain-language diagnosis naming affected owners; no raw MAXScript exception or partial authored edit |

Use actual generated notifications and process subsequent timer/status callbacks.
Add physical UI acceptance for the artist workflow; a `.pressed()` or direct
native function call alone is insufficient.

## 6. Save/load, Undo and portability

| ID | Scenario | Expected result |
| --- | --- | --- |
| SAVE-01 | Rule creation/edit/delete, source removal, layer reorder, radius edit â†’ Undo/Redo | Exact authored IDs/rules and consistent published state restored |
| SAVE-02 | Repeated Undo/Redo after panel destruction/remount | No dangling controls, source slot substitution or unbounded retention |
| SAVE-03 | Save/reopen and cold launch with rules | Same effective relationships and deterministic output after required realization |
| SAVE-04 | Supported schema-58 input | No-override parity; original file preserved; documented transition only |
| SAVE-05 | New-rule file opened by incapable reader | Explicit refusal or verified supported guard; never silently drop rules |
| SAVE-06 | Copy layer/controller and merge into another scene | Internal IDs remapped; deliberate external references handled explicitly |
| SAVE-07 | Complete recipe containing internal relationships | Package-local endpoint mapping resolves atomically |
| SAVE-08 | Recipe targets a layer outside its package | Explicit binding or explicitly chosen omission; no same-name guess |
| SAVE-09 | Individual library model imported into arbitrary scene | No automatic reservation against unrelated existing layers |
| SAVE-10 | Missing assets/renderer/receiver/invalid endpoints | Correct preflight or existing missing-dependency behavior; no partial import |
| SAVE-11 | Unit conversion and scaled/mirrored receivers | Physical distance semantics and saved rule identities retained |
| SAVE-12 | Rename, deletion and same-name replacement across save/load | Persistent identities govern behavior |

Verify the actual old-reader path before claiming compatibility protection.
If a reliable refusal mechanism cannot be established, persistence design
remains a release blocker rather than a documentation disclaimer.

## 7. Real scene fixtures

Use copies/references of existing prepared library assets without modifying
the originals. Verify actual catalog entries, paths and hashes rather than
inventing asset IDs.

1. **Artist example:** Layer_01 has the shown Sycamore Leaf 08 and Bent Leaf 21;
   Layer_02 has pyramids. Sycamore reserves space from pyramids, leaves may
   overlap each other, and pyramids have their own separation.
2. **One-layer equivalent:** the same three models in one layer; preferred
   Sycamore targets all other models while own-copy spacing is independently
   on/off. Confirm Count remains one population. Selecting only one of the other
   two models as a target is outside this first-delivery design.
3. **Tall/short mix:** a tree, bush and grass source; Auto radius, scale variation
   and XY/3D. Record conservative footprint limitations.
4. **Receiver stress:** plane, tilted terrain, box, sphere and stacked surfaces;
   shared receivers across layers and painted coverage on curved receivers.
5. **Texture/viewport regression:** textured leaves with opacity and a supported
   Color Correction change; radius updates must not misassign source materials.
6. **Hidden receiver regression:** Hide/Show, painting, rendering and save/reopen;
   include the single receiver with no selected list row.

Compare preview and final-output source/transform membership for the same
published generation. Image differences from shading alone do not prove
placement changes; placement counters alone do not prove material correctness.

## 8. Performance and memory qualification

Measure equal inputs and frozen builds on the same machine. Suggested sizes:
2,000, 20,000, 100,000 and, where admission permits, 1,000,000 total candidates.
Use 1/3/10 layers and varied model counts within actual admitted source limits.
Include uniform radii, 1:1,000 radius skew, coincident candidates, sparse and
crowded rules, disabled rules and All-other expansion.

Record:

- Rule compilation and effective lookup/cache costs.
- Candidate/transform reuse, radius evaluation, spatial build/search, cleanup/refill.
- Neighbor visits, source/rule counters and total Update latency.
- Warm/cold UI readiness and actual spinner/dropdown response separately.
- Unique native live/peak bytes, temporary copies, old/new overlap, retained
  sparse views, Undo growth/release and script readback rows.
- Preview preparation and GPU uploads separately from solve time.
- Requested/accepted/shown counts and target shortfall.

Hard invariants:

- Warm idle, source selection, scope browsing and unrelated animation produce
  zero clearance solves and zero unchanged geometry uploads.
- No placement-sized MAXScript readback is added.
- Candidate/rule/memory/work limits stop safely and retain the prior result.
- Equivalent numeric inputs repeat output regardless of allowed preparation
  worker count; deterministic acceptance remains explicit.
- Closing/resetting the owned scene releases retired work after valid consumers
  are gone; native language alone is not proof of bounded memory.

Investigate no-override regressions beyond the measured noise floor; use
approximately 10% median and 20% p95 warm-computation regression as initial
review thresholds, not fabricated measured promises. Separate extra-feature
cost from legacy-path regression. Any accepted regression needs a documented
reason and product decision before release.

Use the existing numerical precision policy; do not claim cross-platform or
cross-version bit equality without evidence. Async cancellation tests are
required only if an async executor is actually added.

## 9. Commands and delivery gates

After implementation authorization, use fresh owned output directories:

```powershell
Push-Location AminScatter
try {
    node tools/ui/generate.cjs
    node tools/ui/generate.cjs --check
    node tools/ui/approved-layout.test.cjs
} finally { Pop-Location }

python tools/procedural_lab/check_generated.py --output build/<fresh-run>/generated
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q
python tools/procedural_lab/offline_build.py --project scatter --year 2027 --output build/<fresh-run>/scatter
ctest --test-dir build/<fresh-run>/scatter -R '^scatter_procedural$' --output-on-failure
```

`<fresh-run>` is a placeholder to replace, not a literal command argument.
Discover additional registered test names from the new build; do not assume
future test-target names already exist.

Release requires:

- All required matrix rows linked to actual receipts, or a documented scope
  reduction accepted before calling the feature complete.
- Exact qualified source/native/Gallery/installer pair; no mixed stale module.
- Runnable Max 2027 MZP with archive/host/version/hash checks and restart instructions.
- Each additionally requested host qualified with its own matched SDK payload.
- If an EXE is supplied: plugin-only update, optional adjacent content ZIP,
  shared reuse without duplication, concise success, missing/corrupt content,
  running hosts, interrupted/failing installation and uninstall preservation.
- Source references and artist docs aligned with proven behavior; website source
  updates distinguished from built/published content.
- Remaining limitations and physical artist checks stated plainly.

No new installer, runtime test or product qualification is produced by this
documentation task.

## Review additions (required for 0.86.8)

- Equivalent inherited and explicit rules must preserve accepted identities, cleanup, refill, counters and work, not merely placement count.
- Editing own-copy or same-layer clearance must preserve separately inherited external relationships.
- A distant preferred candidate beyond a filled Count admission prefix must not steal a normal model's slot. When a real conflict frees a slot, bounded refill may admit it.
- Dormant model distance values must not inflate spatial-query admission or alter output.
- A schema-58 scene opens pending explicit upgrade; Undo/Redo covers the upgrade. A schema-59 scene cannot silently run in the old schema-58 build.
- Recipe v8 target references must be complete and explicitly remapped. Old recipe files are read without rewriting their content or identities on disk.
