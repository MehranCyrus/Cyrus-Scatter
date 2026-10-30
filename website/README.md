# Cyrus Scatter — website and field guide

The maintained website follows the **Scatter 0.87.6.7 testing release**, scene 65, portable recipe 9,
Interactions 17 and Edit capability/storage 5/4. It covers individual instance
selection, shared controls for multiple setups, responsive artistic Bend/Trim,
independent root hiding, retained shared geometry and the existing Library.

The website includes the verified **0.87.6.7 EXE for Max 2024, 2026 and 2027**.
The full static upload ZIP contains that installer under `downloads/`. Plugin
runtime qualification covers focused Max 2027 checks; Max 2024/2026 are
SDK-build/package only. Surface Analyzer 0.14.2 and optional plant content 0.86.7
remain independent and are not embedded. This is a local upload package, not a
live deployment.

Five curated guides, **379 semantic controls**, **14 plugin sections** and **37
capability families** follow current source evidence. Catalog visibility does not
grant MCP mutation authority. Development MCP extensions are described separately
from the packaged 0.73.0 foundation. Fast guide responses can leave overlaps;
there is no universal FPS, exact-clearance or arbitrary-topology guarantee.

See [website validation](verification/UPLOAD_08767_20261029.md),
[plugin delivery](../docs/plans/edit-preparation-08767-20261029/DELIVERY.md)
and [packaging/publication state](CPANEL_UPLOAD.md).

## Work locally

From website/:

```powershell
npm ci
npm run docs:sync
npm run docs:check
npm run build
npm run dev
```

`npm ci` is needed only when installing dependencies. The build runs TypeScript,
Vite and the download-publication guard. It creates local `dist/`, not a ZIP or
live deployment. `npm run preview` serves that build. For the established explicit
development port use:

```powershell
node node_modules/vite/bin/vite.js --host 127.0.0.1 --port 5178 --strictPort
```

Hash routes and the relative Vite base support static hosting and subdirectories.
Opening source index.html with file:// is not the supported workflow. Use `npm run package:cpanel` to build the static upload ZIP with the verified
installer. See `CPANEL_UPLOAD.md` before uploading.

## Source ownership

| Path | Purpose |
| --- | --- |
| src/App.tsx | React application, hash routing and route shells. |
| src/components/SelectedLanding.tsx, selected-landing.html, landing-controller.ts | Selected landing composition and bounded educational interactions. |
| src/components/DocsShell.tsx | Fixed documentation rail, search and mobile navigation. |
| src/components/PlantingLayerStudy.tsx and related artwork/styles | Deterministic illustrated guide hero; not plugin output. |
| src/pages/ | Features, guides, workflow, Library showcase, latest version, examples, controls and roadmap. |
| content/release.json, src/content/release.ts | Reviewed product edition; download publication is independent. |
| content/guide-chapters.json | Curated artist chapters rendered into HTML and search content. |
| content/control-explanations.json | Readable explanations and ownership for exact semantic keys. |
| content/changelog.json | Versioned changes; local evidence paths are stripped from public output. |
| content/source-manifest.json | Reviewed parent hashes and the five maintained guide owners. |
| src/content/reference.json | Deterministic generated content; edit its inputs instead. |
| tools/import_reference.py, tools/verify_reference.py | Source import, fingerprints, control coverage, assets and link checks. |
| tools/stage_release.py | Verify and stage only the installer selected in release.json. |
| public/assets/ | Existing local artwork, model previews, fonts and historical studies. |

The reference follows the approved plugin section ordering, including Interactions
and Scene colliders. The selected landing and documentation designs are preserved.
This task changes content and release availability, not the illustrative algorithms.
Public output contains no raw repository Markdown, internal report bodies or owner
licensing documents. Website content generation does not rebuild knowledge indexes.

## Main routes

| Route | Content |
| --- | --- |
| #/ | Selected landing and interactive courtyard studies. |
| #/features | Artist features and contextual historical studies. |
| #/guide, #/workflow, #/visuals | Guide overview, first planting workflow and visual lessons. |
| #/guide/artist-guide/select-instances-and-multiple-setups | Current instance selection and shared-control workflow. |
| #/controls | Searchable current semantic reference. |
| #/library, #/gallery | Plant showcase and 19 feature posters with provenance. |
| #/download | Current release, EXE download, supported hosts and installation instructions. |
| #/examples, #/checklist, #/glossary | Examples, local review notes and vocabulary. |
| #/roadmap, #/about, #/changelog | Status distinctions, credits and historical changes. |

## Evidence and visual provenance

Concept images and educational SVG studies do not execute Scatter or prove its
output. The selected Contour terraces hero and other generated artwork retain
original provenance. The 19 supplied posters retain current reading notes where
baked-in ownership labels are historical. Actual Max captures retain their original
versions: the 0.78.3 point-only Exclude study and the 0.75 Corona garden render.
Individual plant previews are an asset showcase, not a downloadable content pack.

Original design archives, artwork sources and old verification receipts are
preserved. [Selected design implementation](verification/SELECTED_DESIGN_IMPLEMENTATION.md),
[layer study](verification/LAYER_STUDY_INTEGRATION.md) and earlier browser receipts
retain their historical scope; they do not certify current changed copy or layout.

This update uses source/content checks, TypeScript and a production build without
Computer Use. It does not add browser visual acceptance, plugin runtime tests,
installer execution or hosting qualification. The website has no backend, signup,
payment, telemetry, live Max connection or assistant login.

The working source advanced to **0.87.6.7** during this task. Its mesh-shaped
selection-outline patch is still under development. The last recorded qualified
delivery is **0.87.6.4**; previous test passes do not qualify the successor.
