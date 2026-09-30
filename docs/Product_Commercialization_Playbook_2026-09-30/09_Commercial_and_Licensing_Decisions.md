# Stage 09 — Commercial and licensing decisions

## Goal

Prepare one decision sheet for the product owner. Separate what you recommend from what has actually been approved.

## Why this matters

Artists need to understand what they buy, where they can use it, and what happens to their scenes if maintenance, a connection or a machine fails. Those promises determine licensing engineering and support cost.

## What we currently know

- **VERIFIED IN SOURCE:** no licensing authority or provider integration was found in the inspected product paths. Feature activation is an enable/disable control, not entitlement enforcement.
- **PROPOSED:** the governing [commercial strategy](../Product_Strategy_2026-09-29/09_Licensing_and_Commercial_Strategy.md) recommends one complete authoring feature set initially, with simple Solo and separately qualified Studio offers.
- **DOCUMENTED BUT NOT VERIFIED:** earlier specifications describe perpetual maintenance, offline, floating, trials and free render nodes. These are designs, not delivered capabilities or accepted contracts.
- **UNKNOWN:** final business model, activation allowance, trial duration, refund/support terms, seller arrangements and provider costs.

Everything in the default column below is **PROPOSED, UNAPPROVED**. Blank approval fields mean no decision. No price is proposed here.

## My tasks

- [ ] Read the sheet and mark confusing terms.
- [ ] Collect concrete artist/studio needs from approved interviews or beta feedback.
- [ ] Bring the owner a short recommendation, alternatives and unresolved costs.
- [ ] Record decisions with approver, date and scope.
- [ ] Carry approved promises into Stages 10, 11 and 15.

## Engineering / Codex tasks

- Estimate each option's implementation, testing and support burden.
- Prepare a capability table and recovery scenarios before enforcement.
- Identify contradictions between business promises and time-limited offline state.
- Distinguish build eligibility from current maintenance and entitlement proof.
- Do not implement these recommendations as defaults without approved policy.

## Boss / Product-owner decisions

Approve the commercial rules below. An option may be deferred if it is excluded explicitly from the first offer. Questions about business policy belong here, after the first product validation stages.

## Step-by-step procedure

1. Complete the product/scope recommendation from Stages 05–08.
2. Review each decision in the table.
3. Ask engineering which options are feasible for the proposed release.
4. Record approved, rejected or deferred choices in the decision record.
5. Write a plain-language customer example for each approved rule.
6. Check the examples against the capability and continuity worksheets.
7. Revisit cost-sensitive choices after provider experiments and beta evidence.

### Owner decision sheet

| Decision / meaning | Why it matters | Recommended current default — PROPOSED | Alternative | Owner approval needed | Current architecture support |
|---|---|---|---|---|---|
| Perpetual vs subscription: continued rights to an eligible build vs time-limited use | Customer trust and revenue/support obligations | Evaluate perpetual + maintenance; approve only after continuity tests | Subscription, or a clearly described choice of both | Model and exact rights after expiry | Neither licensing model implemented; build identity needs consolidation |
| Maintenance: eligibility for later releases during a term | Avoid confusing update access with scene access | Evaluate 12 months included; eligible older build remains usable | Annual-only subscription or different update period | Duration, renewal, expiry behavior | Eligibility enforcement absent |
| Solo: individual authoring offer | Simple first purchase | One complete authoring feature set | Several feature tiers | Who may use it and permitted work | Features exist; Solo entitlement absent |
| Studio: managed team seats | Different administration/support needs | Same features; offer only a tested team seat model | Individual seats first, Studio later | Seat ownership, admin rights, launch timing | Team administration absent |
| Floating: concurrent seat checkout | Shared seats require lease/crash/outage handling | Defer until acceptance tests pass | Named/node-locked Studio seats | Included hosts, lease/grace rules, separate price | Checkout/runtime authority absent |
| Machine activation count | Laptop/workstation convenience vs seat sharing | One activated authoring machine as initial hypothesis | Two activations with one active user/session | Count and simultaneous use rules | Device binding and seat accounting absent |
| Transfer: move a seat to another machine | Lost machines happen | Self-deactivation plus documented support recovery | Limited self-transfer frequency | Limits, dead-machine reset, abuse handling | Transfer/recovery absent |
| Trial: temporary evaluation entitlement | First experience and conversion | Evaluate 30 days of the complete authoring workflow | Shorter trial or supervised beta only | Length, start rule, extension, expiry and scene behavior | Trial authority absent |
| Offline: disconnected operation | Production networks can be restricted | Support a tested, disclosed method; do not promise permanent offline use yet | Online-only initial offer, clearly stated | Validity, renewal, outage and perpetual continuity | Signed offline state absent |
| Render nodes: evaluation/render without authoring purchase | Farm cost and reliable handoff | Free faithful rendering on qualified workers; no authoring-seat consumption | Explicit worker entitlement | Interactive-machine rendering, clean workers, redistribution | Render transport exists; worker policy absent |
| Air-gapped studios: no external connection | More operational complexity than temporary offline use | Defer as a separately qualified offer | Manual offline activation for a bounded use case | Renewal/recovery process and support commitment | No air-gap licensing deployment |
| Update eligibility | Customers must know which installer they can use | Immutable release identity; preserve access to eligible installers | Account-based update access with equivalent entitlement record | Cutoff calculation and eligible download retention | Package hashes exist; release/version metadata inconsistent |
| Refunds | Support procedure and buyer expectations | Decide a clear policy before selling | Different policies by offer/jurisdiction after review | Conditions, deadlines, who processes requests | No commerce/refund workflow |
| Major upgrades | Avoid surprise paid upgrades | Publish an explicit major-upgrade/maintenance rule | All updates included in an active subscription | Meaning of major version and renewal eligibility | No entitlement-to-release mapping |
| Enterprise features | Procurement, admin, offline and service obligations | Defer custom deployment/SLA commitments | A tightly scoped pilot contract | Features, operational owner, costs | No implemented enterprise licensing/admin service |
| Support level | Response promises create staffing obligations | Named support owner, channels and published coverage; no untested SLA | Paid priority support later | Hours, response target, supported scope | Documentation exists; operating support process untested |

### Capability worksheet — engineering and owner must complete together

**PROPOSED design requirement.** The same generation primitives can serve authoring and faithful scene evaluation. A blanket “license required” check could break old scenes or render jobs.

| Operation | Licensed workstation | No/expired license workstation | Qualified render worker | Decision to record |
|---|---|---|---|---|
| Open / view saved scene | Permit | Recommended permit | Permit | Missing plug-in/assets behavior |
| Faithfully evaluate saved procedural state | Permit | Resolve explicitly; recommended continuity | Permit under worker policy | What authoring changes are excluded |
| Render existing scene | Permit | Owner must explicitly decide local interactive rendering | Recommended no authoring seat | Renderer/context proof and abuse limits |
| Create/change Scatter or Analyzer settings | Permit eligible capability | Recommended deny new authoring with a clear explanation | Deny authoring | Native boundary and evaluation distinction |
| Move/rotate/scale/clone/delete CS Edit rows | Permit | Recommended deny new mutations; preserve saved deltas | Preserve/evaluate saved edits | Selection/inspection must not consume a seat unnecessarily |
| Bake/export | Permit eligible capability | Decide separately from view/render | Decide worker output needs | Native authority; transform output is already locally accessible |
| Activate/deactivate/recover | Permit available actions | Keep recovery reachable | Usually no interactive seat activation | Do not hide recovery behind an active-license gate |

No row is an implemented permission. See [Stage 10](10_Licensing_Technical_Preparation.md) for the integration boundaries.

### Continuity examples to approve

- Maintenance expired: an older eligible installer opens, evaluates and renders a saved job as promised.
- Provider temporarily unavailable: an existing user gets the documented behavior and recovery message.
- Machine died: support can restore the seat without deleting the user's scene.
- Permanently disconnected workstation: the disclosed renewal/recovery process remains practical.
- Provider or product service shuts down: perpetual/offline promises have an explicitly planned continuity route.
- All Studio seats occupied: saved-scene viewing/rendering and checkout denial behave as approved.

### Decision record

~~~text
Decision ID:
Topic:
Approved choice:
Rejected/deferred alternatives:
Affected offer, hosts and workflows:
Customer example:
Engineering acceptance tests:
Unresolved cost or contradiction:
Owner/approver:
Date:
Review trigger:
~~~

## Evidence to collect

Owner decisions, interview/beta notes, capability worksheet, recovery examples, engineering estimates and later provider contract results. Store policy decisions with the release brief; keep customer identifiers out of public docs.

## Status table

| Item | Status | Notes |
|---|---|---|
| Product scope ready for owner discussion | NOT TESTED | Link Stage 05/07 recommendation |
| Commercial rules reviewed | NOT TESTED | Owner/date required |
| Capability/continuity worksheet approved | NOT TESTED | Resolve unlicensed local rendering and perpetual offline expiry |
| Deferred offers excluded from draft copy | NOT TESTED | Floating/air-gap/SLA may remain deferred |

## Completion criteria

Every decision has an approved choice or explicit deferral, an owner/date and a customer-facing example. Active contradictions are recorded as blockers for implementation/sales. A deferred Studio/floating offer need not block a simpler approved pilot.

## Do not do yet

Do not publish trial/offline/perpetual guarantees, choose a vendor, sell a license, implement gates or treat historical terms as accepted policy.

## Optional / later

Customer portal, organization administration, purchase orders, enterprise SLA and on-premises floating.

## Next stage

[Stage 10 — Licensing technical preparation](10_Licensing_Technical_Preparation.md).

