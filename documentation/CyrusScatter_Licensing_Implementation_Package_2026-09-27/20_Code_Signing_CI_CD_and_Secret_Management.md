# 20 — Code Signing, CI/CD, and Secret Management

## Sign

At commercial release:
- native DLL/DLX/DLM;
- installer/package where applicable;
- timestamp signatures.

Keep certificate/private key in a protected signing service or CI secret store, not the repository.

## CI stages

```text
checkout exact tag
 -> regenerate MAXScript
 -> fail on unexpected diff
 -> build core/tests
 -> run CTests
 -> build Max 2026
 -> build Max 2027
 -> package
 -> malware/basic static scan
 -> sign
 -> verify signatures
 -> generate hashes/manifest
 -> publish immutable artifacts
```

## Secrets

Separate:
- provider client/public IDs: distributable;
- provider management API token: server only;
- MoR webhook secret: provisioning service only;
- code-signing private key: signing environment only;
- entitlement signing private key if self-managed: server/HSM only.

## GitHub

Use least-privilege tokens and environment protection for release jobs. Prefer short-lived/OIDC-backed cloud credentials where the chosen signing/storage service supports it.

## Build provenance

Record:
- Git tag/commit;
- toolchain;
- Max SDK target;
- provider SDK version;
- package hashes;
- signing certificate thumbprint/identity;
- test run IDs;
- publication date used for maintenance eligibility.
