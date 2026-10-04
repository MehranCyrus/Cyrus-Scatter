# Licensing document audit

**Review and consolidation:** 2026-10-02. This records documentation findings, not vulnerabilities found in a deployed licensing system. No such system was implemented or tested by this task.

## Scope and disposition

Reviewed all 33 numbered licensing chapters, nine Mermaid diagrams, README and manifest; the dated codebase licensing/security chapters; the active strategy, governance and commercialization licensing instructions; the October 2 architecture/source register; and representative native/generator anchors. Official vendor evidence from the same-day research was retained, with targeted standards/database rechecks. This is not a complete new product-code audit or a legal review.

The result is one current [licensing home](README.md). Its architecture, decisions and roadmap replace competing implementation sequences. Older source research remains available with its dates and limitations. Unknown customer policy is identified rather than silently filled with example numbers.

## Material corrections

| Finding | Correction in the current plan |
| --- | --- |
| Cryptlex/Keygen proof of concept and selection still led active plans | Own-service direction is selected; first real backend is Cyrus. Keep a test backend, not several unused vendor adapters |
| A single state enum mixed outage, eligibility, entitlement and capacity | Independent facts feed a pure operation decision and a derived UI summary |
| Assigned seats, devices and floating sessions were conflated | Separate named assignment count, activation/simultaneous-use policy and floating reservation unit |
| Heartbeat loss or release implied immediate capacity reuse | Reserve until all issued authority ends, including accepted uncertainty/completion windows; offline deletion cannot be proved by a release request |
| Max executable/context detection was presented too confidently | Early boundary experiment includes script parameter changes, direct primitives, saved-state evaluation and render paths |
| Throw-on-denial sketches could break evaluation/rendering | Deny new mutations at proven boundaries; preserve scene data and approved evaluation; return structured reasons |
| A shared DLL appeared sufficient for multiple Max processes | Per-process runtime identity and cross-process credential/session coordination are separate concerns |
| Compromise response resembled normal key rotation | Routine overlap is bounded; a compromised key needs containment and trust revocation with explicit disconnected-client limits |
| Offline replay/clock protection sounded guaranteed | Document storage/VM replay and clock limitations; match bounded authority, capacity and recovery policy |
| Every future enterprise option appeared mandatory at launch | Assigned-seat pilot first; floating, borrowing, air-gap, SSO/SCIM and customer servers are staged |
| Example commercial numbers and schedules looked settled | Trial/device/maintenance/offline terms remain open; old estimate and vendor prices are retired |
| Feature categories risked becoming a license for each control | Reuse product rights and stable operation categories; test new entry points without service/token rewrites |
| Test backends and signed authority were insufficiently separated | Production targets must exclude fake backends/test trust and cannot activate them through a runtime switch |

## September licensing package

Numbered source material is preserved as a dated reference. “Keep” means retain its useful principle in the current documents, not apply every old sentence as a current specification.

| Chapter | Disposition | Current treatment |
| --- | --- | --- |
| 00 Executive plan | REPLACE | Owned-service roadmap and boundary-first experiment supersede vendor-first order |
| 01 Requirements/principles | KEEP / NARROW | Native authority, scene preservation and no hot-loop licensing remain; optional commercial modes are staged |
| 02 SKUs/capabilities | REVISE | Separate product rights, operation categories and offers; retire micro-entitlement defaults and assumed durations |
| 03 State model | REPLACE | Orthogonal facts plus derived decision; outage does not erase valid cached authority |
| 04 Native architecture | KEEP / REVISE | Host-independent core and narrow ABI; prove shared runtime/load identity and cross-process behavior |
| 05 API/pseudocode | REVISE | Structured decisions, bounded operation lifetime, explicit idempotency and effective release; no blanket evaluation throw |
| 06 Integration map | KEEP AS INPUT | Symbols remain useful; remap against current code, include every caller and parameter path |
| 07 Runtime/render context | CORRECT | Process names and flags are observations, not trustworthy proof of free-worker entitlement |
| 08 Signed state/cache/time | KEEP / REVISE | Signature/claim checks retained; owned activation and best-effort clock/device protection |
| 09 Activation/transfer | KEEP / REVISE | Recovery and clear status retained; effective transfer accounts for old disconnected authority |
| 10 Offline/air gap | DEFER / CORRECT | Separate temporary cached use from explicit borrowing and air-gap products; no assumed 90–365-day term or universal replay prevention |
| 11 Floating | REVISE | Transactional accounting, exact issuance, all-session lifetime, partition and stale-restore tests |
| 12 Trial | KEEP AS OPTION | Same product rights can be bounded by a trial grant; 30 days is unapproved; trial abuse resistance is not perfect identity proof |
| 13 Perpetual/maintenance | KEEP / CLARIFY | Use rights, release eligibility and proof expiry differ; continuity promise must be explicit |
| 14 Free render nodes | REVISE / OPEN | No authoring-seat use is a recommendation, contingent on policy and actual native/renderer feasibility |
| 15 Provider comparison | RETIRE FROM PLAN | No procurement recommendation or current price claim; historical research only |
| 16 Provider acceptance matrix | ADAPT | Useful failure cases become E01–E17; provider scoring is retired |
| 17 Commerce/webhooks | KEEP / EXPAND | Trusted origin, durable ingestion, business-effect idempotency and reconciliation; no processor chosen |
| 18 UI/generator | KEEP / NARROW | Edit generator inputs; clear recovery first; defer controls for unsold modes and avoid mandatory cosmetic renames |
| 19 Threat/anti-tamper | KEEP / CLARIFY | Local attacker can patch verification; prioritize service isolation, native coverage and reliability over heavy obfuscation |
| 20 Signing/CI/secrets | KEEP | Separate key purposes, test/production trust, restricted signer and final-artifact verification |
| 21 Release identity | KEEP / UPDATE | Immutable real metadata; old version/date examples are not current build facts |
| 22 Packaging | KEEP AS INPUT | Validate current installers and runtime dependencies before considering a packaging migration; build success is not host qualification |
| 23 Tests | KEEP / CONSOLIDATE | Current experiments cover applicable offers; results start unrun for licensing |
| 24 Migration/rollout | KEEP / NARROW | Isolated candidate, scene regression, reversible rollout; no unneeded installer redesign |
| 25 Support/operations | KEEP / STAGE | Account/seat recovery, least privilege and audit required; advanced enterprise workflows later |
| 26 Privacy/legal | KEEP | Minimal licensing data, defined retention and review before promises/sale; no jurisdiction inferred from timezone |
| 27 Incidents/recovery | CORRECT | Compromise differs from routine rotation; restore must account for issued grants; no universal emergency unlock |
| 28 Roadmap/estimates | REPLACE | Current gated roadmap; old 6–10-week estimate has no validity for this scope |
| 29 Backlog | REPLACE | Owned service and current host facts; provider adapters and stale completion statuses are not work orders |
| 30 Release gate | KEEP / SCOPE | Qualify every promised mode; do not require all hypothetical offers for a narrow launch |
| 31 Risks/experiments | KEEP / EXPAND | Add tenant boundaries, issuance races, offline overlap, multi-process credentials, signer/DB recovery and extension coverage |
| 32 Sources | HISTORICAL | Current source register supplies evidence; old vendor prices/features need fresh validation if ever reconsidered |

All nine diagrams were read. Diagrams 01, 03, 07 and 09 encode the retired provider sequence. Diagram 05 omits the complete outstanding-authority accounting; 06 overstates worker classification. Diagram 04 is an optional future offline exchange. Diagram 02 remains a useful conceptual decision flow, subject to the new fact/context rules. Diagram 08 remains a release-pipeline sketch, not evidence of implemented signing or qualified host support. They are preserved, not silently redrawn as if historically current.

## Other documents and navigation

| Material | Treatment |
| --- | --- |
| `Licensing_Architecture_2026-10-02.md` and its source register | Consolidated into this folder; original entry paths become short redirects, not parallel specifications |
| Product Strategy chapter 09 | Short current direction and links to the decision/architecture/roadmap authority |
| Product Strategy master roadmap and governance | Licensing milestones and authority links updated; unrelated performance/product work preserved |
| Commercialization stages 09, 10 and 11 | Current owner/engineering/validation workflows; no vendor selection gate or duplicate policy table |
| Commercialization index/checklist | Stage 11 now means owned-service validation; historical filename retained for link compatibility |
| Commercialization pricing and launch stages 15/16 | Owned-service operating costs and qualification replace mandatory licensing-vendor charges/selection |
| Commercialization progress log | Dated cleanup entry; earlier records remain historical |
| Complete Codebase Documentation chapters 19 and 20 | Retained as September source/design snapshots, not current implementation guidance; their package bytes/manifest remain untouched |
| Main docs index | Routes licensing readers here and labels the September package historical |

## Codebase follow-up

The user's follow-up requested source-grounded improvements to the licensing plan. The [codebase audit](CODEBASE_AUDIT.md) records ten findings from generation, preview, retained display, CS Edit, Analyzer, bake/PFlow, startup and packaging paths. Its [source evidence](evidence/codebase_snapshot_2026-10-02.json) records 37 selected file fingerprints and 38 native MAXScript declarations, including relevant uncommitted viewport work. This is a targeted static integration audit, not a full code/security audit or completed licensing boundary experiment.

The highest-priority additions are separate artist enable and license state; operation admission before clearing caches or transient render nodes; shared CS Edit mutation coverage; preservation of identity-recovery and history paths; explicit runtime/credential ownership; and final-artifact release identity/signing. No production source or scene was changed by this audit. These findings refine the existing L0/L1/L3 milestones and E01–E17 tests without creating another roadmap. All licensing runtime experiments remain NOT RUN.

## Policy clarification on 2026-10-04

The user confirmed an adaptable foundation and preservation of work with editing locked after subscription expiry, then explicitly selected rendering existing work after expiry. The user also requested offline use through the purchased term and one authorized device per seat with website transfers. Decisions D09–D13 record these choices and requests. The roadmap now requires expiry/save/reopen/render/verified-renewal tests, supported policy variation, clock/restart/storage recovery, device binding and a two-device offline-transfer demonstration.

B07 remains open for the precise procedural dependency, animation, worker-deployment and bake/export boundary. B05/B08 must reconcile full-term offline use with time-confidence recovery and still-usable old grants. Website deletion cannot prove offline revocation; strict delayed reuse, explicitly accepted transfer overlap and shorter offline authority are unresolved alternatives. No subscription length, shorter refresh window or overlap exception was silently selected.

The architecture now explains signed calendar deadlines, local protected storage, server-time/elapsed-time evidence, activation identity and recovery. It rejects local file timers as entitlement authority and IP/bare UUID as sufficient device proof. The source register records fresh Windows/network references and a clock-limit recheck. These updates affect six current licensing documents; the dated source audit and historical packages remain unchanged. No plugin behavior was changed or licensing runtime result claimed.

## Preservation and validation

Before editing, all **43 files** listed by the old licensing manifest matched its byte counts and CRC32 values. The 33 numbered chapters and nine diagrams are retained byte-for-byte. Only that package's README gains a supersession notice; its manifest records the intentional README revision. Local before-copies and the baseline hash record are in `_local/maintenance/2026-10-02-licensing-docs/`, excluded from Git.

The initial consolidation validation checked 23 Markdown files, 230 local link destinations, fence balance, the revised 43-entry manifest, all 42 unchanged historical chapter/diagram hashes, and whitespace errors in the scoped diff. All passed. The seven milestones L0–L6 and 17 acceptance experiments E01–E17 were present in order. Product binaries, licensing service behavior and security resistance are outside these document checks.

**Initial consolidation validation: PASS, 2026-10-02.** Its reproducible local checker and JSON result are retained in `_local/maintenance/2026-10-02-licensing-docs/`. Follow-up validation is recorded separately under `_local/maintenance/2026-10-02-licensing-code-audit/`. External references have individual research scopes in the source register; the local link check is not a blanket live-web verification.

**Codebase follow-up validation: PASS, 2026-10-02.** The separate check covered 24 Markdown files and 267 local link destinations, balanced fences, scoped whitespace, the 43-entry historical manifest and 42 unchanged chapter/diagram hashes. All 37 current selected source files and their local before-copies matched the recorded fingerprints; the fresh 38-declaration scan matched the snapshot. All ten findings, seven milestones and 17 experiments were present in order. These checks establish document/evidence consistency only.
