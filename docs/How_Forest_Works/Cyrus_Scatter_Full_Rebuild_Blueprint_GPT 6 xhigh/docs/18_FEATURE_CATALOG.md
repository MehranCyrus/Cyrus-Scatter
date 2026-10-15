# 18 — ForestPack-style feature inventory mapped to Cyrus engineering components

## Usage and evidence standard

This catalog attempts to cover **every major feature family** in the ForestPack plugin reference and the supplied research. It is **not a certified full extraction of every spinner, default, keyboard shortcut, historical option and version-specific combination**. A target ForestPack 9.4.3 UI audit is required before marking control-level parity complete.

Legend: `D` = behavior documented in the linked official reference; `V` = a detail/combination still needs reference testing; `C` = proposed Cyrus extension or product decision. **Unknown numeric defaults are intentionally omitted** rather than invented. `Touches` names the main subsystem(s), not necessarily every indirect dependency. The implementation must also capture parameter data type, unit, range, default, mode restriction, persistence, Undo, renderer capabilities and fixture IDs for each row.

## A. Create and General

Primary source: [Forest plugin reference](https://docs.itoosoft.com/forestpack/forest-plugin), [General rollout](https://docs.itoosoft.com/forestpack/forest-plugin/general).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| GEN-001 | Create Forest/scatter object | Adds authored procedural scatter to scene | Host, persistence | D |
| GEN-002 | Scatter icon/gizmo | Anchor and display of host object | Host, viewport | D |
| GEN-003 | Enable/Disable scatter | Control scene evaluation/output | Runtime, output | D |
| GEN-004 | Random Seed | Reproducible random variation | RNG, downstream | D |
| GEN-005 | CPU Threads/Auto | Thread count during construction | Scheduler | D |
| GEN-006 | Parameter Presets | Save/load parameter-only settings | Presets | D |
| GEN-007 | Set Default Preset | Initialize new scatter settings | Presets/UI | D |
| GEN-008 | Import/Export preset | External parameter preset exchange | Persistence | D |
| GEN-009 | Diagnostics/stats | Errors, candidate and rejected counts, build state | Instrumentation | D |
| GEN-010 | UI rollout visibility | Show/hide sections | UI | D |
| GEN-011 | Disable pop-ups | Warning presentation policy | UI | D |
| GEN-012 | Manual refresh | Recompute on request | Dirty graph | D |
| GEN-013 | Unit handling | Respect 3ds Max scene-unit system | Host/geometry | C |
| GEN-014 | Deterministic algorithm version | Preserve reproducibility across engine updates | RNG/cache/schema | C |

## B. Geometry and Source Library

Primary source: [Geometry rollout](https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| SRC-001 | Add custom source | Use scene geometry as scatter source | Source registry | D |
| SRC-002 | Multi-add sources | Add many selected scene objects | UI, registry | D |
| SRC-003 | Delete source | Remove Geometry List entry | Sources, downstream | D |
| SRC-004 | Copy/paste source | Duplicate source settings and reference | Registry, Undo | D |
| SRC-005 | Reorder source | Change list order/sequence | Selection/path | D |
| SRC-006 | Rename source | Display and reference-name matching | Source/ref | D |
| SRC-007 | Template/Billboard | Use preset billboard/template geometry | Sources, renderer | D |
| SRC-008 | Custom Object | Source linked to arbitrary compatible scene object | Host/source | D |
| SRC-009 | Missing/Empty/Disabled | Deliberately create gaps without removing selection slot | Selection | D |
| SRC-010 | Source Probability | Relative weighted selection | Selection | D |
| SRC-011 | Normalize Probabilities | Display/adjust normalized weights | UI/selection | D |
| SRC-012 | Randomize Weights | Generate varied source weights | Selection/UI | D |
| SRC-013 | Color ID | Palette for matching map colors and viewport ID | Selection/display | D |
| SRC-014 | Source Scale | Per-source size multiplier | Bounds/transform | D |
| SRC-015 | Billboard Width/Height | Physical billboard dimensions | Source/transform | D |
| SRC-016 | Global Size/Scale | Apply global sizing to Geometry List | Bounds/transform | D |
| SRC-017 | Source Z Offset | Elevate/lower source at placement | Transform | D |
| SRC-018 | Center Displacement | Change billboard rotation pivot offset | Source/transform | D |
| SRC-019 | Collision Radius | Source-specific spacing footprint | Collision | D |
| SRC-020 | Material slot | Assign material override | Renderer/material | D |
| SRC-021 | Auto material reassignment | Reconstruct combined material assignment | Renderer/material | D |
| SRC-022 | Groups | Use grouped components as scatter source | Group policy | D |
| SRC-023 | Keep Group Hierarchy | Group transforms/culling behavior | Transform/renderer | D |
| SRC-024 | Include Children | Include linked hierarchy children | Source registry | D |
| SRC-025 | Non-Geometric Object | Support compatible scene sources such as lights | Host/renderer | D |
| SRC-026 | Library import | Load library source/model/preset | Assets | D |
| SRC-027 | Use Object Dimensions (historical) | Older size behavior; some controls removed in later versions | Compatibility | D/V |
| SRC-028 | Explicit source replacement policy | Preserve ID vs generate new outcome when changed | Identity | C |
| SRC-029 | Group atomization policy | One compound placement vs child-level instances | Groups | C |

## C. Image Distribution and Diversity

Primary source: [Image Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode); [ForestPack 9.3 density map](https://docs.itoosoft.com/forestpack/whats-new/forest-pack-9-3).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| IMG-001 | Image generator mode | Pixel-based potential placement grid | Candidate generation | D |
| IMG-002 | Preset distribution bitmap | Choose provided layout pattern | Input assets | D |
| IMG-003 | Custom bitmap | Supply authored pattern | Input/field | D |
| IMG-004 | Procedural map | Use scene map as distribution field | Host field | D |
| IMG-005 | X/Y Units | World-space dimensions of image repetition | Candidate positions | D |
| IMG-006 | X/Y Pixels | Procedural sample resolution | Candidate reservoir | D |
| IMG-007 | Keep aspect ratio | Couple X/Y proportions | UI/generator | D |
| IMG-008 | Rotation | Rotate pattern orientation | Mapping | D |
| IMG-009 | Offset | Shift distribution pattern | Mapping | D |
| IMG-010 | Fit to Scene | Align/scaling from scene placement | Mapping | D/V |
| IMG-011 | Map Channel/UV | Use receiver UV map coordinates | Surfaces/maps | D |
| IMG-012 | Threshold | Binary map placement acceptance | Density field | D/V |
| IMG-013 | Grayscale Density Map | Treat shades as density, not strict mask | Density | D |
| IMG-014 | Max Density | Cap potential candidate positions (not accepted count) | Safety/runtime | D |
| IMG-015 | Gizmo corner handles | Visual map transform editing | UI/host | D |
| IMG-016 | Diversity Random | Use source probabilities | Source selection | D |
| IMG-017 | Diversity Color ID | Match source color to map color | Source selection | D |
| IMG-018 | Diversity Clusters | Spatially correlated source grouping | Clustering | D |
| IMG-019 | Cluster Size | Spatial patch size in scene units | Cluster field | D |
| IMG-020 | Cluster Roughness | Irregularity of patch boundaries | Cluster field | D |
| IMG-021 | Cluster Blurry Edge | Mix source types at patch borders | Cluster field | D |
| IMG-022 | Cluster Noise | Introduce out-of-patch/random variation | Cluster field | D |
| IMG-023 | Color ID Noise | Random variation from color matching | Source selection | D/V |
| IMG-024 | Collisions Enable | Reject overlapping items | Collision | D |
| IMG-025 | Global Collision Radius | Percentage multiplied with source radius | Collision | D |
| IMG-026 | Collision Height | Change virtual sphere center | Collision | D |
| IMG-027 | Collision Viewport Preview | Show collision filtering interactively | Preview | D |
| IMG-028 | Stable candidate reservoir | Make density changes monotonic pre-collision | RNG/candidates | C |
| IMG-029 | Map-space color management | Declare value-map gamma/filtering | Fields | C |

## D. Path Distribution

Primary source: [Path Mode](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| PATH-001 | Select Path mode | Sample one or more splines | Candidate generator | D |
| PATH-002 | Add/Remove Paths | Manage spline input references | Scene bindings | D |
| PATH-003 | Multi-add paths | Batch path referencing | Host/UI | D |
| PATH-004 | Spacing | Even physical-distance placement | Arc-length | D |
| PATH-005 | In Vertex Positions | Knot-based placement | Path sampler | D |
| PATH-006 | Geom ID Sequence | Repeat source order | Source selection | D |
| PATH-007 | Geom ID Random | Random source along path | Source selection | D |
| PATH-008 | Spline Offset | Move perpendicular to curve | Path frame | D |
| PATH-009 | Random Position | Break regular positional pattern | RNG/path | D |
| PATH-010 | Follow Path X | Align chosen axis to path | Transform | D |
| PATH-011 | Follow Path Z | Orient around vertical axis along tangent | Transform | D |
| PATH-012 | Closed seam policy | Avoid duplicated/omitted endpoint | Generator | V |
| PATH-013 | Multiple sub-spline sequence reset | Continuity across path components | Source ID/identity | V |

## E. Reference, Particle Flow and RailClone Inputs

References: [Reference](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode), [PFlow](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/particle-flow-mode), [RailClone](https://docs.itoosoft.com/forestpack/forest-plugin/distribution/railclone-integration).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| REF-001 | Add/Remove Reference Objects | Link layout markers | Scene binding | D |
| REF-002 | Select by name/multi-add | Bulk reference collection | UI/binding | D |
| REF-003 | Pivot distribution | One placement at object pivot | Generator | D |
| REF-004 | Face distribution | Placement from mesh triangles | Generator | D |
| REF-005 | Items Per Face | Multiple placements per triangle | Generator | D |
| REF-006 | Randomize Position | Random within-face positioning | Generator/RNG | D |
| REF-007 | Material ID filter | Select eligible reference faces | Field/generator | D |
| REF-008 | Align | Inherit reference orientation/face normal | Transform | D |
| REF-009 | Scale | Inherit reference scaling | Transform | D |
| REF-010 | Match Geometry by Name | Source selection from reference names | Registry/regex | D |
| REF-011 | Regular Expressions | Pattern-based name matching | Source matching | D |
| REF-012 | Unmatched fallback to first | First Geometry entry or Empty slot | Selection | D |
| REF-013 | Collisions | Run spacing on reference-based items | Collision | D |
| PFL-001 | PFlow Source List | Use 3ds Max particle sources | Host/provider | D |
| PFL-002 | All Particle Events | Include all events | Provider filter | D |
| PFL-003 | Selected Event List | Use only selected events | Provider filter | D |
| PFL-004 | Align | Inherit particle rotation | Transform | D |
| PFL-005 | Scale | Inherit particle scale | Transform | D |
| PFL-006 | Animated Source | Dynamic particle input | Time/provider | D |
| PFL-007 | Particle Effects attributes | Age, event, speed, rotation, scale | Effects | D |
| EXT-001 | RailClone segments | Use segment transforms as external candidate inputs | External adapter | D |
| EXT-002 | RailClone source matching/tags | Match segments to source models | Source mapping | D |
| EXT-003 | External stable metadata schema | IDs/attributes/transform/provenance | Cyrus adapter | C |

## F. Areas and Linked Regions

Primary source: [Areas rollout](https://docs.itoosoft.com/forestpack/forest-plugin/areas).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| AREA-001 | Area Stack | Evaluate Include/Exclude bottom to top | Area graph | D |
| AREA-002 | Add Spline | Define spline region | Region | D |
| AREA-003 | Add Object Exclude | Exclude from projected geometry | Raster mask | D |
| AREA-004 | Add Forest Exclude | Exclude using other scatter output | Cross-scatter | D |
| AREA-005 | Add Paint | Brush-authored region | Paint/region | D |
| AREA-006 | Surface Include | Use receiver as fill region | Surfaces/areas | D |
| AREA-007 | Add Linked Area | Reuse source Area, keep local properties | Dependency | D |
| AREA-008 | Reorder Area | Change precedence | Area graph | D |
| AREA-009 | Enable/Disable Area | Toggle contribution | Area graph | D |
| AREA-010 | Rename Area | User name and references | UI/document | D |
| AREA-011 | Include/Exclude | Add or remove eligible region | Area graph | D |
| AREA-012 | Spline Thickness | Width of open spline distribution corridor | Spline region | D |
| AREA-013 | Force Open Splines | Treat closed contour as band | Spline region | D |
| AREA-014 | Separate Sub-Splines | Treat multiple sub-curves as separate regions | Region provenance | D |
| AREA-015 | Object Top Limit | Ignore upper geometry in projection exclusion | Raster mask | D |
| AREA-016 | Object Resolution | Exclusion mask pixel resolution | Raster mask | D |
| AREA-017 | Object Scale | Expand/contract exclusion footprint | Region | D |
| AREA-018 | Forest Sphere Shape | Virtual sphere footprint around source items | Cross-scatter | D |
| AREA-019 | Forest Mesh Shape | Mesh-accurate exclusion footprint | Cross-scatter | D |
| AREA-020 | Forest Resolution/Scale | Accuracy and size of generated mask | Cross-scatter | D |
| AREA-021 | Paint/Erase | Edit inclusion/exclusion coverage | Paint | D |
| AREA-022 | Paint Brush Min/Max | Configure brush size | Paint | D |
| AREA-023 | Pressure Sensitivity | Change brush radius with tablet pressure | Paint | D |
| AREA-024 | Preview Falloff | Overlay effective falloff while painting | Display/paint | D |
| AREA-025 | Paint → Spline | Convert coverage to editable contour | Paint/spline | D |
| AREA-026 | Spline → Paint | Convert contour to paint area | Paint/spline | D |
| AREA-027 | Local Source Selection | Restrict Area to source subset | Selection/region | D |
| AREA-028 | Local Density/Distribution | Area-local distribution parameters | Generator/field | D |
| AREA-029 | Per-Area Random Scale | Area-local scale range | Transform | D |
| AREA-030 | Boundary Point | Check pivot only | Boundary | D |
| AREA-031 | Boundary Size | Check approximate item footprint | Boundary | D |
| AREA-032 | Boundary Edge | Trim geometry elements at render | Render/material | D |
| AREA-033 | Density Falloff | Lower/invert density near boundaries | Field/density | D |
| AREA-034 | Scale Falloff | Change scale near boundaries | Field/transform | D |
| AREA-035 | Falloff Include Range | Distance inside include boundary | Field | D |
| AREA-036 | Falloff Exclude Range | Distance around exclusion boundary | Field | D |
| AREA-037 | Falloff Curve | Artist-defined response | Curve field | D |
| AREA-038 | Falloff Affect | Control effect strength | Field | D |
| AREA-039 | Invert Curve | Reverse falloff response | Field | D |
| AREA-040 | Affect Height Only | Scale Z without XY footprint change | Transform | D |
| AREA-041 | Randomize Stacked | Different random variation for vertically stacked items | RNG | D |
| AREA-042 | UV Project Axis | Control Area projection direction on UV surfaces | Surface/region | D |
| AREA-043 | Area Distribution Map on UV | Documented restriction in UV mode | Compatibility | D |
| AREA-044 | Area Linked Local Overrides | Some inherited parameters vs local falloffs | Dependency/field | D/V |
| AREA-045 | Editable Region ID provenance | Track which Include supplied candidate | Data model | C |
| AREA-046 | Accurate 3D volume exclusion | Optional non-projected space exclusion | Spatial field | C |

## G. Surfaces and Projection

Source: [Surface rollout](https://docs.itoosoft.com/forestpack/forest-plugin/surfaces).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| SURF-001 | Surface List Add/Delete | Maintain receivers | Scene binding | D |
| SURF-002 | Multi-add Surface | Batch select receivers | Host/UI | D |
| SURF-003 | Get From Forest | Reuse another scatter's receiver set | Dependency | D |
| SURF-004 | XY Mode | Project local XY along local Z | Surface sampler | D |
| SURF-005 | UV Mode | Placement in surface UV mapping coordinates | UV sampler | D |
| SURF-006 | UV Transform | Mapping alignment/scale | UV sampler | D |
| SURF-007 | Direction Normal/Up/Down | Orient relative to surface | Transform | D |
| SURF-008 | Scale To Fit Sloped | Adjust width on sloped XY receiver | Transform | D |
| SURF-009 | Altitude Top/Bottom | Limit by surface height | Filter | D |
| SURF-010 | Altitude Falloff | Density/scale vary with elevation | Field | D |
| SURF-011 | Slope Angle Range | Restrict steepness | Filter | D |
| SURF-012 | Refresh Surface | Rebuild cached terrain characteristic table | Surface cache | D |
| SURF-013 | Auto Refresh | Refresh when receiver changes | Dependency | D |
| SURF-014 | Link to Surface (Custom Edit) | Follow receiver in manual mode | Manual attachment | D |
| SURF-015 | Place Trees (Custom Edit) | Reproject manual items | Manual attachment | D |
| SURF-016 | Multi-hit policy | Choose among stacked receiver intersections | Cyrus feature | C/V |
| SURF-017 | World-area density | Correct projected area distortion | Cyrus feature | C |

## H. Transform

Source: [Transform rollout](https://docs.itoosoft.com/forestpack/forest-plugin/transform).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| TR-001 | Translation X/Y/Z | Random source-dimension-relative offsets | Transform | D |
| TR-002 | Rotation X/Y/Z | Random per-axis rotations | Transform | D |
| TR-003 | Scale X/Y/Z | Random per-axis dimensions | Transform | D |
| TR-004 | Lock Aspect Ratio | Coupled scaling axes | Transform | D |
| TR-005 | Probability Curve Rotation | Bias frequency of angles | CDF sampling | D |
| TR-006 | Probability Curve Scale | Bias size sampling | CDF sampling | D |
| TR-007 | Transform Map | Map to specific transform values | Field sampler | D |
| TR-008 | RGB Scale Map | Per-channel X/Y/Z scale values | Field sampler | D |
| TR-009 | Probability Map | Modulate amount of randomization | Field sampler | D |
| TR-010 | Mirroring | Flip source instance | Transform/renderer | D |
| TR-011 | Mirror Custom Objects | Allow mirroring imported source assets | Transform | D |
| TR-012 | Post-placement translation | Potentially outside original area | Evaluation order | D |
| TR-013 | Revalidate after transform | Optional Cyrus boundary policy | Boundary | C |

## I. Items Editor and Manual Controls

Source: [Items Editor](https://docs.itoosoft.com/forestpack/forest-plugin/item-editor).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| EDIT-001 | Generate vs Custom Edit | Separate automatic and manual modes | Editor | D |
| EDIT-002 | Item Sub-Object Mode | Pick/edit generated or custom items | Picking | D |
| EDIT-003 | Add Single Item | Manually add placement | Manual layer | D |
| EDIT-004 | Add Selection/Random/Sequence | Choose model when adding | Selection | D |
| EDIT-005 | Move/Rotate/Scale Item | Manual transform edits | Manual layer | D |
| EDIT-006 | Choose Source on Selected Item | Source replacement | Manual layer | D |
| EDIT-007 | Sub Item | Select group component in compound source | Groups | D |
| EDIT-008 | Select By Type | Select all instances of source | Picking | D |
| EDIT-009 | Randomize Type | Re-select source of selected items | Manual layer | D |
| EDIT-010 | Reset Size | Restore selected item scale | Manual layer | D |
| EDIT-011 | Re-Seed | New random transforms for selected items | Random/manual | D |
| EDIT-012 | Store Transform | Bake random transform into explicit edit values | Manual layer | D |
| EDIT-013 | Attach Forest Items | Merge manual populations | Editing | D |
| EDIT-014 | Detach Items | Create new scatter from selection | Editing | D |
| EDIT-015 | Consolidate Geometry List | Merge by matching names/types on attach | Source registry | D |
| EDIT-016 | Persistent Overlay while generating | Manual transforms survive procedural adjustments | Cyrus improvement | C |
| EDIT-017 | Orphan Recovery | Rebind/discard/pin edits whose IDs vanish | Cyrus improvement | C |

## J. Camera and LOD

Sources: [Camera](https://docs.itoosoft.com/forestpack/forest-plugin/camera), [ForestLOD](https://docs.itoosoft.com/forestpack/forest-plugin/forest-lod).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| CAM-001 | Limit To Visibility | Restrict to current camera FOV | Camera/output | D |
| CAM-002 | Expand | Enlarge camera region margins | Camera/output | D |
| CAM-003 | Far Clipping | Skip beyond distance | Camera/output | D |
| CAM-004 | Back Offset | Include some behind-camera items | Camera/output | D |
| CAM-005 | Copy Parameters | Apply camera config to other scatters | UI/doc | D |
| CAM-006 | Look At | Orient items toward camera/target | Transform/output | D |
| CAM-007 | Enable LOD | Use ForestLOD sources | LOD | D |
| CAM-008 | Override Max Distance | Replace per-LOD distance limit | LOD | D |
| CAM-009 | Use Environment Range | Use camera environment distance controls | Camera | D |
| CAM-010 | Use Look At Target | Use target as distance origin | Camera | D |
| CAM-011 | Camera Density Falloff | Thin distant population | Density | D |
| CAM-012 | Camera Scale Falloff | Size variation with distance | Transform | D |
| CAM-013 | Viewport Camera Preview | Enable camera behavior in viewport; performance trade-off | Runtime | D |
| LOD-001 | Distance LOD | Choose supplied model by view distance | LOD | D |
| LOD-002 | Screen-size LOD | Choose supplied model by on-screen size | LOD | D |
| LOD-003 | LOD Material Override | Model-dependent material | Material | D |
| LOD-004 | LOD Transition Variation | Reduce abrupt switching | LOD | D |
| LOD-005 | Temporal Hysteresis | Avoid frame-to-frame toggling | Cyrus improvement | C |

## K. Display and Rendering

Source: [Display rollout](https://docs.itoosoft.com/forestpack/forest-plugin/display).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| DISP-001 | Mesh View | Draw original geometry | Viewport | D |
| DISP-002 | Adaptive View | Switch by geometry budget | Viewport | D |
| DISP-003 | Proxy View | Draw box/plane/plant/etc placeholder | Viewport | D |
| DISP-004 | Point Cloud | Fast point representation | GPU preview | D |
| DISP-005 | Point Display Size | Control point size | GPU preview | D |
| DISP-006 | Color ID Point Preview | Color points by source ID | Viewport | D |
| DISP-007 | Material/Random Tint Preview | Color preview from source/tint | Viewport/material | D |
| DISP-008 | Point Shading | Fake 3D point shading control | Viewport | D |
| DISP-009 | Viewport Max Items | Bound displayed populations | Viewport | D |
| DISP-010 | Manual Update | Defer recompute until requested | Runtime | D |
| DISP-011 | Disable Object | Hide in view/render | Output | D |
| DISP-012 | Freeze All | Temporarily stop heavy updates for many scatters | Runtime | D |
| DISP-013 | Render Representation Mesh/Proxy | Select renderer geometry style | Renderer | D |
| DISP-014 | Render Simplification Level | Reduce rendered population | Output | D |
| DISP-015 | Render Auto/Meshes | Native renderer mode vs combined mesh | Renderer | D |
| DISP-016 | Render Max Items/Faces | Limit generated geometry | Resource budgets | D |
| DISP-017 | Hide Custom Sources at Render | Do not double-render source nodes | Renderer/host | D |
| DISP-018 | Stable Preview Subset | Preview quality without reshuffling | Cyrus improvement | C |
| DISP-019 | GPU Buffer Lifecycle | Retain/reuse GPU buffers until result changes | Viewport runtime | D/C |

## L. Material, Forest Color and Forest Edge

Sources: [Material rollout](https://docs.itoosoft.com/forestpack/forest-plugin/material), [Forest Color](https://docs.itoosoft.com/forestpack/forest-color), [Forest Edge](https://docs.itoosoft.com/forestpack/forest-edge-map).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| MAT-001 | Tint Gradient | Select random tint from gradient | Material attrs | D |
| MAT-002 | Tint Strength | Blend tint with source appearance | Material attrs | D |
| MAT-003 | Tint Map | Select tint from texture | Material field | D |
| MAT-004 | Map Random Values | Random texture pixel color per item | Material field | D |
| MAT-005 | Map As Texture | Spatial texture-based color | Material field | D |
| MAT-006 | Map Channel | Use surface UV for tint mapping | Surface/material | D |
| MAT-007 | Hue Range Correction | Selective H/S/V correction | Material/shader | D |
| MAT-008 | Saturation/Brightness Correction | Color correction controls | Material/shader | D |
| MAT-009 | Forest Color Whole Item | Per-instance color variation | Shader attributes | D |
| MAT-010 | Forest Color Element | Different color within source components | Element attributes | D |
| MAT-011 | Forest Color Alternatives/Blend | Multiple maps/tints and blending | Shader | D |
| MAT-012 | Material Optimizer | Insert required compatible material nodes | Host material graph | D |
| MAT-013 | Forest Edge Cutout | Remove elements outside boundary at render | Renderer/material | D |
| MAT-014 | Safe Idempotent Wrapping | Reapply optimizer without duplicate wrappers | Cyrus contract | C |

## M. Animation and Shadows

Sources: [Animation](https://docs.itoosoft.com/forestpack/forest-plugin/animation), [Shadows](https://docs.itoosoft.com/forestpack/forest-plugin/shadows).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| ANIM-001 | Disabled | No source animation sampling | Source output | D |
| ANIM-002 | Follow Geometry | Synchronized source animation | Source time | D |
| ANIM-003 | Random Samples | Discrete random source time offsets | Sample cache | D |
| ANIM-004 | Sample Count | Number of animation sample choices | Sample cache | D |
| ANIM-005 | Time Offset | Frame offset between sample points | Sample cache | D |
| ANIM-006 | Random From Map | Map chooses time sample | Material/UV/time | D |
| ANIM-007 | Frames From Map | Map controls absolute frame | Time field | D |
| ANIM-008 | Start/End Frames | Allowed sampled range | Animation | D |
| ANIM-009 | Animate Only At Render | Restrict animated evaluation to render | Preview/output | D |
| ANIM-010 | Bounded Animation Cache | Reuse samples with memory limit | Runtime | D |
| SHAD-001 | Billboard Shadow Helpers | Legacy billboard-oriented shadow support | Legacy renderer | D |
| SHAD-002 | XShadow/Raytrace settings | Specialized historical shadow workflows | Legacy renderer | D |

## N. Effects and programmable rules

Source: [Effects overview](https://docs.itoosoft.com/forestpack/forest-plugin/effects), [Attributes](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/attributes), [Parameters](https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/parameters).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| FX-001 | Effects List/Library | Assign built-in or imported procedural rules | Effect stack | D |
| FX-002 | Expression Editor | Author math expressions | Parser/VM | D |
| FX-003 | Editable Attributes | Modify position/rotation/scale/visibility/source/tint etc. | Attribute pipeline | D |
| FX-004 | Read-only Surface Attributes | Access normal/slope/height | Surface field | D |
| FX-005 | Read-only Area Distance | Access nearest include/exclude boundaries | Region field | D |
| FX-006 | Distribution/Path Attributes | Access coordinates and path position | Generator | D |
| FX-007 | Particle Attributes | Read age/rotation/scale/speed/event | Particle provider | D |
| FX-008 | Numeric Parameter | Artist-facing number/percentage/unit | Effect UI | D |
| FX-009 | Object Parameter | Scene node reference and position | Scene snapshot | D |
| FX-010 | Controller Parameter | Host animation/controller value | Scene snapshot/time | D |
| FX-011 | Texture Parameter | Sample user map | Field snapshot | D |
| FX-012 | Curve Parameter | Artist-defined curve | Curve field | D |
| FX-013 | Math / Random / Spline Functions | General per-instance calculations | VM | D |
| FX-014 | Effect Import/Export | Reusable effect recipes | Serialization | D |
| FX-015 | Look-at Boundary / Repulsion / Lean | Example procedural utilities | Fields/transform | D |
| FX-016 | Declarative Read/Write Set | Automatic dependency invalidation | Cyrus extension | C |
| FX-017 | Sandboxed Typed VM | Prevent unbounded/unsafe expressions | Cyrus extension | C |

## O. Shared inputs, tools and extended family

Sources: [ForestSet](https://docs.itoosoft.com/forestpack/forestset-plugin), [Forest Library](https://docs.itoosoft.com/forestpack/forest-library/library-browser), [ForestIvy](https://docs.itoosoft.com/forestpack/forest-ivy/forest-ivy-overview), [Forest Lister](https://docs.itoosoft.com/forestpack/forest-lister).

| ID | Control/feature | Intended behavior | Touches | Evidence |
|---|---|---|---|---|
| SET-001 | ForestSet | Shared reusable collection of inputs | Collections | D |
| SET-002 | Scene Layer Membership | Dynamic collection membership | Host refs | D |
| SET-003 | Nested Collections | Reuse collections within collections subject to restrictions | Dependency | D |
| SET-004 | Role-Specific Consumption | Geometry vs surface/spline collections behave differently | Provider | D |
| SET-005 | Linked Areas | Reuse region definitions across scatter objects | Area graph | D |
| LIB-001 | Library Browser | Browse/install scatter sources and presets | Assets/UI | D |
| LIB-002 | Full Preset | Restore geometry + scatter recipe | Serialization | D |
| LIB-003 | Portable Geometry Preset | Include/bind assets for scene portability | Assets | D |
| LIB-004 | Missing Asset Resolver | Repair unresolved source paths | Cyrus extension | C |
| UTIL-001 | Forest Lister | Manage multiple scatter objects | Scene manager | D |
| UTIL-002 | Convert To Native Instances | Bake scatter into standard Max nodes | Export | D |
| UTIL-003 | Export/Bake Collections | Reusable instance export pipeline | Cyrus extension | C |
| IVY-001 | ForestIvy Plant Growth | Separate climbing/growth procedural subsystem | Plant generation | D |
| IVY-002 | Ivy Branch/Leaf Controls | Growth geometry and botanical parameters | Separate solver | D |
| IVY-003 | Ivy Wind/Growth Animation | Deform/animate generated vine | Time/renderer | D |

## P. What is still required for **literal control completeness**

1. Record ForestPack version **9.4.3** (or selected target release) and Max version in installed UI; capture every rollout and contextual mode.
2. Export a control registry with one row per actual spinner/checkbox/button/menu option; document exact type, units, min/max, default, mode restrictions and visibility dependencies.
3. Reconcile historical UI descriptions in public documentation with the installed version; some labels refer to removed features.
4. For every control create `documented behavior`, `combined behavior test`, `Cyrus behavior`, `known deviation`, `test IDs`, `status level L0–L5`.
5. Make renderer and UV/Paint/Edge compatibility separate dimensions.

Until this audit is performed, the catalog is a **high-coverage design inventory** rather than a verified 1:1 count of all controls.
