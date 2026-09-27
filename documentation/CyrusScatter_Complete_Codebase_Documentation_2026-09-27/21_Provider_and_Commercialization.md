# 21 — Provider and Commercialization Snapshot

**Dated 2026-09-27. Verify again before purchase.**

## Licensing shortlist

### Cryptlex
Current public pricing observed:
- Starter $100/month: node-locked/named-user, offline activation, feature entitlements.
- Growth $300/month: hosted floating, maintenance policies, portal/releases.
- Business $600/month: on-prem floating.
- Enterprise: custom/self-hosted options.

### Keygen
Current documentation supports node-locked/floating policies, cryptographically signed offline license/machine files, public-key verification and perpetual/maintenance patterns. It is attractive when API flexibility and provider abstraction matter.

### LicenseSpring
Current public pricing observed:
- Free development tier;
- Business Starter $199/month with cloud floating;
- Business Plus $750/month;
- Enterprise custom with on-prem floating/air-gap/self-hosting options.

## POC order

Recommended engineering evaluation:
1. Fake provider;
2. Cryptlex POC;
3. Keygen POC;
4. LicenseSpring comparison if enterprise workflow/cost justifies it.

Do not choose solely on feature tables. Run identical activation/offline/floating/render-worker acceptance tests.

## Commercial model hypothesis

- perpetual + 12 months updates;
- optional maintenance;
- Solo node-locked;
- Studio floating;
- full trial;
- render-only workers;
- explicit offline workflow.

## Commerce

Keep Merchant-of-Record/checkout separate from licensing. Lemon Squeezy, Paddle or FastSpring can handle tax/checkout while a dedicated licensing layer handles machine/floating/offline/render policy.
