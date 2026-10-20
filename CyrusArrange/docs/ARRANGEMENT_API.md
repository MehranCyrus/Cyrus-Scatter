# Arrangement API — 0.3.1

These native C++ commands require Max 2027's main thread and the matching
`CyrusArrange.dlx`, `CyrusArrangeStorage.dlh` and MAXScript files. Native code
owns the placement engine and saved document. The [0.3.0 workflow decisions](WORKFLOW_IMPROVEMENTS_0.3.0.md)
record the additive bulk/group API scope and acceptance. Document format 4,
library format 2 and existing arrangement rows remain unchanged. Geometry reuse
and diagnostics were introduced in the preserved [0.1.3 baseline](RELEASE_VALIDATION_0.1.3.md).
The inspector/export primitives are documented separately in [NATIVE_API.md](NATIVE_API.md).

Version 0.3.1 adds the public native **Cyrus Arrange** object-space modifier and
**Cyrus Arrange Icon** helper. New setup commands create the icon with its
modifier attached. Both present the existing native document; evaluation and
selection do not generate placements. [Native presentation](NATIVE_PRESENTATION.md)
documents their class IDs and the temporary MAXScript attribute used to host
the Modify controls. That transient view is UI plumbing, not an additional
saved parameter block or geometry API. [The 0.3.1 acceptance record](REAL_WORLD_0.3.1.md)
defines its current qualification status.

`caModulePaths()` returns the actual loaded primary `.dlx` and storage `.dlh`
paths. Qualification verifies both against the frozen build; a version caption
alone does not establish that the matching pair is loaded.

All distances are physical millimetres. MAXScript arrays are one-based. Furniture
categories are TV console=1, open shelf=2, coffee table=3, kitchen counter=4,
dining table=5. Accessory categories are book=1, book stack=2, plant=3, candle=4,
frame=5, vase=6, accessory=7, bowl=8, tableware=9, kitchenware=10, tray=11.
A category mask sets bit `category-1`. All furniture bits=31; all accessory
bits=2047. IDs are opaque `Integer64` values; keep them as integers rather than
round-tripping through floating-point text conversion.

## Setup and generation

| Command | Result / behavior |
| --- | --- |
| `caCreateSetup furnitureNodes category` | Creates and returns an ordinary setup node with native document ownership. Groups expand natively. Inputs must not contain generated output |
| `caSetupSummary setup` | `#(guid, label, revision, assetCount, placementCount, dirtyMask, live, error, settings)`; reads retained state only |
| `caSetArrangeSettings setup settings` | Saves a complete settings row and marks pending; returns true |
| `caGenerate setup regionIDs` | Stages, validates and publishes the full successor in one Undo transaction; empty IDs regenerates all unlocked regions |
| `caOutputRows setup` | Placement rows shown below; does not inspect or generate |
| `caSetLocked setup placementIDs lock` | Saves locks. When locking, captures each actual output's current upright uniform-scale transform |
| `caTick()` | Services at most four eligible dirty Live setups; returns the number serviced. UI scripts do not schedule their own calculation timer |

Settings is exactly eleven fields:

```maxscript
#(seed, density, spacingMM, edgeMM, clusterStrength, heightVariation,
  emptySpace, style, category, sampleSpacingMM, live)
```

Style is minimal=1, balanced=2, layered=3. Density, clustering, height variation
and empty space lie in [0,1]. Seed is an integer; the artist UI supports
0..9223372036854775807 exactly. Current defaults admit up to 2,000 placements,
100,000 candidates and stack depth four; native hard ceilings are separate
validation limits, not artist UI settings.

Generation/Preview/Commit return exactly six fields:

```maxscript
#(requested, accepted, kept, candidates, underfilled, warnings)
```

The first five fields are exact native `Integer64` counts; warnings is a string
array. Generate/Preview/Commit use the same row shape. Preview reports its pending
solve, while Commit reports its current recomputation. The artist UI removes the
literal `L`/`l` suffix from requested/accepted/kept/underfilled display text; this
does not change the native numbers or make an underfilled result complete.

Output rows have nine fields:

```maxscript
#(placementID, assetID, regionID, worldMMContactPosition,
  yawDegrees, uniformScale, locked, parentPlacementID, outputNode)
```

`parentPlacementID=0` means direct furniture support. A missing output binding is
`undefined`. Selective regeneration retains records on unselected regions and
the complete connected stack of a protected placement. A locked placement that
no longer fits causes an atomic failure. Current generation creates successor
output nodes even for retained records: record IDs/poses remain stable; Max node
handles are not promised stable across successful generation. Failure retains
the actual previous nodes. Only transforms of locked objects are captured;
manual mesh/material edits are not authored accessory overrides.

Book-row lock/unlock expands to every member of the native relationship. This
protects placement records, not the lifetime of those Max node instances; use
fresh `caOutputRows` references after a successful successor.

## Asset registration and reusable geometry

### Atomic quick intake (0.3.0)

```maxscript
caRegisterAssets setup sourceNodes category
-- #(addedAssetIDs, alreadyAvailableAssetIDs)

caCreatePropGroup setup sourceNodes name category
-- #(newCopiedSourceGroup, assetID)
```

These are native C++ commands on Max's main thread. Bulk registration normalizes
selected outer group roots and duplicate nodes, stages every new asset, then
publishes once. A repeated actual source reference in the same setup is returned
in the already-available array; existing metadata is untouched. A different setup
may register that same source independently. No placements are generated by intake.

Quick defaults are all furniture categories, weight 1, uniform scale 1, no stacking,
and allowed yaw angles 0/90/180/270 degrees. All sources share the explicit category
argument; the detailed metadata API can edit entries individually afterward.
Every final generated yaw/scale is validated by the existing placement engine.

Decor group creation requires at least two normalized source models/groups. It
copies the selected hierarchy at the current time with no positional offset and
groups those copies into one new source asset. It preserves original nodes,
materials, hierarchy and world poses. Relative piece positions define the group;
the command does not compose separated pieces. Output generation still produces
the retained flattened mesh per placement. Saving the scene retains the reusable
source hierarchy; portable geometry libraries do not acquire source materials.

Both commands reject forbidden ownership, unsupported/ambiguous hierarchy, invalid
geometry or exhausted admissions before publication. The catalog limit is 256
assets; retained native geometry limits still apply. Selection order is normalized
by actual node handles. One Undo includes the full successful catalog change and,
for a decor group, its copied nodes. Failure retains the prior catalog/settings/
output; monotonic opaque ID reservations can advance. The UI additionally rejects
a stale Props window after its main arrangement owner changes.

### Detailed single-asset controls

```maxscript
caRegisterAsset setup source name category furnitureMask yaws weight minScale maxScale stackable
caUpdateAsset setup assetID name category furnitureMask yaws weight minScale maxScale stackable
caRebindAsset setup assetID source
caUseStoredAsset setup assetID
caRemoveAssets setup assetIDs removeOwnedOutputs
caRefreshAssets setup
caSaveAssetLibrary setup path
caLoadAssetLibrary setup path
```

Registration returns a new asset ID. Update/Rebind/UseStored/Refresh/Save/Load
return true. Remove returns `#(removedAssets, removedPlacements)`; false for
`removeOwnedOutputs` rejects assets still in use. True removes their owned
outputs and stack descendants in one Undo transaction, preserving source models.
Load appends imported assets with new IDs. It does not replace the existing
collection. `.cyalib` stores geometry and metadata only; bound scene sources
supply their visual materials/maps when generating.

Deleting a required scene source does not silently turn it into an imported
asset. Rebind the missing source, explicitly choose stored geometry, or Undo
the deletion. The previous published result survives until a valid successor.

`caAssetRows setup` returns rows of ten fields:

```maxscript
#(id, name, category, dimensionsMM, furnitureMask,
  weight, minScale, maxScale, stackable, sourceValid)
```

`caAssetDetail setup assetID` returns thirteen fields:

```maxscript
#(id, name, category, furnitureMask, yaws, weight, minScale, maxScale,
  stackable, sourceState, sourceNode, sourceLabel, #(authoredContact, authoredStack))
```

Source state: bound=1, embedded geometry=2, missing required source=3. Dimensions
are canonical bounds, not a semantic width/depth prediction. Source group parts
are flattened into one asset in their evaluated orientation. Source geometry is
copied; it is never modified by registration or generation.

The captured asset frame uses physical millimetres and scene-world-oriented
axes. Capture queries explicit `GetObjTMAfterWSM` before fresh evaluation and
applies that final-pipeline transform to vertices, removes the
base-bounds-centre translation, and leaves rotation/scale baked into geometry.
It does not invert the source pivot's rotation. Contact/top coordinates, bounds
and the authored spine face use this frame; allowed yaw rotates it about +Z.
Explicit authored support survives source capture and is revalidated rather
than replaced silently.

`caAssetSupport setup assetID` returns:

```maxscript
#(anchor, contactPoints, stackEnabled, stackHeight, topPoints,
  allowedTopMask, #(authoredContact, authoredStack), boundsMin, boundsMax)
```

Use `caSetAssetSupport setup assetID anchor contactPoints stackEnabled stackHeight topPoints allowedTopMask`
to author these fields, or `caResetAssetSupport setup assetID` to derive defaults.
Coordinates are asset-local millimetres. Convex contact/top footprints have at
most 64 points and must pass native validation. Stack tops must be supported by
the actual captured planar surface. Automatic stack-top capture is restricted
to books and book stacks; other shapes require an authored top patch.

## Category rules and identification

`caCategoryRules setup furnitureCategory` returns eleven rows of
`#(accessoryCategory, weight, maximumCountPerRegion, allowOnStack)`.
`caSetCategoryRules setup furnitureCategory rows` replaces the complete set;
`caResetCategoryRules setup furnitureCategory` restores its native preset.
A zero maximum disables that category. Asset furniture masks, furniture category
rules and region masks must all permit a placement.

Selection is weighted per eligible **asset**: `asset.weight * rule.weight`.
Category weights are not normalized into separate category quotas. With three
eligible Books and one Vase, all weights equal to 1 give Book entries three of
four draw shares before fit rejection. Current counts, surface masks, compatible
row yaws and stack eligibility further filter candidates. Within a Book-only
member draw, the shared Book category multiplier cancels; individual asset
weights still matter. The regional population target uses the weighted mean
eligible footprint/scale/spacing slot area, so changing library weights can also
change the requested count. Count ceilings and rejected fits can leave it
underfilled. Preset occupancy/edge/gap record fields do not override the current
setup's density, edge or spacing settings.

`caSuggestFurniture furnitureNodes` returns `#(categoryOrZero, reason)`.
An integer `CyrusArrangeFurnitureCategory` user property from 1 to 5 is the
explicit tag. Invalid/conflicting tags or ambiguous names return zero with a
reason. Naming suggestions do not override explicit tags, and do not perform
visual object recognition.

## Surfaces and authored regional policy

`caAnalyzeSetup setup` captures furniture, reconciles persistent region IDs,
publishes measured metadata and returns the region count. It needs no accessory
assets. It retains placement records and all existing output nodes, marks the
document pending, and participates in Undo. Armed Live may subsequently process
that authored change. `caRegionRows setup` only reads the retained registry.

Each surface row has thirteen fields:

```maxscript
#(id, label, compartmentLabel, role, worldBoundsMinMM, worldBoundsMaxMM,
  minimumClearanceMM, openAbove, accessoryMask, densityMultiplier,
  allowStacking, excluded, worldFrontDirection)
```

Clearance -1 means infinity. Bounds are derived from sampled cells, not exact
mesh boundaries. Role is unknown=1, exposed top=2, open shelf=3, tray=4, ledge=5.
Labels, compartment labels and roles are authored descriptive metadata. They do
not claim automatic recognition of shelf contents or cabinet construction.

```maxscript
caSetRegionRules setup id label compartmentLabel role accessoryMask densityMultiplier allowStacking excluded worldFrontDirection
```

The setter requires a current stable ID, printable UTF-8 labels of at most
512 bytes, density multiplier [0,4] and a finite nonzero horizontal front vector.
Mask zero denies every accessory category. Exclusions remain in the registry;
they do not become missing identities. Zero density preserves protected props
but generates none. Mask/exclusion/no-stacking conflicts with protected props
reject generation rather than deleting those props.
An excluded region filters placement anchors on that support; it does not create
a separate keep-clear volume across neighboring regions. Use explicit obstacle
geometry for that physical scope.

Exact sampled geometry plus persistent source scope determines identity.
Equivalent retessellation can keep IDs; changed/split/merged support may retire
them. IDs are never recycled across Undo or failed publication. Analyze after
geometry edits and select current surfaces before selective regeneration. See
[REGION_REGISTRY.md](REGION_REGISTRY.md) for matching and bounds.

## Preview and scene lifecycle

| Command | Behavior |
| --- | --- |
| `caPreview setup regionIDs` | Computes bounded transient viewport boxes and returns generation statistics; creates no output nodes and changes no authored revision |
| `caPreviewInfo setup` | `#(present, valid, boxCount, reason)` |
| `caPreviewBounds setup` | Rows `#(worldMMCenter, halfExtentsMM, yawDegrees)` for independent inspection |
| `caCommitPreview setup` | Requires a current preview, reuses provisional region IDs, recomputes and publishes the matching result |
| `caClearPreview setup` | Clears transient boxes; returns whether a preview existed |

Preview disarms Live. Clear does not rearm it; explicit successful Generate or
Commit does. Relevant geometry, settings, time, unit and ownership changes make
a preview stale. Stale Commit fails while retaining published nodes. Save,
load, reset and Undo/Redo clear the transient cache. The cache admits eight
setups, 10,000 boxes per setup, 80,000 total boxes and two million canonical
surface cells. Viewport redraw uses copied boxes and never runs a solver.

Native documents and SDK references persist in `.max` scenes. Load leaves Live
unarmed until an explicit successful update. Clone creates a separate document
namespace. Zero-offset whole-system clones have qualified remapped references;
translated whole-system clones do not automatically reconcile saved frame/poses:
unlock retained props and explicitly Generate before relying on the new result.
Rotated/scaled clone reconciliation is not promised. Relevant bound group
members and hierarchy changes invalidate work, while unrelated scene edits and
UI browsing do not rebuild placements. All host geometry evaluation/publication
is synchronous on the main thread. Budgets bound native work, not total Max RAM.

## Development fit feedback (0.3.2)

`caFitFeedback setup assetID` is a passive bounded read of the last accepted
generation's transient native report. It returns thirteen fields:

| Index | Value |
| --- | --- |
| 1 | Fresh report exists for this source |
| 2 | Artist explanation; stale/missing reports ask for Generate |
| 3 | Issue code: None0, Support1, Width2, Depth3, Height4, Occupied5, Spacing6, Access7, Stack8, Excluded9, Lane10, Search11 |
| 4 | Physically verified suggested scale factor, or zero |
| 5 | Suggested factor is below the current minimum |
| 6 | A checked location is available for highlighting |
| 7 | A physically verified candidate is available |
| 8 | Accepted minimum factor |
| 9 | Attempted factor at the reported location |
| 10 | Region/lane ID at that location |
| 11 | Separate diagnostic probe count, at most4096 |
| 12 | Separate conservative diagnostic work charge, at most5000000 |
| 13 | Applicable percentage checked after float-spinner conversion; zero disables the draft action |

`caShowFitFeedback setup assetID` draws one/two copied world-mm boxes and returns
their count. Orange marks context/obstruction; green marks a verified candidate.
It creates/selects no scene nodes and does not replace a staged Preview.
`caHideFitFeedback setup` clears only that setup's fit highlight.
`caFitHighlightInfo setup` returns `#(present, valid, assetID, boxCount,
hasVerifiedCandidate, completedDrawCalls, boxes)`; each box is
`#(worldCenterMM, halfExtentsMM, yawDegrees)`. Stale boxes are diagnostic data and
are not drawn. This read creates no query or placements.

Advice never changes authored settings, source geometry or output. The Modify
action edits the visible global Shrink to fit minimum; Generate applies it in
the ordinary native transaction. A checked candidate is not an optimal-size or
exhaustive-packing proof. Reports are not saved or put in Undo history. Relevant
inputs, Undo, load, time or system-unit changes require fresh feedback. See
[the implementation contract and evidence](FIT_FEEDBACK_0.3.2.md).

## Independent obstacles and approach requirement

Development 0.3.2 adds `caAddObstacles setup nodeArray`: normalize and merge
explicit roots without losing existing missing-reference slots. The native
`caRemoveObstacle setup oneBasedRow expectedRevision` removes one cached row;
pass the revision returned by `caSetupSummary` when reading the list. A stale
revision is rejected before mutation. These commands share the native scope
validator and Undoable commit. Prop, receiver, path, owner and managed-output
overlap are rejected. Opening the inline Keep clear view only reads references.

The development minimum-generation commands accept an optional final
`requireFrontAccess` boolean: `caGeneratePlacementMinimums` takes four or five
arguments, and `caGeneratePathMinimums` takes five or six. Without it the saved
flag is retained. With it, this draft is staged with the visible settings,
minimums, seed and outputs; failure leaves all accepted values unchanged. This
does not make path-only placement require support geometry. The existing saved
flag and schema7 are unchanged. Full release/installer acceptance is pending.

`caCollisionScope setup` returns `#(requireFrontAccess, obstacleRows)`; each row
is `#(sourceNodeOrUndefined, sourceLabel)`. This is a passive reference read.
`caSetCollisionScope setup nodeArray requireFrontAccess` saves an explicit scope;
an empty array clears it. Closed groups expand natively and selected child/root
duplicates normalize. Up to 4,096 roots are admitted, subject to the stricter
combined geometry/dependency limits at evaluation. Furniture and obstacle
scopes may not contain the same expanded geometry node, and generated Arrange
output cannot be a source. This is a source-identity restriction, not a claim that
separate obstacle geometry can never intersect furniture.

Furniture alone supplies support regions and sampled clearance measurements.
Obstacles participate in collision, closed-solid containment and approach
validation, but their tops never become support. This permits a TV, existing
lamp or other explicitly chosen geometry to block an arrangement without
receiving decorations. Other unselected scene objects are outside the scope.
Deleting a bound obstacle leaves a missing reference and rejects generation
until it is removed, replaced or restored by Undo.

The horizontal approach check is initially enabled for TV consoles/open shelves
and disabled for coffee tables/kitchen counters/dining tables. It uses each
surface's authored front direction. Turning it off still enforces physical
collision and support. Changing the furniture category later does not overwrite
this explicitly authored setting. The collision panel offers an explicit Apply
action and never generates just because it is opened or refreshed.

The preserved qualified 0.1.1 baseline uses document schema 3 and library/registry format 1. The qualified 0.1.2 release writes document 4/library 2 and explicitly reads that supported baseline; registry format 1 is unchanged. Internal document schemas 1/2 remain unsupported.


## Book rows — 0.1.2 contract

These commands are included in the qualified 0.1.2 pair; 0.1.1 receipts do not cover them.
Existing settings, generation, output and asset array shapes remain unchanged.

| Command | Result or arguments |
| --- | --- |
| `caCompositionSettings setup` | `#(bookRows, minimumBooks, maximumBooks, gapMM, rowHeightBalance)` |
| `caSetCompositionSettings setup options` | Saves all five options. Rows default off; min/max are 2..6, min <= max; finite gap 0..1,000,000 mm; balance 0..1. Enabled composition supports TV consoles/open shelves only. |
| `caAssetBookRow setup assetID` | Tag 0 for ineligible; 1=-X, 2=+X, 3=-Y, 4=+Y authored spine face in the captured asset frame. |
| `caSetAssetBookRow setup assetID tag` | Explicitly sets/removes the profile. Only Book assets may carry one; no category/name/dimension inference. |
| `caCompositionRows setup` | Bounded group rows `#(groupID, kind, regionID, memberIDs, savedFront, savedGapMM)`; kind1 is BookRow; each ordered row has 2..6 separately generated members. |
| `caCompositionStats setup` | `#(available, rowAttempts, newRowsFormed, rowFailures, balanceAnchorAttempts, rowsMoved)` for the last current successful generation. Transient; edits/load clear availability. |

Each row member consumes a normal population/category slot and has its own output node and placement ID. Full-box envelopes align to the regional front using allowed yaw angles; the saved gap overrides only pair spacing between members of that same group. Collision, support, edge and approach rules remain active. The row is staged atomically; rejected attempts consume work but publish no siblings or counts. Initial rows cannot contain or support stack children.

Profiles describe the physical outside spine in the captured frame, not source
pivot or camera axes. The tag remains authored metadata through Refresh,
Generate's recapture and Rebind. These commands do not infer printed geometry
or reinterpret the side after a rotation, mirror or replacement. For example,
a -Y source spine rotated +90 degrees about world Z faces +X in the new capture;
the caller must explicitly change its profile/yaws as appropriate. A valid tag
alone is not semantic proof that the modeled spine is on that face. Only saved
allowed yaws aligning the profile to the regional front within 0.0001 degrees
are admitted. The profile does not force scale 1; existing asset scale limits
and variation still apply.

Locking or unlocking one member applies to the whole row. Locking reads every
member's real output transform and validates the retained relationship before
one commit. A broken/missing member rejects a **lock** attempt without partial
locks; unlocking can release the complete row before regeneration. Generation
revalidates protected rows against current profiles, fronts and geometry.
Unselected regions retain complete groups. Protected groups retain their saved
gap if new-row settings change or row formation is disabled. Full regeneration
discards unprotected old groups and can form replacements. Removing an in-use
asset with output removal enabled removes complete affected rows and supported
stack descendants; unrelated catalog assets remain registered. Successful
publication can replace every output node, including retained locked members;
placement/group records and poses are the stable relationship, not node handles.

Row height balance considers the original pose and at most eight deterministic
XY translations of each new, unlocked row in its existing horizontal region.
The sampled support must stay within 0.01 mm of one plane. It keeps assets,
scales, yaw, internal geometry and other props fixed; every translated member
passes the normal region, support, collision, spacing and approach checks.
Candidate/work limits still apply and can reject the entire solve.

The objective uses sixteen lateral bins and the maximum accepted-prop height
in each bin, relative to the regional front. Let `B` be its normalized absolute
height moment, `b` the balance setting, and `d` the XY move divided by the
regional diagonal, clamped to 1. A proposed pose scores `(1-b)*d + b*B`; the
original scores `b*B(original)`. A move requires a strictly better score and
`B <= B(original)`; ties keep the original. This is a bounded profile proxy,
not physical stability, a global optimum or a camera-based quality score.
Zero bypasses the pass, and Balanced style does not enable it. Preview uses the
same native solve and existing registry identity handling as Commit. See
[COMPOSITION_DESIGN.md](COMPOSITION_DESIGN.md) for the design and evidence scope.

Schema-3 scenes and library-1 assets load in memory with disabled composition, empty groups and absent profiles. Loading does not generate, increment authored revision, arm Live or overwrite the file. The next explicit save emits schema4/library2; older plugins cannot read those new formats. Unsupported/corrupt input rejects without an empty-state fallback.

## Retained numerical support and geometry reuse (introduced in 0.1.3)

Arrangement support inspection uses zero-degree slope with a bounded numerical
flatness allowance for an upward triangle whose full Z span is at most the shared
**0.002 mm** contact tolerance. The exact query retains true source min/max Z per
height bin and admits a bin only when both extrema are within its contact
tolerance of the candidate base. Eligible polygons are united before edge inset;
holes, physical collision, spacing and required front approach remain active.
This does not flatten sources, relax footprint containment or allow tolerance to
accumulate along an inclined ramp. Disjoint outliers in one bin can conservatively
reject otherwise local support. See [NUMERICAL_SUPPORT.md](NUMERICAL_SUPPORT.md).

Generate, Preview and Commit can reuse immutable furniture inspection/query data
at the same scene time; current registry reconciliation, bound asset capture,
policies, solve and publication still run. Analyze stays cold and furniture-only.
The working process default enables reuse. These additive diagnostic calls do
not change placement rows, document schema4, library2 or registry1:

| Command | Result / behavior |
| --- | --- |
| `caGeometryCacheEnabled()` | Current process toggle |
| `caSetGeometryCacheEnabled value` | Returns the prior toggle; disabling clears numeric resident entries |
| `caClearGeometryCache setup` | Clears this instance's optional retained numeric data; returns true |
| `caClearAllGeometryCaches()` | Clears optional numeric data globally; returns true |
| `caGeometryDependencyInfo setup` | `#(1, instance, sceneEpoch, geometryEpoch, reusable)` |
| `caGeometryCacheInfo setup` | `#(1, serviceEnabled, lastOrUndefined, totals, phases)`; passive diagnostics, not a freshness check |

Clearing/disabling reuse does not author settings, increment revision, change
Preview validity, rearm Live or change generated nodes. Required dependency
observation stays active in both modes. `serviceEnabled` also requires an existing
numeric service, so a true process toggle alone need not make it true. Totals are
global and last-command metrics are per document. Full field order, admission,
lease accounting and failure boundaries are in [CACHE_RUNTIME.md](CACHE_RUNTIME.md).


## 0.2.0 compact-workflow commands

| Command | Contract |
| --- | --- |
| `caSceneSetups #(selectedNodes)` | Returns `#(#(ownerNode, matchedBoolean, #(furnitureRoots)), ...)` in owner-handle order. Empty selection lists current setups with no match. Passive, bounded, authoritative native references; no capture or solve. |
| `caGenerateVariation setup settings11 regionIDs randomizeBoolean` | Existing six-field generation result. Stages the eleven settings and optionally a new nonnegative63-bit seed; commits settings/seed/output together on success. A false randomize flag uses the supplied seed. |
| `caShowArrangeUI setup:node` | Compact main UI; explicit setup wins initial selection discovery. Without a setup, a unique relevant match (or only existing setup) is chosen; multiple matches require a list choice. |
| `caShowAdvancedArrangeUI setup:node` | Detailed controls for the same native document. |

The original `caGenerate setup regionIDs` remains deterministic. Its callers do
not silently receive a new seed. The compact Generate button uses the new staged
command. Repeat seed is an unsaved window preference; the resulting used seed is
stored in the existing arrangement settings. The API does not promise a different
visible layout for every new seed under locks or restrictive geometry/rules.
