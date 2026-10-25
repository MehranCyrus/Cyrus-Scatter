# Shared library readiness after the 0.87.0 changes

25 October 2026. Source inspection and planning update only. No build, test,
Max session, asset migration, installation or plugin implementation was performed.

**We are ready to implement the shared-storage foundation.** The recent work
does not invalidate one managed store, reusable model/image objects, immutable
recipe revisions or collection sharing. It does affect the integration contract:
the current host uses schema 60, Interactions has additional authored data, and
MCP now has independent catalog readers and retained prepared-package snapshots.
The existing native `.max` model import also has an open Undo-history defect.

The [implementation plan](SHARED_LIBRARY_IMPLEMENTATION_PLAN.md) now records these
integration requirements. Its first supported ten-look case remains ordinary
static planting. Saving a complete Interactions setup requires an explicit
portable adapter; storage reuse by itself cannot supply that missing behavior.

## What was compared

- Original investigation: branch `codex/workflow-0.75`, HEAD
  `7d5fd264f8c39e306389977d1eda7c4f358bd3c8`, plus the then-existing working changes.
- Current branch: `codex/workflow-0.75`, HEAD
  `588abff0ce211d7dc63798b8c5310631895465c7`. The intervening commits deliver
  0.86.9 and 0.86.9.2; current 0.87.0/MCP development includes existing tracked
  and untracked work beyond that HEAD.
- Current README points to the [0.87.0 artist trial](../scatter-interactions-garden-20261025/DELIVERY_0870.md),
  scene schema 60, unchanged native Edit storage 2, Analyzer 0.14.2 and content
  0.86.7. Its qualification limitations remain the delivery report's claims;
  this inspection did not reproduce those results.
- Relevant source, diffs, new headers/modules and current handoffs were inspected
  directly. `knowledge_status(verify_sources=true)` returned `stale_evidence` for
  generation `8a58031bf6efb27cf7c8e30a81d6059206b292269b5e5e24bf1045b704989059`.
  The exact-symbol search for `CyrusRecipeCapture` returned no enrolled hit.
  No knowledge refresh was performed.
- Arrange, Physics Lab and other unrelated changes were inventoried for ownership
  and left outside this library review. This is not a general plugin code audit
  or certification of the entire working tree.

## What changed and how it affects the library

| Change | Current source evidence | Effect on the planned library |
| --- | --- | --- |
| Edit/panel corrections in 0.86.9/0.86.9.2 | Committed Edit and generated-UI changes; library version/assembly guards updated | Preserve source identities and the matching runtime pair. They do not require a different disk-storage design |
| Interactions, schema 60 | `interactions-authoring.ms` appends layer roles/settings and accepted source definitions; `unified-core.ms` reads 59/60 and retains the explicit 58 upgrade gate | Rebase host assumptions to 60; preserve the supported preceding-scene path rather than reverting to 59 |
| Explicit recipe portability restriction | `recipes.ms:234` rejects selected layers with Collider, React or retained preparation IDs; Apply Style has a matching guard at line 827 | A prepared model can block recipe capture even when its active role switches are off. Do not advertise those setups as portable |
| Native recipe codec is still 8 | `recipes.ms:258` writes portable `sceneSchema:59`; current `recipes.cpp` validates that existing contract | Host schema 60 and portable recipe 8/59 are distinct. Blindly changing a version field would break compatibility rather than add the missing settings |
| Independent recipe/preset catalog owners | `recipe_library.h::Catalogs`, `recipe_library.cpp::Catalogs::open`, native catalog APIs | The new store needs a shared metadata provider usable by gallery and independent readers. Preserve owner isolation, cancellation and separate consumer limits |
| Retained prepared-package snapshots | `prepared_package_leases.h`, `recipes_bridge.cpp::PackageTask`, MCP `source_assets_host.py` | Preserve immutable snapshots, exact handle release and aggregate admission while changing the disk resolver. These handles are transient, not persistent model IDs |
| Immediate staging ownership tracking | `assets.ms::CyrusAssetStage` now accepts `createdNodes`; MCP records created meshes/splines immediately | Retain this rollback boundary when loading assets through the new store |
| Source measurements and local content grants | New source-measurement bridge and MCP metadata/source adapters | Reuse verified physical facts where appropriate. Store discovery must preserve local grants, opaque remote references and truthful readiness |
| Existing `.max` import Undo problem | `recipes.ms::CyrusModelMerge` still calls `getMAXFileObjectNames` then `mergeMAXFile`; [B38](../../BACKLOG.md#b38--individual-model-merge-loses-prior-undo-history) records the reproduced history loss | Safe model import must be an acceptance gate. A hold label alone cannot establish transaction safety |

### Interactions content needs its own portable contract

Accepted preparation is persisted by source-row identity in
`interactionSourceIDs`/`interactionDefinitions`. The serialized native definition
contains format, acceptance, preparation settings, source fingerprint, metadata,
report and labels. `interactions_source.cpp::prepareSource` checks source
fingerprint and geometry/binding hash before accepting a saved definition.

For future complete Interactions sharing, the appropriate extension is an
optional immutable preparation definition referencing the exact model revision,
with layer roles and gap/stiffness/root-cover settings in the recipe. Preserve
review/acceptance and source correspondence on load. Do not save per-instance
contact poses, transient review guides or render helper nodes as reusable models;
rebuild derived contact state from the supported authored inputs.

Canonicalize authored preparation content separately from diagnostics. The
current analysis report contains elapsed `seconds`, so hashing the whole report
as model identity would create spurious revisions after equivalent analysis.
The source fingerprint is also not a replacement for the complete mesh/image
content hash: preparation and asset storage have different dependency sets.

This is an identified adapter requirement, not an implemented capability or
permission to remove the current export guard. Plain static recipe sharing can
proceed first. Complete Interactions portability must pass its own versioned
codec, source-binding, unit, stale-definition and roundtrip acceptance before
the library claims to save that whole setup.

### Two different kinds of preparation

MCP's retained package lease owns copied mesh/material package data in memory.
An Interactions definition stores reviewed plant guide/binding authoring data.
Neither mechanism implements cross-recipe physical file deduplication.

The lease API deliberately admits small source cohorts: at most three retained
handles, 1–3 mesh nodes per package, and aggregate payload/mesh/image/map/material
bounds. Do not weaken that policy or apply its small-cohort limits to every
personal-library operation. Reuse immutable data and the resolver underneath
separate consumer admission policies. A later browser scan or package preparation
must not invalidate another owner's approved snapshot.

MCP metadata ready is distinct from dependency/application ready. Its existing
grants and approvals do not authorize exporting a user's whole store, choosing
arbitrary paths remotely or applying a recipe. The MCP work is a paused development
checkpoint, not a newly qualified release on the 0.87.0 pair.

## What remains unchanged

Six key files still match the bytes recorded in the 23 October investigation:

| File | SHA-256 |
| --- | --- |
| `src/asset_package.cpp` | `abcc305539d1ef4fd5f2bf256241bdef217166e5b5264f18ba7b734744e1524f` |
| `src/asset_mesh.cpp` | `cfcf8b2990ad46e5d129f21b3ed449396bf43ae5a678846e53dfbd5aeb525e5d` |
| `src/recipe_store.cpp` | `5428e1308b72b52a290501a46209021c78dace1fc638d3330c82feaddbdc269d` |
| `setup/InstallEngine.cs` | `01d4ab9eb9e4f55fc640f067c75b07beb5f5d8ce6a0496769677d00084a76588` |
| `shared/LibraryLocation.cs` | `c80434a501c2640d92bd7abbd4d14ed152191dde7f67316b49d467558ea1fa2d` |
| `templates/preset-loading.ms` | `4c6e34817a3bef6399c506d3282e274a6b480e058824cc43d136a9cd1e9db1c8` |

Paths above are under `AminScatter/`; the template is under `tools/ui/`.
The native authored recipe codec and managed gallery also have no diff against
the original investigation's HEAD. The changed capture/staging templates are:

- `recipes.ms`: `8673d8fd2e5a6bc72f6ab6445a5df1e4ab33b94a7e912ea3546fe1535216e9c7`.
- `assets.ms`: `adc7b13c6aea486ed9ed871bda922dbfb9256f04a34187b7ff86db0a1e16031a`.

Consequently the original storage findings still apply: payload reuse is local
to a recipe package; metadata revision can copy another complete asset package;
textures are resolved into the profile's `ImportedAssets`; and a recipe entry
can be saved before ready-package failure. The installer already has the shared
byte-store foundation, but personal recipe saves still need the planned integration.
The Standard-material high-poly capture/profile coupling is also still present.

## Readiness decision and next scope

Proceed with SL01–SL04 of the existing plan when implementation is authorized:
freeze canonical asset identity on the current baseline, extract the shared
writer, integrate model capture and atomic recipe saves, and preserve new reader/
lease lifetimes. Sharing and migration still follow SL05–SL07; the original
ten-look physical-allocation acceptance remains mandatory.

Add three explicit gates alongside that original acceptance:

1. **Current-schema and Interactions boundary:** plain recipe 8 works in the
   schema-60 host; unsupported prepared/contact content fails clearly. Only an
   explicitly implemented adapter can claim complete Interactions roundtrip.
2. **Concurrent consumers:** gallery, independent MCP catalogs and retained
   prepared snapshots keep their own identities/lifetimes during save, import,
   migration and cancellation. Persistent asset IDs never contain lease handles.
3. **Model import history:** correct/replace the unsafe `.max` import path or
   explicitly exclude it from the transactional route. Verify meaningful prior
   Undo history, model import Undo/Redo and late-failure cleanup on the actual
   affected path before claiming safe model import.

No new broad competitor research or library-architecture redesign is required.
The existing plan is usable with these baseline and integration amendments.
This review changes documentation only; implementation and all new acceptance
execution remain pending.

## Direct source references

- [Recipe capture and model merge](../../../AminScatter/tools/ui/templates/recipes.ms).
- [Interactions authoring](../../../AminScatter/tools/ui/templates/interactions-authoring.ms),
  [native host serialization](../../../AminScatter/src/interactions_host.cpp) and
  [source binding validation](../../../AminScatter/src/interactions_source.cpp).
- [Independent catalog ownership](../../../AminScatter/include/recipe_library.h) and
  [catalog implementation](../../../AminScatter/src/recipe_library.cpp).
- [Prepared package leases](../../../AminScatter/include/prepared_package_leases.h),
  [bridge lifetime](../../../AminScatter/src/recipes_bridge.cpp) and
  [created-node tracking](../../../AminScatter/tools/ui/templates/assets.ms).
- [MCP source staging](../../../CyrusMCP/cyrus_mcp/source_assets_host.py),
  [current MCP checkpoint scope](../../../CyrusMCP/README.md),
  [recipe grants](../../../CyrusMCP/M03_RECIPES.md) and
  [prepared-source contract](../../../CyrusMCP/M03_ASSET_USE.md).
