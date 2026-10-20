# Real-model preset validation

**Required acceptance · no new host results recorded by this plan**

[Guideline](README.md) · [Preset catalog](PRESETS.md) · [Roadmap](ROADMAP.md)

Use Max 2027 only in owned disposable scenes/profiles. Preserve originals and artist
sessions. Identify the source script/native pair and package bytes before testing.
Preparation reports qualify only their recorded scope; this campaign must exercise
Cyrus Scatter and the actual saved/imported packages.

## Per-preset checks — all 24 entries

| Check | Required observation |
| --- | --- |
| Source identity | Actual models and variants match the manifest; no placeholder substitutions |
| Basic load | Supported Library action loads into a fresh scene and binds to the selected receiver |
| Additive load | Existing planting survives; new layers have independent identities and source settings |
| Models/materials | Complete assemblies, UVs, material IDs, opacity, normals and color spaces survive |
| Physical setup | Dimensions, pivot, orientation and contact agree with the declared intended result |
| Distribution | Requested/accepted/shown counts and intentional gaps/spacing are understood |
| Changes | Amount and source edits update correctly; deleting all sources publishes a valid empty result |
| History | Undo/Redo of load and relevant edits restores complete consistent state |
| Persistence | Save/reopen restores models, materials, sources, layers and dependencies |
| Portability | Reload from a moved package/content location without relying on the authoring folder |
| Render | An actual Corona render of the fresh loaded package shows the intended plants and materials |
| Preview | Catalog image corresponds to that exact package revision; detail does not hide important faults |
| Readiness | Requirements, costs, known limits and distribution status are recorded accurately |

Use comparable framing, lighting and exposure when checking appearance against
prepared assets. Do not claim exact equivalence to original V-Ray materials: the
preparation reports explicitly limit that claim. Preserve intentional authored
differences and identify derivative changes.

## Cross-scene matrix

Run these families on the eight pilots, choosing every relevant asset/adapter path.
Run affected cases on expansion presets that introduce a new dependency, structure
or behavior. Record the mapping from scenario to tested RP IDs; untested cases stay
untested. All entries still require the per-preset checks above.

| Family | Required cases | Expected behavior |
| --- | --- | --- |
| Units | Millimetres, centimetres, metres and feet; source/destination unit differences | Physical size, spacing and density remain consistent within the supported contract |
| Receiver size | Small, typical and large areas at equivalent physical settings | Predictable density/count scaling and explicit resource limits |
| Receiver geometry | Plane, sloped terrain, sphere, box and another manifold curved receiver within current limits | Valid placement; deliberate alignment; explicit supported/unsupported Paint transfer |
| Transforms | Translated, rotated, uniform/nonuniform scale and mirrored receivers | Correct transforms and distances or a clear bounded rejection retaining prior output |
| Multiple owners | Multiple receivers, populated layers, active-layer changes and captured-owner deletion | Correct destination binding; no cross-layer mutation or stale-owner crash |
| Repeat load | Load twice; duplicate source names; duplicate material names | Fresh logical identities and deliberate asset reuse without accidental name-based binding |
| Source lifecycle | Remove one/last source; replace mesh with another; switch asset class | Correct empty/result publication and recovery; no invalid preview source index |
| Amount inputs | Image/pattern → procedural map → channel mask → disabled mask; replace/clear maps | Correct independent ownership; Clear removes the binding; no stale mask influence |
| Update modes | Live edits; Manual pending edits and explicit Update | Live responds to relevant changes; Manual retains last completed output until Update |
| Reuse | Idle, library browsing, selection changes and unrelated animation | No unnecessary static solve or unchanged-buffer upload |
| History | Load/edit/remove with Undo/Redo; scene save/reopen; bound dependency restoration | Consistent identities, references and retained complete results |
| Relocation | New library root; Unicode/spaces; same basenames with different bytes | Correct content resolution without authoring-drive dependence or filename-only collisions |
| Renderer dependencies | Fresh owned profile with the declared installed set; controlled missing-class cases | Correct render or clear preflight failure; never silently degrade the asset |
| Proxy lifecycle | Copy/move/reopen; missing `.cgeo`; viewport vs final render | Persistent proxy references and correct geometry/materials in both paths |
| Invalid input | Missing/corrupt texture, mesh or package; stale/deleted receiver; unavailable required channel | Specific actionable error and no half-added preset |
| Publication failure | Failure before mutation and after staging has begun | Rollback restores prior scene/output/history and releases temporary resources |
| Content replacement | Fresh recipient plus upgrade/repair of bundled catalog | New defaults appear once; old owned defaults retire; personal content survives |

A fresh profile on the same machine may still find globally installed plugins or
texture search paths. Record the actual dependency environment and isolate fallback
paths in owned tests before claiming clean-machine portability. Never uninstall
plugins from the artist's environment to create a negative test.

Curved painting support does not imply transferring arbitrary saved coverage onto
different topology. Respect [the current brush limits](../DELIVERY_0866.md), including
receiver admission and guarded bindings. Do not weaken those contracts to make a
preset load. Prefer receiver-independent defaults for the ordinary collection.

## Visual review

Inspect both a wider composition and a close detail where the asset requires it:

- Leaves: proper silhouettes, opacity from both sides, sensible thickness/contact
  and restrained overlap; alpha cards visibly identified where close-up use is limited.
- Grass/flowers: intentional density, color balance, realistic source scale and no
  unexpected bare squares or texture seams.
- Shrubs/trees: coherent multipart sources, ground contact, complete foliage,
  intended upright/normal alignment and sensible canopy spacing.
- Layered recipes: readable heights, useful negative space and deliberate independent
  collision scopes; no layer accidentally suppresses the rest.
- Proxies/material graphs: intended appearance survives import and reopening;
  Forest-dependent shading is verified with the declared dependency environment.

Catalog screenshots or direct source renders alone do not qualify the saved recipe.
Render the exact package after loading it through the supported workflow.

## Performance acceptance

Measure representative small, medium and larger workloads for each family; choose
actual counts and budgets before claiming acceptance. Do not prescribe one tree
count for a clover carpet or infer proxy performance from its filename.

Record hardware/OS, Max/Corona/plugin versions, source/package hashes, source
geometry and maps, requested/accepted/shown counts, viewport mode/caps and camera.
Measure cold/warm load, calculation, preview preparation/upload, process memory,
final render time and peak memory separately. Distinguish synchronous redraw time
from presented FPS and process memory from VRAM or isolated native allocation.

Define bounded behavior when capacity is exceeded. Keep preceding complete output,
provide a useful error and release staged resources. Inspect repeated load/remove,
Undo/Redo and reopen for retained resources. Raising a limit without measuring peak
old/new publication overlap, host allocations and history is not acceptance.

## Evidence record

Keep executable test receipts under a fresh owned `build/` run and exact delivery
receipts with the eventual artifacts. Summarize accepted scope once in a dated
delivery report when evidence exists. This planning directory must not accumulate
invented pass records or copies of private/licensed model data.

Each per-preset receipt needs:

| Field | Contents |
| --- | --- |
| Recipe | RP ID, UUID, revision and package SHA-256 |
| Source | Model identities, paths/hashes, original vs derivative and dependency manifest |
| Build | Branch/HEAD plus relevant dirty scope; script/native hashes and loaded paths |
| Environment | Max 2027 build; renderer/plugin versions; owned profile; system units |
| Scenario | Receiver geometry/transform; layer settings; counts; exact action sequence |
| Result | Expected vs observed; pass/fail/untested; error and retained-state checks |
| Visuals | Render path/hash, camera, resolution, renderer settings and inspected details |
| Cost | Measured timings/memory with workload and limits |
| Follow-up | Remaining acceptance, known restrictions and reproduction instructions |

Use **draft**, **blocked** and **qualified within stated scope** deliberately.
A passing report must identify the bytes and environment that passed. An absent
receipt, a static check or an older source-asset render cannot stand in for a host
result. Report physical artist interaction separately from automated button/API tests.

## Ready-for-delivery checklist

These boxes are a reusable checklist, not current completion status.

- [ ] All eight pilots and then all 24 recipes pass required per-preset checks.
- [ ] Cross-scene coverage identifies actual tested RP IDs and dependency paths.
- [ ] Visual review uses renders from freshly loaded exact packages.
- [ ] Resource limits and measured costs accompany heavyweight content.
- [ ] Required files resolve after relocation and through save/reopen/Redo.
- [ ] Failures retain previous complete results and leave no partial scene mutation.
- [ ] Distribution eligibility is recorded for every included asset.
- [ ] Old bundled examples are retired by verified ownership/identity; personal content survives.
- [ ] Exact content archives and applicable MZP/EXE payloads pass integrity/recipient checks.
- [ ] Documentation, manifest and readiness labels match actual delivered scope.
- [ ] The user receives paths, usage instructions, limits and remaining artist acceptance.

