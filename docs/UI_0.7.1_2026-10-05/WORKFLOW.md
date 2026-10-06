# Cyrus Scatter 0.7.1: layer editor

Development work, 5 October 2026. Baseline: `addccb492a88292529594de81c287cc26e5ffe98`. Product 0.7.1; serialization remains 53. Publication 1.0 remains a separate milestone.

## Artist workflow

The Modify panel owns setup enable, receiving surfaces, Manual/Live and Update, viewport/render settings, global source rectangles and a compact ordered Layer Manager. Select a layer and press **Edit layer**, or double-click it. One resizable modeless editor follows explicit layer selections, not arbitrary scene selection. This allows selecting source models and painting without losing the edited owner.

The editor always names its Scatter setup, layer and paint set. Its footer reports Manual/Live, pending/cached/error status and cached placed/shown counts. **Update setup** explicitly calculates all enabled layers. **Refresh fields** only reads settings and existing results.

| Topic | Left column | Right column | Ownership |
| --- | --- | --- | --- |
| Assets | Source list, add/pick/remove, share, transforms, radius, advanced point/empty/color tools | Source rectangles; collapsed paint-set management | Paint set; container pool can inherit layer/global |
| Population | Count/density, seed, density texture; bounded target/retry limits | Include/exclude Area and falloff | Shared layer defaults |
| Paint | Coverage enable, Brush controls, editable stroke history | Background mode and explicit earlier-set references | Paint set, on shared receiver/Area |
| Transform | Random rotation, scale and translation | Source assignment, clusters and preserved legacy line/analyzer modes | Layer |
| Spacing | Explicit scope/pair rule; collapsed CS Edit instance radii | Inherited self-spacing; final layer cleanup; legacy rules when applicable | Scope named by each section |
| Statistics | Cached counts, errors and rejection reasons for every set | Short workflow and ownership help | Read-only |

Common edits are visible first. Less frequent paint-set administration and instance-radius operations start collapsed. The long combined Procedural rollout has been split into population limits, background fill, scope rules and instance-radius actions. No Apply button is needed for spacing; background mode and references retain one explicit atomic Apply action. Destructive source removal is distinct from reversible source parking.

## Implementation contracts

- Reuse Max's unit-aware controls and existing feature handlers. No PySide runtime or second data model is introduced.
- Build one set of editor sections, lazily on first topic visit. Retain visited sections when changing topics, resizing or binding another layer. No ten hidden layer-page stacks.
- Browsing, resizing, binding and statistics must not generate placements, publish a new epoch, change input keys or upload unchanged preview buffers.
- Cancel active Brush/pick mode before changing the bound owner or closing. Scene selection alone does not retarget.
- Refresh fields after Undo/Redo. Reset/file-open closes the editor. Deletion invalidates the bound owner safely.
- Existing policy 1/2 controls remain available. Procedural policy hides obsolete pair/Relax controls, while preserving their settings. It does not silently convert scenes.
- Product version, scene serialization, MCP schema versions and native class IDs are distinct. Licensing behavior is unchanged.
- Tooltips describe the action and its scope. Page introductions explain workflow and disabled/legacy limitations.

## Qualification loop

- [x] Map options and ownership; implement compact host and reusable editor.
- [x] Verify compilation and every page in isolated Max 2027.
- [x] Exercise two Scatter roots, ten populations, picking/selection, layer/set switching, Undo/Redo, delete/reset/load/close/reopen.
- [x] Verify automatic spacing, source rectangles, Manual/Live, Brush, Area, transforms, cleanup and output through retained feature tests.
- [x] Use real pointer tests for scrolling, resize, tooltips and navigation; inspect screenshots for clipping and wasted space.
- [x] Check retained preview/generation counters and record opening/switch timings without treating redraw timings as presented FPS.
- [x] Run native tests for both SDKs, MCP regression and generator checks. Freeze source/binary hashes and deliver an isolated preview.

The [results](RESULTS.md) distinguish source checks, event invocation, real pointer evidence and remaining limitations. The final frozen candidate is `build/ui-071/final01`; its receipts, rather than this checklist, establish the bounded pass.
