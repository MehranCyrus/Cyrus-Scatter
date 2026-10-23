# Website refresh: individual library and downloads

Planning review: 20 October 2026. This records the user's requested direction; frontend implementation, asset publication and hosting have not happened in this pass. Concurrent plugin testing and 0.86.7 work remain separate.

## Implementation follow-up — 20 October 2026

The user subsequently authorized implementation and supplied the completed 0.86.7 handoff. The local website now includes the twelve-specimen library, filters/image viewer, library-to-recipe workflow explanation, actual Max 2027 textured-leaf example, landing additions and Download page. Public guide/changelog/roadmap content is reconciled to that handoff. The original planning observations below retain their historical context.

The current release record uses the actual 0.86.7 sizes: EXE **5,480,448 bytes**, Content **5,851,207,027 bytes**. Max 2024/2026/2027 support and the Max-2027-only real Corona qualification are explicit. Public download URLs remain unset with coming-soon actions. Content subsets, installer changes for optional packs, hosting and publication remain undecided.

Production build, deterministic source verification, 22 focused browser checks and independent desktop/tablet/mobile design evaluation passed. Browser review used a serverless production-derived file preview after the earlier background-server action was rejected. This does not qualify HTTP hosting or re-test the plugin. See [the implementation receipt](verification/LIBRARY_DOWNLOAD_REFRESH_20261020.md).

## Evidence and current gaps

- Source reviewed on branch `codex/workflow-0.75`, HEAD `3ec1cbc2b725912e39c2625ceecb648970054050`, with existing tracked and untracked work preserved. This is a working-tree assessment, not a clean-release receipt.
- The existing React/Vite site has an established cream/forest-green visual identity, editorial typography, interactive lessons, guides and concept imagery. Keep that foundation.
- The site has mixed-age content: `src/content/reference.json` identifies Scatter 0.86.6, while README still describes 0.82.6. `python website/tools/import_reference.py --check` reports stale generated reference content. No import was rewritten during this review.
- `src/content/featureStories.ts` still excludes spheres and vertical receivers from vector painting, conflicting with the qualified 0.86.6 delivery. Its Point assignment caveat also needs comparison with maintained source before retention or removal.
- `content/guide-chapters.json` still describes Bundled examples, old default procedural examples and old development labels. The installation text combines EXE and MZP under Run Script; give each its correct installation procedure.
- The route `#/gallery` is the feature poster collection. There is no dedicated plant-library or download route. Add distinct destinations without breaking existing poster links.
- Some roadmap descriptions treat recipe/library work as wholly future work. Separate delivered capabilities from remaining expansion.
- Historical saved desktop screenshots and twelve current model JPEGs were visually inspected. The saved website screenshots predate the current hero. A local preview-server launch was blocked by automatic approval review without a detailed reason; no current rendered-site or live-host acceptance is claimed.

## Design direction

Make the landing page demonstrate the product with actual library renders and current plugin UI alongside its existing illustrative material. Preserve concept-image labels and educational SVG captions. Actual asset renders demonstrate models; they do not demonstrate a finished scattered environment.

Suggested navigation: Workflow, Features, Plant library, Guide, Download. Retain existing deep links and the docs sidebar. Add a restrained download call to action in the header and a fuller section near the landing-page close.

### Curated plant library

Use approximately twelve individuals for the initial website collection, with simple category filters, readable names, consistent cards and a larger-image viewer. Show a small selection on the landing page and the full curated selection at `#/library`. Avoid an exhaustive 96-card public inventory or new elaborate category hierarchies.

These twelve existing 640-square Corona previews were inspected during this review. IDs refer to the local individual-model catalog and remain internal provenance, not required public labels.

| Category | Candidate names | IDs | Review note |
| --- | --- | --- | --- |
| Trees | Broadleaf Tree 02; Cypress Tree; Norway Maple - Red Foliage | A073, A075, A098 | Distinct canopy forms and foliage colors |
| Shrubs | Lavender - 01; Rugosa Rose - 02 | A083, A086 | Flowering variety; lavender is pale and needs final presentation review |
| Grasses | Grass - Bushy Clump | A068 | Clearly readable individual clump |
| Groundcover | Clover - Patch 04; Arthropodium - 01 | A070, A088 | Contrasting leaf forms; clover is pale against grey |
| Flowers | Common Blue Violet - 04; Creeping Phlox - 02 | A062, A065 | Small flowering individuals |
| Leaves | Sycamore Leaf 15 - Faded Gold; Leaf 07 - Curled Leaf - Dry Brown | A023, A007 | Autumn color and curled dry form |

Final curation may replace pale candidates with stronger existing renders. Prefer a few polished images over regenerating the entire catalog. Do not recolor models purely to make marketing images look stronger.

Source: `build/individual-model-library-20261020/Content/Library/model-catalog.json` and its relative thumbnails. It contains 96 unique individual entries derived from 104 original catalog cards; collection and duplicate cards do not increase the individual count. All 96 JPEG previews together are approximately 3.4 MB, so a curated preview showcase is lightweight even though model distribution is large.

Export only selected public image assets and a small website manifest. Do not expose absolute workstation paths, MAX scenes, shared maps or internal audit records through the website bundle. Confirm intended public use of selected supplied assets before publication; this review makes no blanket model-redistribution claim.

### Explain the library and recipe system

Give each concept a clear role:

1. **Plant models:** individual trees, shrubs, flowers, grasses and leaves.
2. **Recipes:** reusable artist-authored scatter settings and supported source/asset bindings.
3. **Designed scenes:** authored compositions demonstrating several choices working together.

Show the real workflow: browse a plant, merge it or add it to a selected layer, combine sources/layers, save a personal recipe, and reuse it. Use a compact sequence of current UI captures. Do not restore the retired eight procedural defaults or present repeated single-species tiles as finished mixed landscape designs. Additional designed scenes remain artist-curated work.

### Download layout, with delivery decision deferred

Create a `#/download` page and matching compact landing section. Proposed layout:

| Area | UI content | Readiness rule |
| --- | --- | --- |
| Main release card | Release version/channel, Windows installer action, verified supported Max versions, actual package size, release notes | Populate from one release record tied to an actual artifact |
| Installation guidance | Separate EXE and MZP instructions, restart guidance and dependencies | Match the selected delivery exactly |
| Plant content card | What the model library contains and its relationship to installation | Explain the current requirement; final download choice remains undecided |
| Future collection area | Space for a curated starter pack and additional collections | Planned/unavailable until matching packages and installer support exist |

The reviewed 0.86.6.2 EXE is approximately 1.84 MB, but requires its matching Content folder. The full Content delivery is approximately 5.85 GB (5,850,789,633 bytes). Removing models from that folder would invalidate the current pinned manifest. A small EXE alone is therefore not currently a complete installation download.

The website can implement the presentation now without choosing hosting or bundling all content. Keep release URLs configurable and make unavailable actions explicitly unavailable. Do not ship fake buttons or claim plugin-only installation, optional packs or automatic content downloads already work. A curated starter distribution would require a separately scoped installer/content-manifest change and matching package.

Keep large release assets outside the frontend bundle and cPanel website ZIP. Decide the actual release host, archive format, content subsets and update mechanism later. The work in progress on 0.86.7 and compatibility testing must not automatically become a public latest-release claim; consume the completed release handoff when ready.

## Proposed implementation order

1. Reconcile current public guide, feature stories, install text and roadmap with maintained product evidence. Preserve independent Analyzer/MCP versions and historical receipts.
2. Add the curated public image manifest, library page, landing showcase and library-to-recipe workflow.
3. Add the download page/layout and one release metadata record with explicit availability and content requirements. Content delivery remains a separate decision.
4. Update public changelog and source metadata once reviewed source is stable; regenerate reference content rather than editing only generated JSON.
5. Run focused source/build checks and a desktop/mobile visual review of the changed pages, image loading, links and download states. No plugin or bulk model retesting is needed for this website work.

## Remaining decisions

- Final twelve showcase candidates and any limited preview replacements.
- Release artifact/version and host support after concurrent testing completes.
- Whether the first downloadable content edition is the complete library or a newly built curated subset, and where release assets will be hosted.
- A real mixed planting showcase can be added when an artist-authored composition is available; it is not a dependency for showing individual assets and the recipe workflow.

No plugin changes, installer rebuild, content repackaging, Git push or deployment is included in this planning pass.
