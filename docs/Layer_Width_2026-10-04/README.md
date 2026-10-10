# Cyrus Scatter 1.2.1 — full-width native layers

> Historical implementation record. For the current product use [the documentation index](../README.md) and [backlog](../BACKLOG.md). Measurements and instructions below apply to their recorded build.

4 October 2026. UI-only patch to the [1.2.0 release](../Layers_First_2026-10-03/REPORT.md).

Layout superseded by [1.2.2's classic flowing stack](../Classic_Layout_2026-10-04/README.md). The artist rejected the fixed container arrangement despite the width correction. The measurements below remain evidence for this earlier patch.

The Layers body previously measured 162 px inside a 248 px native frame. Nested layer settings reduced the usable space again. Explicit control widths and disabled native automatic layout caused the narrow centered column; it was not a scatter calculation or cache problem.

## Changes

- Enable Max's `autoLayoutOnResize` on the Layers host, layer panels and their section containers/editors.
- Express container and control widths relative to their own rollout. Retain small native margins and scrollbar space.
- Expand paired buttons and Randomize Min/Max fields into balanced columns. Keep axis labels fixed. The Analyzer-specific single-button layout follows the same width rules.
- Preserve fixed scrolling-area heights, lazy editor creation, control identities, owner bindings and cached statistics. Add no polling, window hooks, repaint suppression or scene-generation requests.
- Publish version 1.2.1; persisted class version remains 51. The four native binaries for each Max year are byte-identical to 1.2.0. MCP remains 1.1.0.

The authoritative changes are in `AminScatter/tools/ui/layers-first.cjs` and the `layers-first-host.ms` / `layers-first-panel.ms` templates. Regenerate from `AminScatter` with `node tools/ui/generate.cjs`.

## Verification and limits

The final source was loaded in a fresh, disposable Max 2027.1 profile, using the existing saved 1.2 demo. At the normal panel width:

| Check | Result |
| --- | --- |
| Native frame / Layers body | 248 / 246 px |
| Layer body | 234 px with outer scrolling space |
| Settings body | 222–232 px, depending on its native scrollbar |
| Visible native control-component bounds | 618 checks passed across both layers |
| Section open/close actions | 40 passed; outer dimensions and control handles retained |
| Placement generation, paint evaluation and retained display uploads | No increase from section toggles |

The native screenshots were inspected at normal panel width. A live wider-panel drag was not completed because the computer-use helper reported intervening input; no wider-panel or different-DPI result is claimed. The layout uses Autodesk's resize mechanism, but those configurations remain artist QA. The patch does not repeat the prior engine/MCP/renderer matrix: those paths were unchanged. Max 2026 installers contain the matching previously qualified native binaries; Max 2026 interactive testing remains outstanding.

Raw fixture failures while developing the diagnostic concerned top-level MAXScript local scope and reading a spinner's unavailable `.width` property. The final bounds check reads actual HWND rectangles for every visible component, including spinner labels/fields/arrows. Final acceptance and source/package identities are in [evidence](evidence/MANIFEST.json); older release evidence is preserved.

## Use and reproduce

Install the matching MZP from `dist/layers-first-1.2.1` using **Scripting > Run Script**, then restart Max. Existing scenes and the 1.2 demo use the wider layout automatically. The optional MCP package needs no update for this UI patch.

For a new private run, use a name beginning `layers-width`, load `dist/layers-first-1.2.0/Cyrus_Scatter_1.2_Layers_Demo.max` with `tools/v1/launch.py`, then submit `layers_width_probe.ms` and `layers_width_acceptance.ms` through `tools/v1/request.py`. These fixtures are development-only and never shipped in the installer. `collect_width_evidence.py` verifies this patch against the frozen 1.2.0 packages and assembles its handoff notes.

## API basis

Autodesk documents native automatic layout for resizable command-panel content in the [2019 layout additions](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/What-is-New-in-MAXScript/What-was-New-in-MAXScript-in/GUID-0890917F-5AC9-4E01-B860-0095172B48A9.html). Subrollouts expose their own [width and automatic-layout options](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-CDE5B06D-4BB4-4DEA-96C1-6BAB98709F09.html). Assigning a rollout's `.width` after creation does nothing when hosted in a command panel or subrollout, as described in [rollout properties](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.html); this patch therefore uses layout expressions at declaration time.
