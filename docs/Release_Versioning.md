# Release and saved-data versioning

| Domain | Current value | Meaning |
| --- | --- | --- |
| Scatter UI | 0.84.0 | Selectable density mapping; qualification in P04 |
| Scatter native/package | 0.84.0 native candidate / 0.81.6 installed | Matched private P04 builds; no new package or normal installation |
| Saved MAXScript schema | 58 | Independent saved Band scale profiles; current-only scenes, no earlier-schema migration |
| Calculation model | CyrusUnified1 | Current procedural model |
| Surface Analyzer | 0.14 | Independently versioned product |
| MCP package / closed plan | 0.73.0 / 0.73 | Automation contract, not the Scatter UI version |

**Reserve 1.0 for publication readiness.** Earlier artifacts labeled 1.0.x, 1.1.x and 1.2.x were development checkpoints, later relabeled 0.7 onward. A larger-looking historical version is not a newer supported release.

## Choosing the next version

Use three integer components, `MAJOR.MINOR.PATCH`, for new Scatter deliveries. Versions are ordered labels, not decimal numbers: `0.80.0` to `0.81.0` increments the minor component once; `0.80.0` to `0.90.0` skips nine minor labels. Assess the complete change since the last delivered build before selecting a version. Artist-visible capability, changed behavior contracts and saved-data requirements determine the choice; time spent, lines changed and file counts do not determine it alone.

| Delivered change | Version decision | Example from 0.80.0 |
| --- | --- | --- |
| Documentation, tests or internal refactoring with no delivered behavior or package change | No product bump | Remain 0.80.0 |
| Bounded bug fix, UI correction or performance improvement preserving the intended behavior and saved-data contract | Next patch | 0.80.1 |
| New coherent feature, substantial artist workflow, or intentional behavior/saved-data contract change | Next minor; reset patch to zero | 0.81.0 |
| Larger named product milestone | Normally next minor; use a larger jump only when explicitly selected in the agreed roadmap, with a recorded reason | 0.90.0 only as a deliberate milestone |
| Publication readiness | 1.0.0 only after the release acceptance gates are met | Never inferred from work volume |

For a mixed delivery, use the highest-impact applicable category. For example, Band/falloff capabilities and a changed saved schema justify a minor development milestone; a subsequent first-click or hover fix normally warrants a patch. These rules apply to future deliveries; do not rename the existing 0.80.0 packages or historical receipts.

Development versions before 1.0 do not promise compatibility with earlier scenes. Record deliberate current-only schema changes and their artist consequences; a version bump does not authorize migration shims or legacy paths. Schema/interface identifiers change only when their contracts change. Analyzer, MCP and the website's own package version remain independent of Scatter.

Before changing version metadata, record the current and proposed versions, a short impact-based reason, affected version domains and remaining acceptance in the existing plan, handoff or changelog. This does not require a new document for every fix. A privately iterated, undelivered candidate may retain its planned version with distinct build fingerprints. Once a package has been delivered, give a changed successor a new patch or minor version and preserve the old package identity. A version label never replaces exact hashes or proves qualification.

When a bump is within the authorized task, align the Scatter UI template and generated script, native/package metadata, installer labels, coupled catalog assertions, current navigation and changelog. Follow the [agent workflow](AGENT_WORKFLOW.md) for generation and proportionate checks; do not bump unrelated products mechanically. For artist-visible changes, keep the guide, relevant website chapters/control explanations and changelog aligned with proven behavior and run the website import checks when those sources change. Report local source updates, built website artifacts and live deployment separately. Version selection itself does not authorize packaging, installation or publication.

## Current and historical evidence

0.84.0 adds selectable UV channels and density-map resolution with per-layer bake
reuse. This new artist feature warrants a minor version. Schema 58 keeps channel 1
and 128-square defaults. Density capability 1 and the twelve-field generation
options require matching native/script bytes. See [P04](plans/eleven-phase-roadmap/P04.md).

0.82.0 is the next minor for named population, transform, spacing and curve
presets. Format/codec 1 is new; schema 58 and the existing native interfaces are
unchanged. Typed local files, physical-unit conversion and one-Undo Apply are
covered by the [P02 record](plans/eleven-phase-roadmap/P02.md). This is a source
checkpoint, with final artist acceptance pending and no new installation.


0.81.8 is a patch for workflow and cached-result feedback. It distinguishes
accepted placements from prepared display samples, identifies the named layer,
and corrects the generated callback guard and first-result status. Placement
policy, schema 58 and native interfaces remain unchanged. The [Phase 1 record](plans/eleven-phase-roadmap/P01.md)
tracks exact iterations, passing evidence and remaining acceptance. This source
version does not establish phase completion, a package or installation.

0.81.7 is a patch for zero-limit Point Cloud transitions and memory accumulation
during repeated display-mode changes. Saved schema 58, placement policy, Band
interface 10 and publication interface 2 are unchanged. Native viewport policy
capability 2 exposes the resource-derived point preparation capacity. See the
[investigation and qualification](plans/terrace-0815/VIEWPORT_0817.md); package
and normal installation remain the preceding 0.81.6 delivery.

0.81.6 is explicitly selected by the user for navigating/idle display limits and
Mesh fallback correction. The new viewport capability would ordinarily warrant
a minor version; the requested label takes precedence. Additive settings retain
schema 58, Band interface 10 and publication interface 2. Matched scripts require
viewport policy capability 1. Analyzer and MCP versions remain unchanged. See the
[viewport implementation and scoped evidence](plans/terrace-0815/VIEWPORT_0816.md).
The subsequent authorized [package and installation record](plans/terrace-0815/INSTALLATION_0816.md)
pins the same tested bytes, normal-profile backups and loaded native paths.

0.81.5 is explicitly selected by the user for the terrace production-scene work.
The expanded candidate/identity bound would ordinarily warrant a minor change;
the requested label takes precedence. Existing receiver IDs remain stable through
paged ordinals; schema 58 and publication interface 2 remain unchanged, and the
Band/native requirement advances to 10 for the larger supported candidate range.
Compact rectangle selection, bounded point staging and the render source-frame
correction are included. See the [current evidence](plans/terrace-0815/PROGRESS.md)
for exact builds and acceptance. Analyzer and MCP versions remain independent.

0.81.3 is the requested patch for unchanged-layer preview reuse, prepared density
curve evaluation and scale-profile memory accounting. Placement policy, saved
schema 58, Band interface 9 and publication interface 2 remain unchanged. The
script also requires the new preview-comparison primitives from its matched
native package. Build/package/install are authorized; tests and Max execution
are explicitly deferred to the user's manual acceptance. Earlier test results
do not qualify this patch.

0.81.2 is the requested bounded UI/assignment correction: Scale moves directly
below density and Band membership supports click-to-toggle, including none.
Saved schema 58 and native Band interface 9 remain unchanged. Existing 0.81.1
setups retain their authored records; no migration or compatibility path is added.


0.81.1 is explicitly selected by the user for Band scale profiles. This feature
would ordinarily qualify for a minor bump under the default policy; the requested
label takes precedence. Saved schema advances to 58 and native Band interface to 9
for the additional authored fields and 15-field transport. Analyzer, licensing and
MCP versions are unchanged. Retain 0.81.0 installers for original schema-57 scenes.
The [0.81.1 delivery](plans/spline-bands/INSTALLATION.md) records both installed
Max years and their verified hashes. Restart normal Max sessions to load this pair;
fresh normal-profile and physical artist acceptance remain pending.


The 0.80.0 → 0.81.0 development minor is selected for removal of the optional editing workflow and addition of model-to-Point conversion. Schema 57 and native interface contracts stay unchanged. See the [implementation record](plans/spline-bands/PROGRESS.md) for automated checks and remaining host acceptance. The subsequent authorized [local delivery](plans/spline-bands/INSTALLATION.md) installs this exact qualified pair on disk; fresh normal-profile acceptance remains pending.

Historical 0.81.0 source and scoped Max 2026/2027 evidence are recorded in the [Bands implementation record](plans/spline-bands/PROGRESS.md). Schema 57 retains typed distances and removes old migration handlers and placement readers. Native Band interface 8 and procedural publication 2 require a matched script/native pair. The [0.81.0 local delivery](plans/spline-bands/INSTALLATION.md) records package and installed identities, backups and pending fresh-launch acceptance. The [0.79.6 foundation correction](Foundation_0.79.6_2026-10-12/README.md), older metadata-only and team-pilot notes below remain historical.

0.79 begins the [offline team licensing pilot](licensing/ROADMAP.md#079-offline-team-pilot): owner-issued licenses, 30 days from issuance, creation/editing locked without valid authority, and existing scenes loadable/renderable. The initial version bump changes no enforcement or saved format. The subsequent [coding loop](licensing/TEAM_PILOT_0.79_2026-10-11.md) implements the team pilot and records fresh matched Max 2026/2027 builds. Do not relabel the earlier 0.78.3 artifacts as 0.79.

Version-bump checks on 11 October 2026 passed: generator reproducibility/integration, approved layout guards, four catalog/package-version tests, package metadata consistency and `git diff --check`. The integration receipt is local at `build/licensing-079-preflight-20261011-01/generated/generated-check.json`. No 0.79 native build, Max runtime test, package, artist installation or new licensing-runtime qualification was performed in this metadata/plan update.

Preserve internal class IDs and registration names. A caption or matching schema number is not enough to establish a coherent installation: record exact script/payload fingerprint, native hashes, loaded paths and package identity. Never combine new scripts with stale loaded native modules.

0.78 deliberately changes the saved schema and native brush payload. Older development setups and stroke documents are rejected without conversion or compatibility evaluation. Start new scenes/setups; preserve original files and the matching old build. General receiver-local sampling and stable Edit identities remain part of the current engine.

Before delivery, regenerate UI, run appropriate offline/native/host checks, package the tested pair, verify archive contents and hashes, and record remaining gates. Installer execution and host restart need their own qualification. SDK coverage does not certify Max runtime. Use [current acceptance](BACKLOG.md), [build instructions](Max_2027_Installation.md), and [the latest matched package receipts](Container_and_Radius_0.78.3_2026-10-10/README.md). The 0.78 vector payload and script schema are deliberately new. The independent Analyzer freshness format remains unchanged; older Analyzer guides need one explicit Analyze. The dated manifest identifies the exact payload.

0.78.2 removed repeated brush panel layout and refreshed borders from Painter input callbacks. 0.78.3 preserves those changes, corrects cursor radius, repairs source-container selection, adds collection switches and unfolds Painting controls. Schema 55 and the vector payload remain unchanged. The new source-container flag defaults off, including in older saved rectangles without that flag. Separate Max 2026 and 2027 binaries/installers are required.

- **0.79.1**: Point identities and direct spline assignment, separate source-container section, accessible source/falloff controls and area-selection fixes. Retains schema 55 and the 0.79 team licensing authority; Analyzer 0.14 and MCP 0.73.0 are independently versioned. See the [focused qualification](Point_Workflow_0.79.1_2026-10-11/README.md).

## P03 development decision — 14 October 2026

0.82.0 to 0.83.0 adds per-layer slope/altitude eligibility and inside fades, with
protected Edit behavior and independent random thinning. This coherent feature
warrants a minor version. Saved schema 58 and existing interfaces retain their
meaning; new neutral fields and native surface-filter capability 1 are added.
Independent products and the normal installed 0.81.6 package are unchanged.
See [P03](plans/eleven-phase-roadmap/P03.md) for exact evidence and limits.
