# Cyrus Scatter 0.87.6.2

This delivery adds geometry selection and shared controls while retaining the
separate Cyrus Scatter Edit modifier and the 0.87.6.1 contact implementation.

- Hover/click a visible mesh to select its Scatter controller. The yellow mesh
  overlay identifies one instance; Max's node-name feedback uses the controller name.
- In **Cyrus Scatter Edit > Instances**, click the displayed mesh to select the
  stable instance identity, then move, rotate, scale or delete with the existing tools.
- Select multiple controllers for shared viewport controls, or open
  **Viewport & render > Multiple Scatters...**. Set display mode, moving/idle
  triangle budgets, preview visibility, Enable/Disable, or explicitly Update
  pending Manual setups. Each action changes only its chosen property.

[Artist instructions](ARTIST_GUIDE.md) explain scopes, mixed values and drawing limits.
[Implementation](IMPLEMENTATION.md) records ownership, memory, Undo and cache boundaries.
[Qualification](QUALIFICATION.json) records exact package hashes and executed checks.

## Install

The delivery folder is
`dist/CyrusScatter-0.87.6.2-20261029/`.

- [Combined EXE — Max 2024, 2026 and 2027](../../../dist/CyrusScatter-0.87.6.2-20261029/CyrusScatter-0.87.6.2-Setup.exe)
- MZPs: [2024](../../../dist/CyrusScatter-0.87.6.2-20261029/CyrusScatter-0.87.6.2-Max2024.mzp),
  [2026](../../../dist/CyrusScatter-0.87.6.2-20261029/CyrusScatter-0.87.6.2-Max2026.mzp),
  [2027](../../../dist/CyrusScatter-0.87.6.2-20261029/CyrusScatter-0.87.6.2-Max2027.mzp).

Close the selected Max versions before running the EXE. Alternatively, use
**Scripting > Run Script** with the matching MZP, then restart Max. Existing library
content and the independently installed Surface Analyzer remain separate.

## Executed evidence

The final run is `build/viewport-selection-08762-20261029-02/`.
The private Max 2027 host loads the exact extracted final 2027 package. The private
SDK qualification probes are excluded from every installer.

| Check | Result and scope |
| --- | --- |
| Generated UI | Passed; 379 semantic controls; 32 fixture delimiter checks. Final script also loads in Max 2027. |
| Native regression suites | 62/62 passed in the Max 2027 SDK build. |
| Shared controls | Two controllers; automatic window, display switching, Enable/Disable, Show/Hide, explicit Update and one-action Undo pass. Pending Manual placements stay pending when changing a preview budget. |
| Object selection | Retained helper redirects to its real controller. Actual SDK PickNode selects displayed geometry and respects a foreground ordinary box. |
| Instance selection | Actual SubObHitTest/SelectSubComponent selects the expected stable instance away from its pivot; that identity survives movement. Deleted geometry stops being a target after the required Manual Update. |
| Prepared geometry | 133 posed-grass picks match an independent two-sided CPU-baked triangle reference within 0.010743 world units. The fixture contains 65 bent plants, 161 pruned guides and hidden root groups. Querying preserves publication epochs and stream counters. |
| Garden hover | 18,229 placements across six controllers, including one empty controller; 77 rays, 15 hits. No publication-epoch or upload-counter change. |
| Camera navigation | 24 scripted camera redraws with a geometry highlight preserve all placement epochs and all nine retained stream counters. |
| Packages | Separate matching SDK builds for 2024, 2026 and 2027; archive payload hashes and host guards pass. EXE embeds those exact three verified MZPs. |

Garden query median is **0.056 ms** across all rays, **0.284 ms** among hits;
maximum **20.365 ms** includes cold cache construction. Camera redraw submission
median is **32.343 ms** in this fixture. These are bounded CPU observations, not
physical mouse latency or GPU-presented FPS. The earlier implementation in run 01
was measured under different cache/build activity, so it is not a controlled
speedup claim. No new solve or upload was caused by the measured selection/navigation.

The prepared-grass check uses a private brute-force SDK triangle reference.
Max's `intersectRay` was inadequate as a two-sided thin-blade reference; earlier
driver attempts also corrected the bounded inspection size and excluded untouched
instances from the posed-only Bake comparison. Corrected driver attempts remain
in the owned run for traceability. No product solver change was needed.

## Limits and preservation

Only **Max 2027** was launched and tested. Max 2024/2026 support is matching SDK
build/package verification and awaits artist runtime testing. Physical mouse
hover/tooltip dwell, arbitrary renderer graphs and broad soak testing were not run.

Picking follows displayed geometry and its draw limits. Point Cloud/Centers retain
the icon/handle workflow. Rectangle selection retains the existing marker behavior.
Complex highlights sample at most 1,024 faces; this sampling does not limit hit
accuracy. Alpha picking uses a nearest atlas threshold rather than pixel-identical
GPU filtering. Failed pick-cache admission leaves the retained display intact.

No scene/recipe schema or Edit-storage change. Viewport selection capability 1
requires the matching script/native pair. The user explicitly selected 0.87.6.2;
independent products keep their versions. The endorsed 0.87.5.6 Bend/Trim reference
and the measured 0.87.6.1 follow-up remain separate historical evidence.

Artist scenes, installed profiles and unrelated working-tree changes are preserved.
This delivery does not install the plugin, push Git, rebuild the website or refresh
indexed knowledge. Next acceptance is the artist's ordinary hover/click and shared
controls workflow, including the older hosts if needed.
