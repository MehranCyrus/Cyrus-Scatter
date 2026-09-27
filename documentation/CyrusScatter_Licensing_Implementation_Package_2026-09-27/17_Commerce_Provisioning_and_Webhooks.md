# 17 — Commerce, Provisioning, and Webhooks

## Separation

Checkout/Merchant of Record and license enforcement are different systems.

```text
Customer
 -> MoR checkout
 -> signed webhook
 -> Cyrus Provisioning API
 -> licensing-provider management API
 -> license/customer created or updated
 -> customer receives key/portal access
```

## Why a Cyrus provisioning layer

Do not send commerce webhooks directly into client-facing license logic. A small service gives you:
- idempotency;
- product/SKU mapping;
- refunds/revocations;
- maintenance renewals;
- provider replacement;
- audit log;
- manual support operations.

## Webhook rules

- verify signature;
- store event ID;
- idempotent processing;
- reject stale/replayed events where appropriate;
- queue/retry provider failures;
- never expose provider admin credentials to client;
- reconcile periodically against commerce/provider state.

## Events

At minimum:
- order paid;
- refund;
- chargeback;
- maintenance renewal;
- cancellation if subscriptions are later offered;
- seat quantity change;
- manual admin adjustment.

## MoR snapshot

Lemon Squeezy currently advertises 5% + $0.50 per ecommerce transaction and acts as MoR. Paddle currently advertises 5% + $0.50 pay-as-you-go and handles tax/compliance. FastSpring uses negotiated revenue-sharing/flat-rate terms and positions strongly for software/B2B/invoicing.

## Practical launch choice

For simple self-serve Solo sales, Lemon Squeezy or Paddle can minimize tax/compliance work. For larger studio procurement/quotes, FastSpring may be worth evaluating. Do not use the MoR's built-in simple license keys as the security authority if the dedicated provider is enforcing Studio/offline/render policy.
