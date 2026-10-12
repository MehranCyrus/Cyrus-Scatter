# Control reference order and source refresh — 11 October 2026

The previous ten numbered sidebar items mixed guide chapters with capability filters. They combined Layers/Surfaces and Models/containers, sent Amount to a shared Layout chapter, and sent Statistics & diagnostics to Statistics alone. They did not represent the approved twelve-section plugin layout.

`src/content/controlSections.ts` now imports `AminScatter/tools/ui/approved-layout-manifest.json`. Its ordered titles and exact component/control identities define the sidebar, reference index, per-section filtering and control ordering. The sections are Layers, Surfaces, Models & Points, Source containers, Layout, Amount, Painting, Include / exclude areas, Transforms, Spacing & cleanup, Viewport & render, and Statistics & diagnostics. Numbered links now consistently open reference sections; each section separately links to its maintained guide explanation.

Painting combines Paint Areas and Vector Brush. Statistics includes cached statistics and diagnostic recording. Container properties accompany Source containers; setup/activation/update controls precede the sections in the full catalog, and optional layer-window controls follow them. Source group, source section and setting owner remain distinct. Capability families can span multiple sections and are not substituted for physical UI order. Active navigation survives additional filters; entry links retain semantic identities.

## Content accuracy

The source import was stale: the current catalog contains **241 entries**, including License / activation, and identifies **0.79.5**. The missing control now has source-backed editorial metadata. Counts are derived from imported data. The current five guide sources and fingerprints were refreshed; three new qualification references were explicitly enrolled.

The owner licensing report and issuer instructions are enrolled as `source-provenance` records: path/hash only, with `text: null`. Their bodies are not shipped. Primary artist instructions remain available in the artist guide. This resolves the previous import block without exposing owner operational documents or automatically publishing arbitrary linked files.

The public product-roadmap source incorrectly stated that activation was not implemented and that matched packages remained at 0.78.3. It now describes the implemented offline team pilot and bounded 0.79.5 qualification, retaining MCP limits and pending acceptance work. The release-version table was aligned with the current source/package; historical receipts remain historical. Poster imagery, poster-reading edition 0.78.3 and older Max captures retain their original provenance.

## Verification

- `npm run docs:check` passed: five current guides, 241 exact controls, 34 capability families, 28 supporting references and 73 resolved generated local links. Original source hashes, semantic identities, assets and body-free provenance records were checked.
- Strict TypeScript/Vite production build passed (`index-C0cBdD7x.js`). The existing >500 kB chunk advisory remains nonfatal.
- **62 focused reference assertions passed** against the approved manifest: all twelve exact control lists and their order, at 1440/768/320px, with correct active navigation, breadcrumbs, page titles and no horizontal overflow. Additional checks cover complete catalog identity, guide destinations, mobile navigation, Statistics/Diagnostics membership, metadata-only references and no runtime exceptions.
- **45 existing interaction assertions and 31 dropdown assertions passed** on that build. Desktop overview and Painting desktop/mobile screenshots were inspected.

Reproduce with `tools/check_control_reference.py`, `tools/check_selected_interactions.py` and `tools/check_dropdowns.py`, supplying `--browser <agent-browser executable> --url http://127.0.0.1:5180/ --output <fresh directory>/checks.json`. Current receipts, logs and screenshots are preserved under ignored `build/control-reference-20261011/accepted/`.

These are website/content checks, not new Max runtime qualification. No native/plugin implementation, artist scene, installation, commit, push or deployment was performed. Concurrent product and licensing work was preserved.
