# Follow-up findings from the real scene

5 October 2026. The delivered scene's geometry, exact output, source parking and Brush persistence pass their checks. These findings remain separate from those passes. Production fixes were not folded into the pinned 0.7.1 binary/script qualification during scene authoring.

## P1 follow-up — Corona IR repeatedly restarts in the delivered test session

**Observed after delivery:** the user reported that production rendering completes while Interactive Rendering remains at a coarse first image. Read-only inspection of the existing private-session log found 485 render-start markers between 12:03:04 and 12:06:23 on 5 October, repeatedly returning to the first pass. These are log timestamps as written; no new reproduction or fix was performed by the documentation task. See the [compact observation](../Current_System_2026-10-05/evidence/ir-restart-summary.json).

**Impact:** the interactive image cannot refine normally. Earlier production renders do not establish IR correctness. The ordinary test build excludes the licensing experiment; the observation does not indicate a Cyrus licensing denial.

**Cause not yet isolated:** the explicit render-bridge stop/rebuild/start path, scene notifications, container invalidation and retained preview publication are investigation points. The false Pending reproduction below is separate evidence and must not be asserted to cause the restart without a causal trace. The session also reported missing texture-map plugins and asset paths; audit those separately before evaluating appearance.

**Next evidence:** follow the [IR runbook](../Current_System_2026-10-05/DIAGNOSTICS_SPEC.md#ir-01-diagnostic-runbook) with a matching private script/native pair. Record the first unwanted event, bridge phases/build count and existing publication counters. Test one suspended subsystem at a time and restore it afterward. A final correction must preserve real Live/Manual updates, Undo, persistence and retained cache reuse.

## P2 — A redraw can report Pending for an already current publication

**Observed:** In the final eight-population scene, Update sets all eight `dirty` / `needsUpdate` flags to false. After `completeRedraw()` and message processing, all eight are true again. `groupSnapshotKey == procInputKey()` remains true; publication epoch stays at 16. The same false Pending state is visible in the layer manager and floating editor. `evidence/pending-status.json` records all three stages.

**Impact:** Artists cannot reliably tell whether Manual mode has an unpublished calculation change. They may press Update repeatedly and incur avoidable work. This did not regenerate placements or upload unchanged retained buffers during the navigation campaign.

**Relevant source:** `AminScatter/scripts/AminScatterObject.ms:3232` exposes the generic `dirty` flag directly as `needsUpdate`. `CyrusFlowLayerSummary` consumes it at line 185. `layerEntries` propagates any dirty member across enabled shared-policy members at lines 3366–3367. `containerNote` marks container-backed leaves dirty at line 3989 even when an event has not demonstrated changed membership. The exact originating callback for this reproduction has not been isolated; the latter two paths are suspects, not a proven call trace.

**Smallest reasonable fix:** Separate publication-pending status from a display/event dirty hint. Use a cached input/publication revision comparison maintained by the evaluator; avoid recomputing a large input key on every UI label read. Restrict container invalidation to changed membership or relevant inputs.

**Acceptance:** Update → redraw → orbit → all six editor tabs keeps Cached when inputs are unchanged. Actual spacing, Brush, source membership and Area edits show Pending in Manual until Update, then Cached. Verify exact IDs/rows, epoch and retained-upload counters are unchanged during browsing.

## P3 — Very small generated coordinates expose a Brush save/reopen boundary

**Observed:** A freshly generated Gaussian terrain with extremely small positive Z values passed Brush painting but was rejected by the surface-identity guard after save/reopen. The fixture recorded no visible/topological change. Normalizing this generated terrain's Z values below 0.001 cm to zero before painting made save/reopen exact. See `evidence/surface-diagnostic.json` and `terrain-roundtrip.json`.

**Source fact:** `AminScatter/src/brush.cpp:78` hashes raw position bytes; `AminScatter/src/brush_host.cpp:133` rejects changed geometry identity when strokes exist. The particular differing bit pattern was not isolated, so this is not proof that the guard itself is incorrect.

**Smallest next step:** Add a native/host roundtrip fixture covering signed zero, subnormal values, ordinary coordinates and genuine topology edits. If host serialization canonicalizes equivalent values, canonicalize the identity representation consistently while preserving rejection of actual unsupported geometry changes. Do not disable the protection globally.

## P3 — Responsiveness still needs a controlled CPU profile

**Observed:** Retained buffers and placement caches are reused, but some synchronous camera/redraw/message-processing samples still take hundreds of milliseconds or more. The user’s other Max session and a fresh-process launch were active during parts of the campaign. The numbers are not presented FPS or an isolated benchmark.

**Smallest next step:** Measure clean-host input-key, source-container scan, Brush-field, preview-adapter and UI-refresh costs separately. Include long histories, high-poly proxies, many populations and constrained memory. Preserve the cache/upload invariant while improving CPU work. GPU compute is not an evidence-based remedy for this result yet.

## Scene-design issue corrected before delivery

The first offset flower strokes crossed the walking route at tight S-bends. The independent polyline-distance oracle caught eight flower centers within the intended 90 cm clearance radius, including three inside the paved/edged corridor. A final native Brush erase was added to both flower fields. The final oracle passes, with the nearest center 23.485 cm beyond the outer edging. The pre-correction receipt is intentionally retained as diagnostic evidence.

## Suggested next loop

1. Diagnose the later IR restart loop with minimal causal tracing, then fix its demonstrated cause against a newly pinned candidate.
2. Fix false Pending with the exact acceptance cases above; combine it with the IR change only if their relationship is demonstrated.
3. Add and classify the precision roundtrip regression without weakening topology safety.
4. Run a clean-host interaction profile and address measured CPU work before adding abstractions or GPU paths.
5. Requalify the resulting script/native pair in this scene and the small fixtures, testing production and IR separately, then decide whether to package. Version 0.7.1 remains a development label. The [coordinated roadmap](../Current_System_2026-10-05/ROADMAP.md) places diagnostics and MCP work after these evidence gates.
