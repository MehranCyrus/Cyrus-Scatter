# Repository Guidelines

## Start with current evidence

Read [README.md](README.md), its current handoff, and [the agent workflow](docs/AGENT_WORKFLOW.md). At creation (7 October 2026), the baseline is compact **0.73** plus the Layer Actions correction. This is not release certification. Recheck branch, HEAD, tracked diff and untracked files; reports never substitute for source inspection. Follow the user's current scope and authorization; a roadmap does not authorize every future task.

## Project Structure & Module Organization

- `AminScatter/` combines native C++ calculation/display with generated MAXScript orchestration/UI. Edit `tools/ui/templates/unified-core.ms` and the relevant generator modules under that project; never fix only `scripts/AminScatterObject.ms`.
- `CyrusSurfaceAnalyzer/` is independently versioned. `CyrusMCP/` provides bounded host automation; its catalog describes more than its write API supports. `CyrusLicensing/` is a separate, default-off foundation.
- `docs/` holds contracts and dated evidence. `website/` imports artist documentation; its examples illustrate behavior and do not execute the plugin.

## Engineering contracts

Preserve ordered layers/paint sets, stable identities, independent collision scopes, explicit setting ownership, bounded work and atomic publication. Failed successors retain the previous complete result. Keep host API access/publication on the host thread; workers consume copied data.

Browsing, selection and unrelated animation must not rebuild static placements or re-upload unchanged buffers. Manual pending edits wait for explicit Update; Live responds to relevant dependencies, including relevant animation. Preserve retained Mesh/Point Cloud behavior. UI views bind the same model; capture valid owners across callbacks that rebuild controls.

## Build, Test, and Development Commands

From the repository root:

```powershell
python tools/procedural_lab/check_generated.py --output build/agent-review/generated
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q
python tools/procedural_lab/offline_build.py --project scatter --output build/agent-review/scatter
```

These require the documented local toolchain. Choose fresh run directories and checks appropriate to the change; see the workflow for generation, focused tests, Analyzer and host qualification. Offline passes do not prove Max UI, rendering or presented FPS.

## Preservation and delivery

Use owned disposable profiles/scenes for tests. Preserve `Test Scene/`, artist profiles, unrelated licensing work and existing changes. Verify source/package/loaded identities before Max testing; version captions are insufficient. Never mix new scripts with stale native modules.

Keep current navigation and artist docs aligned with proven changes; preserve historical receipts. Do not restore retired unpublished compatibility or add abstraction/GPU work without a demonstrated need. Keep internal registration identities intact. Reserve 1.0 for publication readiness.

Commit, push, package, install and deploy only within the user's authorized scope. Report what changed, exact evidence, limitations and next acceptance criteria. Git excludes ignored scenes, binaries and installers.
