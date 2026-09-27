# 09 — Online Activation, Deactivation, and Transfer

## Activation

1. user enters key;
2. native UI bridge passes it to LicenseCore;
3. provider validates product/license;
4. provider activates current machine or acquires the appropriate seat;
5. signed state is stored;
6. LicenseCore normalizes entitlements;
7. UI refreshes status.

## Deactivation

Online Solo:
1. request provider deactivation;
2. confirm success;
3. clear local active state;
4. retain non-sensitive diagnostic record.

If network is unavailable, do not pretend the server seat was released. Offer offline deactivation workflow if provider supports it or direct the user to support/customer portal.

## Transfer policy

Recommended Solo policy:
- self-service deactivation when old machine is available;
- limited support/admin reset when machine is lost;
- log resets to detect abuse;
- avoid punitive permanent lockouts.

## Key rotation

Provider/admin should be able to rotate a compromised license key without changing the customer's commercial entitlement.

## UI messages

Distinguish:
- invalid key;
- wrong product;
- activation limit reached;
- license suspended/revoked;
- build not covered by maintenance;
- provider unavailable;
- clock/device mismatch.

Do not collapse all failures into “invalid license.”
