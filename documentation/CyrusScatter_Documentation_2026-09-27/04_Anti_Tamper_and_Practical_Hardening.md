# 04 — Anti-Tamper and Practical Hardening

## Reality

A determined attacker can eventually patch a desktop binary. The objective is layered deterrence, not an “uncrackable” claim.

## Threats and mitigations

### MAXScript patching
Attack: remove a scripted license check.  
Mitigation: MAXScript is UX only; native authoring/edit/analyzer operations authorize independently.

### Single native branch patch
Attack: patch one `if (!licensed)`.  
Mitigation: multiple capability checks at distinct valuable native boundaries, not one exported `isLicensed` gate.

### DLL replacement
Attack: replace native modules.  
Mitigation: Authenticode-signed releases, signed update manifests and optional targeted integrity checks. Signing raises trust/tamper visibility but is not DRM by itself.

### License cache copying
Attack: copy a valid local license to another PC.  
Mitigation: signed machine-bound activation plus provider activation limits.

### Clock rollback
Mitigation: signed expiry data, last trusted time/monotonic observations and periodic refresh. Treat anomalies as refresh/support events, not reasons to damage scenes.

### VM cloning
Mitigation: provider fingerprinting, reconciliation and floating licensing for ephemeral environments. Keep legitimate hardware-change support practical.

### API emulation/network blocking
Mitigation: verify cryptographic signatures on responses. Blocking the network eventually exhausts the offline/grace policy but does not break every launch.

### Render-node impersonation
Mitigation: render capability is narrow and natively detected. Render workers can evaluate existing scenes but cannot author/edit/bake.

### Leaked secrets
Mitigation: private signing keys, code-signing keys and provider management credentials never ship.

## Hardening order

**Phase A:** native gates, signed entitlements, activation limits, protected keys, background refresh/grace, code signing, secure release pipeline.

**Phase B:** symbol stripping, targeted string/control-flow obfuscation around licensing, basic integrity checks, privacy-aware anomaly telemetry.

**Phase C:** only if piracy data justifies it, selectively protect licensing routines with a commercial protector. Avoid whole-engine virtualization first.

## Repository hygiene

The audited `.gitignore` already excludes `.env`, `secrets/`, `private/`, `*.pem`, `*.pfx`, `*.p12`, `*.key`, `certificates/`, `signing/` and local config patterns.

Still run secret scanning and rotate anything ever exposed.

## Failure policy

Licensing may block new authoring/mutation. It must not corrupt MAX files, delete data, intentionally crash Max, or prevent an existing scene from being safely inspected/rendered under the supported render-only policy.
