# Release and saved-data versioning

| Domain | Current value | Meaning |
| --- | --- | --- |
| Scatter UI | 0.82.4 | User-selected mesh channel mask and Paint help successor; Phase 6 remains paused |
| Scatter native/package | 0.82.4 packaged for Max 2027; historical installation receipts preserved | Package hashes and scoped Max 2027 qualification are in the mesh mask handoff; manual installation is separate |
| Saved MAXScript schema | 58 | Independent saved Band scale profiles; current-only scenes, no earlier-schema migration |
| Calculation model | CyrusUnified1 | Current procedural model |
| Surface Analyzer | 0.14 | Independently versioned product |
| MCP package / closed plan | 0.73.0 / 0.73 | Automation contract, not the Scatter UI version |

**Reserve 1.0 for publication readiness.** Earlier artifacts labeled 1.0.x, 1.1.x and 1.2.x were development checkpoints, later relabeled 0.7 onward. A larger-looking historical version is not a newer supported release.

## Choosing the next version

Use three integer components, `0.MINOR.PATCH`, with the user's **small-step
development sequence**. Advance PATCH by one through 9; after PATCH 9, advance
MINOR by one and reset PATCH to 0. Example: `0.81.8 → 0.81.9 → 0.82.0 → 0.82.1`.
New features follow this same sequence. Do not jump to the next minor solely
because a phase adds a feature. Larger jumps require an explicit user-selected
milestone. This rule supersedes the earlier feature-based minor-bump policy.

| Delivered change | Version decision | Example |
| --- | --- | --- |
| Documentation/tests only, without a changed delivery | No product bump | Remain 0.82.2 |
| Fix, performance improvement or new feature delivery | Next small step | 0.82.2 → 0.82.3 |
| Last PATCH digit is 9 | Carry into the next MINOR | 0.82.9 → 0.83.0 |
| Larger named product milestone | Explicit user-selected label and recorded reason | No automatic jump |
| Publication readiness | 1.0.0 only after the release acceptance gates are met | Never inferred from work volume |

Assess and record the full delivery's behavior and saved-data impact separately
from its version increment. Schema/native capability changes use their own
identifiers. Preserve original package names, Git commits, hashes and test
receipts when correcting development labels.

Development versions before 1.0 do not promise compatibility with earlier scenes. Record deliberate current-only schema changes and their artist consequences; a version bump does not authorize migration shims or legacy paths. Schema/interface identifiers change only when their contracts change. Analyzer, MCP and the website's own package version remain independent of Scatter.

Before changing version metadata, record the current and proposed versions, a short impact-based reason, affected version domains and remaining acceptance in the existing plan, handoff or changelog. This does not require a new document for every fix. A privately iterated, undelivered candidate may retain its planned version with distinct build fingerprints. Once a package has been delivered, give a changed successor a new patch or minor version and preserve the old package identity. A version label never replaces exact hashes or proves qualification.

When a bump is within the authorized task, align the Scatter UI template and generated script, native/package metadata, installer labels, coupled catalog assertions, current navigation and changelog. Follow the [agent workflow](AGENT_WORKFLOW.md) for generation and proportionate checks; do not bump unrelated products mechanically. For artist-visible changes, keep the guide, relevant website chapters/control explanations and changelog aligned with proven behavior and run the website import checks when those sources change. Report local source updates, built website artifacts and live deployment separately. Version selection itself does not authorize packaging, installation or publication.

## Current and historical evidence

The user selected **0.82.4** on 15 October for mesh channel density and Paint
tooltips. This is a separate feature delivery while Phase 6 stays paused. It adds
neutral, layer-owned saved fields and native mesh-density capability 1, retaining
schema 58, registration identities, Edit geometry bindings and independent product
versions. See the [mask handoff](plans/eleven-phase-roadmap/MESH_MASK_0824.md) for
exact inputs, Max 2027 tests and the runnable package. P06-P11 now plan
0.82.5-0.83.0. No normal-profile installation is part of this task.

The user selected **0.82.3** on 14 October for the idle, interaction and panel
performance correction. At that delivery, planned P06-P11 labels shifted to
0.82.4-0.82.9; the later mask delivery supersedes that schedule. Saved schema 58, calculation policy and
independently versioned products remain unchanged. See the
[performance handoff](plans/eleven-phase-roadmap/PERFORMANCE_0823.md) for exact
qualification and the subsequent verified installer. The 0.82.3 package is ready
for the user to run; this task did not replace the normal 0.82.2 installation.

The user confirmed on 14 October 2026 that Phase 1 starts at **0.81.8**, following
the separately recorded 0.81.7 viewport correction. Phase 5 therefore becomes
**0.82.2**. This correction changes labels and metadata; the five implemented
feature scopes and schema 58 remain unchanged. See the mapping below and
[P05](plans/eleven-phase-roadmap/P05.md) for the new compilation receipt.

## Eleven-phase numbering

| Phase | Corrected version | Feature | Original qualified label / status |
| --- | --- | --- | --- |
| P01 | 0.81.8 | Workflow and feedback | 0.81.8; implemented |
| P02 | 0.81.9 | Settings and curve presets | 0.82.0; implemented |
| P03 | 0.82.0 | Slope and altitude | 0.83.0; implemented |
| P04 | 0.82.1 | Density map controls | 0.84.0; implemented |
| P05 | 0.82.2 | Paint/spline conversion | 0.85.0; implemented |
| P06 | 0.82.5 | Regular grids | Planned; implementation paused |
| P07 | 0.82.6 | Direction controls | Planned |
| P08 | 0.82.7 | Paths, sequences and references | Planned |
| P09 | 0.82.8 | Transform and assignment maps | Planned |
| P10 | 0.82.9 | Recipes and browser | Planned |
| P11 | 0.83.0 | Adaptive viewport completion | Planned |

Future labels are planned checkpoints, not completed releases. Record a revised
schedule if an additional delivery consumes a step. Original qualified labels
remain on their existing receipts, builds and commits; identify them by phase and
hash because a corrected label can overlap an earlier phase's original label.
The preceding 0.82.2 source was rebuilt, packaged and installed on disk for Max 2027
only; see the [delivery record](plans/eleven-phase-roadmap/INSTALLATION_0822.md).
Restart Max 2027 to load the complete new pair. Max 2026 retains 0.81.6, and
independently versioned products are unchanged.

## Earlier development evidence

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

## Original P03 development decision — superseded numbering, 14 October 2026

0.82.0 to 0.83.0 adds per-layer slope/altitude eligibility and inside fades, with
protected Edit behavior and independent random thinning. This coherent feature
warrants a minor version. Saved schema 58 and existing interfaces retain their
meaning; new neutral fields and native surface-filter capability 1 are added.
Independent products and the normal installed 0.81.6 package are unchanged.
See [P03](plans/eleven-phase-roadmap/P03.md) for exact evidence and limits.
