# 11 — Ownership, option behavior and interaction contracts

4 October 2026. Proposed **0.7 evaluation-policy contract**, checked against source `53bfc5d1c76929958dbeb29f5d4c746b2321d0ac`. This is the implementation/qualification checklist, not a declaration that the new controls exist. Old policies retain their existing semantics.

## Owners and switches

The stored parent population currently serves two roles: **logical layer** and **Base Paint Set**. The new evaluator must resolve these roles explicitly without making the artist recreate objects.

| Action/control | Contract | Calculation consequence |
| --- | --- | --- |
| Controller enabled | Enable/disable this planting setup; retain authoring data | Disabled setup supplies no active planting output/reservations |
| Layer enabled in output | Applies to Base and every child set | Remove all member participation; reallocate/reconsider affected dependencies |
| Base set enabled | Applies only to Base | Child Paint Sets remain active; recalculate shares |
| Child set enabled | Applies to that set | Remove its ordinary output, protected reservations and background-reference contribution |
| Layer visible in viewport | Applies to every member's display | Keep render/output and collision participation |
| Set visible in viewport | Applies only to that set, subject to layer visibility | Same placement/output; different display membership |
| Select/edit another set | Rebind source/Brush controls | No generation, seed change or spacing change |
| Rename or open/close a rollout | Presentation only | No placement invalidation |
| Set share weight | Allocate the layer's ordinary candidate/target budget | Not a density multiplier applied a second time to accepted plants |
| Zero share | No ordinary quota; stored coverage and authoring remain | Under the proposed accepted-target policy, valid protected plants remain and can exceed target; this needs the protected-input adapter described below |
| Disable a spacing rule | Permit that pair class to overlap | Does not disable its owners, erase coverage or remove unrelated rules |

Current key construction includes set name/visibility, so presentation-only reuse is a **target with a concrete cache-key correction to qualify**, not a claim that every current toggle is cost-free.

An enabled, zero-weight set can still contribute an authored coverage exclusion when explicitly referenced by Background outside coverage. Disable the set to stop both its ordinary evaluation and reference participation. This separation is deliberate; show it in help rather than silently treating weight as another enable checkbox.

## Control coverage and inheritance

The generated [control inventory](../../AminScatter/tools/ui/layers-control-inventory.json) has **194 entries across 16 rollout groups**: 28 General and 166 layer-panel entries. The `setsUI`, `sourceUI` and `brushUI` groups edit set-owned data within that panel. Counts describe inventory entries, not 194 independently clicked/tested buttons. Modal editors, context menus, native CS Edit and host behavior also need runtime fixtures.

| Existing control family | Owner and meaning to preserve | Relevant new-policy contract/test |
| --- | --- | --- |
| General enable; Manual/Live; Update | Controller scheduling and published result | Manual retains the previous generation with Pending; Live coalesces actual edits; Update verifies current revisions |
| Surface selection/list; policy conversion | Controller receiver inputs | One shared enrolled receiver for the current integrated Brush scope; conversion is explicit and undoable |
| Add/copy/remove/name/enable/visible layer | Layer lifecycle | Stable IDs; independent copied namespaces; remove incident rules/references; no dangling set ownership |
| Paint Set add/remove/name/share/enable/show | Set lifecycle and allocation | Base cannot be removed independently in current storage; shared target, explicit order and enabled state |
| Plant asset add/select/remove/replace; Point/Empty rows | Set sources and stable source entries | Source selection versus receiver selection stays distinct; missing/empty/point rows have explicit output accounting |
| Asset weight/color group/forward axis/Z offset/scale | Set/source assignment and transforms | Weight zero excludes ordinary source selection; group color can affect assignment, unlike a pure preview tint; source offset does not erase a support anchor |
| Asset radius/Follow Scale/Show Radius | Footprint metadata and display | Scale radius once; Show Radius only draws diagnostics; source radius is not mesh resizing |
| Population distribution/count/density/seed/map/invert | Layer defaults shared by sets | Preserve old candidate-budget/density behavior; add accepted count target separately; retain generator restrictions |
| Coverage mode; Paint/Erase; radius/strength/softness/density; Begin/Stop | Selected set's procedural coverage document | Store strokes on indexed surface anchors; density/coverage factors have declared coordinates and are not repeatedly sampled |
| Fill/Empty coverage; stroke enable/erase/edit/delete; reset target | Selected set's authoring history | These edit the mask/history; **Fill coverage is not Target replenishment**; reset has explicit history/binding consequences |
| Brush overlay mode/color | Selected set's feedback | Field samples/tint versus accepted plant centres remain distinguishable; no new placements from overlay color |
| Include/exclude areas; Analyzer bands/points; boundary delete/scale/density falloffs | Layer-wide eligibility and effects | Retain each current domain/coordinate convention; new projected-painted policy uses resolved support anchors; do not call projected masks geodesic |
| Diversity Random/Clusters; group controls | Layer assignment behavior with set-owned sources | New random channels preserve candidate attributes across unrelated rejection; color grouping is computational data |
| Line Pattern/Analyzer paths/strokes/edge/street/corner controls | Current independent-layer modes | Existing multi-set guard remains; these modes need separate adapter/identity tests before new refill support |
| Randomize rotation/axis scale/whole scale/movement; project/align; reset buttons | Layer transforms inherited by sets | Resets affect only their named group; distinguish latent/support/final coordinates; normal alignment is not a spacing metric |
| Collision/point Relax | Current layer defaults | New self/set/layer rules separate their effects; preserve Brush/shared-policy Relax guards |
| Priority/peer/blocker/gap/radius/metric | Relationship settings | Show effective order; classify a pair once; preserve old fixed-radius mappings on conversion |
| Cleanup neighbors/island thresholds; final Relax controls | Layer union | One-pass cleanup remains distinct from iterative pruning; refill can revisit released space; final Relax requires separate qualification |
| Point Cloud/Proxy/Mesh; instance/face/sample budgets; point color; icon/radius display | Controller display | Consume accepted results, with display-only subsets; camera movement does not generate candidates |
| Auto render/Bake/clear baked output | Exact output and authored scene nodes | Use accepted placements, not preview subsets; preserve ownership checks and existing baked-node removal guards |
| Statistics/details/help/refresh | Last published diagnostics | No hidden solve; report Pending/Error separately; explain candidates versus instances versus point samples |

This groups all inventoried controls by their evaluation role. It does not invent new per-set overrides for every inherited setting. First add the requested independent spacing rules; keep population, area, randomization and cleanup at their declared layer scope. Future overrides need a separate field/merge contract.

## Identity and artist edits

Keep owner IDs, sampling keys, allocation tie keys, candidate IDs, source-entry IDs and final instance IDs separate. They solve different problems. Collision reordering must not reseed sampling or reassign an allocation remainder. Increasing the total budget can still change largest-remainder shares; it cannot promise that each set grows monotonically.

CS Edit clones share provenance with their input but have distinct output IDs. A radius override, deletion or move targets that final instance ID. Copying a layer remaps internal IDs and rules while preserving the intended sampling recipe. Source replacement/reordering needs explicit correspondence; never bind by the next compacted row.

Current CS Edit retains records but emits them only when their input ID is present and the base signature is valid. Therefore:

- Erasing the eligible input anchor suppresses its bound result/clones; it does not delete stored edit history.
- Moving an eligible protected plant outside coverage is an authored exception; that is different from erasing its input.
- Disabled owners and deleted rows reserve no space. Hidden owners still participate.
- Unresolved bindings cannot reserve stale positions or silently attach to another plant.

The new accepted-target policy should preserve valid protected instances when their ordinary quota shrinks, including zero. That requires reconstructing and validating their bound input anchors independently of the ordinary prefix. Preserve only bindings proven valid for the new generator/source/receiver state. Until this adapter passes count/zero/source/clone/Undo tests, block incompatible conversion or parameter changes with a clear explanation and intact records. Do not claim this stronger contract already exists.

## Rule and fill interactions

For a plant pair, choose exactly one of self, sibling-set or layer-pair rules. Resolve its override/default once. Threshold is `k * (r_i + r_j) + gap`; equality is allowed. XY and XYZ are explicit; neither is surface geodesic distance. A protected conflict is preserved and reported. Ordinary winners follow visible order.

Background Between plants uses applicable spacing rules, not a second hidden radius. It needs nonzero effective clearance to create a margin. Outside coverage uses the referenced enabled owners' normalized authored Brush field, clipped by their Area domain, before population/occupancy. Whole surface means that owner's Area domain; set share/count and accepted plants do not shrink it. Additional density-map/falloff participation must be explicitly specified by the adapter; do not guess from a distribution-mode name. For the first contract, population density and assignment weights do not redefine a painted exclusion. Preserve stroke strength/softness composition.

Resolve explicit earlier references only; reject forward/cyclic/dangling references. Apply the coverage complement once. Referencing a Whole surface foreground may leave no available domain; explain that outcome. Hiding a foreground does not make its space available. Disabling it does.

Target replenishment is independent of these background choices. A canonical logical prefix/round schedule drives eligibility, collision, union cleanup and bounded retry. A warm cache cannot offer extra candidates early. Temporary cleanup suppression is a bounded heuristic and may underfill an otherwise feasible layout; display attempt/round limits and remaining shortfall. Do not label a sampling limit “surface full.”

Accepted targets count accepted planting slots, including explicit Point placeholders; report rendered mesh instances separately. Initially reject weighted Empty sources in accepted-target mode, while retaining them in candidate-budget mode. Otherwise replenishment would silently fill the intentional gaps those source choices created. A future empty-slot quota extension needs its own specification and accounting.

## State and integration gates

No new-policy completed generation is published until all dependent layer results and consumer state agree. Failed computation retains the previous good generation with an error. Partial/obsolete results cannot masquerade as complete. Manual mode shows the last completed statistics and a pending marker; it does not display pending counts next to old meshes.

Current product limits remain explicit: ten total stored populations including child sets; current count control up to 100,000 per logical layer before set allocation; static Brush surface correspondence; existing multi-set Line/Analyzer and painted Relax guards. Candidate/target refill adds separate hard work and memory caps. Raising a UI limit is not a scalability qualification.

MCP keeps its current closed schemas, host/site/asset/candidate limits and approved owned transactions. New policy/order/rule/fill operations require a versioned capability contract and actual-result export tests. The future ML companion proposes recipes; it cannot bypass eligibility, collision, work limits or artist edits.

The [validation matrix](08_VALIDATION_AND_EXPERIMENTS.md) and [readiness report](10_READINESS_REVIEW.md) distinguish these required behaviors from what has actually been exercised.
