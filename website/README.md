# Cyrus Scatter — Visual Guide

**Historical snapshot:** current plugin development is 0.75. Use the [current artist guide](../docs/System_Qualification_0.75_2026-10-09/ARTIST_GUIDE.md) and [qualification checklist](../docs/System_Qualification_0.75_2026-10-09/CHECKLIST.md) for layer-owned surfaces and Paint Areas. This site's 0.73 model-owning-set examples have not been migrated; do not use them as the current ownership specification.

A complete local landing page, visual artist guide and development roadmap for the **0.73 development baseline**, dated **7 October 2026**. It pairs all 16 reference chapters with a contextual control finder, practical workflows, six interactive explanations and three generated concept images. “Final” describes this combined website iteration, not a public plugin release.

## Open the guide

Open **`index.html`** in a modern browser. Everything needed to read, search and explore the site is included locally. It also works from a local web server:

```powershell
python -m http.server 8765 --bind 127.0.0.1 --directory website
```

Then open `http://127.0.0.1:8765/`. When the terminal is already inside this website folder, omit `--directory website`.

There is no package installation, build step, backend, account, analytics or connection to 3ds Max. Font files are local. The website makes no runtime network requests.

## What is included

- A simpler visual overview, six feature families and a seven-step first planting workflow with one consistent courtyard teaching plan.
- Every original artist-reference chapter, preserving the substantive text and tables.
- A finder for all **240 inventory entries**, with name/description search, Topic, Owner and Common/Advanced filters, and section context for repeated names. This is not a claim of 240 distinct visible buttons.
- Whole-guide search (`Ctrl+K` / `Command+K`), including Surface Analyzer, automation and other controls beyond the core inventory.
- Stable hash routes and precise control anchors. Search and direct links reveal closed Advanced sections. Browser back/forward works without server-side routing.
- Six educational studies: shared population, active/parked sources, coverage versus accepted planting, independent spacing scopes, Manual/Live update behavior, and preview versus accepted/final output.
- A status route separating implemented functionality, qualification limits and four future stages with acceptance conditions. Status copy is traced to the independently reconciled `content/WEBSITE_STATUS.md` snapshot.
- All **28 source walkthrough steps**, with optional local “reviewed by me” checkboxes. They do not claim the plugin passed a test. Reset is available.
- Desktop navigation, a mobile drawer, keyboard controls, reduced-motion support and chapter printing that expands Advanced sections for the printout.
- Portable original Markdown copies, a coverage manifest and exact image prompts.

## Files

| Path | Purpose |
| --- | --- |
| `index.html` | Buildless application shell. |
| `styles.css` | Responsive visual system and print styles. |
| `app.js` | Navigation, search, controls, demos and local walkthrough progress. |
| `content/reference.js` | Generated chapter markup, navigation data and search records. Classic JavaScript works from `file://`. |
| `content/coverage.json` | Every inventory entry's destination, source hashes and walkthrough coverage. |
| `content/WEBSITE_STATUS.md` | Dated source snapshot for the authored status and roadmap route. |
| `sources/` | Exact copies of all 16 authoritative Markdown documents. |
| `assets/*.webp` | Three optimized, generated concept studies. |
| `assets/originals/` | Preserved unmodified generated PNGs. They are not loaded by the webpage. |
| `assets/IMAGE_CREDITS.md` | Exact prompts, captions, generation mode and limitations. |
| `assets/fonts/` | Instrument Serif and Manrope font files, source notes and OFL licenses. |
| `tools/import_reference.py` | Reproducible content importer; Python standard library only. |
| `tools/verify_reference.py` | Offline completeness, deep-link, ownership and asset checks. |
| `verification/` | Saved check results and any subsequent browser evaluation evidence. |
| `TASKS.md` | Delivery checklist and honest remaining boundaries. |

## Source of truth and maintenance

The source is `docs/Artist_Reference_0.73_2026-10-07/` at repository baseline **`d55dfa88cbeda7af366e4510ac3119a749368958`** (`codex/unified-0.73`). Original docs, plugin code, artist scenes and installers are not edited by this website.

From the repository root, rebuild after deliberately updating the authoritative docs:

```powershell
python website/tools/import_reference.py
python website/tools/verify_reference.py
node --check website/app.js
```

For a copy of the website outside the repository, the importer automatically uses its `sources/` snapshots. An explicit source folder is also supported:

```powershell
python tools/import_reference.py --source sources
python tools/import_reference.py --source sources --check
python tools/verify_reference.py
```

The importer supports the Markdown constructs actually present in the supplied reference and fails on unknown local links or unmapped inventory controls. It assigns unique anchors per chapter, preserves repeated control labels, and maps each inventory entry to an explanation. When the inventory changes, review the contextual aliases and owner mappings in the importer. Update the dated baseline deliberately rather than allowing provenance to imply a newer reference.

Keep exact setting names in the authoritative chapters. Use aliases in `app.js` only to help search; do not silently rename plugin controls in the reference.

## Routes and interactions

- `#/` — overview
- `#/workflow` — first planting
- `#/controls?q=radius&scope=Source&topic=models&detail=common` — filtered control finder
- `#/doc/models/control-radius` — a control explanation
- `#/visuals/shares`, `/containers`, `/coverage`, `/spacing`, `/updates`, `/output` — the six studies
- `#/status` — development status, limitations and four-stage roadmap
- `#/walkthrough` — personal checklist
- `#/about` — sources and imagery provenance

The visual studies are lightweight teaching examples. They use deterministic shapes and bounded sample points rather than attempting to run or reconstruct Cyrus Scatter. The courtyard lesson keeps a consistent plan across seven stages; its illustrative filtering is not engine output. The three raster images are separate concept studies, not a matched-camera sequence, generated plugin renders, real UI screenshots or proof of product behavior. No new raster art was necessary for the combined iteration.

Local progress is stored under `cyrus-guide-073-walkthrough-reviewed`. Browser privacy settings may prevent persistence, in which case the checkboxes remain usable for that open page. Reset removes the saved selections. No scene or artist data is captured.

## Verification boundary

`tools/verify_reference.py` checks full content regeneration, exact source-copy hashes, 240 control destinations, 28 walkthrough steps, owner metadata, same-label links, all rendered Markdown cross-links, authored chapter anchors, local assets and image/font signatures.

The earlier website's independent browser review remains in [BROWSER_REVIEW.md](verification/BROWSER_REVIEW.md); it predates the final combined interface and does not qualify these additions. Fresh offline checks write `verification/final-static-checks.json`, including website file hashes, authored route checks and the exact status-source snapshot check. Implementation spot checks and screenshots use the `final-implementation-` prefix. The final combined site received an independent design evaluation **PASS**. The root agent's fresh browser checks and their limits are recorded separately in [COMBINED_BROWSER_REVIEW.md](verification/COMBINED_BROWSER_REVIEW.md).

This website task does **not** qualify any Max UI, rendering, animation, source-container Undo, cache behavior, licensing, MCP operation or ML capability. Those development limitations remain visible in the guide.
