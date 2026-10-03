# Evidence index and reproduction

All scenes are synthetic private fixtures on Windows x64 / Max 2027.1 build 11426. They contain no artist assets. `summary.json` records final source SHA-256 hashes, test counts and fixture timings. Paths and IDs identify local test runs; no connection secret, descriptor or operation journal is included.

| Evidence | What it supports |
| --- | --- |
| `pytest.xml` | 48 contract, geometry, service, transport and MCP tests |
| `cycles.json` | Final 100 cycles after the redraw recovery fix; three unit/transform fixtures, exact retries, deterministic hashes and Undo restoration |
| `scenarios.json`, `refinement-recovery.json` | Approval, five injected failures, prior-result preservation, refinement, save/reopen and stale-context behavior |
| `boundaries.json` | Host/input limits and measured geometry budget; render callback state is tested, not a full renderer workflow |
| `redraw-unwind.json` | Minimal reproduction separating normal versus exceptional pymxs redraw exits |
| `stdio-acceptance.json`, `verified-viewport.png` | Real SDK wire protocol and a visually checked 1,800-plant result after recovery fixes |
| `inspection.json`, `retained.json` | Pure existing-controller inspection and retained Mesh/Point Cloud ready/upload diagnostics |
| `budget-generation.json` | 9k input triangles and 2,000 generated plants with retry/Undo |
| `launch.json` | Final 100-cycle process and loaded native file identities |
| `installed-launch.json`, `installed-host.json`, `installed-acceptance.json` | Fresh-process final installed build, default connection and actual local UI approval; 1,200-plant publication/image/retry; Escape and reopen |
| `panel-lifecycle.json` | Escape releases IPC and deletes the old Qt dialog; reopening starts without scope |
| `playback-admission.json` | Real native Play/Stop rejected/restored admission using the same service/adapter as the final build |
| `package-manifest.json`, `release-verification.json` | Offline artifact hashes, source/host/wheel parity and matching Codex registration |
| `handoff-state.json` | Product panel active for read-only demo inspection; private development timers stopped |

The 100-cycle run used `acceptance-e`. Subsequent UI focus and lifetime fixes were validated in `acceptance-installed`, a new process loading the installed package. The native Play/Stop check preceded that UI-only fix; its service/adapter code is identical. Publication timings are machine/fixture-specific and exclude earlier admission/freshness checks, local review and model latency. They are not FPS measurements.

## Reproduce core qualification

From the repository root, with its build prerequisites installed:

```powershell
build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests -q
python tools/mcp/launch.py --run another-private-run
build/mcp-venv/Scripts/python.exe tools/mcp/qualify.py build/mcp-qualification/another-private-run --cycles 100
build/mcp-venv/Scripts/python.exe tools/mcp/scenarios.py build/mcp-qualification/another-private-run
build/mcp-venv/Scripts/python.exe tools/mcp/boundary_acceptance.py build/mcp-qualification/another-private-run
build/mcp-venv/Scripts/python.exe tools/mcp/stdio_acceptance.py build/mcp-qualification/another-private-run
```

The launcher copies known native candidates from the local Brush/research build folders; those must exist. These scripts can reset their private fixture. Never point them at an artist session or ship `tools/mcp` as product tools.

## Reproduce installation/UI acceptance

Close any panel already owning the default connection. Install the generated package, then launch a fresh private host with `tools/mcp/launch.py --run another-installed-run --installed-host <installed-build>/host`. Use its installed `venv/Scripts/python.exe` to run:

```text
tools/mcp/installed_acceptance.py build/mcp-qualification/another-installed-run prepare
```

Click **Approve displayed proposal** in that private Max panel, then run the same command with `apply`. Start native Play and use `playing`; stop and use `stopped`. Focus the Automation panel, press Escape and use `closed`. Run the installed `Start_Cyrus_Automation.ms` again and use `reopened`. Each phase fails if its expected behavior is absent; none silently approves through MCP.

Full renderer workflows, another workstation, Max 2026, model composition quality and long-duration memory behavior remain separate qualification work.
