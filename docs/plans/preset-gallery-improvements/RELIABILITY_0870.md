# Library and Amount reliability — 0.87.0

User goal activated 19 October 2026. This is the full delivery checklist; partial
passes do not close the goal. Base delivery is 0.86.2. Preserve existing dirty and
untracked work, independent products, artist profiles/scenes and old receipts.
Use Max 2027 only. Installation/restart of artist Max is not authorized.

## Version decision

Planned **0.87.0**: a substantial delivery adds receiver-context texture evaluation
and explicit reusable Paint binding, revises bundled distributions, and fixes
source/window/Clear lifecycle. This follows the substantial-delivery override in
Release_Versioning. Change only Scatter/coupled metadata. Keep registration IDs
and saved parameter IDs; explicitly revise recipe/native capabilities if their
contracts change. No package is qualified by this proposed label.

## Acceptance ledger

| Goal | Required implementation and witness | Status |
| --- | --- | --- |
| 1 All eight presets | Inventory authored dependencies/assets; new selected surfaces across units/topology/size/transforms; Add/Undo/reload; physical sizes/spacing | Final pair passes all eight in feet/millimetres with independent distance/vertex oracles; pair09 cm/metre campaign remains separate evidence. Final transformed/footprint/heightfield cases recorded below |
| 2 Portable distributions | Valley moss uses receiver-derived relative elevation instead of an uncreated channel; Mountain Planting avoids accidental absolute-world-height dependence; explicit artist channels still validated and selectable | Implemented; final pair passes relative-elevation analytic/preview/transform/channel recovery tests |
| 3 Paint transfer | Fit saved receiver-local XY layout to destination footprint; preserve original document; physical brush/falloff distances and correct units; reject invalid projection/degenerate bounds before import | Implemented; units, changed topology, transformed and small/large-footprint cases pass. Folded receiver rejects without mutation; repair succeeds |
| 4 Receiver-aware maps | Map's own UV/data channels, Vertex Color/Checker/Color Correction/Output chains; multiple channels/receivers; edits/time; preview agreement; clear unsupported requirements | Final pair passes 19 phases, including own UV/data channels, multiple receivers, animation, preview, idle, extreme scales and rejection/recovery |
| 5 Amount lifecycle | Assign/replace/Clear/disable/re-enable; patterns/channels/UVs; nested edits, Manual/Live/history/reopen | Final pair passes complete Amount regression, actual picker callbacks, three patterns, channels 0/2/3/7, history and reopen |
| 6 Model removal | No sources yields valid empty publication; remaining Point/gap sources still supported; multi-source removal/reindex, replacement, Undo/Redo/save, actual node deletion | Final lifecycle/edge passes: leading and last source, Live node deletion, empty reopen, Point/gap, replacement and invalid retained inputs |
| 7 Library window | Existing window restores/focuses without losing view; changed destination safely rebinds; closed window recreated; lifecycle/captured owner validation | Final pair passes normal bounds, same HWND, owner/destination callback renewal and close/reopen. Activation is requested; Windows foreground transfer was not observed while another application remained foreground |
| 8 Validation/recovery | Early dependency inspection, clean artist-facing reason, atomic import/update; failures retain complete prior state, no leftovers | Final pair passes missing/corrupt packages, repeated imports to 10 populations, capacity rejection, missing channels, unsupported graphs, singular transforms and 256 MiB mesh-array rejection |
| Delivery | Current guides/website sources, exact source/native identity, Max 2027 host evidence and runnable verified MZP with install directions | Complete within scope; [delivery report](DELIVERY_0870.md), 38 final-pair host records, exact MZP and disposable installer pass |

## Architecture and invariants

F01/F04–F11 apply. Layer records remain the authoritative authored owners. UI
callbacks capture their layer/root/destination; map nodes retain native Max
reference identity. Existing candidate IDs/order and separate collision scopes
remain. Explicit empty-source publication must clear old geometry; an actually
failed successor retains the previous complete publication.

Projected patterns/images keep the current native scalar-image path. A distinct
Map-coordinates mode evaluates supported native Max texture graphs with receiver
context (evaluated mesh, face+barycentric position, every required map channel,
transforms/normals/time). Host SDK calls stay on the main thread. Native storage
and bounded consumers handle placement-sized filtering and preview. Borrowed
mesh/map pointers cannot escape a synchronous evaluation. Placement and field
preview share map evaluation and response semantics. Missing channels/nonfinite
data/unsupported requirements fail explicitly. Relevant map/receiver changes
invalidate; warm idle, browsing and unrelated animation must not evaluate maps.

Paint reusable binding creates a new validated document. It maps original
receiver-local XY bounds to destination receiver-local XY bounds, preserving
relative layout including empty/full coverage. Plant size and spacing remain
physical. Brush/falloff distances convert system units, not terrain footprint.
The supported receiver remains single-valued local XY; arbitrary folded/stacked
surfaces receive a clear preflight rejection. Source documents are immutable.
Exact original-scene restoration remains distinct from reusable preset binding.

Valley distribution should express relative local elevation, computed from the
evaluated receiver, without editing the artist's mesh or creating hidden channel
modifiers. Flat terrain receives a defined low-elevation value. Explicit channel
mask mode remains separate. Native fields/preview must use identical normalization.

Memory/work: preserve native immutable row views, bound graph size and host sample
work before evaluation, cap field detail and receiver mesh size, and record peak
coexistence of old/new results. Avoid per-candidate script arrays. Map and Paint
changes stage before normal publication; Undo retains authored references/new
documents without overwriting originals. Source removal must use normal atomic
publication rather than manually deleting display objects.

## Test matrix and completion audit

Test fresh destination scenes in metres/centimetres/millimetres/feet, tiny/large
footprints, different subdivisions and topology, translated/rotated/scaled and
mirrored receivers, multiple receivers, zero/empty/high amounts, all-black/white
masks, missing/corrupt channels/assets, unsupported Paint geometry, repeat imports,
owner switching, node deletion, nested and animated maps. Exercise Manual/Live,
Undo/Redo, save/reopen, visible/hidden preview, idle and unrelated edits. Use
independent scalar/physical-coordinate oracles and exact publication comparisons
where invariants require them. Record unsupported boundaries explicitly.

Before completion, inspect evidence for every ledger row and every matrix axis;
missing evidence remains open. Validate archive CRC, host/version guards and all
payload hashes against the exact qualified script/native pair. Provide Max 2027
MZP and **Scripting > Run Script**, then restart instructions. Do not install it
or restart the artist session. No Git push/deployment is implied.

## Work record

- Initial goal turn: rechecked branch/HEAD/tracked scope; retained the Clear
  candidate and its [reproduction](AMOUNT_MAP_AUDIT_20261019.md). Next work is
  native/recipe boundary inspection and scoped lifecycle corrections.
- Lifecycle candidate: `D:/CyrusScatterBuilds/reliability-0870-20261019/native02`
  passed SDK compilation and all 45 native CTest cases. Owned Max 2027 profile
  `build/mcp-qualification/density0862-reliability-0870-01` passed all 15 phases
  in `tools/reliability_0870/lifecycle.ms`; `lifecycle-result.json` records hashes
  of loaded script, launch identity, test and every phase log. The owned host
  was closed after qualification. This is a candidate with the existing 0.86.2
  caption; it is not the final 0.87.0 package or qualification of later edits.
- `tools/reliability_0870/preset_inventory.py` records all eight source recipes in
  `build/reliability-0870-20261019/before-preset-inventory.json`. Static inspection
  found Mountain Planting's enabled absolute altitude range in addition to the
  already known Valley channel and Paint dependencies. This inventory does not
  prove transfer behavior or asset/package integrity.
- Map candidate introduces explicit **Map coordinates**; assigning with Map
  chooses this mode, while selecting an image/pattern chooses projected World XY.
  Host-thread texture sampling supplies the receiver face/barycentrics, declared
  channels and object/world frame. Native row filtering and field overlay use the
  same evaluator. Ordinary image sampling explicitly rejects Map coordinates to
  prevent a silent context-free fallback. Graph bounds and unsupported map/context
  errors are explicit. Recipe graph portability, full requirements, animated maps,
  costs and final package qualification remain open.
- Map candidate `native03` passed all 45 native tests, followed by script-only
  pair `D:/CyrusScatterBuilds/reliability-0870-20261019/pair04`. The first Max
  attempt exposed a fixed-format geometry revision being contaminated by a channel
  key. The paired correction keeps geometry revision and map-channel data separate.
  Owned Max 2027 profile `density0862-reliability-0870-02` passed all 11 map phases,
  the 15 lifecycle phases again, and the established Amount/Clear regression.
  `receiver-map-result.json`, `lifecycle-result.json`, `amount-result.json` and
  `script-stage.json` pin the tested script and logs. The owned host was closed.
  Witnesses include exact black/white and RGB channel values, own UV1/UV7,
  multi-receiver data, mirrored/scaled/rotated receiver, nested Live edits, no idle
  samples/solve, save/reopen, Clear/pattern/mesh switching and Undo/Redo. This does
  not qualify arbitrary map classes, all coordinate generators, animated maps,
  portable graph export, large-workload performance, later Paint edits or a release.
- Native Paint candidate fits saved coverage to destination-local XY and converts
  physical falloff/radius by system units only. Package preflight reads the admitted
  saved mesh footprint without staging a scene node; exact recipe restoration stays
  separate. Source packages with Paint already require baked receiver object offsets.
  Path guides use the same XY footprint fit; their physical widths/heights remain.
  Current build: `D:/CyrusScatterBuilds/reliability-0870-20261019/native05`.
- Paint host evidence: script pairs `pair06` and `pair07` in that build family,
  owned Max 2027 profile `density0862-reliability-0870-03`, passed both Formal
  and Borders on fresh 20 x 30 m receivers in centimetres, metres, feet and
  millimetres, plus both presets in centimetres/metres with translated, rotated,
  mirrored and nonuniformly scaled terrain (12 cases). Each case verifies one
  Undo, Redo, asset cleanup and exact save/reopen publication. These counts do not
  independently prove physical source dimensions across units. The folded-box
  case rejected before adding layers but exposed a missing forward global
  declaration in the new error formatter: the status retained its initial text.
  That failure is preserved; the declaration is corrected for the next candidate.
  Host 03 was closed before changing its native payload.
- The relative-elevation candidate adds an explicit surface field choice, with
  default **Mesh channel** preserving existing scenes and recipes. Format 7
  appends `meshMaskSource`; formats 1–6 upgrade to channel mode, never silently
  reinterpret an authored channel. Elevation uses referenced local mesh vertices,
  normalizes low/high to 0/1 and defines flat terrain as 0. The shared native field
  drives placement and preview. Planned bundled revisions use this mode for
  Valley and replace Mountain's accidental absolute-world-height dependence.
  Isolated construction vertices no longer stretch transferred Paint/path
  footprints. Native build 08 compiled; its first test attempt passed 44/45 tests.
  The new recipe test incorrectly called the file serializer on hydrated Paint;
  its corrected rerun is pending. No release qualification is claimed.
- Build 08's corrected native suite passes all 45 tests; generated validation
  passes with 321 controls and all 262 recipe fields accounted for. The broader
  Python run passed 174/175 tests, with only the intentional control-count guard
  outdated; its corrected focused test passed. The original failure logs remain.
  Owned host 04 loaded build 08, then script-only pair 09. Relative elevation's
  eight phases passed: analytic slope, flat/inverted field, preview agreement,
  transforms, physical rescaling, missing-channel mode/recovery and scene reopen.
  Both Paint examples passed folded-receiver rejection, zero leftovers and repair,
  followed by Undo/Redo and save/reopen. Lifecycle adds empty container/missing
  channel/extreme grid and replacement repair, plus safe Library owner/destination
  switching. Window bounds and reuse pass; foreground activation was not observed
  because another application retained foreground during the background test.
- Host 04's map witnesses pass native channel/UV sampling, nested edits, Manual
  and Live map animation, current mask preview, and no solve/sample on unrelated
  animation. Unsupported Falloff and excessive nesting reject and recover with
  exact publication retained. A fixture typo left an enclosing host hold after
  its thrown request; it was recorded and cancelled only in the owned profile.
  Repeating animation and rejection with hold-state logging ends every phase
  outside a hold. This does not authorize cancellation of an artist's hold.
- All eight maintained examples were reauthored into the disposable
  `build/reliability-0870-20261019/library08` copy. Its baseline receipt preserves
  original file hashes. Valley and Mountain use relative elevation and have fresh
  exact-placement thumbnails; all eight packages pass native file validation.
  The staged index contains 104 reachable current payloads. Source library is
  unchanged; destination campaign and physical-dimension oracles remain open.
- Product metadata now selects **0.87.0** for the next candidate. Native build 10
  also bounds retained receiver-map mesh arrays to an aggregate 256 MiB per
  operation/overlay and uses a scale-relative transform singularity check.
  This array accounting excludes host-owned texture caches and SDK internal
  allocations. Build 10 and final host/package qualification remain pending.

- Final native10 compiles and passes all 45 CTest cases. Generated-code checks pass with 321 controls; all 175 Python tests pass. Owned hosts 05/06 load the exact 0.87.0 script/native pair. Host 05 passes lifecycle, Amount, relative elevation and the complete 19-phase receiver-map campaign. Host 06 adds leading-source removal, empty scene reopening, explicit gap/Point distinction, missing/hash-damaged package recovery, three independent repeated imports, population-cap rejection and a real 288 MB unused-channel allocation rejected by the 256 MiB retained-array bound. Initial failures in these new harnesses were fixture phase names/UI settling and an incorrect expectation that an Empty gap produces visible plants; original request/log files are retained. No product failure is hidden by those corrections.

- Final acceptance: all 38 recorded final-pair suites/cases passed. The preserved original library is hash-verified before source promotion. The exact MZP passes archive/hash/host/version checks and the packaged installer passes disposable install/repair/rollback/retry/unregister tests. Website content verification and local production build pass. See DELIVERY_0870.md for limits and user installation directions.
