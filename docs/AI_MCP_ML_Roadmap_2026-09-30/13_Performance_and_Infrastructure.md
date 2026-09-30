# 13 — Performance, deployment and future infrastructure

**Status: PROPOSED budgets and deployment options; no inference or AI performance measurements exist.**

## Keep the AI loop from becoming a bottleneck

A fast scatter engine can still feel slow if every parameter causes a network call, whole-scene export or render. Batch one plan, evaluate one candidate, capture one matching view and make at most one refinement.

Measure:

`total task time = context/evaluation + upload/network + model + validation + mutation/generation + preview/capture + artist review/corrections + recovery`.

Record cold/warm paths, helper startup, model load, cache hit/miss and renderer contention separately. Use operation IDs and parent/child spans; do not log one string per instance.

The [performance roadmap](../Performance_Roadmap_2026-09-28/README.md) still governs CPU optimization, multithreading and optional OpenCL. AI inference acceleration and scatter-engine acceleration are distinct decisions.

## Bounded representations

| Work | Proposed first control |
| --- | --- |
| Scene context | Selected scope only; 64 KiB response; coarse bounds/area/occupancy and source cards |
| Geometry | Local evaluated snapshots with triangle caps; never send the raw scene by default |
| Instance data | Complete local artifact for evaluation; summary/sample to model with explicit completeness |
| Plans | 32 KiB, three layers/sources, 2,000 aggregate requested instances in pilot |
| Tool calls | High-level apply; 24-call total including backoff polls |
| Viewports | Two captures; max 1,536-pixel long side and 2 MiB each; fixed view/revision |
| Point preview | Proposed 20,000 sampled-point ceiling in the pilot, separate from emitted count |
| Render previews | Disabled in MVP; later strict renderer/time/image budgets |
| Cache | Key by scene/context/generation/camera/display/model/preprocessing versions; invalidate on relevant change |
| Network | Timeouts, cancellation and explicit pending status; no network wait inside host transaction |

All figures are experiment policy candidates. They are not measured safe maxima. Use admission checks before mesh copies, density-map evaluation, image decode and generation.

Large scenes require metadata pagination, bounded geometric summaries and dirty-region awareness. Cache summaries only when their input fingerprint/revision remains valid. Never silently substitute a sample for complete constraint validation.

## Minimum hardware policy

**PROPOSED product target carried forward:** at least 32 GB system RAM; intended compatibility with Max 2024 through 2027. **VERIFIED IN CURRENT CODE:** build configurations currently cover 2026/2027. **VERIFIED BY TEST — retained:** narrow runtime evidence is for Max 2027.1.

The cloud-reasoning prototype adds no mandatory local ML GPU requirement. Max and the chosen renderer still have their own hardware requirements. No “works on every GPU” claim is supported.

Local inference must be qualified for a particular model, resolution, precision, runtime and workload. System RAM is not GPU VRAM. Do not set a blanket 8/12/16 GB VRAM minimum from a model family name. Measure peak resident memory, allocation failures, latency and interference with Max/rendering on a real 32 GB machine.

A local-only fallback should provide presets, recipes and manual Cyrus even when no model fits.

## Deployment modes

~~~mermaid
flowchart TD
  U["Artist workstation: Max + local API + orchestrator"] --> C{"Studio-approved mode"}
  C -->|Cloud reasoning| A["Approved summaries and optional images"]
  A --> CLOUD["Reasoning provider"]
  CLOUD --> V["Local plan validation and execution"]
  C -->|Hybrid| H["Local retrieval / optional vision preprocessing"]
  H --> SMALL["Approved compact context"]
  SMALL --> CLOUD
  C -->|Offline| L["Local recipes and rules"]
  L --> LOCAL["Optional qualified local models"]
  LOCAL --> V
  L --> V
  V --> U
~~~

| Mode | Advantage | Cost / risk | Recommendation |
| --- | --- | --- | --- |
| Cloud reasoning | Fastest path to evaluating strong general reasoning | Network, provider cost, upload policy and outages | Optional initial research mode with approved data |
| Hybrid | Keeps geometry and selected vision work local; can reduce repeated context | More runtime/model support; summaries still sensitive | Add only where a measured bottleneck justifies it |
| Local/offline | No external project upload; studio control | Hardware, model quality, packaging and maintenance | Rules/retrieval baseline first, inference feasibility experiment later |

The diagram does not select a cloud vendor. A local model may support segmentation/ranking without replacing the general planner.

## Cost model and options

Do not publish a price-per-layout estimate before measuring actual payloads and acceptance. Use:

`cost per accepted layout = (reasoning + vision/embedding inference + storage/transfer + attributable operations/support cost) / accepted layouts`.

Track rejected attempts and retries in the numerator. Separate provider charges from artist waiting/correction time and local hardware amortization. Recheck prices for the exact model/endpoint at the campaign date.

Option A has the smallest model infrastructure but still substantial Max API work. B adds a maintainable library/index. C adds image runtimes and checkpoint licensing. D adds labelled datasets, training and constrained selection. E combines all of these with research uncertainty. See the [A–E matrix](03_GPT_Astra_vs_Specialized_ML.md).

## Future ML infrastructure

**FUTURE / OPTIONAL:** only after the readiness checklist passes.

| Area | Minimum useful artifact | Technology decision |
| --- | --- | --- |
| Collection | Versioned local records, rights/consent and artifact digests | JSON plus local files initially; database only when needed |
| Labeling | Reviewed masks/pairs/reasons with ambiguity/version | Choose tooling after task and annotation volume |
| Dataset | Immutable manifest and project/studio split | Local/studio storage policy before cloud infrastructure |
| Preprocessing | Versioned unit/camera/resize/features; deterministic cache keys | Reusable offline pipeline, no mutation of source data |
| Augmentation | Training-only transforms preserving geometry/labels | Never randomize scale/rotation without updating camera/coordinates |
| Experiments | Config, dataset hash, code/runtime, seed, metrics and failures | Simple files first; tracking service optional |
| Training | Isolated reproducible environment, resource/cost cap | Evaluate appropriate libraries; no final framework selected |
| Checkpoints | Provenance/license digest, hashes, feature/schema compatibility | Safe distribution and explicit update approval |
| Evaluation | Fixed held-out projects, baselines, uncertainty and artist study | Same acceptance rubric as the product |
| Inference | Separate helper, bounded queue, cancellation and fallback | CPU/GPU runtime benchmarked on supported hardware |
| Deployment | Signed/hashed optional package, dependency isolation | Do not install ML dependencies into Max's Python globally |
| Rollback | Previous model/runtime/config retained and selectable | Bad update must not make scenes unreadable |
| Monitoring | Opt-in local diagnostics and drift review | No hidden training telemetry or automatic online learning |

Quantization, ONNX-style interchange or accelerated backends may be worth testing, but export support and numeric/quality parity depend on the chosen model. GPU inference support does not imply OpenCL is the best backend for Cyrus scatter computation.

## Scheduling and cancellation

One scene mutation at a time. The UI remains responsive during model/network work. Inference/encoding use copied data outside Max; host evaluation stays in its supported context. Pause AI work during render/resource contention unless measured coexistence is acceptable.

Distinguish operation admission timeout, provider timeout, cancel requested and actual cancellation. Existing synchronous computation cannot honestly promise instant cancellation without additional engineering.

## Performance exit gate

Proceed only when stage-level traces show where time/memory goes, the proposed budgets fit the pilot machine, the model does not induce repeated expensive regeneration, and total artist time beats the manual/preset baseline. No GPU purchase or training-service subscription is justified by this document alone.

