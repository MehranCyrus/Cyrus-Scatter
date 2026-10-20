# Cyrus Arrange 0.3.1: scene controls and real model acceptance

Status: **qualified for the documented Max 2027 workflow**. The twenty functional suites
(including the 432-check real-model producer), independent geometry proof,
66-check actual viewport host, 51-check saved-scene GUI readback and 23-check
relocated render/readback have passed, followed by 43 actual MZP installer and
17 automatically discovered installed-startup checks. Exact evidence and deliverables are tracked in
[the 0.3.1 release record](RELEASE_VALIDATION_0.3.1.md).
The delivered 0.3.0 package and its evidence remain unchanged.

## Version and scope

The successor is **0.3.1**, the next development step after 0.3.0. The user asks
for an actual modifier entry, a selectable viewport arrangement control with
parameters in Modify, and a usable scene tested with the prepared tables, books,
plants and decor. These are changes to Arrange presentation and test coverage.
Other Cyrus products retain their versions. Existing registration identities
and document 4, library 2 and registry 1 formats remain unchanged unless an
implementation finding is explicitly recorded here before changing them.

Native C++ remains responsible for geometry, placement, retained state,
transactions, dependencies and lifetime. MAXScript presents controls over that
same document. Merely selecting, drawing or opening a panel must not capture
geometry or solve an arrangement. Failure must retain the previous complete
state and output, and successful authored commands must preserve Undo.

## Scene assets and preservation

Use ready primary models from `Test Scene/Organized Models`, copying the needed
scene geometry and material dependencies into a fresh example. Preserve both
the organized library and `Test Scene/Free Models`. Record source identities,
physical dimensions, selected model parts and dependency relocation. Do not
silently substitute missing renderer classes or change model scale to make a
fit appear successful. Prepared collections may be separated only in the new
working scene. The scene must have simple names and an obvious arrangement
control for each tested furniture target.

## Required acceptance

Use fresh, owned Max 2027 hosts and exact native/script identities. Verify the
modifier is registered, can be added and exposes the intended parameter view;
new setup icons are selectable; modifying settings uses the same native state;
save/reopen, clone, Undo/Redo and stale selection retain correct ownership.
Passive panel operations must leave placement/cache work unchanged.

Build an actual real model scene with tables, books, small plants and decor.
Require nonempty generated output. Independently measure source/output scale,
contact against actual target geometry, edge containment and conservative
non-overlap, using explicit numerical tolerances. Exercise several seeds and
save/reopen the delivered scene. Copy textures locally, check dependency paths
and render the actual result for visual inspection. Separate numerical fit
evidence from visual appearance and renderer support.

Re-run existing functional contracts and native/Python validation appropriate
to the changed native/script pair. Qualify a fresh, immutable Max 2027 MZP in a
private installation and automatically discovered startup. No artist-profile
installation or restart is authorized by this task. Record final identities,
measured checks, limitations and scene-opening instructions after acceptance.
An MZP is immutable during installer qualification; its embedded documents may
therefore say installer-pending. Its external qualification receipt and the
maintained release record report the result without changing tested bytes.

## SDK references checked during implementation

The [native presentation design](NATIVE_PRESENTATION.md) records the supported
scripted-attribute host and the rejected standalone-rollout route. Actual native
stack capture and SDK virtual-call probes showed why the latter entered
Utilities mode and could not qualify a Modify page. Autodesk's
[MSCustAttrib API](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_m_s_cust_attrib.html)
and [scripted attribute guide](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Custom-Attributes/GUID-ADFD29E4-9751-4F55-98CC-F7C721C9AEE2.html)
guide the successor's genuine temporary UI host. Local SDK headers were checked
for display, bounds, hit-testing and lifetime. Only current host tests establish
the complete integration's behavior.

The [Max 2027 command-line reference](https://help.autodesk.com/cloudhelp/2027/ENU/3dsMax-Basics/files/3ds_max_interface_overview/start_3ds_max_from_the_command_line/GUID-1A97CFEC-60A3-4221-B9C3-5C808E2AED35.html)
was checked when separating command-panel acceptance from Batch geometry work.
The Modify suite and installed-startup panel checks use a normal owned Max
process with `-U MAXScript`, a hidden startup window and private configuration.
They require an actual mounted native-hosted rollout. Batch success is not
treated as command-panel or viewport proof. Script-only development runs are
explicitly excluded from package qualification; final acceptance requires the
complete fresh source/build map and unchanged qualified binaries.
