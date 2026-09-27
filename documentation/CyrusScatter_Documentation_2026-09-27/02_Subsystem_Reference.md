# 02 — Subsystem Reference

## AminScatter core

`scatter.h` exposes the main placement model:
- count/seed/source weights;
- collision and relaxation;
- uniform/axis scale, rotation and movement;
- UV density;
- clustering/diversity;
- include/exclude areas;
- line/analyzer bands;
- boundary falloff;
- final cleanup/relax;
- preview sampling.

**Rule:** keep licensing out of this pure core.

## Native Max bridge

Responsibilities:
- evaluate Max nodes;
- convert to triangles;
- extract UV channel 1 when required;
- validate MAXScript inputs;
- populate `amin::Settings`;
- invoke core operations;
- convert native instances back to Max values.

**Future rule:** authorize high-value operations at bridge entry, once per operation; never contact a license server inside placement loops.

## Native preview

The preview system exists to reduce repeated MAXScript conversion/drawing overhead. Treat it as a consumer of authorized placement data. Remote license calls in preview redraw are prohibited by design.

## CS Edit

CS Edit is native and persistent. Commercial capability split:

```text
Evaluate saved edit state     allowed for scene fidelity/render
Enter interactive edit        requires ModifyScatter
Move/Rotate/Scale/Delete      requires ModifyScatter
Clone                         requires ModifyScatter
```

A license outage must not invalidate or erase existing scene edits.

## MAXScript generator/UI

Commercial UI belongs in something like:
```text
tools/ui/licensing.cjs
tools/ui/templates/licensing-ui.ms
```

MAXScript may display status and call native activation APIs. It must not contain private keys/admin tokens or be the sole enforcement point.

## PFlow/final render

The render bridge creates temporary render infrastructure from placements. A restricted render worker therefore needs `RenderExistingScene` while `AuthorScatter`, `ModifyScatter` and `ExportOrBake` remain denied.

## Surface Analyzer

`analyzer.h` defines `Mesh`, `Settings`, `Result`, `analyze`. `elements.cpp` handles connected elements and global point spacing. Tests cover mixed elements, radius/fit constraints, tilted surfaces, holes, impossible footprints and non-planar rejection.

`bridge.cpp::cyrusAnalyzeSurface_cf` is the future native Analyzer entitlement boundary.

## Installer

The current MZP/MAXScript installer is useful for development. Commercial distribution should use Autodesk's package system with explicit Max-version runtime requirements and version-specific native binaries.

## Tests

Current CTest coverage includes scatter, spacing, weights, orientation, edge-border, boundary-falloff and Analyzer tests. Add licensing tests separately so mathematical regression tests remain deterministic and provider-independent.

## Existing feature guides

The repository already includes guides for Analyzer Area, Area Falloff Graph, Boundary Falloff, Boundary Facing, CS Edit, Edge Border, Performance, Selection, Street Layout, UI and Viewport Display. They are valuable feature-history notes and should later be normalized into user-facing documentation.
