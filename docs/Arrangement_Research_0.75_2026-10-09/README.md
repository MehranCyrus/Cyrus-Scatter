# Layout / source assignment investigation — Cyrus Scatter 0.75

9 October 2026. Research only: no product code, installed plugins or artist scene changes. Baseline `30df5cd` on `codex/workflow-0.75`. Scatter script SHA-256 `48c702736169748d2b4526cf6439d4cf96997bfc17ddc3a792d50e09e3e4aea8`; native 0.75 build and unchanged Analyzer 0.14 sources verified against their build receipts. An isolated Max 2027 process used private file transport, without computer use. See [evidence](EVIDENCE.json), [measured results](results.json), and [reproducible probes](Probe.ms).

## Conclusion

Promote this capability to a dedicated **Layout** rollout immediately after Models. It is a central design tool, currently buried under Models > Advanced. Keep only the selected mode's essential controls visible. Do not expose every existing parameter at once.

The section combines three different operations: model mixing, band-based eligibility, and explicit placement along guides. Calling everything "Source assignment" obscures those distinctions. Moving the radio buttons alone will not resolve the confusion around Amount, color groups, stale Analyzer data and the overloaded word "stroke".

## What the engine does

| Method | Actual operation | Good use |
|---|---|---|
| Random | Weighted model choice at surface candidates | General grass/tree/rock mixtures |
| Clusters | A spatial field chooses a source color group, then weights choose a model within that group | Species patches and natural planting mixtures |
| Line Pattern | Closed spline bands filter candidates and assign an allowed model; the first matching band wins | Flower strips, nested shrub bands, garden borders |
| Analyzer Border | Inward bands along the published boundary | Planting just inside an island/lawn |
| Analyzer Centerline | Bands around published central paths | Planting through a median or elongated island |
| Analyzer Points / Radius | Bands/rings around published sample points | Small planting pockets |
| Analyzer Points / Single | Explicit anchors at published sample points | One object per designed point |
| Analyzer Street Side | Inward bands on street-facing boundary segments | Roadside planting with end trims |
| Analyzer Edge Border | Explicit row anchors along a boundary; spacing controls count | Regular shrubs, bollards or edge elements |

The methods belong to the layer. Random/Clusters are alternatives to guided assignment in that layer, not simultaneous switches. Use separate layers for independently controlled ground cover, border planting and a regular tree row. Painting, Include/Exclude, transforms, spacing and cleanup remain additional constraints; the final accepted layout can change when model-specific radii or transforms change.

### Random and Clusters

The clustering field is evaluated in spatial/world coordinates, using Size, Seed, Roughness, Blur edge and Noise. Groups are currently identified by exact source group colors. Group probability uses the sum of member weights; model choice within a group also uses weights. Thus grouping three equally weighted variants together gives that group more overall weight than a group with one variant. There is no independent named-group weight control in this UI.

The assignment color group is distinct from the model's viewport identification swatch. This is an especially important usability problem: changing the attractive swatch beside the model name does not change the cluster group.

Measured on a 10,000-candidate flat plane, with other placement-changing rules disabled:

- Model weights 1 : 0.25 produced 7,959 and 2,041 instances.
- Switching to Clusters retained all 10,000 positions.
- Changing the cluster seed changed 6,300 model choices and retained all 10,000 positions.
- Changing an identification color preserved the full placement/model fingerprint.
- A zero-weight source received zero placements; the other source received all 10,000.
- An unchanged evaluation left the prepared-build counter at 4 → 4.

These prove the behavior in the controlled setup, not that changing model assignment can never affect downstream collisions or source-specific transforms.

### Spline bands

Pick a closed spline, add an Inside or Outside band, set width, choose models, and update. Widths accumulate separately for each side of each guide. A 50-unit outside band followed by a 100-unit outside band covers distances 0–50 and 50–150. These are geometric bands, unrelated to freehand Painting history.

On a 400 × 400 rectangle with 10,000 candidates over a 1,000 × 1,000 receiver, those bands yielded 865 and 2,214 instances respectively; all 3,079 checked positions had the expected band and model. Empty band configuration yielded zero output. Overlapping identical guides yielded 1,894 instances, all assigned by the first guide's band; swapping the assigned models changed the winner as expected. This is ordered priority, not a union that mixes every overlapping rule.

Spline bands use **world XY projection**. Raising the guide 300 units in Z preserved the full output fingerprint. This is useful for top-down landscape design, but must not be presented as surface-following distance on arbitrary curved geometry. Analyzer border bands use different planar geometry tests; they do not share this Z-independent behavior.

Candidate-budget and accepted-target modes also matter. A narrow band with Amount 1,000 produced 202 accepted plants in candidate-budget mode. Bounded accepted-target mode reached 1,000 in this simple case. It is not an unconditional fill guarantee: spacing, domain area and retry limits can still prevent completion.

### Surface Analyzer relationship

The separate Analyzer owns the analyzed surface, analysis settings, street guide and published boundary/centerline/point outputs. Scatter consumes that publication. The receiving surfaces still belong to Scatter; linking an Analyzer does not add its surface to the layer automatically.

On the test plane the real Analyzer published 48 boundary vertices, 38 path vertices, 5 points and 24 street vertices. With a 3,000 candidate budget, the individually tested channels produced:

| Channel | Accepted count |
|---|---:|
| Border band | 907 |
| Centerline band | 240 |
| Point radius | 219 |
| Single points | 5 |
| Street-side band | 239 |
| Edge row | 50 |

These are fixture-specific measurements, not density promises. Edge rows remained at 50 when Amount doubled to 6,000. Amount zero disabled output. The UI therefore needs to say that row spacing / Analyzer point count drives placement in these modes while preserving the existing zero-amount behavior until a deliberate contract change.

Repeated evaluation preserved Analyzer analysis count 3 → 3 and Scatter prepared builds 8 → 8. Changing the surface width and evaluating Scatter did not run a Manual Analyzer. Explicit Analyze advanced its count to 4 and generated a 55-object edge row. Moving the receiver 10 units in Z while retaining its old Analyzer publication changed border output from 831 to zero. This is a reproduced stale-guide mismatch, not evidence that automatic Live scheduling is broken; Live timing was not qualified in this campaign.

The Analyzer explicitly rejected a closed sphere: `Use an open planar surface, not a closed solid.` Open planar elements are its intended input. This limitation is separate from Cyrus Brush's curved-mesh support. Closed/nonplanar use must not be implied by a generic "Analyze Surface" label.

An existing Analyzer assignment regression also passed: source choice isolation, stable edge anchors after population growth, unchanged-data cache reuse, and scene save/reopen fingerprint preservation.

## UI findings and proposed design

1. **Dedicated Layout rollout:** after Models, before Amount. Mode selector: Random mix / Clusters / Spline bands / Surface Analyzer. Show a one-line explanation of what drives placement. Do not move unrelated source-container setup into Layout.
2. **Essential controls first:** cluster Size/Seed and named group membership; spline guide list, band list and selected band's width/models; Analyzer link, status, channel and selected band's/row's essential settings. Put noise, jitter, corner handling and detailed rotations in collapsible Properties.
3. **Clear band terminology:** Consecutive strokes → Bands; Add Inside / Add Outside remain explicit; Remove Stroke → Remove band. Show start–end distances and model names in list rows. Edge Border entries should say Rows and Spacing, not strokes/width.
4. **Visible precedence:** list order matters when guides overlap. Provide deliberate reorder controls and state "First matching band wins". Reordering consecutive bands also changes accumulated offsets, which must be explicit. Do not silently change overlap semantics while redesigning the UI.
5. **Named groups instead of raw color codes:** keep stable identities, add readable group names and model membership; use colors only as a visual aid. Make group probability and within-group model weights understandable. Existing exact-color grouping cannot simply be renamed as though named groups already exist.
6. **Respect Scatter aliases:** the band source picker currently displays scene `node.name`, while Models displays `sourceLabel`. A verified alias of "Friendly grass" leaves the scene name "P07_Asset". Use the Scatter label consistently and retain the scene name in a tooltip. This is a source-confirmed UI mismatch; no physical screenshot was taken.
7. **Analyzer link card:** linked node, analyzed receiver, state (ready / dirty / missing / unsupported), and Pick / Select / Update Analyzer actions. Add Create from selected layer receiver only after defining which receiver to use in a multi-surface layer. The present model has one assignment Analyzer per layer; multi-Analyzer support is a separate model change.
8. **Honest empty states:** "Pick a closed spline", "Add a band", "Choose models", "No guide on the receiving surface", "Update Analyzer". The current disabled controls and "Outside strokes: empty" text do not explain the next action well.
9. **Amount feedback:** candidate-budget filtering, accepted-target retries and fixed rows/points need distinct help text. Show requested/accepted or row-driven count without claiming Count controls every arrangement the same way.
10. **Guide preview:** investigate band extents and the active band highlight as a separate feature. Do not claim the existing Analyzer boundary/point guides already preview the complete Scatter band allocation.

The Analyzer is also linked separately for Include/Exclude masks and edge falloff (`analyzerNode`, `areaAnalyzer`, `fallAnalyzer`). A clearer UI should distinguish "layout guide", "area mask" and "falloff guide" and may offer explicit link reuse. It must not silently make all three use one node and change existing behavior.

## Performance witness and limits

Three seed-changing evaluations per mode at 100,000 candidate budget, followed immediately by unchanged evaluation, measured `evaluateGroups()` wall time. Simple source geometry, no viewport drawing or render qualification:

| Mode | Changed-input median | Unchanged median | Final accepted count |
|---|---:|---:|---:|
| Random | 454.125 ms | 5.2171 ms | 100,000 |
| Clusters | 478.2178 ms | 6.1582 ms | 100,000 |
| Spline band | 129.2839 ms | 5.3582 ms | 19,428 |

Spline band timing included one 471.919 ms outlier; raw samples are retained. Its smaller accepted result makes it an unequal-output comparison. These measurements are not presented FPS, heavy-tree performance, an end-to-end interaction benchmark or an incremental assignment-only performance guarantee.

Focused native tests passed: scatter assignment/Analyzer/cleanup tests, 160,000 prepared-band differential queries, and edge-row spacing/offset/jitter/mask/collision tests. No whole-project rebuild was necessary because product files were unchanged.

## Next bounded implementation

First deliver the dedicated Layout rollout, clearer labels, consistent source aliases, visible Analyzer link/state and useful empty states. Keep engine behavior and saved ownership unchanged. Then qualify actual controls across selected-layer, popup and container views, independent layer switching, Manual/Live updates, Undo/Redo and save/reopen. Follow with named model groups and guide previews as separately defined changes.

Outstanding research: physical UI/DPI and interaction, automatic Analyzer Live scheduling across all dependencies, many guides / large source libraries / heavy geometry, nonplanar guide alternatives, aggregate memory, named-group migration and multi-Analyzer ownership. No claim that these gates were completed here.
