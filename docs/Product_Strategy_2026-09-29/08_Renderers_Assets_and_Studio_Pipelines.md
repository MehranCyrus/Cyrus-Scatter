# 08 — Renderers, assets and studio pipelines

## Current position

Cyrus computes placement data and builds transient PFlow structures. The source contains Corona proxy and IR handling. No rendered-image comparison or farm qualification has been established in this review. Treat renderer support as an exact tested combination, not an implication of successful plugin loading.

Chaos officially announced Max 2027 support in V-Ray 7 Update 3, build 7.30.02, and Corona 14 Update 1 Hotfix 2 (listed as update 1.2 on its download page). These establish vendor-supported candidates to test, not the newest required builds or Cyrus certification. [V-Ray announcement](https://forums.chaos.com/t/v-ray-7-update-3-available-for-download/124628), [Corona announcement](https://forums.chaos.com/t/chaos-corona-14-update-1-hotfix-2-released-for-3ds-max/160584)

## Qualification order

1. Generic host/PFlow correctness with an available renderer and simple mesh sources.
2. Corona production and IR workflows, because explicit integration already exists.
3. V-Ray CPU production/interactive paths on a verified host/build.
4. V-Ray GPU as a separate matrix entry; matching CPU support is insufficient.
5. Batch/network workers for the selected renderer and actual studio launcher.
6. Animation, motion blur, displacement, multi-material sources, proxies and distributed rendering according to advertised scope.

Use named support levels: **required for planned release**, **qualified**, **experimental**, **not tested**, **unsupported**. Record the chosen renderer versions before the beta; do not invent the user's installed renderer.

## Transport decision

| Candidate | Current status | Benefit hypothesis | Required gate |
|---|---|---|---|
| PFlow | Implemented | Existing cross-renderer host mechanism | Ownership, count/matrix/material parity, cancellation and cleanup |
| Incremental PFlow | Proposed | Avoid repeated construction for small changes | Safe host API update plus full rebuild fallback |
| Max 2027.2 Point Instance | Vendor-documented, Cyrus prototype pending | Lower transport/translation memory or time | Exact transform mapping and each renderer's support |
| Renderer-specific procedural/instancer | Research only | Native render instancing and animation features | Supported public SDK/API, redistribution rights and qualification |
| Baked Max instances | Existing artist-facing output | Portable evaluated snapshot in supported host workflow | Correct ownership/undo and explicit loss of procedural updates |
| USD PointInstancer export | Proposed | Studio interchange with shared prototypes | Export/import parity and downstream renderer tests |

Do not use undocumented Chaos internals or infer a public procedural SDK from a product feature. If a supported interface cannot be established, retain the tested transport and document its limits. Avoid introducing a second adapter until it solves a measured problem.

## Render result contract

Check particle/instance count, source selection, complete transform, material IDs, UVs, visibility, normals, negative and nonuniform scales, animated source evaluation, shutter samples and stable IDs where applicable. Then compare images with fixed settings. Image noise tolerance does not excuse a geometry mismatch.

Test empty output, missing source, disabled layer/controller, a moved source pivot, nested transforms, nonzero animation start, time changes, render abort and repeated IR restarts. Include two controllers that share a source and one that uses a different material.

## Proxy contract

The current Corona workaround copies a source and requests another viewport representation because PFlow consumes viewport geometry. A proxy's displayed mesh is not automatically its render payload. Verify file paths, animated frames, material binding, pivot, scale, source visibility and cleanup. Confirm the original proxy is untouched after success and failure.

Do not advertise general proxy preservation from the presence of the `CProxy` branch. A future adapter needs an explicit source capability description: ordinary mesh, static proxy, animated proxy, hierarchy or unsupported source. Report missing dependencies before starting a long render.

## Studio scene preflight

Proposed report, initially read-only:

- Cyrus build/native module paths, host update, renderer build and scene schema.
- Missing surfaces, sources, Analyzer dependencies and asset files.
- Unresolved or invalid edit records; stale Manual-mode data.
- Declared units, generation counts, preview limits and estimated work warnings.
- Duplicate plugin registrations, mismatched modules and unsupported optional features.
- Output/bake ownership and potential duplicate render populations.
- Licensable authoring status separately from render-evaluation eligibility.

Make results actionable with stable issue codes. File paths and scene names stay local by default; support export redacts them unless the user chooses to include them.

## Farm and headless execution

Create a small scene builder and deterministic preflight/evaluate job that returns structured status without dialogs. Test fresh processes with no prior viewport evaluation and missing optional compute runtime. Record whether a worker needs saved Analyzer data or recomputation and what Manual mode means for rendering.

Support the launchers pilot studios actually use. The older licensing plan names Deadline, but Deadline 10 entered maintenance mode in November 2025; it should not be the sole architectural assumption for future farm support. This does not imply automatic support for a replacement service. [Deadline maintenance FAQ](https://docs.thinkboxsoftware.com/products/deadline/10.4/1_User%20Manual/manual/maintenance-mode-faq.html)

Test `3dsmaxcmd`, batch automation and farm-launched interactive executable workflows separately. Process names/environment variables are context signals, not strong security proof against a local attacker. An ambiguous context must never unlock unrestricted authoring.

## Asset and preset portability

Use project-relative or explicitly mapped asset references where appropriate; retain resolution diagnostics for UNC paths and non-ASCII names. A collection operation must respect asset redistribution rights. Never silently duplicate licensed third-party libraries into a distributable demo.

Keep preset schemas distinct from `.max` scene schemas. Provide slot-based source replacement and unit conversion. Exported Analyzer splines/helpers are snapshots unless a live dependency has been explicitly implemented.

## USD scope

OpenUSD PointInstancer supports prototype references and per-instance attributes including IDs, positions, orientation and scale. That is a useful interchange model, but it does not itself export Cyrus or translate renderer materials. [OpenUSD PointInstancer reference](https://openusd.org/release/api/class_usd_geom_point_instancer.html)

First export a static evaluated snapshot with explicit units/up axis, stable prototype paths and visibility. Check matrix decomposition: arbitrary affine/sheared transforms may not fit the chosen orientation/scale representation exactly. Reject unsupported transforms or choose an explicit alternative; do not silently approximate.

Animation, material translation, proxy preservation, live round trip and USD import back into editable Cyrus are separate capabilities. Test the exact USD plugin/version and target consumer rather than claiming generic interoperability.

## Scene lifecycle release gate

Render/IR success, failure and abort must restore user flags and preserve unrelated nodes. Saving must not persist disposable transport. Reopen/reset/delete/clone/merge must not retain stale resources. A failure here blocks release even if an alternative transport is faster.
