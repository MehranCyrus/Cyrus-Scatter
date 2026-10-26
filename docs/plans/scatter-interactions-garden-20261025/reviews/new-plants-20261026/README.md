# New Plants scene — Interactions review

26 October 2026 · Scatter **0.87.3 / schema 61 / Interactions capability 2** · **Max 2027 only**

The user requested investigation and written recommendations, with no plug-in changes. This is a diagnostic report, not a fix delivery or acceptance of these plants. Product code, installed payloads and the original scene were left unchanged. Tests used an isolated Max process and a copied scene; temporary diagnostic settings and control meshes were never saved back.

## Assessment

This scene exposes a substantial gap in automatic plant preparation, plus two reproduced correctness defects. **None of its ten plant models prepares successfully at the default 5 mm / 5% settings.** All ten also fail at 1 mm and 10 mm with 5% preview. Their evaluated geometry is within the current source admission, their source transforms are positive uniform identity scale, and their physical preparation settings are valid. Lower polygon counts alone will not solve this scene.

The most urgent defect is geometry-cache contamination between visual sources and collider proxies. A second defect rejects the advertised 1% preview boundary. The saved sphere also uses a lower-trunk approximation instead of its spherical surface. These are separate from unsupported plant topology and should not be combined into a generic units or performance diagnosis.

Normal scattering works in the copied scene when React is disabled: an explicit Update publishes **one grass and one sphere**, with no layer errors. Enabling React without an accepted plant definition prevents the attempted combined publication. The safety rejection is appropriate; the workflow needs to identify and resolve that condition before enabling React.

## Scene and execution identity

| Item | Evidence |
| --- | --- |
| Original scene | `F:/Cursor/_Cyrus_Apps/CyrusScatter/Test Scene/New Plants test.max` |
| Scene size | 271,441,754 bytes |
| Original and copied input SHA-256 | `62af55f1b9f8c826aa0b07261e11b706e71aaa6cc2ffa87b5e1a7e9d41c75399` |
| Checkout HEAD at review start | `2a68691da59e80d6d24ea248d8e386b836883dae` |
| Branch | `codex/workflow-0.75` |
| Runtime script SHA-256 | `4c192c5f9b61c964cdaa93229f0c5f9135437ffe3a47170049bab23f64ffb05a` |
| Loaded script fingerprint | `e59632c4888424a5a4f696d97fd29d48935771a7e57114fa6d60540940d4df18` |
| Loaded `AminScatter.dlx` SHA-256 | `616693be6623a8d7bf6db71335a670198b8aeca15886d30b541ae9bb760faca0` |
| System units | 1 unit = 1 cm; 0.01 metres/unit |
| Actual preparation minimum | 0.005 m, approximately 5 mm; schema-61 SI field is authoritative |
| Saved preview fraction | Approximately 0.05, or 5% |
| Plant sources | Ten Editable Poly objects; 800,139 vertices / **1,194,050 evaluated triangles** in total |
| Largest individual source | Brainea: 377,133 vertices / 593,787 evaluated triangles |
| Owned evidence | `build/new-plants-review-20261026-01/` |

The native source limit is **per source**, 1M vertices / 2M triangles. No plant reaches it. Max's `getPolygonCount` on these Editable Poly objects reports polygon faces; the table below uses the actual triangulated native snapshots. For example, the active wild grass has 14,291 polygon faces but **27,501 evaluated triangles**.

Other work already exists in this checkout, including Arrange, Physics Lab, MCP and website prototype changes. Those files were not modified by this review. Source hashes, loaded module paths and preservation results are retained in [the evidence manifest](evidence/review-manifest.json).

## Plant results

Names below omit the common `Outdoor_Plants_01_` prefix. Heights are source-local physical bounding-box heights, before random scatter scaling. Pieces mean topologically connected mesh components, not botanical roots or simulated guides.

| Source suffix | Vertices | Evaluated triangles | Height | Pieces | Default preparation result |
| --- | ---: | ---: | ---: | ---: | --- |
| Rhapis_Excelsa_Small02_001 | 100,163 | 142,403 | 1.173 m | 3,216 | Blade fallback exceeds 2,048 groups |
| Neottopteris_Nidus_Bush_Decorative05_001 | 38,818 | 50,382 | 0.774 m | 2,079 | Blade fallback exceeds 2,048 groups |
| Neottopteris_Nidus_Bush05_001 | 125,845 | 183,030 | 1.618 m | 4,756 | Blade fallback exceeds 2,048 groups |
| Dipteris_Conjugata_Small03_001 | 58,750 | 111,172 | 0.717 m | 150 | Does not fit ordered three-vertex blade sections |
| Brainea_Insignis_Fern_Medium03_001 | 377,133 | 593,787 | 1.471 m | 9,401 | Blade fallback exceeds 2,048 groups |
| Lemon_Balm_rly_001 | 7,030 | 12,192 | 0.069 m | 120 | Does not fit ordered three-vertex blade sections |
| Lemon_Balm_rly3_001 | 4,254 | 7,630 | 0.045 m | 56 | Does not fit ordered three-vertex blade sections |
| Grass_Wild_QMH_001 | 22,032 | 27,501 | 0.096 m | 566 | Blade sections are not connected in authored vertex order |
| Grass_Wild_QMH2_001 | 11,900 | 14,887 | 0.064 m | 300 | Blade sections are not connected in authored vertex order |
| Carex_Elata_Aurea_Grass_001 | 54,214 | 51,066 | 0.472 m | 1,574 | Does not fit ordered three-vertex blade sections |

Evidence: [all source runs](evidence/all-plants.json), [1 mm / 10 mm controls](evidence/followup.json), [copied geometry audit](evidence/geometry-audit.json). The active grass was also tested through the actual `interactionsAnalyze` authoring method, reproducing its vertex-order error: [workflow controls](evidence/workflow-controls.json).

## Reproduced findings

### 1. Collider mode changes can reuse the wrong geometry — correctness defect

With earlier immutable captures retained, these native requests produce:

| Request sequence | Requested final geometry | Actual final snapshot |
| --- | --- | --- |
| Saved sphere custom proxy → Closed source mesh | Sphere, 482 vertices / 960 triangles | **34 vertices / 64 triangles**, identical proxy fingerprint |
| Fresh control sphere Closed source → Bounding box → Closed source | Sphere, 482 vertices / 960 triangles | **8 vertices / 12 triangles**, identical box fingerprint |

The returned information says `proxy_mode: 1` despite retaining proxy geometry. This is not merely an overlay or stale caption: exported numeric mesh counts verify the mismatch. See [cache controls](evidence/cache-controls.json) and its snapshot headers in the evidence manifest.

A separate known-supported blade prepares successfully, then fails the same preparation request after a retained box-collider capture, reporting a blade-profile error. This reproduces the effect on plant preparation as well as collider shape switching: [role/cache control](evidence/role-cache-control.json).

Source cause: [`interactions_host.cpp`](../../../../../AminScatter/src/interactions_host.cpp), especially `capture`, `captureCollider` and the shared `sourceCache`. Both caches use the visual node handle. `captureCollider` can store a proxy-only mesh there. `capture` treats a valid visual watcher and matching units as sufficient to copy `old->mesh`, even when that mesh represents a separate proxy or a bounding box. Its fast-return proxy comparison does not protect this later mesh-copy branch.

**Recommendation:** distinguish full visual mesh capture from proxy/box capture in storage and freshness checks. A full-source request must obtain the visual geometry; preparation must never consume a proxy-only capture. Retain per-source sharing, bounded memory and immutable generations. Test every mode transition with previous generations alive, including Collider → React, custom-node edits/deletion, Undo and reload. Comparing UI mode numbers alone is insufficient.

### 2. Automatic preparation depends too strongly on export topology — support limitation

The current analyzer recognizes a small set of layouts using component counts, ordered vertex rings and specific cross-sections. When it finds no supported tubes it tries the whole source as ordered three-column grass. A fern or palm can therefore receive a grass-specific error.

Source owners: [`analysis.cpp`](../../../../../CyrusVegetationLab/experiments/stem-live/analysis.cpp), [`connectivity.cpp`](../../../../../CyrusVegetationLab/experiments/stem-live/connectivity.cpp) and [`interactions_source.cpp`](../../../../../AminScatter/src/interactions_source.cpp).

Concrete observations:

- Carex consists of 1,574 small components, with 30–40 vertices and 28–38 triangles each. These strip-like pieces do not match the supported three-column blade layout. Their exact botanical guide directions have not been inferred or reviewed.
- The wild grasses contain repeated 52-vertex and 15-vertex pieces. At least one component passes the fallback's count test and then fails its authored-order connectivity test. Lowering the minimum stem length does not correct that ordering.
- Fern/palm sources contain many separate foliage pieces. The fallback labels every connected piece as a prospective rooted blade before applying the 2,048 limit. Its error therefore does **not** establish that the plant has thousands of botanical roots.
- The small Lemon Balm variant fails with only 7,630 evaluated triangles. Polygon admission is not the underlying obstacle.

An offline exact-position merge reduced Brainea from 9,401 to 7,377 components and the decorative Neottopteris from 2,079 to 2,047. The grasses, Carex, Dipteris and Lemon Balm component counts did not change. This diagnostic did not modify any source or prove a prepared rig. Blanket welding would not solve the scene and could join adjacent leaves incorrectly. No raw component mixes material IDs, and no unused vertices were found; neither is the demonstrated primary cause here.

**Recommendation:** introduce explicit preparation profiles for ribbons/grass, basal broad leaves, branching herbs, fern fronds and palm structures. Infer ordering from connectivity and shape rather than imported vertex numbers. Separate structural guides from attached leaflets/patches before counting roots. Use material IDs as optional hints, not a required naming convention or guaranteed botanical classifier. Preserve original topology, UVs, normals and a verified deformation binding.

Always offer an authored spline/root-marker fallback when automatic confidence is insufficient. The current advice that a model “needs authored guides” has no general artist-facing import/repair workflow in Scatter. Ambiguous guides must remain reviewable and blocked from contact publication until accepted; do not relax parent/root checks merely to force success.

### 3. The advertised 1% preview value is rejected — numeric boundary defect

The scripted settings accessor admits 1%, but its saved/native float is `0.009999999776482582`. Native analysis compares that promoted value against the double literal `0.01` and rejects it. The diagnostic misleadingly prints a valid-looking `5.000000 mm / 1.000000%` range error.

A fresh known-supported, nine-vertex blade isolates this from imported plant topology:

| Preview | Result |
| --- | --- |
| 5% | Prepares: one guide, one root |
| **1%** | Rejected by native setting validation |
| 1.00001% | Prepares |
| 25% | Prepares |

Evidence: [native control](evidence/cache-controls.json) and [scripted accessor control](evidence/followup.json). Source: settings conversion in `interactions_host.cpp` and strict `foliageFraction < .01` in `analysis.cpp`.

**Recommendation:** define consistent representable endpoint semantics across UI, persistence and native validation; normalize/tolerate bounded float roundoff without accepting genuinely invalid settings. Check both boundaries, settings roundtrip and different system units. This is an additional discovered defect; the supplied scene saves 5%, so it does not explain its default topology failures.

### 4. React can be enabled before any model is ready — workflow gap

The first layer saves React enabled but has no accepted definitions. Update records `Analyze and accept guides for Outdoor_Plants_01_Grass_Wild_QMH_001 before enabling React to colliders.` in **both** layer preview errors. The root status still says no active contact result. In this isolated load no complete result existed to retain; generated counters stayed zero. Disabling React and updating publishes one placement in each layer.

Evidence: [follow-up](evidence/followup.json), [workflow control](evidence/workflow-controls.json). Source: [`interactions-authoring.ms`](../../../../../AminScatter/tools/ui/templates/interactions-authoring.ms), `interactionsSources` / `interactionsStage`, and [`interactions-ui.ms`](../../../../../AminScatter/tools/ui/templates/interactions-ui.ms), the React handler.

**Recommendation:** preflight all unique sources when enabling React. Show per-source Ready / Needs review / Unsupported / Missing proxy states and the failing layer/source. Provide Analyze all, inspect failure components and an explicit way to disable unsupported participation. Preserve atomic publication and the previous complete result; do not silently omit failed plants or publish partial contact results.

### 5. A lower-trunk proxy is assigned to the sphere — configuration and guidance problem

The sphere is approximately **35.97 cm in diameter**. Its saved closed proxy is only **7.02 cm wide and 12.59 cm tall**, occupying local Z approximately **−17.99 to −5.40 cm**. That proxy describes the lower portion of a sphere as if it were a trunk; most of the visible sphere has no matching collision volume. The sphere node is centered at ground Z=0, so its visible lower half is below that plane. Confirm the intended placement before interpreting root coverage.

The closed proxy is admitted successfully. Admission proves valid collision geometry, not agreement with the visible object. Selecting Closed source should use the sphere's surface, but finding 1 must be corrected before mode switching can be relied on with retained captures.

**Recommendation:** use clear shape choices and sensible primitive defaults: full source / fitted trunk / authored proxy / conservative box. Warn when fitting a trunk to a sphere or when proxy coverage differs drastically from the intended visible region. Always allow reviewing the actual collision geometry at a scattered instance. A trunk-quality slider alone would not correct this shape mismatch.

### 6. Replaced-source bindings need clearer inspection — usability issue

The first layer now uses wild grass but still stores a collider binding for a previous Dipteris source ID. The current identity lookup correctly resolves **no proxy** for the grass. This retained link is not the grass preparation failure and should not be automatically transferred by name or proximity.

**Recommendation:** list active and unused source bindings, provide an explicit cleanup action, and explain which role/settings apply to the current source. Preserve the existing stable source IDs and deliberate retention policy.

## Recommended implementation sequence

These are proposals for the next authorized task; no implementation has started.

1. **Correct the two reproduced defects:** separate visual/proxy cache provenance and repair the 1% validation boundary. Add focused transition and endpoint tests, including a previously supported blade after a collider-role change.
2. **Make readiness and failures understandable:** per-source preflight, stage-specific diagnostics, persistent analysis reports even on rejection, problematic-component overlays and complete-result retention. Keep collider shape fitting separate from plant guide preparation.
3. **Expand preparation using this fixed ten-asset corpus:** start with Carex and the two wild grasses, then the two Lemon Balm variants, then Dipteris and the fern/palm sources. Use topology-based guide reconstruction and an artist guide-authoring fallback. Each profile needs reviewed roots, attachments and deformation bindings, rather than an asset-name special case.
4. **Keep the runtime efficient:** analyze each unique original prototype once; reuse definitions across instances with separate poses. Cache keys must include geometry identity, units, profile/settings and producer version. Use a nearby-instance index and conservative plant reach for contact updates; moving a collider must invalidate its previous and new affected regions. Benchmark actual cold preparation, warm edits, affected counts, memory and output costs separately.
5. **Separate lighter display from rig correctness:** low-detail preview and collider proxies are useful independent products. Decimation is not botanical skeleton extraction. Changing a display percentage should ideally not require reviewing roots again; current source code includes foliage fraction in accepted definition/cache settings, so that separation needs an explicit design. Keep full render geometry and verified binding intact.

The existing exposed-tree-root generator work remains on hold. This review does not resume B40 or promise automatic support for every plant or arbitrary tree dynamics.

## Acceptance before a future delivery

- The cache controls must return actual sphere triangles after proxy → source transitions and use visual geometry for plant preparation, with old contact generations retained.
- 1% and 25% must survive UI entry, serialization and native preparation; invalid and nonfinite inputs must still reject.
- Each of these ten source files must have an explicit profile/result. Successful numeric preparation alone is insufficient: inspect roots, parent direction, leaflet attachment and the full visible mesh during contact.
- Prepare each unique geometry once; verify rotated/scaled instances stay independent. Keep positive uniform scale restrictions explicit until additional transforms are supported and tested.
- Exercise actual source changes, relevant Undo/Redo, save/reopen, collider movement through Cyrus Edit, retained old results after failure and unrelated scene actions that must not rebuild placements.
- Record full-mesh penetration, root drift, stem/leaf strain and measured update costs. A valid mesh count, fast rejection or script/native unit test is not natural-bending or presented-FPS acceptance.

## Evidence and limits

Raw host and numeric evidence is retained under `build/new-plants-review-20261026-01/`. The small JSON records copied into [evidence/](evidence/) contain identities, asset measurements, exact errors and control outcomes; original model meshes and `.max` files are not copied into documentation or Git.

The knowledge generation `637cdc784e7dba8eab31f2703578abc9011bd792d70fa553095aa37fd1b4613a` verified all 64 enrolled parent files before investigation. Retrieval supplied historical support limits and current source routing; direct inspection and this Max 2027 run establish the findings here. No index refresh or activation was performed.

No plant in this corpus reached accepted contact fitting, so this review does not claim successful bending, drag performance, renderer fidelity or general root correctness for these assets. No physical pointer/viewport acceptance is claimed. One attempted screenshot of the hidden owned window returned unrelated foreground pixels and was excluded from evidence; no input was sent to the artist window. The existing 0.87.3 payload was used unchanged; no product rebuild, installation, version change, Git commit/push or website update was performed.
