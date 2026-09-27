# 05 — Provider Evaluation

Snapshot: **2026-09-27**. Re-check pricing/features before purchase.

## Criteria

Native/C++ integration, node lock, floating, offline/air-gap, signed local state, features, maintenance/version policy, portal, API/webhooks, studio/on-prem path, cost and lock-in.

## Cryptlex

**WEB VERIFIED:** public monthly plans currently show:
- Starter $100: node-locked, named-user, offline activation, feature entitlements.
- Growth $300: hosted floating, maintenance policies, customer portal/releases.
- Business $600: on-premise floating and additional governance.
- Enterprise: custom/self-hosted options.

Current docs describe local cryptographic validation, offline request/response activation, hosted floating leases and on-prem `LexFloatServer`.

**Fit:** strong native desktop fit; clear Solo-to-Studio path. Main tradeoff is recurring cost/provider SDK coupling.

## Keygen

**WEB VERIFIED:** docs support node-locked/floating policies, signed offline license/machine files, Ed25519/ECDSA/RSA schemes, public-key verification, perpetual/maintenance patterns and machine/process limits.

**Fit:** strong API/crypto flexibility and an attractive abstraction-friendly design. More integration ownership than a turnkey native SDK.

## LicenseSpring

**WEB VERIFIED:** current public pricing:
- Free $0 development tier.
- Business Starter $199/month, including cloud floating.
- Business Plus $750/month.
- Enterprise custom, including on-prem floating, air-gap and self-hosted options.

**Fit:** credible enterprise path; evaluate cost against expected early revenue.

## POC recommendation

Build `LicenseCore` first, then implement:
```text
ILicenseProvider
  +-- FakeLicenseProvider
  +-- CryptlexProvider (POC)
  +-- KeygenProvider   (POC)
```

Run identical tests for activation, transfer, offline state, maintenance, trial, floating exhaustion/crash, outage, clock anomaly and render-only behavior.

## Commerce / MoR

Keep commerce separate from licensing.

- Lemon Squeezy: useful MoR/checkout and built-in license-key features; use commerce features without forcing Cyrus's advanced DRM model into the commerce layer.
- Paddle: evaluate as another MoR.
- FastSpring: official current pricing is quote/revenue-share based; worth evaluating for B2B/studio procurement.

```text
MoR -> signed webhook -> Cyrus provisioning -> licensing provider -> LicenseCore
```

This lets either provider layer change independently.

## Shortlist

1. Cryptlex POC.
2. Keygen POC.
3. LicenseSpring as comparison/enterprise alternative.

No provider has been selected yet.
