# Licensing decisions

**Updated:** 2026-10-02. This is the current decision register; older worksheets are historical proposals. No price, duration or sales contract is approved by this document.

## Selected direction and engineering constraints

| ID | Decision or constraint | Status and basis |
| --- | --- | --- |
| D01 | Own and operate the licensing service; no commercial licensing-platform integration in the initial plan | SELECTED by the user |
| D02 | Support individual customers and studios, including purchased seat quantities and future volume offers | REQUESTED by the user; exact offers and discounts remain open |
| D03 | New same-product features should reuse existing rights rather than demand licensing redesign | REQUESTED design goal; L1 and L3 must demonstrate it |
| D04 | Use maintained crypto/auth/database components; keep private keys off clients | ENGINEERING REQUIREMENT of the proposed design |
| D05 | Keep licensing outside computation/display loops and preserve scene data | ENGINEERING REQUIREMENT; native integration still needs tests |
| D06 | Individual and assigned studio seats first; floating only after its race/outage tests | RECOMMENDED implementation scope, not an approved sales promise |
| D07 | Complete initial authoring feature set; avoid individual entitlements for every control | RECOMMENDED simplification; separately sold products can be added later |
| D08 | One authoritative seat writer initially; explicit reservation accounting for all issued offline authority | ENGINEERING REQUIREMENT for the proposed capacity model |

## Business and operating choices

These decisions do not prevent a configurable test harness. Do not substitute old example values for an answer.

| ID | Choice needed | Recommendation or options | Must be settled before |
| --- | --- | --- | --- |
| B01 | Subscription, perpetual plus maintenance, or both | Model use rights, update eligibility and proof validity separately; choose a small launch offer | Customer pilot terms and enforcement behavior |
| B02 | Individual device allowance and simultaneous use | Treat device activation separately from one person's assigned seat; test multiple Max processes | Individual candidate policy freeze |
| B03 | Studio allocation | Assigned people first; floating is a later offer unless a pilot specifically requires it | Studio pilot |
| B04 | Floating reservation unit | Proposed: user + registered installation + product pool, with child Max sessions | L4 implementation contract |
| B05 | Refresh, offline/grace and optional borrow duration | Measure expected disconnected work and capacity cost; every allowed offline interval must be backed by a reservation where concurrency is limited | Issuing real customer authority |
| B06 | Trial | Duration, start event, allowed rights, extensions and recovery; a supervised pilot can precede a public trial | Public trial provisioning |
| B07 | Unlicensed local render, free workers and bake/export | Complete the operation matrix below after the native boundary experiment | Native enforcement and advertised render policy |
| B08 | Transfer, reassignment, lost machine and reductions | Define effective times and any accepted offline overlap; no claim of instant deletion on remote machines | Activation/recovery pilot |
| B09 | Seat prices and volume discounts | Versioned catalogue; all-units or graduated bands are possible; specify proration, refunds and term alignment | Checkout and sales copy |
| B10 | Perpetual/business shutdown continuity | Specify eligible-build access and how customers recover if our service ends; no universal embedded unlock secret | Selling perpetual rights |
| B11 | Identity, signer, deployment and support ownership | Choose maintained components after compatibility tests; name operators for accounts, keys, backups and incidents | Service pilot using customer data |
| B12 | Supported hosts/renderers, privacy and support promise | Publish only qualified configurations; define data retention and support coverage | External pilot/release scope |

The old 30-day trial, one-machine default, 12-month maintenance period, 90–365-day offline range and 6–10-week estimate are not approved values. They must not become accidental implementation defaults or published promises. On-premises servers, long air-gap borrowing, SSO/SCIM, multi-region writers and custom enterprise SLAs are deferred unless a concrete customer need changes scope.

## Operation and scene-continuity contract

All rows are proposed behavior to test, not implemented permissions. A valid grant must also match the product, build and operation. “No valid grant” includes absent, expired or rejected authority; a temporary outage alone does not invalidate an unexpired verified grant.

| Operation | Valid authoring authority | No valid authoring authority | Proposed worker behavior | Unresolved issue or test |
| --- | --- | --- | --- | --- |
| Open, inspect, select and navigate | Allow | Preserve access and scene state | Allow inspection needed for jobs | No automatic authoring-seat checkout |
| Save existing scene and retained edits | Allow | Preserve serialized data; do not erase or rewrite IDs | Preserve job data | Scene comparison before/after denial, save/reopen and upgrade |
| Faithfully evaluate saved procedural state | Allow | Continuity recommended | Evaluate under the agreed worker policy | L0 must distinguish this from authoring through changed script parameters |
| Render saved scene | Allow supported paths | Local interactive rendering remains B07 | No authoring seat recommended; exact proof/scope remains B07 | Clean workers, animation, missing caches and IPR; filename alone is insufficient |
| Create/change distribution, sources, masks or new Brush data | Allow covered rights | Deny new authoring with a useful reason | Deny authoring under worker-only rights | All public native/script/parameter entry paths, not just UI buttons |
| Move/rotate/scale/clone/delete/reset CS Edit data | Allow covered rights | Deny new mutation, retain existing edits | Evaluate stored edits | Undo/Redo and restore must not become destructive or bypass the agreed policy |
| Run new Analyzer authoring work | Allow covered rights | Deny new authoring | Permit only dependencies required by agreed evaluation policy | Analyzer may be called by scene evaluation; blanket checks are unsafe |
| Bake or export | Allow covered rights | B07 | B07 for required job outputs | Script-only check is bypassable; accessible transforms limit export control |
| Sign in, inspect status, deactivate and recover | Allow available actions | Keep available | Provide appropriate noninteractive recovery | Recovery must not require the right that has expired |

If the native boundary cannot support the proposed distinction without major refactoring, revise the policy or explicitly accept the practical limitation before shipping. Do not label arbitrary caller input as trusted evaluation.

The [codebase audit](CODEBASE_AUDIT.md) adds concrete B07 evidence: preview, PFlow and bake share placement evaluation; public functions accept new inputs; transient render nodes are cleared before saving; edit evaluation updates identity records. These facts leave B07 OPEN. L0 must test the proposed boundary and continuity policy before promising free workers, restricted export or unlicensed regeneration.

## Continuity scenarios and rules

| Event | Required engineering outcome | Policy still needed |
| --- | --- | --- |
| Temporary service outage | Continue within valid signed authority; background retries cannot stall Max | Offline window and support message |
| Authority ends during an operation | Reach a defined safe boundary without data loss | Maximum completion window or checkpoint/cancel behavior; reserve capacity accordingly |
| Maintenance ends | Evaluate build eligibility independently of maintenance being active today | Continued-use and recovery promise for the purchased model |
| Studio pool is occupied | Deny a new reservation clearly; preserve existing scene data | Queuing/wait experience and allowed inspection/rendering |
| Employee leaves or machine is lost | Revoke future issuance, audit recovery, track outstanding old authority | Delayed reuse versus accepted temporary overlap |
| Key is compromised | Stop issuance and distribute authenticated trust changes; assess affected grants | Customer recovery and disconnected-client consequences |
| Database is restored from an older backup | Do not allocate capacity against forgotten still-valid grants | Restore source, recovery interval and operating procedure |

## Record a decision once

For each B-row record: selected choice, approver/date, affected offer, customer example, implementation limits, test IDs/evidence, alternatives deferred and review trigger. Record pricing only in the approved catalogue/offer specification; the native client needs rights and eligibility, not price bands.

Until those entries exist, the row stays OPEN. Engineering can use explicitly named synthetic policies in tests; those values never represent agreed customer terms.
