# 00 — Executive Plan

## Current verified architecture that drives licensing

Cyrus Scatter already has the right separation for commercial licensing:
- host-independent C++ scatter core;
- native Max bridge;
- native preview;
- native CS Edit with persistent scene state;
- separate native Surface Analyzer core/bridge;
- generated MAXScript UI/orchestration;
- PFlow render transport.

The licensing project is therefore an integration project, not a rewrite.

## Implementation order

### Gate 0 — baseline safety
Before licensing code:
1. keep the pre-licensing Git tag/commit;
2. make repository private if proprietary;
3. run secret/history scan;
4. build Release and execute current CTests;
5. load on clean Max 2026;
6. archive representative old scenes and expected counts/transforms;
7. centralize release version/date metadata.

### Gate 1 — provider-independent licensing core
Create:
- `CyrusLicenseCore.dll`;
- capability model;
- entitlement snapshot;
- `RuntimeContext`;
- `ILicenseProvider`;
- `FakeLicenseProvider`;
- signed/local state interface;
- policy tests.

No real provider yet.

### Gate 2 — native enforcement
Integrate checks at:
- scatter authoring entry;
- CS Edit mutation;
- Surface Analyzer interactive analysis;
- bake/export;
- restricted render evaluation.

### Gate 3 — generated UI
Add license UI through the generator, not by editing `AminScatterObject.ms` manually.

### Gate 4 — vendor POCs
Implement Cryptlex and Keygen adapters independently. Run identical acceptance tests.

### Gate 5 — commerce/provisioning
Connect checkout/MoR webhooks to a Cyrus provisioning service, then to the chosen licensing provider's management API.

### Gate 6 — render/offline/studio validation
Prove:
- interactive render;
- command-line render;
- Deadline/target farm;
- Corona IR;
- hosted floating;
- on-prem/offline;
- provider outage/grace.

### Gate 7 — packaging/signing
Max 2026/2027 builds, Application Plug-in Package, Authenticode, protected release CI.

### Gate 8 — commercial beta
Small controlled cohort before broad release.

## Do not do first

- do not buy/integrate a provider directly into every module;
- do not virtualize/obfuscate the whole plugin;
- do not make MAXScript the license authority;
- do not make render nodes consume normal authoring seats;
- do not make perpetual licenses depend on constant internet access;
- do not change Class IDs, chunk IDs or scene schema as part of licensing.
