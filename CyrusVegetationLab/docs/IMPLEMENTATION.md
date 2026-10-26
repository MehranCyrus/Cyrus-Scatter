# Grass and stone lab 0.1.0 — implementation boundary

User authorization: build a small Max 2027 test plugin for trying the reviewed rooted-grass/stone interaction. This is an independent experimental product, **Cyrus Vegetation Lab 0.1.0**. First coherent artist-test delivery warrants its own initial version; Scatter remains 0.86.9.2, schema 59. It does not resume other roadmaps.

## Artist flow

Create a demo with 1–21 prepared grass ribbons and a standard Sphere stone. Move/resize the sphere, then press Fit. Reset restores the same authored planted roots and rest ribbons. Bake Mesh creates an ordinary mesh copy. Existing scene content is never reset or removed by a demo command.

The first supported colliders are complete, unmodified standard Spheres with rigid/uniform-scale transforms. Grass owners support rigid transforms. Nonuniform/sheared owners/colliders, hemisphere/slice/deformed stones and arbitrary imported plants are rejected explicitly. Default demo: seven tapered 60 cm ribbons, each 3 cm wide at the base and eight spans, near a 25 cm stone. A constant 15 mm guide envelope conservatively bounds the taper. This is static fitting, not timeline dynamics.

## Ownership and publication (F05–F07, F09–F11)

- Reviewed A/B/C modules are copied with SHA-256 provenance; C includes the four qualified local corrections. Their frozen public source header is retained. Native C++ owns rest/binding data, fitting, validation, cache and lifetime.
- A native ReferenceTarget stores immutable accepted states. A small scripted SimpleObject exposes its cached mesh and UI. Node references and pending clearance/root-mode settings use native Max parameter blocks through the wrapper.
- Fit captures Max 2027 units, owner frame and sphere data on the host thread. The numerical core consumes copied metre-space data. A world/pose generation stays fixed for the complete fit. No host objects enter the solver.
- Every ribbon must converge and pass independent visible-triangle validation **after conversion to representable Max float coordinates**. A 0.1 mm solver guard is separate from the requested visible clearance. It covers this bounded host representation; it is not an artist clearance default or a robustness claim at arbitrary scales.
- Only a complete successor is installed. Failed fit/invalid capture retains the previous complete geometry. Native RestoreObj snapshots retain immutable before/after data for Undo/Redo; original source and roots never move or reseed.
- Browsing, redraw, selection, render reads and unrelated animation read the same accepted cache and do not run a solver. Explicit Fit samples the current frame. No automatic live update is promised.
- Save/load carries a bounded, versioned source definition and accepted poses/snapshot; cold realization may reconstruct/validate geometry but never refits. Clone owns its next accepted state independently. Scene units must match the stored document when editing; cached numeric geometry remains retained on mismatch.

## Bounds and scope

At most 21 ribbons, nine guide nodes/eighteen render vertices/sixteen triangles each; one sphere; at most 20,000 public queries per command; 400 iterations per ribbon. Rest source and candidate buffers are admitted; serialization is capped at 2 MiB. Undo retains small immutable states and declares estimated payload cost. Aggregate allocator/OS peaks and catastrophic Jolt OOM are not certified; do not describe payload limits as hard process-memory caps.

The independent static Jolt library and its factory/allocator owner are local to this DLX. Shapes die before their runtime lease. No sharing of PhysicsLab/other DLL runtime handles is introduced. Test loaded identities and standalone lifecycle; cross-plugin combinations remain separately scoped.

## Delivery gate

Build only with Max 2027 SDK/MSVC. Test native core plus owned-profile Max creation, physical mesh change, exact planted anchors, float-delivered triangle validation, same-result reset/refit, failed-fit retention, Undo/Redo, clone, save/reopen, cached-read counters and Bake. Run an actual renderer control when available and distinguish it from scripted mesh inspection.

Package the exact qualified native DLX/storage-DLH/script pair in a hash-verified Max 2027 MZP. Test installation only in an owned profile. The user installs through Scripting > Run Script and restarts their own Max; no artist installation/restart is authorized here.

Startup verifies both native hashes and the script hash, rejects any already loaded pair from a different directory, then explicitly loads any missing verified modules before defining the scripted class. This also supports custom Max profiles whose alternate plug-in INI does not discover user-directory registrations. The installer itself never loads binaries into the running session.
