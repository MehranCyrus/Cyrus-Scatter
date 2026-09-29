# 19 — Threat Model and Anti-Tamper Priorities

## Threats

Assume attackers can:
- edit MAXScript;
- patch conditional jumps in native binaries;
- inspect exports/imports/strings;
- replay local files;
- redirect/block DNS/network;
- change clock;
- clone VMs;
- copy installations;
- know the architecture/source.

## Do now

1. native capability gates at multiple meaningful boundaries;
2. signed provider/offline state;
3. public-key pinning/verification;
4. machine/activation limits;
5. trusted-time/grace logic;
6. code signing;
7. protected secrets and release pipeline;
8. safe error behavior;
9. basic integrity checks around licensing module loading if practical;
10. strip debug symbols from public release while retaining private symbols.

## Later if piracy justifies it

- selective control-flow/string obfuscation in LicenseCore/provider adapter;
- duplicate independent checks around high-value operations;
- integrity verification of critical licensing module;
- watermark/forensic identifiers in support diagnostics, not rendered output;
- provider-specific anti-debug/tamper features if stable.

## Avoid initially

- whole-plugin virtualization;
- kernel drivers;
- always-online DRM;
- destructive scene changes;
- hidden “time bombs”;
- blocking render because a telemetry endpoint is down;
- pretending obfuscation is a cryptographic secret.

## Source exposure assumption

Because repository visibility was reported public during audit, design as though an attacker may understand the source. Security must depend on server-held secrets/signatures and provider state, not obscurity.
