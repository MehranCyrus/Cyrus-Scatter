# Eleven-phase private host qualification

These fixtures operate only in redirected, disposable profiles under
`build/mcp-qualification/foundation-roadmap-*`. They are not MCP write tools and
must never execute in an artist's scene/profile. Phase 1 evidence and remaining
acceptance are in [P01](../../docs/plans/eleven-phase-roadmap/P01.md).

Build from frozen current sources, then launch a matching host. Example paths
below identify the recorded candidate; use fresh suffixes for a new iteration.

```powershell
python tools/eleven_phases/launch.py foundation-roadmap-p01-max2027-03 --native build/eleven-phases-20261014-01/p01-native-2027-03 --year 2027
```

The launcher checks the native receipt against all current source inputs, checks
the four native module hashes, and verifies loaded module paths. It does not
install into the normal Max profile. Optional `--visible` is for a requested
interactive/visual witness. Run Max 2026 with its own matching build/profile.

Once the host is ready, submit each fixture separately and inspect its correlated
completion before submitting another. A timeout does not cancel the request.

```powershell
python tools/eleven_phases/request.py build/mcp-qualification/foundation-roadmap-p01-max2027-03 tools/eleven_phases/phase01_undo.ms
python tools/eleven_phases/request.py build/mcp-qualification/foundation-roadmap-p01-max2027-03 tools/eleven_phases/phase01.py --timeout 120
python tools/eleven_phases/request.py build/mcp-qualification/foundation-roadmap-p01-max2027-03 tools/eleven_phases/phase01_panels.py --timeout 120
python tools/eleven_phases/request.py build/mcp-qualification/foundation-roadmap-p01-max2027-03 tools/eleven_phases/phase01_limited.py
python tools/eleven_phases/request.py build/mcp-qualification/foundation-roadmap-p01-max2027-03 tools/eleven_phases/phase01_passive.py
```

The Undo fixture runs first, entirely outside Python's execution hold, and rejects
an already-held host. It does not clear history. Feedback and panel fixtures reset
or load only owned generated scenes. Their JSON/text files contain assertions,
counter snapshots and measured callback costs. The feedback fixture retains a
request-specific result as well as `phase01.json`. `phase01_probe.py` is a targeted
diagnostic for a failed intermediate run; it is not part of the acceptance suite.

`P01_visual_ready.max` is the owned scene for visual inspection. API/callback
checks and recorded rollout dimensions do not replace that check. The normal
0.81.6 installation cannot qualify the 0.81.8 UI.
