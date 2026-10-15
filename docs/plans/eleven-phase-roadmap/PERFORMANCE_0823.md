# 0.82.3 scheduling and interaction correction

14 October 2026. The user authorized fixing reported idle, navigation, panel and
parameter-edit latency, explicitly selected **0.82.3**, and requested all three
interaction classes including heavy scenes. Phase 6 remains paused. This is a
performance successor to delivered 0.82.2; schema 58, placement policy and other
product versions remain unchanged. Packaging/installation are separate actions.

## Baseline and acceptance

Base HEAD `604e3aa3fd1c84c5ef128dc564f4abaf6f4978e4`, branch
`codex/workflow-0.75`. Existing version-correction and delivery changes were
preserved in `build/live-idle-20261014-01/baseline/` before edits. Knowledge
generation `44bb57523e1286764c655754ce79ed3e4299bce12c0c71b7c49b212258dfa0d3`
reported stale sources; implementation and F04/F05/F06/F08 contracts were read
directly. No index was refreshed.

The original matched 0.82.2 pair is copied into owned Max 2027 profiles
`foundation-roadmap-idle-baseline-20261014-01` and
`foundation-roadmap-idle-heavy-baseline-20261014-01` under
`build/mcp-qualification/`. Each contains loaded module paths and hashes. The
heavy fixture copies the current artist terrace; its hash is recorded per run.
Normal Max profiles and original scenes are preserved.

Required acceptance:

- Idle after edits, navigation and UI activity stops solving, preparing,
  synchronizing and uploading unchanged content.
- A hidden/unsubmitted native helper cannot sustain a retry loop; fallback and
  explicit recovery remain usable.
- Unrelated events avoid scene-wide discovery and layer synchronization.
- Relevant settings, receiver/source changes, maps, animation and deletion still
  update in Live; pending Manual changes wait for Update.
- Compare placement position/source fingerprints and counters independently of timings.
- Measure native panel creation, open/bind/layout and navigation separately;
  do not call synchronous redraw timings presented FPS.
- Verify current-schema persistence and failure retention and repeat focused
  inherited host checks after scheduling changes.

## Reproductions and corrections

The synthetic fixture contains eight layers / 40,000 placements and 1,000
unrelated scene objects. Ordinary idle and navigation retained solve and upload
counts. Hiding a native helper before a new retained publication reproduced 24
additional scene syncs in a 5.5-second idle window. Unrelated callback dispatch
took about 19 ms per notification before the correction.

An initial selection harness redundantly called `modPanel.setCurrentObject`
after selection had already mounted the same object. Its 2.5–3.2-second figures
include two mounts and are not the cost of one artist click. A subsequent probe
separated about 1.3–1.5 seconds of native UI construction from about 91 ms of
mount binding and 0.03 ms of native rollout arrangement. Corrected paired
measurements use one mount. Original failed/probe receipts are retained.

The heavy baseline reproduced a second loop after mounting/browsing the editor:
51 cached evaluations, 51 synchronizations and 153 controller notifications
arrived during 50 observer ticks (18.4 seconds because the host was busy). No new
placement epoch was needed. All but the final layer remained dirty. A bounded
trace pins the notifications to the Scatter controller, with unchanged geometry
revisions and no source-container change.

Corrections in authoritative source and generated output:

- `procRefreshPreview` clears all evaluated layer flags after a complete successful
  refresh, including the cached-display path. A successful evaluation already
  checked its recipe, so it does not immediately repeat the full input-key read.
  Unevaluated Manual work still compares against the publication and stays pending.
- Missing native readiness uses two presentation-only redraw attempts per new
  viewport record. It cannot request another scene synchronization. CPU fallback
  stays available; explicit Refresh or a real change can establish a new record.
- External notifications and viewport synchronization use the existing registered
  controller collection. Unrelated notifications do not call `layerEntries` and
  synchronize every layer's settings. Actual controller and dependency changes
  retain their invalidation paths and scene-boundary registration.
- Opening the editor no longer rewrites an unchanged `nextEditLayerKey`.
  Composed UI pages own visibility/height; retired component layout passes do not
  briefly show controls that the composed page immediately hides again. Source,
  Amount and Area binding skip unchanged general enabled-state writes.

## Qualified candidate identity

Build `build/live-idle-20261014-01/native-02`, Max 2027 SDK, 115 frozen source
files. Saved schema 58, calculation model, native interfaces and native runtime
behavior are unchanged. Native binaries were rebuilt with the current metadata.

| File | SHA-256 |
| --- | --- |
| Generated script | `5d46848de5b72e3f692b1740d329a186c8a7717a9ffc2cd47689cad00d64be31` |
| AminScatter.dlx | `ab185b9b2989172e146b406abede272ae7f079327f7a947104c936e0298a0c4a` |
| CyrusBrush.dlx | `bee290d35272f1ed54dd75ffdae00e5b5cfbd5a95b0b4039583d8a269f63a60a` |
| CyrusBrushStorage.dlh | `477a19ed1c1fe2ef570a4f014051455fe263b328be4e9133fb9e69772528f606` |
| CyrusScatterEdit.dlm | `cc870b3822a4d7fa4e0b82b43dad917d03fbe619202df45c82e9b60935ebc947` |

Final heavy host:
`build/mcp-qualification/foundation-roadmap-idle-heavy-candidate-20261014-02`.
`launch.json` pins copied hashes and `loaded.tsv` confirms the four modules came
from that private profile. The original terrace and both baseline/candidate
copies hash `0012e46d7cff8f3ccc732ffcfb760e4d95e38f40c6f2c0ff73e3b2fd0162332a`.
This differs from older terrace receipts; current evidence uses the current
artist scene, not a substituted historical scene.

## Measured results

Point Cloud: **220 assertions passed**, including exact baseline scene and position/source
fingerprints for all **245,664 placements** across nine layers.
The test prepares 25,878 preview points with the scene's existing viewport limits.
The seven quiet windows follow idle, navigation, panels/selection, unrelated
notifications, a relevant Amount edit, an unsubmitted hidden helper and recovery.
They show zero additional epochs, cache evaluations, prepared/preview builds,
time queries, synchronizations or GPU uploads. Release/UI timers stop; every
successfully evaluated layer is clean. The real Amount handler commits exactly
one successor, then becomes quiet. Recovery restores native readiness.

| Witness | Baseline 0.82.2 | Candidate 0.82.3 |
| --- | --- | --- |
| Cached evaluations/syncs after panels, 50 observer ticks | 51 / 51 (18.4 s) | 0 / 0 (5.3 s) |
| Unrelated event dispatch, median of 100 | 25.7 ms | 8.2 ms |
| Include/exclude open plus explicit bind, median of 5 | 148.7 ms | 80.2 ms |
| Amount open plus explicit bind, median of 5 | 13.9 ms | 6.2 ms |
| Models open plus explicit bind, median of 5 | 49.5 ms | 38.0 ms |
| Scripted navigation/redraw, median of 80 | 47.2 ms | 41.7 ms |
| Object reselection/editor construction, median of 3 | 2.40 s | 2.05 s |
| Relevant heavy Amount edit, one sample | 2.90 s | 3.21 s |

Timings are observations, not a controlled system benchmark or presented FPS.
The machine was also used interactively; an earlier baseline run overlapped
compilation. No solve-speed improvement is claimed. Cold full-editor construction
still costs about two seconds, and a real large placement edit still costs
seconds. There is no evidence for claiming universally instant interaction.
The concrete regression removed here is repeated unchanged work, plus avoidable
panel updates; raw measurements include slower cases rather than selecting only
favorable results.

Physical Computer Use in the final heavy host opened Include/exclude and Amount
and zoomed the viewport. Controls displayed the expected current owner and
220,001 accepted placements after the deliberate +1 edit. Before/after receipts
`idle-physical-before.json`, `idle-physical-after.json` and
`idle-physical-navigation-after.json` show identical work and non-draw native
counters. OS/native draw counts may increase when a window is exposed or moved;
that does not mean placements were calculated or buffers uploaded. Screenshots
were inspected in the tool; no quantitative presented-frame claim is made.

## Validation and limits

- Final SDK build and all **31 native suites** passed.
- Generated reproducibility, approved layout checks and integration passed
  (**271 controls / 36 capability families**).
- **161 Python tests** passed after the final production-source change.
- Heavy Mesh passed the same **220 assertions**, including quiet idle after all
  seven interaction classes and native-preview recovery.
- **467 inherited P01-P05 host assertions passed** in
  `foundation-roadmap-p05-idle-0823-20261014-01`, including relevant/unrelated
  animation, UV/map changes, pending Manual edits, actual dependency deletion,
  failure retention/recovery, Undo/Redo, current-schema reopen/merge, owner
  switching, all page guards and 120 passive status callbacks. Consolidated
  receipt: `build/live-idle-20261014-01/inherited-evidence.json`.
- **217 synthetic-scene assertions passed** in the same owned regression host
  after its lifecycle suite: eight layers / 40,000 placements and 1,000 unrelated
  objects. All seven idle windows retain work counters. Unrelated notification
  dispatch measured 2.5 ms median, versus 19.2 ms in the earlier synthetic run.
  Freshly created receivers have different UUID-derived random salts, so equality
  between separately created synthetic scenes is not a valid acceptance check.
  The failed cross-fresh-scene comparison is preserved; the verifier now requires
  a matching saved-scene hash for cross-build comparison.
- `cyrusEditFingerprint` hashes positions and source indices, not complete
  matrices/identities. The heavy cross-build comparison is explicitly limited
  to those fields. The inherited lifecycle fixtures also compare full serialized
  rows in their named scenarios; no arbitrary-scene matrix-equality claim is made.
- Original terrace hash and the frozen final 115 build inputs were rechecked;
  they match. Only owned test processes were stopped after collecting receipts.
- Website documentation import checks and a local production build passed.
  This updates local sources/build output only; nothing was deployed.

The test harness and assertions are in `tools/performance/live_idle/`. Raw
correlated requests preserve failed fixture iterations: the first parameter
probe used an old control name; the first readiness probe attempted to replace a
read-only native primitive; the component profiler initially looked for Painting
on the Areas page. These were fixture failures, not passing product checks.
The discarded property-only panel probe did not establish delivery of a physical
rolledUp callback; final timing includes an explicit bind. Candidate 01 tested
the scheduling fix before the final UI correction and is not the final pair.

All scoped checks above passed. Cold full-controller construction remains a
measured limitation (B21); the reproduced idle loops are tracked as corrected
B25 in [the backlog](../../BACKLOG.md).

Normal installation remains **0.82.2**. Read-only inspection of normal Max 2027
process 12380 confirmed the four delivered 0.82.2 module hashes/paths (receipt
`normal-loaded-readonly.json`). Its payload files match the installation receipt.
The full Plugin.UserSettings.ini hash differs from that earlier receipt, but its
Scatter entry still selects `bin-max2027-e541650c7fd6`; its last-write time is
13:20:59. No registration repair/restore or normal-host input was performed. At
this performance-qualification checkpoint, no installer, normal-profile write,
Git push, website deployment or Max 2026 test was performed. Phase 6
remains paused. Future phase labels shift to 0.82.4 through 0.82.9. General
renderer qualification and arbitrary heavy-scene acceptance are not implied by
these scoped witnesses.

## 0.82.3 package for manual installation

14 October 2026, subsequent user-requested delivery. The user asked for the
installer to run themselves and explicitly excluded installation by the agent.
No source version bump or production-code change was needed: this packages the
exact final qualified pair from `build/live-idle-20261014-01/native-02`.

- Package: [CyrusScatter-0.82.3-Max2027.mzp](../../../dist/CyrusScatter-0.82.3-20261014/CyrusScatter-0.82.3-Max2027.mzp), **894,924 bytes**.
- Archive SHA-256: `7243e2585cd4ffd199a0062932c3827fbd5f981a1fbe616e84de10818150cd9b`.
- Selected native directory: `bin-max2027-a636f9df0a77`.
- Script and four native module hashes match the final qualified build; all
  **115 frozen build input files** were rechecked against its receipt.
- ZIP integrity, every manifest payload hash, exact file membership, Max 2027
  guard, expanded installer placeholders and MZP entry point passed verification.
  The existing packager also rejects laboratory binaries and checks team authority.
- The **8 packaging/version/authority tests passed**. No new Max execution was
  needed for this unchanged pair; archive verification does not execute the installer.
- Reproduction and receipt: `build/package-0823-20261014-01/package_verified.py`
  and `package.json`. The earlier performance receipt remains unchanged.

In **Max 2027**, save work, choose **Scripting > Run Script**, select the MZP,
then restart Max to load the complete matching pair. Use scene copies for
acceptance. Check idle after changing settings, browsing panels and navigating
the viewport, then check relevant Live edits and Manual pending/Update behavior.
The [first-five-phase checklist](ARTIST_ACCEPTANCE_0822.md) still applies; the
performance limits above remain open where stated.

No installation, host restart, Git commit/push, website deployment or Max 2026
work was performed. Phase 6 remains paused. AGENTS.md now requires a verified
runnable Max 2027 MZP with each new version delivered for user testing, with
installation left to the user unless explicitly requested.
