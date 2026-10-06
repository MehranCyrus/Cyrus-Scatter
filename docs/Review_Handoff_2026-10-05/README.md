# Cyrus Scatter 0.7 — independent review handoff

<!-- CURRENT_SYSTEM_2026-10-05 -->

Preserved handoff snapshot. Later source-container/UI work and the subsequent real-scene IR finding are summarized in the [current system guide](../Current_System_2026-10-05/README.md). The unfinished UI state described below is historical, not the latest local 0.7.1 source.

5 October 2026. This is the current handoff for reviewing the local code and documentation before continuing development.

**Status: procedural 0.7 has a previously tested candidate; the subsequent command-panel layout change is unfinished. The current working tree is not the same build as the packaged candidate.** Do not interpret the earlier runtime pass as qualification of today's UI source.

## Read in this order

1. [Current state and evidence boundaries](CURRENT_STATE.md).
2. [Requirements and review matrix](REQUIREMENTS_REVIEW_MATRIX.md).
3. [Review and completion plan](REVIEW_PLAN.md).
4. [Prompt for the new conversation](HANDOFF_PROMPT.md).
5. [Procedural implementation](../Procedural_Implementation_0.7_2026-10-04/IMPLEMENTATION.md), [runtime report](../Procedural_Implementation_0.7_2026-10-04/RUNTIME_REPORT.md), and [design contracts](../Procedural_Evaluation_2026-10-04/11_OPTION_CONTRACTS.md).

The design contracts describe requirements at their dated baseline. The implementation report identifies what was implemented and deliberately gated. This handoff identifies later changes and remaining validation. Source inspection and reproducible tests must decide whether any implementation claim is correct.

## Repository and delivery boundary

- Workspace: `F:\Cursor\_Cyrus_Apps\CyrusScatter`.
- Branch at handoff: `codex/planting-groups`.
- Committed baseline: `53bfc5d1c76929958dbeb29f5d4c746b2321d0ac`.
- The procedural implementation, tests, documents and latest UI work include **uncommitted and untracked files**. Reviewing only `git diff` or only committed history misses required source.
- Unrelated licensing work is also present. Preserve `CyrusLicensing/`, `tools/licensing_lab/`, and `docs/licensing/`. It is not part of this UI change or the default procedural review scope.
- Product metadata is **0.7.0**; MAXScript serialization version is **52**. Historical 1.x labels are development history, not publication status. Keep scene class IDs and internal compatibility identifiers intact.
- No commit, push, new installer, or artist-profile installation was performed in this handoff pass.

`evidence/current-snapshot.json` records source and local artifact hashes; it is an inventory, not a passing-test certificate. Small receipts are copied under `evidence/`. SDKs, DLLs, MZPs, scenes and full private logs remain in ignored local folders.

## Immediate decision

The next conversation should first give an independent requirements/code/evidence review. Then resolve the native page visibility/order issue, verify real resizing and scrolling, qualify automatic spacing in Live mode, and rebuild matching packages. Do not add more features or claim production readiness before those findings are understood.
