# Cyrus Scatter 0.87.6.7 — Max 2027 testing delivery

29 October 2026. The user-selected **0.87.6.7** includes pinned instance edits,
movement during held drags, panel repaint, assigned-model Band badges, selected
plant-part profiles and guide detail, and the two remaining Library/version
defects in the supplied 0.87.6.3 review. This supersedes the unpublished 0.87.7
candidate label. Earlier candidate receipts retain their original identities.

Install [CyrusScatter-0.87.6.7-Max2027.mzp](../../../dist/CyrusScatter-0.87.6.7-20261029/CyrusScatter-0.87.6.7-Max2027.mzp)
through **Scripting > Run Script**, then restart Max 2027. The package is
2,830,152 bytes; SHA-256:
`92eb40e16751c0f3fdf4bef63001959e70f8b9290e77b9f45d93c3e05321eefa`.
The installer has not been run in the artist profile. No artist Max session was
restarted. Save upgraded scenes as copies: new Edit storage and preparation data
require the new plugin. See the [artist guide](ARTIST_GUIDE.md) for controls,
migration and limits.

## Resulting behavior

- Moving, rotating or scaling an instance pins its full authored transform and
  model choice. Changing Amount > Seed or procedural size variation regenerates
  other instances. **Reset selected edits** restores procedural ownership and
  supports Undo/Redo. Missing compatible owners suspend rather than erase pins.
- Ordinary Mesh/Proxy edits publish selected transform changes during held input
  using retained source geometry. The bounded path handles up to 4,096 selected
  items. It does not consume pending Manual settings or rebuild static placements.
- Layout radio and Layers checkbox captions repaint after panel expansion and
  column changes. Band badges derive from assigned model identification colours:
  one colour, a split badge for mixed models, or no badge when unassigned.
- Source Preparation offers **Stem**, **Leaf** and **Flower head** profiles and
  **3, 5, 9 or 16 guide points** on selected bending pieces. Leaves can have
  independent guides; flower heads can follow a chosen stem rigidly. Unselected
  automatic guides keep their existing shape and attachment owners. Undo/Redo,
  invalid-successor retention, scene persistence and portable capture are covered.
- Scene-load copies receive an ownership marker before copying starts, allowing
  recovery after the owning process exits. Active and unverified stages remain
  protected. New Scene metadata uses the actual Gallery assembly version, and
  licensing/preparation captions no longer embed obsolete versions.

These are deformation guides in the existing mesh; they do not generate missing
visible leaf-stalk geometry or subdivide the source. Profile assignment is an
artist decision. Automatic preparation detail and the endorsed artistic Bend/Trim
baseline are unchanged.

## Exact qualification

The [qualification manifest](QUALIFICATION.json) binds the final MZP to the frozen
648-file source snapshot, the Max 2027 SDK build, producer receipts and loaded
module hashes. The working source still matched that snapshot at sealing. The
branch was already extensively dirty; a clean Git HEAD is not used as a substitute
for the frozen source identity. No commit or push was performed.

| Check | Final 0.87.6.7 result |
| --- | --- |
| Clean Max 2027 SDK build and native suites | 62/62 |
| Generated script | 379 controls accounted; 32 delimiter fixtures; exact packaged script hash |
| Focused Python regressions | 54 passed |
| UI generator suites | Both passed from their required `AminScatter` working directory |
| Managed Library transactions | 261 checks, including interrupted Scene-load recovery, active/unverified-stage preservation and version provenance |
| Ordinary Edit workflow in owned Max | 27 assertions: held presentation, reseed, size, untouched items, cancel, reset, Undo/Redo, save/reopen, portable replay and Manual pending |
| Supplied Terraces scene, byte-identical owned copy | 20 assertions: held presentation/reuse, Seed, fixed edited transform/source, changing unedited items, cancel and reset/Undo/Redo |
| Older Edit scene migration | Matching 0.87.6.5 history binds, reseeds and survives save/reopen |
| Panel and Band workflow | 21 assertions; physical close/open inspection confirms captions remain visible without hovering |
| Exact Violet editor workflow | 43 assertions; physical dropdown selects 16 points for all 62 chosen leaves without altering other stem settings |
| New preparation in full portable recipe | Capture and native validation preserve envelope/source 3, intent 2, profiles and all 74 guides |
| Native exact-Violet shape/roundtrip probes | Automatic metadata unchanged; all source triangles preserved; zero rest-position error for Automatic, stem, leaf and combined profiles |
| Exact-Violet contact probes | Two numerical contacts clear all 17,110 triangles, preserve roots and rigid flower pieces, retain reusable source data and restore rest after removal |
| MZP | CRC, complete member manifest, Max 2027 guard, helper identity and exact qualified script/native/managed payload hashes verified |

The UI test initially invoked from repository root failed because it requires
`AminScatter` as its working directory. The corrected invocation passed; both
logs are retained. A legacy fixed-coordinate pixel diagnostic in the UI harness
did not match the final window layout and is not counted as an assertion. The
actual final labels and badges were inspected through Computer Use and captured
in the owned host. These are harness limitations, not concealed product passes.

## Measurements and limits

Three held SDK transform callbacks per scene had median CPU durations of
**0.249 ms** in the ordinary fixture and **0.344 ms** in Terraces. Each sample
presented its changed matrix while the gesture was held; placement, preparation
and geometry-upload counters remained unchanged. These are controlled callback
and presentation-ticket measurements, not physical mouse latency or GPU FPS.

On the supplied Violet (197 pieces, 10,922 vertices, 17,110 triangles), the
12 automatic stem guides used 3–5 points. Sixteen-point guides reduced the worst
source ring-centre distance to the guide polyline from **7.681 to 0.802 mm**;
each of the 12 stems improved. The authored profiles produced **62 independent
leaf guides** and **120 rigid flower-head pieces**, for 74 guides total. The
measured retained source size rose from 1,467,842 bytes to 1,500,821 for detailed
stems and 1,632,517 for the combined profiles. These sizes exclude transient
process peak memory and are not a contact-speed claim.

The two numerical contact probes preserved root anchors exactly and flower-piece
distances within floating-point error. They do not establish strain-free bending:
the existing skinning reported maximum edge-length changes of about 6.1% and
44.3% in those respective contacts. More guide points improve rest-curve sampling;
they do not make the existing deformation solver inextensible.

Point Cloud, selections beyond the transient-preview cap, prepared interaction
layers and separate radius overrides retain their documented paths/rules.
Receiver geometry incompatibility and old history saved against an unknown
generation remain guarded. Arbitrary modifier-stack cloning, extreme low-memory
failure, general renderer behavior and broad physical input/FPS qualification
remain open. This task does not claim the supplied review's historical test
counts as fresh 0.87.6.7 passes. Its broader optimization and peak-memory advice
remains separate from the repaired FS-01/FS-02 defects.

The original Terraces file remains byte-identical:
`ed764dc7140ea46ded27d544db8ab201ed6daada4fb0de594ad56d1986d63449`.
All five final owned Max processes exited successfully with unchanged artist INI
hashes. No Max 2026 build/run, independent-product release, website build/publish,
knowledge activation or artist-profile installation was performed. Next
acceptance is the artist's assessment of movement feel, pin behavior and profile
choices in their own saved-copy workflow.
