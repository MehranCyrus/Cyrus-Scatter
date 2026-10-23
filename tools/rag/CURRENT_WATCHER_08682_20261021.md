# Automatic knowledge watcher — 21 October 2026

The user separately requested updating the automatic watcher while leaving plugin
code unchanged. Its existing authorization is now rebased to the verified
[current index](CURRENT_REFRESH_08682_20261021.md). A bounded watcher is running,
and newly established project connections use the updated connection-owned policy.

## Authorized baseline and scope

- Branch: `codex/workflow-0.75`; HEAD:
  `3d387550cacf37fe1aeae7a01455f7644d9cf08b`.
- Baseline index:
  `_local/rag/indexes/20261021-knowledge-refresh-03-candidate-01/`.
- Generation:
  `7bd37979ae4e3c242694fde44943d7ec54cfe6236112ce00c7d01bae18751fbc`.
- New immutable policy:
  `_local/rag/refresh/20261021-knowledge-watcher-policy-01/policy.json`.
- Policy SHA256:
  `a30b305a6f0f4932d5ebee3a993c06f521c974e21fdb0ab572f601c421541d6e`.
- The previous policy and every prior index/receipt remain preserved.

The rebase retains the same **48 enrolled parents**, four evaluation definitions
(original v19, revised v19, challenge v18 and foundation v13), and both plain and
terminology profiles. The previous refresh's reviewed retrieval tradeoffs are
the new baseline; the watcher cannot accept new regressions automatically. The
previously verified `candidate_guard.py` correction is now included in the helper
fingerprints. No new updater or retrieval implementation change was needed here.

Only the policy path and its exact hash changed in the project MCP registration.
The selected index, command, tool exposure and unrelated configuration bytes are
preserved. A private before-copy and exact comparison receipt are retained under
`build/knowledge-watcher-08682-20261021-01/`.

## Operation and limits

Checks run every **60 seconds**, with the existing maximum **12-hour session**.
Unchanged inputs do not trigger a rebuild. A new project connection starts its
own bounded worker; one root-scoped lease prevents concurrent refresh operations.
Already-running adapters retain their old startup policy and can continue showing
its unavailable status until reconnection. Their read-only searches still follow
the current registered index.

For immediate coverage without interrupting those connections, the documented
standalone `automatic_refresh.py watch` command was started hidden with the new
policy, a 60-second interval and a 43,200-second maximum. Its PID, process start
identity, exact arguments and output paths are recorded in
`build/knowledge-watcher-08682-20261021-01/launch.json`. The initial PID is `32544`;
that number is historical launch evidence, not a future liveness guarantee. This
is a finite local process, not a newly installed OS service or scheduled task.

The existing semantic and resource gates remain intact. Changed or ambiguous
required evidence/contract intervals, immutable historical evidence, runtime or
policy changes, and retrieval regressions require explicit review. No enrollment,
authority, thresholds, ranking or glossary changes are automatic. The 90-second
stage, 1,800-second operation and 16 GiB aggregate-read bounds are unchanged.
A full four-suite refresh can hit these bounds; the previous index then remains
selected and a retained failure requires review. This watcher reduces mechanical
maintenance; it cannot guarantee automatic acceptance of every future version.

## Verification and preservation

- The real production `tick` passes as `unchanged`, identifies the current
  generation, and attempts no activation.
- A fresh real STDIO connection starts its own watcher with the new policy,
  reports `watching` / `process_running=true`, verifies **48/48** parent hashes
  and serves an identifier search from the same generation. Its owned worker
  exits when the connection closes, confirmed separately with Win32 process
  liveness. A killed worker can leave its last operational status observation;
  that file alone does not prove the process is alive.
- The immediate standalone watcher holds the production lease and reports
  `unchanged`, `watcher_running=true`, with the current policy hash. Its actual
  process identity is checked independently of the observation file.
- All **18 automatic-refresh tests pass** in the pinned SDK environment
  (125.306 seconds). Disposable tests include real paired builds/evaluations,
  activation and same-connection adoption, owned shutdown, lease contention,
  regression rejection and preservation of the previous selection on failure.
- All **961 tracked product files present at task start** retain their hashes.
  No plugin code, generator, native binary, profile or installer changed. No Max
  launch/restart, plugin build, install, Git commit/push or deployment occurred.

Raw evidence is in `build/knowledge-watcher-08682-20261021-01/`, notably
`rebase.json`, `tick.json`, `connection-status.json`, `connection-search.json`,
`connection-lifecycle.json`, `automatic-tests.log`, `launch.json` and
`final-verification.json`. This production baseline was unchanged during the
check; a changed production successor was not manufactured to claim acceptance.
The changed-input end-to-end witness is the disposable test, not a plugin edit.

The policy snapshots, process logs and private configuration backup are ignored
local artifacts. A source-only Git backup does not include them. See
[the automatic refresh contract](AUTOMATIC_REFRESH.md) for supported commands,
review boundaries and recovery behavior.
