# 0.72 results and qualification boundaries

6 October 2026. **Development label 0.72; package/native metadata 0.72.0; scene serialization 53.** Final generated script SHA-256: `77dadf0df9faabbba224de5c0602745c98302b1401e7a21368d5af0ba77f855b`. Use the [source inventory](evidence/snapshot.json), [loaded-path manifest](evidence/launch.json), [receipt index](evidence/index.json) and [package manifest](evidence/packages.json) together.

The requested pre-change backup, `75564c4`, was pushed to `codex/floating-layer-editor-0.7.1`. The implementation branch is `codex/integrated-ui-0.72`. This campaign uses CLI/offline tools and explicitly launched, redirected private Max hosts. No computer-use, pointer automation, artist scene opening, normal-profile installation or licensing implementation changes were performed. The artist INI hash remains `67718c4d9751f9077fd463ec1fb1da14f28650e9b285e30949ad10bc86854a71` before and after the final host campaign.

## Corrections and resulting behavior

| Finding / impact | Correction and source | Evidence |
| --- | --- | --- |
| P1: a warm popup topic could keep controls bound to its previous layer/root and edit the wrong owner. | `templates/layer-editor.ms:113` accepts explicit rebind on the already-built topic; retarget uses it at line 156. Same-owner browsing still retains its cheap path. | Real population edits after layer and controller switches change only the intended owner. Popup paint-set selection refreshes the open integrated fields. |
| The mandatory popup made ordinary layer editing depend on a separate window; constructing a full UI per layer would grow unnecessarily. | `layers-first.cjs:147` generates one sixteen-section selected-layer native view from the same feature bodies as the optional popup. `templates/compact-host.ms:38` binds open sections, clears stale owners and releases command-panel references on close. | Native and popup control/lifecycle regression, empty-owner checks, retained HWNDs and multi-root editing pass. No per-layer UI copies were added. |
| Repeated owner switches could issue sixteen native Show/Hide/layout calls even when page visibility remained valid. | `templates/compact-host.ms:60` changes visibility only when the selected-layer view transitions between empty and valid. Unchanged list contents are retained by `templates/layers-flow-helpers.ms:3`. | Valid-owner retarget, page metadata and browsing invariants pass; perceived dropdown latency was not measured. |
| P2: direct population control-handler changes did not provide a reliable explicit Undo boundary in the new shared UI body. | `layers-first.cjs:188` wraps distribution/count/seed/density handlers in the existing named Undo gesture for both views. | Real handler edit → Max Undo restores the amount and rebound field. No duplicate evaluator or serialized state was introduced. |
| The native recorder required Automation's panel for friendly controls. | `templates/diagnostics-ui.ms` adds Start/Stop/Save/Read status directly to Scatter. It uses the existing bounded recorder and has no polling timer. | Start remains opt-in; cancel leaves the recording active; 620 events export over two valid stopped pages; existing-report replacement and an unwritable-path failure preserve the previous report. |
| P2: the old Corona Stop wrapper treated every nonzero status as failure, and Stop can pump nested callbacks. | `templates/runtime-scheduling.ms:10` avoids Stop when no render is active, excludes nested bridge mutation while stopping IR, and verifies the resulting render type. A renderer that remains active is a failure; its bridge is preserved. | Real Corona 15 inactive Stop returns `2` with type `0` before/after. Mocked active/failure/reentry cases and actual floating-IR lifecycle pass. This does not isolate the original artist-session trigger. |

Source paths in the table are under `AminScatter/tools/ui/`. The generated script is a delivery output, not the only authoritative source. CMake metadata and package version extraction agree. Saved parameter schema/class IDs, procedural order, collision/radius semantics, retained Mesh/Point implementations, worker architecture and default-off licensing policy are preserved.

## Final evidence

| Check | Result and practical scope |
| --- | --- |
| Generator / feature catalog | Reproducible current source; all prior 241 semantic controls retained, four Diagnostics buttons added, 245 total. One native selected-layer view and one optional-popup factory set. Inventory parity does not prove every field combination was tested. |
| Python/offline | **140 passed**, no failures/errors/skips. Covers schemas, transport/authority, diagnostic/publication pages, feature mapping, offline study contracts and version/package metadata. Synthetic preference tests do not demonstrate artistic ML. |
| Native SDK builds | **14/14 Scatter suites pass for each Max 2026 and 2027 SDK build**. Unchanged Analyzer dependency receipts also match current sources and pass its native suite. Max 2026 application is unavailable here; compilation is not runtime qualification. |
| Headless Max 2027 playback | **1,312 assertions pass** on the final script/native pair. Policies 1/2/3: unrelated animation/rewind, parameter edits, receiver/source animation, in-place and animated density maps, Manual freeze/catch-up, disable/hide catch-up, retained preview modes, registry lifecycle and Analyzer notification/timer integration. Loaded module paths and hashes are checked. |
| Private Max 2027 controls/core | Final `controls10` full campaign passes owner/set routing, warm popup retarget, sixteen retained native sections, automatic spacing, diagnostic cancellation/export/replacement/failure, Undo and selection/close/reopen/deletion. Existing core, Edit/radius, flat/curved Brush, background/cleanup and persistence fixtures pass. API invocation of handlers is distinct from pointer input. |
| Source containers | Existing acceptance, edge cases and output fixtures plus eight real queued event stages pass: park, return, enroll, grouped source/container movement and source geometry. Identities/settings survive parking/reentry. |
| Native Qt metadata | Exactly sixteen `MaxSDK::QMaxLegacyRollup` pages, unique categories 50…200 and ordered positions per native column. All visible for a valid owner, all explicitly hidden for an empty owner after posted layout messages settle. Observed native host width 449; this is metadata evidence, not an actual drag-resize/DPI test. |
| Retained navigation / UI | 100,000 instances of a 32-face synthetic source, 30 camera/redraw steps per hidden/Point Cloud/Mesh/centres mode. No placement, Brush or container rebuild and no unchanged-buffer upload. Three cycles through all sixteen native sections and six popup topics preserve control handles, placement/preparation keys and retained Mesh/Point statistics. |
| Settled Live/Manual idle | Eight approximately ten-second windows pass with zero changes in the measured preparation/publication/preview/container/callback/redraw/upload/IR timer/key counters. Includes all native sections + popup open, Manual pending, actual amount/density edits, failed successor, exact cached recovery and post-recording idle. Relevant edits still publish; a failed successor preserves its prior result. |
| Actual Corona lifecycle | Floating IR type 3 advances passes **8 → 31** at unchanged epoch 3/bridge build 9. One Live edit changes population **120 → 180**, epoch **3 → 4**, bridge builds **9 → 10**, then passes advance **5 → 16** with no further rebuild. Save resumes IR at the same epoch with its expected bridge rebuild. Repeated guarded Stop leaves type 0. Synchronous production completes a **96×96 bitmap**; reset clears helpers/timer/resume state. |
| Packages | Exact script/native identities, ZIP integrity, all manifest file hashes, host guards and licensing-lab marker exclusion pass. Max 2027 is the qualified development target; Max 2026 package is SDK-only. No 0.72 installer was executed in an artist profile. |

See [core/UI receipts](evidence/max-controls.json), [playback](evidence/playback-final.json), [idle](evidence/idle-qualification.json), [retained browsing](evidence/retained-ui-072.json), [actual Corona](evidence/corona072-result.json), [mock failure cases](evidence/corona-stop-072.json), and [selected](evidence/native-rollup-selected.json)/[empty](evidence/native-rollup-empty.json) page metadata. The index hashes 52 preserved files; its source snapshot inventories 560 source/configuration/test files. Raw local bytes may differ from Git-normalized text; the frozen generated script uses LF.

## Performance interpretation

The relevant-input playback corrections were already part of the initial backup. This slice preserves them and independently rechecks them with the integrated view. It does not claim all prior slowness was a full solve, or that ordinary drawing has no cost.

| Synthetic navigation mode | Median / p95 synchronous step, ms |
| --- | --- |
| Hidden scatter | 31.60 / 44.78 |
| Point Cloud | 31.22 / 45.98 |
| Mesh | 32.84 / 50.71 |
| Centres | 32.64 / 46.80 |

These samples include camera change, `completeRedraw` and posted messages in one 1176×750 private viewport. P95 uses the sorted observation at `floor(.95 × (n − 1))`. They are not presented FPS, isolated GPU time or an artist-scene benchmark. Process working set was about 2.88 GB, including Max/other plugins/fixtures; it is not a per-Scatter memory bound. Proxy retains cached immediate triangle batches and still pays per-draw submission cost; it was covered in playback correctness but excluded from this 100k navigation timing set.

Diagnostic overhead used interleaved off/on trials, 24 edits per condition in one warmed 600-candidate scene: median **285.0 ms off / 293.5 ms on**, about **3.0% higher** for this sample. Recording is bounded, opt-in and memory-only on event paths. The private test transport polls at 200 ms; process CPU remains nonzero, so zero Cyrus counters must not be described as zero host CPU or zero processing throughout Max.

## Evidence quality and intermediate failures

An intermediate headless run (`regression03`) failed after 197 assertions because a static deferred-work flag had not settled. It ran alongside another private UI host; the triggering condition was not isolated. The assertion was retained and only failure-state output was added. The subsequent isolated intermediate run and the final frozen run each pass 1,312 assertions. [Failed](evidence/intermediate/playback03.json) and [intermediate passing](evidence/intermediate/playback04.json) receipts remain distinct from the final pair.

Early Max runs exposed real MAXScript initialization and .NET overload problems in the new UI/exporter: reading an undefined root during rollout construction, chained GUID syntax and `File.Replace` with an undefined backup argument. They were corrected before the final fresh-host pass. Fixture mistakes were also corrected separately: invoking a list's string property as an event, hiding the floating Corona VFB before observing IR, reading metadata before posted layout settlement and assuming `python.ExecuteFile` returned a Boolean. None of those failed runs supplies final passing evidence.

Corona's production statistic 0 can retain the previous IR pass count. This report uses completed render and bitmap dimensions; it does not claim that this statistic certifies the configured production pass limit. The synthetic bitmap was not visually inspected and does not qualify appearance, material fidelity, missing assets or a beautiful composition. The previous courtyard render remains evidence only for its own dated build.

## Remaining gates

Manual pointer/resize/scroll/DPI/multi-monitor and perceived UI latency, artist-scene presented FPS, successful docked IR, long mixed renderer sessions, other intended renderers, Max 2026 runtime/installation and Brush BR-01 tiny-coordinate serialization remain open. See [prioritized acceptance criteria](NEXT_WORK.md).

MCP code authority is unchanged: policy 3 remains read-only and closed plans 1/2 retain their supported writes. Help now maps the integrated view/direct recorder and honestly records prior bounded MCP qualification. No trained model, policy-3 mutation adapter, complete causal database, commercial licensing enforcement or publication-ready 1.0 is claimed.
