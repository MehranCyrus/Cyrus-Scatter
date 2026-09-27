# 18 — Licensing UI and MAXScript Generator Integration

## Generator source

Do not edit the generated 964 KB `AminScatterObject.ms` directly.

## Rename collision

Current `tools/ui/activation.cjs` controls feature enable/disable, not commercial activation. Rename it to `feature-enable.cjs` or `scatter-enable.cjs` while preserving generated behavior.

Then add:
- `tools/ui/licensing.cjs`;
- `tools/ui/templates/licensing-ui.ms`.

## UI functions

Native primitives should expose sanitized operations such as:
- `cyrusLicenseStatus()`;
- `cyrusLicenseActivate key`;
- `cyrusLicenseDeactivate()`;
- `cyrusLicenseRefresh()`;
- `cyrusLicenseCreateOfflineRequest key path`;
- `cyrusLicenseImportOfflineResponse path`;
- `cyrusLicenseDiagnostics()`.

MAXScript displays results; it does not decide whether a capability is allowed.

## UI states

Show:
- Trial / Licensed / Floating / Offline / Grace;
- customer-safe license identifier;
- maintenance date;
- release eligibility;
- machine/seat status;
- last refresh;
- offline/grace deadline;
- Activate / Deactivate / Refresh / Offline workflow;
- support diagnostics copy button.

## Error UX

Never show provider error codes alone. Map to a stable Cyrus reason code plus optional technical detail.

## Analyzer UI

Analyzer can share the same global license status UI or link to it. Do not create a separate activation state for Analyzer if it is one product entitlement.
