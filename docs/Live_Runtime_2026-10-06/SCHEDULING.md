# Runtime scheduling contract

6 October 2026. This describes the implemented scheduling change. Use the campaign results and fingerprints to identify the tested build.

## When work is necessary

Live must respond to relevant parameter changes, source/receiver geometry and transforms, source-container membership, Brush history, Edit/radius changes, Undo/Redo and time changes. A parameter is not the only possible input. Manual preserves its last complete publication until Update; pending settings remain visible as pending.

Opening an editor, leaving it open or browsing topics does not authorize regeneration. Navigation necessarily draws the viewport, but must reuse placement caches and retained buffers. A scene reset/reopen must reconstruct transient state once. Active painting, dragging, rendering and an admitted MCP operation are work in progress, not unchanged idle operation.

## Event and timer ownership

| Owner | Arming event | Completion |
| --- | --- | --- |
| Release timer | A drag deferred work or retained output needs publication | Stop at entry; wait only while input is held, then settle once |
| Layer Editor / Modify-panel status timers | Relevant controller notification, explicit refresh or completed publication | Refresh cached labels once; stop until another event |
| Brush timer | An explicitly started Brush session | Stop when the session ends; active Brush continues its 150 ms session/status checks |
| Corona bridge timer | Relevant redraw/publication/material/visibility or render lifecycle event | Debounce a changed render dependency, update once, then stop; errors stop the sequence |
| MCP panel Qt timer | An authenticated queued IPC request or an unfinished admitted operation | Drain on Max's UI thread; stop when the queue and operation are empty |

The policy-3 render key uses the completed publication epoch and published source material identities. Constructing this key does not reconcile source containers or evaluate the procedural recipe. Manual pending input is not a new publication. The complete bridge still validates exact output on admission.

Timers used for deferred work stop before invoking code that can pump host messages. The Corona and MCP dispatch paths also reject reentry. Script reload disposes old release/render timers and preserves the existing callback teardown rules. A failed Corona start/stop return code becomes a local error; it does not justify an indefinite retry loop.

Pending propagation only changes clean dependents to dirty. Reassigning `dirty=true` through another scripted-plugin instance can emit geometry/topology/mapping notifications even when the value is already true. Doing that during drawing caused a self-sustaining Manual-mode redraw loop; the new guard preserves the pending flag without rewriting it every draw.

## Measurements and limits

Idle assertions compare preparation, publication, preview, membership, callback, render-key, timer, bridge and retained counters without calling the input-key/evaluation functions. Whole-process CPU includes Max, renderer, other plugins and the private test transport. It is not a measure of Cyrus alone. Unchanged retained upload counts and unchanged placement epochs are separate assertions.

The private development transport polls every 200 ms solely to execute diagnostic fixtures. It is not shipped by this change. The MCP panel has no recurring host-dispatch timer when idle; its background loopback server still waits for connections. This is not a promise of zero operating-system activity, zero host CPU or unlimited viewport FPS.

The existing native geometry algorithms and retained Point Cloud/Mesh implementation are unchanged in this campaign. GPU compute, a new evaluation framework and asynchronous host geometry access are unnecessary for the demonstrated problems.

## Primary API contracts used

- [Autodesk NodeEventCallback](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/GUID-7C91D285-5683-4606-9F7C-B8D3A7CA508B.html): queued scene notifications, batching and callback lifetime. A callback receipt time is not the original artist action time.
- [Autodesk render callbacks](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/General-Event-Callback-Mechanism/GUID-E5BE0058-2216-4E0B-88AF-680CA58AAC73.html): prepare render nodes at the supported render boundary; avoid scene mutation from per-frame mesh evaluation.
- [Chaos Corona MAXScript](https://docs-chaos.atlassian.net/wiki/spaces/CRMAX/pages/124394405/MAXScript): floating/docked IR are render types 3/2; startup functions report status, and docked startup needs a valid inactive docked viewport. A failed startup is not success merely because it returned without throwing.
- [Existing Autodesk/Houdini research register](../Current_System_2026-10-05/VENDOR_RECHECK.md): host-thread access, stable identities, bounded resources and explicit publication contracts remain applicable. Source references do not replace runtime results.
