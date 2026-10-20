# Native scene ownership — 0.3.1, schema 4

This describes the retained native ownership contract in **Cyrus Arrange 0.3.1 for Max 2027**, including native Book row
relationships, document schema 4, library format 2 and registry format 1. Readers
accept the released schema-3/library-1 examples without generating or rewriting
the originals. Matching native/storage/UI files are required; MAXScript arrays
are not the authoritative scene model. The
[preserved 0.3.0 release report](RELEASE_VALIDATION_0.3.0.md) records that
delivery's exact evidence. The [0.3.1 contract](REAL_WORLD_0.3.1.md) records the
successor's implementation and acceptance status.

The 0.1.3 geometry/query cache preserves the authored ownership contract;
transient reuse and observation are not serialized scene state. The historical
0.1.2 native28 functional, migration and installer evidence remains bound by
[its release validation](RELEASE_VALIDATION_0.1.2.md) and
`dist/CyrusArrange-0.1.2/qualification-receipt.json`. Earlier progress and failed
runs below are explicitly historical. Immutable 0.1.0/0.1.1/0.1.2 packages and
receipts remain unchanged, and the full-system goal is tracked separately.

## Ownership graph

New setups use a native Cyrus Arrange Icon helper with a pass-through Cyrus
Arrange modifier. Earlier built-in Point owners retain the same ownership
contract. A native `CustAttrib` attached **to the setup node** owns one native
`ReferenceTarget` Document. The
Document references:

1. A built-in weak `NodeMonitor` for its owning setup node.
2. One built-in `IRefTargContainer` for furniture node references.
3. One built-in `IRefTargContainer` for source asset node references.
4. One built-in `IRefTargContainer` for managed output node references.
5. One built-in `IRefTargContainer` for bounded furniture/asset/obstacle-group descendant dependencies.
6. One built-in `IRefTargContainer` for independent external obstacle roots.

Native reference slots remain fixed: owner 0, furniture 1, assets 2, outputs 3,
derived descendants 4, obstacles 5. Furniture, assets, outputs and obstacles retain
their positional authored rows; the derived container observes the three input
scopes' group descendants without changing those rows. Keeping group roots allows
each Update to discover newly added members. Independent obstacles participate
in collision and access tests; they never authorize support or become inspected
furniture regions. Their names are presentation only.
The reverse owner monitor avoids a strong setup → attribute → document → setup
cycle. Containers have positional slots: source slot `i` corresponds to asset
`i`, output slot `i` to placement `i`. Deleting a referenced node nulls its slot
rather than shifting the following slots. The native state remains available and
is marked dirty. Names, node handles, user properties and global variables are
not authoritative ownership links.

The presentation helper and modifier own no Document or input-node references.
The modifier changes no object channels and passes furniture geometry through
unchanged. Opening its parameter view resolves actual edited node contexts and
native setup bindings; a MAXScript rollout reads and edits that document through
the existing commands. Ambiguous contexts require an explicit arrangement
choice. Unbound furniture requires an explicit Create action. Opening, closing,
selecting and drawing do not capture geometry or solve placements. View bindings
are transient and clear on close; captured document identities guard callbacks.
The helper draws a bounded cyan wire icon and never contributes render geometry.
New owners start at the first furniture pivot, with identity orientation; moving
the icon is presentation and does not move the furniture or generated props.

`src/arrange_presentation.cpp` implements both native classes and the rooted
rollout-page lifetime. The storage plugin registers their descriptors alongside
the existing two ownership classes. Added class IDs are modifier
`(0x6a4387d3,0x4fa90372)` and icon `(0x6a4387d4,0x4fa90372)`; existing IDs and
document reference slots remain fixed. The icon descriptor is private to avoid
offering an empty setup through the Create panel. The modifier is public in the
Modifier List. The controls are documented in [Modify panel](MODIFY_PANEL.md).

Keep furniture, source nodes and output nodes outside the setup's parent/child
hierarchy. In particular, parenting an output under its setup can create a
reference cycle with the Document's strong output reference. Group/layer
organization must not introduce such a cycle. Output scene geometry is ordinary
Max geometry/instances; removing the ownership attribute leaves those objects.

Portable state/codec: `include/cyrus_arrange/document_state.h` and
`src/document_state.cpp`. Host references/services: `src/arrange_document.h` and
`src/arrange_document.cpp`. The portable module includes no host references or Max
headers; saved time retains its signed int32 representation, checked at the host
boundary against `TimeValue`.
The companion `src/storage_plugin.cpp` registers the Document and owner
attribute classes through descriptors exported by the main `.dlx`:
`CyrusArrangeDocumentDesc`, `CyrusArrangeOwnerDesc`. The main target must produce
an import library (`SHARED`), and the storage target links it. Native document
GUID creation needs `ole32`. Root initializes the descriptor module with
`set_document_module(HINSTANCE)` and stops callbacks during plugin shutdown via
`stop_document_service()`. `CyrusArrangeShutdownBridge()` also calls
`shutdown_preview()` before module unload, releasing transient viewport callbacks
and their native Document lifetime references.

## Native state and coordinates

`DocumentState` owns actual C++ `Asset`, `Placement`, `Settings` and
`ArrangeSettings` values, together with label, GUID namespace, revision, identity
high-water companion, Manual/Live mode and captured frame.
The current schema stores asset capture policies, per-furniture category rules,
persistent furniture source keys and an immutable support-region registry. Schema
3 adds the obstacle-root count and independent `require_front_access` preference.
New TV-console/open-shelf setups require front access by default; coffee tables,
kitchen counters and dining tables start with that requirement disabled. The
artist can explicitly change that preference alongside the obstacle scope; it is
separate from the eleven arrangement settings and persists through Undo and save.
Schema 4 adds setup-wide `CompositionOptions` and ordered `composition_groups`.
Each BookRow group owns a stable ID, kind, persistent region ID, two to six member
placement IDs, saved front vector and saved gap. Members remain ordinary placement
records/output nodes. Groups introduce no new Max reference slot or hidden Max
group head. Default options disable rows and height balance, with two-to-six books
and a 3 mm generation gap. Asset row profiles are explicitly authored metadata;
missing metadata never becomes an inferred upright-book capability.
The `Asset` records include their bounded canonical meshes and contact/stack
metadata. Its copy-on-write `AssetCatalog` shares captured meshes across immutable
settings/lock edits and Undo snapshots. Const reads share the catalog; an explicit
nonconst asset mutation detaches it once. The registry uses
`shared_ptr<const RegionRegistry>` and immutable shared `RegionShape` records;
ordinary settings/lock edits share their canonical cells. MAXScript receives
bounded summaries, authored commands and explicit diagnostic rows. Native state
and real references remain authoritative.

Each asset has a parallel `AssetCapturePolicy`:

- `source_required` distinguishes a registered scene source from an intentionally
  imported or explicitly detached geometry-only asset. A deleted required source
  leaves a null reference and causes Generate/Refresh to fail while retaining the
  previous complete output. `caRebindAsset` installs a new required source;
  `caUseStoredAsset` explicitly clears the reference and requirement. Library
  imports are intentionally source-free; deletion never silently changes policy.
- `authored_contact` preserves the authored anchor and contact footprint during
  geometry refresh. Without it, capture derives the contact anchor/footprint from
  the captured geometry.
- `authored_stack` preserves and revalidates an authored stack-top patch. Without
  it, automatic stack-top capture currently supports books/book stacks and checks
  coverage of the proposed planar rectangular top. Support reset returns to
  automatic capture. Portable imports preserve their encoded support metadata.

The document owns one complete category-rule table for each of the five furniture
categories, with all eleven accessory categories represented. A row stores its
weight, maximum count and permission to appear on a stack. Zero maximum count
disables that category. Defaults come from the native furniture presets; edits,
reset, validation, generation and save/reopen use this same native table.

Placement positions use the inspected near-origin millimetre frame. Add
`frame_origin_mm` to obtain world-mm contact coordinates. Persist captured
system-unit scale and time alongside that frame. Root converts native rows to
Max transforms and validates current dependencies before generation. Recomputing
geometry can retire support regions; numeric inspector observation order is not
persistent identity. The registry assigns uint32 stable IDs against canonical
supported-cell geometry, quantized to 0.001 mm, and saved furniture source keys.
Current host integration uses exact matching. Changed or unmatched support gets
new IDs; protected placements that reference retired support fail validation
instead of moving silently to another region. Region metadata can be retained
only when its identity is matched. Optional overlap matching in the pure registry
API does not imply it is enabled by the host.

`RegionSemantics.excluded` is the sole exclusion owner. There is no parallel
document-level exclusion-ID list. The former schema-2 wire position is an explicit
reserved zero count; decoding rejects a nonzero value. Authored region labels,
roles, category masks, density/stacking controls and front direction live on their
native region records and follow the same exact-identity policy.

Regional exclusion, category masks and selective ownership govern the placement
anchor in its sampled region. Whole-footprint support uses the precise global
union of selected furniture surfaces at that height. An accessory anchored on an
allowed surface may therefore extend onto a touching, coplanar excluded surface;
actual gaps and holes still reject unsupported footprints. Exclusion is not a
physical keep-clear volume or exact per-region footprint clipping. For an area
that must remain empty, bind an obstacle volume rising above the support plane.
It blocks conservative accessory bounds without contributing support. See
[placement policy](PLACEMENT.md) for the numerical contract.

Asset and placement IDs are native uint64 values. Placement IDs may occupy all
64 bits (the solver uses deterministic hashing); do not reject IDs merely for
having the high bit set. `reserve_ids(count)` provides monotonic IDs for authored
registrations, furniture source keys and region allocation; its high water
survives Undo, failed successors and save/reopen. Setup GUIDs
namespace those IDs. Clone and duplicate merge obtain a new setup GUID.
Furniture source keys are stored alongside positional furniture bindings; node
handles remain transient capture/query identifiers. A region successor and its
placement/group rows are published in one native document transaction. Group IDs,
like placement IDs, use a deterministic hash domain and may use all 64 bits. They
do not advance the monotonic asset/source/region allocator.

## Composition retention and validation

The portable structural validator checks group/member identity, uniqueness,
membership counts, common region, finite horizontal front/gap and the absence of
stack edges touching row members. It deliberately does not require a current
asset profile or active support record. A pending profile/geometry edit or an
Analyze operation may leave old output on a retired surface; full regeneration
can discard an unprotected old group instead of making the document unsavable.

After protection is selected, retained rows receive current profile, allowed-yaw,
scale, support-plane, front alignment and saved-gap validation. Each member also
passes ordinary precise support, collision and access checks. Relationship
tolerances are 0.01 mm and 0.0001 degree; they do not relax the fit query. Same-row
gap replaces only sibling spacing, never penetration checks or spacing to other
props/rows. Row members cannot be stack children or support generated stack
children in this milestone.

Locking one member expands to its entire row. The bridge captures every affected
output's current upright/uniform transform and validates the complete relationship
before committing lock flags/poses. A broken or missing member rejects the command
atomically. Unlocking one member unlocks the row. Selective generation protects
complete unselected groups. Removing an in-use asset with output removal enabled
closes through entire affected rows as well as dependent stack children, then
publishes catalog, groups, placements, references and node deletion in one Undo
transaction. Other catalog assets are retained even when their row placements
are removed by that closure.

New groups are staged atomically: a rejected final member leaves no partial row,
membership or population/category counts. Query/work already spent stays charged.
The optional sixteen-bin height-profile pass moves only new unlocked rows among
at most eight alternatives plus their already-valid original poses. It preserves
member scales and row geometry, keeps standalone/stack/protected poses fixed and
selects only fully revalidated legal poses. It is a bounded per-region front-profile
objective, not global aesthetic optimization or physical stability.

`Lifecycle::composition_stats` holds optional transient statistics from the last
successful committed generation. Dirty events and state commits clear availability;
the bridge records the new counters after successful publication. Load/clone do not
deserialize statistics. Preview does not substitute its proposed counters for the
committed result. The counters are diagnostic; options, profiles and group records
are the persisted authoritative data.

## Root API and publication

All API calls are main-thread only, in `cyrus::arrange::host`:

- `create_setup(name)` returns the ordinary owning Point `INode*`.
- `get_document(setup, required)` validates the native attribute and returns its
  Document. A setup passed by the UI is the owning node consistently.
- `Document::state()` returns `shared_ptr<const DocumentState>`.
- `Document::bindings()` returns bounded native arrays of current node pointers
  for the duration of the synchronous operation.
- `commit(next, bindings, label, published)` publishes a complete successor.
  Counts must match the state and source/output rows. Missing references may
  remain null for recovery, but a generation command must reject missing enabled
  dependencies before replacing an existing result.
- `mark_clean(time, input_validity)` records the combined evaluated input
  validity after successful generation. Supply real geometry/transform validity
  for animated dependencies; `FOREVER` is appropriate only for static inputs.
- `reserve_ids(count)` reserves authored stable IDs without reusing Undo/cancelled
  identities. Increment the authored state revision when editing it.
- `flush_dependency_events()` drains queued native hierarchy notifications before
  capturing a Generate/Preview baseline. It neither solves nor publishes output.
- `disarm_live()` changes only the transient arming flag. Explicit successful
  Generate/Commit re-arms according to the saved Live preference.
- `record_composition_stats(stats)` records bounded transient counters after the
  successful generation transaction; it does not edit authored state or revision.
- `remove_document(setup)` removes native ownership while retaining ordinary
  output nodes; wrap any wider bake/detach changes in the same outer Undo hold.

An edit clones the immutable native state, validates it, builds fresh native
reference containers, and stages its Undo restore object before publication.
Staging container construction suspends Hold so it cannot leak intermediate
container edits into the user's Undo transaction. A single native restore object
keeps both before/after immutable states and real native reference containers
alive. Publication swaps the complete state and all five reference containers.

Root must use one Undo transaction for scene output materialization/deletion and
Document publication. Suppress self-notifications with `set_updating(true)`
throughout that operation, publish with `published=true`, record valid input
intervals with `mark_clean`, and clear the updating guard on every exit. On a
failure in the wider scene transaction, cancel that transaction so scene objects
and native state both recover. Native `commit` also restores its own before
state if its publication fails. It creates a hold only when the caller has none.

The restore record retains the actual old/new reference containers, not a vector
of raw node pointers. A deleted output/source can therefore participate in Max's
native reference/Undo restoration. Snapshot sharing limits duplicate native
state within history; the conservative Undo size estimate is not exact process
RAM accounting. No code clears Undo history.

Numeric and visual source capture edit owned mesh copies. Visual capture preserves
mapping channels, face material IDs and source material references while merging
an accessory group. Its transient default/material combination work runs under
native `HoldSuspend`; intermediate Multi-materials must not create Undo records
that outlive their temporary owners. Scene-node creation, final `SetMtl` and
document publication remain part of the ordinary output Undo transaction. The
workflow04/05 crash was traced to a stale material `SetSubRestore` record. The
current suspension fix passed native10 workflow06, including generation Undo/Redo.
Embedded library geometry does not serialize source materials or textures.

Mirrored visual capture saves each geometry face and its specified-normal face
before changing winding. After `Mesh::FlipNormal`, it derives the actual corner
permutation from the face's vertex identities and reassigns both normal IDs and
per-corner specified bits from that saved face. It does not assume that
`MeshNormalFace::Flip` uses the same permutation: the Max 2027 host demonstrated
different swaps. `MeshNormalSpec::Transform` then applies the geometry transform's
inverse transpose. UV corners, material IDs, smoothing groups and explicit flags
remain associated with their source triangles through group merging.

Native14 visual04 and native16 visual05 each recorded 77 passes and six failures
with the stronger distinct-per-corner fixture. Component diagnostics isolated
the mirrored part: normal directions matched other corners at dot 1.0 while the
source/snapshot vertex orders agreed. This was a native normal-ID permutation
defect, not a matrix-transform or source-oracle error. Native17 visual06 passed
83 checks after the vertex-derived remap, with zero component mismatches and
normal dots 1.0 through generation, Undo/Redo and save/reopen. The earlier SDK
Mirror sample's separate `MeshNormalFace::Flip` call was insufficient for this
runtime; measured corner correspondence determines the implementation contract.

## Save, load, clone and merge

The native `.max` chunk encodes bounded explicit little-endian fields with a magic
number and document schema version 4, including the reserved zero field. It embeds
library format 2 and unchanged registry format 1, capture policies, category rules,
furniture source keys, placement records, settings and frame metadata. Composition
options/groups follow the existing placement records. No pointer, STL structure
layout or executable script is written.

The reader explicitly accepts delivered schema 3 with its original library-1
payload. It preserves original GUID, revision, settings, frame, identities,
placements, provenance and references, adding disabled composition defaults, empty
groups and absent row profiles. New explicit saves emit schema 4/library 2; loading
does not rewrite the original scene, increment its authored revision, generate,
auto-save or arm Live. Library migration is nested inside document migration.
Unknown versions, earlier internal document schemas 1/2, malformed/trailing data
and nonzero reserved data reject. Older 0.1.1 binaries are not promised to read
schema 4/library 2; keep baseline inputs and save migrated work to new paths.

Reading validates scalar finiteness, bounded UTF-8, enum/count/byte admission,
policy/catalog sizes, identities, registry geometry, parent graphs and structural
group membership before accepting the state. Counts are checked before allocating
their buffers. The portable UTF-8 validator preserves released setup-label
acceptance, including ASCII controls other than NUL, and rejects overlong encodings,
surrogates and out-of-range code points. The decoded allocator high-water output is
assigned only after every check succeeds, including late exhausted-identity checks.

Max persists the owner attribute, Document and native containers as references;
the custom chunk does not serialize node handles as substitute references.
Loading performs no geometry evaluation. A late priority-10 callback checks the
restored reference counts and detects duplicate GUID namespaces. It marks the
setup dirty and leaves Live disarmed until one explicit successful Update.

Cloning creates an independent native document and namespace. Furniture/source/obstacle
references follow jointly cloned nodes when Max's post-patch map supplies them;
otherwise they remain shared external inputs. Managed output is retained only
when **every** output has a jointly cloned counterpart. A setup-only or partial
output clone starts without managed placement/output rows or composition groups, preventing two setups
from controlling the same output nodes. Complete joint clones retain ordered group
membership under their independent document namespace. The clone is dirty and requires Update.
Ordinary objects cloned without their setup remain ordinary objects.

The clone post-patch callback keeps immutable original bindings and original
authored state. Every invocation maps fresh local copies, so repeated backpatch
delivery cannot map an already-cloned output a second time or preserve a partial
pass's cleared rows. A native reference keeps the target Document alive for the
callback. It returns `TRUE`, matching SDK post-patch examples. This is the current
source fix for the lifecycle02 joint-clone failures; native10 lifecycle03 passed
all 89 assertions. Current tests qualify zero-offset whole-system clones. A
translated whole clone retains its old authored placement frame; automatic
translation inference is not implemented. Unlock its placements and explicitly
Generate to create a fresh arrangement on the translated furniture. This does
not promise to preserve the translated poses or old region IDs. Rotated/scaled
whole clones and protected-pose transformation are not qualified. Preview and
Analyze do not silently infer a replacement frame from edited output nodes.

Native references are canonical even when a diagnostic tag/name still reflects
the source namespace. Root can refresh tags during its next ordinary publication.
Object XRefs, published custom attributes, Save To Previous and arbitrary
third-party missing-plugin recovery remain separate qualification targets.

## Manual and Live lifecycle

Manual is the default. Geometry/topology/transform notifications and native
container null events only update bounded dirty flags/epochs; they do not solve,
clone objects or invoke MAXScript from reference callbacks. Time changes dirty a
published arrangement only when the combined input validity does not contain the
new time. Material-only notifications do not force geometry recomputation.
Furniture, asset and obstacle groups keep direct descendant references for child mesh/TM changes. A
bounded native scene hierarchy callback recognizes newly linked group members and
previously watched removed members; it only dirties the owning setup. Hierarchy
messages are polled before native Live ticks and drained before a successful
capture is marked clean. Combined furniture/asset/obstacle dependencies above 8,192 nodes
are rejected before replacing the previous complete state.

An obstacle-root deletion leaves an explicit null positional reference and dirties
the arrangement. Generate/Preview fail until that scope is repaired, cleared or
restored with Undo. A missing obstacle is never silently ignored. Relevant obstacle
animation/geometry/transform changes join the same main-thread validity and epoch
lifecycle as furniture. Unrelated nodes remain outside that dependency scope.

Root registers a native callback with
`set_live_update_callback(void (*)(INode*, Document&))`. A 250 ms Win32 timer
created on Max's main thread calls `process_live_updates`; a bounded explicit
native `caTick` can invoke that same function for deterministic tests. At most
four pending setups are processed per normal tick. Manual setups never call the
generation callback. Unchanged setups never rebuild. The registry only schedules
scene-owned Documents; it does not own or persist their authored state.

The service suspends during scene reset/open/save, Undo/Redo and rendering. It
skips active holds and reentrant updates. A failed Live attempt is not retried
continuously at the same input epoch; its error is retained until another input
change or explicit Update. Output-only edits/deletions block automatic replacement
and request Lock/Detach/explicit Update. Upstream source changes can also modify
instanced output geometry; those changes remain eligible for Live recomputation.

Live arming requires one successful published Update and is deliberately cleared
after load/clone. It is not renderer-time procedural evaluation. Actual callback
cost is synchronous; work/candidate budgets bound solver work, not wall-clock
latency. The callback must preserve complete-result rollback on any failure.

## Transient native preview

`src/preview_service.h/.cpp` implements a native post-scene
`ViewportDisplayCallback`. It draws cached diagnostic oriented bounds in world
millimetres using the SDK GraphicsWindow. Drawing performs no solve, mesh capture,
scene-node creation, MAXScript call or authored-state edit. Graphics transform and
render limits are restored after drawing. The boxes describe conservative bounds,
not a shaded copy of the proposed accessory models.

Each cache entry owns copied bounds, counts/statistics and a selected-region
scope. It also holds an immutable staged registry to preserve newly reserved
region IDs from the first Preview through Commit, and one native `SingleRefMaker`
for Document lifetime. It stores expected state identity, revision, dependency
epoch, time and system-unit scale; it does not copy asset meshes or store proposed
placement arrays. Repeated valid Preview uses its staged registry as a matching
base. Reserving IDs advances the monotonic identity high water, but Preview does
not publish a document revision, region table or placement rows.

Staging validates and allocates a complete successor before exchanging cache
entries. Failure retains the previous complete preview. After successful staging,
native Live is disarmed so a timer cannot replace committed scene output while
the artist reviews a candidate. Clear and stale-preview invalidation leave Live
disarmed. Explicit successful Generate or Commit re-arms it according to the saved
preference. Direct Generate remains available independently of Preview.

Freshness validation permanently hides and rejects a preview after a relevant
dependency epoch, authored/published state, owner, time or unit mismatch. A native
time callback prevents moving away and back from reviving it. Reset/new/open/save,
Undo/Redo and unit notifications discard transient caches. Clones inherit no
preview, and no preview data is serialized into the scene or creates scene Undo
entries. Shutdown unregisters callbacks and releases native lifetime references.

`preview_selection`, `preview_regions` and `preview_bounds` validate freshness
before returning bounded owned diagnostic data. `caCommitPreview` validates the
scope/stamp, then recomputes against unchanged current inputs using the staged
registry and performs ordinary atomic generation. It does not materialize cached
boxes. A stale or failed Commit retains the previous committed scene result.
Composition settings/profile/group edits change native state/revision and therefore
invalidate the same stamp. Preview uses the identical row/balance solver; member
bounds remain ordinary boxes, with no duplicated mesh or persistent group store in
the preview cache. Preview/Commit retains the existing staged-region-ID mechanism.

## Admission and acceptance

Bounds: 512 resident Documents including Undo-retained owners; 4,096 furniture
roots; 4,096 obstacle roots; 256 assets; 8,192 combined dependency nodes; 10,000 placements;
5,000 composition groups with at most 10,000 total member references and two-to-six
members per group; 160 MiB encoded document chunk. Generated row counts also obey
the current placement/population/category limits. Each registry admits at most 4,096
regions, 1,000,000 canonical cells, 32,768 source-key references and 64 MiB encoded
data under its own work budget. Preview cache limits are eight active setups,
10,000 boxes per setup, 80,000 total boxes and 2,000,000 retained canonical registry
cells. A failed admission preserves existing previews. Asset geometry retains its
own stricter per-asset and total limits.

The fit query separately admits at most 4,096 evaluated furniture plus obstacle
bodies combined, 1,000,000 combined triangles and 3,000,000 combined vertices.
Authored-root, descendant-watch and evaluated-geometry limits are different
admission stages. Expanded furniture/obstacle overlap and generated output used
as an obstacle reject explicitly. Obstacles do not allocate furniture source keys
or change support-region identity; they do invalidate candidate preview freshness.

Staging a successor and retaining Undo can coexist with old state, immutable
registries, reference containers and encoded save buffers. Preview's native
Document lifetime reference can retain that Document's existing scene-owned state
until the preview is cleared/pruned. These are scoped admission limits, not a
claim about whole-Max peak memory or renderer/viewport timing.

The native modules use the Max 2027 SDK and MSVC14.38. Scene-lifecycle
qualification covers: setup create/delete/Undo; metadata/source edits and
Undo/Redo; output generation then replacement/cancel; missing source/output
deletion and Undo; save/reopen/merge; setup-only clone and joint setup/output
clone; duplicate namespace repair; Manual dirty without recomputation; Live
relevant updates, idle reuse and failure retention; first-Update rearming after
load; ownership removal preserving ordinary meshes and material references.
The [release report](RELEASE_VALIDATION_0.1.3.md) identifies the matching evidence.
Installer packets must include the exact tested `.dlx` and storage companion.

## Historical 0.1.2 integration evidence — native22

These partial integration results were followed by the qualified native28
collection above. Pending wording in this record describes that earlier stage.

`build/core-composition-agent-02/receipt.json` records
a passed core-only build with all nine CTest targets, including composition,
disabled-path golden and portable document tests. The eight document suites also
pass in `build/document-state-agent-03/test-final.log`: an independent released
schema-3/library-1 writer, complete old-field preservation, schema-4/profile round
trip, every truncated prefix, malformed membership, pending invalidated metadata,
late high-water failure atomicity, UTF-8 and copy-on-write sharing. These do not
qualify Max load/clone/Undo/UI or renderer behavior by themselves.

`build/native-arrange-22/receipt.json` passes the full SDK build.
`build/host-migration-01/receipt.json` passes **60/0** on that exact pair, including
actual baseline `.max`/library migration, disabled defaults, unchanged records,
SaveAs/reopen, disabled-engine deterministic regeneration and unchanged original
input hashes. `build/host-composition-01/receipt.json` preserves **0 passes and one
failure** before its first fixture: a test function bound undeclared factory/UI
names as implicit locals before `fileIn`. Explicit test-global declarations have
been corrected; that failed run supplies no composition qualification. Composition
lifecycle execution and a refreshed matched source/test pair were pending then;
the later exact native28 release passed its own composition/lifecycle and
installer gates.

## Historical qualified 0.1.1 baseline

The delivered 0.1.1 baseline completed all ten matched native21
functional suites (654 assertions), five independent inspector JSON exports and
six Scanline images. Its exact revised r3 archive additionally passed 43 actual
installer and 12 fresh automatic-startup checks, recorded by the adjacent external
`dist/CyrusArrange-0.1.1-r3/qualification-receipt.json`. Those original receipts and
the baseline schema-3/library-1 examples remain immutable. They qualify that
0.1.1 snapshot; the schema-4/composition extension has its own qualified 0.1.2
evidence linked above.

## Earlier historical evidence

- Native09 `build/host-arrange-preview-02/result.txt`: 37 passes, zero failures,
  including first-ever Preview/Commit world centers, extents, yaw and scale using
  real output mesh bounds/transforms, and transient-cache lifecycle/admission.
- `build/host-arrange-lifecycle-02/result.txt`: 87 passes, two whole-system clone
  retention/remapping failures. The later immutable clone-callback fix compiles;
  this historical run does not qualify that fix.
- Native10 `build/host-arrange-workflow-06/result.txt`: 147 passes, zero failures;
  the material Undo suspension passed the matched generation/Undo/Redo workflow.
- Native10 `build/host-arrange-lifecycle-03/result.txt`: 89 passes, zero failures;
  the immutable clone-callback fix passed setup-only/joint clone ownership and
  remapping together with dependency, deletion, persistence and failure cases.
  Native10 compilation/core checks also passed. These receipts qualify their
  matched snapshots; the earlier failed runs remain historical evidence.
- Native10 `build/host-arrange-preview-03/result.txt`: 38 passes, zero failures,
  extending the earlier preview cases with repeated-preview determinism.
- Native12 `build/host-arrange-obstacles-01/result.txt`: 78 passes, zero failures,
  for schema-3 static collision/front access, protected failure retention,
  missing roots/Undo, descendants, Manual/Live, preview staleness, cloning,
  persistence and actual collision-rollout handlers. Its receipt verifies both
  actual loaded module paths/hashes, the frozen test identity and private profile.
- Native12 `build/host-arrange-regions-02/result.txt`: 74 passes, zero failures,
  for persistent surface metadata, per-region rules and rollout workflows.
- Native17 `build/host-arrange-visual-06/result.txt`: 83 passes, zero failures,
  with distinct authored normals at every face corner, mirrored/nonuniform
  source transforms, UV channels 1/2, materials, smoothing, explicit flags,
  source preservation, outer-hold generation Undo/Redo and save/reopen. All three
  component summaries have zero mismatches and minimum normal dot 1.0. The
  receipt verifies both actual loaded modules, binary hashes and private profile.
- Native16 `build/host-arrange-gallery-03/result.txt`: 48 passes, zero failures,
  for five original furniture categories, deterministic complete poses, material
  retention and independent full-bounds surface/hole checks. Its render01
  successor produced the saved gallery, native Scanline overview and five detail
  images. These are scoped scene/render receipts, not production-renderer or
  final-installer qualification. All receipts above qualify their exact snapshots;
  final-pair regression and installer qualification were still pending at that
  earlier stage and were completed for the later exact 0.1.1 baseline above.
