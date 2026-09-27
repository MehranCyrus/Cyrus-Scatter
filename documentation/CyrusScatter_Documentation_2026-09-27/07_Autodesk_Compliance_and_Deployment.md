# 07 — Autodesk Compliance and Deployment

## Current coupling

**VERIFIED CURRENT SYSTEM:** current CMake defaults to the 3ds Max 2026 SDK; `max_bridge.cpp` has a compile-time 2026 assertion; Surface Analyzer also links the 2026 SDK.

## Autodesk 2026

**WEB VERIFIED:** Autodesk states 3ds Max 2026 is an SDK-breaking release. Autodesk also documents the managed host move from .NET Framework 4.8 to .NET 8.

A native C++ `LicenseCore` avoids unnecessary managed-host coupling. If a future account UI uses .NET, isolate it behind version-specific host adapters.

## Autodesk 2027

Current Autodesk 2027 material describes further foundation changes including .NET Core 10, Qt 6.8 and C++20-era platform updates. Build/test a dedicated 2027 native target; do not assume the 2026 binary is compatible.

## Application Plug-in Package

Autodesk's package format uses `PackageContents.xml` with product metadata, `UpgradeCode`, version-specific `RuntimeRequirements` and `ComponentEntry` definitions. App Store distribution also uses version-specific product metadata.

Proposed layout:
```text
CyrusScatter.bundle/
├── PackageContents.xml
└── Contents/
    ├── 2026/
    │   ├── AminScatter.dlx
    │   ├── CyrusScatterEdit.dlm
    │   └── CyrusSurfaceAnalyzer.dlx
    ├── 2027/
    │   ├── AminScatter.dlx
    │   ├── CyrusScatterEdit.dlm
    │   └── CyrusSurfaceAnalyzer.dlx
    ├── Scripts/
    ├── Resources/
    └── Licensing/
```

Verify the exact module/load-order relationship on clean installations before freezing this layout.

## Scene compatibility

Do not casually rename Class IDs, serialized chunk IDs, scripted class names or globals used by old MAX files. Product-facing branding can change independently of internal compatibility identifiers.

## Code signing

Sign and timestamp commercial Windows binaries/installers. Keep the private signing credential in protected release infrastructure, never in the repository or shipped package.

## Branding

Use “Cyrus Scatter” as the product name and compatibility phrasing such as “for Autodesk 3ds Max.” Review current Autodesk trademark/Marketplace rules before listing. This document is technical planning, not legal advice.

## Release matrix

For every supported Max release test: install, native module load, create/update scatter, Analyzer, CS Edit save/reopen, preview, production render, render worker, upgrade/uninstall, activation/offline/floating and signature verification.
