# Selected logo and favicon — 11 October 2026

The user-selected `Layer 13 copy 2.png` is now the active site mark. The unchanged 714 × 713 RGBA original is preserved in `artwork/brand/cyrus-scatter-original.png`; its SHA256 is `954cca98cbdcaffce1f5e8c1cae7a973c3c458f4ddcc8e6ee4705f7372f3cecc`.

The landing header/footer, guide invitation and documentation sidebar use PNG derivatives of this exact artwork, preserving the existing wordmarks, link labels and navigation. The shared `Mark` component now uses the selected image. The active landing no longer defines or references the previous dotted SVG mark.

`tools/prepare_brand_assets.py` produces 96/192px header logos, 16/32px favicon PNGs, a 180px Apple touch icon, a 512px icon, and a multi-frame 16/32/48/64px ICO. Aspect ratio and alpha are preserved. No creative editing, tracing or image generation occurred. Source and derivative hashes are recorded in `public/assets/brand/manifest.json`; the source/content verifier now checks these assets.

Strict TypeScript/Vite build passed. **25 focused checks passed**: original byte identity, derivative hashes/dimensions/alpha, four ICO frames, landing and documentation logos at 390/1440px widths, no horizontal overflow, favicon/touch-icon declarations and successful HTTP delivery, old active mark removal and no browser runtime errors. Desktop/mobile screenshots were inspected. Evidence and the reproducible check script are in ignored `build/brand-logo-20261011/`. The pre-existing full documentation-import block is unrelated to these checks and is not claimed resolved here.

No plugin/native changes, installation, commit, push or deployment occurred. Other concurrent source/document changes were preserved.
