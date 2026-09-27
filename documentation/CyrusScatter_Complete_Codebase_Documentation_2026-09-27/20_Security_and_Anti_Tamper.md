# 20 — Security and Practical Anti-Tamper

## Threat model

Assume an attacker can:
- read/modify MAXScript;
- inspect native exports and network traffic;
- patch client binaries;
- copy local license state;
- block/redirect network access;
- manipulate system time;
- clone VMs.

## Required layers

1. Native capability checks at multiple meaningful operations.
2. Cryptographically signed entitlement/offline state.
3. Provider activation/concurrency limits.
4. Machine binding with reasonable hardware-change tolerance.
5. Trusted-time/refresh logic for trials/offline windows.
6. Authenticode-signed binaries/package.
7. Private keys/admin credentials only in protected server/CI systems.
8. Optional selective obfuscation after the basic architecture is stable.

## Do not rely on

- MAXScript-only `licensed?`;
- hidden strings;
- MAC address alone;
- a single patchable native branch;
- always-online validation in preview/render loops;
- destructive behavior when validation fails.

## Scene safety

A licensing failure may block **new authoring/mutation**. It must not corrupt scenes, delete saved edits, intentionally crash Max or silently alter scatter results.

## Repository hygiene

The current `.gitignore` excludes common secret/certificate paths. Still run secret scanning and rotate anything ever exposed. Repository visibility was public during this audit and should be reviewed if source is proprietary.
