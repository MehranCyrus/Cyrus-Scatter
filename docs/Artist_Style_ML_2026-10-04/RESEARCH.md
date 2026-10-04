# Research: what should learn an artist's planting style?

4 October 2026. External capabilities below are primary-source facts. Application to Cyrus is a proposal or research hypothesis, not a measured result. Source details and reading limitations are in [sources.csv](sources.csv).

## Separate the problem into four decisions

1. **Interpretation:** What does the artist mean by lush, restrained, organized, natural, or a reference image?
2. **Design:** Which plant roles, proportions, spacing, clusters, rows, open areas and view relationships express that intent on this site?
3. **Placement:** Which actual transforms satisfy receiving surfaces, masks, source dimensions and collision policy?
4. **Display:** How can Max show that already generated layout efficiently?

The proposed learning system addresses the first two. Cyrus already handles substantial parts of the third and fourth. A model may eventually guide candidate placement, but it should still be constrained by the procedural engine. Training a model is not a viewport optimization.

Three different inputs also need different treatment:

| Input | What it can reasonably provide | What remains necessary |
| --- | --- | --- |
| Inspiration photographs/renderings | Visual intent, proportions in the image, composition and example retrieval | Site geometry, scale, source roles and artist confirmation of uncertain interpretation |
| Registered plans/CAD | Explicit zones, dimensions, symbols and placement intent | Units, coordinate registration, symbol-to-asset mapping and ambiguity resolution |
| Authored Cyrus layouts/3D patches | Real positions, plant dimensions, accepted relationships and generation settings | Scope, context, approved usage and transfer to a different site's constraints |

A perspective image is not a labelled 3D planting plan. Depth, occluded plants, camera, focal length and asset size can produce similar appearances from different layouts. An image alone cannot uniquely determine true plant density or hidden positions. This is a design limitation, not something a LoRA automatically resolves.

## What LoRA means here

LoRA adapts a pretrained model by learning low-rank weight updates while keeping its base weights frozen. It is an adaptation method, not a specification of the model's output or an automatic source of landscape knowledge. [LoRA paper](https://arxiv.org/abs/2106.09685)

| Adapted component | Required task examples | Output | Cyrus value / decision |
| --- | --- | --- | --- |
| Image generator | Images and conditioning descriptions | Another image | Optional concept art or paintover; still needs a separate path to editable 3D |
| Image/text encoder | Retrieval or feature-learning examples | Embeddings/features | Possibly improves reference matching; test frozen features first |
| Structured planner | Site, brief, role palette and references paired with accepted typed recipes | Recipe/field parameters | The relevant LoRA experiment if unadapted planning repeatedly misses personal style |
| Small preference model | Alternatives for the same brief, plus the artist's choices | Relative scores | Likely a cheaper first learned component; may need no LoRA at all |
| Spatial generator | Context paired with maps or labelled point layouts | Fields or point sets | Later research; harder data, topology, constraint and editing integration |

The official Diffusers LoRA workflow targets image generation, whereas supervised language-model training can target prompt/completion records. These are different tasks even if both use adapters. [Diffusers LoRA](https://huggingface.co/docs/diffusers/training/lora), [TRL supervised fine-tuning](https://huggingface.co/docs/trl/sft_trainer)

An adapter also depends on a compatible base model and configuration. PEFT checkpoints contain adapter parameters and configuration rather than an independently complete base model. Cyrus should record the exact base revision and preprocessing dependencies. An artist cannot import an arbitrary image LoRA into whichever reasoning model happens to be connected through MCP. [PEFT checkpoint format](https://huggingface.co/docs/peft/en/developer_guides/checkpoint)

**Product decision:** expose “Artist Style Profile,” with optional learned components inside it. Do not make every artist manage model internals. A profile containing references, recipes and explicit preferences is useful before any weights are trained.

## Research that changes the implementation order

### Learning from a small planting patch

The 2015 paper *Sample-Based Vegetation Distribution Information Synthesis* represents plant locations/types as a 2D vector pattern and synthesizes larger patterns through neighborhood histogram matching. It is direct prior art for learning placement relationships from a small example, without an image-generation LoRA. [PLOS paper](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0134009)

**Cyrus inference:** offer “use this planting patch as an example.” Extract role proportions, nearest-neighbor distances, directional regularity and relationships between roles. Fit supported procedural parameters or retrieve a similar recipe. Preserve distances in metres and also report distances relative to source footprints; scaling every coordinate to a unit square would lose useful planting scale.

This does not imply that copying neighborhoods will solve an arbitrary building site. Repeated local patterns do not encode entrances, focal views, irregular boundaries or a complete composition. Test an exemplar method as a baseline inside explicit zones, and measure seams, repetition, constraint losses and style transfer to new assets. A single patch can support a useful local exemplar, but cannot establish broad generalization.

### Learning procedural rules rather than every plant position

*Procedural Urban Forestry* describes environment-sensitive placement models using structural and functional urban zones. Parameters can be authored or learned from satellite imagery and land-register data. [Author publication page, TOG 2022](https://graphics.uni-konstanz.de/publikationen/Niese2022ProceduralUrbanForestry/index.html)

**Cyrus inference:** a model should often predict a compact procedural recipe conditioned on the actual site. This is closely aligned with Cyrus' editable controls. It also makes artist corrections meaningful: changing a planting relationship is a parameter edit rather than replacing an opaque generated mesh.

The paper's public description is not evidence that arbitrary reference photographs can be converted into correct 3D constraints, or that this algorithm has been integrated into Cyrus. The full Urban Forestry PDF could not be retrieved by the web reader because of its size; this assessment relies on its author abstract and publication metadata.

### A recent hybrid landscape system

*LandCraft* (AAAI 2026) combines high-level language-model planning, map generation and procedural 3D construction. The retrieved paper introduction describes layout/height maps feeding parametric generators. [AAAI paper and publication record](https://ojs.aaai.org/index.php/AAAI/article/view/37686)

**Cyrus inference:** the boundary between design intent, spatial representation and procedural execution is a defensible architecture. We do not need to reproduce the entire system: Cyrus already has assets and a scatter engine, and the first pilot can use recipes rather than a learned map generator. The paper does not establish Cyrus performance, per-artist LoRA quality or Max compatibility. Full-paper retrieval was intermittent; no numerical claims from its experiments are used here.

*GardenDesigner* (April 2026 author preprint) describes aesthetic rules, curated garden knowledge, asset selection and layout optimization for Jiangnan gardens. This is another example of domain structure accompanying generative reasoning. It is specialized to its own design setting; its abstract is not a universal landscape-design benchmark. [Author preprint](https://arxiv.org/abs/2604.01777)

### Multiple connected spatial layers

*Coherent multi-layer landscape synthesis* learns from terrain exemplars with related elevation, orientation, soil and vegetation information. [University publication abstract, 2017](https://upcommons.upc.edu/entities/publication/3c942a60-c704-4848-a327-51f0b975bfd9)

**Cyrus inference:** learning each vegetation layer independently can lose the relationship between trees, shrubs, paths and open space. Our records should preserve the complete planting context and pair relationships. Terrain ecology remains an optional separate product scope, not a capability claimed by artistic style learning.

## Production procedural systems as design references

Houdini Scatter and Align exposes density, scale/orientation and relationships to constraint points; Epic PCG works with points carrying transforms, bounds, density, seeds and metadata. Both support the usefulness of explicit, inspectable intermediate data. They do not establish the private implementation of FStorm, Chaos or tyFlow. [SideFX Scatter and Align](https://www.sidefx.com/docs/houdini/nodes/sop/scatteralign.html), [Epic PCG overview](https://dev.epicgames.com/documentation/en-us/unreal-engine/procedural-content-generation-overview)

For Cyrus, the practical lesson is to keep roles, zones, density, spacing and transformations explicit. We should reuse and qualify existing native algorithms before inventing a neural replacement. In particular, current Diversity clustering controls source assignment, while native boundary-row code already exists. Neither is currently available as a general learned-pattern interface through MCP. See the [source audit](CODEBASE_AUDIT.md).

## Model options worth testing, not installing by default

| Candidate | Verified purpose | Bounded Cyrus experiment |
| --- | --- | --- |
| SigLIP 2 | Image/text representations for tasks including retrieval | Retrieve approved recipes from reference images after filtering by plant roles and site type |
| DINOv3 | Visual features; its model card recommends frozen features before fine-tuning | Compare visual structural similarity for references and standardized planting previews |
| SAM 3 | Promptable image/video segmentation | Help an artist mark vegetation or protected image regions; it does not provide world-coordinate registration |
| Linear pairwise model or boosted ranker | Relative preference prediction; XGBoost documents query-group ranking | Rank already valid alternatives within one brief and site |
| Trainable structured planner with optional LoRA | Supervised adaptation to chosen output task | Improve valid recipe proposals if retrieval plus a base planner underperforms |

Primary references: [SigLIP 2 paper](https://arxiv.org/abs/2502.14786), [Google model card](https://huggingface.co/google/siglip2-base-patch16-224), [DINOv3 model card](https://raw.githubusercontent.com/facebookresearch/dinov3/main/MODEL_CARD.md), [SAM 3 repository](https://github.com/facebookresearch/sam3), [XGBoost ranking guide](https://xgboost.readthedocs.io/en/stable/tutorials/learning_to_rank.html).

These models are alternatives for separate jobs. Loading all of them would create avoidable dependencies and memory use. No base model, adapter format implementation, inference provider or training hardware has been selected. Pin code, weights, preprocessing and applicable distribution terms when an experiment actually chooses one.

## What a style should describe

“Dense jungle” and “clean formal” are not merely different count values. Proposed descriptors include:

| Dimension | Lush/natural tendency | Formal/restrained tendency |
| --- | --- | --- |
| Spatial organization | Patches, variable gaps, overlapping height bands | Repetition, alignment, controlled spacing |
| Mix | Several complementary roles | Limited palette or repeated role sequence |
| Scale | Wider variation where appropriate | Narrower ranges or deliberate accents |
| Open space | Irregular clearings and transitions | Legible boundaries and deliberate voids |
| View composition | Depth layers and partial screening | Clear facade views and focal placement |

These are editable starting interpretations, not universal aesthetic rules. A profile must allow an artist to like dense vegetation but dislike facade obstruction, or prefer formal paths surrounded by natural planting. Hard project constraints override profile defaults. Camera-specific composition is an explicit mode; it must not move plants whenever the artist orbits the viewport.

Maintain both scales of design: local relationships between neighboring plants and the site's overall composition. A locally convincing jungle pattern can still frame a building badly. Pair authored patches with project context and deliberate open-space decisions; a model of small neighborhoods alone is not a complete composition model.

## Decision register

| Decision | Rationale | Revisit when |
| --- | --- | --- |
| Separate design companion | Keeps training dependencies and long jobs outside Max | Integration measurements justify a different boundary |
| Style profile before personal LoRA | Makes references and examples useful with little data | A trained adapter wins against the same unadapted baseline |
| Reuse recipes and test authored patches | They contain controllable parameters and measurable spatial data | Tests expose patterns the current vocabulary cannot express |
| Rank whole valid layouts first | Matches current generation-scoped exports | Stable candidate exchange and correction semantics are qualified |
| Keep procedural constraints authoritative | Style predictions may be wrong or conflict with the site | No planned relaxation of this responsibility |
| Keep rendering separate | ML design quality and viewport throughput are different measurements | No planned inference during ordinary redraw |
| Treat learning as optional | A profile and scene should remain usable without model runtime | No planned dependency of ordinary scatter editing |

The simplest useful baseline should be measured before additional model complexity. This ordering is consistent with Google's engineering guidance on establishing metrics and simple systems early; it is not proof that the simplest system will ultimately win. [Rules of ML](https://developers.google.com/machine-learning/guides/rules-of-ml)
