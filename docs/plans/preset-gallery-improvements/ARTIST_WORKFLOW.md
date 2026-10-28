# Cyrus Library — current model and recipe workflow

Current Scatter packages include the [0.87.5.6 responsive-bending patch](../drag-response-08756-20261028/DELIVERY_08756.md). The Library foundation below retains its own qualification. In Max 2027, Scene presets also retain ordinary scene collider references and broad branch-response settings. Portable recipes explicitly reject those unsupported new references/settings. Content and Analyzer remain independently versioned.

The delivered Library baseline is [0.87.5.1 native Scene presets](../scene-presets-08751/DELIVERY_08751.md), **Max 2027 only**. The current MZP preserves the independent Analyzer and content installations. Earlier three-host EXEs and versioned material tests retain their own scope. Use the current [interaction controls](../drag-response-08756-20261028/ARTIST_GUIDE.md) for Bend/Trim and trunk/falloff settings; the Library evidence below does not qualify that interaction work.

## Individual plant models

The supplied private content has 96 prepared single-model files covering 104 catalog cards. Choose **Plant models**, then **Merge model** for a visible scene source or **Add to selected layer** for the captured Scatter layer. The banner reports completion or failure. This imports a model; it does not load a complete planting setup or replace receiving surfaces. The [artist guide](../../ARTIST_GUIDE.md) owns source controls and viewport/material behavior.

## Browse collections

Open **Cyrus Library** from the Cyrus action category or **Layers > Recipes**. For portable planting, select the destination terrain and intended setup before opening; later scene selection does not redirect the captured destination. Native Scene presets restore their saved receivers and arrangement without requiring a destination terrain.

**My recipes**, model cards and collections share the existing Library. Browsing reads metadata/images, without calculating plants, capturing previews or merging objects. **Refresh** explicitly discovers file changes; missing previews show placeholders. The gallery admits 128 items per page with a bounded image cache. Physical mixed-monitor behavior retains separate qualification.

## Choose what to save

In **Save Recipe**, choose:

| Save as | Saved result |
| --- | --- |
| **Scene preset** | Complete native Max setup, collected files, editable geometry, preparation, Paint, controllers and instance edits. |
| **Portable preset** | Selected layers with supported static assets, settings, native Paint and bounded authored records for another compatible terrain. |
| **Settings only** | Supported settings and Paint; models need compatible bindings later. |

Enter a name and optional collection, tags and description. **Update selected** writes a new revision; **Save Copy** creates another identity. **Edit details** updates the card while reusing saved files. A failed complete save retains the previous revision. Saving pending Manual settings does not Update the original placements or repath the original materials.

Thumbnails are optional. Capture the published viewport explicitly; use Update-and-capture if pending settings should appear in the preview. Bundled examples remain read-only. Refresh/review a card if its saved revision changes externally.

## Load a native Scene preset

Choose its card, then **Load > Merge**. It adds an independent setup in its saved arrangement, with fresh owner/source/clone identities. Standard Max merge clears existing Undo history; the load dialog gives a short notice. This is the selected Scene workflow. Existing scene objects are retained.

Scene presets require **Max 2027**, matching system units and required object/material plug-ins. Max-declared files are collected; missing files, nested external scenes and unresolved sequence patterns must be resolved before Save. Plug-in installations and licenses are not bundled. Destination renderer/environment/colour settings follow ordinary Max merge. See [exact tests and limits](../scene-presets-08751/DELIVERY_08751.md).

## Load portable planting or apply a style

For a Portable preset, **Load onto surface** imports independent supported models/materials and adds layers to the captured terrain/setup. If several setups use the terrain, open Recipes from the intended one. Existing layers and Manual/Live mode remain. Loading explicitly updates once, including pending setup settings, and retains its existing single-Undo transaction.

Portable planting fits supported Paint contours and static spline guides between local-XY footprints and converts physical distances. Terrain Paint transfer requires a single-valued footprint; surface-attached Paint requires matching indexed topology. New Paint can be drawn directly on supported manifold curved receivers. Portable recipes do not reconstruct arbitrary receiver modifier stacks or required mesh-channel producers.

Format 9 carries supported sparse Cyrus Edit changes and accepted preparation within finite bounds. Use Scene presets for complete Edit stacks, per-instance radius history and animated controllers. Plant interactions retain one Edit modifier per controller; stacked edits can travel with interactions off. Unsupported geometry/material graphs and oversized data are reported explicitly.

**Apply Style** copies selected supported setting groups into the captured layer, keeping models, receivers and Paint by default. Review external bindings and variation choices. It is separate from native Scene merge and is not a whole-scene or Edit-stack transfer command.

## Share and store

Use **Export library / collection** and **Import shared library** for verified `.cyruslib` transfer. Identical objects are reused; recipes pin saved revisions. Share only assets you have permission to redistribute. **Manage storage** shows the active store and explicit maintenance actions. The [versioned shared-store guide](SHARED_LIBRARY_ARTIST_GUIDE_0871.md) retains storage, migration and recovery details.

**Export portable package** remains the bounded static adapter: supported standalone meshes, Standard/Blinn and static PNG maps. Arbitrary renderer shaders/proxies, XRefs and animation are outside that adapter. Native Scene serialization has a broader graph boundary with installed dependencies; it does not make those portable adapters universal.

## Install and preserve

Run the [current Max 2027 MZP](../scene-presets-08751/DELIVERY_08751.md) through **Scripting > Run Script**, then restart Max. Existing Analyzer and optional plant content 0.86.7 remain independent. The earlier EXEs and historical eight examples keep their original host/version qualification. Preserve original scenes and save upgraded copies. No online content download or automatic Max restart is implied.

The [installation guide](../../Max_2027_Installation.md), [artist guide](../../ARTIST_GUIDE.md) and [Scene guide](../scene-presets-08751/ARTIST_GUIDE.md) own current instructions and limitations.
