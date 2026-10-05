# Independent review and continuation plan

## Stage A — establish the exact scope

- Read this handoff before earlier “ready for testing” statements.
- Inspect `git status`, branch, HEAD, tracked diff and untracked source. Compare against `53bfc5d1c76929958dbeb29f5d4c746b2321d0ac`; do not assume working files are committed.
- Preserve licensing work, artist scenes, installed profiles and original evidence. Avoid destructive cleanup or automatic staging of everything.
- Capture a fresh source/binary fingerprint before testing; compare it with `evidence/current-snapshot.json`.
- Treat docs as claims to check. A timestamp, test name or passing inventory count is not enough to prove behavior.

## Stage B — review calculations and state ownership

Trace a plant from receiver/Area eligibility through candidate identity, Brush field, transforms, source/radius, CS Edit, ordered collision, cleanup/refill, publication, preview and exact output. Trace an edit backwards through invalidation and cache keys.

Start with:

- `AminScatter/include/procedural.h`, `src/procedural.cpp`, `src/procedural_bridge.inc`, `tests/procedural_tests.cpp`.
- `AminScatter/src/scatter.cpp`, `group_spacing.cpp`, `brush_host.cpp`, `cyrus_edit.cpp`, `cyrus_edit_stack.inc`.
- `AminScatter/tools/ui/templates/procedural-model.ms`, `procedural-evaluation.ms`, `procedural-ui.ms` and `tools/ui/procedural-policy.cjs`.
- `CyrusMCP/cyrus_mcp/procedural.py`, `max_host.py`, `settings.py` and `tests/test_procedural.py`.

Look for mismatches with the [requirements matrix](REQUIREMENTS_REVIEW_MATRIX.md), incomplete compatibility guards, nondeterministic retries, stale blockers, invalid ID reuse, incomplete rollback and any calculation inside navigation/display-only paths. Assess worst-case work/memory, not just average demo performance.

## Stage C — review the unfinished UI patch first for blockers

Inspect `layers-first.cjs`, `layers-first-host.ms`, `layers-first-panel.ms`, `procedural-ui.ms`, `src/rollout_flow.cpp`, and the existing `src/rollout_scroll.cpp`.

Check static page lifetime, `this`/owner binding during open/close, deferred mount timing, ten-slot limits, native categories, helper ownership checks, hidden-slot state, structural remounts, selected-peer persistence and background timer interactions. The earlier intermediate run's page visibility failure is a concrete reproduction target, not hypothetical polish.

Do not build a custom styled UI to work around this without first assessing the native architecture. Do not silently change calculation or layer/set semantics while correcting layout.

## Stage D — validate in increasing scope

Offline commands, from the repository root:

```powershell
Push-Location AminScatter
node tools/ui/generate.cjs
Pop-Location
build/mcp-venv/Scripts/python.exe tools/procedural_lab/check_generated.py
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests -q
build/mcp-venv/Scripts/python.exe tools/procedural_lab/build_check.py --max-year 2027
build/mcp-venv/Scripts/python.exe tools/procedural_lab/build_check.py --max-year 2026
```

The generator check validates reproducibility and delimiters; only loading in Max establishes MAXScript compilation/host integration. Native tests cannot validate command-panel behavior.

For a fresh isolated Max 2027 run, choose a previously unused run name starting `procedural07-ui-`:

```powershell
build/mcp-venv/Scripts/python.exe tools/mcp/launch.py --run procedural07-ui-review-01 --native-build build/procedural-07/max2027
build/mcp-venv/Scripts/python.exe tools/procedural_lab/runtime_driver.py build/mcp-qualification/procedural07-ui-review-01 tools/procedural_lab/Max_Procedural_07_UI_Prepare.ms
build/mcp-venv/Scripts/python.exe tools/procedural_lab/runtime_driver.py build/mcp-qualification/procedural07-ui-review-01 tools/procedural_lab/Max_Procedural_07_UI_Acceptance.ms
```

The launcher uses private plugin/config/temp directories. The preparation fixture loads a **copy** of the local example and needs that demo file to exist; the acceptance fixture replaces only its private test scene. Never run those reset/load fixtures in an artist session. Use returned process/window identity, not “the first Max window.” Check launch/runtime errors before proceeding.

Extend validation to assert final page visibility/order, rather than just page ownership arrays. `ui_geometry.py` can inspect actual Qt wrappers. Add real pointer resizing, wheel/background dragging and spinner edits. Keep screenshots and counter receipts with the exact loaded source/native hashes. Reuse the previous procedural/Brush/Edit/MCP fixtures where the UI/host changes can affect integration; do not describe every legacy option as tested unless it was.

Close only private test sessions created for the review. Loaded native DLLs cannot be updated in place; restart a disposable test process for a native change.

## Stage E — report before implementing more work

Deliver an independent review with:

1. Findings ordered by severity, exact file/line, affected workflow, reproduction/evidence and a minimal remedy.
2. A requirements matrix: satisfied with evidence, partial, missing, intentionally deferred, or unverified.
3. What is sound and should be preserved, plus simplifications supported by the source.
4. Test results with exact source/build identity and explicit exclusions.
5. A prioritized next coding loop and acceptance criteria.

Review first. Do not mass-refactor, install into the artist profile, publish, commit or push as a side effect of the review.

## Completion gates after findings are addressed

- [ ] Matching final native + MAXScript loads cleanly in a fresh Max 2027 process.
- [ ] Native page order and hidden slots remain correct across resize and owner lifecycle.
- [ ] One/two/three-column navigation and scroll/drag work with controls retaining focus and state.
- [ ] Automatic spacing commits to the correct scope/peer; Manual/Live, Undo and inheritance are verified.
- [ ] UI operations preserve accepted rows and retained display buffers unless a data change requires work.
- [ ] Earlier procedural, Brush/Edit and MCP guarantees still hold on the final source.
- [ ] Both SDK builds pass; Max 2026 runtime is either tested separately or clearly remains unqualified.
- [ ] Final packages contain exactly the validated source/native pair, with verified payload hashes.
- [ ] Documentation distinguishes supported behavior, limits, planned features and historical evidence.

Only after those checks should the native-column/automatic-spacing update be offered as a new artist-testing package. A later Git checkpoint requires explicit scope selection so unrelated work is not accidentally included or dropped.
