# Stage 11 — Licensing provider evaluation

## Goal

Prepare comparable experiments, then select a provider only when policy, technical evidence and current commercial terms justify it.

## Why this matters

A provider name or attractive price says little about Max deployment, offline continuity, floating crash recovery or the workload created for your support team.

## What we currently know

- **DOCUMENTED BUT NOT VERIFIED:** the earlier [25-test acceptance matrix](../CyrusScatter_Licensing_Implementation_Package_2026-09-27/16_Provider_POC_Acceptance_Matrix.md) remains the detailed starting checklist.
- **PROPOSED:** Cryptlex, Keygen and LicenseSpring are candidates to investigate later. Another provider requires a reason tied to an unmet requirement.
- **UNKNOWN:** current features, editions, SDK restrictions, prices, contract terms, seller availability and support quality for each candidate. Historical comparisons are not renewed purchasing recommendations.
- **VERIFIED IN SOURCE:** current host build configuration covers Max 2026/C++17 and 2027/C++20. Max 2024/2025 still require port/qualification work, including any chosen licensing deployment.

No provider accounts, purchase, SDK integration or selection was performed for this playbook.

## My tasks

- [ ] Prepare the experiment worksheet now.
- [ ] Obtain approved Stage 09 policy and an engineering harness before running provider tests.
- [ ] Recheck official documentation and obtain comparable current quotes later.
- [ ] Record pass/fail/unknown with evidence for each candidate.
- [ ] Present owner recommendation only after must-have requirements pass.

## Engineering / Codex tasks

- Use one provider-neutral harness and the same scenarios for every candidate.
- Preserve all 25 tests from the existing matrix; add the concrete cases below.
- Test deployment in each intended host/toolchain, rather than trusting an SDK's generic Windows claim.
- Record latency, crash/lease behavior and local-state fidelity.
- Keep API credentials/private keys out of repository, scenes, reports and screenshots.
- Estimate adapter, hosting, operations and migration cost.

## Boss / Product-owner decisions

Approve must-have scope, test budget, projected customer/seat scenarios and weights. Final purchase/selection is a later evidence-based decision. Selection can remain pending while an explicitly approved feature beta proceeds.

## Step-by-step procedure

1. Draft this plan and mark every vendor column UNKNOWN.
2. Complete Stage 09 policy and Stage 10 fake-provider/policy harness.
3. Before experiments, recheck each vendor's official docs, SDK/license terms and current commercial offer; record URL/date/quote validity.
4. Engineering implements comparable disposable adapters in a later assignment.
5. Run the 25 original acceptance tests plus these grouped extensions.
6. Reject candidates with an unresolved must-have failure; a high weighted score cannot erase it.
7. Compare total cost and support burden under the same assumptions.
8. Document selection, rejected alternatives and a migration/continuity plan; obtain owner approval.
9. Revalidate the selected adapter in the complete product before licensing beta.

### Experiments and evidence

| ID | Experiment | Concrete observation required |
|---|---|---|
| LE01 | Node-locked activation/deactivation/duplicate/lost device | Restart state, capacity behavior, self-transfer and support reset; authorized-machine count exactly matches policy |
| LE02 | Offline request/response and replay | Truly disconnect the machine; test renewal/expiry, old eligible builds, clock changes and recovery; record duration and user actions |
| LE03 | Hosted floating | Two machines contend for one authoring seat; close/crash/restart; exact lease/reclaim/outage outcomes; no seat consumed merely opening/rendering |
| LE04 | Worker and interactive render | Clean worker runs the same scene without paid authoring checkout; unlicensed interactive render follows the approved rule; no blanket generation denial |
| LE05 | Outage and continuity | Block provider access; fresh vs cached state; bounded failure; recover when restored; document long-term service loss assumptions separately |
| LE06 | VM/hardware/clone/transfer | Predictable tolerance, duplicate response and recovery; no unsupported VM promise |
| LE07 | Trial | Start, restart/reinstall, expiry and permitted extension; preserve saved scene according to policy |
| LE08 | Perpetual maintenance/release eligibility | Eligible old release after maintenance expiry; later ineligible release; signed identity; continuity behavior disclosed |
| LE09 | Proxy/firewall/latency | Timeouts, cancellation, background refresh behavior and UI responsiveness; no network calls during viewport draw |
| LE10 | SDK/toolchain/deployment | Max 2026/2027 candidate builds, clean install, dependency load, multiple processes, shared-runtime identity; 2024/2025 when ports exist |
| LE11 | State/signing/privacy/recovery | Bad signature/input bounds/key rotation/uninstall/reinstall; useful redacted audit log; support recovery without a universal client unlock key |
| LE12 | On-premises / air-gap | Only if approved scope: install/update/backup/restore server, seat recovery, disconnected workflow and named operator |
| LE13 | Commercial/support/exit | Current scoped quote, escalation path, contract limits, data/export rights, termination and adapter migration plan |

Keep the original matrix's trial extension, hardware change, key rotation and audit/privacy cases even where experiments group them. Add saved-scene fidelity, concurrent Max sessions, mixed product installs and maintenance/offline contradiction tests explicitly.

### Candidate worksheet — no evaluation results yet

| Requirement | Cryptlex | Keygen | LicenseSpring | Evidence / must-have? |
|---|---|---|---|---|
| Approved node/trial/transfer policy | UNKNOWN | UNKNOWN | UNKNOWN | |
| Offline/perpetual continuity | UNKNOWN | UNKNOWN | UNKNOWN | |
| Floating/worker scope | UNKNOWN | UNKNOWN | UNKNOWN | |
| Host SDK/deployment fit | UNKNOWN | UNKNOWN | UNKNOWN | |
| Outage, VM and recovery | UNKNOWN | UNKNOWN | UNKNOWN | |
| Support and operational burden | UNKNOWN | UNKNOWN | UNKNOWN | |
| Comparable total cost | UNKNOWN | UNKNOWN | UNKNOWN | |
| Exit/migration constraints | UNKNOWN | UNKNOWN | UNKNOWN | |

Each result needs provider/edition/API or SDK version, date, policy ID, environment, test input, expected/actual outcome and an evidence file. Mark unsupported launch requirements as failures; deferred offer requirements remain out of scope.

### Scoring after experiments

The older proposed weights are 30% technical fit, 20% studio/offline/render, 15% reliability/operations, 15% integration, 10% support and 10% cost. Reuse only if the owner accepts them. Document the scale and missing evidence; do not give an unknown a passing score.

Compare fixed fees, per-license/seat usage, hosting, required enterprise add-ons, taxes/payment conditions and support labour for identical scenarios. No current price is quoted here.

### External facts to recheck before commitment

- Official product/edition availability and C++/Windows SDK deployment rights.
- Offline/floating/air-gap terms and whether add-ons or self-hosting are required.
- Current price, billing metric, limits, quote expiry and termination terms.
- Seller's actual business/jurisdiction eligibility and payment availability.
- Data processing, retention, security documentation and support commitments.
- Customer/license export and transition rights.

Use qualified reviewers for contractual questions. The workstation's timezone does not establish the seller's jurisdiction.

## Evidence to collect

Versioned experiment results, redacted logs, official links with dates, current quotes, support answers, must-have failures, cost assumptions and eventual owner selection record.

## Status table

| Item | Status | Notes |
|---|---|---|
| Experiment plan | PARTIAL | Draft supplied; owner scope pending |
| Fake-provider harness available | NOT TESTED | Future engineering |
| Current commercial facts | NOT TESTED | Refresh before commitment |
| Comparable vendor experiments | NOT TESTED | No provider chosen |
| Selection decision | NOT TESTED | Later owner decision |

## Completion criteria

**Planning complete:** all approved requirements map to experiments, owners, evidence and cost assumptions. **Evaluation complete later:** required experiments and commercial verification are recorded and an owner approves selection or rejects all candidates. Do not check provider selection complete because this plan exists.

## Do not do yet

Do not choose a vendor from an old ranking, copy historical prices, buy a plan, embed keys, or promise a vendor feature as delivered Cyrus functionality.

## Optional / later

Fourth candidate, on-premises floating and migration rehearsal when justified by approved requirements.

## Next stage

[Stage 12 — Beta readiness](12_Beta_Readiness.md). A feature beta may follow product gates before provider selection; a licensing beta requires the implemented and tested licensing path.

