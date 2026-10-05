# Licensing decisions

**Updated:** 2026-10-05. This is the current decision register; older worksheets are historical proposals. The user selected post-expiry rendering without editing and requested full-term offline use plus one-device activation and portal transfers. Transfer overlap and clock-recovery policy remain open. No price, subscription term length or sales contract is approved by this document.

The [October 5 native/real-installation tests](NATIVE_FOUNDATION_2026-10-05.md) provide new B07/B08 evidence. Native recipe/Edit/Brush state survives expiry/reopen/renewal, but external source/receiver/animation changes still affect evaluation. Issuing a second installation permission leaves the disconnected first permission valid. B07 dependency-continuity versus frozen-world options and B08 immediate-overlap versus delayed-reuse options have been presented to the user; **no answer has been recorded, so both remain OPEN**. A development fixture is not a commercial policy selection.

## Selected direction and engineering constraints

| ID | Decision or constraint | Status and basis |
| --- | --- | --- |
| D01 | Own and operate the licensing service; no commercial licensing-platform integration in the initial plan | SELECTED by the user |
| D02 | Support individual customers and studios, including purchased seat quantities and future volume offers | REQUESTED by the user; exact offers and discounts remain open |
| D03 | New same-product features should reuse existing rights rather than demand licensing redesign | REQUESTED design goal; L1 and L3 must demonstrate it |
| D04 | Use maintained crypto/auth/database components; keep server license-signing private keys off clients | ENGINEERING REQUIREMENT; a separate protected device key may exist locally for activation binding |
| D05 | Keep licensing outside computation/display loops and preserve scene data | ENGINEERING REQUIREMENT; native integration still needs tests |
| D06 | Individual and assigned studio seats first; floating only after its race/outage tests | RECOMMENDED implementation scope, not an approved sales promise |
| D07 | Complete initial authoring feature set; avoid individual entitlements for every control | RECOMMENDED simplification; separately sold products can be added later |
| D08 | One authoritative seat writer initially; explicit reservation accounting for all issued offline authority | ENGINEERING REQUIREMENT for the proposed capacity model |
| D09 | Subscription expiry preserves existing work and blocks new authoring/editing; verified renewal restores editing of the retained work | SELECTED product intent by the user, 2026-10-04; D11 settles existing-work rendering; precise evaluation scope remains B07 |
| D10 | Keep entitlement verification, commercial policy and scene-operation integration separate so supported rules can change without rewriting the foundation | REQUESTED design goal, 2026-10-04; L1 policy-variation and feature-extension tests must demonstrate it |
| D11 | Allow rendering of existing work after subscription expiry while new Cyrus authoring/editing remains locked | SELECTED by the user, 2026-10-04; L0/E15 must prove the distinction; worker deployment, changed dependencies and bake/export remain B07 |
| D12 | After activation, allow offline authoring through the subscription's calendar end rather than requiring routine online refresh | REQUESTED by the user, 2026-10-04; signed deadline, clock limits, recovery exceptions and transfer consequences need qualification; no term length chosen |
| D13 | One authorized device per purchased seat, with self-service device transfer through the website | REQUESTED by the user, 2026-10-04; B02/B08 must define counting/recovery and effective transfer; IP or a bare UUID is not sufficient authority |

## Confirmed subscription behavior

D09/D11 describe the intended customer experience: work created while authorized remains available as retained project data and can still render; expiry locks new Cyrus authoring/editing; renewal restores the covered operations so the user can continue. Keep saved parameters, identities, source references and stored edits. Do not erase state, convert the scene irreversibly or require reconstruction merely because authority ended. Preserve save/open and recovery access; any current operation reaches the bounded safe boundary defined by E13.

This selects a subscription behavior, not a subscription-only catalogue or a perpetual-rights policy. Renewal means receiving and validating new authority for the relevant product/seat/build; a payment-success screen alone is not authorization. Temporary connectivity loss with valid cached authority remains distinct from subscription expiry. D12 requests normal offline use through the subscription end; B05 still needs clock-recovery exceptions and qualification before this becomes a customer promise.

"Existing work stays unchanged" needs an explicit procedural-scene contract. Preserving authored state does not by itself freeze evaluated output when a source tree, distribution surface, modifier, external asset or animation frame changes. B07 must settle how dependencies may evaluate for the selected render permission and whether bake/export is included. L0 must test reopen with missing caches and renewal after upstream changes; do not promise an exact frozen render result or impose a full baked-cache architecture from this statement alone.

## Offline use and device transfer

D12 is a request for a signed, device-bound permission whose authoring deadline reaches the purchased term end. A local timer is not proof of purchase or trustworthy calendar time. Normal expiry can be enforced in the unmodified client, including while Max stays open, but offline clock/storage rollback resistance remains best effort. Deleted local state must not restart the term. One-time activation and renewal require authority issued by our service; a file-exchange activation route would be a separate later workflow.

D13 separates a purchased seat from its current activation. The portal should record a transfer/deactivation, stop future issuance to the old activation and retain its history and outstanding signed deadline. It must not simply delete the purchase or forget issued authority. Reinstall, hardware replacement and a lost device need recovery rules.

The unresolved tradeoff is explicit: full-term offline authority, immediate transfer to a new device and strict prevention of overlapping offline use cannot all be guaranteed by this desktop design. B08 must choose delayed reuse until old authority ends, controlled transfers with explicitly accepted overlap, or a shorter offline window with periodic refresh. An online deactivation can stop an honest current installation, but does not prove a saved offline copy cannot be replayed. No overlap policy or shorter window is silently selected here.

## Business and operating choices

These decisions do not prevent a configurable test harness. Do not substitute old example values for an answer.

| ID | Choice needed | Recommendation or options | Must be settled before |
| --- | --- | --- | --- |
| B01 | Subscription, perpetual plus maintenance, or both | Model use rights, update eligibility and proof validity separately; choose a small launch offer | Customer pilot terms and enforcement behavior |
| B02 | Device counting and simultaneous use | D13 requests one device per purchased seat; define account/Windows-user/reinstall identity and multiple Max process behavior separately | Individual candidate policy freeze |
| B03 | Studio allocation | Assigned people first; floating is a later offer unless a pilot specifically requires it | Studio pilot |
| B04 | Floating reservation unit | Proposed: user + registered installation + product pool, with child Max sessions | L4 implementation contract |
| B05 | Offline deadline, time confidence and recovery | D12 requests normal offline editing until the subscription end; qualify clock anomalies, restart/restore and any recovery connection; track outstanding authority; no shorter window or extra grace selected | Issuing real customer authority |
| B06 | Trial | Duration, start event, allowed rights, extensions and recovery; a supervised pilot can precede a public trial | Public trial provisioning |
| B07 | Post-expiry evaluation, worker deployment and bake/export | D11 permits rendering existing work; settle changed dependencies, animation, missing caches, worker proof/deployment and bake/export through L0 | Native enforcement and advertised continuity/render policy |
| B08 | Transfer, reassignment, lost machine and reductions | D13 requests portal transfer; select delayed reuse, explicitly accepted overlap, or revised offline window; deleting an activation cannot invalidate a disconnected grant | Activation/recovery pilot |
| B09 | Seat prices and volume discounts | Versioned catalogue; all-units or graduated bands are possible; specify proration, refunds and term alignment | Checkout and sales copy |
| B10 | Perpetual/business shutdown continuity | Specify eligible-build access and how customers recover if our service ends; no universal embedded unlock secret | Selling perpetual rights |
| B11 | Identity, signer, deployment and support ownership | Choose maintained components after compatibility tests; name operators for accounts, keys, backups and incidents | Service pilot using customer data |
| B12 | Supported hosts/renderers, privacy and support promise | Publish only qualified configurations; define data retention and support coverage | External pilot/release scope |

The old 30-day trial, 12-month maintenance period, 90–365-day offline range and 6–10-week estimate are not approved values. D13 now explicitly requests one device per purchased seat; D12 ties requested offline use to the actual purchased subscription end without choosing a subscription length. Neither confirms every historical package assumption. On-premises servers, file-exchange air-gap deployment, SSO/SCIM, multi-region writers and custom enterprise SLAs remain deferred unless required.

## Operation and scene-continuity contract

D09/D11 select preservation, rendering of existing work, the new-authoring lock and verified-renewal recovery for subscription expiry. A bounded private native slice now implements and tests this lifecycle; the table remains the intended whole-product contract, which is not yet enforced in ordinary builds. Remaining evaluation/worker details and application to other denial causes are proposals to test. Authoring authority must match product, build and operation; its expiry must not automatically disable the selected rendering behavior. “No valid grant” includes absent, expired or rejected authority; a temporary outage alone does not invalidate an unexpired verified grant.

| Operation | Valid authoring authority | No valid authoring authority | Proposed worker behavior | Unresolved issue or test |
| --- | --- | --- | --- | --- |
| Open, inspect, select and navigate | Allow | Preserve access and scene state | Allow inspection needed for jobs | No automatic authoring-seat checkout |
| Save existing scene and retained edits | Allow | Preserve serialized data; do not erase or rewrite IDs | Preserve job data | Scene comparison before/after denial, save/reopen and upgrade |
| Faithfully evaluate saved procedural state | Allow | Continuity recommended | Evaluate under the agreed worker policy | L0 must distinguish this from authoring through changed script parameters |
| Render saved scene | Allow supported paths | Allow existing-work rendering after subscription expiry under D11; behavior for other denial causes needs qualification | No authoring seat recommended; exact proof/deployment remains B07 | Clean workers, animation, missing caches and IPR; filename alone is insufficient |
| Create/change distribution, sources, masks or new Brush data | Allow covered rights | Deny new authoring with a useful reason | Deny authoring under worker-only rights | All public native/script/parameter entry paths, not just UI buttons |
| Move/rotate/scale/clone/delete/reset CS Edit data | Allow covered rights | Deny new mutation, retain existing edits | Evaluate stored edits | Undo/Redo and restore must not become destructive or bypass the agreed policy |
| Run new Analyzer authoring work | Allow covered rights | Deny new authoring | Permit only dependencies required by agreed evaluation policy | Analyzer may be called by scene evaluation; blanket checks are unsafe |
| Bake or export | Allow covered rights | B07 | B07 for required job outputs | Script-only check is bypassable; accessible transforms limit export control |
| Sign in, inspect status, deactivate and recover | Allow available actions | Keep available | Provide appropriate noninteractive recovery | Recovery must not require the right that has expired |

If the native boundary cannot support the proposed distinction without major refactoring, revise the policy or explicitly accept the practical limitation before shipping. Do not label arbitrary caller input as trusted evaluation.

The [codebase audit](CODEBASE_AUDIT.md) adds concrete B07 evidence: preview, PFlow and bake share placement evaluation; public functions accept new inputs; transient render nodes are cleared before saving; edit evaluation updates identity records. D11 settles the product intent to render existing work after expiry, while B07's implementation/evaluation details remain OPEN. L0 must prove the selected behavior and document limits before release; free-worker deployment and restricted export are not automatically solved.

## Continuity scenarios and rules

| Event | Required engineering outcome | Policy still needed |
| --- | --- | --- |
| Subscription authoring authority ends | Preserve authored data, permit existing-work rendering under D11 and deny new authoring/editing under D09; keep recovery available | B05 time confidence and B07 evaluation details; bounded in-progress work follows E13 |
| Subscription is renewed | Verify renewed authority and restore covered editing using retained state; no reset or reconstruction due solely to licensing | Reconcile upstream changes and stale caches without silently publishing denied changes; test E04/E15 |
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
