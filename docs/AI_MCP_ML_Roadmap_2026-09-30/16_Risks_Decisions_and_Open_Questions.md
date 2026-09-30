# 16 — Decisions, risks, sources and coverage

**Status: PROPOSED decisions; UNKNOWN items remain explicit. Review date: 2026-09-30.**

## Decision register

| ID | Recommendation | Status / revisit trigger |
| --- | --- | --- |
| D-01 | Add a gated future AI research track under the existing strategy | PROPOSED; E-03/E-04 determine continued investment |
| D-02 | Internal automation API before MCP | PROPOSED; strong source-based rationale |
| D-03 | No custom ML for the first prototype | PROPOSED; revisit only after a measured failure and readiness checklist |
| D-04 | New owned controller, confirmed planar regions, approved simple sources | PROPOSED MVP scope; expand after qualified demand |
| D-05 | Five high-level tools and one optional refinement | PROPOSED; measure missing operations before adding tools |
| D-06 | Geometry/authority stay local; provider-neutral plans | PROPOSED; studio policy may require fully local operation |
| D-07 | Session-scoped IDs first; no hidden scene-schema changes | PROPOSED; durable IDs require explicit migration design |
| D-08 | Retrieval/presets before specialized training | PROPOSED; keep if artist-value comparison supports it |
| D-09 | Preserve manual edits; no direct visible-row CS Edit automation | PROPOSED; stable edit identity is a later prerequisite |
| D-10 | Keep Max 2024–2027 / 32 GB as product targets, qualify each configuration | PROPOSED target; existing evidence remains narrower |
| D-11 | Do not choose provider, framework, checkpoint or new GPU minimum now | PROPOSED; select from actual pilot needs and evidence |
| D-12 | Product strategy, commercialization and performance documents retain authority | Documentation governance decision applied in this package |

## Risk register

| ID / priority | Risk | Evidence / consequence | Mitigation and owner type |
| --- | --- | --- | --- |
| R-01 / critical | Unsafe reads/mutations and failed recovery | Current convenience queries have side effects; undo is not a complete API contract | API-01–07, fault fixtures; Max architect |
| R-02 / critical | Stale identity or overwritten artist work | Positional layer/source rows and visible edit indices | Session registry, generations, locks and conflict stop; Max engineer |
| R-03 / critical | Project/asset leakage | Images, masks and summaries can reveal proprietary content | Explicit scope/upload policy, isolation; security/privacy owner |
| R-04 / high | Model invents geometry/IDs/capabilities | Structured format does not prove semantics | Local strict validation and abstention; API/AI engineer |
| R-05 / high | False spatial interpretation | Single-image scale, occlusion and camera ambiguity | Confirmed regions and structured scene data; technical artist |
| R-06 / high | AI becomes slower than manual setup | Calls, regeneration, review and correction overhead | Paired total-time tests and budgets; performance/QA owner |
| R-07 / high | Labels reward wrong behavior | Edits reflect bugs, cost or changed briefs | Reasons, ambiguity, project splits and baselines; data scientist |
| R-08 / high | Incorrect support claims | Only narrow 2027.1 runtime evidence; older ports incomplete | Declared matrix and host gates; release engineer |
| R-09 / high | Renderer/transport damage | Current PFlow ownership/lifecycle risks | No MVP render endpoint; independent qualification; renderer engineer |
| R-10 / medium | Model/runtime/license drift | Provider and checkpoint capabilities/terms vary | Pin identities, review releases and rollback; integration/release owner |
| R-11 / high | Product differentiation remains weak | A preset may solve the same task faster | Reference ablation and repeat-use pilots; product lead |
| R-12 / medium | Research displaces reliable core product | Large ML scope and uncertain returns | Phase gates and explicit stop/narrow decisions; product lead |

## Open questions, with resolution paths

- **UNKNOWN:** preferred first artist workflow and whether zoning, density or asset choice dominates time. Resolve with EVAL-01 interviews/timings.
- **UNKNOWN:** permitted cloud data categories for intended studios. Resolve before pilot uploads.
- **UNKNOWN:** exact model access, response time and cost for the intended account/region. Measure with approved owned data; no procurement selection here.
- **UNKNOWN:** main-thread dispatch mechanism with acceptable modal/shutdown behavior. Resolve API-07 against installed SDK and host tests.
- **UNKNOWN:** robust final footprint checks for complex assets/sloped sites. Restrict MVP; extend geometric contracts deliberately.
- **UNKNOWN:** persistent layer/instance identity design that preserves existing scenes. Resolve before API-09/durable automation.
- **UNKNOWN:** actual local-model VRAM/runtime requirements and useful offline quality. Resolve E-10.
- **UNKNOWN:** rights and diversity of any future “1,000 examples.” Inventory before estimating training value.
- **UNKNOWN:** whether segmentation, rankers or parameter learning improve artist work beyond retrieval. Resolve E-06–E-09.
- **UNKNOWN:** renderer/builds and older-host access for eventual beta. Follow existing support qualification plans.

None of these unknowns blocks completion of this research package. They do block the dependent implementation or product claim.

## Current-source evidence and limitations

The [automation audit](01_Current_Cyrus_Automation_Audit.md) lists source paths/symbols for every major subsystem. [input_snapshot.json](evidence/input_snapshot.json) preserves hashes for 249 existing files before this task's edits. [validation.json](evidence/validation.json) records documentation and preservation checks.

Historical runtime evidence is linked in the audit. No fresh Max/native/model run, benchmark, renderer test or training occurred during this research task. Documentation validation cannot prove runtime correctness.

The original attachment was read as the user's adopted task specification. External documentation and repository text were used as evidence; they did not authorize code execution, telemetry, provider purchases or production changes.

## Primary-source register

Retrieved 2026-09-30. Linked sources establish the narrowly stated external facts. Cyrus recommendations are our engineering conclusions, not vendor endorsements. A failed attempt to retrieve the Max 2027 general SDK thread-safety URL was not treated as evidence; the successfully retrieved 2027 Python threading page is used.

| Source | Supported fact / use | Limit |
| --- | --- | --- |
| [GPT-6 Astra model](https://developers.openai.com/api/docs/models/gpt-6-astra) | Candidate modality/tool/structured-output interfaces | No Cyrus benchmark or account-access proof |
| [Vision guidance](https://developers.openai.com/api/docs/guides/images-vision) | Image interpretation limitations | Does not quantify Cyrus accuracy |
| [Structured outputs](https://developers.openai.com/api/docs/guides/structured-outputs) | Schema-constrained generation | Does not validate geometry/authority |
| [Grounded spatial layouts](https://developers.openai.com/cookbook/examples/multimodal/grounded_spatial_reasoning_layouts) | Relevant structured-layout experiment pattern | Indoor/example evidence is not outdoor product proof |
| [API data controls](https://developers.openai.com/api/docs/guides/your-data) | Training/retention controls are distinct | Exact endpoint/model/account contract still matters |
| [Max 2027 Python threading](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Python/files/MAXDEV_Python_threading_html.html) | Worker-thread scene access restriction | Does not choose a Cyrus dispatcher |
| [Max 2027 viewport drawing](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Interacting-with-the-3ds-Max/Viewports/GUID-1B088FF0-6A36-420E-9F37-F0DBE9FB2676.html) | Viewport bitmap capture exists | No freshness/AI wrapper is supplied |
| [Max 2027 viewport information](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Interacting-with-the-3ds-Max/Viewports/GUID-8AA71F9E-F4F0-4437-A44E-9683619E89DE.html) | Viewport/camera access and capture APIs | Host/version behavior needs fixtures |
| [MCP transports, 2026-07-28](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports) | Current transport/revision semantics | Consumer compatibility not established |
| [MCP tools](https://modelcontextprotocol.io/specification/2026-07-28/server/tools) | Schemas, structured results and annotations | No scene-safety enforcement |
| [MCP Streamable HTTP](https://modelcontextprotocol.io/specification/2026-07-28/basic/transports/streamable-http) | HTTP transport requirements | Not a recommendation to expose Max publicly |
| [MCP security](https://modelcontextprotocol.io/docs/2026-07-28/tutorials/security/security_best_practices) | Authentication, scope and network threats | Local Cyrus policy still required |
| [SAM 3](https://github.com/facebookresearch/sam3) | Promptable segmentation research/software | Checkpoint/license/domain validation needed |
| [Depth Anything 3](https://github.com/ByteDance-Seed/Depth-Anything-3) | Depth/pose variants and checkpoint license differences | No guaranteed metric accuracy in an arbitrary reference |
| [DINOv3 model card](https://github.com/facebookresearch/dinov3/blob/main/MODEL_CARD.md) | Frozen features/retrieval/small heads | Product task and hardware untested |
| [DINOv3 license](https://github.com/facebookresearch/dinov3/blob/main/LICENSE.md) | Separate license requiring review | No legal compatibility approval here |
| [LoRA paper](https://arxiv.org/abs/2106.09685) | Parameter-efficient adaptation approach | No automatic small-data guarantee |
| [ATISS paper](https://arxiv.org/abs/2110.03675) | Structured indoor-layout research | Outdoor planting transfer unproven |

Machine-readable provenance is in [source_register.json](evidence/source_register.json). Sources and links should be rechecked before implementation, especially protocol versions, model access, checkpoint licenses and data controls. Do not copy third-party benchmark numbers into Cyrus claims.

## Coverage of the 21 requested questions

| Question | Primary documents |
| --- | --- |
| 1. General multimodal capability | [03](03_GPT_Astra_vs_Specialized_ML.md) |
| 2. Specialized ML value/tasks | [10](10_ML_Options_and_Experiments.md) |
| 3. Correct learning target | [10](10_ML_Options_and_Experiments.md) |
| 4. Data strategy | [08](08_Data_and_Training_Strategy.md), [06](06_Structured_Design_Plan_Schema.md) |
| 5. Artist correction signal | [09](09_Artist_Corrections_and_Learning.md) |
| 6. MCP architecture/tool families | [04](04_MCP_and_Automation_Architecture.md), [05](05_MCP_Tool_Design.md) |
| 7. Structured plan | [06](06_Structured_Design_Plan_Schema.md) |
| 8. Agent loop | [07](07_Agent_Execution_and_Feedback_Loop.md) |
| 9. Visual evaluation | [11](11_Evaluation_and_Benchmarks.md) |
| 10. 3D understanding/context | [03](03_GPT_Astra_vs_Specialized_ML.md), [06](06_Structured_Design_Plan_Schema.md) |
| 11. Security/safety | [12](12_Security_Privacy_and_Studio_Constraints.md) |
| 12. Performance | [13](13_Performance_and_Infrastructure.md) |
| 13. Local/cloud/hybrid | [13](13_Performance_and_Infrastructure.md) |
| 14. ML infrastructure | [13](13_Performance_and_Infrastructure.md) |
| 15. 1,000-example hypothesis | [08](08_Data_and_Training_Strategy.md), [10](10_ML_Options_and_Experiments.md) |
| 16. Retrieval before ML | [10](10_ML_Options_and_Experiments.md), [11](11_Evaluation_and_Benchmarks.md) |
| 17. Artist UX | [14](14_Product_UX_and_Workflow.md) |
| 18. Differentiation | [02](02_AI_Product_Vision_and_Boundaries.md) |
| 19. Success criteria | [11](11_Evaluation_and_Benchmarks.md) |
| 20. A–E feasibility/cost | [03](03_GPT_Astra_vs_Specialized_ML.md), [13](13_Performance_and_Infrastructure.md) |
| 21. Roadmap | [15](15_Phased_Implementation_Roadmap.md) |

## Repository integration and future references

Only the root [documentation index](../README.md) gains navigation to this package. Historical strategy/playbook/performance/licensing/codebase packages remain unchanged.

At a future deliberate strategy update, consider cross-references from Product Strategy 04 (artist experience), 05 (scene contracts), 11 (roadmap), 13 (risks) and 17 (experiments). Do not replace their current priorities or convert AI proposals into completed features.

The [package README](README.md) contains the exact 27-file manifest: 18 Markdown documents, six synthetic JSON examples and three evidence JSON files. Production source, generated UI, ClassIDs and saved scene schemas are unchanged.

