# Source rectangles, Painting controls and brush radius — 0.78.3

10 October 2026. Development patch on `codex/workflow-0.75`, starting from `cbd25ff`. Scatter/package 0.78.3, schema 55, calculation model `CyrusUnified1`; Analyzer 0.14 and MCP 0.73.0 are unchanged.

## Findings and changes

### Source rectangles

The 0.78.2 Max 2026 control run reproduced the reported selection exception verbatim: `Unknown property: "uiPaintSetID" in Cyrus Scatter`. The generated rectangle panel still wrote retired paint-set selection state. A second obsolete `selectedPaintSet` call remained in global-container context resolution. Both are removed; a rectangle resolves its linked layer directly.

The same control run registered a model on the first scan immediately after rectangle creation. Rectangles now have a saved **Enable collection** checkbox, off by default. It appears below the rectangle list in Models and at the top of the rectangle's Modify panel. Position and resize first, then enable collection. Disabled rows show `[off]`, and viewport labels report collection off.

Inactive rectangles contribute no membership frames. When all rectangles in a pool are inactive, reconciliation skips scene geometry enumeration and candidate membership tests. Disabled rectangles cannot carry their previously assigned source models. Their source identities, settings and parked rows are preserved. Collection changes mark linked owners dirty; Manual retains its completed population until Update, while Live publishes the change automatically. Disabling a shared rectangle keeps every linked layer available as an editing context.

The new field defaults off in older saved rectangles that do not contain it, too. Enable those rectangles explicitly after opening with this build. Class IDs, controller schema, source settings and vector payload are unchanged.

### Painting layout

Area density, Paint feedback mode/color and help now appear directly in Painting alongside area selection, brush controls and feather curves. Painting has no Advanced disclosure. All area-specific rows, including feedback controls, hide when Use Paint Areas is off. Generated Modify, rectangle and floating views share the same handlers. The semantic inventory/catalog now contains 240 controls, including the two collection checkboxes.

### Cursor radius

The authored region already used the requested radius. The cursor did not: the old code passed that radius directly into Painter's min/max Size. Autodesk's SDK header describes those Size methods as radius, but the supplied implementation halves Size in cursor display and in `AppendTempList`.

The installed Max 2026 control run confirmed the implementation: authored radius **100**, Painter min/max Size **100/100**, actual stored Painter radius **50**. The old test only checked that the configured Size matched the UI; it did not measure Painter's resulting radius.

Start and in-session radius changes now pass **2 × authored radius** to Painter. Vector geometry remains unchanged. Stop restores the previous Painter settings. A radius of **100 mm** means **200 mm diameter**; the cursor now represents that footprint.

Primary implementation evidence is in the installed 2026/2027 SDKs: `samples/PainterInterface/painterInterface.cpp`, cursor display (`GetSizeAndStr`, then `radius *= 0.5f`) and `AppendTempList`; compare `include/IPainterInterface.h` Size comments. No vendor binary reverse engineering or web inference was needed for this correction.

## Qualification

Testing uses owned disposable Max profiles and scenes through MAXScript and a test-only SDK probe. No computer use, OS pointer injection or artist-profile installation. The private probe is excluded from installers. Exact artifacts and identities are recorded in `EVIDENCE.json` and the package receipts.

| Check | Result |
| --- | --- |
| Generated UI / catalog | 240 semantic controls; generator and layout checks pass |
| Python | 143 tests pass |
| Native builds | 15 suites pass for each Max SDK |
| Rectangle workflow | 28 assertions pass in each Max version |
| Painter radius / vector footprint | 10 assertions pass in each Max version |
| UI bounds | 36 contexts, 2,170 native rectangles, zero clipping or overlap in each version |
| Playback | 838 assertions pass per host, including all retained-owner checks |
| Drawing responsiveness | Seven assertions pass per host; unchanged status skips layout |

The eight-fixture host suite passes in each version: button/callback workflow, native layout diagnostics, layout modes, vector acceptance, extended behavior, passive inspection, performance/cache checks and playback. Button/session checks pass 26 assertions per host; vector checks pass 447 in 2026 and 463 in 2027 (per-candidate checks vary with fresh receiver identities); passive inspection passes six per host. Drawing responsiveness passes seven assertions per host, including 1,000 SDK callbacks, mid-gesture borders without timer delivery, final flush, no redundant preparation, preserved Manual/candidate caches and cancellation.

Playback was strengthened during qualification: the original fixture could silently omit 24 retained-buffer checks when desktop held-input state prevented one private display owner from being created. The wrapper now isolates that state and asserts owner existence in all three modes before comparing counters. The package gate requires all 838 assertions (the previous 835 plus three explicit owner checks).

The radius fixture measures the installed Painter's stored stroke radius through `ClearStroke`, `AddToStroke` and `GetStrokeRadius`. At radius 100 it also queries the actual vector filter: points at distance 99 are inside and points at 101 are outside in four directions. Identity, uniform `[2,2,2]`, and nonuniform `[2,3,1]` receiver scales pass. Units are converted through Max's unit system: 100 mm is 3.93701 system units in the 2026 private profile and 10 units in the 2027 profile; Painter matches both.

The focused rectangle workload uses 64 source boxes. Inactive creation/positioning records zero geometry scans and zero membership tests; enabling admits all 64 in one scan and produces the requested 100 plants. These counters establish that inactive collection avoids the scene scan; they are not a benchmark of thousands of heavy meshes.

Physical mouse/tablet interaction, arbitrary DPI/fonts, sustained heavy scenes and full renderer certification remain separate acceptance gates. Numeric Painter-radius verification and native control bounds do not replace that walkthrough. The prior physical container Move/Undo observation remains in [B05](../BACKLOG.md).

## Delivery and reproduction

Use the complete package for the installed Max year and restart Max. Do not replace only the script while old native modules remain loaded. Installers are local ignored files, not included in Git.

- [Max 2026 Scatter installer](../../dist/Container_and_Radius_0.78.3_2026-10-10/Max2026/CyrusScatter-0.78.3-Max2026.mzp)
- [Max 2027 Scatter installer](../../dist/Container_and_Radius_0.78.3_2026-10-10/Max2027/CyrusScatter-0.78.3-Max2027.mzp)
- [2026 package receipt](PACKAGE-2026.json) · [2027 package receipt](PACKAGE-2027.json)

Follow the [private-host instructions](../../tools/vector_brush_078/README.md). Final hosts are `containers-host2026-03` and `containers-host2027-04`, using native builds `containers-max2026-02` and `containers-max2027-02`. The last script change preserves all linked editing contexts for inactive global rectangles; native code did not change after those builds. Packaging verifies all compiled-source hashes and the final loaded script separately.

Reproduce the focused checks with [containers.ms](../../tools/vector_brush_078/containers.ms) and [radius.ms](../../tools/vector_brush_078/radius.ms), followed by the eight-fixture regression suite and the drawing responsiveness fixture. Baseline evidence comes from `containers-baseline2026` (0.78.2 script) and `containers-host2026-01` (native module before the radius correction). Intermediate runs are retained as diagnostic evidence, not final qualification. One 2027 private launch (`containers-host2027-03`) exited before the Cyrus bootstrap; the fresh `-04` profile completed startup. Its pre-bootstrap exit is not recorded as a product-test pass.

Test-development corrections: source weights are bounded to 0–1, so the fixture uses 0.25; `intersectRayEx` witnesses use an Editable Mesh receiver; save/open selection checks allow Max's posted mount events to complete. These corrected fixture issues did not require weakening product assertions.

Drawing-stage medians and p95 are preserved in `EVIDENCE.json`. The expanded panel still skips layout for unchanged status. These are synchronous CPU measurements under ordinary desktop activity, not a new controlled speedup comparison or presented FPS.
