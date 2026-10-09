# Reproducing the focused inspection

Run from the repository root. These helpers use the neutral backend/capture/export helpers in `../../reproduce/`, the earlier PE parser and the existing local toolchain. They never execute the vendor binary. All raw outputs must stay under an owned ignored `build/` run.

1. Capture a fresh run with the parent `capture.py --output build/<fresh-run>`; record inspected Brush source identities too.
2. Start the parent `backend.py` in that run. The actual run copied the previously saved Ghidra project into its own project directory; it did not alter the original.
3. Inspect the live schema. This installed backend's `/open_program` advertised endpoint required GUI mode and did not load a program headlessly. Preserve the error; use the supported `/load_program` on the copied binary, then `/run_analysis` instead. Always inspect JSON success/error fields, not just Python process exit status.
4. Run `inspect.py --run ...` to locate brush anchors, decode RTTI inheritance and identify the canvas owner. Run `probe.py --run ... --anchors` only after a program is actually loaded.
5. Feed reviewed, version-specific selections to the parent `export_selected.py`. Retain failed attempts separately and inspect assembly, decompiler warnings and resolved entry points; selection names are not ground truth.
6. `sdk_witness.py --output build/<fresh-run>/sdk-witness` compiles four interface layouts without linking/execution. Official brush pages are captured with `collect_docs.py --run ...`.
7. Save/close the owned project and stop only the backend whose executable, argument file and listener ownership match its startup receipt. Preserve the database.
8. Finalization requires a constants receipt as well as the saved/closed/stopped receipts; see the actual run's `read-constants.py` for the bounded PE reads. `finalize.py --run ...` validates hashes, helper syntax, links, whitespace and ignored raw inputs before writing this report's `EVIDENCE.json`. For a new run/report, copy the helpers to a new dated report directory so the previous receipt is retained.

Actual run: `build/forest-brush-research-20261008-01`. No new runtime installation, Max launch, product build or scene modification occurred.
