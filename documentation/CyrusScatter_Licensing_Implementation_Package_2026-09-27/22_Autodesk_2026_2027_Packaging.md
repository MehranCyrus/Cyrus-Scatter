# 22 — Autodesk 3ds Max 2026/2027 Packaging

## Verified current external facts

Autodesk documents 3ds Max 2026 as an SDK-breaking release. Its SDK requirements list VS 2022/v143, .NET Core 8 and Qt 6.5.3.

Autodesk's 2027 What's New lists foundation updates including .NET Core 10, Qt 6.8 and C++20. Treat 2027 as a separate native target and test matrix.

Autodesk's Application Plug-in Package format supports `PackageContents.xml`, per-component `RuntimeRequirements`, plug-in DLL components and startup/MAXScript components.

## Recommended bundle

```text
CyrusScatter.bundle/
├─ PackageContents.xml
└─ Contents/
   ├─ 2026/
   │  ├─ AminScatter.dlx
   │  ├─ CyrusScatterEdit.dlm
   │  ├─ CyrusSurfaceAnalyzer.dlx
   │  └─ CyrusLicenseCore.dll
   ├─ 2027/
   │  └─ corresponding tested binaries
   ├─ Scripts/
   │  ├─ AminScatterObject.ms
   │  └─ CyrusSurfaceAnalyzer.ms
   └─ Resources/
```

## Migration

Current installer writes to userScripts and `Plugin.UserSettings.ini`. Commercial installer must detect/remove or disable the old registration so Max does not load both old and bundle copies.

## Licensing module loading

Test Windows DLL dependency resolution from the package layout on a clean machine. Do not assume development PATH/plugin directories match customer machines.

## Marketplace/direct distribution

The same bundle structure is useful for direct installer distribution even if you do not immediately publish through Autodesk Marketplace.
