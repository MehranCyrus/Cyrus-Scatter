# 15 — Persistence, Compatibility, and Identifiers

## Scripted object IDs

Cyrus Scatter:
- internal scripted class: `AminScatterObject`;
- Class ID: `#(0x617d43a1,0x395c2e17)`;
- generated class version: 44.

Surface Analyzer:
- class: `CyrusSurfaceAnalyzer`;
- Class ID: `#(0x45a201c7,0x1829bc63)`;
- class version: 13.

CS Edit:
- Class ID: `Class_ID(0x43b612e9,0x578124cd)`;
- internal name: `CyrusScatterEdit`.

## CS Edit chunks

- legacy reader: `0x3901`;
- current stable-identity chunk: `0x4001`.

These are serialized scene compatibility identifiers.

## Callback IDs

Scatter:
- `#AminScatterAutoRender`;
- `#CyrusPFBridge`;
- `#AminScatterLayers`;
- `#CyrusScatterIconColor`.

Analyzer:
- `#CyrusAnalyzerRealtime`;
- `#CyrusAnalyzerIconColor`.

## User properties / naming

- baked ownership: `AminScatterOwner`;
- transient render nodes: `CyrusPFTransient`;
- transient PFlow names begin `Cyrus_Render_`;
- proxy prototype name `Cyrus_Render_ProxyPrototype`.

## Scene data

Most Scatter feature state is stored as scripted-plugin parameters, including nested layer objects and tab parameters. CS Edit stores native modifier data in chunks. Analyzer stores flattened boundary/path/sample arrays in scripted parameters.

## Compatibility rules

Do not casually change:
- Class IDs;
- internal scripted class names;
- native modifier internal name;
- serialized chunk IDs/layout;
- parameter names/types;
- layer migration semantics;
- callback IDs without removing old registrations;
- user-property conventions used for cleanup;
- accepted native primitive signatures used by older generated scripts.

## Branding

Product-facing strings can say Cyrus Scatter while legacy internal `AminScatter` identifiers remain. A broad rename would create unnecessary saved-scene risk.
