# Using Cyrus Scatter 0.72

Use the matching [0.72.0 development package](PACKAGE.md) and restart Max. Opening an older scene does not choose a newer plugin: the installed startup script and loaded native modules determine the implementation. Scene serialization remains 53.

1. Select the Scatter controller and open Modify. Global Update, Surface Scatter, Viewport and Render, and Layer Manager remain separate from layer settings.
2. Pick receiving surfaces in Surface Scatter. These are where plants grow. Source rectangles organize the models used as assets; they are separate from receivers.
3. Select a layer in Layer Manager. Its sixteen sections appear below. Adding or selecting a layer uses this integrated view; double-clicking a layer or **Edit layer in window...** opens the optional popup.
4. In Paint sets, choose the set whose assets, Brush and spacing you want to edit. Layer population, Area, transforms and cleanup stay shared across its sets. Check the selected layer/set names before an artist edit.
5. Add models in Models and settings or configure the source rectangles. Moving a registered model outside its container parks it; returning the same scene model preserves its registered identity/settings. Removing a source row explicitly unregisters it. See the [container contract](../Independent_Review_0.7_2026-10-05/SOURCE_CONTAINERS.md).
6. Configure Population, then paint coverage and set spacing. Spacing fields save automatically. In Manual mode, use Update to publish pending placements; Live responds to relevant changes and settles afterward.
7. Use Statistics / help to inspect the cached publication, attempts, shortfall and errors. An accepted target has bounded replacement work; it does not guarantee filling every surface.

## Where settings live

| Native Modify section, in declared order | Job / owner |
| --- | --- |
| Paint sets | Select, name, enable and order siblings within the selected layer |
| Models and settings — paint set | Models, weights, source transforms and footprint radii for the selected set |
| Source rectangles — own / inherited | Global, layer or set asset-container membership; registered/parked source rows |
| Population and seed — layer | Parent layer distribution, count/density and seed |
| Target and retry limits — layer | Parent layer candidate budget or accepted target and bounded attempts |
| Include / exclude areas — layer | Parent layer include/exclude and supported Analyzer-area restrictions |
| Brush coverage and strokes — paint set | Selected set's surface-bound Paint/Erase and saved stroke history |
| Background fill — paint set | Selected set's coverage exclusion / between-plants behavior and earlier sibling references |
| Random transforms — layer | Parent layer rotations, scales, movement and reset controls |
| Source assignment — layer | Parent layer assignment/colour options; policy restrictions still apply |
| Spacing rules — selected scope | Selected set/layer/pair spacing scope, radii factors and gaps |
| Instance radii — CS Edit | Stable-instance Edit radius bindings and overrides |
| Inherited self-spacing / legacy Relax | Supported legacy collision/Relax settings and compatibility gating |
| Final cleanup / legacy pair rules | Parent layer union cleanup and supported older shared-spacing settings |
| Statistics / help | Cached result/shortfall/error evidence for the selected context |
| Workflow and ownership | Supported workflow/output actions; availability follows the active policy |

Collapsed sections bind when opened. Layer switches retain the existing controls and only bind open sections; a valid-to-valid switch does not rearrange all native pages. Max owns column distribution and scrolling. The popup is another view of the same persisted model; opening it creates no second evaluator or recurring refresh timer. The implementation uses Qt-hosted MAXScript legacy rollouts, not a newly written native Qt widget application.

## Recording a local diagnostic report

1. Open **Modify > Diagnostics**, then **Start recording**. Recording is off by default and shared by all Scatter setups in that Max process. It is capped at ten minutes, 4,096 events and 4 MiB.
2. Perform the interaction you want to investigate. **Read recording status** reads retained, eviction, lock-drop, failure and truncation counts on demand; the panel does not poll.
3. Choose **Stop** to retain the history in memory, or **Save report...** to choose a local JSON file and stop/export. Cancelling the file chooser keeps the recording state unchanged. Closing the panel does not stop a recording; the session's own duration cap still applies.
4. Inspect `cyrus.diagnostic-bundle/1.0`: development label, generated-script payload identity, loaded-module file hashes, stopped event pages and each page's health. Module hashes describe files on disk; the private launcher separately verifies actual loaded paths before qualifying a pair.

No MCP installation is needed for these buttons. The Automation panel retains its existing `cyrus.diagnostic-report/1.0` format. Sharing a trace with MCP requires a separate local grant. Neither recording nor export authorizes uploads or ML training. This bounded recorder is useful engineering evidence; a complete causal database/search archive remains future work.

## Current boundaries

All existing 241 semantic controls remain; four diagnostic buttons bring the catalog to 245. This count describes inventory parity, not exhaustive testing of every value/combination. Policy 3 supports its existing Random/Clusters pipeline; Line/Analyzer assignment and incompatible Relax paths retain their prior restrictions. MCP policy-3 access remains read-only. Licensing enforcement and production ML have not been enabled by this UI campaign.

The no-computer-use qualification checks real controls, owners, native page metadata, queues and cache counters through private host APIs. Manual pointer, DPI, multi-monitor, drag-resize and perceived-latency checks remain in [next work](NEXT_WORK.md).
