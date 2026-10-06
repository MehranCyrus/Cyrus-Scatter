# Reference understanding and spatial composition

## Convert references into inspectable intent

A photograph is evidence of a view, not a complete site plan. It contains perspective, lighting, occlusion, lens effects and possibly plants unavailable in the user's library. The first reference feature should extract editable design intent, with confidence and provenance, then map that intent to enrolled assets and feasible Cyrus controls.

Example: an artist supplies a photograph of a loose meadow around a curved walk. The system proposes “continuous low grass background,” “flower drifts near selected sections of the path,” “occasional taller accents,” and “open visibility toward the entrance.” It shows the inferred regions over the image and corresponding proposed regions on the actual site. The artist can correct either.

## Representation layers

| Representation | Useful content | Authority |
| --- | --- | --- |
| Reference observations | Plant masses, height bands, visible paths, palette, negative space, focal regions | Uncertain image interpretation |
| Design brief | Which aspects to transfer; target style, camera priorities, required assets | Artist-confirmed intent |
| Site graph | Surfaces, entrances, paths, beds, buildings, protected objects and relationships | Enrolled Max geometry plus explicit annotations |
| Planting recipe | Roles, asset weights, zones, distributions, ranges, collision rules, coverage and ordering | Validated editable proposal |
| Published layout | Actual identities, transforms, effective radii, counts and reasons | Cyrus evaluation result |
| Render evidence | Images tied to one layout, camera set and renderer configuration | Captured/rendered receipt |

Keep these layers separate. A segmentation mask should not directly overwrite a Brush document. A model's statement that an entrance is visible must be checked against scene geometry or rendered views.

## Spatial relationships worth encoding

Use a small vocabulary: inside, outside, near, far, adjacent, along, between, faces, behind-from-camera, preserves-view-of and separated-by. Each edge carries its coordinate frame, units, endpoints, tolerance, confidence, source and hard/soft status.

For the courtyard example:

- The walking path connects the entrance to the site boundary and stays outside planting exclusions.
- Low grass occupies the remaining approved bed area.
- A flower ribbon follows selected portions of the path with editable width and offset.
- Taller accents remain away from an entrance visibility region.
- Shrub clusters use an artist-approved radius/spacing rule and stop at the bed boundary.

These are proposed design rules, not facts extracted from the existing demo. Route geometry creation is a separate scene-authoring capability; the first scatter assistant can consume an artist-authored path and zones. Native Brush can already author coverage locally, while public MCP authoring remains a gap.

GardenDesigner's relation-based arrangement is useful precedent for this representation. Cyrus should test its own small vocabulary and map it to existing controls before adding a general constraint language. [GardenDesigner](https://arxiv.org/abs/2604.01777).

## Density is only one part of a pattern

Two fields with equal plant count can look very different: uniform scatter, isolated clumps, long drifts or regularly spaced borders. Candidate recipes should expose density, local clustering, cluster size, directional structure, cross-species adjacency and edge response separately where the engine can support them.

Older vegetation synthesis work models local marked-point relationships, while Patternshop separates density from point-pattern correlation. These are useful ideas for measurable descriptors and example-based recipes. Their algorithms are not already in Cyrus; exact code/asset reuse requires a separate license and integration review. [Vegetation distribution synthesis](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0134009), [Patternshop](https://xchhuang.github.io/patternshop/).

Start with descriptive measurements, not a replacement sampler: occupancy at several scales, nearest-neighbour distances by role, cluster extents, height distribution, distance to path/edge and species co-occurrence. Normalize distances by scene units and, where meaningful, plant radius. Report empty/sparse cases explicitly rather than unstable ratios.

Future distribution primitives should be justified by a failed recipe experiment: for example, artists repeatedly want a continuous drift that existing masks plus scatter cannot reproduce. Add that primitive with deterministic seeds, bounded work, stable IDs and ordinary UI controls; then expose it to learning.

## Camera and view dependence

Use two complementary checks. World-space geometry evaluates exclusions, spacing, route clearance and source bounds. View-space measurements evaluate silhouette, depth layering, occlusion, visible colour balance and focal emphasis.

Do not optimize only the hero camera and hide errors behind the building. Include a top view and one or more alternate views. When matching a reference, lock camera/lens/lighting for the initial planting comparison. A later camera-composition feature should be a separate experiment so better framing is not falsely credited to better planting.

The VSI-Bench work studies limitations in multimodal spatial reasoning. It supports testing spatial judgments against ground truth; it does not imply that every newer VLM will fail every spatial task. [Thinking in Space](https://arxiv.org/abs/2412.14171).

## Model components to benchmark, not preselect

| Component | Candidate approach | Cyrus test and restriction |
| --- | --- | --- |
| Reference segmentation | SAM 3 image segmentation; editable manual masks as baseline | Measure plant-mass/path mask usefulness and correction time on actual references. SAM 3.1's March 2026 addition concerns video tracking, so do not assume it improves our still-image task. |
| Visual embeddings | DINOv3 frozen features; simple palette/geometry descriptors | Compare retrieval and preference ranking on held-out sites; do not treat similarity as aesthetic quality. |
| Depth cues | Depth Anything 3 as an optional reference cue | Compare inferred ordering against annotations. Max geometry supplies actual depth for our own renders. No single-photo reconstruction promise. |
| Semantic interpretation | A version-pinned multimodal model with a closed observation schema | Measure role/relationship accuracy, unsupported claims, consistency, cost and correction burden. |
| Learned preference | Small ranker over geometry and optional frozen image features | Compare against curated recipes, retrieval and an artist baseline before a larger personalized VLM. |

The official SAM repository uses its own model license and access process. DINOv3 uses a custom license. DA3's code license does not cover all checkpoints uniformly: its model table lists several large checkpoints as CC BY-NC 4.0 and smaller/other variants as Apache 2.0. Exact checkpoint and dependency terms must be checked before commercial integration; this package selects none. [SAM 3](https://github.com/facebookresearch/sam3), [DINOv3](https://github.com/facebookresearch/dinov3), [DA3 model table](https://github.com/ByteDance-Seed/Depth-Anything-3#-model-cards).

Keep inference dependencies in a separate environment. Measure actual peak memory and latency on the available hardware before choosing a local model. A hosted alternative needs explicit permission for the particular reference/scene images and a documented retention policy. No upload is implied by installing the plugin.

## Reference benchmark

Build an artist-owned set of reference/site/asset tasks spanning restrained architectural beds, informal meadows, borders, woodland understory and mixed shrub planting. Include references with occlusion, unusual lighting and missing matching assets. Artist annotations identify which aspects should transfer and which should not.

Compare four levels: manual brief only; model-extracted brief; brief plus corrected masks; brief plus learned preference reranking. Measure the time to a usable interpretation, constraint satisfaction and final blinded preference. A visually impressive reference analysis is not enough if it produces no better executable recipe.

Record reference rights, allowed use and provenance separately from scene/model ownership. Keep originals distinct from crops, masks and embeddings. A crop or embedding does not remove the need to track its source.
