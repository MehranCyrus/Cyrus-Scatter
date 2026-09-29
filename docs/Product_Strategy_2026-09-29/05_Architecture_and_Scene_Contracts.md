# 05 — Architecture and scene contracts

**Direction: incremental boundaries around the existing hybrid architecture. Proposed types below are design concepts, not existing APIs.**

## Ownership model

| Layer | Owns | Must not own |
|---|---|---|
| Max host adapter | Node evaluation, main-thread capture, undo, references, lifecycle | Worker access to arbitrary live scene objects |
| Evaluation request | Immutable input values, dependency generations, time and units | Borrowed MAXScript/GC values or stale node pointers |
| Native engines | Sampling, constraints, analysis, deterministic numeric results | Provider SDKs, UI, scene mutation |
| Result snapshot | Ordered transforms/source IDs, diagnostics, provenance | Renderer-specific mutable objects |
| Display adapter | Bounded preview representations, picking and bounds | Authoritative scene generation |
| Render adapter | Owned transient transport, preparation and teardown | Unrelated artist/callback-created nodes |
| Licensing authority | Local capability decisions and provider session lifecycle | Placement RNG or geometry algorithms |

Autodesk explicitly documents restrictions on concurrency, including single-threaded reference/node evaluation. Adopt host capture → owned native work → host publication as the conservative default; verify any exception against the exact API. [Autodesk thread safety](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/best_practices/thread_safety.html)

## C1 — Legacy scene behavior is an interface

Preserve class IDs, internal names, parameter types, saved chunk readers, source ordering, random streams, tie rules and operation ordering. Preserve unknown/inapplicable old data where feasible. Do not turn a branding cleanup into a compatibility migration.

Current anchors: Scatter class `0x617d43a1/0x395c2e17`, Analyzer `0x45a201c7/0x1829bc63`, CS Edit `0x43b612e9/0x578124cd`; script schema versions 44/13; native edit chunks `0x3901` and `0x4001`. See [existing persistence reference](../CyrusScatter_Complete_Codebase_Documentation_2026-09-27/15_Persistence_Compatibility_and_Identifiers.md).

Within a frozen host/toolchain, exact legacy placement/identity parity is the optimization default. Cross-host numeric identity requires separate evidence. A deliberately new distribution algorithm gets an explicit mode/version and old-scene behavior remains available.

## C2 — Separate identity from display position

Current base IDs derive from row order, protected by a generation fingerprint. That protects against some invalid reuse but does not provide durable identity through arbitrary generation changes.

Before layer reorder, brush authoring or animation, specify durable controller/layer/source IDs and an explicit base-generation identity. Cloning must define whether IDs are copied, namespaced or regenerated; merge must resolve collisions. Copies of instances need persistent IDs and suspended-parent handling. File restore must not confuse transient Max node handles with portable identity.

Do not promise nearest-position remapping as a safe migration: symmetric or dense scenes make it ambiguous. Prefer refusal with retained records over a plausible-looking wrong edit. Capture fixtures before any schema transition.

## C3 — Transactional publication

Construct candidate output separately, validate it, then replace the active generation. On failure retain a clearly marked last-valid display. Analyzer boundaries, paths, points, stats and revision must publish together. Native edit loading should validate aggregate limits and complete records before accepting a replacement state.

Bound the memory overlap between old and new results. If a safe transaction cannot fit, preflight and fail with the scene unchanged; do not assume double buffering is free.

Final render has stricter semantics: current intended inputs must prepare successfully. A stale viewport is a recovery aid, not permission to render obsolete geometry.

## C4 — Explicit dependency generations

Separate placement, source geometry, display style, material/render, edit geometry, selection, and Analyzer output revisions. Include time, transforms, topology, maps/settings and units where relevant. Initial implementation can remain synchronous and per-evaluation; persistent caching needs a complete invalidation contract first.

Do not key CS Edit visibility only on `editRevision`: `applyStable` also changes inputs and activity. Do not use a raw node handle alone as a long-lived key. Selection/color changes should not force placement computation unless they truly affect source assignment.

The current global revision/string signatures are a workable baseline. Replace them only after diagnostics identify unnecessary work and fixtures cover every dependency.

## C5 — Render preparation owns its objects

Specify a render-session owner/token, every created node and auxiliary resource, and the cleanup rules for finish, abort, error, reset, save, file open and shutdown. PFlow may create auxiliary nodes; explicit tracking must cover them. A global scene difference alone is not a safe long-term ownership definition.

Capture and restore baked visibility/renderability and prototype settings. Avoid callback recursion and reentrant IR rebuilds. A transport failure must leave enough state to explain and recover without deleting unrelated scene content.

## C6 — Worker and optional device lifetime

Use one bounded runtime per intended process/module ownership scope, not a pool per controller. Workers operate on plain owned arrays and disjoint result slots. Exceptions, cancellation and statistics merge in deterministic order. No detached work survives reset/unload; join before releasing captured data.

Async preview, if later justified, needs request generations, coalescing, cancellation, controller lifetime checks and main-thread publication. Rendering/saving must synchronize against the correct generation. Synchronous multithreading alone does not create an interactive cancel workflow.

## C7 — Small adapter interfaces

Introduce renderer/display adapters only around a real second implementation. Suggested operations: capability probe, prepare, update if supported, validate, teardown, diagnostics. Keep host version and renderer version in capability checks; a supported host does not imply every renderer supports a new object type.

Keep existing visible native primitive signatures working while an internal evaluation context reduces repeated conversion. Make the public scripting API small and documented; do not expose internal cache pointers or require callers to understand provider state.

## Generator evolution

The successful two-run check is a baseline, not a substitute for guarded stages. Add replacement-count/anchor assertions, a generated parameter/interface manifest, and a repeatable build check. Gradually move fragile text transformations to explicit templates or structured generation when touched. Avoid a whole-generator rewrite alongside a behavioral change.

Separate product version, host target, scene schema, algorithm version, preset schema and licensing policy version. Generate public build identity from one source; do not repurpose scene migration numbers as marketing versions.

## Security as engineering hygiene

Validate every exposed input, array dimension and byte-size product before allocation. Cap total work, not just each field. Keep diagnostics bounded. Load optional dependencies from deliberate trusted locations and do not replace host-shipped runtime DLLs. Microsoft's loader guidance supports explicit search control. [DLL security](https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-security)

Presets and caches should be data, not executable scripts. Keep ordinary host scene protections enabled; qualify generated callbacks/PFlow behavior under those settings. No architecture claim here makes a local native process impossible to tamper with.
