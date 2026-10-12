# Public content and changelog — 12 October 2026

The website now publishes five curated, rendered guide chapters and a 53-version development timeline. Raw Markdown downloads, internal report pages/JSON, implementation evidence panels and the public `sources/` tree are removed. Artwork credit and font README Markdown files were moved out of the public tree; font license text remains bundled. Local walkthrough export is plain `.txt`.

Repository documents remain intact. The former generated public sources and credit authoring files are preserved locally under ignored `build/website-public-history-20261012/retired-public/`. Historical verification reports describe their earlier packages and are not current acceptance. Do not deploy the preceding cPanel ZIP.

## History decisions

`content/changelog.json` contains concise Added/Fixed/Improved/Changed entries with private evidence paths. `content/source-manifest.json` pins 48 reviewed local source documents. The importer strips those paths and publishes only editorial history/guide content, semantic control descriptions and capability context.

Coverage runs from documented 0.10 milestones through 0.79.5, using the September version-history handbook, dated implementation/fix reports and Git chronology. Early dates are unknown and shown as before 27 September; missing versions are not invented. In particular, no independent 0.79.3/0.79.4 changes are documented here. Same-version follow-ups are grouped: 0.74 includes 9 October ownership work, 0.75 includes 10 October Proxy/Analyzer fixes, and 0.79.5 includes the creation correction. Early 1.0–1.2.3 labels precede the later 0.7 numbering and are explicitly historical, not commercial releases. Current uncommitted 0.79.2/0.79.5 campaigns are documented development work, not new published Git releases. Analyzer and MCP are independently versioned.

The page exposes change-type filters, version/feature search, collapsible earlier eras, stable version links and guide-search results. It is linked from documentation navigation and the landing footer. Existing design, logo and artwork remain intact.

## Exact accepted package and checks

- `dist/website/cpanel-2026-10-12-CISKsvEm/CyrusScatter-website-0.79.5.zip`: 76 files, 17.80 MiB, SHA-256 `4f952afdd85b4075038d636a590e6f6ff947aa7ae565fa6a563e9a8ee7bc3258`.
- Documentation/source checks, TypeScript compilation, production build and ZIP integrity/readback pass. No public Markdown or internal reference snapshots remain.
- Exact ZIP tested on an owned plain static server at root and `/preview/`: **76 assertions and 152 HTTP file/hash checks pass**. Eleven routes per destination include all five chapters, changelog and credits. Checks cover removed raw URLs returning 404, no raw document links, type/version search, empty state, early-history expansion, historical deep links, connected dropdowns, mobile fit and no browser exceptions.
- **45 existing interaction assertions pass**, including lessons, sliders, search, gallery, checklist `.txt` export, mobile navigation and landing controls.
- Screenshots and receipts: ignored `build/website-public-history-20261012/accepted-final/` and `regression-final/`.

The first archive check exposed filtered changelog state surviving a version-link navigation. Keying the page by its route resets filters before following a version destination; the accepted rerun includes this regression. The earlier failed run is retained. An initial preview regression attempt found no server listening; a fresh local preview was started and the complete rerun passed.

This is website qualification only. No Max source/runtime change, artist installation, Git push or public deployment was performed. cPanel/DNS/HTTPS remain unverified. If a previous package was uploaded, its retired public source files must be removed from that destination; see [upload instructions](../CPANEL_UPLOAD.md).
