# Website verification — 7 October 2026

**Result: the local documentation website passed the checks below.** This review concerns the website, not the 3ds Max plugin.

The primary agent independently tested the implementation using an isolated Chromium browser. A separate design evaluator completed two review rounds; the final verdict was PASS. Testing used the local HTTP preview and direct `file://` loading, with desktop 1440 × 1000, mobile 390 × 844 and narrow 320 × 740 viewports.

## Content and preservation

- All 16 original Markdown snapshots match their authoritative source hashes.
- An independent comparison found all 240 inventory entries, retaining repeated names and section context, without missing or extra entries.
- Every inventory destination was opened in the rendered browser: 240 checked, no missing targets, no targets left hidden inside closed Advanced sections, and no duplicate IDs in the destination chapters.
- All 16 chapters rendered from `file://` at mobile width without page-wide horizontal overflow. Wide reference tables have their own scrolling region.
- All 28 artist walkthrough steps remain available. Personal checkboxes explicitly mean reviewed by the reader; they do not record plugin test passes.
- All 2,617 pre-existing tracked/reference files match the captured baseline. See [preservation.json](preservation.json).

## Browser interactions

| Area | Observed result |
| --- | --- |
| Navigation | Overview cards, chapter navigation and study tabs reach their destinations. Browser Back restores the control-finder query and owner filter. |
| Search | Rectangle, radius, logging and grass searches give contextual results. Empty searches have a recovery message. Keyboard search, result selection and Escape work. |
| Advanced links | A destination opens its containing Advanced section. Reopening the same destination after manually closing its section also works. |
| Ownership | The control finder distinguishes setup, layer, paint-set, source and instance contexts. The layer-entry metadata error found during review was corrected and rechecked. |
| Population study | Visibility changes leave the flower allocation intact; disabling the set reallocates the shared request. |
| Container study | Parking and returning a model preserves its edited weight and identity. Changing height does not change membership. |
| Coverage study | Changing the rule remains pending until Apply. The illustrated accepted count changes from 60 to 70 out of 80 when switching between the tested coverage choices. |
| Update study | Manual edits stay pending until Update. Reading cached statistics does not commit them. Live applies a relevant edit after a short pause. No DOM changes were observed during a 1.5-second idle sample of this website illustration. |
| Walkthrough | Personal progress survives page reload and can be reset. |
| Mobile navigation | Opening the drawer focuses its close control and makes the background inert. Closing it restores the normal page; the hidden drawer is inert. |
| Responsive studies | All four study tabs remain visible in a two-by-two arrangement on mobile. Range controls have explicit accessible labels. |
| Reduced motion | The browser preference is recognized; sampled link transitions are zero-duration and page scrolling is not smooth. |
| Direct local opening | The application, search, chapters, generated images and local fonts load from `index.html`. The checked overview made no HTTP(S) resource requests. |
| Errors | No uncaught JavaScript errors were reported during the checked routes and interactions. |

The reviewer initially observed an inconclusive card-click issue. A subsequent independent click on that complete visible link correctly opened the visual studies; no failure was reproduced.

## Offline checks

These commands were rerun independently and passed:

```powershell
python website/tools/import_reference.py --check
python website/tools/verify_reference.py
node --check website/app.js
```

The offline validator also checked 333 rendered source links, 22 authored chapter links, 847 unique deep links, local assets and image/font signatures. Its separate result is saved in [static-checks.json](static-checks.json).

## Visual evidence

- [Desktop overview](desktop-overview.png)
- [Mobile overview](mobile-overview.png)
- [Mobile interactive study](mobile-study.png)

Three generated concept images were visually inspected. Their exact prompts and provenance are recorded in [image credits](../assets/IMAGE_CREDITS.md). They are labelled as concept illustrations in the website.

## Limits of this review

The browser run used Chromium with viewport emulation. Other browser engines, physical touch devices, assistive-reader software and printed-page pagination were not qualified. This website review does not establish 3ds Max performance, cache correctness, render behavior, Undo correctness, licensing, MCP operation or ML capabilities. Interactive studies are teaching examples rather than a replacement scatter engine.
