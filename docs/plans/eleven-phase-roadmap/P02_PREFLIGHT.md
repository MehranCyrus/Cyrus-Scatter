# P02 preset preflight — source and format decisions

14 October 2026. Preparatory research while P01 visual acceptance is unavailable.
P02 implementation has not started. This does not waive P01's acceptance/push
gate, qualify a preset workflow, or change the candidate version.

## Evidence and boundary

Read against the 0.81.8 candidate, schema 58, generated script SHA-256
`1c40a0147fe176825f96752f1c565ec70e8c6e020732e97428cd06e291e76e50`.
Current authoritative source is
[unified-core.ms](../../../AminScatter/tools/ui/templates/unified-core.ms).
The source inspection below is separate from the planned behavior.

Forest documents parameter-only presets that preserve external object references
and a separate library workflow that can import complete objects and geometry.
That supports the P02/P10 product split; it does not establish Forest's private
serialization or caching implementation. Cyrus will require an explicit Apply
action so selecting a name remains passive. See the official
[General rollout](https://docs.itoosoft.com/forestpack/forest-plugin/general) and
[Library Browser](https://docs.itoosoft.com/forestpack/forest-library/library-browser).

## Observed code constraints

1. `AminScatterLayerFields` / `AminScatterCopyLayer` include source/receiver
   references, candidate salts and IDs, Paint documents, output/display fields,
   and controllers. They are not a safe preset allowlist. The new category
   descriptor must enumerate only its intended authored values.
2. `layerTransfer` suppresses min/max companion-value correction during bulk
   assignment. Setters still call `markInputDirty`. The latter marks cached
   validity/dirty state; it does not itself perform a solve. Preserve the prior
   transfer state in success and failure paths; do not mistake it for a general
   atomic transaction or scheduling lock.
3. `procSelfRule()` resolves a layer's explicit override or saved defaults.
   The visible spacing editor offers Within this layer and Between layers.
   Pair rules live on the root and contain owner IDs. Saving an effective rule
   and saving inheritance state are different operations.
4. World distances use typed world-unit properties. `plantsPerM2` already means
   plants per square metre; generation divides by `units.decodeValue "1m"`
   squared when it needs density per scene-unit area. Preset conversion must not
   scale this density twice.
5. The curve editor samples 257 positions and also stores eight numbers per
   graph control point. Band graph edits have a 64-point limit and capture the
   controller, layer, Band and Path identities. Density is bounded to 0..1;
   Paint scale is also clamped to 0..1. Band scale supports 0..100 multipliers.
   These domains cannot be treated as interchangeable generic curves.
6. Curve storage differs by owner: Paint uses `cyrusBrushSetFalloff` plus
   `publishPaint`; ordinary boundary/area curves use `setFallConfig` and
   `setFallGraph`; Bands use parallel sample/graph arrays. A curve preset needs
   an explicit target adapter, not only a write to a similarly named property.
7. The repository already pins nlohmann/json 3.12.0 in
   [CyrusLicensing/CMakeLists.txt](../../../CyrusLicensing/CMakeLists.txt).
   Its include path is currently conditional on licensing integration. If used
   for preset parsing, expose that header dependency explicitly to the preset
   target without linking preset behavior to license policy or changing it.

## Proposed category contract

The first implementation step must finalize numeric bounds against the native
readers and freeze the field table. The following is the reviewed starting map.
No stored node handle, owner ID or arbitrary parameter name is accepted from a
preset file.

| Category | Authored values | Apply target |
| --- | --- | --- |
| Population | `amount`, `populationMode`, `plantsPerM2`, `randomSeed`, `procPopulation`, `procAttemptFactor`, `procRounds`, `procRepair` | Captured ordinary layer; never its Paint Areas or the root's Manual/Live setting |
| Transforms | Active axis/legacy mode, XYZ rotation/scale/movement ranges, whole-scale range, normal alignment, movement projection, and the legacy scalar values still consumed when axes are disabled | Captured ordinary layer; no source-specific size, pivot, forward-axis or radius rows |
| Spacing rule | Enabled, radius multiplier, physical gap, XY/3D metric | Explicit current Within-layer or Between-layer scope; a pair's two owners are chosen in the scene, not serialized |
| Density curve | Canonical density samples and editable graph trace | Explicit Paint, area/Analyzer boundary, or Band density target |
| Scale curve | Canonical scale samples, graph trace and semantic domain | Explicit compatible scale target; reject values outside the target domain without clamping |

Spacing Capture stores the **effective numeric rule**. Apply creates an explicit
override for the chosen scope; it does not silently replace defaults or pair
membership. Reset/inheritance remains a separate existing action. Candidate
Relax and final cleanup are separate operations; their settings should not be
changed by an action labelled Spacing rule.

Curve Apply changes the selected curve, preserving widths, density/scale enable
flags and scale ranges. Display the target's enabled state so saving a curve
does not imply the feature is active. Captured ownership must be revalidated
after dialogs and any panel rebind; deleted/replaced owners fail before writes.

## Data and persistence requirements

- One UTF-8 JSON document per preset, with an explicit format version, category,
  display name and category-specific values. Proposed initial bounds: 64 KiB per
  file, nesting depth 8, name length 80 characters, and 512 indexed user files.
  These are product admission limits to test, not performance measurements.
- Store distances in metres, density in plants per square metre, angles in
  degrees, and factors as dimensionless values. Convert once at the scene
  boundary. Reject non-finite or out-of-range converted results.
- Reject duplicate/unknown keys, wrong primitive types, fractional integer
  fields, unsupported versions, missing fields and trailing content. There is
  no `execute`, `fileIn`, code expression or automatic object reconstruction.
- Retain samples as the evaluation authority and graph handles as the editable
  representation. Accept a graph only when its reconstruction agrees within a
  defined host-tested tolerance. A samples-only preset remains editable as a
  sampled polyline without inventing Bezier handles. Resolve the 257-sample
  representation versus the Band editor's 64-control-point bound before coding
  the final curve format; do not silently resample an arbitrary trace.
- Use opaque local file IDs and keep display names out of paths. Save creates a
  new item; replacing an existing item is an explicit action. Rename changes
  metadata, not the scene. Delete targets only the selected library item.
- Write a uniquely named temporary file beside the destination, validate it,
  then perform a single replacement. A failed write leaves the old item usable.
  Do not implement replacement as delete-then-write. Keep reads bounded even
  when files change between listing and opening. External edits require a fresh
  validation before Apply; a cached label is not a trusted payload.
- Microsoft documents same-volume restrictions and failure cases for
  [File.Replace](https://learn.microsoft.com/en-us/dotnet/api/system.io.file.replace).
  That is an available mechanism to qualify in both Max hosts, not proof of
  crash durability. Choose the exact native/.NET file boundary during P02.
- If using the pinned JSON library, a parser callback's `false` means filtering,
  not rejection. Duplicate/depth violations must abort validation. Its current
  [callback documentation](https://json.nlohmann.me/api/basic_json/parser_callback_t/)
  includes later unreleased changes; test against the pinned 3.12.0 header.

## Application and qualification plan

Parse, validate and convert into a complete proposal before changing scene
parameters. Capture the old authored values and the target identity. One native
Undo operation applies the proposal, restores transfer/guard state on every
exit, and schedules the existing invalidation once the whole proposal is valid.
Failure after the first setter must restore authored values as well as preserve
the published placement result. An Undo label alone does not prove rollback.
Do not use the enclosing Python execution hold to qualify this operation.

Before implementation, settle application to animated/wired/shared parameter
controllers: a numeric preset must not accidentally remove animation, insert
keys through Auto Key or alter another owner through a shared controller. Test
the chosen policy explicitly and describe it in the Apply feedback.

| Witness | Required evidence |
| --- | --- |
| Each category | Capture A, apply B, compare every included value and every protected owner/reference field |
| Physical units | Metre and centimetre scenes agree in physical distances; density stays numerically per m² |
| Curves | Density and each scale domain; handle/sample consistency; reopen does not alter the stored result |
| Spacing | Within-layer defaults versus override; explicit pair target; other pair rules unchanged |
| Atomic scene apply | Inject failure after partial assignment; exact authored restoration and previous complete publication |
| Undo/Redo | One native transaction; repeated cycles preserve Manual pending behavior and stable owner identity |
| Live | One completed intended successor; no intermediate category state can publish |
| Passive browser | Opening/selecting/renaming/deleting presets changes no scene settings, solve counts or uploads |
| File failures | Duplicate keys, malformed UTF-8/JSON, excessive bytes/depth, future version, interrupted write, locked/read-only destination |
| Lifecycle | Target deletion or replacement while dialog open; current-schema save/reopen/copy/merge |
| UI | Actual generated controls, real subsequent timers, and physical visible workflow at working panel width |

This is preparatory evidence only. No P02 acceptance box is complete, no product
code changed for this preflight, and no vendor implementation claim is made.
