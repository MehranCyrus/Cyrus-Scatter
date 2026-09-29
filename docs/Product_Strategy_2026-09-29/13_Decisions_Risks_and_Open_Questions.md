# 13 — Decisions, risks and open questions

## Decision register

"Required" records an explicit user constraint. "Recommended" is this review's judgment. A documented proposal is not an implemented feature or a business commitment.

| ID | Decision | Status | Revisit when |
|---|---|---|---|
| D01 | No Git or subagents for this work | Required; honored | User changes the instruction |
| D02 | Support Max 2024 through current 2027; 32 GB minimum target | Required; qualification incomplete | New host release or explicit product-scope change |
| D03 | CPU operation remains usable without optional compute | Recommended continuity contract | No planned removal |
| D04 | Preserve existing scene IDs, edit records and legacy algorithms | Recommended release contract | Explicit versioned migration with fixtures |
| D05 | Focus initial product on precise environment/site layout | Recommended product hypothesis | Pilot tasks reveal stronger repeatable demand |
| D06 | Measure on the working 2027.1 baseline first | Recommended implementation order | Another qualified host better matches pilot needs |
| D07 | Stage profiling before choosing CPU/thread/GPU changes | Recommended; consistent with performance plan | Actual baseline identifies urgent bottleneck |
| D08 | Keep PFlow while testing alternatives | Recommended | A qualified adapter wins on full operation and lifecycle |
| D09 | Investigate 2027.2 Point Instance behind an optional adapter | Recommended experiment | Matching SDK/runtime/API or renderer support unavailable |
| D10 | Keep current generated UI; improve it incrementally | Recommended | Measured UX needs justify a broader rewrite |
| D11 | License policy before vendor/enforcement; no provider selected | Recommended | Contract tests and commercial decision completed |
| D12 | No public paid release with unresolved critical scene/render defects | Recommended release rule | No planned exception |
| D13 | This package governs priorities/status; existing packages retain detailed specs | Recommended documentation rule | A later dated decision explicitly supersedes it |

## Risk register

Owner labels are roles, not assigned people. In a small team one person may fill several roles; every implementation task still needs an accountable owner.

| Risk | Severity | Evidence / uncertainty | Mitigation and owner |
|---|---|---|---|
| Wrong edit attachment after base/layer change | Critical consequence | Conditional row/signature identity in source; full scenarios untested | BT-05/ID-01 fixtures; engine owner |
| Cleanup deletes an unrelated newly created node | Critical consequence | Scene-difference ownership observed; failure not reproduced | Sentinel/fault tests and explicit ownership; render owner |
| Density/projection bypass in basic/legacy state | High | Fast-path predicate omits relevant conditions | Reproduce C-01 and isolate correction; controller owner |
| Failed rebuild erases useful display or mixes Analyzer generations | High | Nontransactional publication visible in source | Freshness/atomic publication tests; controller owner |
| Oversized/corrupt edit state exhausts resources | High | Per-field limits do not establish aggregate bounds | Host load fixtures and bounded transaction; persistence owner |
| Optimization changes seed layout or fingerprints | Critical consequence | Ordered RNG/ties/FP arithmetic feed saved identity | Golden outputs and reference path; engine owner |
| Renderer mismatch, double scale, material/proxy loss | High | No current image qualification | Exact transform plus image matrix; render owner |
| Older-host binary/runtime incompatibility | High | Only 2027.1 smoke evidence | Matched SDK/toolchain and runtime matrix; release owner |
| 2027.2 feature has no suitable public adapter API | Medium/high | Overview available; detailed API not established | Bounded discovery spike, retain baseline; integration owner |
| UI/runtime changes break timers or callbacks | High | .NET/Qt foundation changes across hosts | Repeated lifecycle and DPI tests; UI owner |
| Memory fits developer PC but fails 32 GB | High | Current machine exceeds requested floor | Real floor-hardware envelope; QA owner |
| GPU competes with viewport/renderer or resets driver | High | No prototype/driver qualification | Optional bounded path, standalone tests and stop rule; performance owner |
| Licensing prevents historical work from rendering | High | Enforcement not implemented; policy ambiguity | Capability table and outage/worker tests; licensing owner |
| Perpetual/offline promise cannot be honored | High | Conflicting proposed policies | Continuity decision before sale; product owner |
| Duplicate old MZP/new bundle/native runtime | High | Multiple install mechanisms and shared-DLL proposal | Clean-profile migration/rollback; release owner |
| Feature breadth exceeds support capacity | High business risk | Broad audience and many proposed integrations | Focused workflows, explicit support matrix; product owner |
| Documentation drifts from delivered binaries | Medium/high | Historical stale claims already present | Evidence ledger and versioned release records; documentation owner |

Severity describes potential impact, not proof that a failure has occurred.

## Open inputs and working defaults

| Question | Working default while unanswered | Required before |
|---|---|---|
| Which exact renderers and builds matter? | Generic smoke plus Corona-first integration research, V-Ray next | Advertising renderer support / paid beta scope |
| Which production scenes are representative? | Built-in synthetic W1–W3 fixtures | Credible workload/performance claims |
| Can 2024/25/26 runtime and SDK tests be arranged? | Prepare source/fixtures, mark those rows pending | Claiming the full required host range |
| Where is the real 32 GB test machine? | Measure current machine but do not infer floor support | Publishing the minimum workload envelope |
| First customer segment and target workflow? | Archviz/site-layout artists | Public positioning and pricing |
| License activation/offline/perpetual terms? | No production enforcement, provider-neutral design | Provider selection and sale |
| Is new layer reorder needed immediately? | Retain current ceiling/order semantics | Identity migration scope |
| Do customers need animation and deformation? | Static-layout first, explicitly limited animation claims | Temporal attachment/motion-blur milestone |
| Are source and sample assets redistributable? | Original simple assets only | Shipping libraries/demos or public source |
| How much ongoing support can be sustained? | Small controlled cohort, no enterprise SLA | Expanding support scope |

These gaps do not prevent the next diagnostics/fixture milestone. Obtain answers when they become decision dependencies rather than interrupting every reversible engineering step.

## Experiment decision record

For each experiment record: question, owner, baseline/candidate hashes, intended workload, expected mechanism, required semantics, exact environments, raw evidence, result, cost/risks, accepted/deferred/rejected decision and reopening condition. Preserve failed experiments; they prevent repeating attractive but ineffective approaches.

## Stop conditions

Stop and recover the baseline if there is scene corruption, unintended deletion, wrong-instance editing, persistent stale publication, or a reproducible host crash. Stop expanding a backend if transfer/maintenance costs erase the gain. Stop adding features to a workflow that pilot users cannot yet complete reliably.
