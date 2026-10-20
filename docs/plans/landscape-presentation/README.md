# Landscape presentation MVP: implementation plan

Plan date: **15 October 2026**. Status: **private MVP implemented and tested with the selected previous Botanical Islands model; broader release qualification remains later work**. See [current implementation evidence](PROGRESS.md) and [run instructions](../../../presentation-studio/README.md).

The initial request authorized saving the [research](RESEARCH_2026-10-15.md) and writing this plan. The user's subsequent instruction, **“Start implementing everything do the testing you need”**, resumed implementation. Work is isolated in `presentation-studio/`; existing website integration and deployment remain outside this delivery. This browser project is independent of native Scatter's version, schema and roadmap. The dated research retains its original historical scope.

**Acceptance update:** the user subsequently selected the earlier scrolling/vector study's Botanical Islands GLB and accepted mobile browser testing for now, prioritizing desktop studio use. The current local MVP uses that owned model and desktop/browser QA. Physical mobile qualification and representative customer-asset capacity are later support/publication work; the original performance targets below remain future qualification targets, not claims established by the current tests.

**Camera delivery update (0.1.1):** the user authorized a standalone **Max 2027** camera exporter and studio import. [Usage and contract](../../../presentation-studio/tools/max2027/README.md) document sampled world-space movement/lens/time, one continuous read-only imported track and desktop workflow qualification. Rigged/animated landscape GLBs remain deferred. Camera-bearing author projects use schema 2; ordinary schema 1 projects remain readable. This is separate from native Scatter delivery and deployment.

**Heavy-building delivery (0.1.2):** the subsequent user goal authorizes Max scene preparation, optimization, artistic materials, cinematic camera authoring and complete workflow qualification. The [BAILEY delivery guide](BUILDING_DELIVERY.md) indexes the 35.35 MiB / 2.84M-triangle result, reusable preparation tool, Max/camera/project/website artifacts and hardware-specific evidence. The [study ledger](BUILDING_STUDY.md) preserves rejected experiments and exact qualification boundaries. Existing website integration and publishing remain separate.

**Stacked timeline follow-up (0.2.0):** the user authorized After Effects inspired camera and layer tracks. [Timeline contract and evidence](TIMELINE.md) cover absolute camera keys, viewport capture, visibility keys, protected Max clips, schema 3, portable/public parity and desktop review. Existing schema 1/2 projects retain their original timing.

**Camera desk follow-up (0.3.0):** the user authorized adjustable timeline height, composition aspects/safe guides, Orbit performance investigation and transport that preserves Orbit/Plan navigation. [Camera desk contract and evidence](CAMERA_DESK.md) cover the change. No new project schema or Max exporter version is needed.

## 1. Delivery and accepted decisions

Build a local, single-admin presentation studio using **Three.js, TypeScript and Vite**, plus a separate static public player. The admin imports a prepared landscape, organizes its layers, aligns a plan, authors the reveal and camera journey, attaches artistic images, saves a portable project and exports a website package. The published viewer can navigate the presentation and toggle permitted layers. Scene editing exists only in the studio.

The first complete acceptance flow is:

1. Import a layered landscape GLB and a plan image.
2. Check metres, orientation, origin and plan alignment.
3. Map nodes into presentation layers and choose public visibility controls.
4. Set an architectural-plan opening and a staged landscape reveal.
5. Capture at least three camera stops, edit travel/holds and attach artistic images.
6. Scrub, play and reverse; preview desktop, portrait and reduced-motion presentation.
7. Save an editable archive, close the studio and reopen it without losing authored state.
8. Compile and preview the public artifact, export a ZIP, and verify it from a nested HTTP path with the studio closed.
9. Toggle a vegetation layer in the player: the image yields to the actual 3D state; no editing or regeneration appears.

| Decision | MVP contract | Later scope |
| --- | --- | --- |
| Asset creation | Import completed landscapes or assemble prepared GLB assets with root transforms; preserve useful groups as layers | Reusable planting sets and customer-designed compositions |
| Layers | Admin mapping is explicit; published layers can be hidden/shown when allowed | More detailed procedural layer controls |
| Scene sizes | Optimize a representative medium site first; include a large-site stress fixture | Larger capacity after measurements |
| Device support | Mainstream middle-range laptops and phones; WebGL2 capability check and fallback | Broader qualification based on real devices |
| Density | Present the density baked into imported assets | Explicit uniform, mask-driven and species-weighted density modes; spacing defined separately |
| Editing | One admin, local studio; public output is a read-only presentation | Customer accounts and authoring access later |
| Replacement | Explicit immutable asset revisions with reviewed node mapping | No automatic filesystem watching in the MVP |
| Photographs | Artistic interpretations tied to stops, with explicit approval and stale detection | Generation/provider integration later |
| Collaboration | None | Shared projects and concurrent editing deferred |
| Commercial licensing | No pricing, activation, entitlements or licensing integration | Product licensing decisions later |

Customer-created planting sets are a future authoring feature. The MVP may present a set designed in another tool, but it will not generate or edit planting distributions. Asset preparation must never silently reduce plant density or move plants to meet a performance target.

## 2. Scope and product behaviour

### Included

- Static GLB import: complete scene, building/terrain, or a prepared asset assembly. Translate, rotate and uniformly scale imported asset roots in the studio; no mesh editing.
- Node hierarchy, stable project layer IDs, rename, reorder, hide, isolate, include in export, and choose which layers viewers may toggle.
- PNG/JPEG/WebP plan images, two-point metric calibration, orientation/translation and a third-point alignment check. Plan imagery is visual input, not automatically interpreted geometry.
- Top-down plan and perspective editing; temporary free navigation; explicit camera capture/update.
- Stops, travel segments, holds, reorder/delete, path handles, target/orientation and FOV controls, scrubbing, forward/reverse playback and undo/redo.
- Authored plan/ink-to-colour reveal, layer reveal intervals, and optional imported boundary/point overlay groups.
- Imported artistic photos at stationary stops, desktop/portrait framing, stale status and visibility-aware fallback.
- Local autosave, portable project archive, missing-asset diagnostics, compiled preview and static export.
- Quality profiles, bounded resource admission, error recovery, demand rendering, keyboard controls and reduced motion.

### Deferred

Procedural scatter, density/exclusion/species maps, region drawing and polygon booleans, terrain generation/displacement, precise collision, per-plant overrides, SVG/DXF/PDF interpretation, rigged/animated scenes, arbitrary glTF extensions, material/shader graph editing, WebGPU, cloud storage, authentication services, collaboration, image generation APIs and licensing systems.

For the opening plan, use an authored image and optionally imported overlay geometry. Do not promise to extract accurate architectural drawings, planting boundaries or individual plant points from an arbitrary merged GLB. If no overlay metadata exists, the MVP can reveal whole named groups without inventing missing semantics.

## 3. Repository and build isolation

The isolated implementation follows this module layout; see the evidence record for concrete paths and intentional differences from this planning sketch:

```text
presentation-studio/
  package.json                 # independent dependencies and lockfile
  package-lock.json
  tsconfig.json
  vite.studio.config.ts
  vite.player.config.ts
  studio/index.html
  player/index.html
  public/decoders/              # only decoders actually supported
  src/
    core/                      # IDs, schema, validation, commands, units
    assets/                    # import, revisions, mapping, preparation
    presentation/              # pure path/timeline/reveal/photo evaluator
    render/                    # Three renderer, resources, styles, quality
    storage/                   # autosave and editable archive
    compiler/                  # public manifest and file-map compilation
    studio/                    # UI, navigation, inspectors and history
    player/                    # public controls, loader and input mapping
    workers/                   # bounded validation/packing/preparation jobs
  tools/                       # repeatable offline asset preparation
  tests/{unit,integration,browser}/
  fixtures/                    # small reproducible test inputs
  dist/{studio,player}/         # generated, ignored
```

`website/` remains the existing public frontend. Do not change its package files, routing, documentation importer, source manifest, build/export scripts, public assets, content or prototype folders. Do not put studio outputs inside `website/public/`. No common root dependency upgrade is needed. Any future link, embed or deployment integration is a separate task.

Local metadata inspected for this plan: [website README](../../../website/README.md), [website package](../../../website/package.json), [garden prototype README](../../../website/prototypes/scroll-garden/README.md) and [prototype package](../../../website/prototypes/scroll-garden/package.json). These document separate ports/builds and the prototype's Three.js 0.186.1 / Vite 8.3.4 pins; their runtime claims were not requalified here. The original research did not inspect local prototype source. Reuse must begin with source inspection and a specific reason to carry code across.

Use separate Vite configurations and output directories, a relative player base (`./`), and distinct dev ports such as 5190 for the studio and 5191 for the player. Keep the current site's 5178 and prototype's 5186 free. The [Vite production guide](https://vite.dev/guide/build.html) supports static output and relative base paths; dynamically constructed manifest/asset URLs still need resolution against the manifest URL. Recheck the selected Vite version's configuration API before writing config.

Pin Three.js, Vite, TypeScript and Node at implementation start. The observed prototype pins are starting candidates, not a requirement to upgrade other projects. Select a Node 22 LTS patch satisfying the selected tool versions. Use vanilla TypeScript UI modules and an imperative Three renderer initially; introduce a UI framework only for a demonstrated need. Select navigation, schema-validation, archive and test libraries after small API/compatibility checks; keep the project/evaluator interfaces independent of them.

The player build must not import studio modules. Build the player shell before the studio and provide its hashed files as an export payload. The browser does **not** run Vite: compiling a presentation validates the project, selects prepared assets, emits a public manifest and packages it with that prebuilt shell. Test the dependency graph and exported ZIP to exclude editor code, source maps containing private paths, editable originals, history and local project metadata.

## 4. Runtime and data contracts

Apply the relevant ideas from [engineering foundation](../../ENGINEERING_FOUNDATION.md): F01 ownership, F04 explicit dependencies, F05 complete publication, F06 bounded resources, F07 worker lifetime, F08 reuse, F10 units and F11 persistence. Native Max evidence does not qualify this browser implementation.

### Authored project

Use `schemaVersion: 1` for this independent browser format; it has no relation to Scatter schema 58. Allocate UUIDs for project, asset, asset revision, imported instance, layer, camera stop and segment records. File hashes identify content; they do not replace logical entity IDs.

| Record | Required fields and responsibilities |
| --- | --- |
| Project | Schema, project ID, revision, title, canonical units/up axis, asset references, layers, plan, presentation, output profiles |
| Asset revision | Logical asset ID, revision ID, source hash, source bytes, import options, extension/material report, bounds and resource estimates |
| Prepared derivative | Source revision/hash, preparation recipe/version, output hash, supported profile, node provenance mapping |
| Imported instance | ID, asset revision, root transform and node-to-layer membership |
| Layer | ID, display label/order, include-in-export, default visibility, viewer-toggle permission and reveal interval |
| Plan | Image hash/dimensions, two calibration correspondences, metric distance, transform and optional third-point residual |
| Stop | ID, world pose, projection/FOV, framing policy, hold timing and optional approved photo |
| Travel segment | ID, start/end stop IDs, Bézier controls, duration/speed setting and arrival/departure easing |
| Photo | Immutable image reference, aspect variant, caption, interpretation label, approved dependency fingerprint |
| Derived state | Bounds, path lookup, decoded assets and prepared render resources; rebuildable and excluded from undo snapshots |

Use metres and Y-up. Normalize unit/orientation/origin once at the import boundary, retaining the original asset and transform. Reject nonfinite or singular transforms. Imported GLB nodes are not edited in place; presentation overrides live in the project. The admin can place asset roots, but mesh topology/material authoring stays upstream.

### GLB admission and layer mapping

Support the static material/geometry subset proven by fixtures. Stage the candidate import before replacing the active scene. Validate glTF structure and declared required extensions, resource availability, finite bounds, counts, texture dimensions and estimated peak decoded resources. Initially accept self-contained GLBs; reject external-resource dependencies with a clear preparation instruction. Never fetch arbitrary URLs merely because an import references them.

Qualify base metallic-roughness PBR, alpha mask/blend, double-sided materials, texture transforms and unlit materials before advertising them. Meshopt, Draco, KTX2/Basis and GPU-instancing extensions are accepted only once their loaders, bundled decoders, metadata preservation and export roundtrips pass. Unsupported required extensions fail admission; unsupported optional appearance produces an explicit report, not a claim of faithful rendering. Animated, skinned and morphing inputs require an upstream static export for this MVP.

glTF has a node hierarchy, not a universal DCC layer format. Prefer persistent exporter metadata such as `extras.cyrus.entityId` and `extras.cyrus.layerId` when supplied; validate uniqueness. Otherwise show top-level groups and let the admin assign them. Store project UUIDs and a revision-scoped node table. Names are labels, never authoritative identity.

Every rendered primitive belongs to one effective presentation layer. Explicit child membership overrides inherited group membership; validation rejects conflicting explicit assignments. A shared source mesh can have multiple imported instances with independent memberships. Splitting/instancing/merging during preparation must preserve that ownership. Do not merge across visibility layers.

Recommended starting layers are Site, Paths, Building, Ground cover, Shrubs, Flowers and Trees. These are editable labels, not required hard-coded semantics. Imported point/line overlays get their own layers. A merged mesh spanning several requested layers must be split upstream or treated as one layer; the studio should explain the limitation.

### Asset replacement policy

Replacement is an explicit admin command against a selected logical asset, producing a new immutable revision. No automatic disk watching or silent same-name replacement.

1. Validate and prepare the replacement alongside the last complete asset.
2. Match unique persistent external IDs where available. Otherwise offer unique structural-path/name matches as **suggestions** requiring review; node indices are valid only within the original revision.
3. Show mapped, new, missing and ambiguous nodes with affected layers/reveals. Require complete resolution of references used by the presentation before commit/export.
4. Preserve project layer IDs and their settings only through the reviewed mapping. Unmatched new content enters an explicit unassigned group for the admin to resolve.
5. Keep the instance root transform and world-space camera stops. Never auto-fit/recenter a replacement silently. If a rebase is needed, make it a separate reversible command.
6. Commit model, resources and mapping together. Undo restores the previous revision and mapping. Failure/cancellation retains the old complete scene. Mark affected photos stale.

### Public visibility

`includeInExport` controls whether content is packaged at all. For included layers, evaluate:

```text
visible = timelineGate && (viewerToggleAllowed ? viewerChoice : defaultVisible)
```

Initialize `viewerChoice` from `defaultVisible`; it is session-only and resettable. This permits an initially hidden optional layer to be shown by the viewer. A reveal interval can still keep that layer hidden before its story stage. A toggle changes visibility and relevant shadows, without regenerating geometry or re-uploading unchanged static buffers. Layer controls display only meaningful public labels.

## 5. Authoring, camera and visual presentation

The interface has one active render viewport, a compact camera toolbar, a right camera inspector and a bottom saved-view strip. The left layer/asset tree opens through **Scene** and is closed by default. **Focus** temporarily hides both panels and the journey without modifying the project. Project/open/save actions and output/preview/export actions use separate compact menus. Provide visible mode and save/export status. Pointer drags capture the selected owner ID at gesture start and commit one undo item on release. Keyboard delete/undo cannot target a new selection accidentally after a panel rebuild.

**Explore** moves only the temporary editor camera. **Capture stop** creates an authored stop from it. **Update selected stop** replaces a specific stop intentionally. **Playback/compiled preview** uses the presentation camera and disables authoring gizmos. Leaving playback restores the prior editor view. Unsaved edits remain visible in studio status.

The implemented authoring workflow leads with **Camera → navigate → Capture view**. Focus-scoped WASD/drag-look and Q/E height let the admin compose directly through the viewport; Orbit remains available in the mode selector. A single top commit button captures successive new views, or becomes **Save view** after an explicit **Edit in viewport** action. Its named owner remains stable across saved-view selection changes; the dropdown also offers capture as a new view and finish editing. Captures include the actual perspective viewport aspect and lens. Numeric pose and Bézier controls are optional detail sections. Orthographic Plan cannot capture an unrelated hidden perspective camera, and navigation never commits a keyframe implicitly.

Use piecewise cubic Bézier travel segments with auto-initialized handles and editable plan/perspective handles. Store path geometry independently from timing. A shared adaptive arc-length table maps distance to curve parameter. Each segment has duration or desired average speed, gentle start/end easing, and an explicit constant-speed interior when selected. Holds are separate intervals. Reorder/delete rebuilds adjacency through one command and preserves unaffected stop IDs.

The evaluator returns camera pose/FOV, layer reveal values, style blend and eligible photo at any time. Orientation uses normalized quaternions with hemisphere continuity and SLERP; a look-target inspector resolves to an explicit orientation. Define safe behaviour for coincident targets, zero-length segments, repeated points and zero-duration intervals. Do not add hidden runtime obstacle steering. Studio path preview and admin inspection establish the intended route; automatic walkable-terrain navigation is deferred.

The public story has four authored phases: plan, group reveal, colour/full landscape, and the eye-level journey. Start from a clean calibrated plan image with optional imported boundary/point groups. Transition by fading this screen-space plan over an aligned overhead **perspective** scene, then continue into the camera journey. This avoids needing an orthographic-to-perspective camera morph in the MVP. The studio's top-down editing camera can remain orthographic. The admin previews the blend and adjusts alignment; automatic perfect image/3D correspondence is not promised.

Use a restrained monochrome scene style before colour, preserving original material resources for the final state. Qualify transparent foliage explicitly; use canopy/group appearance or authored proxies rather than per-leaf wireframe. Reveals operate through layer visibility or a supported presentation material parameter; no plant growth simulation is required. Any shader-driven clipping requires deliberate cap/alpha limitations in preview.

Native scroll maps to timeline position. Start with direct progression; if damping is needed, use elapsed-time-based smoothing and stop scheduling frames when settled. A hold occupies scroll distance but does not force the viewer to wait. Autoplay observes actual hold duration and stops when the tab is hidden. Add keyboard/button stop navigation, play/pause and restart. Public free-orbit navigation is deferred to keep photographic and authored framing predictable.

Use authored landscape and portrait framing records where supplied. Otherwise preserve the authored composition with a fitted presentation viewport and neutral letterboxing. Do not silently crop a building or change FOV for a phone. Reduced motion uses discrete stops, no automatic travel and an immediate or minimal crossfade. A visible control can select this mode regardless of the system preference.

### Artistic-photo policy

The admin imports approved images; no generation service is part of this MVP. Public copy identifies them as **Artist impression**. Artistic freedom is allowed, while the editor tracks which scene state they were approved against.

Fingerprint stop pose/FOV, aspect framing, included scene revisions/transforms, layer visibility, material/style and lighting. Timing-only changes do not stale the photo. Conservatively include all scene layers in the MVP fingerprint; later work may narrow dependencies. Replacing content or changing the relevant composition marks the photo stale. The admin must explicitly approve it again or replace it before it can be included in a new export.

Fade an image in only within its stationary hold and fade it out before movement. If a viewer changes any relevant layer, immediately reveal 3D and apply the toggle together; suppress the image while the viewer state differs from the approved state. Restoring the approved visibility allows the image again through the normal hold evaluation. A failed or pending image load leaves 3D visible. Mobile variants preserve an approved crop; default to fitting rather than automatic cropping. Lazy-load current/next images and release decoded images beyond a bounded cache.

## 6. Save, compile, preview and export

The editable archive and the public package are distinct formats:

```text
project.cyrus-presentation.zip       presentation.zip
  project.json                        index.html
  assets/originals/<hash>.*            manifest.json
  assets/prepared/<hash>.*             runtime/<hashed-player-files>
  plans/<hash>.*                      assets/<prepared-hash>.*
  photos/<hash>.*                     photos/<prepared-hash>.*
  provenance.json                     decoders/<required-files>
                                      notices.txt
                                      README.txt
```

The project archive preserves originals, calibration, IDs, asset mappings, editable stops and photo approvals. Prepared derivatives are optional if rebuildable. The public manifest contains evaluated presentation data and prepared resource references, without editor history, originals, local paths or private settings. A read-only player means no editing UI; downloaded browser assets are still accessible to the recipient.

Autosave uses IndexedDB transactions for metadata and a committed revision pointer, with content-addressed blobs in OPFS when available and an IndexedDB blob fallback. Write blobs before switching the pointer. Autosave failure preserves the last committed revision and reports that state. Browser storage availability/quota is checked; offer portable archive export immediately if storage is unavailable. Closing and reopening from the portable archive is a release gate.

Importing an archive validates schema, paths, counts, expanded byte limits and hashes before activation. Reject traversal, unsupported schema and corrupt resources; keep the open project unchanged. Missing blobs produce a recoverable diagnostic without guessing a same-name replacement. Undo references immutable asset revisions; cap retained history by estimated bytes and explain when the oldest entries are pruned. Explicit archive save is the durable backup operation.

Compilation is a deterministic pure transformation for fixed inputs/tool versions: validate references and photo state, select the output profile, resolve prepared assets, emit the public manifest and build a file map. Volatile timestamps stay outside content-hashed payloads. Schema/player compatibility and resource hashes are checked by the player loader.

Compiled preview runs the **same built player entry and manifest parser** in an isolated iframe, supplied the compiled file map through a bounded resource resolver. Studio preview can resolve resources to owned blob URLs; exported playback resolves them relative to the manifest over HTTP. Both paths share validation and evaluation. Suspend the editor renderer while preview runs, and revoke URLs/dispose resources when leaving. Do not create a second mock playback engine.

Validate the iframe message origin, sender and session token; accept data only through the defined manifest/resource protocol. Imported labels and captions render as text. An archive supplies data and supported media, never executable HTML or JavaScript. Add malformed-message and hostile-label cases to the compiler/player tests.

Pack the ZIP in a worker with cancellation/progress and explicit size admission. Start with a 250 MiB compressed archive admission ceiling and a separate 512 MiB expanded byte ceiling, subject to decoded CPU/GPU estimates and available headroom; these are protective starting settings, not capacity promises. Large scene preparation belongs in repeatable offline tools before import. If browser packing cannot fit admitted headroom, reject with actionable preparation guidance and preserve the project rather than starting an unbounded attempt.

Serve export validation through a local HTTP server, including `/presentations/example/`, with network requests audited for missing resources and external services. Include plain instructions to unpack and upload to static hosting. The export contains no API secrets or authentication. The admin studio runs on loopback only during this MVP; exposing it publicly would require a separate server-side access design. A frontend-only password is not the access boundary. The public player remains independently hostable.

Commercial licensing is deferred. Retain ordinary required third-party notices for selected dependencies; do not add activation, account billing or native licensing integration.

## 7. Rendering and performance acceptance

Initial target: a mainstream integrated-GPU laptop and mainstream phones capable of WebGL2. Qualify the current stable Chrome/Edge/Firefox desktop engines and Safari on selected Apple devices at the test date. Browser syntax compatibility from Vite is not a graphics-capacity promise. Record exact devices before declaring support. Studio authoring is desktop-first; mobile qualification applies to the player.

Use capability detection, bounded texture dimensions and a poster/static-stop fallback for unsupported WebGL2 or unrecoverable resource failures. Keep layer controls unavailable when the fallback cannot faithfully show those layers, with a clear state message. Context restoration rebuilds from retained prepared data and resumes at the same timeline position/visibility state.

Demand-render the static scene. Only timeline input, active transitions, control motion, resource completion, resize and relevant state changes request frames. Visibility does not trigger geometry generation. Reuse identical source geometry/materials and preserve imported instancing; add deterministic repeated-node instancing only when provenance and layer ownership remain intact. Compute bounds and use frustum culling. Add spatial chunks for repeated foliage after measuring the medium/large fixtures; chunk size cannot affect authored transforms or IDs.

Ship a default Balanced profile and a Mobile profile. Both preserve plant count, species, placement, layers and timing. Profiles may change render scale/DPR cap, shadow distance/resolution, postprocessing and approved mesh/texture derivatives. Use a maximum DPR of 1.5 for the initial Balanced trial and 1.0 for Mobile; tune from evidence. Adaptive quality changes only these display settings using sustained thresholds and hysteresis. No automatic density thinning.

| Gate | Balanced desktop | Mobile | Interpretation |
| --- | --- | --- | --- |
| Frame cadence | 60 Hz; p95 interval ≤16.7 ms | 30 Hz; p95 ≤33.3 ms | Physical-device trace; investigate percentile noise and dropped frames |
| CPU / GPU work | ≤6 / 10 ms per frame | ≤8 / 20 ms | Independent measurements where GPU timing is available |
| Input response | Camera ≤50 ms; layer action ≤100 ms | ≤100 / 150 ms | Input to visible update |
| Static idle after settling | 0 renders, 0 scene rebuilds, 0 unchanged buffer uploads over 10 seconds | Same | Instrumented counters plus trace |
| Camera-only journey | 0 scene rebuilds and 0 unchanged geometry/instance-buffer uploads | Same | Separate this from normal uniforms/LOD selection |
| Steady estimated GPU allocations | ≤384 MiB | ≤192 MiB | Estimate buffers/textures/render targets; not a browser limit |
| Application CPU working allocation | ≤768 MiB | ≤256 MiB | Player target; report decoder peaks separately |
| Critical initial transfer | ≤4 MB compressed | ≤4 MB compressed | Useful plan/poster and controls; complete 3D readiness measured separately |
| First usable opening | ≤5 seconds at 10 Mbps, 80 ms latency | Same | Cold cache, controlled network; show 3D loading progress |
| Photo delivery | Prepared, lazy-loaded | About 0.5–1 MB each | Quality reviewed; not all original PNGs at startup |

The [research](RESEARCH_2026-10-15.md#12-benchmark-and-correctness-protocol) explains these unmeasured starting targets. A useful opening is not a claim that all 3D assets loaded in five seconds. Record time to first complete 3D frame, total transfer, decode peaks and ten-minute thermal performance separately. If a representative fixture misses a gate, optimize or narrow the qualified profile explicitly before release.

For initial admission, estimate old-plus-new resources, decoder scratch space and image decode peaks. Permit one heavyweight import/replace/export preparation job at a time. Workers use job IDs, project revision and dependency hashes; stale completion cannot commit. Cancellation should acknowledge within 100 ms between bounded work units; expose any uninterruptible third-party decode limitation. Failed GPU preparation retains the old scene and disposes the failed successor.

## 8. Implementation sequence and reviewable gates

The stage requirements below remain the broader release acceptance contract. The current authorized local MVP is implemented and browser-tested using the user-selected prior model. Physical device/customer-asset qualification and the independent admin publishing walkthrough remain later acceptance work. See [the stage-by-stage evidence](PROGRESS.md). These stages are this browser MVP's plan, not native Scatter's P01–P11 phases.

| Stage | Concrete work and module ownership | Exit gate |
| --- | --- | --- |
| S0 — Fixtures and contracts | `core/`, `fixtures/`, test harness: schema, ownership, supported GLB subset, source hashes and selected physical devices; record dependency pins | Hand-authored example project/manifest validates; golden IDs/units and budget expectations agreed from fixtures |
| S1 — Isolated player vertical slice | Separate Vite configs, `player/`, `render/`, initial `presentation/`: one prepared layered scene, plan opening, three fixed stops, layer controls | Standalone built player works at a nested HTTP path; website file hashes unchanged; static idle counters pass |
| S2 — Import and editable studio | `assets/`, `studio/`, commands/history: GLB staging, calibration, hierarchy, explicit layers, root transforms, replacement review | Import/replace/undo and invalid-input cases preserve ownership and prior scene; no hidden changes from browsing/selection |
| S3 — Camera and reveal authoring | `presentation/`, timeline/inspectors: capture/update/reorder/delete, Bézier handles, arc length, holds, reveal controls, reverse seeks | Direct-time and sequential evaluation agree; constant-speed interior within 2%; Explore never edits stops; one gesture equals one undo |
| S4 — Photos and responsive playback | Photo fingerprints, approvals, aspect records, public scroll/buttons, keyboard and reduced motion | Movement removes photos; toggles reveal correct 3D; stale photos excluded until approval; portrait/reduced-motion fixtures pass |
| S5 — Persistence and actual export | `storage/`, `compiler/`, `workers/`: transactional autosave, portable archive, deterministic manifest, compiled preview and ZIP | Cold archive reopen; extracted artifact runs without studio/network services; resource hashes, public-only contents and preview parity pass |
| S6 — Measured asset/render optimization | `render/`, `assets/`, `tools/`: resource accounting, supported codec preparation, bounds/instancing/chunking where justified, quality profiles | Medium fixture meets selected-device gates; large fixture records limits; authored counts/positions/layers unchanged across profiles |
| S7 — Failure and delivery qualification | Integration/browser tests, traces, repeat lifecycle, export docs and evidence | Corrupt/missing assets, quota failure, stale jobs, context loss and failed replacement recover; independent user walkthrough succeeds |

S1 uses a small fixed fixture to prove the public output early; it is not the finished product. S5 is required for an MVP delivery. Add codec or chunk complexity in S6 only where the selected fixtures justify it. Do not postpone basic resource disposal, bounds or cancellation architecture until S6/S7; those contracts begin in S1/S2.

Planned scripts within the new app: `dev:studio`, `dev:player`, `typecheck`, `test:unit`, `test:integration`, `test:browser`, `build:player`, `build:studio`, `build`, `verify:export`, and `prepare:asset`. Define them during implementation; they do not exist as a result of this plan. `build` produces the player payload before the studio. `verify:export` consumes an already compiled ZIP and verifies its contents and HTTP behaviour. Asset preparation records source hash, tool versions, settings and derivative hash.

## 9. Fixtures and required evidence

Use redistributable or owned disposable assets; preserve `Test Scene/`, artist files and all existing website work. Store small generated fixtures in the app, with large binary fixtures in a documented ignored location plus hashes and reproducible preparation instructions.

| Fixture | Proposed contents | Required observations |
| --- | --- | --- |
| Tiny correctness | Several nodes including duplicate names, shared geometry, nested layers, two imported instances, three stops and two photos | Identity, overrides, root transforms, mapping, timing and photo rules |
| Medium landscape | Starting envelope around 100 × 100 m; building, paths and several foliage layers; roughly 2,000 prepared plant instances if suitable source assets exist | Baseline load, full journey, idle, layer toggles, portrait and export parity |
| Large stress | Starting envelope around 500 × 500 m with roughly 10,000–25,000 prepared repeated plants and long sight lines | Culling, overdraw, memory, import/export admission and graceful rejection; no advertised capacity inferred |
| Material/format | Alpha foliage, double-sided cards, transparent surfaces, unlit/PBR, supported compressed assets, missing/unsupported extensions | Faithfulness, explicit rejection and decoder packaging |
| Failure/lifecycle | Truncated/corrupt GLB/archive, missing blobs, extreme bounds, oversized images, forced job reordering/quota failure/context loss | Prior project retained, recovery and bounded resource growth |

Dimensions/counts are fixture proposals, not user-provided site measurements. The medium fixture takes priority; make the large fixture harder without turning it into a promise to render arbitrary landscapes. A plant count is only useful alongside mesh, material, texture, view and device data.

Minimum automated checks:

- Schema roundtrip; immutable original hashes; metric calibration and nonfinite/singular transform rejection.
- Nested layer resolution and independent shared-mesh instances; viewer visibility formula and excluded-layer asset pruning.
- Replacement with duplicate names, reordered nodes, missing IDs and ambiguous matches; explicit reviewed mapping and undo restore the correct content.
- Arbitrary-time/reverse camera evaluation, endpoint/hold behaviour, arc-length speed error, zero-length segments and quaternion continuity.
- Photo dependency invalidation, timing-only stability, visibility mismatch, delayed load and portrait fallback.
- Project archive integrity, expanded-size bounds, path validation, incompatible schema, quota/commit failure and fresh-profile reopen.
- Stale job rejection and cancellation; failed resource creation before/after publication; reference-counted disposal through repeated imports and preview changes.
- Compiled preview versus extracted export at fixed times, viewport and visibility states: equal evaluated values and reviewed screenshot differences with declared raster tolerances.
- Public bundle excludes editor/private resources; all URLs work under a nested path; offline network isolation after serving local files; keyboard/reduced-motion behaviour.

Use unit tests for pure contracts, integration tests for commands/storage/compiler and browser tests for the actual studio/player. At S6/S7, supplement automation with real-device traces and visual review of alpha foliage, shadows and image transitions. Do not label emulated mobile results as physical-device evidence. Version/file hashes, device/browser details, settings, failures and remaining limits belong beside this plan in a delivery evidence record when execution actually happens.

The release walkthrough is complete only when the admin can save/reopen and produce a correct standalone artifact, then a viewer can run it without the studio, navigate the journey and toggle permitted layers. Implementation source alone is insufficient. No native Max test, installer or Scatter version change is part of this independent browser MVP.

## 10. Planning evidence and implementation handoff

The original planning pass used the saved external research, repository guidance and local website/prototype metadata described above. The knowledge service's full-source check reported **stale evidence** for its bound corpus; direct inspection of the engineering foundation was used for the applicable contracts. The corpus was not refreshed or altered. No runtime/performance qualification occurred during that initial documentation-only pass; subsequent implementation and browser evidence are recorded in [PROGRESS.md](PROGRESS.md).

Planning checkout: branch `codex/workflow-0.75`, HEAD `604e3aa3fd1c84c5ef128dc564f4abaf6f4978e4`, with substantial pre-existing tracked and untracked work. Local observations refer to that working tree, not a claim that HEAD alone contains those changes. This documentation task preserves that work and does not create a commit or release.

The remaining qualification inputs are representative artist source assets and exact physical test devices. Owned synthetic and opt-in Khronos fixtures now cover software contracts; select real medium/large landscapes before claiming their quality or capacity. These inputs did not block implementation of the isolated MVP.

Continue from [PROGRESS.md](PROGRESS.md) for current source, commands, artifact identities, measured limits and next acceptance work. Keep this as the single maintained plan for the presentation MVP; retain the dated research as its rationale. No commit, push, native installation, website integration or deployment has been performed for this browser delivery.
