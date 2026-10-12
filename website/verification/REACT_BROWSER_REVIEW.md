# Unified React website: source and browser review

**Historical / rejected presentation.** This receipt covers the preceding React design. The user subsequently selected different landing and documentation designs; use [the selected-design review](SELECTED_DESIGNS_REVIEW.md) for current presentation acceptance. Preserve the source reconciliation and asset provenance here as dated evidence.

Reviewed 11 October 2026 against branch `codex/workflow-0.75`, HEAD `46374194c5dba42d643425e3810390b8ddb3f903`, with the documented working-tree changes. This is a website/documentation review, not a new Max runtime qualification.

## Delivered scope

- One active React/Vite/TypeScript application under `website/`; the former buildless entry scripts are retired.
- Artist overview, feature explanations, five complete maintained guides, a searchable 240-entry semantic control reference, roadmap and source/credit views.
- Source inspection reconciled documentation with Scatter 0.78.3/schema 55, Surface Analyzer 0.14 and MCP package/plan 0.73.0/0.73. All 34 catalog families remain discoverable, including explicitly retired and experimental entries.
- Corrected stale receiver/paint-set ownership, vector-painting surface limits, Point versus Empty behavior, container collection defaults, Manual refresh actions, output cleanup versus an unavailable artist Bake action, and distinct Max/plugin/MCP qualification boundaries.
- MCP and ML descriptions separate the bounded implemented foundation, offline experiments and future product direction. No invented purchase/download destinations, assistant compatibility, release date or production ML capability.
- Local supplied concept artwork and genuine historical/current Max studies have different captions and source/hash provenance. A garden render initially described as a viewport capture was corrected before delivery. The original artist assets and scenes are untouched.
- Existing design archives, historical receipts and pre-existing test work are preserved. Four selected implementation references expose path/hash metadata only; their C++/MAXScript bodies are excluded from public assets.

## Reproducible checks

Run the first two commands from `website/`, and the remaining commands from the repository root:

```powershell
npm run docs:check
npm run build
python tools/procedural_lab/check_generated.py --output build/website-react-qa-20261011-010510/generated-final
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests/test_feature_catalog.py -q
git diff --check
```

All passed. The generated check used a fresh directory at invocation; use a new run directory when reproducing it. The build includes the TypeScript check. Content verification confirms 30 deterministic outputs, five complete maintained documents, 240 unique semantic keys, 34 catalog families, 24 selected supporting references and 67 resolved imported local links. The feature-catalog regression passed (one test). Catalog control records and schema remain unchanged; catalog edits update explanatory capability metadata and its documentation hash.

The source audit also checked 100 local links in the changed maintained documentation and the JSX feature/guide destinations. Generated MAXScript remained unchanged with SHA-256 `75e7105990052825a86b018649c6b425e6f0ec4ea1cc191ee49e57be327d6f1d`.

## Headless browser verification

An isolated agent-browser/Chromium session, `cyrus-react-root`, exercised the production preview at `http://127.0.0.1:5180/`. The review did not automate 3ds Max or use native computer control.

- **Responsive sweep:** overview, features, artist guide, controls, roadmap and credits at 320, 390, 768 and 1440 pixels: 24 cases, with no horizontal overflow or broken loaded images. Results: [responsive JSON](react-responsive-checks.json).
- **Search:** trigger button, Ctrl/Cmd+K, Escape, focus restoration, empty results, arrow-key selection and Enter navigation to a guide result.
- **Control finder:** radius search returned 19 entries; intersecting C14 returned two; Reset restored all 240. The stable Start Brush semantic ID opened the corresponding explanation.
- **Navigation:** mobile menu open/close, close on navigation, Escape/focus return, section deep links, browser Back/Forward and an intentional unknown-route recovery screen.
- **Teaching plan:** selecting Surface showed stage 01; ArrowRight advanced to stage 02.
- **Assets and motion:** local fonts/images loaded, the desktop hero used the 960-pixel source, reduced-motion preference was recognized, and no external asset hosts were requested during the inspected overview.
- **Final study images:** after the final build, a fresh document load confirmed the historical Corona caption and 900 × 1125 WebP. Both study images loaded without overflow at all four review widths: [image checks](react-study-image-checks.json), [Features screenshot](react-features.png). The garden display derivative is 425,950 bytes versus the untouched 9,596,603-byte original; both fingerprints and the encoding recipe are recorded in the capture manifest. Reopening only a hash in an older preview tab retained the previous bundle; the final check explicitly refreshed the document.
- **Errors:** the inspected browser flows returned no page errors. Lower-page controls were scrolled into view and navigation/modal readiness was awaited before interaction.
- **Visual inspection:** [desktop](react-desktop.png) and [mobile](react-mobile.png) screenshots, plus the full-page production capture in the owned run directory.

Owned root artifacts: `build/website-react-qa-20261011-010510/`. Implementation checks are recorded separately in [the implementation receipt](REACT_IMPLEMENTATION_REVIEW.md).

## Independent design review

An independent design evaluator returned **PASS** in rounds 1 and 2, including a fresh final review after the image/provenance correction. The root did not read its private evaluation reports. Only the available provider was used, so this is not a cross-provider evaluation.

## Remaining boundaries

- Human screen-reader use, additional real devices and cross-browser coverage remain optional acceptance work; responsive Chromium checks do not certify them.
- Hosting, distribution/download targets and commercial release decisions remain separate work. No deployment, commit or push was performed.
- This audit verifies documented features against source and existing evidence. It does not physically retest every Max control, requalify painting/rendering/performance, or certify assistant clients or ML behavior. Current product qualification limits remain visible in the guides and roadmap.
