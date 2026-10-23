# Review remediation validation matrix

23 October 2026. Companion to the [confirmed findings and implementation plan](REVIEW_REMEDIATION_PLAN_20261023.md). **Future acceptance requirements, not passing results.** The executed investigation is summarized separately in section 1.

Use owned disposable files/scenes/profiles and Max 2027. Protect artist profiles, existing processes, private assets, .6 gallery work and unrelated changes. Product mutation is not part of this planning task.

## 1. Evidence executed while planning

| Witness | Actual result | Limit |
| --- | --- | --- |
| Current .6 receipt/artifact checks | Source entries, EXE/ZIP hashes and Max 2027 Scatter archive/payloads verify | Does not execute the installed UI |
| Current native-source comparison | 428 Scatter implementation/header/vendor files match the review build's source manifest | Does not make that manifest complete for external dependencies |
| Density control | Native array with three moving points succeeds in optimized and ASan builds | Tiny synthetic numerical input |
| Density failure | Native image crashes with `0xC0000005`; ASan locates `final.inc:45` | No Max crash deliberately performed |
| Backup retry | Exact .6 core refuses two attempts on a simulated truncated final backup, for each product; originals preserved | Simulated interrupted disk state, not actual power-loss/process-kill qualification |
| Analyzer MZP | Current package's four relevant payloads match historical exact Max reproduction inputs | Current source/parity plus historical host result; no fresh Max run |
| Projection | Three native runs show medians 21.44/88.34/365.18 ms for 1k/4k/16k faces, 2k candidates | Numerical timings on current machine, not host latency/FPS |
| Build provenance | Five real dependency paths omitted in synthetic mutation successor; included controls detected | No live dependency or trust input edited |
| JSON ambiguity | Top-level and nested duplicate statuses accepted; ordinary failure rejected | Synthetic records do not invalidate existing receipts |
| Existing focused regressions | 20 Python cases passed: gallery identity and result protocol | No full Python/native/host rerun |

Raw records and commands are in [the owned evidence directory](../../../build/review-remediation-plan-20261023/). The initial provenance fixture used a synthetic non-existent header spelling; [probe02](../../../build/review-remediation-plan-20261023/source-manifest-probe02.json) verifies actual current source paths and is authoritative for the header claim. Earlier probe records are retained.

## 2. Protocol for future runs

Every scenario has a unique run/request/scenario ID, declared assertions, contract IDs, fixture/input hash, build configuration, source/package/loaded identities, terminal outcome and evidence paths. Reject duplicate JSON keys before inspecting status. Keep **pass, fail, blocked and not run** distinct.

Freeze the same baseline fixture for before/after comparisons. Compare full ordered candidate identities, source/receiver mappings, transforms, radii and acceptance metadata where relevant. Native allocation/work failures compare retained result/owner epochs. Host tests additionally observe display/preparation/upload counters and actual saved state.

Use bounded completion predicates. A timeout is not a pass and does not authorize replaying an unresolved mutation. Serialize requests per Max process; close only verified owned PIDs. An SDK-driven action is not a physical gesture witness.

## 3. R01 — Density and Boundary Relax

| ID | Scenario | Required outcome |
| --- | --- | --- |
| DEN-01 | Original three-point white 2×2 array/native-image case | Both succeed, movement actually occurs, ordered outputs agree; ASan clean |
| DEN-02 | Native image and array; Point/Boundary Relax off, each alone, both | No representation-dependent result; count/source/candidate identities preserved where contract requires |
| DEN-03 | Zero, one, gradient and checker images | No movement into sampled zero support; uniform control unchanged; no extra RNG admission |
| DEN-04 | UV channels, UV repeat/clamp, World XY, Local XY, rotated/scaled/nonuniform frames | Same mapping used for generation and Boundary movement; World/Local need no UV channel |
| DEN-05 | Response curve creates zero regions, inversion, offsets/rotation, seam crossings | Endpoint and existing intermediate path checks honor final sampled response |
| DEN-06 | Native dimensions/pixels malformed, nonfinite values/frame, invalid UV/barycentric input | Controlled diagnostic before publication; no indexed invalid read |
| DEN-07 | Curved receiver, density image, displacement, Bands/Analyzer membership | Moved rows remain on the supported receiver and in permitted membership |
| DEN-08 | Original Paint plus density/Relax, then protected Edit/clearance | Paint authored bytes unchanged; required eligibility/priority order retained |
| DEN-H01 | Actual image/pattern picker and Boundary control → Update in Max 2027 | Matched installed pair calculates and displays complete result; no crash |
| DEN-H02 | Manual pending mapping/amount edits; browse Recipes/source/rollouts | Rows/epoch unchanged; no unwanted solve/preparation/upload; explicit Update applies edits |
| DEN-H03 | Relevant Live mapping/image edit and unrelated selection/time/Undo | Relevant change settles once as required; unrelated action preserves publication |
| DEN-H04 | Undo/Redo and save/reopen with native image + both Relax modes | Authored settings and exact deterministic result restored; no stale native image lifetime |
| DEN-H05 | Receiver Map mode control | Existing host-aware filter remains on its intended stage and thread; no forced ImageSampler Map path |

Cheap numerical tests should cover the full representation × image mapping × wrapping × Relax-mode product. Host cases select the dangerous combinations explicitly; do not claim the subset exhausts every material map.

## 4. R04 — Receiver extraction

| ID | Scenario | Required outcome |
| --- | --- | --- |
| GEO-01 | Index equal to vertex count, far out of range and unsigned maximum | Rejected before vertex dereference with receiver/face diagnostic |
| GEO-02 | Invalid signed counts or required absent buffers in private adapter fixture | Controlled rejection without reserve overflow or pointer read |
| GEO-03 | Valid empty/degenerate meshes, ordinary converted mesh and original TriObject | Existing valid/empty semantics retained; correct cleanup ownership on success/failure |
| GEO-04 | UV valid/invalid with valid/invalid geometry | Independent checks; no UV requirement for World/Local density |
| GEO-H01 | Hidden owned malformed SDK TriObject reaches actual adapter after a valid publication | Update reports failure; previous rows/epoch/statistics/preview remain |
| GEO-H02 | Repair malformed receiver and retry; Undo/Redo; saved valid scene reopen | Successful recovery and no leaked converted mesh or stale owner |

Fixtures must reach the real SDK adapter without asking Max to render the malformed mesh. Native vector-only tests cannot replace GEO-H01.

## 5. R02/R03 — Installation preservation and recovery

Run file-transaction tests for **Scatter and Analyzer**, followed by exact Max 2027 MZP and EXE entry-point checks. EXE checks use isolated destinations; MZP checks use a redirected owned host profile.

| ID | Scenario | Required outcome |
| --- | --- | --- |
| INS-01 | Fresh and repeated install | Correct paired payload/receipt/registration; no extra backup copies on repeat |
| INS-02 | Recognized legacy bytes without receipt | Verified durable backups remain after success; old runtimes/content retained |
| INS-03 | Modified startup/macro, unknown receipt, unrelated/custom registration | Byte-identical preservation, exact actionable path, no replacement of registration |
| INS-04 | Current recognized source plus legacy truncated final backup | New verified backup namespace permits retry; old differing artifact preserved |
| INS-05 | Corrupt/different current canonical backup | Refuse overwrite; original and backup remain intact |
| INS-06 | Fail before create, during write, after flush, before/after verify and move | Never expose a partial canonical backup; retry succeeds safely |
| INS-07 | Kill verified owned child at backup and journal/publication boundaries; relaunch | Persistent recovery gives a complete old or complete new registration; no missing original backup |
| INS-08 | External edit during recovery or concurrent installer | Preserve external change or reject lock contention; no guessed ownership |
| INS-09 | Long path, linked destination, locked file, insufficient working space, malformed journal | Bounded actionable failure; no deletion of unknown data |
| INS-10 | Tampered native/script/helper/inventory, wrong host, stale helper already loaded | Reject incompatible identities; no fallback to mismatched helper/native pair |
| INS-H01 | Exact Analyzer MZP against custom wrapper in owned Max 2027 | Replaces historical destructive reproduction with preserved bytes and refusal |
| INS-H02 | Exact Analyzer MZP known migration, repeat, restart and analysis | Matched native/script load; receipt/backup verify; Analyze then Scatter Update works |
| INS-H03 | Combined EXE actual Install/Update handler | Both products use corrected core behavior and report separate completion honestly |
| INS-H04 | Exact Scatter MZP and EXE upgrade from .6 | Recipe/content registration and 96-model gallery retained; no library recopy |
| INS-H05 | Scatter-only uninstall control | Analyzer and shared content retained under the existing independent ownership contract |

Process-kill tests do not prove every power-loss/storage-failure ordering. Report the tested interruption model and filesystem. Do not count checkpoint labels as separate Max sessions.

## 6. R06/R07 — Evidence and packaging

| ID | Scenario | Required outcome |
| --- | --- | --- |
| EVD-01 | Change selected Licensing source/header/CMake/public trust input in synthetic tree | Frozen-input comparison fails; final receipt cannot become complete |
| EVD-02 | Change shared Gallery source or producer/build script | Top-level source identity changes; stale nested producer/package rejected |
| EVD-03 | Missing/added/renamed input, altered build option or selected SDK/toolchain | Explicit changed input/configuration identity; no silent omission |
| EVD-04 | Wrong artifact, gallery assembly version/host, modified shared source | Preserve all six .6 gallery admission regressions |
| EVD-05 | Installer Analyzer/Options/shared source changes after producer receipt | MZP and EXE consumers both reject the stale core |
| EVD-06 | Input changes during managed/native compile or after test before sealing | Pending/failed receipt; no acceptance of a partially frozen build |
| EVD-07 | Historical weaker receipt | Read as historical with original limits; never rewritten as current complete evidence |
| JSON-01 | Duplicate fail/pass and pass/fail status at root and nested levels | All rejected before status can be trusted |
| JSON-02 | Duplicate identity/terminal keys, identical values, escaped equivalent names | All rejected; insertion order does not change outcome |
| JSON-03 | Valid records, ordinary failure, missing/duplicate assertion IDs, stale identities, truncation/size limit | Existing correct acceptance/rejection retained |
| JSON-04 | Reparse old sealed results with original expected requests | Valid records still pass; any actual ambiguity reported rather than repaired |

## 7. R05 — Projection parity and cost

| ID | Scenario | Required outcome |
| --- | --- | --- |
| PRJ-01 | Random meshes/targets compared with exhaustive eligible-face scan | Same winning face and exact closest point under same toolchain/arithmetic |
| PRJ-02 | Equal distances, shared vertices/edges, duplicate/coplanar faces, reordered tree | First eligible face tie rule preserved; existing Relax hint policy unaffected |
| PRJ-03 | Degenerate exclusions, disconnected/curved receivers, extreme finite coordinates | Correct supported result or explicit bounded rejection; no incorrect pruning |
| PRJ-04 | Full scatter with movement, density, anchors, source weights, Bands and Edit | Same ordered IDs/transforms/source/receiver mapping/radii/acceptance as oracle baseline |
| PRJ-05 | No movement, projection disabled, small mesh | No unnecessary index allocation/build; measured small-input overhead controlled |
| PRJ-06 | 1k/4k/16k and larger measured face counts; fixed candidates and increasing candidates | Query counts and total cold/warm timings reported separately; dense gate improves at least 10× in exact triangle tests |
| PRJ-07 | Tree-build allocation fault, query/work allowance exhaustion, multiple receivers | Whole successor rejects; one shared allowance cannot be evaded per receiver |
| PRJ-H01 | Actual projected movement Update on dense receiver in Max 2027 | Parity with frozen scene, measured solve/preparation/display costs, retained output on failure |
| PRJ-H02 | Unchanged warm update/browse, changed receiver geometry/transform, relevant animation | Reuse only on matching dependencies; correct invalidation without stale index |

Record peak scratch/retained bytes and release after the call. Lower query counts alone do not prove lower total time; include index construction. No FPS claim follows from these numerical measurements.

## 8. Cross-cutting lifecycle and release gates

| ID | Scenario | Required outcome |
| --- | --- | --- |
| LIFE-01 | Fail during prepare/validate/stage/install and after observer commit | Correct preceding/successor complete publication; no mixed owner epochs |
| LIFE-02 | Owner/layer/source switch, deletion/repair, clone/merge/reset/open | Correct persistent identity and native ownership; no dangling view/callback |
| LIFE-03 | Repeated large/small counts, Undo/Redo, display switches, history release | Explainable live generations and memory release; no new retained mesh/index/image leak |
| LIFE-04 | Mesh/Point Cloud, Bake and a documented PFlow/render setup | Consistent accepted membership and output; scope limited to tested renderer/backend |
| UI-01 | Actual rollout drag, deselect/reselect, supported monitor/DPI transition | Artist arrangement survives; physical witness recorded separately from SDK reorder |
| UI-02 | Recipes opens 96 models, previews, repeat activation and close/reopen with pending Manual edits | .6 correction stays closed; no scatter solve/result change from browsing |
| REL-01 | Fresh strengthened receipt → generated source check → SDK/native suites → Python → package → matched Max 2027 | No stale intermediate promoted to final acceptance |
| REL-02 | Exact EXE/MZP archive/hash/host/development-marker guards | Delivered bytes are the tested bytes; private diagnostics excluded |
| REL-03 | Authorized website staging later | Exact EXE referenced; plugin-only ZIP/content separation preserved; built/uploaded/live states distinguished |

True device loss, all renderer/proxy combinations, physical all-control acceptance and sustained long-session reliability remain explicit broader qualification work. Do not mark them passed because a narrower row succeeds.

## 9. Completion record

For each R01–R07, record original witness, corrected source/configuration/artifact identity, exact commands, positive/negative controls, associated host/package rows, failures/limitations and the acceptance decision. Attach raw results to the current delivery handoff. Update navigation/knowledge only with those proven facts; retain historical review and .6 receipts.
