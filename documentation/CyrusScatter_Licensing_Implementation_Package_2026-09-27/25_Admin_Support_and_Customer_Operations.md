# 25 — Admin, Support, and Customer Operations

## Support actions

Support/admin must be able to:
- find customer/license;
- see active machines/seats;
- reset a dead machine;
- deactivate an activation;
- extend trial;
- renew maintenance;
- suspend/reinstate;
- rotate compromised key;
- issue offline response;
- inspect audit history.

## Support diagnostic bundle

Customer-facing “Copy Diagnostics” should include:
- Cyrus version/build;
- Max version;
- license state/reason;
- license kind;
- activation mode;
- maintenance date;
- last refresh;
- grace/offline deadline;
- hashed machine ID;
- provider SDK version;
- relevant non-secret error code.

## Refund/revocation

Define policy before automation:
- refund before activation;
- refund after activation;
- chargeback;
- fraudulent key sharing;
- accidental duplicate purchase.

A refund webhook should not immediately destroy a studio's active scene in the middle of work without a deliberate commercial policy. Provisioning service should translate commerce events into licensing actions.

## Studio admins

If the provider supports organization/customer portals, decide what customers may self-manage:
- seat/machine visibility;
- deactivate machines;
- offline requests;
- user assignment.

Self-service reduces support load but needs abuse limits.

## SLA

If you sell enterprise/on-prem, define response expectations and who owns license-server troubleshooting.
