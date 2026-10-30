# Edited instances and held movement — 0.87.6.7 candidate

The user reports that Seed in Amount fails after moving an instance in Cyrus
Edit, and that mesh movement appears only after mouse release and feels heavy.
They chose to keep edited items fixed while regenerating other items and supplied
`Test Scene/Terraces_Garden_0.87.6.5_Max2027.max` for isolated testing.

The user explicitly selected 0.87.6.7, superseding the unpublished 0.87.7 candidate.
Current preceding delivery is 0.87.6.5. Version 0.87.6.7 groups this authored-state
change and its viewport correction as an Edit workflow delivery. Native Edit
capability becomes 5 and storage becomes 4; scene 65, recipe envelope 9 / authored Edit payload 2 and independent
products remain separate. Existing recipe deltas retain destination-relative
replay; imported edits acquire their pin at the destination's first valid bind.
No current acceptance is inferred from the version. Max 2027 only.

## Required behavior and ownership

- Native Edit owns a sparse immutable base record for a manually transformed,
  copied or deleted item. The existing stable output ID, source lineage and
  authored delta remain authoritative. Seeds and ordinary transform settings
  regenerate other candidates; pinned instances keep their authored transform
  and source. This is distinct from baking or creating Max scene nodes.
- A pin replaces its generated slot; an explicit clone remains additional.
  Existing count/spacing/protected-edit semantics remain. Lowering Count does
  not silently erase authored history. Missing sources/receivers suspend pins;
  returning the same owner restores them. Receiver geometry incompatibility
  remains guarded. Unresolved old history must not be guessed.
- Pins still enter the existing acceptance, spacing, interaction, display and
  render pipelines. Their authored rest transform is fixed; contact poses may
  still respond. Reset selected edits returns generated rows to procedural
  ownership and removes selected clones through the existing authored deletion
  model. Undo/Redo restores the pin and delta together.
- Held mesh movement publishes sparse transforms against retained geometry.
  Source preparation, placement generation and pending Manual settings must not
  be consumed. All Max calls and publication remain on the host thread; immutable
  views reach drawing. Failed staging retains the last complete display.
- Pin storage is shared by copy-on-write histories, proportional to authored
  rows, with existing record limits and native allocation accounting. Transient
  display patches are bounded and retire with their generation. Measure this
  separately from total scene memory and presented frames.

F01/F02/F04–F08/F11 apply. Preserve the artistic Bend/Trim baseline and other
agents' dirty files. No installation, artist-session restart, push or deployment.

## Verification

Reproduce on matched 0.87.6.5 in an owned host, then validate native state/storage,
reseed with changing source choices, untouched rows, missing-source restore,
clone/delete/reset, old storage, failure retention, Undo/Redo, save/reopen and
portable recipe replay. Use actual SDK gesture callbacks across host events;
compare held displayed transforms/tickets and source/placement/upload counters.
Repeat in a byte-identical owned copy of the supplied Terraces scene. Runtime
timings are scoped CPU/submission measurements, not physical input latency or
GPU FPS. A delivery requires the exact qualified Max 2027 MZP and integrity/hash
checks. Original review receipts and scenes remain unchanged.

The independent 0.87.6.3 review's 72 manifest files and 73-member ZIP pass current
hash/CRC inspection. FS-01 and FS-02 matched source. The user's resumed request
to finish the installer with all fixes includes marking Scene-load stages before
copying their payload and recording the actual managed assembly version in Scene
metadata. Licensing captions no longer embed an obsolete release. Recovery keeps
active/unverified folders and published assets. Test an owned child interrupted
after Scene staging, active-stage retention and immutable published bytes. Broader
optimization and peak-memory recommendations remain separate open qualification.

## Added user scope: panel repaint and band assignment swatches

The user supplied 0.87.6.5 screenshots where opening Viewport & render erases
radio/check captions until hover, and requested band badges matching assigned
models. Reproduce with owned Max 2027 panels, repair presentation without
rebuilding placements or consuming Manual parameters, and verify repeated
expand/collapse and column changes. Band list swatches derive from the existing
source identification colours: one model uses its badge, mixed assignments use
a split swatch, and unassigned bands have no swatch. Keep authored Band viewport
colours and assignment groups independent. No scene/recipe schema change for
these UI fixes. Include them in the still-undelivered 0.87.6.7 package and requalify
the exact final script/native pair.

## Added user scope: source preparation profiles and guide detail

The exact supplied Violet has 197 pieces, 17,110 triangles and 12 automatic
guides, matching the screenshot. Most flower stems have only three guide points.
Explicit selected-piece Stem, Leaf and Flower head profiles and 3–16 guide
points are authored preparation intent. Leaf guides follow existing source
cross-sections when topology proves their ordering; otherwise use the bounded
topology chart with explicit leaf admission. Flower heads attach rigidly to a
stem, with the existing explicit parent override available. This creates bend
guides, not missing source mesh geometry. Automatic defaults remain unchanged.

Native C++ owns analysis, copied geometry and prepared rig storage. The editor
owns draft intent and its bounded Undo/Redo history; a worker stages a successor
and host-thread publication accepts only the latest complete revision. Failed
analysis retains the previous complete preparation and disables Use until fixed.
Detail is per selected piece, never a placement-sized script operation. Existing
guide, point (16), work, preview and memory limits remain. Higher detail costs
more only for opted-in sources; measure analysis/retained bytes and source rest
reproduction separately from contact/display performance. Selection alone does
not analyze or upload source geometry.

New fields require authoring intent 2 and prepared source/envelope 3. Readers
retain intent 1 and preparation 1/2. Interactions capability becomes 17; scene 65,
recipe envelope 9 and independent products remain unchanged. Exact-source hash
guards, all original triangles/materials, manual guide points and chosen parents
remain authoritative. Test profile/detail persistence, Undo/Redo, invalid detail,
failure retention, actual Violet leaves and stems, and unchanged Automatic output.
