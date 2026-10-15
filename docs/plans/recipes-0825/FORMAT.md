# Implemented recipe wire contract, version 1

Current successor: [format 2 in Scatter 0.83.0](../improvement-program/FORMAT_2.md) adds orientation and a strict read conversion from this version. The original format-1 contract below is preserved.

This describes Scatter 0.82.5, not the earlier illustrative semantic example. Normative validation is in `AminScatter/src/recipes.cpp`; the explicit setting list is `recipe_fields.inc`, and host capture/import is `tools/ui/templates/recipes.ms`. Scope and qualification are in [PROGRESS](PROGRESS.md).

## Manifest

The closed top-level object requires:

| Field | Meaning |
| --- | --- |
| `format` / `formatVersion` | `cyrus.planting-recipe` / `1` |
| `evaluationContract` / `sceneSchema` / `hostYear` | `CyrusUnified1` / `58` / `2027` |
| `id` / `name` | Safe package ID and artist name; IDs are data, never filesystem paths or host handles |
| `unitsPerMetre` | Number of original scene system units per metre; required for native Paint context |
| `exportScope` | `complete-setup`; no partial/lossy variant in this delivery |
| `rootSettings` | Complete 228-field static typed settings object; used for new setup, preserved destination preferences for Add |
| `roles` | External node, texture or destination-layer requirements |
| `layers` | Ordered one-to-ten authored owners, each with `id`, `name`, `enabled`, `visible`, `settings`, `paint`, `areas` |
| `spacingRelationships` | Scope, endpoints, enabled state, multiplier, metre gap and planar flag |

All settings objects contain every allowlisted key, including dormant values. Types/array alignment/enums/curves/Band ranges are validated before host mutation. Distances are normalized to metres where declared world units, including typed arrays. Native Paint brush radius/frame and payload retain their original system-unit context. They are not silently converted.

A role requires `id`, `kind` (`node`, `texture` or `layer`), `name`, `purposes` and `requirements`. Settings references use role IDs or null, not object names or numeric node handles. Optional source-container requirements record width/length in metres, collection/label state and ordered saved-source role membership. Bindings live only in the host import proposal; matching a name is an explicit suggestion. An external spacing role binds to a layer in the Add destination. To import a separate setup, include its spacing partner in the saved selection.

Each Paint Area requires `id`, `settings`, `receiverRole` and `paint`. A native Paint entry requires `payload`, `receiverRole`, `radius`, `erase` and `frame` (twelve values or null). Native layer Paint and ordered child Paint Areas are accounted for separately. Null receiver roles represent unbound documents, not a permission to scatter on the whole surface.

## Native Paint attachments

On disk, `payload` is an object with `file`, `sha256`, `bytes`. `file` is relative to the manifest, ordinarily `paint-<recipe-id>.payload/paint-<n>.cspaint`. Full reads constrain the resolved path to that package directory, bound its size and check exact bytes/hash before decoding. Review hydrates payloads to lowercase hex in the transient MAXScript transport tree. The caller cannot make an executable filename or arbitrary script part of a recipe.

The canonical Paint document codec stores coverage, holes, surface fingerprint and falloff traces. Recipe metadata stores receiver role/frame and brush options. Importing bound Paint validates frame, saved units and evaluated shape/topology. Native scene storage additionally retains a known receiver frame in chunk `0x7303`, so orphan documents retain it after reopen. An old orphan with no frame keeps null. Paint coverage bytes are unchanged by recipe conversion.

## Import identity and transaction

Manifest owner IDs identify relationships within that file. Each import creates new scene owner/source/receiver identities and new Edit layer keys. Source-row visual metadata, Band membership and source/receiver correspondence remap coherently. Numeric Path/Band IDs remain owner-local; a new owner supplies their new namespace. Cached placements, native buffers and prepared geometry never enter the file.

Import validates the document, roles, current owner, units and capacity, starts one native Undo hold, suspends display publication, stages native Paint/new owners, appends the complete graph and validates it. Failure cancels the authored hold and retains the previous complete graph/publication. On success, it accepts one Undo, restores suspension and schedules the normal Manual/Live behavior. Manual does not advance the publication epoch. A later calculation failure retains the complete preceding publication; authored imported settings remain available for correction.

## Save, versioning and limits

Saves create new files only. Temporary payloads are verified and published before the manifest; failed saves clean their owned staging. A missing/corrupt attachment can still leave a readable metadata row, but full Review/import fails. Metadata cache validity uses path, size and mtime; explicit Refresh drives listing. There is no background polling.

Unknown or duplicate keys, wrong types, nonfinite values, duplicate owners/rules, invalid references and unsupported format/engine/schema/host versions reject. Limits are pinned in the implementation and [handoff](PROGRESS.md). Future layouts, maps, native record types or fidelity-changing additions need a reviewed format/capability successor and corresponding inventory/fixtures. Product version and recipe version do not substitute for each other. The older design example remains illustrative and non-loadable.
