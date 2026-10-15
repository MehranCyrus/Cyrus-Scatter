# 17 — Max host integration, persistence, collections, and assets

**Status: proposed integration contract. Research basis: R0 §§7–8. Host anchors: S21–S25.**

## 1. Preserve the C++/MAXScript boundary

Native C++ owns numerical evaluation, snapshots, caches, compact populations, host references, and qualified output adapters. MAXScript owns artist workflows, panels, convenience commands, and integration with studio automation. It does not loop through millions of instances to evaluate masks or transforms.

Expose one command API from native code. MAXScript, CS Edit, and automation use it. Do not implement the same mutation once in a rollout callback and again in an MCP handler with different validation or Undo behavior.

## 2. Suggested native object structure

A persistent setup controller stores the recipe and references. Layer state can be embedded versioned data or dedicated reference targets, depending on the audited existing implementation. A display object exposes the evaluated population through the host viewport integration. Editing tools operate on stable IDs through the command layer.

This is a logical proposal, not a mandate to replace every current Cyrus class. The actual Class_IDs, ParamBlock IDs, reference layout, and compatibility strategy must be documented after reading the repository. Never reuse an existing saved parameter ID for a new meaning.

## 3. SDK interfaces: precise scope

`IPainterCanvasInterface_V5` supplies the paint lifecycle and hit information; `Hold`/`RestoreObj` support Undo; `IObjectDisplay2` supplies shared/per-node/per-view display boundaries [S21–S24]. Those are verified interface families, not complete plugin implementations.

A version-specific main-thread dispatch mechanism is needed for publication. A documented `IMainThreadTaskManager` entry was located for the 2026 SDK [S25]; do not assume the same interface is available or identical in the Max 2024 target. The adapter must choose a route supported by the actual SDK.

## 4. Host references and notifications

Keep scene references through host-managed reference targets so deletion, cloning, merge, and save/load participate in Max's lifecycle. Persistent UUIDs supplement host references; they do not replace host ownership rules.

Translate host notifications into typed changes: geometry, topology, transform, UV, material, time, selection, and display. Coalesce repeated notifications. Unknown changes conservatively invalidate relevant snapshots, not unrelated authoring data.

Avoid rebuilding inside notification callbacks. Record dirty state and schedule evaluation at a safe point. Guard against notifications caused by Cyrus updating its own output transport.

## 5. Snapshot capture and validity

Evaluate only requested source/receiver channels at the required time. Copy data and release temporary converted host objects according to SDK ownership rules. Do not retain pointers into temporary evaluated meshes after capture.

Use validity intervals when trustworthy, but do not assume a third-party object reports them perfectly. Provide a diagnostic forced-refresh path and fixtures for animated/modifier-driven sources. Content/revision checks complement host notifications.

Unit conversion uses system units, not display formatting alone. Store the recipe's canonical units and conversion version. A scene unit rescale operation updates both geometry and numeric length parameters through one explicit policy.

## 6. Save format

Persist authoritative data in versioned chunks:

```text
Header: format version, engine profile, UUID namespaces, unit/time profile
Recipe: layers, parameters, area programs, references
Sources: providers, weights, transforms, bounds policy, materials, LOD
Paint: canonical domains and tiles / surface atlases
Edits: overrides, pins, tombstones, manual items, orphan records
Effects: definitions, parameter bindings, dependency declarations
Assets: logical references and recovery metadata
Optional caches: complete fingerprints, never sole authority
```

Store a checksum for large embedded payloads. Decode with length/count limits before allocating. An unknown newer field should be preserved when feasible or cause a clear compatibility refusal; silently dropping it may corrupt artistic intent.

Do not make the scene depend on a temporary absolute path in the developer's workstation cache. Authoritative paint must be embedded or referenced through a durable managed asset contract.

## 7. Save during computation

Save committed authoring state, not a half-written worker buffer. A working uncommitted gesture must either be committed/cancelled by the host's safe save policy or excluded with clear user feedback.

A derived cache can be omitted while an update is in progress. Loading then rebuilds from authority. Never write a cache fingerprint describing new paint beside an old population and call the pair valid.

## 8. Clone, merge, and reference collisions

Cloning a setup generates new setup/layer UUIDs where independence is intended and remaps internal references. Shared source assets may remain shared. A linked instance of a setup may intentionally share recipe definitions while having a separate node transform; that is a different command.

Merging two scenes can introduce UUID collisions. Detect them and remap the imported namespace deterministically within the import transaction. Manual edits, source IDs, paint references, and cross-layer links must be remapped together.

Stable identity across cloning does not mean every clone must share randomness. Expose `Preserve variation` versus `New variation` as explicit commands.

## 9. Shared collections

A collection has a role, UUID, explicit members, optional scene-layer query, and nested collection references. Resolve membership into a canonical ordered snapshot. Display order does not affect source randomization unless an explicitly ordered sequence consumes it.

Detect cycles during collection edits. Dynamic layer membership creates a dependency on that layer's membership revision. Renaming a scene layer is not necessarily changing its identity; the host adapter should use a stable identifier where available.

ForestSet provides a feature reference for shared scene inputs [S18]. Cyrus's role-specific collection model is a design choice intended to avoid ambiguous “one item versus all members” behavior.

## 10. Preset levels

**Settings preset:** parameters, curves, and behavior profile, with no embedded scene-specific receiver.

**Source collection:** asset/provider references, metadata, materials, and variants.

**Complete recipe:** sources plus distribution, area definitions, paint/edits where selected, and portable dependency bindings.

Import previews missing requirements and lets the artist bind receivers/paths. It does not silently reuse unrelated current selections as missing references.

## 11. Portable packages

Use a manifest with logical asset IDs, relative paths, content fingerprints, media types, and required capabilities. Separate authored assets from derived caches. Include only assets the user is authorized to distribute.

Validate archive paths against traversal and absolute-path injection. Bound decompressed size and file count. Effect definitions remain constrained data; importing a package does not automatically execute arbitrary scripts.

An asset resolver searches explicit project roots, package-relative paths, and configured mappings in a deterministic order. A missing item produces a report with original and attempted locations.

## 12. Headless and render-farm operation

Provide a startup path that registers data types and adapters without opening panels. A final render synchronously establishes a coherent current population through a safe host entry point. It cannot depend on a mouse event, active viewport, or background UI timer to finish initialization.

Log required plugin versions, unresolved assets, active behavior profiles, and output capability failures. Rendering cached data is an explicit frozen mode, not a workaround silently selected when headless evaluation fails.

## 13. Thread and shutdown safety

Scene reset, file open, and plugin shutdown cancel jobs, invalidate publication tokens, and retire resources. Host-owned objects are released on the required domain. A worker never calls into an unloaded renderer module.

Avoid deadlocks between renderer callbacks, host main-thread dispatch, and workers. Document who can wait for whom. A host thread waiting for a worker must not simultaneously block the only route that worker needs for a host task.

## 14. Acceptance cases

Save/reopen with no caches, missing assets, disabled layers, unresolved edits, ongoing cancelled work, shared collections, merged UUID collisions, different system units, network asset paths, and headless rendering. Verify exact authoring restoration before considering optional cache-speed improvements.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S18]: https://docs.itoosoft.com/forestpack/forestset-plugin
[S21]: https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_i_painter_canvas_interface___v5.html
[S24]: https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_max_s_d_k_1_1_graphics_1_1_i_object_display2.html
[S25]: https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/_main_thread_task_manager_8h.html
