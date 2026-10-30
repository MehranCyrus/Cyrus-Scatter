# Recommended sequence

This review does not authorize or implement these changes. Preserve the artist-endorsed responsive Bend/Trim behavior and the now-passing R1–R7 regressions.

| Order | Work | Effort / dependencies | Measurable acceptance / rollback risk |
|---|---|---|---|
| 1 | **FS-01: mark Scene-load staging** | Small; use existing ownership marker and recovery code | Dead owned stage removed; live/unmarked stages retained; 20 interrupted cycles do not accumulate copies; published hashes unchanged. Low risk if marker failure stays inside cleanup. |
| 2 | **FS-02: correct writer identity and license wording** | Small; shared verified build identity, generated UI route | Newly saved metadata equals loaded version; historical presets remain loadable; no obsolete package instruction. No schema or placement change needed. |
| 3 | **GAP-01: qualify construction peak and failure retention** | Medium; allocation accounting/fault hooks in disposable build | Report old/new/scratch/render/GPU ownership separately; reject before predictable excessive construction; previous complete result survives injected failures. Avoid changing Count or merely raising limits. |
| 4 | **OPT-01: reduce unchanged snapshot bookkeeping if real profiles justify it** | Medium; preserve immutable snapshots and deterministic ordering | At least 50% lower cumulative allocation in the 8,192-posed/local-edit fixture, equivalent full results, stable tickets, no small-batch regression. Measure the garden separately before claiming artist speedup. |
| 5 | **Close focused release acceptance gaps** | Medium to large; representative owned scenes and supported renderer matrix | Multi-event Undo/Redo after source/role changes; topology/material cases; repeated editor open/close and owner switches; long-session resource retirement; render fidelity and device recovery. Physical/DPI work requires a separately permitted method. |

Do not combine the small storage/wording fixes with a solver rewrite. Each should have its own focused regression and unchanged-case control, then the appropriate current build/package qualification when delivery is authorized.

## Research projects, not immediate repairs

1. **Picking acceleration:** measure representative dense visible geometry and actual warm hover paths first. Consider an instance spatial index and pose-aware face hierarchy only when repeated cost warrants them. Preserve displayed-subset selection, stable IDs and opacity policy.
2. **Worker lifetime:** compare the synchronous join model against an owned pool only if thread launch is a material fraction of the workload. Shutdown, revision ownership, cancellation and failure order must remain explicit.
3. **GPU contact fitting:** establish CPU/GPU break-even, resident data, upload/readback, SDK interop, fences, vendor coverage and device recovery with an isolated prototype. Include render and CPU picking consumers. A kernel benchmark alone is insufficient.
4. **Broader packaging/customer service:** maintain the current team-pilot truth. Clean-machine install/upgrade, supported hosts/renderers and a real activation/seat service need independent qualification and authority.

The immediate engineering judgment is to keep the present native/retained architecture, finish the two small verified defects, and measure the remaining ownership costs. The evidence supports refinement, not replacing the working system.
