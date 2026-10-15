# Recipe library presentation contract — 0.82.6.1

Qualification and delivery status live in [PROGRESS](PROGRESS.md). This extends
the existing [recipe v1 authored-data contract](../recipes-0825/FORMAT.md);
scene schema 58, recipe capability 1 and native Paint encoding are unchanged.
The separate library capability is 1. These identifiers do not certify a build.

## Authored data and presentation

Save Everything writes the complete supported authored settings and Paint first.
It never exports cached meshes, generated rows, GPU buffers or scene handles.
Receiver-bound Paint still requires compatible evaluated terrain, transform and
saved system units. Models, maps and paths remain explicitly bound external roles.
Unsupported controllers and authored Edit/radius data reject with an owner-specific
explanation; this delivery does not introduce a lossy save mode.

An optional `<recipe filename>.library.json` sidecar supplies presentation only:

```json
{
  "format": "cyrus.recipe-library",
  "version": 1,
  "recipeSHA256": "sha256 of the exact authored manifest bytes",
  "metadata": {"category": "Woodland", "tags": ["trees"], "description": "..."},
  "thumbnail": {"file": "thumbnail-<manifest hash>.png", "sha256": "...", "bytes": 12345}
}
```

`thumbnail` can be null. Category, description and each tag allow respectively
96, 1,024 and 64 UTF-8 bytes; there are at most 16 nonempty distinct tags. Sidecars
are at most 8 KiB. Hash binding prevents presentation from silently describing
different authored data. A damaged/stale presentation sidecar warns but does not
invalidate the recipe. A presentation save failure explicitly reports that the
authored recipe was saved without its tags/thumbnail.

Thumbnails are optional stored PNGs, at most 2 MiB and 1,024 pixels per dimension.
The native reader checks header, dimensions, package-local path, exact bytes and
hash. The UI then decodes the image and copies it before disposing its input stream.
One selected image is retained and disposed on replacement/close. A bad image has
a visible fallback. Native header validation alone is not a complete PNG decode.
Thumbnail generation is explicit; browsing never renders or captures the scene.

## Library behavior and bounds

The file-only worker receives copied absolute paths. It reads and validates
manifest metadata and optional presentation records, without hydrating Paint
attachments or accessing Max scene APIs. It admits at most 10,000 recipe files,
100,000 directory entries and an estimated 32 MiB of indexed serialized metadata
plus per-entry accounting. The estimate is not a process-RSS guarantee.
Scanning is nonrecursive, case-insensitive for the recipe suffix, and deduplicates
canonical paths. Search uses Unicode case folding; category filtering is exact.
Pages contain at most 128 entries. Query/page operations use the in-memory index.

Explicit Refresh starts a new generation and rereads content, including a file
replaced with the same size and timestamp. A stale generation cannot be queried.
No filesystem or UI polling remains after scanning. While scanning, a 250 ms UI
timer presents bounded progress; it does not drive scattering. Review/import
hydrates only the explicitly selected recipe after the scan finishes or is cancelled.

Cancel requests worker cancellation immediately and asks Windows to cancel pending
synchronous I/O. Filesystem/driver cancellation latency is not universally bounded;
the UI never joins an active worker during ordinary browsing. Refresh remains
unavailable until the prior scan stops. Shutdown notifications and `LibShutdown`
join/destroy the worker before DLL teardown. Slow network-thumbnail selection and
actual network outage behavior require their own measurements; local tests do not
establish them.

## Artist workflow and content

My recipes uses `Documents\CyrusScatter\Library`. Bundled examples use
`<Max user scripts>\CyrusScatter\Library-<product version>`; saving while browsing examples writes
to My recipes. A custom folder is explicitly selected by the artist. There is no
background library watcher. Keep the recipe, Paint payload directory, presentation
sidecar and stored PNG together when moving a complete entry.

Search matches recipe/layer names, tags, category and description. The scrollable
summary lists layers, Paint document count and external-role count. Review bindings
shows the actual required scene objects/maps/layers. Match unique scene names is
an explicit suggestion and never an automatic hidden import. Import offers Add
layers or New setup and preserves the existing transactional Undo/Manual/Live rules.
Amount/Transform settings presets remain a distinct existing format, accessible
from this dialog without being presented as complete recipes.

Four initial procedural examples and matching scenes passed scoped qualification; see [I03 delivery](I03_08261.md). Grid and path
examples follow those feature implementations. Their thumbnails must come from
actual accepted placements, and the package inventory must record exact content
hashes. A preview render of temporary geometry from accepted rows does not certify
renderer adapters or final renderer-level edge trimming.
