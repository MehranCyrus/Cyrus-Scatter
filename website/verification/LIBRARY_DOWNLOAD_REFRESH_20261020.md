# Individual library and download website refresh

20 October 2026. Local source/build delivery; no website publication or plugin changes.

## Result

- Existing selected visual identity and main concept hero retained.
- `#/library`: twelve original Corona model previews, six botanical categories, accessible native image dialog, library-to-recipe steps and a labeled actual Max 2027 textured-leaf example.
- Landing: four specimens, navigation and release/download section.
- `#/download`: one typed 0.86.7 release record, supported hosts, accurate EXE/Content sizes, separate EXE/MZP instructions and explicit unavailable actions. URLs remain null pending hosting/content decisions.
- Public guide, feature stories, controls, changelog, roadmap and website documentation reconciled with the actual 0.86.7 handoff. Independent Analyzer/MCP versions remain separate. Historical source receipts are preserved.
- Narrow changelog overflow and two garbled public editorial strings corrected.

The source report is `docs/plans/preset-gallery-improvements/DELIVERY_0867.md`. Native/UI/installer checks span Max 2024/2026/2027; actual supplied Corona leaf appearance was tested on Max 2027. Preview supports bounded base-color/cutout behavior, not final-render equivalence. These are imported delivery facts, not new plugin testing by this website task.

## Assets and distribution

Twelve exact existing JPEGs total 460,525 bytes. Private provenance is in `library-showcase-provenance.json`. The public output contains selected images and one viewport PNG; no MAX models, texture library, EXE or MZPs were copied into the website. Concept images and teaching SVGs remain labeled separately from actual outputs.

All twelve copied previews were compared with their 0.86.7 originals using SHA-256 and match exactly.

0.86.7 EXE: 5,480,448 bytes. Required matching Content: 5,851,207,027 bytes. The twelve website specimens do not constitute a smaller installable pack. Installer/content changes would be required before advertising optional smaller collections.

## Checks performed

- `npm.cmd run build`: TypeScript/Vite production build passed. Vite reports a main chunk above its 500 kB warning threshold; this is a warning, not a failed build or a measured page-performance result.
- `npm.cmd run docs:check`: deterministic import and static reference verification passed. Five documents, 320 controls, 83 changelog entries, 85 reviewed source identities, 44 generated links and 45 static navigation destinations. Receipt: `react-static-checks.json`.
- Focused Chromium browser review: **22 checks pass**. All twelve specimen images decode, Trees/Leaves filters give the expected cards, enlarged image dialog opens, Escape closes/restores focus, release identity and unavailable actions match, mobile navigation works, and changed pages have no horizontal overflow at 390/1440 pixels. No JavaScript runtime errors were observed.
- Independent design-agent review passed at 390/768/1440 pixels; final disabled-download refinement passed at 390/1440. Evaluator uses the same available provider because no different-provider evaluator was enabled.
- `git diff --check -- website`: passed (line-ending normalization warnings only).

Browser artifacts are under ignored `build/website-refresh-20261020/`: `functional-review.json`, `offline-preview.html`, `offline-app.js`, `make-offline-preview.mjs` and `evaluation/` screenshots. Final download screenshots use `download-final-1440.png` and `download-final-390.png`. Library and landing screenshots retain their original names.

The prior automatic approval review rejected a background local preview-server launch without a detailed reason. This task did not retry that action. Instead, the standard production entry was bundled into a classic IIFE for an explicitly local `file://` preview, with an unchanged production asset base. No server, browser security override or artist session was used. HTTP root/subfolder serving, CDN caching, live domain deployment and real downloads remain unqualified.

## Delivery and remaining work

The standard deployable site is `website/dist/`; the upload packager writes its ZIP/integrity manifest under root `dist/website/`. The offline preview is review-only and is not included in that upload ZIP. Website sources and maintained plans are updated locally. No Git commit/push, plugin installation, Max restart or hosting deployment is part of this pass.

Integrity-checked local upload artifact: `dist/website/cpanel-2026-10-20-DhCT5nDs/CyrusScatter-website-0.86.7.zip`, 89 files / 19,283,549 bytes (18.39 MiB), SHA-256 `128ac19cae7d6d6c9b2e4e57aede875dd154b091ee0e64dcf5111ed0cac995c3`. ZIP entries were read back and compared byte-for-byte by `tools/package_site.py`.

Decide public release hosting, complete versus curated content delivery, and any corresponding installer changes before enabling download links. Optional preview replacements for pale lavender/clover remain editorial refinements, not blocking implementation defects.
