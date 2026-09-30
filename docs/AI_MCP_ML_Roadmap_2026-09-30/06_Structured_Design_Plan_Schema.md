# 06 — Structured design and data contracts

**Status: PROPOSED domain contracts v0.1.0.**
The six JSON files are synthetic fixtures, not live results. This document is a contract sketch for implementation; it is not an implemented JSON Schema validator.

## Common rules

Every record has `record_type`, `schema_version`, `example_only` and `evidence_status`. Real records need a unique record/session identity, provenance, permissions, and exact build/host identity. Unknown measurements are `null`, never a fabricated zero.

- Units: lengths in metres, areas in square metres, angles in degrees.
- World coordinates: right-handed, Z up. Regions in v0.1 are simple horizontal world-XY polygons on the enrolled site.
- Polygon vertices are CCW, non-self-intersecting, with no duplicated closing vertex. Holes/exclusions are separate explicit regions; reject degenerate or unsupported boundaries.
- Position/vector arrays contain three finite numbers.
- Stored matrix: 4×4 row arrays representing a column-vector transform. Translation is in the last column. Conversion from Max `Matrix3` is explicit and tested; never merely reinterpret its memory.
- Camera metadata states projection, world transform, frame/time, viewport dimensions and color/display settings.
- IDs are opaque and scoped; names are display text. Model output cannot create an existing-object ID.
- Unknown fields/capabilities are errors in executable plans. Do not silently ignore future features.
- Canonical plan hashing pins key ordering, numeric normalization and schema version. Resolve units/enums before hashing; exclude the digest field itself.
- Stable seeds reproduce a qualified engine/build/input path, not every future version/platform automatically.

The fixture uses three instances only so its complete output is readable. It is not a representative density, benchmark or design recommendation.

## Scene context

[scene_context.json](examples/scene_context.json) demonstrates:

| Field group | Contract |
| --- | --- |
| Identity | Scope, context, scene epoch/revision and time |
| Build | Manifest digest, host year/full version, automation capability version |
| Units | `meters_per_system_unit`, world frame |
| Site | Opaque ID, evaluated bounds/area/triangle count, planarity/eligibility and fingerprint |
| Assets | Approved source ID, category, dimensions, conservative footprint and rights/scope |
| Regions | Artist-confirmed planting and locked/excluded polygons with source/provenance |
| Existing state | Owned/unowned controllers, edit/lock status and generation IDs |
| Observation | Explicit camera/viewport; snapshot freshness |
| Capabilities | Supported plan features and actual adapter limits |

Metadata that requires evaluation must report its revision. A cheap raw-parameter read must not present stale geometry as current. Truncation is explicit with a continuation token tied to the same snapshot, or a request to narrow scope.

## Design plan

[design_plan.json](examples/design_plan.json) is model-neutral and contains no MAXScript, node pointers, credentials or filesystem paths.

| Field | v0.1 meaning and validation |
| --- | --- |
| `plan_id` / `based_on` | Plan identity and exact context/epoch/revision |
| `intent` | Artist-readable purpose; non-executable text |
| `required_capabilities` | Every requested executable feature must be supported |
| `target` | `create_owned_controller`, or `replace_owned_candidate` for the one authorized refinement; replacement requires the owned controller ID and expected generation |
| `assets` | Subset of approved source IDs/categories |
| `zones` | References to enrolled world-space regions; image guesses cannot become geometry silently |
| `layers` | Unique plan-local IDs, role, region IDs, approved sources/weights, explicit population mode and seed |
| `transforms` | MVP uniform scale/yaw ranges, normal alignment and zero movement |
| `source_assignment` | Explicitly random or spatial source assignment; not positional clumps |
| `relationships` | Directed layer/blocker relationships; validate references and reject cycles when semantics require an order |
| `constraints` | Locked/excluded regions, footprint clearance, allowed changes and protected manual objects |
| `edge_placement` / `falloff` | Disabled in MVP; later typed policies with units and supported modes |
| `hero_placements` | Empty in MVP; later explicit anchored/source/footprint records |
| `unknowns` / `assumptions` | What the model cannot infer and how the proposal resolves it |
| `confidence` | Qualitative, uncalibrated explanation; never authority to override constraints |
| `budgets` | Caller-requested limits no greater than local policy |
| `refinement_policy` | One permitted revision with exact field ranges; scope cannot expand itself |

Population is a tagged union: `count` requires a bounded integer; a future qualified `density` mode requires nonnegative plants/m² and a cap. Do not allow both or treat canopy coverage as plants/m². Source weights must be finite and nonnegative with positive effective total.

Population also declares `underfill_policy`: `report` accepts a valid smaller output with a warning; `reject` requires the requested count. Neither allows automatic constraint relaxation or an unbounded refill loop. The fixture uses `reject`.

For `replace_owned_candidate`, require the `bounded_refinement` capability, a fresh `based_on` context, `existing_controller_id`, `expected_generation_id` and the previous accepted plan identity. The replacement carries the complete normalized configuration; validation checks its diff against the approved field envelope. Missing identity or intervening manual edits is a conflict, not permission to recreate the controller.

Future schemas can add texture-density references, positional density fields, edge-row spacing, falloff curves, collision radii, relax settings and per-source axes/offsets. They require a new capability and validation contract, not arbitrary property bags. A disabled field does not imply its enabled form is supported.

### Example layer semantics

The fixture proposes one tree in the tree region, one shrub in a border and one low plant in a third region. All three use approved sources, fixed seeds and no random movement. A protected lawn remains excluded. Initial scene revision 12 becomes revision 13 in the synthetic completed state.

Hard rules are local predicates: approved IDs only; allowed site/region; conservative footprint clearance; no protected/manual object changes; population/resource limits. Soft goals describe composition and style. The model cannot downgrade a hard rule to improve visual similarity.

## Tool execution log

[tool_execution_log.json](examples/tool_execution_log.json) illustrates one synthetic apply operation:

- Request/operation/plan identity, tool name, idempotency key and validation/approval receipt identifiers.
- Before/after revisions and final generation.
- Started/finished timestamps, duration and model usage fields, left null in this non-executed example.
- Requested/emitted/displayed counts and publication/recovery state.
- Structured error field, affected owned IDs and local-only privacy policy.

Logs contain receipt identifiers, not reusable credentials. Detailed raw prompts/images require separate permission and retention; a minimal operational log need not contain them.

## Final layout state

[final_layout_state.json](examples/final_layout_state.json) records the actual published configuration plus transforms and source/layer IDs, not merely the requested plan.

A real export stores the complete output in a bounded local artifact with a content digest; model context gets a summary. The fixture has `complete: true` because all three synthetic instances are present. Large sampled exports must say `complete: false` and record the sampling algorithm/seed.

Persist requested versus emitted versus displayed counts, generation/build/input identity, exclusions, edge/falloff/collision/relax/source-assignment settings, actual source assignments and warning flags. A missing cluster assignment is unknown/not applicable, not an invented cluster label. Save frame, camera and screenshot/render provenance separately.

The effective configuration also stores owned derived include-mask identities and normalized polygons. These are deterministic insets of approved convex planting regions using the conservative scaled footprint plus clearance, not AI-invented regions. Their geometry must be included in transaction/recovery and generation fingerprints.

## Artist correction

[artist_correction.json](examples/artist_correction.json) shows an explicitly explained move within the same generation lineage, from revision 13 to 14.

Record before/after state references, stable subject identity, edit type, numeric delta, artist reason when given, acceptance and consent. Future events include delete, clone with parent ID, source swap, count/density, scale, clustering, boundary changes, undo/rejection and whole-proposal acceptance.

A row index alone is insufficient. If regeneration destroys correspondence, emit a parameter/whole-layout event and mark instance mapping unknown.

## Training sample

[training_sample.json](examples/training_sample.json) demonstrates how a correction could become a pairwise ranking example. It remains `training_eligible: false` and synthetic.

Required real lineage: task and feature version, project/studio split group, source records/digests, label method/reason/ambiguity, candidate-generator version, sampling propensity if known, permissions, and dataset inclusion status.

Only information available before the artist decision belongs in inference features. The preferred final position belongs in the label. Train/test membership is determined by project/studio lineage before deriving point rows, crops or augmentations.

## Schema evolution and determinism

Version separately: automation API, plan contract, stored record contract, capability set, dataset features, engine/build and model/prompt. Store original records immutably; migrations generate derived versions with provenance.

A plan may remain valid while its output changes under a new engine; never conflate schema compatibility with output parity. Pin accepted plans, normalized parameters, seeds, source/site fingerprints, output ordering and build manifests for regression.

**REQUIRES EXPERIMENT:** strict JSON Schema implementation, semantic validators, Max unit/matrix conversions, canonical hashing, rejection fixtures and data migration. Documentation validation checks the provided JSON and cross-record consistency only; it does not qualify a runtime API.

