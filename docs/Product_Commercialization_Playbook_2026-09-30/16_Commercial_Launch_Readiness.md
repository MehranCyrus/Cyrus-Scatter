# Stage 16 — Commercial launch readiness

## Goal

Make one explicit go/no-go decision for the first paid release, backed by product, operational and commercial evidence.

## Why this matters

A paid product must remain usable after purchase, updates, failures and handoff. A good demo does not replace installation, licensing recovery, delivery, support or rollback.

## What we currently know

- **VERIFIED IN SOURCE / VERIFIED BY TEST:** the development product and narrow retained test evidence are summarized in [98](98_Repository_Review_and_Deliverables.md).
- **UNKNOWN:** paid-release readiness. Licensing, commerce, signed commercial delivery and broad runtime qualification are not established.
- **PROPOSED:** the checklist below applies the governing [quality/release strategy](../Product_Strategy_2026-09-29/10_Quality_Qualification_and_Release.md) and [commercial strategy](../Product_Strategy_2026-09-29/09_Licensing_and_Commercial_Strategy.md).
- Required product targets remain Max 2024–2027 and a qualified 32 GB workload envelope. Any smaller first release requires explicit owner scope, accurate public wording and continued tracking of unfinished targets.

## My tasks

- [ ] Gather one release record, not scattered verbal approvals.
- [ ] Verify every advertised claim against qualified evidence.
- [ ] Rehearse a new customer's purchase/trial/install/first task/recovery.
- [ ] Confirm terms, contact, downloads and support ownership.
- [ ] Present unresolved blockers to the owner.
- [ ] Record the launch decision and post-launch review plan.

## Engineering / Codex tasks

- Qualify final binaries/host/renderer scope and close release-blocking issues.
- Verify signed artifacts, final package identity and clean installation/removal.
- Exercise owned licensing service, signer, database, credential and commerce failures and recovery.
- Preserve eligible old installers, backup/restore and rollback.
- Supply diagnostics and issue handling for the actual released build.
- Retest affected paths after any last-minute binary/package change.

## Boss / Product-owner decisions

Approve offer, public support scope, reviewed policies, seller arrangements, support coverage and the final go/no-go. This stage plans those decisions; it does not authorize deployment, sales, outreach or publication now.

## Step-by-step procedure

1. Freeze a candidate build, scene kit and offer; record exact hashes and versions.
2. Mark every required row below with evidence and a named owner.
3. Run the customer journey and a failure/recovery journey using the final distributable.
4. Audit website/download/offer claims against the claims matrix.
5. Review beta outcomes, remaining issues, operations and owner approvals.
6. Record **GO**, **LIMITED GO** with explicit qualified scope, or **NO-GO** with next actions.
7. Publish/sell only under the eventual approved launch assignment.
8. Monitor through the staffed support process; use the tested stop-delivery/rollback procedure for severe failures.

### REQUIRED FOR FIRST PAID RELEASE

A checkbox passes only for the declared offer/scope. Excluded optional offers require a written exclusion; “not tested” is not a pass.

| Done | Area | Required evidence | Accountable role |
|---|---|---|---|
| [ ] | Product | Core create/revise/edit where offered/save/reopen/render workflows correct on release scenes | Engineering + you |
| [ ] | Stability and scene safety | No unresolved critical/high scene-loss, unrelated deletion, corruption or broken offered workflow; failure/cancellation recovery tested | Engineering |
| [ ] | Host/renderer/resource scope | Every advertised Max update, renderer/mode, OS and workload passes required tests; missing 2024/2025/2026 or 32 GB work remains visible | Engineering + QA/you |
| [ ] | Licensing policy and enforcement | Approved capabilities, entitlement states, direct/native mutation paths and faithful evaluation/render outcomes | Engineering + owner |
| [ ] | Owned licensing service | Applicable [L0–L6/E01–E17 evidence](../licensing/ROADMAP.md), protected production trust, operating costs and named outage/recovery owners | Owner + engineering |
| [ ] | Commerce | Approved seller/payment arrangement; authenticated provisioning, duplicate/retry handling, reconciliation and refund/revocation recovery tested | Owner + engineering/operations |
| [ ] | Installer / upgrade / uninstall | Final package, dependencies, clean profile, both included products, deliberate license-state retention and tested rollback | Engineering + you |
| [ ] | Code signing / release trust | Signed native binaries, timestamp/verification evidence and trusted final download identity; checksums alone are not publisher authentication | Engineering/release owner |
| [ ] | Documentation | Build-matched quick start, support matrix, limits, activation/recovery, uninstall/rollback and troubleshooting | You + engineering |
| [ ] | Trial / evaluation | Published trial terms and start/expiry/recovery behavior work; if no trial, remove the trial CTA and document the approved evaluation path | Owner + engineering |
| [ ] | Pricing / maintenance / upgrade | Approved currency/price, seat/activation rules, update eligibility and consistent copy | Owner |
| [ ] | Refund policy | Reviewed policy, named operator and tested practical processing/reconciliation | Owner + operations |
| [ ] | Privacy | Reviewed actual collection/retention/diagnostic handling, provider disclosures and consent where required; no hidden analytics | Owner + appropriate reviewer |
| [ ] | EULA / rights | Reviewed terms for actual seller/product; asset/media/demo redistribution rights recorded | Owner + appropriate reviewer |
| [ ] | Landing page / claims | Approved content/media; no unsupported compatibility/performance/licensing claims; correct CTA and requirements | You + owner/engineering |
| [ ] | Download delivery | New buyer/tester receives exact intended package; hashes/signatures, access and eligible older downloads checked | Operations + engineering |
| [ ] | Email / receipts / contact | Delivery/account/support messages use monitored channels; critical instructions and receipt/access recovery tested under agreed workflow | Owner + operations |
| [ ] | Support | Real contact, responder, coverage, escalation, redacted diagnostics and known-issue handling | Support owner + you |
| [ ] | Backups / restore | Release artifacts, policy/configuration and entitlement/provisioning records backed up appropriately; restore rehearsed without exposing secrets | Operations + engineering |
| [ ] | Rollback / incident | Stop delivery, recover installer/scene, communicate through authorized channels; responsibility and retention defined | Release/support owner |
| [ ] | Beta feedback | Pilot gates passed, repeat-use value and support burden reviewed; severe issues fixed/retested | You + engineering + owner |
| [ ] | Known issues / release identity | Consistent product/native/script/package versions and release notes; limitations visible before purchase | Engineering + you |

Signing implementation is future work. Legal/privacy/payment facts need current verification and appropriate reviewers for the actual arrangements; this playbook does not supply legal conclusions or choose a commerce service.

### NICE TO HAVE

- Optional, privacy-reviewed analytics with clear metrics and consent/controls as applicable. Analytics is not required to release; if enabled, its actual handling becomes part of the privacy gate.
- More than the starter media kit, additional tutorial scenes and caption languages.
- Self-service customer portal and a polished status page.
- Automated support intake, expanded build automation and additional non-advertised hardware coverage.
- Beta testimonials with permission and approved attribution.

### FUTURE

On-premises floating/air-gap enterprise offer, SLAs, broad farm certification, new host/renderer transports, OpenCL/CPU executor, additional editions, asset ecosystem and integrations. Move an item into required gates if it becomes part of the advertised first offer.

### Final customer journey

1. Read support scope, price and trial/licensing rules.
2. Receive the intended installer through the agreed purchase/evaluation route.
3. Verify identity, install and activate where required.
4. Complete S01; save/reopen; render on a supported configuration.
5. Recover from a deliberately prepared activation/asset/network failure.
6. Find support and provide a redacted reproduction.
7. Upgrade or restore an eligible earlier release.
8. Process a test cancellation/refund under the approved policy.

Use sandbox/test transactions during preparation. No real transaction, email or service action occurs in this documentation task.

### Launch decision record

~~~text
Candidate release / exact package and native/script hashes:
Public offer and approved policy IDs:
Qualified Max/OS/renderer/workload scope:
Outstanding required targets and advertised exclusions:
Product/manual/benchmark/licensing/commerce evidence:
Signing/install/uninstall/rollback/restore evidence:
Approved claims and media:
Reviewed terms/rights/privacy:
Support and incident owner:
Open issues, severity, mitigation and retest:
Decision: GO / LIMITED GO / NO-GO
Owner/approver and date:
Conditions / stop-delivery triggers:
First post-launch review date and metrics:
~~~

## Evidence to collect

Final release manifest, signed artifact verification, QA matrix, licensing service/commerce results, approved offer/policies, download/customer-journey records, beta summary, recovery/restore exercise and owner decision.

## Status table

| Item | Status | Notes |
|---|---|---|
| Product and support gates | NOT TESTED | Development evidence is insufficient |
| Licensing service/commerce gates | NOT TESTED | Owned direction selected; implementation and qualification pending |
| Signed installer/recovery/delivery | NOT TESTED | Future final release |
| Copy/terms/support approvals | NOT TESTED | Owner and reviewers |
| Final launch decision | NOT TESTED | No launch authorized by this task |

## Completion criteria

Every required gate passes for the declared scope, evidence is linked, responsibilities are staffed and the owner records an explicit launch decision. Unknown required items result in NO-GO or a genuinely excluded narrower scope; they cannot silently become passes.

## Do not do yet

Do not treat completion of this playbook as launch approval, collect payment, publish unreviewed terms or distribute a candidate with severe unresolved offered-workflow risks.

## Optional / later

See the NICE TO HAVE and FUTURE lists. New promises require new evidence and support ownership.

## Next stage

Use [99 — Progress log](99_Progress_Log.md) for release and post-launch follow-up, and keep the [master checklist](00_Master_Checklist.md) current.
