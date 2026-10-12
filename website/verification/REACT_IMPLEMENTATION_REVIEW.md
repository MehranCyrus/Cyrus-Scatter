# React implementation verification — 11 October 2026

Scope: the unified `website/` frontend and its public content. This receipt does not qualify the Max plugin, native calculations, every artist control, MCP clients or ML behavior.

## Build and deterministic content

- `npm install`: 24 packages installed, audit reported zero vulnerabilities at this run. Exact versions and transitive resolution are in `package-lock.json`.
- `npm run build`: TypeScript and Vite production build passed. After the image-provenance correction, code is split into React vendor (218.75 kB / 68.26 kB gzip), application/current content (377.41 kB / 66.10 kB gzip), a small runtime and local CSS/assets. These are build sizes, not browsing performance measurements.
- `python website/tools/import_reference.py --check`: all 30 outputs matched the selected sources.
- `python website/tools/verify_reference.py`: passed for five complete maintained documents, 240 unique semantic-key controls, 34 capability families and 67 imported local reference/section links.
- All 240 entries have source-verified readable labels, specific explanations, owner context and evidence paths; raw catalog fields remain intact.
- Twenty selected supporting documentation snapshots are bundled on demand. Four implementation references contain source path/hash metadata and no C++/MAXScript body. The verifier asserts this distinction.
- Eight WebP variants are extracted/deduplicated from supplied artwork; the corresponding 960-pixel images are used for the main features. Fonts are local, with SIL licenses.

## Focused headless browser checks

Agent-browser / Chromium session `cyrus-react-implementation` used the local Vite server at `http://127.0.0.1:5178/`.

- The overview rendered with the intended courtyard image and local type. Visually inspected `build/website-react-implementation-20261011/home.png`. The final Features studies view was captured in `features-final-garden.png`; the historical Corona render’s optimized WebP derivative loaded at 900 × 1125, preserving its 1200 × 1500 rendered-source provenance.
- Selecting the Surface workflow tab changed the visible SVG/panel to stage 01, “Choose the ground.” Pressing ArrowRight moved to stage 02. Lower-page controls were scrolled into view before clicking.
- The `#/controls?q=brush` deep link populated the finder with relevant readable control names, ownership filters and all 34 capability options.
- An unknown route displayed the intentional “This page hasn’t taken root” recovery view. The browser error query returned no page errors in that check.
- The corrected development-server command runs Vite directly. An earlier npm-shell argument attempt treated a port value as a directory and returned 404; that launch was stopped and replaced. It is not the delivered launch configuration.

Independent root browser verification covers broader routes, filters, modal keyboard/focus behavior, history and responsive sweeps. Its separate report is the authority for those checks; they are not inferred from this focused implementation receipt. Human screen-reader and target-browser certification remain open.

## Content and release boundaries

The garden display asset is an optimized WebP derivative: 900 × 1125, quality 90, 425,950 bytes, with transparency preserved. Original and derivative fingerprints are stored separately in `public/assets/captures/manifest.json`; the 9.6 MB source image remains only in the artist folder. Side-by-side full-image and detail comparisons in `build/website-react-implementation-20261011/garden-encoding-comparison.png` and `garden-encoding-detail.png` were visually inspected. Plant texture, color, silhouettes and transparency remain faithful at the intended display scale.

Concept images are not Cyrus renders. The two actual Max studies retain their precise image type and version/context labels: a Max 2026 0.78.3 point-only viewport capture, and a historical 0.75 Corona garden render (16 passes, 1200 × 1500). The latter is a visually faithful display derivative of `Test Scene/Reference_Garden_075/Garden_Final.png`, identified by `build/reference-garden075/final_render.ms:23–32`; it is not a viewport capture or current benchmark. Current, Experimental and Planned status are separate; no purchase, public-download, subscription-compatibility or release-date claims were fabricated.

No plugin code, Max profile/scene, supplied design archive, Git push or deployment was part of this implementation.
