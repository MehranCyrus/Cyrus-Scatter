# 08 — Appendices and Reference Schemas

## Entitlement example

```json
{
  "schema": 1,
  "product": "cyrus-scatter",
  "licenseId": "lic_example",
  "customerId": "cus_example",
  "type": "solo",
  "ownership": "perpetual",
  "features": ["core.scatter", "edit.native", "surface.analyzer"],
  "maintenanceUntil": "2027-09-27T23:59:59Z",
  "subscriptionUntil": null,
  "offlineUntil": "2026-10-27T23:59:59Z",
  "machine": {"id": "provider-managed", "policy": "provider-managed"},
  "issuedAt": "2026-09-27T00:00:00Z"
}
```

## LicenseCore sketch

```cpp
enum class Capability {
    AuthorScatter,
    ModifyScatter,
    UseSurfaceAnalyzer,
    ExportOrBake,
    RenderExistingScene
};

struct RuntimeContext {
    bool isNetworkRenderServer{};
    bool isInteractive{true};
    bool isCommandLine{};
    OperationPurpose purpose{};
};

class LicenseCore {
public:
    LicenseStatus status() const;
    Authorization authorize(Capability, const RuntimeContext&) const;
    bool hasFeature(std::string_view) const;
};
```

## Version source

```json
{
  "productId": "cyrus-scatter",
  "displayName": "Cyrus Scatter",
  "version": "1.0.0",
  "releaseDate": "2026-10-15",
  "supported3dsMax": [2026, 2027]
}
```

## Secret policy

Never commit/ship:
- license-signing private key;
- Authenticode private key/PFX;
- provider management/admin token;
- MoR webhook secret in client code;
- DB/CI deployment credentials.

Safe when designed correctly:
- public verification key;
- client-safe product/account IDs;
- provider client SDK;
- API base URL;
- entitlement schema.

## Current .gitignore coverage

The repository ignores `.env`, `secrets/`, `private/`, `*.pem`, `*.pfx`, `*.p12`, `*.key`, `certificates/`, `signing/` and local config patterns.

## Security test matrix

| Test | Expected |
|---|---|
| patch MAXScript “licensed” state | native authoring still denies |
| copy cache to another machine | binding rejects |
| temporary network outage | cached/grace state works |
| outage beyond offline window | clear authoring denial |
| rollback clock | anomaly/refresh policy |
| kill floating client | lease eventually returns |
| no floating seats | scene safe, authoring denied |
| render worker without seat | existing scene renders |
| render worker tries authoring | denied |
| old perpetual build after maintenance expiry | works |
| newer build after maintenance expiry | upgrade denied |
| tampered entitlement | signature fails |
