# Cyrus UI architecture investigation

Date: 2026-10-02. Investigation and private prototypes; **no production UI replacement or new installer**.

**Later focused fix:** [main-rollout repaint investigation](MAIN_ROLLOUT_REPAINT.md) reproduced the user's narrow-until-hover defect, corrected three behavior lines in UI **2026-10-02.5**, validated 76 UI assertions and 30 reopen cycles, and staged that script for the next Max restart. The prototype results below retain their original revision-4 scope; the full reusable-editor/Qt replacement remains unimplemented.

**Remaining flash:** the [2026-10-03 layer/settings trace](LAYER_RESIZE_TRACE_2026-10-03.md) confirms a 240 → 162 → 240 native-width reset during main-rollout height changes, including with the polling timer disabled. Idle polling caused no resize/remount writes in that fixture. The remaining visual correction is pending.

## Decision

Prefer **one reusable editor for the selected layer, with Qt managing layout**, subject to a small command-panel integration experiment. Keep the existing scatter objects, parameter data, calculation code and retained viewport display as the model. Change how their settings are presented.

There are two distinct issues: constructing many controls on a layer's first expansion, and resizing nested MAXScript rollouts during expansion. Moving identical controls into a flat container did not eliminate construction cost. A reusable editor avoids constructing another six settings panels for every layer visited. Qt provides the supported layout machinery needed to replace our manual width/height repair cycle.

This is an architectural recommendation, not a claim that the complete Qt UI is implemented or flicker-free. The working prototypes are separate from the artist's plugin.

## What was actually tested

A new Max **2027.1**, build **29.1.0.11426**, process **32592**, loaded private copies of the 0.64 native binaries and a trace-only derivative of source UI **2026-10-02.4**. The original `SaveSelect 2.max` session was left separate. The synthetic fixture contains ten Cyrus layers. The installed artist profile still reports **2026-10-02.2**; it was not updated in this investigation.

Experiments ran sequentially on the same desktop, with ordinary background activity uncontrolled. Timings measure synchronous calls, not completed painted frames or end-to-end mouse latency. They are diagnostic observations, not hardware-independent performance guarantees.

| Experiment | Result | Meaning and limitation |
|---|---|---|
| Current nested Cyrus UI, first visit to each of 10 layers | Median **831.8 ms**, range **648.4–1280.8 ms** | Six settings sections are constructed, including controls in collapsed sections. |
| Same layers, already constructed, reopened | Median **20.3 ms** | Existing controls are already reused while that layer UI remains mounted. |
| Same production factories in a plain rollout floater | Median construction **822.6 ms**, 5 trials | Flattening the container does not remove widget construction work. |
| Same factories in a nested floater, custom resizing omitted | Median construction **808.3 ms**, 5 trials | Nesting alone did not account for the large first-open cost in this comparison. |
| Source-derived controls as ordinary command-panel rollouts | Median construction **619.5 ms**, 5 trials; expansion **4.3 ms** median | No equivalent Cyrus nested host; still substantial construction work. Width reset/clipping remained in this test. |
| One reusable set of all six Cyrus sections, 30 layer switches | Median **49.5 ms**, p95 **116.3 ms**, maximum **119.0 ms** | Widgets remained mounted. Values were rebound across ten layers with differing settings and all four diversity modes. Initial construction still cost **648.8 ms**. |
| One-section Python/Qt Collision–Relax pilot | Median binding **3.0 ms**, 30 switches | Six bound fields only; not comparable to the complete 160-control editor. One observed construction cost was **236.4 ms**, excluding Python/Qt import. |
| Autodesk QtObjectDemo SDK sample | Loaded successfully; command-panel selection median **50.4 ms**, 5 trials | Reference implementation with different controls and data. **Not a Cyrus speedup estimate.** |

The reusable editor's 50 ms is **not faster than the current UI's 20 ms warm reopen**. Its benefit is avoiding another approximately 0.8-second construction step when visiting a previously unopened layer. These are different operations, and their ratio must not be advertised as an overall UI speedup.

All six sections together contain **160 declared MAXScript controls**: Source 23, Generation 11, Collision 9, Area 31, Diversity 43, Randomize 43. The current ten-layer architecture can retain ten such sets after all layers have been opened. Global controls and subrollout containers are additional. This count is not a measured memory or native-window count.

The floater comparison uses the same factory definitions, owner and control sizing inputs, with alternating test order. The host-allocated rollout widths differ: the flat host reported 257 pixels and the nested host 211. The command-panel comparison is also a different host. Treat these as architectural probes, not an exact pixel-matched benchmark.

## The flash: verified mechanism versus inference

The private trace recorded this sequence when a warmed Grass layer was collapsed through Computer Use:

1. The outer subrollout height changed from **460 to 322**.
2. The main rollout height changed from **488 to 350**.
3. Its native window was then **162 pixels wide**, positioned 43 pixels into its parent.
4. `fitWidth()` immediately repositioned it and restored the intended **240-pixel** width.

The native width reset and corrective write are verified. A width change of that kind is a credible explanation for the visible sideways flash. We did not capture high-speed video proving the duration or sole cause of every user-reported flash. Scrollbar appearance may add another effect; it is not established as the only cause.

The source-derived flat command-panel fixture also reported an immediate width change from 277 to 162 on section expansion, and the resulting controls appeared narrow/clipped. Simply deleting our width repair would therefore risk leaving an incorrectly sized UI. The delayed settled width was not sampled in that fixture.

At the tested settled width, the existing one-shot diagnostic reported no root-control remount and unchanged preview build/dirty state. An idle trace read was empty. One width rebuild occurred during initial setup/settling. Thus, the 300 ms timer should not be blamed for every expansion without evidence: the synchronous height/width sequence exists independently of a repeated width rebuild.

See [interaction trace](evidence/interaction-layout-trace.json), [baseline trace](evidence/baseline-layout-trace.json), [mounted diagnostic](evidence/diagnose-selected.txt) and [native flat comparison](evidence/native-flat-comparison.json).

## Prototype correctness checks

- The shared editor completed **30 switches and 240 assertions** covering owner identity, count, collision toggle/radius, relax iterations, diversity mode, random scale and stable rollout handles. Preview build counters and dirty flags stayed unchanged during browsing.
- A real keyboard edit changed Grass count **100 → 137**. Leaves remained **200**. Switching away and back preserved the edit with the same rollout handles.
- The Qt pilot kept the same field widgets across 30 bindings, loaded the intended owner's values, and left preview build/dirty state unchanged while browsing.
- A Qt field signal changed only the intended owner. Max Undo restored the stored radius. **The pilot explicitly refreshed the UI after Undo**; automatic external Undo notification is not implemented.
- Qt collapse/expand reused widgets. Form fields fit at dialog widths **300, 350 and 480**, using layout management rather than hand-coded positions or a width polling timer.
- Computer Use inspected the real controls, the native Qt sample and both prototypes. Still screenshots and geometry assertions do not establish absence of millisecond flicker.

The synthetic fixture covers only a subset of real scene states. It does not yet cover large source lists, populated analyzer/path data, all texture/map controls, every keyboard interaction or deletion while a pick operation is active.

## What Autodesk's implementations teach us

The local Max 2027 SDK includes inspectable modifier samples. They are SDK sample source under its license; the entire SDK should not be called open source.

- `samples/modifiers/bend.cpp`: `P_AUTO_CONSTRUCT + P_AUTO_UI` at line 318, parameter-map lifecycle delegation at lines 392/405, and targeted invalidation using `LastNotifyParamID()` at line 468.
- `samples/modifiers/shell/SolidifyPW.cpp`: automatic parameter UI at line 313 and lifecycle delegation at lines 739/747.
- `howto/ui/qtObjectDemo/QtObjectDemo.cpp`: `CreateQtWidget`, `P_AUTO_UI_QT` and two maps. `QtDemoObjectRollupWidget.cpp` constructs the Qt Designer form with `setupUi()`; layouts size the controls. The sample is a **geometry object, not a modifier**.

The inspected sources show standard ownership, parameter binding and layout mechanisms. They do not establish the implementation of the user's Boolean modifier. No private Autodesk implementation was inferred from its screenshot.

Autodesk recommends Qt for new SDK plugin UIs and describes automatic parameter/widget binding. This does not automatically bind our current scripted layer objects to a new native Qt form. That adapter still needs design and qualification. [Parameter Blocks](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/3ds_max_sdk_-_the_learning_path/lesson_6_parameter_blocks.html)

The SDK has a supported `AddRollupPage(QWidget&)` / `DeleteRollupPage(QWidget&)` path. **Max takes ownership of the widget and may delete it**. A production host must follow that lifecycle; it cannot retain a dangling widget pointer after panel teardown. The local declaration is in `include/maxapi.h`, lines 4835–4842 and 4896. Availability of this API is verified; its integration with Cyrus's current scripted controller is **not yet tested**. [SDK command-panel API](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_interface_ex.html)

Python/PySide6 is also an official Max UI route. We used it for the small feasibility pilot, parented to Max, with signals blocked while reading model values. This floating pilot does not demonstrate production command-panel hosting. [Creating Python UIs](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Python/files/MAXDEV_Python_creating_python_uis_html.html), [qtmax helpers](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Python/files/MAXDEV_Python_qtmax_module_html.html)

MAXScript subrollouts and geometry setters have explicit limitations. Changing a subrollout's height does not lay out subsequent siblings; setting a rollout's width is not a general command-panel layout mechanism. These facts help explain why our accumulated manual layout work is fragile. [SubRollout](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-CDE5B06D-4BB4-4DEA-96C1-6BAB98709F09.html), [Rollout properties](https://help.autodesk.com/cloudhelp/2025/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.html)

## Recommended design rules

1. **One editor follows the selected layer.** Build its controls once for the editor session and rebind their values. The layer list owns selection; the scatter object owns scene data. This changes the interaction from several simultaneously expanded editors, so artist review of that workflow is still required before shipping it.
2. **Qt owns layout.** Use normal form/box/grid layouts, Max styling and a single scroll owner. Expansion changes visibility; resizing should not destroy and reconstruct the inspector. Avoid another framework of deferred headers, custom width repair or nested height accounting.
3. **Keep the current model authoritative.** Use a small explicit adapter for reading values and applying existing operations. Do not duplicate the scatter algorithms or change scene class IDs, saved fields or renderer paths for a UI redesign.
4. **Separate reading from editing.** Block signals during refresh, validate the active owner before writes, group user edits into appropriate Undo operations, and refresh from model notifications. Reading statistics or opening a section must not generate scatter output.
5. **Honor Max lifecycle and units.** Handle controller changes, Undo/Redo, deletion, reset, load, and panel destruction through explicit ownership. Production spinners must support Max's units and interaction conventions. The Qt pilot currently labels raw scene units and is not a finished spinner implementation.

Qt is recommended for layout and maintainability. This investigation does **not** show that changing language/toolkit alone guarantees a faster complete editor. Reuse is the demonstrated architectural improvement.

## Smallest next implementation experiment

Build only a **native Qt command-panel host for the layer selector and Collision / Relax section**, connected to the existing Cyrus layer objects. Use the public SDK rollup APIs or the appropriate native plugin lifecycle; first prove mounting and teardown beside the current scripted controller without migrating scene data. Avoid implementing the other five sections until this works.

Acceptance gates, proposed rather than passed:

- Max 2026 and 2027: repeatedly select/deselect two controllers, switch layers, remove a layer, Undo/Redo, reset and reload. No stale owner, dangling widget or duplicated callback.
- Refresh values after external edits and Undo, including user units. A focused spinner, keyboard accelerator or pick operation must not edit the wrong layer.
- Collapse/expand and command-panel resizing at 100%, 150% and 200% display scaling. Stable layout, preserved focus and scroll, no widget remount just for width changes. Capture a short visual recording for the original flash report.
- The same counts/transforms, cached preview build counters and native upload/generation counters before and after passive UI browsing. Editing remains the only intentional cause of data invalidation.
- Record first construction, warm opening, layer binding, paint completion and responsiveness separately. Suggested budget for a settled layer switch: p95 below 100 ms on the supported test machines; no guarantee is inferred from this desktop.

If this host passes, migrate sections incrementally, starting with Generation and Source. Remove the superseded MAXScript layout/generator code as each section becomes complete. If supported command-panel hosting would require disproportionate scene/plugin restructuring, evaluate an officially supported dockable Qt editor as a separate workflow proposal rather than embedding it through undocumented window surgery.

The existing renderer and GPU optimizations need no redesign for this work. Licensing and MCP remain outside this UI experiment.

## Evidence and reproduction boundary

- [Measurement summary](evidence/summary.json)
- [File identities and checksums](evidence/manifest.json)
- [Current-UI timings](evidence/ui-open-timing.json)
- [Same-factory host comparison](evidence/host-comparison.json)
- [Shared editor timings](evidence/shared-editor-timing.json) and [integrity](evidence/shared-editor-integrity.json)
- [Real input edit](evidence/shared-editor-real-edit.json)
- [Qt pilot](evidence/qt-pilot.json) and [layout checks](evidence/qt-pilot-layout.json)
- [Autodesk sample loaded-module receipt](evidence/qt-reference.json)
- [Local reproduction notes](REPRODUCTION.md)

The original generated product script retains SHA-256 `89c6f102012c81d5fb46e7ef24e1f087af2b6a6a3f4d06d548a3d8dc0974eadc`. The artist scene retains `42d3bd0835aba91ef7c29925669fda61e9bc7dda3479287b9e1775cc09696e6c`. Product source and installed files were not changed by this investigation. The private instrumented script has a separate identity in the manifest.
