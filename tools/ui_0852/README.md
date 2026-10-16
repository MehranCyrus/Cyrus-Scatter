# 0.85.2 private UI qualification

These fixtures target only `build/mcp-qualification/foundation-ui0852-*` Max 2027 profiles. They never install into the artist profile, move the desktop pointer, change Windows DPI, or clear Undo. `recipient.py` uses an owned install destination. `close.ms` closes only a prefix-guarded owned host.

- `launch.py` stages the exact native receipt and generated script with default zero, explicit one or configured 1.5 UI scale.
- `run_checks.py PROFILE [--installed]` runs native wheel/drag, 12-panel/two-owner bounds, library scaling/reopen/browsing checks. The installed route chooses the real bundled-library action.
- `run_more.py PROFILE` checks controls/grips, ten remounts at 260/600-pixel panel widths, pending Manual state, then at least 120 seconds each of Manual and Live idle.
- `native_navigation.py` separates preparation, native input delivery and observation across host event-loop turns. It resolves current column ownership and reads the actual scroll value, full publication fingerprint, work/upload counters and Undo/Redo. The final fixture raises only the owned test window without activation during delivery/observation, then lowers it and verifies foreground preservation.
- `navigation.py`, `diagnose.py`, `read_columns.py` and `small_scroll*.py` are diagnostic predecessors/probes, not substitutes for the final matrix. Qt scrollbar writes used by diagnostic preparation are not input acceptance.
- `package.py` builds/verifies the exact MZP and unsigned EXE; `recipient.py`, `installer_exe.ps1`, `installer_mzp.py` test their actual install routes in a disposable recipient.

The initial 100%/150% fixture versions differ from the final native-input fixture. Receipts pin per-step hashes where recorded; the exact pre-raise native fixture was reconstructed and matched to the copied recipient receipt hash, then preserved under the ignored campaign `fixture-predecessors`. Early diagnostic/runner failures are not relabeled as passes. The tracked correction report and qualification JSON state the executed scope and limits. Physical monitor/input and production-scene acceptance remain separate.
