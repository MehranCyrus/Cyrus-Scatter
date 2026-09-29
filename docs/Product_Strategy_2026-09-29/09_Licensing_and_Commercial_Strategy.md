# 09 — Licensing and commercial strategy

**Status: proposed business and engineering policy. No licensing provider or commerce service was selected, purchased or integrated in this review.**

## Keep the sound parts of the existing package

The [licensing specification](../CyrusScatter_Licensing_Implementation_Package_2026-09-27/README.md) correctly separates a native capability authority from provider adapters, keeps secrets out of clients, proposes signed state, and protects saved-scene evaluation. A fake provider and pure policy tests should precede network integration.

Licensing must remain out of placement math and viewport hot loops. Loading a plugin or rendering an existing scene should not automatically acquire an authoring seat. Network refresh should be bounded and asynchronous, while authorization consumes a locally validated snapshot.

## Resolve these conflicts before enforcement

| Issue | Why it matters | Recommended resolution |
|---|---|---|
| Perpetual access vs expiring offline entitlement | Eligible builds may become unusable when an offline renewal expires | Define what remains usable, renewal method, service-outage/business-continuity recovery and revocation tradeoff before selling the promise |
| Unlicensed scene viewing vs free worker rendering | Current prose does not fully define local rendering on an unlicensed interactive machine | Write one capability table for open/view/evaluate/render/author/edit/bake, covering workstation and worker contexts |
| Runtime detection vs security | A local process/command line is not a cryptographic proof of a legitimate farm | Use scoped evaluation permissions and practical abuse resistance; do not promise an unbypassable free-worker boundary |
| Shared DLL vs copies beside separate products | Duplicate loads can undermine one-process state or leases | Define one versioned runtime identity/load path per process and test mixed Scatter/Analyzer installs and multiple Max sessions |
| Bake gate in script | A script can skip a separate authorization check | Keep meaningful authority at the native operation boundary; also acknowledge that delivered transforms/render geometry are locally accessible |
| Lifetime of provider state | Renew/revoke/refresh can change during an operation | Use an operation-scoped decision and a defined expiry boundary; never destroy work mid-transform |
| Expired license during evaluation | A blanket throw can break scene load/render rather than just authoring | Separate mutation from faithful evaluation; test automatic callbacks and old scenes before adding gates |

These are design decisions, not confirmed vulnerabilities in an implemented licensing system; that system does not exist yet.

## Recommended initial offer

Use one complete authoring feature set during pilot/beta. Avoid splitting essential analysis/editing features into many small entitlements. A simple Solo offer and a separately validated Studio seat model are sufficient starting hypotheses.

Perpetual plus maintenance remains a reasonable option to evaluate, but pricing, activation allowance, trial length, offline validity, refunds and support terms need owner decisions backed by customer interviews and provider contract tests. Existing documents' 30-day trial and one-machine default are proposals, not accepted contractual terms.

Do not sell on-premises floating, an enterprise SLA, or broad farm support until installation, recovery and support ownership have been exercised. These are operational products in addition to code features.

## Implementation sequence

1. Centralize immutable release identity and maintain old eligible installers.
2. Complete the scene/render contract and policy decision table.
3. Add provider-neutral capability policy with a fake adapter in a standalone harness.
4. Test expired/no-license/outage cases without changing scene output.
5. Integrate native boundaries in a separate candidate build; keep performance comparisons isolated.
6. Evaluate shortlisted providers with the existing acceptance matrix and current commercial terms.
7. Select a provider only after offline, floating, recovery, renderer-worker and deployment tests.
8. Add commerce provisioning with authenticated, idempotent events, reconciliation and audited recovery.
9. Run a controlled commercial beta before public launch.

Pure policy work can proceed while performance work is designed. Enforcement and paid launch depend on runtime evidence. The older provider ranking and prices are historical research; this review does not renew those procurement recommendations.

## Continuity and trust

Specify normal online use, temporary outage, permanently disconnected workstation, lost machine, expired maintenance, all seats occupied, provider shutdown and product shutdown. Each needs an intelligible user action and a tested support procedure.

For perpetual licensing, distinguish build eligibility from proof of entitlement. An eligible build should not suddenly become ineligible because maintenance expires. If periodic offline renewal is required, disclose that clearly and design a durable recovery mechanism. Do not market unconditional offline permanence while enforcing a time-limited lease.

Render continuity must cover historical jobs and clean workers. Do not assume a preview cache is a durable render cache. Decide whether a portable evaluated snapshot is needed; prove size, completeness and corruption handling before relying on it.

## Client and service boundaries

- Keep management credentials and private signing keys server-side.
- Verify signatures before trusting entitlement fields; validate input lengths and schemas.
- Separate entitlement-key rotation from code-signing certificate rotation.
- Do not add a universal emergency unlock key to the client.
- Keep customer license state separate from replaceable program binaries and define uninstall behavior.
- Mask license identifiers in logs; collect no geometry or asset paths for routine licensing.
- Product analytics must be optional and separate from required entitlement operations.

Changing file hashes in an unsigned manifest is possible; checksums alone do not authenticate a publisher. Commercial packages need signed native artifacts and a trusted release channel. Use timestamped signing and verify the final distributable. [Microsoft SignTool](https://learn.microsoft.com/en-us/windows/win32/seccrypto/signtool)

## Business model discipline

Track support time per active customer, payment/provisioning failures, seat recovery requests, renewals and repeated workflow adoption. Estimate sustainable pricing only after understanding the cost of supporting hosts, renderers and enterprise options. No revenue forecast or market-size estimate is established by this review.

Before accepting money, confirm the seller's actual jurisdiction, provider/payment availability, contract terms, data handling and asset rights with appropriate reviewers. This document does not infer any legal conclusion from the workstation's timezone or choose a payment provider.

The commercial goal is to protect revenue while making legitimate production work dependable. Heavier anti-tamper measures come after evidence of a problem and must pass the same stability gates as other native changes.
