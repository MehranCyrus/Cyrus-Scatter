# Autodesk contracts for reliable automation and diagnostics

Second pass: **5 October 2026**. This is a documentation/source cross-check and a qualification plan. It does not diagnose the cause of the Corona IR loop or certify a loaded DLL. References target Max 2027 where accessible; the 2026 time overview and 2022 Batch page are explicitly older references. The [vendor ledger](17_VENDOR_SOURCE_LEDGER.md) records reading depth and version limits.

## Render callbacks are different phases

Autodesk permits creation of render-time objects in `#preRender`, before render instances exist, and cleanup in `#postRender`, after they are destroyed. Render parameters are already captured at `#preRender`. The documentation forbids modifying rendered meshes in frame callbacks and `#beginRendering*` callbacks because the renderer may retain mesh pointers. [Max 2027 rendering notifications](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/General-Event-Callback-Mechanism/GUID-E5BE0058-2216-4E0B-88AF-680CA58AAC73.html).

**Source fact:** Cyrus currently registers `#preRender` and `#postRender`, not `#preRenderFrame`, for the PFlow bridge. See [the generated script](../../AminScatter/scripts/AminScatterObject.ms), lines 4727–4730 and 4772–4773. The documented frame restriction is therefore **not evidence of an existing callback-phase violation** in those registrations.

**Qualification requirement:** trace actual callback order for production, IR, cancelled renders, errors and restart. The renderer must be tested separately; a callback name alone cannot establish its IR lifecycle. Record when bridge geometry is created, hidden, restored or deleted and which publication owns it. Do not fix a loop by moving rebuilding into a later callback without establishing that phase's contract.

Native `NOTIFY_RENDER_PREEVAL` exists for work before renderer object evaluation. It is not permission to mutate arbitrarily while a render is already using snapshots. [System notification codes](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/group___notification_codes.html). The local Max 2027 SDK `notify.h` independently documents the pre-frame restriction at lines 180–185 and pre-evaluation phase at 274–281; header hashes are captured in [the SDK receipt](evidence/vendor_sdk_crosscheck.json).

## Validity intervals and notifications solve different problems

Object/modifier validity describes when computed data remains valid and can avoid unnecessary reevaluation. The `NotifyDependents` change interval is a different API contract: Autodesk specifies `FOREVER` except for its documented dependency-test exception. Reference messages also propagate through dependents, so a receiving target is not necessarily the original initiator. [Time and intervals, Max 2026](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/overview/overview_time_and_intervals.html), [ReferenceTarget, Max 2027](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_reference_target.html).

**Plan correction:** do not recommend narrowing `NotifyDependents` to a tiny time interval as a generic IR optimization. Investigate unnecessary publication, broad or incorrectly classified change messages, wrong cache dependencies and feedback cycles using measured evidence. Preserve required geometry/material/transform updates. Neither blanket `REF_STOP` nor suppressing all `REFMSG_CHANGE` is an acceptable qualification strategy.

The retained point helper already avoids replacement in its `sameLayers` path and emits `PART_GEOM | PART_DISPLAY` on a changed publication ([point_display.cpp](../../AminScatter/src/point_display.cpp), lines 261–268). Its helper `ObjectValidity()` returning `FOREVER` at line 207 does not by itself establish that every underlying source/receiver cache is valid forever. Trace the actual controller, prepared data and publication dependencies. Do not rewrite this mechanism merely because a generic validity example looks different.

## Observe events without causing the behaviour being measured

The Node Event System catches node geometry/topology changes and Undo/Redo-related events, but is timer-based and needs a Windows message loop. It supports delayed or mouse-release handling; polling is a different mode. [Max 2027 Node Event System](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/GUID-7C91D285-5683-4606-9F7C-B8D3A7CA508B.html).

General callbacks support ownership IDs for selective removal. Function callbacks retain the registered function instance, so redefining the function alone does not update that registration. Max 2027 adds `callbacks.notificationEvent()`; use a version-gated path when also supporting 2026. [General callback mechanism](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/GUID-C1F6495F-5831-4FC8-A00C-667C5F2EAE36.html).

**Proposed diagnostic event fields:** monotonic time, session/build identity, initiating user/API operation, callback/event name, current render phase, affected persistent IDs, input revision, old/new publication digest, dirty reason, cache decision, queued/coalesced outcome and elapsed work. A raw SDK pointer is not a persistent ID or safe background payload.

Record cached facts in a bounded buffer. Do not enumerate all scene meshes, invoke evaluation, force redraw or call a renderer query on every event just to fill a log row. Add expensive snapshots only as an explicit diagnostic capture at a supported host point. Measure diagnostics enabled/disabled overhead and observer-induced events.

Qualification must cover repeated script reload, editor open/close, reset/open/save, deletion, Undo/Redo and cancellation. Registrations should have a known owner and teardown path; remove only owned callbacks. Count active timers/handlers before and after these operations. A source match is not proof that an older function callback or DLL is no longer loaded.

The companion diagnostics proposal should extend the existing [current-system diagnostics specification](../Current_System_2026-10-05/DIAGNOSTICS_SPEC.md), not introduce a second incompatible event vocabulary. That document was read but not edited during this pass. Both proposals remain unimplemented logging work.

## Host APIs and parallel computation

Worker Python threads cannot use `pymxs`; the old token approach is deprecated and ineffective. Conversely, Max has explicitly multithreaded rendering contracts: texture evaluation must operate safely on prepared local data. “All Max work is single-threaded” would be an incorrect conclusion. [Python threading](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Python/files/MAXDEV_Python_threading_html.html), [Texmap thread-safety contract](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_texmap_thread_safe.html).

**Cyrus boundary:** resolve scene references and collect supported snapshots on the host path; move copied plain arrays, immutable artifacts and model work to the companion or qualified native workers. Serialize scene mutation and publication. Each native worker stage needs its own ownership, cancellation and thread-safety evidence. Do not move arbitrary mesh/material evaluation to a pool merely because numeric scatter work can be parallelized.

Measure CPU, RAM, renderer contention and transfer cost before selecting GPU compute. A fast surrogate or GPU kernel does not improve artist interaction if source extraction, upload or repeated notifications dominate.

## Render geometry ownership is a separate adapter contract

The GeomObject API documents caller/producer mesh ownership via `needDelete` and object-space transform/validity handling for multiple render meshes. Any future direct render-geometry adapter must obey those contracts. [GeomObject](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_geom_object.html).

The current automation path uses the existing PFlow bridge. This review does not establish a current `GetRenderMesh` ownership defect, and it does not recommend replacing PFlow as the first fix. First measure bridge construction, transform fidelity, source instancing, visibility restoration and callback behaviour. A future adapter comparison must include render correctness, materials, memory, motion/time behaviour and cancellation—not just build time.

## Undo is a host transaction, not a workflow checkpoint

Autodesk's `Hold` API requires a balanced begin and accept/cancel for undoable operations; cancel restores registered changes. [Hold](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_hold.html).

**Cyrus proposal:** one explicit user apply should map to its existing supported Undo transaction and complete-or-fail publication path. Companion checkpoints record intent and attempt state; they do not replace Max Undo. Test nested operations, failed setters, cancellation, Undo/Redo and save/reopen with the public API and UI producing equivalent results. A process crash is an unknown outcome until receipts/base-scene reconciliation establish what happened.

Prefer repairing the existing transaction path over adding a parallel custom Undo stack. Keep parked source settings and layer ownership in serialized plugin data, not only in companion memory.

## Interactive worker and Batch are separate supported modes

Autodesk's older Batch usage page documents process exit codes, including initialization/licensing failures. That is useful operational evidence but not current Max 2027 renderer qualification. [3ds Max Batch usage, Max 2022 documentation](https://help.autodesk.com/cloudhelp/2022/ENU/3DSMax-Batch/files/GUID-48A78515-C24B-4E46-AC5F-884FBCF40D59.htm).

**Plan amendment:** advertise a `host_mode` and a tested capability set. Begin with a private, isolated persistent Max worker if that is the path actually qualified. Add Max Batch only after proving load, explicit evaluation, publication, render completion, save and cancellation without relying on UI timers or modal dialogs. The Node Event System message-loop requirement makes this a concrete test obligation, not a hypothetical concern.

Record worker initialization, asset/plugin availability, source/DLL identity, Max/renderer version, job status and semantic artifact completion independently. Exit zero is necessary process evidence where applicable; it does not prove the expected image was produced. Never turn a Batch/renderer licensing error into an aesthetic rejection label or infer that Cyrus licensing caused an IR loop.

## Minimum next host qualification

P0 should establish causal traces and matching loaded code; P1 should establish identity and artifact receipts; P2 should declare exactly which worker mode can execute the new jobs. [E17](11_EXPERIMENTS.md#e17--callback-lifecycle-and-worker-mode-qualification) covers lifecycle and host-mode cases. Unsupported combinations remain visible in capability output rather than silently falling back to a different execution mode.

This pass consulted the installed-in-workspace SDK headers through the path recorded in `build/ui-071/native01/max2027/CMakeCache.txt`. Reading headers and prior build configuration is not proof that the running Max process loaded that build. No host process was touched.
