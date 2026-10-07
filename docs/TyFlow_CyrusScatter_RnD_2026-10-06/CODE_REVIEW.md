# Code Review

6 October 2026. Focused diff: `75564c4d659af578e0c4639f444998b306bc4581..01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2`. Applies the code-review skill's changed-code boundary. Pre-existing complexity/resource concerns are in [the broader findings](FINDINGS_AND_ROADMAP.md).

**Verdict: APPROVE — with one nonblocking P2 correction recommended.**

**Confidence: MEDIUM.** Canonical templates/generator and generated script were traced; fresh offline tests passed; matching prior host receipts were audited. No new Max execution or pointer/renderer test was performed here. Approval concerns this bounded diff review, not commercial release or untested host behavior.

## Summary

The 0.72 changes repair warm popup owner rebinding, reuse the feature bodies in a selected-layer native Modify host, expose the existing recorder directly and narrow Corona Stop handling. The native placement/display core is not rewritten. Current source and preserved host evidence agree on the supported corrections.

The native selected-layer view and optional popup share the same authored owner objects. No second evaluator or permanently constructed UI for every layer is introduced. Section expansion binds the current owner; warm retarget now explicitly rebinds the existing topic. Empty/nonempty host transitions control page visibility. Callback/layout work is not eliminated, but it is separate from placement publication and unchanged GPU data.

No new P0/P1 regression was established. The former same-topic popup P1 belongs to the earlier snapshot and is fixed in this diff. Existing ordinary failure/publication, cached reader, idle and 100k navigation receipts are relevant positive evidence. API-driven rollouts do not qualify actual DPI, pointer scrolling, monitor transitions or perceived latency.

## Finding

| ID | Priority | Changed location | Impact / evidence |
| --- | --- | --- | --- |
| CR1 | P2 | [diagnostics-ui.ms:78](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/diagnostics-ui.ms#L78), cleanup at lines 79–81 | An export failure can be replaced by another exception from Close/Delete/status refresh; later cleanup can be skipped and a temporary file left. Source trace plus the documented StreamWriter failure contract; not reproduced in Max here. |

### CR1 — Preserve the original export failure through cleanup

The new saveReport catch block calls stream.Close(), deletes the temporary file and refreshes status without individual guards. If a write/flush failed because storage is full or unavailable, Close can attempt another flush and throw. Execution then never reaches temporary deletion or the final rethrow. Delete and refresh can also fail after the first error. The user may see a cleanup error instead of the export cause.

Microsoft documents that Close writes remaining data and can throw when the disk has insufficient space. This is a concrete failure mode, not an assumption that closing a writer is always safe. [StreamWriter.Close contract](https://learn.microsoft.com/en-us/dotnet/api/system.io.streamwriter.close?view=netframework-4.8.1).

This does **not** establish corruption of an existing report: publication uses File.Replace/Move only after a successful complete close. The previous destination is preserved by the intended atomic path. The problem is reporting and best-effort cleanup during a failed export.

Smallest fix for a future coding loop: retain the primary exception/message before cleanup; guard close, delete and status refresh independently; report cleanup leftovers without replacing the primary failure. Keep replacement after successful completion. Do not add a new logging framework.

Acceptance: fail writing/flush/close separately, fail temporary deletion, fail destination replacement and fail status refresh. Existing destination bytes stay identical after unsuccessful export; the primary cause remains visible; any leftover path is identified; recording remains stopped according to the documented Save contract. The existing locked-destination fixture covers replacement failure, not all these paths.

## Review of tests and implementation choices

- The generated script has a large reordered diff. The canonical generator/templates, semantic inventory and generated-check receipt are a more useful review surface than interpreting every moved line as a behavior change.
- Real owner retarget/control events, collapsed-section binding, Undo and persistence have preserved 0.72 host receipts. Merely counting 245 controls would not test those interactions.
- Corona's state-verified Stop correction has an actual floating-IR lifecycle receipt. It does not prove the original artist trigger is isolated, every status code is universally benign, or successful docked IR works.
- Direct diagnostics are process-scoped and opt-in. Module file hashes identify files associated with the process; they cannot prove the exact loaded memory if a file was replaced after loading.
- Fresh 14 native suites and 140 Python tests passed. The new independent collision oracle adds value beyond pass counts; it does not independently validate the entire host pipeline.

## Recommendation

Keep the diff and its retained foundation. Address CR1 alongside bounded reporting failure tests, then complete the explicitly listed host/UI/renderer gates. Avoid a blanket script-to-C++ migration or a wider MCP write boundary as a response to unmeasured latency.
