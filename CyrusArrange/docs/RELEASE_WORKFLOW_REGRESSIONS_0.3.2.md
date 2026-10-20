# Current workflow release checks

The final release requires all32 current-source correctness families and the
separate geometry, timing, installer and automatic-startup gates in
[the acceptance policy](RELEASE_POLICY_0.3.2.md). Partial runs below do not
qualify a package. Every failed receipt and frozen source map is retained.

## Release04 checkpoint

`build/native-032-release04` passes all21 native suites on189 inputs. Six owned
Max2027 hosts finish normally with both native-path guards, unchanged binary
hashes, private INI identity and unchanged artist profiles:

| Family | Terminal result | Interpretation |
| --- | --- | --- |
| Unified Modify |143 passed,0 failed| Complete suite passed. |
| Modifier workflow |133 passed,0 failed| Complete suite passed, including actual native hosting, retired views, GUID replacement, clone, Undo and save/reopen. |
| Migration |155 passed,1 exception| Schema3 preservation and current generation pass; library assertion hits a MAXScript argument-thunk capture error before schema4. |
| Broader workflow |15 passed,1 exception| Library assertion hits the same argument-thunk capture error. |
| Simple workflow |57 passed,2 failed| Passive full-cache equality and reopened exact-record repeat require diagnosis. |
| Bulk workflow |38 passed,1 exception| Native large seed is correct; the test lacks an explicit global declaration for its script-defined reader. |

The queue stops after the already-active sixth host finishes. It does not stop
Max or a per-host runner. Exact inputs remain in `build/release04-source-snapshot`;
the campaign and all six original receipts remain under `build/`. The remaining
26 families were not dispatched in this checkpoint.

## Reviewed fixture corrections

Build-only proposals `mxs-thunk-proposal01` and02 are hash-reviewed and adopted
after all owned hosts are terminal. Migration/workflow evaluate nine inline
comprehensions as ordinary local loops before assertion arguments, retaining the
same predicates, strict comparators, count guards and Generate-before-read
ordering. Bulk declares only `caReadExactSeed` globally. Independent large
Integer64 literals and exact seed assertions remain unchanged.

The simple fixture now records pre-settle and post-settle authored state, last
command, phases, all global cache fields and dependency tickets. Explicitly
draining prior notifications must perform zero Live updates and retain authored
state and last-command work. Mount/refresh is then checked against the complete
settled baseline; no global field is silently excluded from that comparison.
Undo can queue cache retirement, so resident-memory totals are not themselves
executed geometry work. The next actual run must establish the relevant deltas.

Reopened-repeat diagnostics retain the existing strict assertion and log saved,
native and visible draft settings, exact seed text, counts, physical checks and
row deltas around Protect, Unprotect and reopen. Protect captures the actual Max
transform; equivalent yaw encodings and host float precision are possible causes,
not an established explanation of this failed receipt. No seed or placement
defect is dismissed without the actual measured result.

## Current gate

The resulting189-input release05 build passes all21 native suites. Its fresh
serial Max campaign starts with the instrumented simple workflow, followed by
migration and the corrected broader/bulk workflows. Current Max acceptance is
pending. The release04 passes retain their own exact source identity and are not
pooled with release05 or earlier184/185/186-input checkpoints.

## Measured release05 diagnostics

The first owned normal Max exits before fixture entry and remains a failed
startup receipt. A full-heap capture is retained separately for offline analysis.
The fresh same-pair simple retry exits normally with all five identity/profile
guards:59 assertions pass and one strict captured-versus-recipe assertion fails.

Settling reports zero Live updates, unchanged authored state, last command,
phases and dependency ticket. One queued cache entry and101,784 requested live
bytes retire; deferred metadata544 bytes become0. The subsequent mounted refresh
retains the complete cache arrays, state and dependency ticket exactly. This
establishes the overdue-retirement explanation for the earlier passive assertion.

The saved, native and visible draft seed are exactly5493928879080194911; every
accepted setting is unchanged. All six IDs, positions, scales, locks and parents
repeat and physical checks pass. Only the first row's yaw differs: actual Protect
captures approximately-90.0000123703 degrees from an original270-degree Max PRS;
Unprotect retains that capture and Generate restores270. The modulo360 difference
is approximately0.0000123703 degrees. The retained report contains all raw deltas.

Release06 retains strict captured-state save/reopen equality, adds exact actual
ObjectTM preservation through Protect/Unprotect, and requires reopened Repeat to
equal the original pre-Protect seeded recipe **exactly**, with unchanged saved
settings and support. It adds no tolerance comparator and changes no production
placement logic. Its fresh189-input build passes all21 native suites. The actual
release06 simple host passes61 checks with normal exit and all five identity and
profile guards. This qualifies that fixture only.

## Release06 findings and release07 corrections

The migration fixture reaches235 passing checks before the genuine sampling
identity failure documented in [Sampling and saved region identity](REGION_SAMPLING_IDENTITY_0.3.2.md).
Bulk completes with121 passes and five physical-board failures; diagnostics for
the next run retain the original physical oracle and log actual bounds, region
IDs, accepted sampling and clearance. Neither failure is waived.

The broader workflow reaches18 passes before correctly rejecting a source rebind
whose smaller replacement cannot contain the preserved authored contact base.
The corrected fixture first requires that rejection to preserve the catalog,
revision and support data atomically. It then explicitly resets support to
automatic before rebinding, and checks the replacement's actual dimensions and
support policy. This changes the test's invalid assumption; it does not relax
the production authored-support safety contract.

All four release06 hosts are terminal before adopting release07 changes.
Release07 requires a fresh full-source build and campaign; historical receipts
remain separate and no0.3.2 package has been qualified.

## Release08 measured results and release09 fixture corrections

The189-input release08 build passes21 native suites. Four terminal owned hosts
pass with all five identity/profile guards: migration254, bulk126, native
geometry workflow29 and simple61. The sampling regression is documented with
its exact scope in [Sampling and saved region identity](REGION_SAMPLING_IDENTITY_0.3.2.md).
These470 checks are a partial campaign, not a complete release gate.

The broader workflow reaches48 passes, including the corrected support reset
and exact protected-record comparison, before selecting a deleted old output
node. Successful native publication creates successor nodes and retires prior
nodes; stable placement IDs remain authoritative. Release09 resolves the saved
protected ID to exactly one current valid output, selects that node and checks
its actual selection/protected flag before the existing Unprotect command.
No exact historical ObjectTM comparison is added across reconstruction.

The unchanged gallery separately completes48 passes and one failed kitchen
support assertion. A passive exact-scene Batch diagnostic passes9 checks and
all five guards. Frozen independent mesh verifiers confirm all seven kitchen
bases are fully covered by18 actual top triangles, with unchanged complete
source topology and pose geometry. The actual sink void is localx[206,794],
y[-194,194]; the old nominalx[200,800],y[-200,200] predicate rejects the bowl's
complete bounds over a modeled6mm rim. Its actual base and complete bounds have
zero overlap with the actual void. This is not an observed upper-overhang
collision or a solver defect.

Release09 retains the exact historical predicates as diagnostics and replaces
their support decision with bounded actual referenced bottom-band hull checks,
complete concave-notch/sink clipping and nonvacuous oracle controls. Original
material, size, rotation, height, repeat and publication assertions remain.
Separate independent release geometry proofs still supply their stated body
collision/clearance coverage. The gallery diagnostic does not prove25mm edge
margin, pair collisions, UVs or rendering.

All release08 hosts are terminal before adopting the two release09 fixture
changes. The full189-input release08 sources are preserved separately. Native09
and the new full campaign require their own terminal receipts; earlier passes
are never pooled into a new-source release claim.

The release09 full build subsequently passes all21 native suites. Its first
terminal broader workflow host passes66 checks, exits0 and passes all five
identity/profile guards. The saved-ID lookup fixes the observed deleted-node
test error while retaining protection, support reset, selective generation,
Undo/Redo, save/reopen, failure retention and Live/unrelated-edit checks. This
qualifies that exact fixture; the other31 current-source hosts remain required.


## Release09: complete attempted campaign and contact-oracle diagnostics

The frozen release09 pair passes all 21 native suites on 189 inputs. The
serial Max campaign is now terminal: 27 of the 32 required fixtures pass their
actual reports and all five module/profile guards. The other five remain
unaccepted. No 0.3.2 release is qualified by this result.

`build/release-functional09b-campaign.json` binds every selected receipt and the
separate original gallery startup failure. Its status is
`failed-completed-no-retry`. Root revalidated every passed receipt through the
existing package validator and checked all 32 terminal receipts against the
unchanged build source map. `build/release09b-terminal-review01/` records that
review and the manager/direct-host and private-session process identities.
The gallery's explicit same-pair rerun passes 57; its earlier failed attempt is
preserved, not relabeled.

| Unaccepted fixture | Actual result | Established facts and remaining work |
| --- | --- | --- |
| Geometry workflow | PENDING, startup exit 0xffffffff | Zero fixture assertions. Its normal dump records a null-execute fault with both Arrange modules present. Cause remains unresolved. A future current-source run is required. |
| Visual | 147 passed / 9 failure-counter increments | Three WSM coordinate assertions fail at each of three stages. Source/output topology, mapping, materials, smoothing, winding and explicit-normal checks pass. The fixture assumes a zero contact anchor at the complete body's center; the new source-base contract permits a different physical contact center. |
| General cache | 495 passed / 12 failure-counter increments | Six observer-role cases abort at an old three-per-board category ceiling; each prerequisite failure is also counted by its exception handler. Actual enabled/disabled results agree: seven props on the main board, nine with the extra board. Their later observer phases did not run. |
| Cache atomicity | 25 passed / 24 failure-counter increments | All twelve callback cases stop at one combined baseline prerequisite, counted twice. Actual publication-completed flags are true; its row-count/dirty operands need separate observation. No callback atomicity pass is inferred. |
| Real models | 421 passed / 11 failures | Eight Coffee vertex comparisons use the complete body center. Three Side diagonal-edge checks use complete body bounds. The final exported scene cannot establish the overwritten failing diagonal pose's base clearance. |

The passing fixtures include the actual Modify/creation/bulk/migration workflows,
region/obstacle/lifecycle/preview/library tests, all 1,182 cache-boundary checks,
status/Undo, base support, fit feedback, paths, shelves/stairs, compound collision,
curved-road, complete-device/imported-table, packing recovery and raw-legacy
minimum workflows. These retain their separate producer exports. Their host
passes do not replace the seven required independent proof families, isolated
performance, exact installer or portable-example gates.

### Actual WSM saved-scene closure

The package-ineligible passive diagnostic at
`build/host-032-release09-wsm-anchor-readback01` passes 21 checks, exits zero and
passes all five ownership/module/profile guards. It opens a byte-identical copy
of the failed scene, independently clips the eight literal-verified source
triangles at the lowest 0.5 mm band, and reads every actual saved output corner.
It performs no generation, scene saving or source mutation.

The independently derived canonical contact offset is approximately
(32.3213, 22.5, 0) mm. The old full-body-center prediction misses the saved output
corners by about 39.38 mm. Both saved outputs match the physical-base prediction
within 0.000183105 mm, below the original 0.003 mm tolerance; complete bounds and
sizes agree. Native public state, references, output handles, dependency ticket
and the original failed scene bytes stay unchanged. This establishes the
coordinate-oracle error for the saved +60 mm WSM state, not a new release pass or
an independently observed snapshot of its earlier two stages. The proposed
fixture retains all appearance checks and uses an independent base center.

### Actual real-model exported-geometry closure and unresolved corner

`build/real-world-anchor-audit09/` binds the original failed report, scene and
29 MB geometry CSV. An independent source-triangle band calculation shows that
all 47,532 saved actual output vertices agree with the contact-center prediction
within 0.000252 mm. Relative shape errors are at most 0.000253 mm, below the
unchanged 0.03 mm threshold. The plant and two books have nonzero contact-center
offsets; the vase assembly does not. Final saved output bases pass complete
support and the existing Euclidean edge allowance against the exported actual
top triangles.

Those final outputs use the later artist seed. They do not prove the original
Side seed 412004 diagonal pose, which was replaced before the final CSV. A
build-only copy preserves every original check and adds phase exports directly
after that Generate/Repeat. Its future observations must resolve that separate
support question before changing the support oracle. No tolerance increase or
production collision bypass is proposed.

The next corrected source freeze must receive its own complete current-build
regression and delivery evidence. This failed campaign and its supplemental
diagnostics remain historical evidence with their original identities.


### Later observed closures and full candidate fixture smokes

These later runs are explicitly supplemental and package-ineligible; they do
not repair the failed campaign or qualify the future adopted source map.

- The unchanged atomic baseline was measured in both cache modes at
  `build/host-032-release09-atomic-original-baseline01`: four accepted outputs,
  zero row groups, dirty zero, and completed/published true. Thus its failing
  prerequisite was the missing row, not an observed dirty publication or cache
  disagreement. The diagnostic completes two observations with zero unexpected
  errors; its wrapper deliberately keeps a failed functional status.
- A full candidate cache smoke at
  `build/host-032-release09-cache-observer-smoke01` passes 685 checks, including
  every formerly aborted observer role and its terminal assertion. The helper
  uses independently measured box geometry and the authored Fill calculation
  instead of the retired category cap. Physical and state checks remain intact.
- The v2 explicit-six-copy atomic fixture at
  `build/host-032-release09-atomic-proposed-smoke02` passes 257 checks across all
  twelve strict callback cases. Its actual baseline is six copies and one
  three-book group; three ordinary copies remain. The earlier proposed demand
  for two groups was removed before testing because quantity does not promise
  a particular number of row groups. The original nonempty-row and every
  publication/dirty/epoch/handle/recovery assertion remain.
- A supplemental unchanged-oracle real-model run captures the seed 412004
  Generate/Repeat geometry before replacement at
  `build/host-032-release09-real-world-corner-capture01`. It still fails the old
  checks (419 passed / 13 failures; two extra random foliage-bounds failures).
  All guards and source preservation pass. The actual captured corner has the
  original logged placement ID and reproduces its full-bounds deficit of about
  0.770768 mm². Independent source/output triangle analysis measures a fully
  covered 37,609.178109 mm² contact hull and 36.351850 mm true edge clearance.
  Generate and Repeat meshes and all logical pose fields are exact. This is an
  observed recreation with the original identity and bounds witness; the
  overwritten original process's meshes cannot be compared byte for byte.
- The corrected full real-model fixture at
  `build/host-032-release09-real-world-corrected-smoke01` passes all 432 checks.
  It caches independent original source contact centers, measures each actual
  output's referenced bottom-band hull, and keeps the original support, edge,
  full-shape, material, UV, complete-body collision, file and history checks.
  Full-body bounds coverage remains a per-placement diagnostic. No original
  tolerance is widened.

Every successful smoke exits zero and passes both loaded-module paths, native
binary hashes, private INI and artist-profile guards. The four proposed fixture
changes and original preimages are bound by
`build/release10-fixture-plan01.json`; at preparation they are not adopted.
Their native runtime is the unchanged release09 pair. The proposed visual
fixture itself has only static review and the separate 21-check saved-state
closure; it still requires its complete new-build host run.


## Exact fixture adoption for the release10 freeze

The four reviewed proposals were adopted after the last owned diagnostic host
exited. [The adoption receipt](../build/release10-fixture-adoption01/receipt.json)
binds each old and proposed hash, the preserved native09 receipt, actual
supplemental host receipts and all five identity/profile guards. Exactly four
of189 maintained inputs changed: visual, cache-role, atomic-cache and real-world
fixtures. No production C++ or artist controls changed at this adoption.

The cache-role, atomic and real-world proposed fixtures had complete supplemental
runtime passes. The visual correction had passive saved-scene numerical evidence;
its full corrected fixture still requires the fresh release10 host. These
supplementals are diagnostic evidence, not accepted release10 producers.

The build-only serial campaign driver also had its stale09 record/stop paths
corrected before execution, preserving the previous campaign. Fresh native10,
all32 current-source hosts, independent proofs, controlled performance and
installer acceptance remain required. All source inputs stay frozen during
the build and owned Max runs.


## Release10 profile-guard observations during the full campaign

The fresh lifecycle fixture reported89 passes and library validation6 passes,
both with normal process exit and matching modules, hashes and private INI.
Their artist-profile preservation guard failed, so neither run is accepted.
[The bounded read-only audit](../build/lifecycle-profile-guard10-audit01/REPORT.md)
and [sealed receipt](../build/lifecycle-profile-guard10-audit01/receipt.json)
record the exact artist `3dsMax.ini` changes: `[Performance] UnitType`3 to4
during lifecycle, then the Material Browser dialog position from
`714 185 492 661` to `600 180 492 661` during library validation. The first
old hash was exactly reconstructed in a labelled build-only copy; the second
delta compares authenticated endpoint copies. Recorded write timestamps lie
inside the corresponding test intervals. UserSettings endpoint hashes match.

The writer is unknown. No artist profile was restored or changed by this audit,
and these observations do not excuse or bypass the failed guard. Subsequent
preview and cache-boundary runs passed their own preservation guards. Only
explicit fresh same-source/pair retries after the full queue can supply accepted
replacement evidence for lifecycle and library validation. Original failed
receipts remain unchanged; any retry qualifies its own observed interval only.
