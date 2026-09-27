# Cyrus Scatter 0.58 / Surface Analyzer 0.13

Performance changes (MAXScript only; native engines remain bin55 / bin05):

- Layer rollouts mount their child controls only on the first expansion. They retain those controls while the panel remains mounted. Switching objects or resizing the command panel can reconstruct the UI, preserving expanded-layer state.
- Viewport preview and Analyzer realtime evaluation wait while a mouse button is held. Scatter keeps its existing preview during a drag. A 200 ms release monitor redraws after release; source geometry notifications are queued with mouseUp:true. Explicit production rendering still evaluates current data.
- Each blocker keeps one raw-placement result keyed by placement parameters, source/surface/area identities and transforms, Analyzer output revisions, time, external scene revision and explicit refresh revision. Overlap filtering, final cleanup, orientation and CS Edit remain downstream and are not cached as raw blocker data. Memory usage increases by the retained raw placements; changing a key replaces that layer's entry.
- IR waits for a stable input signature (at least one second, checked by the existing 750 ms timer) before rebuilding. Deletion notifications for disposable PFlow nodes are excluded from Scatter/Analyzer invalidation; user node deletions remain processed.

No point generation algorithm, seed, collision rule, saved scene, native DLL, or renderer quality setting has been changed by this release. Old scenes retain parameter defaults; updated script class versions are Scatter 43 and Analyzer 12.

## Validation

See work/v58/test.txt and render-test.txt for recorded timings and outcomes on a disposable copy of Select.max. UI lazy expansion/reopen, exact raw placement matrix/source equivalence, cache invalidation by seed and scene revision, and scene saving are exercised. Render test checks held-input preview suppression, a small production render, and exactly one IR rebuild after one Border width edit.

## User check

Restart 3ds Max after installation. Open your own scene, select Scatter, expand only the layer you need. During vertex/spinner dragging the previous scatter preview is intentionally retained; release the mouse to evaluate the final value. Test Corona IR start, a Border width change and stop. The final recomputation can still take time on dense scenes; this release avoids redundant work rather than promising zero calculation cost.
