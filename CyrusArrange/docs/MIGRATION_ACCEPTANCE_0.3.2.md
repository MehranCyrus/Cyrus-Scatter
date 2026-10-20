# Older scenes and the geometry workflow

Opening an older arrangement must preserve its saved result. Regeneration is an
explicit edit: current geometry rules may choose different unlocked placements.
Protected placements and their retained relationships must remain exact. A
single Undo must restore the old settings, records and actual output references.
Opening or saving alone must not silently regenerate or infer book eligibility.

## Independent released inputs

`tests/data/baseline-011` retains the released schema3 gallery and portable
library1. The gallery contains five native Documents and 35 saved placements.
`tests/data/baseline-031` retains a real schema4 book-row scene: three Documents,
45 saved placements and nine ordered groups. The latter was **authored by 0.1.3
and distributed unchanged with 0.3.1**. Its provenance manifest records the
unchanged scene, release archive and original producer. It is not described as
a scene authored by 0.3.1.

The expected original IDs, revisions, world poses, locks, parent references and
row descriptors are literal values decoded from the original native chunks.
They are not regenerated using the candidate. The baseline files remain
immutable; every successor is saved in the owned test output folder.

## Maintained acceptance

`tests/max/arrange_migration_tests.ms` checks passive loading, exact public poses,
actual output transforms and reference survival, source geometry and material
descriptions, idle ticks, and separate save/reopen. It then checks current
Quantity generation, truthful counts, current-seed repeatability and one-step
Undo/Redo. The original portable library imports without live sources or
guessed row profiles and explicitly exports the current format.

The schema4 case protects a complete saved row through one member. An invalid
minimum draft must preserve the old recipe, revision, seed and node handles.
Explicit current Generate stages ordinary geometry and minimums atomically,
retains the protected row's exact ordered descriptor and poses, and leaves other
Documents unchanged. Analytical checks of actual book bounds cover the original
TV's support levels, divider, roof, edge margin and inter-object gaps. Save,
reopen and repeated Generate must preserve the accepted successor.

These assertions do not require a new geometry solver to recreate an old
category-filtered algorithm's unlocked result. Source comparison covers vertices,
faces, smoothing, face material IDs, transforms, hierarchy and material
descriptions. Dedicated visual and real-model suites own UV, explicit-normal and
renderer coverage. This Batch suite makes no mounted-UI or performance claim.

## Qualification status

The reviewed fixture and unchanged baseline were adopted before the fresh
`build/native-032-release03` freeze. The adoption record is
`build/migration-032-adoption03.json`. Actual acceptance requires a terminal
current-source host receipt with both native-path guards, binary hashes, private
INI identity and unchanged artist profiles. Adoption or a static decoder result
is not a Max pass. Final release qualification remains pending.

The first current-source Batch run, `host-032-release03-arrange_migration_tests`,
passes57 assertions before a fixture exception while snapshotting the gallery's
camera target. All identity/profile guards pass and the host exits0; its overall
receipt remains failed. Autodesk's [2027 geometry export tutorial](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/How-To-Practical-Examples/How-To-Read-Write-Geometry-Data/GUID-537409FE-EF5B-4E02-8261-456F74134CA5.html)
explicitly excludes TargetObject: its historical superclass is GeometryClass but
it has no mesh. The successor fixture retains target class, transform and
hierarchy in the source snapshot while excluding only that class from mesh
capture. All actual geometric sources still require a valid complete snapshot.
Native release04 rebuilds the resulting189-input map and passes21 native suites.
Its fresh migration host passes155 assertions, including the complete schema3
passive/save/reopen and explicit geometry/Undo/Redo/repeat cases. It then raises
a MAXScript free-thunk error while an inline library-check comprehension reads
its enclosing `imported` local. The library command itself returned eleven
source-free assets. The receipt remains failed; schema4 acceptance was not
reached. The successor must evaluate that loop before passing its boolean to the
check function, preserving every source/profile condition. No failed or partial
count qualifies the complete migration family.
