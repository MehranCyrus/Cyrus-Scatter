# 10 — Offline and Air-Gapped Licensing

## Node-locked offline flow

```text
Offline workstation
  -> Generate request file
  -> transfer request to connected device
  -> customer/admin portal validates request
  -> download signed response
  -> transfer response back
  -> native LicenseCore imports/verifies
  -> local offline entitlement active
```

Cryptlex currently documents this exact request/response pattern for node-locked licenses. Keygen supports signed license/machine files for offline and air-gapped environments.

## Policy

Offline is a first-class supported mode, not an emergency bypass.

Recommended defaults to validate in beta:
- perpetual Solo offline entitlement: long renewal window, e.g. 90–365 days depending on support/revocation needs;
- trial: shorter online-contact expectations;
- response files bound to machine/request;
- offline deactivation generates a request and invalidates local state where provider supports it.

The exact duration is a commercial/security parameter, not hard-coded business logic.

## Air-gapped floating

Hosted floating is not appropriate for a disconnected studio. Cryptlex's current model uses an on-prem LexFloatServer for this scenario. LicenseSpring lists on-prem/air-gap at Enterprise. Keygen supports offline/floating patterns but would require a POC to determine the operational model you want to support.

## Security

- signed response;
- short request nonce/ID lifetime where supported;
- machine binding;
- anti-replay;
- trusted issued/expiry times;
- no private signing key in client.

## Support

Document the workflow with screenshots/files before launch. Offline licensing that technically works but requires developer intervention for every renewal is not production-ready.
