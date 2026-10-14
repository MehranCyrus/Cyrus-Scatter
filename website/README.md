# Cyrus Scatter — selected landing and visual guide

The one maintained public frontend for the artist plugin, its documentation and the separate future direction for MCP/learning. Curated guide content records **Scatter 0.82.0 development**, **Surface Analyzer 0.14** and **MCP package 0.73.0 / plan 0.73**. Named settings and curve presets join the completed Phase 1 feedback checkpoint; final physical artist acceptance remains pending. These identify the imported reference edition; the [root README](../README.md) owns the latest product build and host qualification. Local content includes the Band/falloff workflow, Auto Radius, first-click/hover fixes, panel-help cleanup and the subsequent single-panel/Point-conversion workflow and independent Band scale profiles. The maintained source import and verification pass, with internal report/source records excluded from public output. These source updates do not establish a rebuilt upload package, live deployment or public-release certification.

## Run locally

Node 22.14.0 and npm 10.9.2 were used. From this directory:

```powershell
npm ci
npm run docs:sync
npm run dev
```

Open the local URL printed by Vite. The development review uses `http://127.0.0.1:5178/`, launched explicitly with:

```powershell
node node_modules/vite/bin/vite.js --host 127.0.0.1 --port 5178 --strictPort
```

The explicit command also avoids shell wrappers consuming arguments after `npm run dev`. Production checks and a local production preview:

```powershell
npm run docs:check
npm run typecheck
npm run build
npm run preview
```

Deploying the contents of `dist/` requires a separate publishing decision. Hash routing works on static hosting and retains meaningful guide/control deep links without server rewrites. The relative Vite base supports a subdirectory. Opening source `index.html` directly with `file://` is no longer the supported workflow.

For a cPanel upload package, run `npm run package:cpanel`. The verified ZIP and hash manifest are written under the repository's ignored `dist/website/` directory. Follow [the cPanel upload guide](CPANEL_UPLOAD.md); this command builds locally and does not publish to a host.

## What the website contains

The control reference now follows all twelve approved plugin sections, with exact control membership, matching sidebar links and guide destinations. See [reference order and source refresh](verification/CONTROL_REFERENCE_ORDER.md).

The catalog filters and visual lessons share one minimal dropdown component, with keyboard navigation and viewport-aware menus. See [dropdown design and verification](verification/DROPDOWN_REFINEMENT.md).

- The user-selected blended garden landing: five interactive courtyard stages, layer/density/source controls, boundary inset, Analyzer views, keyboard local edits and a concept-image viewer.
- The guide’s “Plant with intention” hero now uses the accepted circular garden study. A compact toolbar offers Garden / Layers views and Build up above four closely spaced illustrative planes. Both views and playback retain the same illustrative plants. This is educational SVG, not plugin output.
- The user-selected fixed-rail visual guide: an illustrated ownership overview, six interactive lessons, first planting workflow, practical examples, glossary and a local 24-item review checklist.
- All 19 supplied feature posters, with current source-verified reading notes that visibly identify obsolete baked-in ownership labels.
- Artist features, exact behavior boundaries and two actual Max studies with version/context captions.
- Five complete maintained source documents, a fixed documentation sidebar, section links, printing and global search (`Ctrl+K` / `Command+K`).
- The complete current semantic catalog, with exact source keys, readable source-verified labels, explanations, ownership, local/MCP context and implementation-evidence paths. Entries do not each represent a distinct visible button or an individually qualified feature; current counts are in the [static verification receipt](verification/react-static-checks.json).
- All **34 capability families** are discoverable through the finder, including retired and experimental records. They are not marketed as 34 available product features.
- Explicit **Current**, **Experimental** and **Planned** distinctions, plus the five dependent roadmap stages from the maintained public summary.
- Native-dialog search with Escape/focus restoration, keyboard result navigation, empty states, mobile navigation, reduced-motion support and meaningful unknown-route/source-loading/error states.

There is no backend, signup, payment, telemetry, live Max connection or assistant login. Every primary action opens real guide/feature/reference content. The optional MCP foundation is narrower than the native artist UI; catalog visibility does not imply remote control support.

## Source architecture

| Path | Purpose |
| --- | --- |
| `src/App.tsx` | One React application, two user-selected route shells and hash navigation. |
| `src/components/SelectedLanding.tsx`, `selected-landing.html`, `landing-controller.ts` | Faithful supplied landing inside a React-owned, mount/dispose lifecycle boundary. Scoped listeners, observers, timers and drawing frames are cleaned up. |
| `src/components/DocsShell.tsx` | Selected fixed rail, breadcrumb/search topbar and accessible mobile drawer. |
| `src/components/PlantingLayerStudy.tsx`, `planting-layer-art.ts`, `planting-layer-study.css` | React-owned guide hero interaction, deterministic botanical SVG and scoped responsive layout. |
| `src/components/` | Search, real-study presentation, shared botanical symbols, typed educational drawing models and icons. |
| `src/pages/` | Illustrated guide, six lessons, workflow, poster library, examples, local checklist, glossary, full references and roadmap. |
| `src/styles.css`, `landing.css`, `docs-design.css`, `selected-refinements.css` | Local typography, preserved reference geometry, scoped shell styles, responsive states and print. |
| `content/source-manifest.json` | Explicit five-document manifest, catalog and selected supporting-doc/source-provenance enrollment. |
| `content/control-explanations.json` | Source-verified editorial metadata for every current exact semantic key. |
| `content/gallery-reading-notes.json` | Current reading notes, source evidence and guide links for every supplied poster. |
| `src/content/reference.json` | Deterministically generated current content and complete source fingerprints. |
| `content/guide-chapters.json` | Curated customer-facing chapters rendered into HTML and search data. |
| `content/changelog.json` | Concise version timeline with local-only evidence paths. |
| `public/assets/` | Local fonts, nine newly generated responsive concept images, eight preserved historical variants, 19 unchanged optimized posters and two actual Max studies. |
| `artwork/brand/` / `public/assets/brand/` | User-selected logo original, responsive logo/icon PNGs and provenance manifest. Root `public/favicon.ico` contains 16/32/48/64px frames. Reproduce with `tools/prepare_brand_assets.py` (Pillow). |
| `artwork/landing-20261011/` | Native 1448 × 1086 generated PNG originals and exact prompts. These are concept images, not plugin renders. |
| `artwork/hero-studies-20261011/` | Five native 1672 × 941 aerial image options and prompts. User selected Contour terraces for the full-width landing hero, fitted below navigation within the desktop viewport. |
| `tools/prepare_hero_studies.py` | Fifteen responsive hero-study encodings; SHA256/source receipts in `public/assets/hero-studies/manifest.json`. Requires Pillow. |
| `tools/import_reference.py` | Standard-library source importer and deterministic `--check` mode. |
| `tools/verify_reference.py` | Source hashes, current version, semantic-key identity, editorial coverage, reference links, assets and no-source-export checks. |
| `tools/extract_design_assets.py` | Reproducible extraction of the supplied main design's eight unique WebP variants. |
| `tools/prepare_concept_assets.py` | Native and responsive 480/960-pixel encodings of the new generated images, WebP quality 96; never upscales. Requires Pillow. |
| `tools/prepare_study_assets.py` | Faithful native 1200-pixel WebP display derivative with separate original/render provenance; requires optional `tools/requirements-assets.txt`. |

The importer renders curated guide text and strips changelog evidence before publication. Source fingerprints and control explanation evidence remain local. Raw Markdown, internal report snapshots, implementation bodies and owner licensing documents are not distributed. The packager rejects Markdown and the retired public source tree.

The public roadmap is curated against `docs/PRODUCT_AND_AI_ROADMAP.md`. Root/docs navigation and the MCP contract remain authoritative. Re-sync after changing these maintained sources; stale outputs fail `docs:check`.

## Routes

| Route | Content |
| --- | --- |
| `#/` / `#/home/workflow` | Selected landing and anchored interactive courtyard. |
| `#/features` / `#/features/painting` | Artist feature sections and technical studies. |
| `#/guide` | Selected illustrated guide overview and five core ideas. |
| `#/workflow` | Six-step first planting workflow. |
| `#/visuals/layers` | Six selectable interactive lessons; other IDs are containers, coverage, spacing, updates and viewport. |
| `#/gallery` | All 19 posters, series filters, viewer and current reading notes. |
| `#/examples` / `#/checklist` / `#/glossary` | Practical studies, local artist review and vocabulary. |
| `#/guide/artist-guide/vector-painting` | Exact chapter/section link. |
| `#/controls?q=radius&feature=C14` | Search and capability filters. |
| `#/controls?id=control-layer-brushui-beginbutton` | Semantic-key destination, independent of catalog order. |
| `#/roadmap` | Current/experimental/planned direction. |
| `#/about` | Versions, source provenance and image credits. |
| `#/changelog` / `#/changelog/v0.78.3` | Filterable development timeline and direct version links. |

## Visual provenance and history

The supplied `Landing Page Design/` archive is preserved unchanged. The active landing faithfully integrates `cyrus-scatter-site`; documentation preserves the `Design 1/website` shell, with the user-requested layer study replacing its overview hero illustration. These are direct ports of the selected compositions and interactions, with current source-verified text, rather than the previous React interpretation. Its supplied typography, proportions, image treatments and illustrated teaching structures remain visible. Concept images illustrate intent; educational diagrams do not execute Scatter. Actual captures are labeled separately: the 0.78.3 Max 2026 point-only Exclude inspection and the historical 0.75 Corona garden render (16 passes, 1200 × 1500). The garden display derivative is a 848,774-byte WebP (1200 × 1500, quality 95), with the unchanged 1200 × 1500 original’s hash recorded separately. The redundant 9.6 MB original is not shipped in public assets. Optional asset regeneration uses Pillow 12.3.0 (`python -m pip install -r tools/requirements-assets.txt`, then `python tools/prepare_study_assets.py`) and requires the original local artist source. Normal site builds do not need Pillow or that source folder. See the rendered Sources & credits page and image manifests. Fonts and SIL licenses remain local.

Old `assets/`, `sources/`, `content/coverage.json`, `content/WEBSITE_STATUS.md` and earlier `verification/` receipts are inactive historical evidence. They are excluded from the active React entry/build. The retired buildless `app.js`, root `styles.css` and `content/reference.js` have been removed; `src/` is the sole application. Historical browser reports do not certify this React edition.

## Validation boundary

Current public-content cleanup, version-history decisions and the replacement cPanel ZIP are recorded in [PUBLIC_CONTENT_HISTORY.md](verification/PUBLIC_CONTENT_HISTORY.md). The exact package passed 76 assertions and 152 HTTP file/hash checks; 45 existing interactions also pass.

The current visual lessons, complete practical-example artwork, connected controls and native-resolution image upgrade are recorded in [VISUAL_LESSONS_REFINEMENT.md](verification/VISUAL_LESSONS_REFINEMENT.md). The 45-interaction suite and 57 focused checks passed. That historical source-import block is resolved by the current reference refresh; internal report/source records have since been removed from public output.

The current guide hero integration is recorded in [LAYER_STUDY_INTEGRATION.md](verification/LAYER_STUDY_INTEGRATION.md). Earlier selected-design screenshots precede this hero replacement.

The selected-design implementation is recorded in [SELECTED_DESIGN_IMPLEMENTATION.md](verification/SELECTED_DESIGN_IMPLEMENTATION.md). Reproducible headless scripts are `tools/check_selected_routes.py` and `tools/check_selected_interactions.py`; CLI logs/screenshots are in the owned `build/website-react-implementation-20261011/` run. The current static check covers curated chapters, semantic controls, capability families, changelog versions, local source fingerprints, poster assets/reading notes and static navigation destinations. See the [current static verification receipt](verification/react-static-checks.json) for measured counts. No raw Markdown or supporting-report snapshots are public.

The [independent selected-design review](verification/SELECTED_DESIGNS_REVIEW.md) records the production-browser checks, reference preservation and final screenshots.

**Historical / rejected design:** `REACT_BROWSER_REVIEW.md`, `REACT_IMPLEMENTATION_REVIEW.md`, `react-desktop.png`, `react-mobile.png`, `react-features.png` and their earlier React receipts describe the preceding design that the user rejected. Preserve them as history; they do not validate this selected-design iteration.

Website validation does not qualify Max input, rendering, animation, long sessions, licensing, production ML, a particular assistant client, or every plugin control. Educational browser drawings change only deterministic SVG illustrations. The checklist starts unreviewed, stores only local browser notes and exports those notes; it is not certification. This website iteration did not edit product/native/runtime files, artist scenes, supplied design archives or installed profiles. Concurrent product/licensing work in this shared workspace is separate and was preserved.
