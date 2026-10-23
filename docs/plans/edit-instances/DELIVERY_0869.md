# Cyrus Scatter 0.86.9 — Edit instances

23 October 2026. **Implemented and qualified for the recorded focused scope.**
One EXE installs Scatter 0.86.9 and independently versioned Surface Analyzer
0.14.2 for Max 2024, 2026 and 2027. Final producer, package and host identities
are recorded below and in [the qualification manifest](QUALIFICATION_0869.json).
Earlier candidate results retain their original scope and are not substituted
for final-pair acceptance.

## Scope and ownership

Implements the [approved plan](IMPLEMENTATION_0869.md) from baseline
`7d5fd264f8c39e306389977d1eda7c4f358bd3c8` on `codex/workflow-0.75`.
The implementation preserves schema 59, recipe 8, source-clearance calculation,
original Paint and content 0.86.7. It does not change the artist's running Max
sessions or installation, publish a website, or commit unrelated work.
Baseline hashes and worktree inventory are retained in
`build/edit-0869-20261023/baseline.json`.

## Changed behaviour

- Edit handles use the existing Model, Layer and Bands identification palette.
  A selected handle keeps its colour and adds contrasting black/white marks.
  Palette changes are presentation work and preserve pending Manual settings.
- Display, picking, selection bounds and transform gizmos resolve the same
  final accepted placement. A lower Edit modifier's world-space gesture is
  converted through the later Edit transforms. Singular conversions refuse the
  edit without changing authored state.
- Removing a model retains its saved move, deletion and clone histories as
  inactive records. Matching surviving candidate/source pairs keep their edits;
  another model assigned the same candidate cannot inherit them. Undo and
  re-adding the original compatible source can restore the original history.
- Source compatibility now separates the generation basis, receiver geometry
  and persistent source settings. Seed changes, changed receiver geometry and
  incompatible retained-source settings remain guarded. Node names and compacted
  list indices do not establish correspondence.
- Point and gap source slots preserve already saved placeholder identities;
  newly added placeholders use persistent authored row IDs. Removing an earlier
  list item cannot rename the surviving role or assign an old role to a new row.
- Radius overrides remain owned by the layer. A versioned descriptor records
  candidate/source correspondence; inactive values remain saved. A disabled
  population's empty result does not replay overrides or require a transient
  prepared binding immediately after load.
- Failed CPU successors restore Edit state, prepared rows, binding and complete
  publication together. At the separate renderer boundary, handles retain the
  actual visible generation until the new display commits. Movement, deletion,
  cloning and selected-radius authoring reject a mismatched displayed generation.

## Native and saved-data design

`edit_binding.cpp` compares bounded source-aware descriptors while retaining
the exact preceding binding as legacy evidence. `source_radius.cpp` owns
lineage capture, replay and authoring for overrides. The native modifier owns
source variants, stable order, authored deltas, selection and clone IDs in its
existing copy-on-write storage. MAXScript coordinates bounded source metadata,
the actual Remove command's Undo hold and complete publication.

An immutable final native view and palette are shared across Edit modifiers.
Each modifier retains its own immutable intermediate input and shared authored
blocks for gesture conversion. Renderer feedback uses bounded snapshots and
weak host handles with serial checks. Capture, stage and commit run on the host
thread; snapshot destruction and worker activity never call Max APIs.

Native Edit capability and storage are version 2. The new `0x7302` chunk stores
source history and explicit scalar matrix data. The old `0x7301` reader remains
available for supported existing scenes; a guard in that recognized chunk makes
an older plugin reject upgraded source-aware files. Load validates complete
temporary state before installing it. Unknown, truncated, duplicate or invalid
records cannot partially replace edits. Save an upgraded copy and preserve the
original scene; opening new source-aware files in an older plugin is unsupported.

Legacy ownership is hydrated only from a compatible original generation. An
already incompatible old scene retains its payload and requires restoration of
the matching setup. It is never remapped by position or name. The actual source
Remove command captures old ownership before changing the list, without forcing
evaluation of pending Manual settings. **Reset all edits** explicitly labels the
existing modifier-wide reset operation; it is never automatic.

## Actual Orange Tree alignment finding

The read-only library witness is
`Models/Trees/A076 - Orange Tree/model.max`, SHA-256
`d4652fd353f77980b40a3ec09dab330dc19f069229c632f8bc0d414020af2119`.
In the owned Max 2027 scene its node/object transforms and object offsets were
identity. Native pivot-local bounds were approximately
`[-309.984,-312.456,0]` to `[309.984,312.456,686.436]`.

The mean of the 11 vertices in the bottom 0.5% of its height was
`[112.791,129.061,1.68368]` in pivot-local coordinates. This sample is a geometry
measurement, not a claim to locate a unique mathematical trunk centre. The
viewport capture visibly places the trunk to one side of the source pivot.
At source scale 0.01 the sampled horizontal displacement is about 1.71 cm in
the centimetre test scene. The native marker matrix exactly matched the
published instance matrix before and after movement.

This witness is an asset-pivot offset. It is not caused by using the canopy
bounding-box centre in the Edit drawing routine. The implementation preserves
the asset's pivot, vertices, stored deltas and Auto Radius. It does not silently
recenter the tree or introduce a second display anchor. Full Mesh, native marker
coordinates and the actual viewport image are all checked separately.

## Focused evidence

Evidence root: `build/edit-0869-20261023/`. The final Max 2027 production
build is `scatter-2027-02`; the final functional host is `hosts/max2027-03`.
The private fault build is `scatter-fault-2027-02` and ran only in
`build/mcp-qualification/foundation-spline-edit0869-fault-02`.

| Area | Current evidence | Status |
| --- | --- | --- |
| Generated UI/version/catalog | `generated-04/generated-check.json`: 333 controls, 32 bounded fixture delimiter checks | Passed |
| Affected Python packaging/provenance/version checks | `focused-python-final.log`: 69 tests | Passed |
| Scatter native | Distinct clean 2024/2026/2027 SDK builds; 56 CTest targets per host | Passed |
| Surface Analyzer | Distinct clean 2024/2026/2027 SDK builds; 1 native test per host | Passed |
| E1 feedback/stack/Bands | 7 + 3 + 2 assertions; actual viewport capture inspected | Final production pair passed |
| E2 source removal | 9 assertions through actual generated Remove handler | Final production pair passed |
| E3 dormant state and ordinary controller copy | 5 assertions, including evaluated copy matrices | Final production pair passed |
| Genuine 0.86.8.7 migration | 4 assertions: exact fingerprint/selection, upgraded round trip, incompatible preservation and recovery | Final production pair passed |
| E4 CPU guard/rollback | 6 assertions | Final production pair passed |
| Real Orange Tree | 4 assertions and inspected image/coordinate log | Final production pair passed |
| Point identity / disabled saved radius | 3 + 3 assertions after reproducing each edge failure on the first candidate | Final production pair passed |
| Late renderer failure | Private build: 56 CTest targets and 5 actual viewport assertions; no fault hooks in packages | Passed |
| New-format / old-reader boundary | Preserved 0.86.8.7 module rejects the final upgraded scene, 1 assertion | Passed |
| Max 2024 and 2026 compatibility | Per host: 33 core assertions + 4 Analyzer/Gallery + 6 high-poly admission/recovery | Passed |
| Exact MZP adapters | 8 actual installer assertions per host, 2024/2026/2027 | Passed |
| Exact EXE handler | `build/e869e01/receipt.json`: 53 assertions, all three host cards, exact installed bytes and repeat update | Passed |
| Fresh EXE-installed startup | Automatic installed wrappers and exact loaded native/managed paths, plus 11 functional assertions per host | Passed |

Host results bind request, run, artifact, fixture and loaded binary identities.
The driver publishes each request once and observes unresolved requests rather
than replaying mutations. Early fixture failures are retained: selecting the top
Edit modifier did not mount the base Scatter rollout; newly loaded renderer
feedback needed a completed frame before inspection; receiver callbacks needed
normal message processing. Max 2024 required setting the base rollout after the
last node selection. A recovery fixture initially tried to author radius values
while it deliberately kept viewport refresh suspended; the new stale-feedback
guard correctly refused it. The corrected fixture awaits a completed frame.
MAXScript member-access/conditional errors in new installer fixtures were fixed
before their accepted runs. These changes affect qualification tools, not shipped
product code. Earlier failures and their original request identities are retained.
The first installed-startup probe also compared slash styles literally; correcting
the fixture's path normalization allowed a fresh process to verify the same
installed bytes. Owned process-close races were observed without terminating a
replacement or unrelated process.

The final production Max 2027 campaign has 46 functional assertions, plus the
separate five-assertion renderer failure witness and one old-reader refusal.
Its old-scene placement fingerprint is exactly
`84632088898976ab42e35f397970c281d56fc61ff5819f7ea7e8762039ae00f8`;
the selected ID remains `c:4294967296`. Numerical comparisons of saved/copy
matrices use a 0.0001 system-unit per-row vector tolerance; IDs, lineage, clone
IDs and deletion flags are exact. Undo/recovery fingerprints are exact.

One final-pair host launch (`hosts/max2027-02`, PID 57060) exited before the
fixture bootstrap produced `loaded.tsv` or readiness. Its host log ended during
Python module imports; the cause was not established. No product change or
termination followed. The next fresh owned host loaded the identical bytes and
completed the campaign. The unsuccessful launch and observation are retained.

The older-host memory witness uses the unchanged A097/A098 library files and
draws two green Maples, 3,281,260 placement triangles. Lowering the allowance to
256 MiB preserves the current resources; an appearance successor is refused
with a status, and restoring Automatic recovers Mesh without publishing the
pending Count. The captured original-material tree is a black silhouette in
the older host. This proves geometry admission and recovery, not textured
material parity or Corona rendering on those hosts.

## Limits

- Qualification uses small owned scenes and scripted SDK/UI notifications.
  Viewport images are visually inspected. This is not a physical mouse, DPI,
  renderer-material or long-session qualification campaign.
- Changing source membership may legitimately change weighted assignment,
  accepted counts and collision outcomes. Preservation means authored identity
  and recoverable history, not identical scatter after changing its population.
- A pre-existing full-object-copy limitation remains when upper Edit modifiers
  edit clones produced by lower Edit modifiers: regenerated clone IDs are not
  remapped across that stack. A radius override targeting a cloned instance also
  needs coupled ID remapping on full-object Copy. The original setup remains
  intact. Ordinary same-controller editing/save/load and the tested single-Edit
  copy are separate from that unsupported copied-stack case.
- Layer-panel Copy already refuses authored Edit/radius transfer. Portable
  recipes continue to refuse unsupported authored Edit/radius data.
- The local knowledge index remains stale in part; these source/doc edits do not
  publish a refreshed index. No website deployment or artist install is included.

## Installer

Download [CyrusScatter-0.86.9-Setup.exe](../../../dist/CyrusScatter-0.86.9-20261023/CyrusScatter-0.86.9-Setup.exe).
The [package folder](../../../dist/CyrusScatter-0.86.9-20261023/) retains matched
Scatter MZPs for 2024/2026/2027 and Surface Analyzer 0.14.2 for each host.
Existing content is reused; the optional content ZIP remains separate. Save
and close the target Max versions, run **Install / Update**, then reopen.
Alternative guarded MZPs use **Scripting > Run Script**, followed by a restart.
This work did not install into the artist's profile, restart their Max session,
commit/push changes, build website artifacts or publish a website.

The exact recipe is `build/edit-0869-20261023/packages01/recipe-receipt.json`.
Distinct SDK producers are `scatter-2024-01`, `scatter-2026-01` and
`scatter-2027-02`, with `analyzer-2024-01`, `analyzer-2026-01` and
`analyzer-2027-01`. Their complete source-bound receipts are carried into each
package receipt. The unchanged managed installer core was reused only after
its selected source/compiler/reference closure verified; its SHA-256 is
`6c25fbbd1166255a8fcc3b4108379d9c91f216c72a4cd0268273d4231fce5a0a`.
Private failure-injection binaries are excluded from every package.

| Artifact | SHA-256 |
| --- | --- |
| Combined EXE | `e9e35f5e1c6cb4bf40abb8de293a71faf0c8598a213c9d861e01a9aa91adb208` |
| Scatter Max 2024 MZP | `46a6f30ddfbb3a1a4ca02d161a527420b1bb2caefecb36286660db96b2b08cbe` |
| Scatter Max 2026 MZP | `88df2d98a4bb2eb16c644f96033a23bac8774da9f0ce4d50ebd6615facd59c0e` |
| Scatter Max 2027 MZP | `4a47b6daa3de2625e29edaa76f40d44cfafa0426692a0f85e7ad7aa00603cdfc` |
| Analyzer Max 2024 MZP | `e95dec9ae18e7c7542d7bdd65060570f0c3617c73d4badcccf4c190cc789cecc` |
| Analyzer Max 2026 MZP | `1cc1b09b0c7b22a0ec4492ff11650b606b3f52c5a31270e22cae68f6c7929885` |
| Analyzer Max 2027 MZP | `8b1adb26709e9b73ebdff195e6c7796c54c283eec0ee46ea50b4a1685f24f011` |
