# 02 — Product SKUs, Capabilities, and Entitlements

## Capabilities

```cpp
enum class Capability {
    OpenLicenseUI,
    AuthorScatter,
    ModifyScatter,
    UseSurfaceAnalyzer,
    ExportOrBake,
    RenderExistingScene,
    EvaluateSavedEditState,
    EvaluateSavedAnalyzerData
};
```

## Feature entitlements

Keep commercial capabilities separate from feature flags.

Suggested feature keys:
- `core.scatter`
- `edit.native`
- `surface.analyzer`
- `advanced.edge`
- `advanced.falloff`
- `render.existing_scene`

Do not initially create dozens of micro-entitlements. Start coarse and split only if the product plan needs tiers.

## SKU model

| SKU | Author | CS Edit | Analyzer | Bake/export | Render existing | Seat model |
|---|---:|---:|---:|---:|---:|---|
| Trial | yes | yes | yes | yes | yes | node-locked, 30 days |
| Solo Perpetual | yes | yes | yes | yes | yes | node-locked |
| Studio Floating | yes | yes | yes | yes | yes | concurrent authoring |
| Render Worker | no | no mutation | only required evaluation | no | yes | free/restricted |
| Unlicensed Viewer | no | no mutation | no new analysis | no | saved-state fidelity only | none |

## Recommended Solo default

- one active authoring machine;
- self-service online deactivate;
- support-assisted recovery for dead machines;
- 12 months maintenance from purchase/license creation;
- perpetual use of releases published within maintenance.

Whether to sell a two-machine Solo license is a commercial decision, not an architectural requirement.

## Studio

Hosted floating for internet-connected studios. On-prem floating is an enterprise/air-gap option. Borrowed seats remain seats; do not present borrowing as free render capacity.

## Scene safety rule

A capability failure must never rewrite saved parameters, delete CS Edit records, alter Class IDs, or intentionally produce a different scatter to punish the user.
