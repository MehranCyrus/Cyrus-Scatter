# Implementation evidence — 5 October 2026

This is a running qualification record. The original review findings remain in README.md; a later feature change does not inherit an earlier qualification automatically.

## Phase A: procedural correctness and native UI

The five reproduced P1 findings were corrected in the generator/templates and native cleanup budget. The final scroll helper resolves the page's current native parent for each gesture; Max 2027's `IRollupPanel::GetRollupWindowHWND()` returned zero in this Qt host, and the aggregate `IRollupWindow::GetHwnd()` only represented one column. Assuming ancestry from that aggregate prevented nested scrolling in other columns. Read-only ownership checks still use the SDK's registered page.

Fresh SDK 2026/2027 builds passed all 13 native suites. Max 2027 loaded the matching private binary and script. The core, binding/rollback, UI and five new correctness regression fixtures passed again after the fix. Max 2026 is build/test qualified only, not UI qualified. See `evidence/phase-a-identity.json` for the exact pair and receipt names.

Real pointer input in the private Max 2027 window verified native widths of three, one, two, then three columns; nested wheel scrolling and background dragging in the third column; and typing a spacing factor of 2.3 in Manual followed by 2.7 in Live. Manual stayed at epoch 1, Undo/Redo restored the field, and Live advanced epoch 3 to 4 without rebuilding candidate preparation. The separate event fixture verifies all four spacing scopes, selected-peer retention, structural Undo, three editor reentries and twenty layout cycles. Pointer testing does not qualify every DPI/layout combination.

The default scalar/source-list Manual regressions retain completed exact output and source mapping until Update, including actual PFlow data. Same-object and nested texture changes invalidate preparation. Reopening a disabled saved owner with radius overrides preserves the override and permits reenabling it. A dense cleanup request fails at the shared 50-million-neighbor work limit while retaining the preceding completed epoch and exact rows.

Navigation used 30 synchronous camera/redraw/message-loop steps per mode on a simple synthetic source, for 20,000 and 100,000 procedural plants. Hidden, Point, retained Mesh and Centers modes all retained their generation, Brush-query and buffer-build/upload counters. Median synchronous steps ranged approximately 13.3–15.1 ms in that private host. These are not presented FPS measurements and say nothing about arbitrarily complex artist geometry. Initial Updates measured 98 ms / 588 ms; process working sets were about 2.15 / 2.21 GB, including Max and earlier disposable tests. Proxy mode was not benchmarked in this cycle.

No artist scene/profile installation, package replacement, commit or push occurred. Current feature work has advanced beyond this checkpoint; final integrated qualification is still required.

## Phase B: source containers

The implementation and bounded Max 2027 qualification are complete for the contract below. Serialization version 53 adds container mode and node references; product version remains 0.7.0 and scene Class IDs are unchanged. Existing scenes default to manual source lists. No matching installer has been published or installed into the artist profile.

The candidate keeps registered rows separate from an active mask, filters after CS Edit but before spacing/cleanup, and preserves candidate/source identities while parking a source. Global, layer and set pools use ordinary Rectangle nodes. A moved/added asset is reconciled from the existing node-event batch; cold load and changed container geometry trigger bounded registration reconciliation. Navigation does not enumerate the scene to find new sources. This does not promise fixed wall-clock time for a million-object scene scan.

Node transform events and geometry/topology events have different dependencies: staging translation does not change candidate recipe keys; mesh/surface changes still invalidate the affected procedural leaf. Existing legacy policies retain their global invalidation path. Autodesk documents these event distinctions and delayed/coalesced delivery in its [Node Event System](https://help.autodesk.com/cloudhelp/2019/ENU/3DSMax-MAXScript/files/GUID-7C91D285-5683-4606-9F7C-B8D3A7CA508B.htm) and [controller-event contract](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/group___controller_event_methods.html).

`Max_Source_Containers_Acceptance.ms` verifies full surviving placement rows and unchanged source settings/IDs on parking/reentry; transformed and parented rectangles; boundary pivots and height; singular-transform rollback; global/layer/set ownership; copy/reopen; CS Edit parking/Undo; guarded new enrollment with existing edits; and unchanged read counters. `Max_Source_Containers_EdgeCases.ms` adds source/container deletion and Undo, overlapping pools, manual-mode round trips, all-parked bounded shortfall/refill, rounded-shape rollback and a membership bit beyond twenty source entries.

`Max_Source_Containers_Events.ms` runs in separate private-host requests, allowing Max's real delayed node-event timer to run between them. It verifies Live parking/reentry without candidate rebuilding and automatic enrollment of a previously unregistered moved node. It does not directly invoke the event handler. The UI fixture exercises create/pick/unlink and inherited-control availability; a real pointer dropdown selection additionally verifies that the native selected event saves/binds the requested pool.

`Max_Source_Containers_Output.ms` verifies published Manual semantics and matching exact/PFlow/Bake source mapping. In the recorded 100-candidate fixture, parking one source left 52 instances in all three consumers. Baked instances share the active model's base object; maximum matrix-row deviation from published transforms was 2.53e-7, below the 1e-5 host-roundoff tolerance. A baked output moved into the rectangle was excluded from registration.

The complete core, binding, UI, review-regression and container fixtures passed together. Retained navigation on 100,000 plants with an active container passed all generation/Brush/buffer and membership-cache counter checks. Both SDKs still pass 13 native suites. MCP now exports the configured pools/references without computing membership; 66 offline tests pass, and a direct private Max Python read preserved all cache/reconciliation counters. Plan schemas 1/2 and policy-3 mutation denial remain unchanged. This recipe inspection is not a new complete procedural layout-import capability.

Remaining product qualifications include Max 2026 runtime, additional DPI/host layouts, complex third-party asset/proxy cases, very large real scene registration cost, and renderer-specific end-to-end coverage. Earlier general caveats about host thread use, million-candidate memory peaks and projected movement cost still apply. Source containers are opt-in and do not remove these limits.

### Fresh paired navigation check

A new private Max 2027 host ran 100,000 placements for 60 camera/redraw/message steps per mode, first without containers, then with a container, then without again. Median milliseconds (Hidden/Point/Mesh/Centers) were 20.53/18.46/19.03/19.73, 21.54/19.77/19.35/18.88, and 19.08/18.58/19.40/18.45. All generation, Brush, membership and buffer rebuild/upload assertions passed. This supports retained behavior and shows modest timing variation; it does not establish zero CPU overhead or presented FPS. Initial Update times (300/588/691 ms) and cumulative process memory vary with run order, so they cannot isolate container construction cost. The raw receipts and `phase-ab-paired-navigation-summary.json` preserve these limits and the matching script hash.

## Phase C: licensing foundation

The [licensing report](../licensing/NATIVE_FOUNDATION_2026-10-05.md) records a bounded native-owned amount/seed recipe, actual CS Edit and shared Brush mutation gates, immutable signed claims, single-use bounded permits, real installation-key/DPAPI activation, actual expiry/reopen/renewal and measured core costs. It includes the failed runs and remaining bypass/continuity/recovery limits. The ordinary product does not enable this partial experiment, and the synthetic issuer is not a customer service. B07/B08 remain open pending the user's answers.

## Final ordinary build and regression

`build/qualification-07-20261005/final01/` froze and built current ordinary source against both SDKs; all 13 native groups per SDK and 66 MCP tests passed. A fresh runtime loaded the correct pair and passed core/binding tests, then the UI fixture refused the launcher's licensing-prefixed private folder. `final02` retained that failed attempt, verified unchanged compiled inputs and reused the binaries in a correctly named private UI profile. This is explicit build reuse, not an invented new build receipt.

The final fresh Max 2027 campaign passed core/binding/UI, all review regressions, source-container acceptance/edge/output cases, real delayed event stages and retained 100k navigation counters. All loaded native module paths/hashes matched. The ordinary process had no development authority or Brush diagnostic primitives. Final script identity is unchanged from phase B; the final native pair includes the ordinary Dab callback-failure correction and default-off licensing gate source.

The final hidden-window campaign had higher synchronous timings than the earlier visible paired run, despite unchanged generation/Brush/buffer counters. Its raw timings are retained. A follow-up put both the earlier phase-A/B pair and final ordinary pair in the foreground with the same 1,176 × 750 viewport, 100,000 plants and 60 synchronous camera/redraw/message steps per mode. The first final-pair attempt had a 56 × 341 viewport and is explicitly excluded from the comparison.

| Mode | Earlier pair median / p95, ms | Final pair median / p95, ms |
| --- | --- | --- |
| Hidden | 28.874 / 159.704 | 22.786 / 47.259 |
| Point | 27.150 / 175.982 | 29.306 / 49.225 |
| Retained Mesh | 29.190 / 161.928 | 24.605 / 44.358 |
| Centers | 30.335 / 163.201 | 25.297 / 39.612 |

All generation, Brush, membership-cache and buffer rebuild/upload checks passed; final loaded module paths/hashes matched the final candidate. These runs do not establish formal performance equivalence: the earlier host was long-lived, the final host was fresh, and run order/system activity differ. Point median was about 8% higher while the other medians and all p95 values were lower. There is no consistent new slowdown in this comparison, but it neither proves zero overhead nor measures presented FPS. Initial Update times of 290 / 697 ms and working sets of 2.77 / 2.66 GB cannot isolate feature cost across these host histories. See [foreground comparison](evidence/final-foreground-navigation.json) and its retained raw trials.
