# 22 — Autodesk Deployment and Max-Version Strategy

## Current source

Current native code is explicitly Max 2026-targeted. `max_bridge.cpp` asserts `MAX_PRODUCT_YEAR_NUMBER == 2026`.

## Autodesk 2026 facts

Autodesk's current SDK documentation says 3ds Max 2026 is an SDK-breaking release and 2025 plug-ins need recompilation. Autodesk lists VS 2022/v143 and .NET Core 8 for 2026.

## Autodesk 2027 facts

Autodesk's current 2027 What's New lists foundation updates including .NET Core 10, Qt 6.8 and C++20. Treat 2027 as a dedicated build/test target.

## Application Plug-in Package

Autodesk documents `PackageContents.xml` with:
- `AutodeskProduct="3ds Max"`;
- `ProductType="Application"`;
- `AppVersion`;
- stable `UpgradeCode`;
- `RuntimeRequirements` per component/version;
- `ComponentEntry`.

Recommended future structure:

```text
CyrusScatter.bundle/
├─ PackageContents.xml
└─ Contents/
   ├─ 2026/ native modules
   ├─ 2027/ native modules
   ├─ Scripts/
   ├─ Resources/
   └─ Licensing/
```

## Migration concern

The current userScripts/Plugin.UserSettings.ini installation may coexist with a new ApplicationPlugins bundle if not removed. Commercial installer must detect/migrate the old install to avoid duplicate class/plugin loading.

## Official references

- https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/what_s_new/whats_new_3dsmax_2026_sdk.html
- https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/about_the_3ds_max_sdk/sdk_requirements.html
- https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-Developer/files/writing_plug-ins/plugin_package/packagexml_format.html
- https://help.autodesk.com/cloudhelp/2023/ENU/Max-Developer-Help/writing_plug-ins/plugin_package/packaging_plugins.html
