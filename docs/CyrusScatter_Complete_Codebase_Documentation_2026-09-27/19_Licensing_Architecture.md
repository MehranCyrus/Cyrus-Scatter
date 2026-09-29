# 19 — Licensing Architecture

## Principle

Licensing should wrap native host-facing operations, not contaminate the pure scatter/analyzer algorithms.

## Capabilities

Recommended:
`AuthorScatter`, `ModifyScatter`, `UseSurfaceAnalyzer`, `ExportOrBake`, `RenderExistingScene`, plus feature entitlements.

## Components

```text
MoR/commerce
 -> provisioning/webhooks
 -> licensing provider
 -> ILicenseProvider
 -> native LicenseCore
 -> RuntimeContext/capability policy
 -> bridge/edit/analyzer enforcement
 -> existing engines
```

## Enforcement map

- `aminScatterAdvanced` / authoring bridge: `AuthorScatter` or restricted render evaluation.
- CS Edit mutation primitives: `ModifyScatter`.
- `cyrusAnalyzeSurface`: `UseSurfaceAnalyzer` for interactive/new analysis.
- bake/export: `ExportOrBake`.
- PFlow render path: `RenderExistingScene`.

## Render workers

Render-only must be a narrow capability, not a global bypass. Existing scene evaluation can run; authoring, edit mutation and bake/export remain denied.

## Signed state

Use asymmetric signatures. Private signing/admin keys remain server-side. Client embeds/pins public verification material and caches signed entitlement/offline state.

## Perpetual + maintenance

Perpetual ownership should continue to run builds released inside the maintenance window after maintenance expires. Maintenance expiry blocks later releases, not the owned build.

## Provider abstraction

Implement `ILicenseProvider` and `FakeLicenseProvider` before vendor SDK integration. This allows Cryptlex/Keygen/LicenseSpring POCs without scattering provider types through the codebase.
