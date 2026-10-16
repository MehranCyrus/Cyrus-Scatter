# Max 2027 gallery qualification fixtures

Private development fixtures, excluded from installers. They create/change/reset
owned test scenes and must never run in the artist's profile. Campaign identities,
failed predecessors and supported boundaries are in
[the 0.85.1 ledger](../../docs/plans/preset-gallery-improvements/PROGRESS_0851.md).

`launch.py` creates a fresh `foundation-roadmap-gallery0851-*` profile under
`build/mcp-qualification`, verifies the native receipt's inputs, and copies the
current generated script and managed gallery. Use a new profile name; never mix
new scripts and old native modules. Only 2027 and configured 100%/150% UI scales
are accepted. `recipient.py` instead exercises the copied EXE's actual Install
handler and starts the owned host from its installed registration.

Send one request at a time per host through `tools/eleven_phases/request.py`.
Inspect a timeout's correlated request/result before retrying. `command.json`
and the small phase/index files belong to that one owned profile. Scene open,
Undo and deferred helpers need separate event-loop turns; a returned operation
is not proof that every queued notification has settled.

| Runner or fixtures | Evidence |
| --- | --- |
| `run_suite.py` | No-op settings, curves/style, revision persistence, capture, static asset/PNG fidelity, Scanline, rollback/reuse and admission boundaries |
| `final_acceptance.py` | Eight matching example scenes, Paint/full placements, departed-owner release, Undo/Redo, installed import and exact MZP wrapper |
| `final_gallery.py` | L128/L2K/L10K search, 120-second Manual/Live idle, then 30-minute gallery lifecycle |
| `import_soak.py` | 60-minute alternating independent/reused imports with native Undo/Redo and discarded-owner checks |
| `visual_layout.py`, `dialog_layout.py` | Actual gallery/Save/Details/Load/Style handlers, native child bounds and managed-control renders at configured scales |
| `installer_filesystem.py`, `installer_crash.py` | Owned inert-payload publication/repair/unregister and exact-payload process-exit/lock/cancellation/upgrade cases |

Inspect each runner's `--help` and source prerequisites. In particular, the hour
test needs a completed verified `package_bitmap_export.ms` fixture; running it
after the memory-pressure scene without recreating that fixture is invalid.
`final_acceptance.py --after-idle` skips only its initial idle phase, while
`--examples-only` omits package/installer checks. Receipt arguments preserve
which path actually ran.

For terrain browsing, use `heavy_prepare.py`, allow notifications to settle,
then `heavy_publish.ms` in a separate request. Record `heavy-config.json` and
`heavy-count.txt`; the valid final 0.85.1 fixture uses 10,000 rows per layer,
20,000 total, on 180,000 faces. Run `final_gallery.py --current-scene --native-rows`
and a final `heavy_state_probe.ms`. The native witness hashes every ordered
placement field without allocating a Python wrapper for every component.
Do not force Update as part of passive browsing or relabel this as the failed
60,000-row editing fixture. `heavy_setup.py` preserves the earlier monolithic
diagnostic and is not the final qualification path.

`resource_probe.py` is an explicit post-soak .NET-finalizer diagnostic; it is not
product GC behavior and never clears MAXScript Undo. No fixture may enlarge the
artist's heap or flush history to produce a pass. `close.ms` stops only the
verified owned host; its transport can time out because Max exits before writing
a response, so check its closure marker and process absence instead of resending.

Generated scenes, compiled modules, installers and raw receipts remain ignored
local artifacts. A source checkout alone does not contain the `.max` examples;
retain the qualified distribution or reproduce/stage them from the recorded
generation fixtures. SDK/offline passes do not qualify actual Max UI or renderers.
