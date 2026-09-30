# Stage 15 — Pricing and offer preparation

## Goal

Give the owner a comparable set of offer options, costs and customer evidence. No final price is invented here.

## Why this matters

The sustainable price depends on product value, support burden and promised compatibility/licensing operations. Matching a competitor's sticker price could conceal very different features and ongoing costs.

## What we currently know

- **PROPOSED:** one complete authoring feature set with a simple Solo offer and a separately qualified Studio model.
- **UNKNOWN:** willingness to pay, actual support cost, provider/commerce fees, accepted seller arrangements and final refund/upgrade rules.
- **DOCUMENTED BUT NOT VERIFIED:** historical provider prices and commercial assumptions are reference material only.
- **REQUIRES MANUAL 3DS MAX TEST:** maturity and supported workload must be established before pricing claims. Beta enthusiasm alone does not prove value or willingness to pay.

## My tasks

- [ ] Collect the exact information below.
- [ ] Compare competitor offers under the same period/seat assumptions.
- [ ] Summarize beta task outcomes, repeat use and support minutes.
- [ ] Prepare two or three internally consistent offer options.
- [ ] Ask the owner to choose price and rules after reviewing the costs/uncertainty.
- [ ] Carry the approved offer into the landing page and licensing brief.

## Engineering / Codex tasks

- Estimate qualification and release maintenance per supported host/renderer.
- Report support, recovery and provisioning effort.
- Separate one-time implementation cost from recurring per-user/seat costs.
- Confirm that proposed edition/offline/floating terms can actually be delivered.
- Supply known product limits and cost risks rather than revenue forecasts.

## Boss / Product-owner decisions

Choose model, Solo/Studio seat rules, price/currency, maintenance, trial, discounts, upgrades, refunds and support coverage. Confirm seller/payment/contract arrangements through appropriate reviewers. None are approved by this document.

## Step-by-step procedure

1. Finish Stage 09 policy and obtain product/beta evidence.
2. Research current official competitor offers and dated quotes. Normalize license type, authoring seats, renderer/host coverage, libraries, maintenance and support.
3. Obtain comparable licensing and commerce cost information only for viable options.
4. Estimate support from actual beta minutes and recovery requests.
5. Build 12- and 36-month cash/cost scenarios using stated customer/seat assumptions.
6. Prepare two or three offer cards; mark missing inputs and sensitivity.
7. Owner chooses or postpones the offer. Record date, rationale and conditions.
8. Test purchase, activation, eligible updates, cancellation/refund and delivery before enabling public sales.

### Exactly what is needed before setting price

| Input | What to record | Source / responsible role | Current state |
|---|---|---|---|
| Competitor range | Official offer, currency/date, licence type, seats, renewals, included assets/support, comparable 1–3 year cost | You; current official pages/quotes | UNKNOWN |
| Product maturity | Qualified workflows, severe defect count, install/recovery outcome, scope limits | Engineering + Stage 12 | UNKNOWN for external use |
| Customer value | Repeated task use, matched revision times where measured, alternative workflow and purchase objections | You; approved interviews/beta | UNKNOWN |
| Solo vs Studio | Authoring users, activated machines, concurrency, admin/support needs | Owner + customers | PROPOSED only |
| Perpetual vs annual | Rights after expiry, included update period, renewal/major upgrade rule | Owner + Stage 09 | UNAPPROVED |
| Maintenance | Eligible build cutoff, installer retention, qualification/update obligations | Owner + engineering | UNAPPROVED |
| Support burden | Minutes per user/month, escalation cases, responder cost and coverage | You + support owner | UNKNOWN |
| Offline/floating | Provider add-ons, server/lease operations, recovery labour, deployment support | Engineering + Stage 11 | UNKNOWN |
| Licensing provider | Fixed and usage/seat charges, minimums, quote limits, integration/hosting cost | Stage 11 evidence | UNKNOWN |
| Commerce / Merchant of Record or payment route | Current fees, fixed charges, payout/currency conditions, refund/chargeback/provisioning effort | Owner + verified provider terms | UNKNOWN; no service selected |
| Upgrade policy | Major/minor definition, eligibility and transition cost | Owner + engineering | UNAPPROVED |
| Delivery and operations | Download hosting, signing, backups, release maintenance, support tooling | Engineering/operations | UNKNOWN |
| Rights and reviewed policies | Seller details, assets, EULA/privacy/refunds reviewed for actual arrangements | Owner + appropriate reviewers | UNKNOWN |

Prices and commercial conditions must be rechecked before commitment. Do not infer seller eligibility or tax treatment from the workstation location/timezone.

### Offer card

~~~text
Option / intended customer:
Included complete feature set:
Qualified Max/renderer/workload scope:
Perpetual or subscription rights:
Authoring seats / activations / simultaneous use:
Maintenance / renewal / major upgrades:
Trial / offline / worker / floating rules:
Support and recovery commitment:
Proposed price and currency: [owner input]
Refund/discount conditions: [owner input]
Dated competitor comparisons:
Provider/commerce quote and validity:
Actual beta/support evidence:
Estimated costs / missing inputs:
Owner decision and date:
~~~

### Simple cost worksheet

Use actual **net receipts** from the proposed commerce arrangement; keep gross sale price and every deduction visible in the worksheet.

~~~text
For a stated period and offer:
Net customer receipts = gross receipts minus recorded deductions/refunds
Variable cost = per-customer licensing + support labour + per-customer hosting/operations
Contribution = net customer receipts - variable cost
Period contribution = sum of contributions across offers/customers
Cash after fixed operating costs = period contribution - fixed operating costs

Record initial engineering/signing/release costs separately.
Do not count a provider fee both as fixed and per-customer.
For Studio, distinguish authoring seats, activations, concurrent leases and paying customers.
For perpetual offers, record new sales and maintenance renewals separately.
~~~

This is a planning calculation, not a profit forecast or accounting/tax conclusion. Use verified terms and appropriate reviewers for those questions.

Run conservative, expected and higher-volume scenarios. Vary support minutes, renewal uptake, provider fees, refund volume and supported host/renderer scope. A missing input is a range/UNKNOWN, not zero.

### Keep the first offer understandable

A complete authoring feature set avoids confusing feature locks. Defer Studio floating/offline enterprise commitments until tested and costed. Avoid lifetime support or permanent offline promises whose operating cost/continuity has not been resolved. An early discount requires explicit duration, eligibility and owner approval.

## Evidence to collect

Dated official offers/quotes, normalized comparisons, beta task/support data, cost workbook or table, offer cards, owner decision and reviewed terms. No customer financial identifiers or credentials belong in public docs.

## Status table

| Item | Status | Notes |
|---|---|---|
| Required information collected | NOT TESTED | UNKNOWN inputs listed |
| Comparable cost scenarios | NOT TESTED | No price/result invented |
| Offer options reviewed | NOT TESTED | Owner |
| Price/terms approved | NOT TESTED | Later decision |
| Purchase-to-recovery workflow tested | NOT TESTED | Before sales |

## Completion criteria

The owner approves a coherent offer with dated price, rights, scope and support terms after reviewing evidence, costs and remaining uncertainty. The customer-facing summary and licensing policy agree.

## Do not do yet

Do not publish a final price, copy stale competitor/provider fees, advertise an undefined lifetime deal, or accept money before operational release gates.

## Optional / later

Regional/currency variants, reseller arrangements, educational offers and enterprise contracts after a sustainable initial offer.

## Next stage

[Stage 16 — Commercial launch readiness](16_Commercial_Launch_Readiness.md).

