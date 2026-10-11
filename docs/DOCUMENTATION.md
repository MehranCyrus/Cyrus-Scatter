# Documentation maintenance

## Authority

[The index](README.md) links the maintained artist guide, architecture, feature details, backlog, build and versioning instructions. Update these in place. Source and reproducible tests resolve conflicts; a historical report's use of “current” applies only to its recorded snapshot.

The capability matrix and MCP agent workflow remain at their existing `Current_System_2026-10-05` paths because code/catalog generation and external references use them. Their directory date does not make their maintained content obsolete. The semantic inventory, catalog hashes and current control register are functional inputs, not disposable prose.

## What to keep

- Current usage, engineering contracts, build/testing instructions and one active work list.
- Exact dated qualification, failures, benchmarks, reproduction fixtures and package/source identities. Retain their paths when tools, manifests or other documents depend on them.
- Unique design rationale and unresolved findings. Carry still-open acceptance into the backlog before retiring a task plan.
- Separate component contracts such as licensing and MCP; do not flatten distinct ownership into one document.

## What to remove or consolidate

Remove duplicate explanations, obsolete installation instructions and copy-paste task prompts after moving still-useful guidance into the maintained documents. Git preserves their original text. A short compatibility link is justified only for an externally used old document path; do not keep two full versions of the same current guide.

A new dated folder is appropriate for new measured evidence or a delivery receipt. It is not needed for every conversation, formatting change or restatement of the backlog. Mark historical entry points and keep them out of the current reading sequence.

## Website and public roadmap

Use `website/` as the single maintained frontend. The user-selected presentation sources are `Landing Page Design/cyrus-scatter-site/` for the landing page and `Landing Page Design/Design 1/` for the documentation. Preserve these supplied packages as design references, not additional current guides. Website content comes from an explicit manifest of maintained documents and the current generated feature catalog. Historical 0.73 reference snapshots, artwork and validation receipts retain their provenance but must not republish retired paint-set ownership into the current site.

[Product and AI direction](PRODUCT_AND_AI_ROADMAP.md) is the maintained public summary for current manual plugin features, the narrower MCP foundation, the offline learning experiment and planned assistant/ML work. Keep future capabilities visibly planned. Specialist research remains useful rationale, but its old versions and proposed APIs do not establish current availability. Recording, sharing and training permission remain separate.

The 11 October 2026 website reconciliation checked all 34 catalog families, the 240 semantic control records and relevant current handlers against the artist guides. It corrected retired set ownership, Point/Empty policies, vector projection limits, explicit Refresh versus cached reads, Analyzer integration wording and output cleanup availability. The capability help catalog was regenerated from its maintained matrix; tool dispatch, schemas, native code and UI controls were unchanged. Website editorial explanations supplement incomplete or stale tooltips without silently changing the plugin. Source review and documentation checks do not replace physical artist acceptance or certify every option combination.

### Public copy rules

Lead with what artists can build today. Present MCP as a separate bounded foundation and broader assistance as roadmap work. Present ML as experimental foundations plus planned product capabilities. Use explicit **Current**, **Experimental** and **Planned** labels where a visitor might otherwise infer availability.

Do not invent pricing, purchase availability, public download endpoints, customer testimonials, release dates, benchmark comparisons or assistant-client certification. Prefer links to the guide, features and roadmap until a real distribution destination exists. Keep generated concept images and teaching diagrams labeled separately from actual plugin captures.

## This cleanup

The review inventoried tracked Markdown and text paths, distinguished logs/test data from guides, checked duplicated material and incoming tool/document references, read the active guides and the superseded standalone guides/task prompts, and reconciled uncertain current claims with source. Historical implementation packages were assessed for version, provenance, dependencies and retained findings; their raw results were not rerun or recertified.

The website, research collections, licensing work, binary artifacts, artist scenes and installed profiles were excluded. Research was not re-evaluated. Byte-pinned evidence and website-imported source chapters remain untouched.

Fifteen obsolete standalone guides/task prompts were removed. Current installation, module, versioning and MCP guidance were corrected. The artist guide has one maintained location. Existing links to removed historical instructions point to their exact pre-cleanup Git version. Three externally used guide/audit paths remain short routing pages rather than competing manuals.

[The per-file decision register](documentation-inventory.csv) records retained, consolidated, removed and excluded paths and why. [History](HISTORY.md) is the route to dated implementation evidence. The removal baseline is commit `f5bc9737378d097cd469d20b32d5576cf10dab01`; recovery does not require retaining another local copy.

Validation on 9 October 2026: all 472 local links in changed/new guides resolved, no remaining local Markdown links target the removed guides, generated UI verification passed, all 141 MCP/tool Python tests passed, and `git diff --check` passed. Scope checks confirmed no changes to protected research, website, imported chapters, evidence or product source. Scratch validation details are local under `build/docs_cleanup/`. No new Max session or runtime qualification was needed for this documentation-only change.
