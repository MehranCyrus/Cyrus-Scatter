# Instance hover and entry — 0.87.6.4

User-authorized patch: replace whole-controller highlighting with a small cue
on the one instance under the pointer. A plain viewport click activates that
instance's layer and the separate Cyrus Scatter Edit modifier. Icons and Ctrl
multi-selection continue to select setups. No scene schema or solver change.

## Ownership and work

- The committed visible display supplies controller, native layer owner,
  stable output identity and generation ticket. No list index is persisted.
- Hover uses twelve box edges from already computed instance bounds. It does
  not skin an additional sampled mesh or highlight all layers.
- The shared render helper does not participate in HitTest. A second private,
  transient helper forwards picking to the committed render publication but
  has no render items of its own. Max therefore has no shared geometry to tint
  yellow. Global viewport preferences remain untouched. DoOwnSelectHilite alone
  was insufficient in Nitrous and was rejected by the run-01 visual check.
- Selection redirection captures a recent viewport hit. Entry is deferred
  until release, then rechecks selection and the visible generation.
- An existing Edit uses its committed feedback. A new empty Edit binds retained
  final views and palettes, without applying pending Manual settings. Until its
  first authored edit it is excluded from placement dependency keys.
- Native staged data and COW selection preserve allocation failure behavior;
  adding the modifier is one Undo command. Geometry, pose and source ownership
  remain with their existing pipelines. No preparation or contact work on hover.
- Hover storage is bounded to 24 points; existing pick inventory, source face
  block caches and admission remain unchanged. Exact visible triangle picking
  still has a cost; the box is only the visual cue.
- Both private helpers retire together on save, scene replacement, deletion and
  reset. The pair cleanup uses explicit local arrays: a nested collection inside
  the delete call triggered Max's free-thunk local-member error in run 02.

## Required evidence

1. Max 2027: plain clicks across layers, new/existing Edit, stable selection and
   Move/Rotate/Scale; Manual pending counts preserved on entry.
2. Whole-object yellow highlight absent; one cheap box. Foreground occlusion,
   hidden previews, icon selection, multi-selection and stale hits remain safe.
3. Selection/navigation leave placement and display upload counters unchanged;
   measure repeated picking separately from presentation cost.
4. Generated source, native regression suite, exact loaded payload identity.
5. Matching SDK builds and integrity-checked MZPs for 2024/2026/2027, one EXE.
   Older-host compilation is not runtime qualification.

Preserve the 0.87.5.6 artistic interaction baseline and all 0.87.6.3 review
repairs. This document is an implementation plan, not a passing test receipt.
