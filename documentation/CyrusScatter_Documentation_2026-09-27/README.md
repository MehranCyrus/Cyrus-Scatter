# Cyrus Scatter Documentation Package

Snapshot: **2026-09-27**  
Audited code baseline: `main` / `b9a9e909b469456a6193337363b7c50b2397e549`

This package reconstructs the multi-file documentation set recorded in the previous Cyrus Scatter research report, then checks the current-system claims against the actual repository.

## Reading order

1. `00_Executive_Summary.md`
2. `01_Project_Overview_and_Architecture.md`
3. `02_Subsystem_Reference.md`
4. `03_Licensing_Design.md`
5. `04_Anti_Tamper_and_Practical_Hardening.md`
6. `05_Provider_Evaluation.md`
7. `06_Implementation_Roadmap.md`
8. `07_Autodesk_Compliance_and_Deployment.md`
9. `08_Appendices_and_Reference_Schemas.md`
10. `09_Codebase_Audit_Log.md`
11. `10_Sources_and_Provenance.md`

Standalone Mermaid sources are under `diagrams/`.

## Evidence labels

- **VERIFIED CURRENT SYSTEM**: directly supported by the audited repository.
- **RECOVERED RESEARCH**: retained from the earlier research package.
- **WEB VERIFIED 2026-09-27**: checked against current official vendor/Autodesk material.
- **RECOMMENDATION**: future design; not yet implemented.

## Core finding

Cyrus Scatter is already a hybrid native product. The scatter algorithm is a host-independent C++17 library; 3ds Max integration is a native bridge; preview caching and CS Edit are native; Surface Analyzer has its own native engine and bridge; MAXScript primarily handles scene state, UI and orchestration. Commercial licensing can therefore be added around native host-facing boundaries without rewriting the scatter engine.

## Important operational note

GitHub reported `MehranCyrus/Cyrus-Scatter` as **public** during this reconstruction. If proprietary source was not meant to be public, change visibility and review exposure history. The current `.gitignore` excludes common private-key, certificate and secret patterns, but repository visibility remains a separate concern.

This is a static architecture/security review. It does not claim that CTest, 3ds Max, renderer farms or penetration tests were executed during reconstruction.
