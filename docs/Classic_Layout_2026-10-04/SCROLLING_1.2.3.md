# Cyrus Scatter 1.2.3 — native panel scrolling

4 October 2026. This patch fixes wheel and background-drag navigation in the nested classic layout. It preserves the 1.2 planting model and persisted class version 51.

## Artist behavior

- Wheel over a section header or empty panel background to scroll the whole stack.
- Hold the left mouse button on blank grey space and drag up/down, using Max's native panel scrolling.
- Lists, dropdowns, spinners and buttons retain their own input behavior. Begin a navigation drag outside them.
- The outer scrollbar remains available. A matching 1.2.3 installer and Max restart are required because this patch updates a native DLL.

Use the [artist guide](ARTIST_GUIDE.md). The installers are generated locally under `dist/classic-layout-1.2.3`; choose the matching Max year.

## Cause and implementation

The 1.2.2 stack contains native subrollouts sized to their complete contents, with internal scrollbars disabled. Real wheel and background-drag input was consumed inside those containers without moving the outer command panel. The outer scrollbar continued to work. This was reproduced in a disposable Max 2027 session.

[`rollout_scroll.cpp`](../../AminScatter/src/rollout_scroll.cpp) adds a small adapter to the existing `AminScatter.dlx`. It subclasses only descendant rollout dialogs and their rollup containers/headers beneath Cyrus's main rollout. Wheel messages go to Max's command-panel rollup. Background mouse messages are translated into the root rollout's coordinates and passed to the SDK's `IRollupWindow::DlgMouseMessage`. Max owns capture, movement and clamping. Passing a nested dialog directly to that method did not work in the diagnostic prototype; passing the root dialog with translated coordinates did.

Authoritative MAXScript templates bind the adapter after structural mounting and detach it on panel close. Destroyed child windows also release their binding. Existing bindings are reused. Editable native controls are not subclassed; header clicks and dragging keep their existing handling. There is no global mouse hook, scroll timer, new Python runtime dependency, or scatter calculation in the adapter. The only added native link dependency is Windows `comctl32`.

Changed product sources are `AminScatter/CMakeLists.txt`, `AminScatter/src/rollout_scroll.cpp`, the `layers-first.cjs` version, `layers-first-host.ms`, `layers-first-panel.ms`, and regenerated `AminScatterObject.ms`. Build/package instructions and documentation were updated separately. Placement, Brush evaluation, retained Mesh/Point Cloud/Proxy display, threading, render output and MCP logic were not edited by this patch. This is a navigation improvement; it makes no new FPS claim.

## Qualification

The release test session loaded the actual 1.2.3 script and four native binaries from a private profile. The native binaries and generated script are checked against the packaged bytes in [the manifest](evidence/scrolling-1.2.3/MANIFEST.json). Prototype DLLs were absent from this release session. The artist's running Max and scene were not changed.

| Check | Result |
| --- | --- |
| Actual wheel over Plant assets background | Outer scroll 0 → 90 |
| Actual left drag upward on blank background | 90 → 263 |
| Actual left drag downward | 263 → 98 |
| Actual wheel over Plant assets header | 98 → 188 |
| Actual header click | Plant assets collapsed normally |
| Add/remove layer, switch objects, restore expanded/collapsed settings | Passed ownership and restoration assertions |
| Actual drag after that panel lifecycle | 0 → 239 |
| All root/layer/feature expansion checks | 52 toggles; 618 control-bound checks passed |
| Max 2027 native build and suites | 12/12 passed |
| Max 2026 native build and suites | 12/12 passed |

For each recorded gesture, authoring parameters, placement generation, Brush evaluation counters, retained control handles, inner scroll positions and display-upload counters stayed unchanged. The gesture records are under [separate patch evidence](evidence/scrolling-1.2.3/). Max 2027.1 was tested at the current desktop configuration; Max 2026 runtime, other DPI configurations and other Max versions remain untested. This narrow patch did not rerun renderer or MCP campaigns.

## Reproduction

Build both SDK targets with `tools/v1/build.py`. Launch a disposable `classic-layout-scroll-*` profile with the frozen `dist/layers-first-1.2.0/Cyrus_Scatter_1.2_Layers_Demo.max`, then submit `tools/v1/scrolling_prepare.ms`. That fixture refuses ordinary artist sessions, saves its own synthetic scene copy, opens the source controls, and arms navigation assertions.

Use real input over blank panel space or a header, then submit `CSScrollCheck "case-name" direction:1` for movement toward later controls, or `direction:-1` for movement back toward the top. Each successful check rearms the baseline. Use direction 0 for a header-click check and also assert its expected open state. The fixture does not synthesize mouse input.

The existing `classic_layout_acceptance.ms` was rerun with only its expected UI revision changed from 1.2.2 to 1.2.3; the exact executed copy is retained as `layout-check.ms` in the patch evidence. `classic_manager_acceptance.ms` ran unchanged. Its request exceeded the initial client wait but subsequently returned SUCCESS and wrote its passing result before further work. A final real drag checked routing after recreation. Historical 1.2.2 evidence is preserved.

## Native API references

- Autodesk documents empty-area panel dragging in [Special Controls](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-Basics/files/3ds_max_interface_overview/GUID-FD2F49B2-B86F-445B-AE4B-03F020671485.html).
- The SDK documents the background-message mechanism on [IRollupWindow](https://help.autodesk.com/cloudhelp/2022/ENU/Max-Developer-Help/cpp_ref/class_i_rollup_window.html). The matching 2026/2027 SDK `custcont.h` and `maxapi.h` declarations were checked locally. `GetCommandPanelRollup()` returns a borrowed interface; it must not be released by this adapter.
- Autodesk's [QmaxRollupContainer reference](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_qmax_rollup_container.html) describes the Qt scroll container behind native rollups. The fix keeps the existing native MAXScript layout rather than replacing it with a new UI framework.
