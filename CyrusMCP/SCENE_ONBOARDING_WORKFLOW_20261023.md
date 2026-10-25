# Scene onboarding, artist input and planting workflow

23 October 2026. Product/workflow design proposal, not implemented MCP behavior.
Companion to the [system design review](SYSTEM_DESIGN_REVIEW_20261023.md) and
[research](RESEARCH_20261023.md). The current public authoring subset still requires
local enrollment of restricted inputs and exact local approval; it does not survey
an arbitrary scene, classify plant assets, create general design zones or edit
arbitrary existing artist setups. This proposal does not expand that authority.

## 1. Product decision

The normal entry should be **choose where to work and describe the desired result**.
The assistant proposes the planting composition, technical settings and output
organization. Ask the artist only for decisions that cannot be obtained from
current scene evidence, an existing approved choice or a reasonable visible
proposal. Optional organization should accelerate this experience without becoming
a prerequisite.

Do not require every artist to rename objects, build source containers, draw all
flower beds, prepare Scatter layers or calculate densities before assistance can
start. Equally, do not promise that an AI can infer the intended site, plant roles,
property boundary or preservation rules from an arbitrary mesh collection alone.
Use selection and a small role review to resolve the important ambiguity.

The key distinction is **source assets versus planting destinations**. Asking the
artist which mesh is a flower prototype can be necessary. Asking the artist to
design every flower location defeats the purpose of the assistant. A prototype's
current scene position does not imply where its instances should be planted.

## 2. Minimum information: needed by the system, not necessarily typed by the user

| Information | Preferred source | Ask only when |
| --- | --- | --- |
| Work area/setup | Current selection, selected Scatter's receivers, an explicitly picked surface/boundary | The target is missing, ambiguous or unsupported |
| Desired outcome | The artist's short brief or a choice such as natural meadow/formal planting/decide for me | No meaningful goal can be inferred from the request |
| Usable source assets | Existing enrolled palette, confirmed scene prototypes, qualified installed library | Asset roles/availability are unclear or import requires a new decision |
| Preservation constraints | Preserve existing work and all objects outside the approved change by default; apply any explicit brief | The requested design conflicts with existing work or needs additional authority |
| Physical scale | Scene units plus checked source/receiver dimensions | Units/geometry are inconsistent enough to make the result materially wrong |
| Artistic preferences | Existing task choices, matching recipe, or a stated proposal | Different interpretations would substantially change the intended result |

A complete brief can require no clarification before presenting a proposal. A
partially specified brief can still permit useful read-only inspection. A missing
target or contradictory scale must be resolved before geometry-changing work.

The ordinary archviz workflow does not need a mandatory questionnaire about exact
species percentages, plants/m², seeds, collision factors, soil or irrigation.
If the artist requests a real planting specification, its additional requirements
are a separate product scope; do not treat a visual composition as that deliverable.

## 3. Normal artist journey

### A. Select and connect

The artist selects a receiving surface, an existing Scatter setup or an intended
boundary and starts assistance. Selection supplies intent; the local connection
review still determines read/edit authority. A boundary alone is not necessarily
a receiver. If there is no suitable surface, explain the missing prerequisite or
propose a separately supported surface-creation action rather than pretending
the curve supplies terrain elevation.

The artist can say: “Create a natural meadow here with occasional flower patches.
Keep the drive clear and preserve the existing trees. Use the installed library.”
That supplies a goal, scope cue, constraints and asset policy. No density or source
weight questionnaire is necessary to start.

### B. Survey the relevant scene

Use bounded hierarchy/layer/object metadata around the selected target first.
Inspect only potentially relevant geometry more deeply. Report units, target
extent, source availability, obvious existing planting and supported dependencies.
No implicit scatter Update, full-scene mesh export, asset import or scene repair
belongs in this survey.

Names, groups and materials are hints. Geometry can establish measurements and
relationships, not the artist's semantic intent by itself. A flat object could
be terrain, a roof, paving or an imported drawing. An existing garden tree could
be preserved context, a source prototype, or both in different roles.

### C. Establish a small role map

| Role | Meaning |
| --- | --- |
| Work surface | Approved receiving geometry |
| Design boundary/zone | Where a composition is allowed or requested |
| Keep-clear constraint | A path, hardscape or approved obstacle footprint/setback |
| Source prototype/palette | Geometry available for repeated placement |
| Existing work to preserve | Scene objects or specific existing Scatter owners/results |
| Context | Readable surrounding geometry that helps interpretation but is not a write target |

These are task-specific bindings, not a mandatory exclusive tag on every scene
object. A building can be context and contribute an approved exclusion. Role
classification does not grant permission to edit that building.

Show only relevant assignments, with direct pick/highlight/correction where
supported. Record the evidence as artist assigned, previously confirmed, library
metadata or inferred. Use explicit unresolved status for important uncertainty;
do not fabricate calibrated confidence percentages.

### D. Ask only blocking or consequential questions

Examples: which of two ground surfaces is the work area; which unnamed curve is
the driveway; which of several unclassified prototypes are flowers; whether a
roof is a planting surface; whether existing planting may be replaced. Prefer
showing candidates and letting the artist pick to asking them to type internal IDs.

### E. Propose the composition and assets

The assistant chooses suitable supported recipes/operations and proposes the
distribution of grass, flowers, shrubs and trees. It can propose new planting
zones; it should not require the user to draw every one. Exact authoring methods
must be capability-gated: native Paint Areas, Paths/Bands, assignment groups and
maps have different semantics and current MCP support is limited.

Show source thumbnails/names, intended work zones, preservation rules, broad
planting character and important assumptions. If the installed library lacks a
required role or dependency, offer available alternatives or ask for sources. Do
not silently download assets or represent placeholders as finished planting.

### F. Review one coherent plan, then evaluate

The review should state where work will occur, the asset palette, which existing
work is preserved, what the main planting rules mean, and whether Update will run.
Put numeric settings and cost estimates in expandable detail. Exact local approval
continues to apply to the complete normalized proposal; do not ask for permission
for each individual spinner change.

Prefer cheaper display representations of the actual intended population for
review. Lowering viewport display limits is not lowering planting density. If a
large site needs an explicitly approved test patch, label it as a partial trial;
do not pass it off as a complete low-cost solution.

### G. Refine the result in the artist's language

Support requests such as “fewer flowers near the entrance,” “larger patches,”
“shorter plants by the path,” or “keep that tree.” Resolve references against the
task's remembered bindings and current scene revision. Preserve unrelated owners,
seeds and constraints. Do not rerun onboarding or reclassify every asset after a
small density change.

If a refinement changes the approved proposal, use the existing validation/approval
lifecycle for that new concrete effect. After reconnect or geometry changes,
revalidate the relevant bindings rather than assuming stored consent still applies.

## 4. Question policy

| Situation | Recommended response |
| --- | --- |
| Target or authority is unknown | Ask for the surface/setup or intended change boundary before applying anything |
| Units/scale conflict | Show the measured conflict and ask for a known dimension or corrected units; do not rescale originals silently |
| Ambiguity would change topology, preservation or main design intent | Ask one focused question with visible alternatives |
| Cosmetic preference is unspecified | Make a reversible proposal and show the assumption |
| Existing brief or confirmed binding already answers it | Reuse it without asking again |
| Useful information can be measured/read | Inspect rather than asking the artist to calculate or transcribe it |
| Feature is unavailable | Explain the boundary and propose supported alternatives, not an arbitrary-script workaround |
| User says “decide for me” | Choose a stated composition within the approved area/assets and show a review; no unlimited authority is implied |

A useful default interaction budget is one small batch of the important questions,
then a proposal. This is a design preference, not a measured universal question
limit. A fully specified request should not trigger that batch mechanically.

Examples of useful questions, asked only where unresolved:

- “Use the lower terrain or the raised courtyard?”
- “Are these selected models the palette, or may I use the installed library?”
- “This curve could be the property edge or a path. Which role should it have?”
- “May this existing grass layer change, or should the new planting be added beside it?”

Avoid asking for exact seeds, per-axis transform ranges, technical collision
multipliers or density values as ordinary onboarding. Offer an advanced detail
path for artists who already know those values.

## 5. Density, ratios and visual coverage are different

The maintained [artist guide](../docs/ARTIST_GUIDE.md) defines weights as relative
selection frequency, Surface random Count/Density, bounded accepted targets,
different grid population semantics and collision/mask effects. The workflow must
translate visual language into those actual contracts.

| Artist phrase | Interpret carefully |
| --- | --- |
| “Dense grass” | Desired appearance; actual density depends on clump footprint, scale, spacing, masks and view |
| “30% flowers” | Could mean instance mix, flowering-bed area or visible color; ask if the distinction changes the design |
| “30 flowers” | A count intent; exact acceptance requires a qualified feasible target mode and explicit underfill behavior |
| “Flowers over 30% of the garden” | A zone/coverage intent; source weights do not directly establish it |
| “Grass with occasional flowers” | Usually enough for a proposed composition with no numeric clarification |
| “Formal rows at this spacing” | Layout/pitch intent; random population density is not an interchangeable control |

Weights do not guarantee an exact final ratio after spacing, masks and cleanup.
The same grass density can look completely different for one-blade and large-clump
assets. A conservative bounding radius is not a measured botanical coverage area.
Do not present a visual coverage estimate as exact physical coverage.

For ordinary design assistance, let the assistant choose an asset-aware starting
recipe and reveal its resulting numeric values. Use the native evaluation and
matching visual review to refine it. No universal plants/m² value can be justified
from the scene's label alone.

Use separate logical layers when roles need independent regions, density,
clearance or refinement. Use source weights within a shared population for
appropriate model/species variants. Do not blindly translate “70% grass / 30%
flowers” into two weights when the artist actually means flower-bed area.

## 6. How much scene organization should the artist do?

### Required

- The work target must be identifiable and within a supported geometry/authority
  scope. Selection or picking is sufficient; special naming is unnecessary.
- The system must have usable source models or an approved available library.
- Physically meaningful dimensions/units must be recoverable, and material
  ambiguities about protected work must be resolved.

### Helpful and optional

- Keep prototypes together or on an existing Models/Assets layer.
- Use meaningful names or existing categories for terrain, paths and source types.
- Select only the models intended as the palette when available.
- Reuse saved task/recipe role bindings where supported and still valid.

The UI can understand the artist's existing organization. Do not impose a mandatory
`AI_*` naming scheme, a fixed Max layer tree or source containers. Containers
remain optional palettes with their existing pivot/membership semantics.

The assistant should not rename, move or regroup existing objects just to improve
its own discovery. Ask only when actual scene reorganization is requested. It can
organize its approved new output into readable Scatter logical layers, leaving
the underlying scene's organization intact. Scene layers and Scatter's logical
planting layers are different concepts.

For recurring scenes, an explicitly saved lightweight role map is more useful
than repeated naming instructions. The first implementation can keep mappings
within enrollment/task state. Saving mappings into a scene is an authored action
with persistence/Undo semantics, not a hidden side effect of inspection. Bind to
supported scene references and IDs; do not assume a display name or transient
handle remains a permanent identity across merge/reopen/replacement.

## 7. What can be inferred, measured or only proposed?

| Item | Treatment |
| --- | --- |
| Units, bounds, mesh/spline type, closed/open state, measured slope/area | Deterministic bounded host/native inspection, with explicit failure/availability |
| Current source assets and receiver bindings on an existing setup | Read authoritative configuration |
| “This is a flower species” from an arbitrary mesh | Prefer curated metadata/artist confirmation; visual/name evidence is provisional |
| “This shape is the legal property boundary” | Requires an explicit task binding; geometry alone does not prove it |
| Building footprint or keep-clear region | Derive only through a qualified method, show assumptions and preserve courtyards/holes; bounds are only a coarse discovery aid |
| Which entrance/view is important | Use a stated brief/selected reference or ask if it materially affects the design |
| Desired composition | AI proposes from the brief and available assets; artist can correct it |
| Exact visual coverage | Requires a defined metric and appropriate evaluation; do not equate counts or circle bounds with it |

Hidden/frozen/locked flags help determine available actions and preservation, not
semantic roles by themselves. Existing placed trees and generated populations
must not automatically become source prototypes. A building's upper terrace may
be an intended receiver; never assume all upper surfaces should be excluded.

## 8. Concrete example with minimal artist work

Scene: a building, a ground mesh, several curves and loose plant models.

1. Artist selects the ground and says, “Natural planting with flower patches.
   Keep the drive clear and preserve these existing trees.”
2. The system records the approved work area and surveys nearby relevant inputs.
3. If curve roles are unclear, show the likely drive outline and ask the artist
   to confirm/pick it. If prototype roles are unknown, show the small candidate
   palette once. Skip these questions when existing bindings already resolve them.
4. The assistant proposes a grass base, flower zones and any other explicitly
   justified planting, with qualified sources and constraints. It decides the
   zones rather than requiring the artist to place every flower bed.
5. Review: identified work surface and path, chosen palette, preservation of the
   building/trees, planting character, important numeric choices and expected work.
6. After the required proposal approval, apply through the shared engine and verify
   actual placement/exclusions and preserved objects/identities.
7. Artist says, “Fewer flowers by the door, and larger patches farther away.” Reuse
   the current task map and change only the relevant supported owners.

The unresolved “door” reference can be picked or clarified if the scene has several
entrances. Do not infer a critical entrance from one camera image and claim it was
confirmed. This is a future acceptance scenario, not a demonstration of today's MCP.

## 9. Fast discovery without a scene-cleanup project

Use progressive inspection: selected setup/receiver → relevant hierarchy/layers →
coarse bounds/types → selected geometry and relationships → optional shared visual
context. Keep computation on the host thread/native copied-data boundaries already
defined by the foundation. Neither expensive geometry work nor all-scene scans
become safe merely by labeling a call “analysis.”

Cache confirmed task roles and passive metadata by their applicable revisions.
Changing grass density should not trigger whole-scene classification. Changed
receiver geometry invalidates the relevant spatial bindings; changing a label
should not silently remap them. Context images must retain viewport/camera and
publication provenance and do not grant broader scene sharing authority.

For a very large imported architectural scene, one explicit target pick is usually
a better starting decision than attempting exhaustive semantic reconstruction.
This is a proposed interaction strategy; its speed must be measured on real tasks.

The initial useful workflow can work with explicit targets and a small reviewed
palette. More automatic scene discovery can be added incrementally after that
path is reliable. No general scene-classification model is required for the first
vertical slice.

## 10. Implementation and acceptance

Build these capabilities into the existing architecture:

| Capability | First useful implementation |
| --- | --- |
| Scoped survey | Small typed overview for selected setup/receivers and relevant candidate references |
| Task role map | Receiver, boundary, keep-clear, source palette and preserve bindings, with evidence/unresolved state |
| Asset roles | Curated library categories and one-time artist assignment for unknown scene prototypes |
| Intent brief | Outcome, hard constraints and optional preferences; preserve explicit versus proposed decisions |
| Clarification | Only unresolved consequential choices; support object picking/role correction |
| Proposal | Readable spatial/asset/planting summary, numerical details and normalized effects |
| Evaluation | Existing native pipeline, explicit Update, actual output and preservation witnesses |
| Refinement | Reuse task bindings and change a narrow set of owners without starting over |

No independent planning database, mandatory organizer or broad script tool is
needed. Use current enrollment/validation/apply machinery, extending typed
capabilities where actually required. Role discovery and plan authority remain
separate. The API must explain when a requested layout, source type, receiver,
exclusion derivation or existing-setup edit is unavailable.

Acceptance cases should cover an unorganized scene with explicit selection; a
well-organized scene with no required renaming; reused existing Scatter bindings;
several plausible receivers; unnamed sources; source assets positioned beside
their future site; ambiguous curves; separate roof/ground receivers; corrupt scale;
missing library roles; weighted mix versus area-coverage requests; preserved
existing trees; and a small refinement after geometry or session changes.

Measure correct target/role selection, consequential clarification count, task
completion, preservation, unsupported reporting, model/tool cost and time to a
useful reviewed proposal. Test whether the artist can correct a mistaken mapping
without restarting. A low question count alone is not success if the resulting
scene is wrong. A complete brief should not be punished with redundant questions.

## Research and source basis

Source semantics were checked against [the artist guide](../docs/ARTIST_GUIDE.md),
[the recipe/library workflow](../docs/plans/preset-gallery-improvements/ARTIST_WORKFLOW.md),
[foundation ownership/randomness/dependency contracts](../docs/ENGINEERING_FOUNDATION.md),
and the current MCP enrollment/context/panel implementation. These establish
current ownership and limits, not automatic scene understanding.

Microsoft's [Human-AI Interaction guidelines](https://www.microsoft.com/en-us/research/project/guidelines-for-human-ai-interaction/)
support making capabilities/limitations understandable, resolving uncertainty,
efficient correction and granular feedback. They inform this design but do not
prove that the specific Cyrus workflow is optimal. OpenAI's
[use-case planning guidance](https://developers.openai.com/plugins/plan/use-case)
similarly starts from user goals and required context. Chaos's official
[Objects](https://docs.chaos.com/display/VMAX/Objects%2BRollout) and
[Areas](https://docs.chaos.com/display/VMAX/Areas%2BRollout) documentation provides a
familiar example of separating receivers, instanced models and exclusions; it is
not a specification for Cyrus or evidence of either product's internal algorithm.

This proposal is for review before implementation. No scene roles were assigned,
no artist objects were reorganized, no new MCP tools were implemented, and no
plugin/client configuration or Max session was changed.
