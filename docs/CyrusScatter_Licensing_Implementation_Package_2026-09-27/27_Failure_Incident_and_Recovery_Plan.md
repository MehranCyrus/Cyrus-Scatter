# 27 — Failure, Incident, and Recovery Plan

## Provider outage

- use valid signed cache/grace;
- do not block viewport because refresh timed out;
- surface “service temporarily unavailable”;
- retry with backoff;
- preserve work.

## Provisioning outage

Orders should queue/retry. Customer support needs a manual license-issue path with audit log.

## Signing key compromise

Have documented rotation:
- revoke/replace server key;
- ship updated trusted public key set if required;
- support overlap period;
- invalidate compromised artifacts.

## Code-signing certificate issue

Timestamped existing binaries should remain verifiable according to certificate/timestamp semantics. New release pipeline must fail closed if signing is unavailable rather than publish unsigned production binaries accidentally.

## Provider migration

Because product code uses `ILicenseProvider`, migration can support:
- old provider state reader;
- new provider activation;
- temporary dual-provider acceptance;
- customer key migration.

## Emergency grace build

Prepare a controlled emergency mechanism before launch. It should be a signed release/policy change, not a hidden universal key embedded in the binary.

## Incident logs

Record server-side administrative changes and provisioning events. Client diagnostics should remain privacy-minimized.
