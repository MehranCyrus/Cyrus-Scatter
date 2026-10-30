# 0.87.6.2 — viewport selection and shared controls

User-selected patch version. Preserve 0.87.6.1 placement/contact behavior and the
0.87.5.6 artistic interaction baseline. No interaction solver changes are planned.

## Delivery checklist

- [x] Shared viewport controls for selected Scatter controllers, with explicit Update and enable/disable.
- [x] Geometry picking selects the owning Scatter in ordinary object mode.
- [x] Cyrus Scatter Edit remains separate; Instances picks the displayed geometry and highlights the hovered instance.
- [x] Focused Max 2027 checks: multiple owners, Manual pending, Undo, picking depth, accepted bent/trimmed grass, moved/deleted instances and unchanged warm navigation. Scripted SDK checks; physical input and tooltip dwell remain artist acceptance.
- [x] Matching Max 2024/2026 binaries (build only) and Max 2027 qualified payload; three MZPs and one EXE; archive/hash checks.
- [x] Artist guide and exact qualification record.

Completed scope and limits: [delivery](DELIVERY.md), [qualification](QUALIFICATION.json).

## Ownership and boundaries

Picking reads the last complete retained display, never source nodes or pending
recipes. Native code owns triangle/instance queries and temporary acceleration.
Derived picking data is transient, shared with immutable display geometry where
possible, and bounded by viewport memory admission. Hover changes only presentation.
Stable published placement identities connect hits to Edit rows; row order alone
is not identity. Selection does not change authored transforms. Existing Edit Undo
continues to own transformations and deletion.

Shared controls capture an explicit list of controllers, apply only the edited
property, use one Undo action, and reuse normal display-only update paths. Explicit
Update is the only batch action that consumes pending Manual placement changes.
Selection changes must not reopen/rebuild every rollout or recalculate scatter.

Tests use disposable profiles/scenes and Max 2027. Older host execution, physical
mouse latency and arbitrary renderer behavior are not implied by SDK builds.
Artist scenes and installed profiles remain untouched. No Git push or website
deployment is included in this request.
