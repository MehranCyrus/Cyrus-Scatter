# 06 — Exact Code Integration Map

## Scatter

### `AminScatter/src/max_bridge.cpp`

Primary authoring gate:
`aminScatterAdvanced_cf`.

Also review `aminScatterTransforms_cf` because the generated controller has a fast path. If either path can produce new placements, both need equivalent capability policy.

Recommended helper:

```cpp
static void requireScatterEvaluation() {
    auto cap = RuntimeContext::current().isRestrictedRender()
        ? Capability::RenderExistingScene
        : Capability::AuthorScatter;
    require(cap);
}
```

Do not gate pure helpers such as surface area queries unless they expose commercially meaningful standalone authoring.

## CS Edit

### `AminScatter/src/cyrus_edit.cpp`
Gate mutation commands:
- move/rotate/scale;
- delete;
- clone;
- reset if it destroys user edits;
- selection itself may remain available if it is read-only.

### `AminScatter/src/cyrus_edit_stack.inc`
Do **not** block saved stack evaluation needed for scene fidelity/render. It should use `EvaluateSavedEditState` / `RenderExistingScene`, not `ModifyScatter`.

Interactive transform sessions should cache the authorization at edit start rather than rechecking on every mouse move.

## Surface Analyzer

### `CyrusSurfaceAnalyzer/src/bridge.cpp::cyrusAnalyzeSurface_cf`
Interactive/new analysis requires `UseSurfaceAnalyzer`.

If render evaluation requires recomputation from saved Analyzer settings, allow a restricted render-evaluation path after runtime validation.

## Bake/export

### Generated MAXScript `bakeInstances()`
UI should preflight `ExportOrBake`, but the authoritative operation should have a native licensing primitive or native capability check that cannot be bypassed by editing MAXScript.

Recommended new primitive:
`cyrusLicenseRequire #exportBake` is **not sufficient alone** if script can skip it. Prefer moving the irreversible licensed operation or authorization token into a native helper.

## Preview

Do not gate `aminScatterDrawPreview` with network/provider calls. Preview should consume results already authorized.

## Generated UI

Add status/activation UI through `generate.cjs`. Rename existing `activation.cjs` to something like `feature-enable.cjs` before adding `licensing.cjs` to avoid conceptual collision.
