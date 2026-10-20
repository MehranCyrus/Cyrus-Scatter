# Cyrus Arrange 0.3.2 release acceptance

The packager owns acceptance evidence and immutable archive construction. It does
not build, launch Max, install into an artist profile, or change a scene. A
candidate is a reviewable artifact, not a qualified delivery. Qualification applies
only after the exact same MZP passes the isolated installer and installed-startup
phases.

## Ownership and failure contract

The full source map and the two native module hashes belong to the full SDK build
receipt. Every host producer must match that original complete source map and
native pair; current source changes invalidate acceptance. Explicit deployment-only
reuse retains its named eight-file partition and cannot excuse a functional input
change. Added or removed source paths always require a new full build.

The package policy owns an explicit required-suite list, the mounted-UI host-mode
list, and the input/dependency lists for each independent verifier. The candidate
copies exact producer inputs into a fresh ignored build directory, verifies every
copy, runs the qualified verifier, and records source/copy, producer receipt,
verifier/dependency and result hashes. It never adopts an old copied pass flag.
Validation rechecks those identities and recomputes the proofs from the saved
inputs. Failed verification leaves the existing candidate, released archives,
producer receipts and artist files unchanged. A failed fresh evidence directory is
kept for diagnosis. No source-sized meshes are retained in plugin state by this
offline policy; temporary proof copies are disk evidence, not runtime caches.

Installer tests own their private profile changes and rollback assertions. The
packager requires the same candidate hash, exact phase-test hashes, installed
module hashes, private profile/INI identity and untouched artist-profile evidence.
Finalization writes a new qualification receipt once; it does not rebuild the MZP.
There is no scene Undo operation because packaging never mutates Max state.

## Required acceptance

Keep all twenty existing functional suite families, including their current UI
ports, and add the twelve geometry-first workflow suites. Separate backend cache
timing from the correctness list. Require two fresh opposite-order processes with
matching native/source identities and an explicit, hashed no-overlapping-QA
attestation. That operational attestation is not an independently measured idle
machine claim. Raw geometry, cache work, phases and retained/process memory remain
independently checked; no speedup threshold is fabricated.

The policy identity is `geometry-first-032-exact-proofs-v1`. Historical development
receipts and packages are not final qualification of this policy/source map.

All required names are under `tests/max/` and end in `_tests.ms`:

| Preserved coverage | Current geometry-first coverage |
| --- | --- |
| `inspect`, `arrange_native`, `arrange_workflow`, `arrange_lifecycle` | `arrange_unified_modify`, `arrange_status_undo` |
| `arrange_preview`, `arrange_regions`, `arrange_obstacles`, `arrange_visual` | `arrange_geometry_workflow`, `arrange_base_support` |
| `arrange_library_validation`, `arrange_cache`, `arrange_cache_atomic`, `arrange_cache_boundaries` | `arrange_fit_feedback`, `arrange_path_workflow` |
| `arrange_gallery`, `arrange_composition`, `arrange_composition_lifecycle`, `arrange_migration` | `arrange_shelves_stairs`, `arrange_compound_collision` |
| `arrange_simple_workflow`, `arrange_bulk_workflow`, `arrange_modifier_workflow`, `arrange_real_world` | `arrange_road_scene`, `arrange_device_imported`, `arrange_packing_recovery`, `arrange_legacy_minimum_workflow` |

Eleven mounted-UI families require `owned-interactive-command-panel`: workflow,
simple workflow, bulk workflow, modifier workflow, unified Modify, status/Undo,
fit feedback, road, imported device, packing recovery and legacy minimum workflow.
The remaining twenty-one correctness families and both performance producers use
`owned-batch`. The offline policy test requires this list to equal the launcher
list. Handler tests establish actual mounted controls and native ownership; they
do not establish mouse-gesture or screenshot usability under the no-computer-use
constraint.

Each host receipt must still have its exact terminal result, loaded-identity log,
private module files, all five identity/profile guards, original complete source
map and test hash. The loaded log must identify both private native paths and the
private INI. Copying a success receipt from another source build is rejected.

## Independent geometry evidence

Candidate construction runs these current verifiers on fresh exact input copies:

| Family | Verifier | Actual cases | Invalid controls |
| --- | --- | ---: | ---: |
| Inspector exports | `verify_exports.py` | 5 JSON exports | known hole/divider/dimension assertions inside verifier |
| Actual bases | `verify_base_support.py` | 6 | 5 |
| Shelves/stairs | `verify_shelves_stairs.py` | 2 | 4 |
| Compound bodies | `verify_compound_colliders.py` | 3 | 4 |
| Complete cars/road | `verify_road_scene.py` | 6 | 5 |
| Device/imported receivers | `verify_device_imported.py` | 6 | 7 |
| Packing recovery | `verify_packing_recovery.py` | 5 | 5 |

The six mesh families total twenty-eight cases and thirty deliberately invalid
controls. Case counts are a manifest completeness check; the actual geometry
calculations and rejection reasons belong to the independent verifiers. Every
mesh file and every settings file read by those verifiers is retained and hashed,
including settings omitted from older standalone proof JSON hash lists. Each
transitive local verifier import is bound to the original frozen source map.

Proofs live in a fresh `build/package-032-proofs-*` directory. The embedded manifest
and external `package-receipt.json` hold `independent_proofs`, exact producer
receipt hashes, original/copy input paths and hashes, verifier dependencies, and
result hashes. Candidate validation creates a separate
`build/package-032-recheck-*` directory, recomputes all seven proofs, and requires
the same result data. A rehashed, fabricated pass JSON does not pass recomputation.
Keep those owned evidence directories and producer outputs with the release.

## Backend performance evidence

The two separate producers are `arrange_cache_performance_tests.ms` and
`arrange_cache_performance_reverse_tests.ms`. Their two current receipts are
supplied with `--performance-run`, independently of the thirty-two correctness
suites. Normal/reverse raw schedules must match their receipt PIDs and run in
distinct owned processes. Both runs' raw CSVs, environment and terminal reports
are copied and hashed; `verify_cache_performance.py` recomputes physical poses,
cache work, phase data, memory fields and paired summaries.

Supply `--performance-isolation` with an explicit JSON driver/operator record:

```json
{
  "no_overlapping_qa_workload": true,
  "scope": "Native ordinary and explicitly requested legacy book-row backend commands; no Modify gesture, FPS, rendering, general-scene or machine-idleness claim.",
  "runs": [
    {"receipt": "ABSOLUTE_NORMAL_RUN/receipt.json", "sha256": "EXACT_RECEIPT_SHA256"},
    {"receipt": "ABSOLUTE_REVERSE_RUN/receipt.json", "sha256": "EXACT_RECEIPT_SHA256"}
  ]
}
```

Paths must use the same resolved platform spelling as the run folders. The record
must be written only when its claim is accurate. It explicitly records an
operational observation, not measured CPU exclusivity or machine idleness. The
earlier development performance03 pair overlapped an offline audit and cannot be
promoted to this isolation claim. Performance03 remains useful scoped development
evidence. Timings do not determine cache hits or imply a minimum speedup.

## Commands and output

From the CyrusArrange directory, after a frozen full SDK build and all fresh host
producers, repeat `--host-run` once for every name in `tools/package.py`'s
`REQUIRED_TESTS`:

```powershell
python tools/package.py candidate --binary-dir build/FINAL_NATIVE --host-run build/FINAL_INSPECT --host-run build/FINAL_NATIVE_HOST --host-run OTHER_REQUIRED_RUNS --performance-run build/FINAL_PERF_NORMAL --performance-run build/FINAL_PERF_REVERSE --performance-isolation build/FINAL_PERF_ISOLATION.json --output dist/FRESH_CANDIDATE
python tools/run_installer_tests.py --candidate dist/FRESH_CANDIDATE --output build/FRESH_PRIVATE_INSTALL
python tools/package.py finalize --candidate dist/FRESH_CANDIDATE --installer-run build/FRESH_PRIVATE_INSTALL
```

The placeholder host list above is abbreviated; supply all thirty-two actual
folders. Candidate creation produces `CyrusArrange-0.3.2-Max2027.mzp` and
`package-receipt.json`; the exact tested MZP is preserved by finalization, which
adds only `qualification-receipt.json`. A candidate remains unqualified until
that last step passes. No installed artist profile is changed by this workflow.

`--reuse-functional-runtime` remains an explicit existing exception for only the
eight named deployment files. It is not the default final freeze and cannot
permit any added/removed input, runtime, test, verifier or UI change.

## Offline policy verification

`python -m unittest discover -s tests/python -p test_package_qualification.py -v`
passed thirty-one offline tests. They cover required/mounted-host manifests,
source/runtime/deployment boundaries, missing/duplicate evidence, actual payload
and terminal/log identities, settings and transitive-verifier tampering, producer
hashes, invalid controls, proof recomputation, performance isolation/PID/schedule,
immutable archive round-trip, exact installer candidate binding, installed Modify
host requirements and one-time finalization. Synthetic verifier transport and
temporary payloads are explicitly labeled and are never claimed as Max, geometry,
timing, installer execution or release qualification.
