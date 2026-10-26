# Shared models and recipes — 0.87.1

The [delivery report](DELIVERY_0871.md) identifies the exact installers, scoped Max 2024/2026/2027 checks and remaining limits.

## Save and reuse

Import your static models into Max and build a planting setup normally. In Cyrus
Library choose **Save Recipe** and leave **Include models, materials, terrain and
paths** enabled. The plugin captures the supported geometry, materials, image
files and authored settings. You can then load the complete recipe in another
scene without importing the original models again.

**My models** contains reusable source models from complete recipes. To save models
without a recipe card, select one to ten static geometry objects in the scene and
choose **Library > Save selected scene models**. Select a saved model and choose
**Merge model**, or **Add to selected layer**. These personal-model actions use the
native portable geometry route and support Undo. The separate installed **Plant
models** `.max` merge route retains its existing behavior and B38 limitation; its
old header/merge path is not the new transactional personal-model importer.

Models have their own packages containing only the chosen model's dependencies.
Exporting a tree from a former three-model recipe does not include its grass,
flowers or receiver. Individual models import at the origin; recipes retain their
saved layout and bindings.

The store identifies exact bytes with SHA-256. One geometry/image object can serve
many models, recipes and collections. Each material/map interpretation remains
separate. Changing tint or placement settings reuses the mesh/image bytes;
changing a mesh or an image creates a new object. Existing recipes retain their
saved assets. Disk sharing does not link materials between imported scenes.
Equal shader definitions share stored bytes while preserving separate versus
instanced shader objects inside an imported model. Different gamma interpretations
use separate hard-link filenames over the same raw image bytes.

Your original import folder can stay where it is. A completed save owns the bytes
needed by its supported assets. A failed complete save keeps the previous complete
recipe; it is never silently changed into a settings-only recipe. Unchecking the
asset option intentionally saves settings with external bindings instead.

## Collections and sharing

Select a card in **My recipes** or **My models**, then choose **Library > Add
selected to collection**. Enter an existing or new name. Membership shares the
same stored objects. Select a collection in the tree to browse/export that group;
choose All recipes/All models to export the personal library.

**Export library / collection** writes a `.cyruslib` archive containing the selected
roots and the union of their dependencies. Send the archive to a recipient who has
a compatible plugin and any required renderer adapters. They choose **Import
shared library**. Import copies the missing verified bytes into their store;
removing the archive afterwards does not break imported content. Repeating an
unchanged import creates no duplicate cards or payloads. Export assets only when
you have permission to redistribute them.

An existing recipe identity with a different saved revision is preserved and the
ordinary import reports a conflict. **Import conflicting recipes as copies** keeps
both with a stable derived copy identity; repeating that operation reuses the same
copy. A conflicting current model revision still requires explicit reconciliation
or a separate store. Names alone are never used to replace geometry or images.

## Storage and older libraries

**Library > Manage storage** shows the active local NTFS folder. The default uses
an existing registered managed content store when available; otherwise it uses
Documents/CyrusScatter/SharedLibrary. All three supported host profiles resolve the
same personal registration. A root must be at most 80 characters so bounded native
package paths fit the supported Windows/Max path limits.

Use **Import older recipe folder** for supported flat `.csrecipe.json` libraries
and their `Presets/<recipe digest>` packages. Present corrupt packages cause a
reported failure, rather than a settings-only downgrade. Source folders and old
scene paths are retained. **Consolidate verified migration originals** can replace
verified same-volume dependency copies with hard links while retaining their old
filenames. It touches only a folder recorded by an earlier successful migration.
Cross-volume originals are retained copies; moving them is a separate decision.

**Relocate library** requires a separate empty local NTFS folder. It copies unique
objects, recreates views and verifies packages/history before redirecting future
writers. The old store remains available to saved scenes. **Relink current scene
and save a copy** verifies known shared image hashes, changes only matching image
paths, and writes a new `.max` file. The original scene file is preserved and Undo
restores old paths in the open scene.

Removing a card retains published objects and scene paths. **Restore previous
catalog** restores the previous committed catalog as another history revision.
**Recover abandoned staging** removes only marked staging owned by processes that
have ended. Unverified folders are retained. **Repair assets from backup** requires
a valid `.cyruslib` archive; it replaces corrupted objects/views with exact
verified bytes and keeps replaced corrupt bytes in quarantine. Ordinary import
refuses corrupt existing objects.

Storage usage distinguishes unique object lengths, allocated object bytes and
catalog history. Hard-link filenames do not each allocate another full mesh or
image. Original import folders, retained migration/relocation copies, history,
quarantine and temporary capture space are additional storage. There is no
automatic purge of published assets.

## Supported content and bounds

This delivery targets supported static planting: editable mesh/poly models,
supported Standard/Bitmap materials and the existing finite renderer adapters.
The existing Corona profile remains Max 2027 and exact-adapter specific. A shared
static graph uses the native plant-mesh codec for editable sources independently
of their material. The per-mesh limits remain one million vertices/faces and
224 MiB encoded; graphs, images, package totals, host memory and scene population
counts have additional existing limits.

Portable textured content requires Max's **normal default OCIO** pipeline and the
same saved configuration, rendering space and data space. Max 2024 can start in
legacy Gamma mode; choose the supported OCIO profile deliberately for those scenes.
The plugin does not change scene colour management or silently convert a mismatch.
Matching renderer plug-ins and colour profiles remain requirements when sharing
across computers or host versions.

Unsupported proxies, animated/controller dependencies, arbitrary shaders,
Interactions authoring, retained reviewed contact definitions, unsupported Edit
or radius authoring are rejected explicitly. This is a planting recipe library,
not a complete arbitrary Max scene serializer. Ten three-layer looks belong in
ten separate scenes; a single Scatter setup still has its ten-population limit.

A portable archive allows up to 100 recipe roots, 1,000 model roots, 4,096 objects
and 16 GiB expanded bytes. Lower type/package limits still apply. Shared catalogs
are bounded to 10,000 combined entries and 8 MiB serialized metadata, with
128-card pages. At most eight file operations may be pending, two file workers
run concurrently, and native package validation is serialized to bound memory.
NTFS also limits each file to 1,024 hard links; immutable recipe/model views and
interpretation aliases consume links. Reaching that limit reports a failed save
and retains the previous catalog. The entry-count bound is not a promise that one
texture can have unlimited aliases. Keep backups; published assets are never
automatically purged.
