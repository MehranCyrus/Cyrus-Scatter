# Landing images and viewport fit — 11 October 2026

The user selected **Contour terraces**, the third of five newly generated aerial landscape options, for the main landing image. The hero spans the available desktop width and fits in the remaining viewport height below the navigation. It no longer adds a 1080px image section below an 88px header. The headline is smaller (96px maximum, italic multiplier 1.28), moves to an approximately 6% left inset and retains the existing fonts and colors. The “Consider every layer” caption, brackets and their obsolete CSS are removed.

An initial aspect-ratio/min-height combination also expanded the section horizontally at a 900px viewport. Explicit width, viewport height and removal of that aspect-ratio constraint fixed it. Header-height handling matches the existing 959px breakpoint. Narrow/mobile layouts retain their separate copy-over-image composition and a staircase-focused crop. Responsive source selection accounts for the image width needed by the tall mobile cover crop.

## Generated assets and prompts

All generation used the **built-in image_gen** tool. No external stock-image services were used. These images illustrate composition; they are not plugin renders or proof of brush behavior.

The first set comprises a limestone courtyard, coastal hillside and perennial border. Native PNGs are 1448 × 1086, with quality-96 WebP derivatives at 480, 960 and native width. The landing environment gallery, enlarged viewer and Sources page use the new assets. Eight older supplied variants retain their original bytes and manifest records.

The five aerial concepts have native dimensions **1672 × 941**:

1. [Meadow ribbons](../artwork/hero-studies-20261011/01-meadow-ribbons.png)
2. [Courtyard islands](../artwork/hero-studies-20261011/02-courtyard-islands.png)
3. [Contour terraces — selected](../artwork/hero-studies-20261011/03-contour-terraces.png)
4. [Reflection garden](../artwork/hero-studies-20261011/04-reflection-garden.png)
5. [Park brushstrokes](../artwork/hero-studies-20261011/05-park-brushstrokes.png)

Exact prompt sets: [three environment images](../artwork/landing-20261011/prompts.json) and [five aerial images](../artwork/hero-studies-20261011/prompts.json). The requested resolution in a prompt is not the delivered resolution; native sizes above were decoded from the resulting files. There is no raster upscaling. Normal CSS display scales/crops the images to the viewport.

The selected native WebP is 1,061,590 bytes. Native and 640/1100-width derivatives for all five options are in `public/assets/hero-studies/`, with original/derivative SHA256 hashes and dimensions in its manifest. `tools/prepare_hero_studies.py` reproduces these derivatives. `tools/prepare_concept_assets.py` reproduces the environment set. Native PNG originals remain in `artwork/` rather than the public download bundle. Sources links open full native WebP images. Supplied design packages and real Max captures were preserved.

## Verification

- Strict TypeScript and Vite production build passed. Final entry: `index-CuQgTz12.js`, stylesheet `index-BavPKe8t.css`. Existing large-chunk advisory remains.
- **50 focused checks passed**: all 15 aerial derivative hashes/dimensions and original hashes; ten responsive viewport sizes; selected image, visible actions, full-width layout, exact viewport-height fit below the header, reduced headline, left inset, overlay removal, Sources links and no browser runtime errors. Desktop sizes included 900/960/1024 × 768, 1366 × 768, 1440 × 900, 1904 × 909 and 1920 × 1080. Mobile/tablet sizes included 320 × 900, 390 × 1000 and 768 × 1024.
- **45 existing interaction assertions passed again** after the final layout changes, including gallery navigation and focus restoration. Earlier environment-image review passed 27 checks before the hero replacement; it remains scoped to that earlier presentation.
- Desktop/mobile screenshots were inspected. Reproduction scripts, JSON receipts and screenshots are in ignored `build/hero-studies-20261011/`; earlier environment receipts are in `build/landing-image-refresh-20261011/`.
- `git diff --check -- website` passed; CRLF normalization notices are not whitespace errors.

Full source-document synchronization is still blocked by `docs/licensing/TEAM_PILOT_0.79_2026-10-11.md` missing from the explicit public supporting-source manifest. This image/layout change does not silently publish that document or claim a fresh product-reference import. Plugin/native code, installation and release qualification are outside this work. No commit, push or deployment was performed.
