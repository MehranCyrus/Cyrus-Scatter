# 06 — Persistent data, native controls, diagnostics and integration

Status: proposed new-policy contracts; current capabilities are called out separately.

## Versioned state with stable ownership

Add a named evaluation-policy version rather than changing the meaning of existing `groupPolicy` values in place. The exact new numeric/schema identifier is an implementation decision. Use Cyrus names for new public APIs; renaming existing internal classes, class IDs and serialized plugin identities is not required for this feature.

Introduce explicit policy capabilities at the adapter boundary. The generated program currently contains 80 literal `groupPolicy == 2` / `!= 2` sites, including repeated UI factories. Paint Set creation, Manual display, shared spacing, copying, Relax guards and Edit visibility all depend on them. Adding a third value only in the solver would fall through other legacy paths. Audit every dispatch site; preserve MCP plan 1.0/2.0 mappings in `max_host.py` until a separate schema extension is qualified.

Recommended normalized model:

| Record | Essential fields |
| --- | --- |
| Controller | schema/policy version, UUID namespace, receiver references, units, ordered layer IDs, revision domains |
| Layer | ID, ordered set IDs, enabled/viewport-visible state, population mode and budget, inherited defaults, cleanup settings |
| Set | ID, owner layer ID, sampling key, allocation tie-break key, source-entry IDs, coverage reference, share weight, self-rule override, optional background mode/references |
| Source entry | Stable ID, scene reference, weight, geometry/transform revisions, source radius policy/value, follows-scale |
| Pair rule | ID, scope, canonical endpoint IDs, enabled, XY/XYZ metric, radius multiplier, gap |
| Candidate | Namespace/ordinal ID, receiver identity, latent and resolved support anchors, deterministic random channels |
| Instance edit | Input binding and distinct output ID, transform/delete/protect fields, optional radius mode/value, binding revision |
| Completed result | Input revision, policy version, accepted views, consumed upstream digests, counts/timings, output digest |

These are conceptual fields, not an already implemented JSON schema. Define types, bounds and units in a single contract before wiring UI or MCP. Native scene units may remain the existing implementation's units; external contracts should keep explicit metres and convert once at the boundary.

Names are labels. IDs survive rename/reorder and identify rule endpoints. Copy receives new IDs and remaps internal references. Removing a set removes or reports its incident rules and fill references in one Undo operation. Never reconnect a missing endpoint by matching a display name.

Source entry identity also matters: inserting a source row must not silently attach a radius override or asset assignment to the next array element. Where existing generation cannot preserve correspondence, create a new binding revision and report that limit.

Persist sparse radius overrides against the final instance identity, including clones. Store candidate provenance separately. Copy remaps instance/rule references while preserving the intended sampling recipe. Current generation-scoped or Edit-key-derived identities are inputs to conversion, not proof that these stronger guarantees already hold.

## Minimal native UI

Keep the classic flowing command-panel layout and existing scroll/expansion fixes. General settings remain outside layers. A selected Paint Set owns its source/coverage editor; layer-wide controls remain visibly layer-wide.

Proposed additions, without a custom graph editor:

| Location | Controls |
| --- | --- |
| Layer manager | Effective order, Move up/down, compact accepted count and cached/pending/error status |
| Paint Sets | Ordered set selector, enabled/visible, weight, background role and Move up/down |
| Within this set | Inherit/override, enabled, spacing multiplier/gap, metric |
| Between sets | Choose sibling pair, inherit/override, same rule controls; show which earlier set wins |
| Between layers | Existing pair editor extended with multiplier and effective winner |
| Plant assets | Source radius and follows-scale; clear units and footprint help |
| CS Edit | Optional instance-radius override and Reset to source; added after binding tests |
| Population | Candidate budget versus accepted target; bounded refill option and underfill reason |
| Background | Between accepted plants versus outside painted coverage; explicit earlier references |
| Statistics | Counts, removed reasons, timings, cache/work counters and capped conflict inspection |

Reuse one rule editor for the three scopes. Avoid an always-visible `N × N` matrix. Defaults handle common cases, and a compact list shows only overrides. Native help should state “centre spacing using radius estimates” and should explain that hiding affects the viewport while disabling affects evaluation/output.

Opening a rollout, selecting another layer or reading statistics must not dirty computation. A control event modifies its captured owner, creates one meaningful Undo transaction, bumps the appropriate revision and refreshes cached presentation. Suppress value-binding events while refreshing controls.

[11 — Option contracts](11_OPTION_CONTRACTS.md) records the base-set versus layer distinction, zero weight, visibility, offsets, fill references and inherited controls. Use that table for native UI labels, configuration output and test fixtures; do not create different interpretations for each interface.

## Statistics with useful accounting

Forest Pack's documented statistics are a useful usability reference, not an undocumented implementation blueprint. Cyrus should help the artist answer “where did my plants go?” and “why did this update take time?”

Recommended per-set/layer fields:

- Population mode, requested budget/target and allocated share.
- Unique candidates generated; coverage/area eligible candidates.
- Accepted ordinary slots, protected slots, renderable plants and preview-shown plants.
- Rejections by scope: inter-layer, sibling set, self-spacing; cleanup removals; missing source/binding reasons.
- Attempt/repair limits, added refill candidates, remaining shortfall and protected conflicts.
- Snapshot, generation, coverage, assignment, spacing, cleanup, packet-build and upload timings where measurable.
- Cache hit/miss/build counts and invalidation reason; current and peak attributable buffer bytes.
- Exact generation ID and whether this describes the last completed result or a pending operation.

Intentional point-only/placeholder rows can be accepted procedural slots without being final render geometry. Empty source choices and missing assets also need separate semantics; preserve the current source policies and label the resulting counts.

For ordinary candidates, keep one disjoint **final classification** per unique ID in the completed transaction. Its categories must sum to the unique ordinary pool, including `not consumed` after a target/work stop. Protected records are counted separately; transferring a candidate to a protected override must not count it twice. Repeated checks across repair rounds are **work counters**, not extra candidate or removal counts.

Clones introduce additional instance output IDs without additional sampled candidate anchors. Keep candidate accounting and instance accounting as two explicit totals. Count a clone's active protected result once, and label suppressed or unresolved authored records separately. The ordinary pool is the logically exposed pool for this transaction; unrelated cached suffix rows are resident memory, not attempted candidates.

Avoid presenting the sum of all stage measurements as wall time when tasks overlap. A shared source cache is counted once at controller level; a per-layer referenced-byte estimate is explicitly non-additive. A stale displayed scene must not show new pending counts as if they describe its meshes. Reading these fields uses stored statistics and does not invoke the solver.

## MCP: preserve the current boundary, then extend it deliberately

Current MCP 1.1 has nine bounded tools: connection status, scene context, validate/apply plan, controller status, diagnostics, viewport capture, configuration and execution-record export. Plans 1.0/2.0 are closed schemas. Current design automation is limited to Max 2027, a static horizontal convex site, up to three enrolled mesh assets and three owned independent layers, with 2,000 aggregate requested candidates and additional enrollment/capture/application limits.

It can inspect effective layer/set configuration, but it does **not** create Paint Sets or mutate Brush stroke histories. Current capabilities do not include the new three-scope schema, background/refill policy or per-instance radius edits. See [current capabilities](../Layers_First_2026-10-03/CAPABILITIES.md).

After native qualification:

1. Add read-only policy/order/rule/cache/underfill fields to configuration and diagnostics.
2. Design an explicitly versioned plan extension for set ownership, rules, order and fill settings.
3. Add generated-candidate, repair-round and memory/work limits: a 2,000-plant target must not accidentally authorize unlimited attempts under the old 2,000-candidate boundary.
4. Normalize inherited/default values before approval/digest. Reject unsupported geometry, metrics, fields or combinations.
5. Apply all owner identities and rules inside the existing owned transaction before solving; validate fresh scene revision and exact approved digest.
6. Export the actual completed placements and counts, including policy version and bounded-fill outcomes, from one generation.
7. Qualify Undo, cancellation, idempotency, stale approval, ownership boundaries and unchanged legacy schemas.

Reuse the same evaluator as the UI. Do not create a second “AI scatter” algorithm or run arbitrary MAXScript supplied by a client. Existing scope, local approval and export limits remain unless a separate release explicitly changes them.

The current exported IDs are generation-scoped. A new stable cross-generation identity contract must be versioned and validated; matching an old row index is not correspondence. An underfill acceptance policy must consider the actual final result, not just the requested target.

## Future ML connection

The proposed external design companion can eventually produce a typed recipe: zones, asset roles, layer/set order, coverage, density/targets and spacing rules. MCP validates/transports approved operations. The procedural engine computes the result. Display continues to consume retained results independently.

Useful future learning examples include the recipe, receiver/asset context, policy version, actual accepted layout, explicit artist corrections and preference labels. Radius and rejection statistics can explain why a proposal failed, but they are not themselves proof of a good artistic design.

Current records are not automatically training data; their training eligibility is false, and collection/training is not implemented. Maintain the separate consent and lineage workflow in the [Artist Style ML guide](../Artist_Style_ML_2026-10-04/README.md). No model, LoRA, image interpretation or dataset service is necessary to deliver these procedural controls.

## Persistence and migration

- Opening an old scene preserves its old policy and result semantics.
- Offer explicit conversion with a summary of effective order, spacing mapping and changed population meaning; conversion is undoable.
- Retain old edit bindings when provably valid. Otherwise preserve records and report unresolved bindings rather than silently discarding them.
- Save/reopen and merge/copy must reconstruct IDs/references, not depend on process handles.
- Runtime caches are disposable; saved Brush/rules/edits are not.
- A new plugin version may read older scenes; older plugins need not understand new schemas. State that limitation in the conversion UI and release notes without changing old class identities casually.
