# Current source to proposed recipe field map

15 October 2026; source baseline **0.82.4 / schema 58**. This is a design inventory, not a serializer or an executed round-trip test. Phase 6 remains paused. The [contract](PRESET_CONTRACT.md) defines completeness; the [plan](IMPLEMENTATION_PLAN.md) assigns implementation gates.

The companion [PARAMETER_INVENTORY.csv](PARAMETER_INVENTORY.csv) enumerates every `name type:#...` declaration in the authoritative controller and source-container templates, with source line, raw type, default expression, proposed semantic group and handling policy. Its purpose is to prevent omissions. It does not pretend that declaration defaults define all engine ranges or that a generic property dump is a valid recipe. Native records below supplement it.

## Capture policies and round-trip rules

- **Value:** preserve the authored value, including inactive values, with explicit physical units. A static controller's current value is supported; animated/wired controllers require a supported graph adapter or block complete export.
- **Role/remap:** preserve relationship/ordering through file-local IDs and resolve new scene IDs/references on import. Never copy raw node handles.
- **Native document:** preserve a versioned authored payload and its binding context. Stage a new owned object; do not share mutable Paint between imported layers.
- **Preference:** save in a separate preferences block. Add preserves destination global preferences; a new setup can restore captured preferences after authored commit. Active overlays/tools do not start automatically.
- **Derived/transient:** reconstruct; do not serialize cached output, validation flags, UI selection or identity allocators. This is intentional exclusion from authored fidelity.
- **Guarded:** preservation needs a dedicated adapter. Unsupported nonempty authored data blocks Save Everything and is never silently discarded.

For an aligned tab, retain every authored row, including inactive/missing-node and Point/Empty rows. Use stable file-local row IDs for membership; do not compact arrays according to currently valid models. Missing default entries in current Max tabs are interpreted through the actual source helper, then captured explicitly without mutating the artist's object. The CSV records literal defaults; runtime helper defaults are specified below. Import never guesses required fields from defaults of a newer plugin.

## Controller, layers and identity

| Current source properties | Proposed ownership / destination | Capture/apply policy |
| --- | --- | --- |
| `layerObjects`, `layerNames`, `layerEnabled`, `layerVisible` | Ordered `layers[]` records | Capture names/enabled/visibility and exact order. Recreate objects; no raw `maxObject` serialization. Hidden and disabled differ: hidden may still calculate. |
| `layerID`, `logicalParentID`, `isPaintArea`, `paintAreas`, `areaTarget` | Owner IDs, parent edges, area records and receiver role | Fresh scene IDs with one remap; keep authored parentage and area order. Do not recreate retired model-owning Paint-set semantics. |
| `paintSetName`, `paintSetEnabled`, `paintSetVisible`, `layerIDColor` | Layer/area authored label/state/identification | Preserve separately from controller enable and transient UI selection. |
| `cyrusEnabled`, `updateMode` | `setupPreferences` | Save both. Add does not overwrite destination state; new setup activates its saved mode only after transaction completion. |
| `procOrder`, `procSetOrder` | Evaluation order metadata | Derive destination ranks from preserved owner order; reject inconsistent input rather than allow a second contradictory priority order. |
| `randomSeed`, `procSamplingSalt` | Layer sampling settings | Preserve explicit numeric values as inputs to `effectiveSeed`; new receiver identities still follow existing policy. Do not claim exact cross-scene placement parity solely from equal seed. |
| `procSourceNodes`, `procSourceIDs`, `procSourceSlots`, `procReceiverNodes`, `procReceiverIDs`, `procReceiverID` | Persistent correspondence records | Convert persistent roles/slot order to a remap. Inactive correspondence needed by authored Edit must be retained or guarded, not mistaken for a disposable cache. Do not reuse foreign scene IDs. |
| `sourceRowIDs`, `pathIDs`, `strokeIDs`, `strokePathIDs`, `visualSourceKeys` | File-local rows/Paths/Bands/visual identity edges | Allocate fresh scene IDs and rebuild cross-references. Preserve original authored ordering. |
| `nextPathID`, `nextBandID`, `nextEditLayerKey`, `editLayerKey` | Allocators / Edit owner mapping | Recompute fresh allocators; map existing authored Edit ownership through a qualified adapter. |
| `procSchemaValid`, `activeLayer`, `uiAreaID` | Validation/UI state | Revalidate/reset; never export a stale validity result or selection as authored planting behavior. |

## Population, source assignment and transforms

| Semantic record | Exact source fields | Units, defaults and required treatment |
| --- | --- | --- |
| Amount | `amount`, `populationMode`, `plantsPerM2` | `amount` is count/cap; density is instances/m². Save both even when one is inactive. Declared defaults 200 / Count / 100 per m². Preserve candidate budget versus accepted target. |
| Bounded retries | `procPopulation`, `procAttemptFactor`, `procRounds`, `procRepair` | Candidate budget/Accepted target, attempt factor 1..32, rounds 1..16, repair flag. Declared defaults 1/8/8/true. Root admission is still shared. |
| Source layout | `diversityMode`, `diversitySize`, `diversitySeed`, `roughness`, `blurryEdge`, `diversityNoise` | Random/Clusters/Bands/Analyzer; size is a distance; noise/roughness/blur are UI percentages converted at the engine boundary. Preserve unused cluster settings. |
| Basic transforms | `scaleMinimum`, `scaleMaximum`, `tiltDegrees`, `yawMinimum`, `yawMaximum`, `movementRange` | Dimensionless scales, degrees, physical movement. Preserve inactive basic controls when advanced axes are enabled. |
| Axis transforms | `advancedAxes`, `alignNormal`, `projectMove`, `rotXMin/Max`, `rotYMin/Max`, `rotZMin/Max`, `sclXMin/Max`, `sclYMin/Max`, `sclZMin/Max`, `movXMinWU/MaxWU`, `movYMinWU/MaxWU`, `movZMinWU/MaxWU` | Store all ranges; ordered min/max, degrees, multipliers and metres. `alignNormal=false` means world-up; true currently means geometric triangle normal. Keep on surface is independent. |
| Whole-layer scale | `wholeScaleMin`, `wholeScaleMax` | Dimensionless additional multiplier range; both default 1. It is distinct from axis, source, Band and Paint scales. |
| Generation Relax | `relaxEnabled`, `relaxSpacing`, `relaxIterations`, `relaxStrength` | Spacing is distance, iterations integer, strength dimensionless. Preserve disabled settings; do not merge with final Relax. |
| Final Relax / cleanup | `finalRelax`, `finalStrength`, `finalIterations`, `finalMaxMove`, `finalCleanup`, `finalNeighborRadius`, `finalMinNeighbors`, `finalMinIsland`, `cleanupPlanar` | Max move/neighbor radius are distances; planar choice changes metric. Preserve every stage and inactive value; existing acceptance/cleanup ordering remains unchanged. |

`movementRange`, declaration values such as `finalNeighborRadius=100`, and other `#worldUnits` defaults are scene-unit values at initialization, not automatically metres. Capture actual values through the unit conversion boundary. Do not copy the declaration's number into a metre field unconverted.

## Sources, groups and containers

| Current fields | Proposed record | Required behavior |
| --- | --- | --- |
| `sources`, `sourcePoint`, `sourceEmpty`, `sourceRowIDs` | `sourceRows[]` with model role / Point / Empty kind | Preserve rows/order, intentional duplicates, missing references and dormant original model links. Point is represented by `sourcePoint=true` with `sourceEmpty=true`; do not mistake it for a weighted gap. |
| `sourceWeights`, `sourceScales`, `sourceZOffsetsWU`, `sourceForwardAxes` | Weight, scale, lift metres, forward-axis token | Helpers default weight/scale to 1, lift to 0 and forward to +Y. Save explicit resolved values. Do not normalize weights destructively. |
| `sourceRadiiWU`, `sourceAutoRadius`, `sourceFollowScale`, `sourceShowRadius` | Manual radius metres, requested Auto mode, Follow Scale, presentation preference | Defaults radius 0 and flags false. Preserve saved Auto/manual settings even if Point/Empty makes Auto ineffective. Auto failure is an error, never a silent Manual fallback. |
| `sourceColors` | Assignment group membership keys | Current group key is rounded RGB packed as `R*65536 + G*256 + B`. Preserve exact group identity/color and membership. Do not infer group membership from displayed identification colors. |
| `visualSourceKeys`, `visualSourceLabels`, `visualSourceColors`, `visualSourceColorSet` | Row/model alias and identification records | Remap keys; preserve label/color override and whether it was explicitly set. Repeated source rows do not automatically become distinct geometry assets. |
| `containerMode`, `containerNodes`, `containerGlobalNodes` | Source collection policy and container roles | Preserve requested policy and references. Global/shared dependencies are visible in the recipe summary. Unsupported inherited ownership cannot be flattened silently. |
| Container `width`, `length`, `collectEnabled`, `showLabel` | Container dimensions/collection/presentation | Distances and collection behavior are authored. Existing container role binding must validate them or require an explicit difference; moving/rewriting an artist's container is not implied by Add. |
| Container `savedSources`, `movementSources`, `containerID`, `contextRootID`, `contextSetID` | Source dependency/membership roles, fresh container ID, editing-context links | Preserve authored saved membership; derive transient movement eligibility on restore. Remap durable editing context rather than point into the source scene. |

Container helper native movement state, cached consumer rows/labels and scan keys are derived. An optional package can preserve the helper's node transform and hierarchy; a role-only recipe records those requirements without secretly copying the whole scene. Collection off does not delete its saved source settings.

## Mesh/texture masks, areas and Analyzer

| Record | Exact fields | Rules |
| --- | --- | --- |
| Receiver list | `surfaceNodes`, `surface` | Preserve ordered receiver roles. `surface` is a declared single-node fallback; current valid receivers are authoritative. Normalize the supported representation on capture without mutating the source. |
| Texture density | `distributionMode`, `densityMap`, `invertDensity`, `densityUVChannel`, `densityResolution` | Save mode, map role, invert, UV channel and resolution, including dormant map reference. Current UI selects Uniform or Map; supported numeric mode must be checked against the declared evaluation contract. Do not convert a Texmap to a mesh-channel role. |
| Mesh density | `meshMaskEnabled`, `meshMaskChannel`, `meshMaskComponent`, `meshMaskMinimum`, `meshMaskMaximum`, `meshMaskInvert`, `meshMaskSamples`, `meshMaskGraph` | Disabled / channel 0 / component 1 / 0..1 / not inverted are declaration defaults. Empty samples mean effective linear `[0,1]` today. Preserve authored empty-versus-explicit representation or record that declared normalization; preserve graph handles. |
| Slope | `slopeEnabled`, `slopeMinimum`, `slopeMaximum`, `slopeLowerFade`, `slopeUpperFade` | Degrees 0..180, oriented geometric normal against world +Z. Preserve inside fades and nonoverlap validity. No absolute-normal or shading-normal substitution. |
| Altitude | `altitudeEnabled`, `altitudeMinimum`, `altitudeMaximum`, `altitudeLowerFade`, `altitudeUpperFade` | Physical world-Z distances and datum. Save inactive ranges; preserve anchored eligibility semantics. |
| Include/Exclude areas | `areaNodes`, `areaModes` | Ordered roles with explicit Include/Exclude tokens. Preserve missing/disabled dependencies honestly. |
| Per-area falloff | `areaFallConfigs`, `areaFallDeleteWidths`, `areaFallScaleWidths`, `areaFallDensityWidths`, `areaFallScaleGraphs`, `areaFallDensityGraphs` | Decode flags/curve samples into typed data; physical widths come from the world-unit tabs, not old string slots. Retain separate delete/scale/density widths and graphs, including inactive values. |
| Analyzer boundary falloff | `fallAnalyzer`, `fallDelete`, `fallDeleteWidth`, `fallScale`, `fallScaleWidth`, `fallScaleCurve`, `fallDensity`, `fallDensityWidth`, `fallDensityCurve`, `fallScaleGraph`, `fallDensityGraph` | Analyzer role plus independent flags/widths/curves. The same graph field names are also used on Paint Area owners; route by captured owner type. |
| Analyzer coverage | `areaAnalyzer`, `areaUseLine`, `areaLineWidth`, `areaLineCaps`, `areaUsePoints`, `areaPointRadius` | Line width is full width; the bridge uses half width. Lines and points can union. Preserve both inactive configurations and Analyzer freshness requirement. |
| Analyzer assignment | `analyzerNode` and applicable Band/street fields below | Bind published Analyzer data; do not serialize cached generated Analyzer paths as if authored splines, or run Analyze during browsing. |

Mesh channel 0..99, component X/Y/Z, finite ordered input range and 2..257 unit samples follow `mesh_density.cpp`. The actual layer owns one selected channel/component for all its receivers. Role suggestions cannot silently introduce different per-receiver selections absent engine support. Texture UI resolutions are 64/128/256/512; export/import must use the qualified texture validator, not accept any power of two.

## Paths and Bands

| Record | Current fields | Required semantics |
| --- | --- | --- |
| Path | `patternPaths`, `pathIDs`, `pathJoins` | Role, fresh ID, Rounded/Sharp corners. Preserve Path order; at most 32 per layer today. |
| Band identity/order | `patternLines`, `strokeIDs`, `strokePathIDs` | Stable file-local Band and Path edges; regenerate aligned host arrays. At most 64 Bands per layer. |
| Side and range | `strokeSides`, `bandArrangement`, `patternWidths`, `strokeStarts`, `strokeEnds` | Outside/Inside versus Analyzer-specific sides. Consecutive derives current range from ordered widths per Path+side; Independent uses explicit Start/End. Preserve inactive range data too; no automatic conversion. |
| Membership | `strokeModes`, `strokeColorRows`, `strokeColorKeys`, `strokeSourceRows`, `strokeSourceIDs` | Assignment-group or direct-row mode. Store membership by file-local Band/row/group IDs; preserve dormant memberships. Current raw membership indices are not portable. |
| Density | `strokeStrengths`, `strokeCurveEnabled`, `strokeCurveSamples`, `strokeCurveGraphs` | Strength is 0..1 (UI percent); curve is a distinct unit-domain profile. Preserve inactive curve/graph. |
| Scale | `strokeMin`, `strokeMax`, `strokeScaleModes`, `strokeScaleSamples`, `strokeScaleGraphs` | Random Band multiplier range plus Off/Follow Density/Custom profile. Custom profile samples are 0..100 multipliers; Follow Density uses effective curve shape, not the density-strength percentage. Preserve custom data while inactive. |
| Identification | `strokeDisplayColors` | Band identification only; not materials or assignment groups. |
| Analyzer row transforms | `edgeRotX/Y/Z`, `edgeOffsetsWU`, `edgeAlongWU`, `edgeAcrossWU` | Per-row degrees/distances. Preserve arrays tied to stable Band IDs, even while a different layout is active. |
| Analyzer corners/orientation | `edgeKeepCorners`, `edgeCornerAngle`, `edgeCornerCount`, `edgeFaceOut`, `edgeCornerRadius`, `borderFaceOut`, `streetFaceOut`, `borderCornerRadius`, `streetCornerRadius` | Separate edge/border/street behavior. Do not collapse these into one “align to path” flag. |
| Street/centerline | `streetStraight`, `streetTrimStart`, `streetTrimEnd`, `centerStreetOffset` | Preserve straight-only flag and physical offsets/trims; these are distinct from source movement. |

Unknown sides/layout combinations fail validation. Plain spline Bands currently support the Outside/Inside case through the native spline-field path; Analyzer Radius/Single/Street/Edge meanings must remain in their own mode. Do not export the display prefix “Both” as proof of a third generic spline-side implementation.

## Paint, spacing and authored Edit

| Record | Current fields / native members | Required behavior |
| --- | --- | --- |
| Paint owner | `paintEnabled`, `paintDensity`, ordered `paintAreas`; each area's `paintSetName`, `paintSetEnabled`, `areaTarget`, `paintDocument` | Preserve layer and area density, activation, order and receiver roles. No area creates its own population. |
| Native Paint | `Document.surface`, `Document.contours`, `Document.falloff` | Lossless native payload including islands/holes and binding fingerprint. Single-valued receiver-local XY only. Empty contours are valid authored clear state. |
| Native falloff | `inside`, `outside`, `density`, `scale`, `scaleMin`, `scaleMax`, `densityCurve`, `scaleCurve` | Physical fades in saved native units; edge/inner scale and independent flags; 2..257 unit-domain samples. Current native scale minimum cannot exceed maximum; don't invent reversed-edge support. |
| Paint graph/preferences | `fallDensityGraph`, `fallScaleGraph`, `paintView`, `paintColor`; native `radius`, `erase` | Preserve editable graphs and saved options outside the vector document. Never restore an in-progress gesture or start a brush automatically. |
| Within-layer spacing | `procLayerSelfEnabled/Multiplier/Gap/Planar` | Four independent fields, with metres for gap. Capture defaults even when disabled. |
| Per-owner override / sibling defaults | `procSelfOverride`, `procSelfEnabled/Multiplier/Gap/Planar`, `procSiblingEnabled/Multiplier/Gap/Planar` | Preserve declared scopes; reject unsupported owner arrangements instead of inventing a Paint-set population. |
| Explicit pairs | `procRuleScope`, `procRuleA/B`, `procRuleEnabled`, `procRuleMultiplier`, `procRuleGapWU`, `procRulePlanar` | Capture enabled and disabled rules; remap internal endpoints and retain external endpoints as requirements. Winner order follows owners, not record-name sorting. |
| Radius edits | `procRadiusIDs`, `procRadiusModes`, `procRadiusValues`, `procRadiusDistances`, `procRadiusBinding` | Guarded authored candidate locators plus absolute distance or multiplier. Preserve original binding; do not copy runtime IDs into unrelated terrain. |
| Native Edit stack | `CSEdit.layers`, keyed `EditLayer.signature`, `EditRow.inputId/outputId/source/delta/deleted`; modifier order/enabled state | Guarded native adapter retains authored deltas/deletions/copies and compatible binding. `source` indexes current input placement correspondence, not a model role; it must be resolved correctly, never blindly reused. |
| Edit derived state | `EditLayer.input/sources/publishedIDs/published/active/viewportVisible`, transient invalid/result flags, `EditRow.selected` | Rebuild/revalidate; selection and generated input arrays are not recipe content. Retain original invalid authored records inactive if a safe storage adapter supports them. |

Native current `.max` Edit storage includes selection and raw indices as part of scene persistence. That format does not establish portable import safety. Full setup export requires a dedicated bounded adapter or an explicit unsupported-data error; the scene-copy helper is insufficient. This does not authorize a new arbitrary remesh correspondence algorithm.

## Preferences, derived outputs and deliberate exclusions

Capture presentation preferences: `viewportMode`, `proxyShape`, `viewportInstances`, `viewportFaces`, `viewportNavigationPoints`, `viewportNavigationInstances`, `viewportNavigationFaces`, `previewBudget`, `showPoints`, `pointsPerPlant`, `showCenters`, `pointColorMode`, `solidPointColor`, `identificationMode`, `radiusDisplayLimit/All/Metric`, `sourceShowRadius`, `paintView`, `paintColor`, `fieldFalloff`, `fieldBoundaries`, `fieldCombined`, `fieldSamples`, and remapped `fieldBandID`. Captured overlay choices do not imply immediate preview calculation. `iconSize`, `autoRender` and `groupCenters` belong to controller/output preferences; restore according to action, not as a hidden global override.

`bakedNodes` is a link to generated output, not authored scatter rules. Report its presence; never duplicate baked geometry as a second population when importing a recipe. If the user wants those scene objects too, use explicit asset/scene packaging. Cached meshes, candidate/accepted rows, native projection fields/BVHs, sampled preview points, source evaluation samples, GPU resources, epochs, timers, errors and UI callbacks are excluded. Saved scene identities needed for authored relationships are remapped, not confused with those caches.

## Enum boundary table

| Source field | Current host meaning | Proposed token / validation |
| --- | --- | --- |
| `updateMode` | 1 Manual, 2 Live | `manual`, `live`; no Add-time override. |
| `populationMode` | 1 Count, 2 Plants/m² | `count`, `density`; save both numeric controls. |
| `procPopulation` | 1 Candidate budget, 2 Accepted target | `candidate-budget`, `accepted-target`; preserve retry bounds. |
| `diversityMode` | 1 Random mix, 2 Clusters, 3 Spline Bands, 4 Surface Analyzer | Four distinct tokens. |
| `distributionMode` | 1 Uniform or 3 Map; bridge passes value minus one and native accepts only 0 or 2 | `uniform`, `texture-map`; stored 2 and unknown values are unsupported and block complete export. Never silently convert 2 to 1. |
| `meshMaskComponent` | UI 1 R/X, 2 G/Y, 3 B/Z; native 0/1/2 | `X`, `Y`, `Z`; subtract/add once at host boundary. |
| `sourceForwardAxes` | 1 +Y, 2 -Y, 3 +X, 4 -X | Signed axis strings. Source up-axis expectations are separate. |
| `sourcePoint/sourceEmpty` | false/false Model; false/true Empty; true/true Point | Explicit kind plus dormant raw settings; inconsistent combinations rejected. |
| `sourceAutoRadius` | Requested bool; effective false for Point/Empty | `manual`/`auto` plus retained dormant manual value. |
| `containerMode` | 1 Manual, 2 inherited provider, 3 root/shared, 4 local containers | Preserve semantic policy, not dropdown index (some UI modes hide 2). Unsupported inheritance is reported. |
| `areaModes` | 1 Include, 2 Exclude | `include`, `exclude`. |
| `areaLineCaps` | 1 Flat, 2 Round | `flat`, `round`. |
| `pathJoins` | 1 Rounded, 2 Sharp | `rounded`, `sharp`; native enum conversion is explicit. |
| `bandArrangement` | 1 Consecutive, 2 Independent | `consecutive`, `independent`; retain widths and saved ranges. |
| `strokeSides` | 1 Outside, 2 Inside; Analyzer prefix codes 3 Both/centerline, 4 Radius, 5 Single points, 6 Street, 7 Edge | Tokens qualified by layout; no generic spline interpretation of Analyzer values. |
| `strokeModes` | 1 Assignment groups, 2 Models/Points | `groups`, `source-rows`. |
| `strokeScaleModes` | 1 Off, 2 Follow Density, 3 Custom | `off`, `follow-density`, `custom`; preserve unused custom graph. |
| `procRuleScope` | Host 1 Sets, 2 Layers; bridge rejects other values | `sets`, `layers`; additionally validate supported owner types. |
| `proc*Planar`, `cleanupPlanar` | true XY, false 3D | `XY`, `3D`; radius display metric does not alter these rules. |
| `procRadiusModes` | 1 absolute distance, 2 multiplier | `absolute`, `multiplier`; reject other values. |
| `paintView` | 2 vector borders, 1 samples, 0 off | Capture preference; overlay activation remains explicit. |
| `pointColorMode` / `identificationMode` | 1 solid/2 identification; identification 1 model/2 layer/3 Bands | Capture separately; no change to material or assignment group. |
| `radiusDisplayMetric` | 1 XY, 2 3D | Presentation only. |
| `viewportMode`, `groupCenters` | Stored mode 1 Point Cloud, 2 Proxy, 3 Mesh; centres uses mode 1 plus `groupCenters=true` | Preserve both fields; the UI's fourth choice is not a fourth stored viewport mode. |
| `proxyShape` | 1 Box, 2 Sphere, 3 Pyramid | `box`, `sphere`, `pyramid`. |

Remaining presentation integers are counts/budgets, not additional enums. Preserve their current validated limits, including the explicit meaning of zero, without changing destination budgets on Add. Unsupported preference values block complete capture rather than being replaced silently. Numerical min/max validation is shared with the authoritative engine where possible; a UI spinner is not the entire validity contract.

## Source and validation anchors

- [Controller template](../../AminScatter/tools/ui/templates/unified-core.ms): `AminScatterLayerFields`, `AminScatterCopyLayer`, `syncBandRecords`, `bandInterval`, `bandScaleCurve`, `getFallConfig`, `procCopyRelations`, `procValidate`, source helper defaults and UI enums.
- [Category preset template](../../AminScatter/tools/ui/templates/presets.ms) and [native codec](../../AminScatter/src/presets.cpp): typed categories, graph representation, bounds, captured owner and transaction/storage precedent.
- [Container template](../../AminScatter/tools/ui/templates/container-node.ms): helper persistence and collection ownership.
- [Brush types](../../AminScatter/include/brush.h), [codec](../../AminScatter/src/brush.cpp), [host wrapper](../../AminScatter/src/brush_host.cpp): native document/falloff, quantization, projection, saved target and tool preferences.
- [Edit object](../../AminScatter/src/cyrus_edit.cpp), [storage](../../AminScatter/src/cyrus_edit_storage.inc), [stack](../../AminScatter/src/cyrus_edit_stack.inc): authored/derived distinction and original binding semantics.
- [Mesh validator](../../AminScatter/src/mesh_density.cpp), [surface validator](../../AminScatter/src/surface_filter.cpp), [procedural bridge](../../AminScatter/src/procedural_bridge.inc), [spline types](../../AminScatter/include/spline_bands.h): numeric/evaluation domains.

Before production importer work, enforce this map against every declaration and native authored member. Tests must mutate each supported field and enum, capture/import/capture, and compare semantic values plus native bytes where conversion is absent. An inventory with zero missing rows is coverage accounting, not proof of a correct adapter. [Required R13–R20 fixtures](VALIDATION.md#complete-save-and-paint-regressions).
