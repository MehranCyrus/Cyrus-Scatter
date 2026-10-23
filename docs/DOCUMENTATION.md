# Documentation maintenance

## Authority

[The index](README.md) links the maintained artist guide, architecture, feature details, backlog, build and versioning instructions. Update these in place. The [execution ledger](plans/improvement-program/PROGRESS.md) is the single current roadmap; the backlog owns defects and acceptance rather than a second feature queue. Source and reproducible tests resolve conflicts; a historical report's use of “current” applies only to its recorded snapshot.

The capability matrix and MCP agent workflow remain at their existing `Current_System_2026-10-05` paths because code/catalog generation and external references use them. Their directory date does not make their maintained content obsolete. The semantic inventory, catalog hashes and current control register are functional inputs, not disposable prose.

The 23 October 2026 maintenance reconciles current guidance with [Scatter 0.86.9](plans/edit-instances/DELIVERY_0869.md): source-aware Edit history, identification colours, final displayed feedback, native Edit storage/capability 2 and one EXE containing matched Max 2024/2026/2027 payloads with Surface Analyzer 0.14.2. Schema 59, recipe 8, original Paint and content revision 0.86.7 are preserved. The [qualification manifest](plans/edit-instances/QUALIFICATION_0869.json) retains the exact producer/package/host evidence. The remaining full-object Copy limitation is tracked as [B37](BACKLOG.md#edit-instance-findings--0869); it is not a completed fix. Earlier performance, rendering and host evidence retain their original limits. Knowledge selection, actual freshness and direct-source routing are recorded in the [knowledge entrypoint](../tools/rag/README.md). This documentation pass does not rebuild plugin packages, activate a knowledge index, build a website or publish one.

This pass checked 20 maintained/campaign Markdown files: 662 local links and
16 current anchor links resolve. Generated integration checks pass for 333
controls and 32 bounded delimiter fixtures; the three focused installer-doc and
catalog tests pass. The native producer source hashes and all seven qualified
EXE/MZP hashes still match the 0.86.9 evidence. Catalog changes are help metadata
only. Local receipts are under `build/docs-0869-20261023-01/`; no new Max runtime
qualification is implied by these documentation checks.

## What to keep

- Current usage, engineering contracts, build/testing instructions and one active work list.
- Exact dated qualification, failures, benchmarks, reproduction fixtures and package/source identities. Retain their paths when tools, manifests or other documents depend on them.
- Unique design rationale and unresolved findings. Carry still-open acceptance into the backlog before retiring a task plan.
- Separate component contracts such as licensing and MCP; do not flatten distinct ownership into one document.

## Foundation and knowledge upkeep

The [engineering foundation](ENGINEERING_FOUNDATION.md) owns durable behavior and architecture direction; [architecture](ARCHITECTURE.md) describes implemented source, task plans describe proposals, and dated receipts preserve what actually ran. Agent skills route to these documents instead of copying version policies or roadmap commands. Current user scope overrides a historical objective.

A documentation inventory or topic scan is not a semantic review of every file. Report the inspected scope, keep historical qualification labels intact, and update current entrypoints when later experiments or fixes supersede their summaries. Reusable lessons need cause, scope, evidence, uncertainty and an invalidation condition.

Knowledge indexing has separate enrollment, freshness, retrieval and activation gates. Removed source paths require explicit scope/evaluation review; do not restore retired fixtures, overwrite sealed hashes or switch registration just to make status green. Fresh source hashes do not establish implementation correctness. [Knowledge maintenance](../tools/rag/README.md) records the current selection and actual consumer verification; dated audits retain their original scope. Index current navigation and the execution ledger deliberately, keep required historical evidence labeled, and verify complete contracts as well as ranking. An archive location alone is not evidence that a contract is obsolete.

## What to remove or consolidate

Remove duplicate explanations, obsolete installation instructions and copy-paste task prompts after moving still-useful guidance into the maintained documents. Git preserves their original text. A short compatibility link is justified only for an externally used old document path; do not keep two full versions of the same current guide.

A new dated folder is appropriate for new measured evidence or a delivery receipt. It is not needed for every conversation, formatting change or restatement of the backlog. Mark historical entry points and keep them out of the current reading sequence.

Before adding a document, identify its owner: artist behavior in the artist guide, implemented structure in architecture, required behavior in the foundation, status in the execution ledger, defects in the backlog, and maintenance procedure here. Add a contract only for a distinct reusable boundary. Record exact delivery evidence once, with links from maintained guidance. Do not append a second copy of its narrative to the roadmap. Use Git history for superseded prose; preserve useful failure/test receipts. Short routing pages are justified by real external/tool references, not by a desire to keep every old path alive.

[The archive](archive/README.md) distinguishes physically moved plans from historical evidence kept at original byte-pinned paths. Preserve research packages and their manifests together. Rewriting links in an archived plan changes that file's bytes; record the original path/hash and recovery commit rather than presenting it as an unchanged sealed artifact.

## Website and public roadmap

Use `website/` as the single maintained frontend. The user-selected presentation sources are `Landing Page Design/cyrus-scatter-site/` for the landing page and `Landing Page Design/Design 1/` for the documentation. Preserve these supplied packages as design references, not additional current guides. Website content comes from an explicit manifest of maintained documents and the current generated feature catalog. Historical 0.73 reference snapshots, artwork and validation receipts retain their provenance but must not republish retired paint-set ownership into the current site.

[Product and AI direction](PRODUCT_AND_AI_ROADMAP.md) is the maintained public summary for current manual plugin features, the narrower MCP foundation, the offline learning experiment and planned assistant/ML work. Keep future capabilities visibly planned. Specialist research remains useful rationale, but its old versions and proposed APIs do not establish current availability. Recording, sharing and training permission remain separate.

The 11 October 2026 website reconciliation checked all 34 catalog families, the 240 semantic control records and relevant current handlers against the artist guides. It corrected retired set ownership, Point/Empty policies, vector projection limits, explicit Refresh versus cached reads, Analyzer integration wording and output cleanup availability. The capability help catalog was regenerated from its maintained matrix; tool dispatch, schemas, native code and UI controls were unchanged. Website editorial explanations supplement incomplete or stale tooltips without silently changing the plugin. Source review and documentation checks do not replace physical artist acceptance or certify every option combination.

### Public copy rules

Lead with what artists can build today. Present MCP as a separate bounded foundation and broader assistance as roadmap work. Present ML as experimental foundations plus planned product capabilities. Use explicit **Current**, **Experimental** and **Planned** labels where a visitor might otherwise infer availability.

Do not invent pricing, purchase availability, public download endpoints, customer testimonials, release dates, benchmark comparisons or assistant-client certification. Prefer links to the guide, features and roadmap until a real distribution destination exists. Keep generated concept images and teaching diagrams labeled separately from actual plugin captures.

## Consolidation on 18 October 2026

The current inventory covers 667 tracked Markdown documents under docs and the knowledge tools. This count is an inventory, not semantic verification of every research claim. Current navigation, the P/I/PG/N ledgers and overlapping plan/checklist status were reviewed against the 0.86.0 delivery. Six superseded planning/checkpoint narratives were moved to the archive with original hashes and relocated relative links. The two duplicate TODO pages now route to one execution ledger; detailed future phase/gallery contracts and performance/Max 2027 gates remain accessible. Root/index pages were shortened and stale planning-only, Phase 6 pause and 0.85.4-current claims were removed from current navigation.

Exact native/script/package identities, useful test/failure evidence, website-imported byte-pinned reports and original research-package artifacts are preserved. Independently active Physics Lab and presentation navigation was preserved. Product source, installed Max profiles and binaries were outside this task. No new runtime/build pass is implied. The [decision register](documentation-inventory.csv) records maintained, consolidated, archived-in-place and excluded paths; a source-only clone does not include ignored runtime artifacts.

Knowledge refresh must separately verify reviewed source hashes/ranges, historical labels, original evaluation requirements, complete contract retrieval and actual project-following activation. Its exact generation, checks and remaining search limits are maintained in [the knowledge tooling entrypoint](../tools/rag/README.md), rather than another competing documentation report.

## Historical cleanup on 9 October 2026

The review inventoried tracked Markdown and text paths, distinguished logs/test data from guides, checked duplicated material and incoming tool/document references, read the active guides and the superseded standalone guides/task prompts, and reconciled uncertain current claims with source. Historical implementation packages were assessed for version, provenance, dependencies and retained findings; their raw results were not rerun or recertified.

The website, research collections, licensing work, binary artifacts, artist scenes and installed profiles were excluded. Research was not re-evaluated. Byte-pinned evidence and website-imported source chapters remain untouched.

Fifteen obsolete standalone guides/task prompts were removed. Current installation, module, versioning and MCP guidance were corrected. The artist guide has one maintained location. Existing links to removed historical instructions point to their exact pre-cleanup Git version. Three externally used guide/audit paths remain short routing pages rather than competing manuals.

[The per-file decision register](documentation-inventory.csv) records retained, consolidated, removed and excluded paths and why. [History](HISTORY.md) is the route to dated implementation evidence. The removal baseline is commit `f5bc9737378d097cd469d20b32d5576cf10dab01`; recovery does not require retaining another local copy.

Validation on 9 October 2026: all 472 local links in changed/new guides resolved, no remaining local Markdown links target the removed guides, generated UI verification passed, all 141 MCP/tool Python tests passed, and `git diff --check` passed. Scope checks confirmed no changes to protected research, website, imported chapters, evidence or product source. Scratch validation details are local under `build/docs_cleanup/`. No new Max session or runtime qualification was needed for this documentation-only change.
