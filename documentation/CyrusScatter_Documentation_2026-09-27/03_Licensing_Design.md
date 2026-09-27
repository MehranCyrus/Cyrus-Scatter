# 03 — Licensing Design

## Requirements

- Solo node-locked activation.
- Studio floating/concurrent seats.
- Trial.
- Offline/air-gapped workflow.
- Free restricted render workers.
- Perpetual + maintenance and/or subscription support.
- Feature entitlements.
- Good outage behavior.
- Provider abstraction.

## Capability model

```text
AuthorScatter
ModifyScatter
UseSurfaceAnalyzer
ExportOrBake
RenderExistingScene
Feature:<name>
```

Suggested entitlement fields:
```text
Status, LicenseId, CustomerId
LicenseType: Trial | Solo | Floating | Enterprise
Ownership: Perpetual | Subscription
Features[]
MachineId
MaintenanceUntil
SubscriptionUntil
LastValidation
OfflineUntil
```

## Native architecture

```cpp
class ILicenseProvider {
public:
    virtual ~ILicenseProvider() = default;
    virtual Entitlement loadCached() = 0;
    virtual Entitlement refresh() = 0;
    virtual ActivationResult activate(const ActivationRequest&) = 0;
    virtual void deactivate() = 0;
};

class LicenseCore {
public:
    Authorization authorize(Capability, const RuntimeContext&) const;
    bool hasFeature(std::string_view) const;
};
```

Provider SDK types should not leak into scatter/edit/analyzer code.

## Enforcement points

1. `max_bridge.cpp`: authoring primitives such as `aminScatterAdvanced_cf`.
2. `cyrus_edit.cpp`: mutation commands and interactive edit sessions.
3. `cyrus_edit_stack.inc`: preserve saved-state evaluation/read-only/render behavior.
4. `CyrusSurfaceAnalyzer/src/bridge.cpp`: interactive/new analysis.
5. Export/bake path if later sold as a capability.

## Render-only policy

| Capability | Workstation | Render worker |
|---|---:|---:|
| AuthorScatter | yes | no |
| ModifyScatter | yes | no |
| Use Analyzer interactively | yes | no |
| Export/Bake | policy | no |
| RenderExistingScene | yes | yes |
| Consume interactive seat | yes | no |

Use native host/process context, not an editable MAXScript boolean.

## Perpetual + maintenance

Maintenance expiry should block **newer releases**, not stop an already-entitled perpetual build. Store release eligibility independently from local runtime/offline expiry.

## Signed entitlement

```json
{
  "product": "cyrus-scatter",
  "licenseId": "lic_...",
  "licenseKind": "perpetual-node",
  "features": ["core.scatter", "edit.native", "surface.analyzer"],
  "maintenanceUntil": "2027-09-27T23:59:59Z",
  "offlineUntil": "2026-10-27T23:59:59Z",
  "machine": {"fingerprint": "...", "policy": "provider-managed"}
}
```

The server/provider holds the private signing key. The plugin receives only public verification material.

## Online/offline

- verify cached signed state locally;
- refresh in background;
- define a grace/offline window;
- support request/response files for air-gapped machines;
- cache trusted time information to reduce simple clock rollback;
- fail authoring clearly, never destructively.

## Floating

Acquire a lease for interactive authoring sessions, release on clean exit, and rely on lease expiry after crashes. Do not acquire/release per scatter command.

## UX

Errors must explain recovery: no seat, offline authorization expired, maintenance does not cover this build, or render-only mode. Never silently alter point counts or scene data because licensing failed.
