# 15 — Provider Comparison and Recommendation

**External facts refreshed 2026-09-27 from official provider pages. Pricing can change.**

| Requirement | Cryptlex | Keygen | LicenseSpring |
|---|---|---|---|
| Node-locked | yes | yes | yes |
| Offline | yes | signed license/machine files | yes |
| Hosted floating | Growth+ | flexible floating API model | Business Starter+ |
| On-prem/air-gap floating | Business+ | self-host/Relay/custom architecture options | Enterprise |
| Perpetual | yes | yes | yes |
| Maintenance/update window | explicit maintenance policies | perpetual fallback/release policy patterns | product versioning; verify exact maintenance fit in POC |
| Trial | yes | yes | yes |
| Public dev/free entry | 30-day full trial | Dev tier up to 100 ALUs | Free dev tier |
| Current public base pricing | $100 Starter / $300 Growth / $600 Business monthly | tier/volume pricing; site calculator | $0 / $199 / $750 / Enterprise custom |

## Cryptlex

Strongest direct match to Cyrus Scatter's desired out-of-box model:
- Starter: node-locked, offline, entitlements;
- Growth: hosted floating + maintenance;
- Business: on-prem floating;
- local node-locked validation with background sync;
- explicit offline request/response;
- trial system.

Main tradeoff: Studio hosted floating pushes you to at least Growth, and on-prem to Business.

## Keygen

Strong fit if you value API control and cryptographic primitives:
- node/floating/offline/perpetual/feature models;
- signed license and machine files;
- Ed25519-supported verification;
- self-hosting options;
- Dev tier for integration.

Tradeoff: more of the exact Cyrus business policy may be your responsibility, which is flexibility but also engineering/support surface.

## LicenseSpring

Good commercial licensing platform with free development and production floating at Business Starter. Enterprise includes on-prem floating/air-gap/self-hosting. Worth a POC if enterprise support model or vendor relationship is attractive.

## Recommendation

**POC Cryptlex first, Keygen second.** Do not hard-wire the product to either. Choose only after the contract test matrix passes.

For a first commercial release, Cryptlex currently has the most direct mapping to the proposed Solo + Studio + offline + maintenance model. Keygen is the strongest architectural alternative.
