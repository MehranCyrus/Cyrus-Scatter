# 15 — Phased implementation roadmap and backlog

**Status: PROPOSED implementation work. This research package completes documentation, not the coding backlog.**

## Order and scope

The governing [Product Strategy](../Product_Strategy_2026-09-29/11_Master_Roadmap_and_Backlog.md) and [Baseline and Trust milestone](../Product_Strategy_2026-09-29/12_First_Implementation_Milestone.md) retain priority. AI work is a separate gated track. Relevant reliability fixes are prerequisites; unrelated licensing or GPU work should not be mixed into the first AI comparison build.

| Phase | Outcome | Exit gate |
| --- | --- | --- |
| 0 | Contracts, owned fixtures and evaluation plan | Scope/data policy defined; manual baseline ready |
| 1 | Provider-neutral automation API | G0 and direct API parity/recovery |
| 2 | Five-tool MCP MVP | Typed client runs E-01/E-02 within policy |
| 3 | General-model design assistant | E-03 valid plans and basic task value |
| 4 | Reference/visual feedback | E-04/E-05 artist-value gate |
| 5 | Optional governed correction collection | Meaningful labels, consent and lineage |
| 6 | Retrieval and reusable examples | E-06 beats simpler defaults |
| 7 | Optional specialized ML experiments | Readiness checklist and task-specific G3 |
| 8 | AI product beta | Qualified support/privacy/recovery and repeated artist value |

Phases 5–7 can be omitted if a useful beta needs no learning. Local manual pilot records begin in Phase 0; Phase 5 refers to productized automatic collection, not the first evidence gathering.

## Backlog conventions

Each table belongs to its stated phase. **Required** means required to advance that phase/feature, not mandatory to ship the core plugin. Optional experiments never become hidden launch dependencies. Owners are role types, not assigned people. Acceptance criteria are future checks, not completed results.

### Phase 0 — research, contracts and baseline

| ID / required? | Goal and expected artifact | Dependency / owner type | Acceptance criteria | Principal risk |
| --- | --- | --- | --- | --- |
| AI-00 — Required | Review and freeze v0.1 scope, exclusions and decision record from this package | Governing strategy; product lead + Max architect | MVP fields, first five tools, budgets and stop conditions agreed; unresolved items named | Expanding scope before value |
| EVAL-01 — Required | Create three owned reproducible scene builders plus a 20–50-brief pilot inventory and manual timing rubric | AI-00; technical artist + QA | Rights recorded; units/seeds/assets fixed; manual acceptance and correction time captured | Biased easy examples |
| DATA-00 — Required | Define manual local records, rights, consent and retention manifest | AI-00; product/privacy owner | No automatic collection; all pilot artifacts have purpose and rights status | Accidental client-IP reuse |
| SEC-00 — Required | Define local scope, upload categories and threat fixtures | AI-00; security engineer + studio representative | Unauthorized objects/paths/uploads are explicit rejection cases | “Local” mistaken for trusted |
| API-00 — Required | Reproduce automation-path source risks; preserve build/schema identity | Baseline and Trust; Max/native engineer + QA | Read side effects, preview failure and source/layer consistency characterized; blockers fixed/tested before adapter release | Existing defects amplified by automation |

### Phase 1 — internal automation API

| ID / required? | Goal and expected artifact | Dependency / owner type | Acceptance criteria | Principal risk |
| --- | --- | --- | --- | --- |
| API-01 — Required | Pure bounded scene/context snapshot API | API-00, SEC-00; Max engineer | E-02: no parameter/selection/undo/preview changes; approved IDs and accurate units only | Hidden refresh/evaluation effects |
| API-02 — Required | Session identity, ownership, generation and revision registry | API-01; Max architect | Reset/reopen invalidates IDs; external edits/undo detected; ambiguous owners rejected | Handle/index reuse |
| API-03 — Required | Strict plan parser, capability registry and semantic validator | AI-00, API-02; API/native engineer | Unknown fields/IDs, bad ranges, NaN, cycles, unsupported modes and infeasible constraints rejected | Syntactic JSON accepted as safe |
| API-04 — Required | Owned create/configure transaction with source/layer lifecycle helpers | API-03; Max engineer | Correct parallel arrays; one undo unit; no unowned object mutation; direct-output parity | Partial state and callback effects |
| API-05 — Required | Operation ledger, truthful status, idempotency and local cancel/reject/undo | API-04; systems engineer + QA | Disconnect/retry and each injected failure have known outcome; duplicate apply suppressed | Replay after unknown commit |
| API-06 — Required | Convex region inset compilation, owned mask persistence, final footprint checks, unit/matrix fixtures and coherent publication | API-03, API-04; geometry engineer + QA | Eligible-centre masks persist through regeneration; infeasible geometry rejected; derived shapes undo/clean up; final constraints pass | Pivot-only masks and incomplete ownership |
| API-07 — Required | Supported main-thread dispatch and host lifecycle qualification | API-01; Max SDK engineer | No worker Max calls; modal/render/load/reset/shutdown cases exercised; queue bounded | Deadlock or off-thread SDK access |

### Phase 2 — MCP MVP

| ID / required? | Goal and expected artifact | Dependency / owner type | Acceptance criteria | Principal risk |
| --- | --- | --- | --- | --- |
| MCP-01 — Required | Five-tool adapter with pinned protocol/client/SDK matrix | API-05, API-06, API-07; integration engineer | Strict inputs/outputs; E-01/E-02; actual protocol compatibility recorded | Assuming every client supports latest |
| SEC-01 — Required | Authenticated local IPC, scope/approval checks and injection suite | SEC-00, MCP-01; security engineer | Out-of-scope IDs, metadata instructions, eval/path payloads and replay attempts cannot mutate/export | Tool boundary bypass |
| MCP-02 — Required | Revision-bound viewport capture and bounded artifact store | API-05, API-07; Max/graphics engineer | Explicit viewport/camera/color state; stale capture rejected; no desktop/arbitrary file capture | Wrong or stale view |
| UX-01 — Required | Local scope/review/progress/cancel/reject/undo panel | API-05, SEC-01; UX + Max UI engineer | Artist can operate and recover without model cooperation; permissions visible | Unclear authority or recovery |

### Phase 3 — general-model planning

| ID / required? | Goal and expected artifact | Dependency / owner type | Acceptance criteria | Principal risk |
| --- | --- | --- | --- | --- |
| AGENT-01 — Required | Provider-neutral reasoning adapter and versioned prompt/plan fixtures | MCP-01, UX-01, DATA-00; AI integration engineer | Exact model identity recorded; refusal/incomplete output handled; no vendor lock in domain API | Provider/model drift |
| AGENT-02 — Required | Bounded plan/validate/apply state machine | AGENT-01, SEC-01; systems engineer | Call/count/cost limits enforced; approvals bound; stale plans stop; E-03 G1 | Runaway calls or authority expansion |
| EVAL-02 — Required | Manual-versus-agent task report | AGENT-02, EVAL-01; QA + technical artists | All 20 brief outcomes including failures retained; time includes review/corrections | Measuring only first-image speed |

### Phase 4 — reference and visual feedback

| ID / required? | Goal and expected artifact | Dependency / owner type | Acceptance criteria | Principal risk |
| --- | --- | --- | --- | --- |
| AGENT-03 — Required | Reference interpretation with confirmed world regions and source cards | AGENT-02, MCP-02; AI engineer + technical artist | No guessed metric mapping; assumptions/camera/asset mismatch visible | Reference misinterpretation |
| AGENT-04 — Required | One-refinement loop and candidate comparison UI | AGENT-03, UX-01; systems + UX engineer | Same seed/view where appropriate; manual edits pause loop; budgets/stop rules pass | Oscillation or overwritten edits |
| EVAL-03 — Required | E-04/E-05 paired held-out campaign and go/narrow/stop decision | AGENT-04; QA + product lead | G2 assessed with uncertainty, quality and hard validity; no selective successes | Attractive demo without useful workflow |
| API-08 — Optional | Qualified density, edge/falloff/Analyzer and partial-region features | EVAL-03 + relevant engine tests; Max/geometry engineer | Add only features demanded by observed failures; typed units and final validity tests | Feature expansion hides baseline failure |

### Phase 5 — governed feedback capture

| ID / required? | Goal and expected artifact | Dependency / owner type | Acceptance criteria | Principal risk |
| --- | --- | --- | --- | --- |
| DATA-01 — Required for collection | Opt-in local versioned session/correction export | DATA-00, EVAL-03; data/product engineer | Purpose/retention/deletion controls; no silent upload; exact build lineage | Telemetry disguised as diagnostics |
| API-09 — Required for point labels | Stable edit query/event identity and correspondence contract | API-02, edit-stack qualification; Max engineer | Move/clone/delete/source replacement/undo/reopen mappings tested; ambiguous mapping declared | Row-index labels attached to wrong point |
| DATA-02 — Required for learning | Curated label/split manifest and ambiguity review | DATA-01; data scientist + artists | Projects/studios grouped; explicit versus weak labels separated; rights checked | Correlated or biased labels |
| SEC-02 — Required for sharing | Studio isolation and deletion/derived-artifact policy | DATA-01; security/privacy owner | No unauthorized retrieval/training reuse; revocation effects documented | Cross-project/studio leakage |

### Phase 6 — retrieval and examples

| ID / required? | Goal and expected artifact | Dependency / owner type | Acceptance criteria | Principal risk |
| --- | --- | --- | --- | --- |
| RET-01 — Required for retrieval | Versioned recipe library with roles/constraints/compatibility | DATA-00, EVAL-03; technical artist + tools engineer | Compatible recipes adapt to current IDs/units; held-out projects excluded | Stale asset/parameter assumptions |
| RET-02 — Optional | Frozen embedding retrieval behind metadata filters | RET-01, rights review; ML engineer | E-06 beats tag/rule baseline enough to justify runtime | Visual similarity without design relevance |
| EVAL-04 — Required for retrieval release | E-06 paired downstream value report | RET-01; QA + product lead | Improvement in accepted-layout time, not only search relevance | Library maintenance exceeds benefit |

### Phase 7 — specialized ML, only if justified

| ID / required? | Goal and expected artifact | Dependency / owner type | Acceptance criteria | Principal risk |
| --- | --- | --- | --- | --- |
| ML-00 — Required before any custom ML | Completed readiness checklist and chosen narrow target | DATA-02, baseline failure; ML lead + product lead | Every item in [10](10_ML_Options_and_Experiments.md) answered; minimum gain fixed before training | Training without a product problem |
| ML-01 — Optional | Segmentation/depth zoning experiment E-07 | Rights/checkpoint review, calibrated mapping where needed; vision engineer | Lower tracing/correction time, class metrics and resource/license report | Wrong masks or false metric depth |
| ML-02 — Optional | Small parameter or studio-preference experiment E-09 | ML-00, SEC-02; ML engineer | Beats saved settings/retrieval on held-out projects and artist workload | Learning changed briefs or bugs |
| ML-03 — Optional | Candidate API and constrained ranker experiment E-08 | ML-00, API-09, candidate contract; geometry + ML engineer | Frozen baseline/candidates; G3 final-layout benefit; hard validity preserved | Unary scores fail global composition |
| ML-04 — Optional | Local/runtime experiment E-10 and optional model packaging | Chosen lawful checkpoint/runtime; inference engineer | Offline/no-egress test, resource traces, dependency isolation and rollback | VRAM/driver/support burden |

### Phase 8 — AI product beta

| ID / required? | Goal and expected artifact | Dependency / owner type | Acceptance criteria | Principal risk |
| --- | --- | --- | --- | --- |
| BETA-01 — Required | Declared host/asset/privacy support matrix and installation/recovery guide | EVAL-03, core release qualification; release + QA engineer | Named builds tested; 2024/2025/2026 claims only after ports/tests; no hidden model download | Overstated compatibility |
| BETA-02 — Required | Studio/artist pilot with repeat-use and support report | BETA-01, UX qualification; product/support lead | Artists understand authority and recovery; repeat use and cost/value documented | Novelty without sustained value |
| BETA-03 — Required | Claims, entitlement/offline behavior and launch go/no-go | BETA-02, commercialization/licensing decisions; product/release lead | Claims match evidence; AI outage/entitlement does not silently corrupt scenes or trigger render-worker calls | Commercial policy undermines trust |

## Smallest first coding assignment

Implement API-01 through API-07 for one host and one owned-fixture path, with E-01/E-02-style direct tests before MCP. Deliver a developer test harness, schema/capability definitions, a new clearly identified internal build, fixtures, operation/recovery evidence and a concise limitation list.

Do not begin by installing ML libraries, wiring a chat box to arbitrary MAXScript, or adding renderer automation.

## Replanning gates

At each phase, preserve a short decision: evidence, failures, cost, next scope and stop criteria. If a recipe solves the user's problem, ship the recipe improvement without forcing a model dependency. If reference value fails, keep the automation investment and narrow or close the AI track.

Current scheduling is **UNKNOWN**. Estimate effort ranges after dispatch/transaction spikes and pilot data; do not convert this backlog into unsupported delivery dates.

