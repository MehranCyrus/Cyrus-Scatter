# Process loss and restart qualification

M01/M09 foundation increment, 24 October 2026. The three scoped native restart cases below pass; the full lifecycle and integration remain in progress.

## Contracts

On restart, the production journal conservatively interprets queued/running work as `outcome_unknown`. A durably saved `committed` witness remains committed; otherwise effects remain unknown. The original key/arguments and old scene epoch still identify the receipt. An exact-key retry reads that receipt; a new-key apply and design enrollment remain blocked until local reconciliation. Restart never reconstructs write authority or replays the plan.

Owned-change admission now records `target_identity` (controller, generation and configuration) with explicit **approved base before execution** semantics. It is not a commit witness or permission to adopt a controller. Recovery compares committed identity preferentially, otherwise labels the recorded identity as the old base. A changed configuration after an uncertain operation must not be misreported as agreement with that base.

The startup panel now reflects the loaded recovery guard before any client request: clear local-review guidance, disabled enrollment/approval, available recovery review. Invalid states/effects/flags/resolution status or duplicate journal IDs fail closed without changing the file. A failed committed record requires review even without its explicit recovery flag. Save enforces the same two-million-byte ceiling as reload and retains the previous durable file on an oversized successor.

## Owned native fault matrix

Use only the exact staged Scatter 0.86.9.2/Analyzer 0.14.2 pair in Max 2027. Each case has separate before/after private profiles and one shared owned connection/journal directory. Save only the synthetic checkpoint inside that case. Termination obtains a process handle, rechecks its full owned command/profile and executable, terminates that handle, and requires its signalled terminal state before launching the successor. No process is selected by generic executable name.

| Case | Native boundary / on-disk evidence | Required fresh-host result |
| --- | --- | --- |
| queued | Approved configure request durably queued; private host busy guard prevents execution | Unknown outcome/effects, base target retained, saved old settings restored; no replay/new-key mutation |
| host_return | Actual native configure and checkpoint save finish; process stops before service commit acknowledgement; journal running/unknown | Unknown stays unknown even though the private test witness knows settings changed; old base configuration comparison is false; current native scene is retained on local retirement |
| journal_commit | Native configure and save finish, service persists running/committed, then stops before completion fingerprint | Unknown completion with committed effects and new configuration witness retained; current selected configuration comparison is true |

Every case must use a real external SDK client after restart, query the old epoch/operation, exact-key retry, new-key denial, fresh-scope absence, immediate startup widget state and local retirement without changing restored native state. Native saved settings/layer IDs/modes must match the relevant checkpoint. Publication identity is transient across reopen; whether Manual pending publication reconstruction preserves its old population is measured separately, never assumed from saved parameters. This is not durable task/adoption completion or full crash recovery for all storage/hardware failure modes.

The private fault barrier is bounded to 45 seconds. Expiry is a failed test, not proof of process termination. Any timeout must resume observation of the same process/request; do not launch or apply again merely because observation expired.

Reusable fixtures: `tools/mcp/loss_campaign.py`, `loss_host.py`, `loss_boot.ms`. `launch/resume/arm/terminate/check/close` separate admission, observation and recovery; `attempt.json` persists the original key before submission and prevents a second attempt. Immutable before/after metadata, journal, checkpoint hashes, boundary marker and result receipts are required. Code/SDK/native API evidence, GUI interaction and actual artist consent remain distinct.

## Executed evidence

**349 offline tests passed in 37.70 s**, `build/mcp-process-loss-20261024-01/offline.xml`. Eight additional cases cover target-versus-commit identity, restart guard/message, invalid journal fields, duplicate IDs, missing recovery flag on a failed commit and preservation of the previous file on oversized save. The queue fixture was corrected after these tests; production runtime/test sources were unchanged. Its original source/attempt and explicit reload/rebind remain archived.

All three cases used actual original-process termination followed by a new Max 2027 process, the exact saved synthetic checkpoint, the same owned journal/connection directory and a real external SDK client. After restart, the startup widget snapshot precedes client requests: review available, enrollment/approval disabled, no scope and clear local-review message. The old operation/epoch and exact key return the original derived unknown outcome, while a new-key apply is denied. Local retirement retains the outcome/effects, discards authority and leaves the measured restored native snapshot unchanged (layer IDs/counts/seeds/modes, owner/generation/configuration tags, cached manifest and node count). This is not a proof of every material/geometry property or artist comprehension.

| Case | Receipt directory | Original → new PID | Restart effects | Restored first-layer count |
| --- | --- | --- | --- | --- |
| queued | `build/mcp-process-loss-20261024-01/queued/` | 11908 → 57488 | unknown | 80 |
| host_return | `build/mcp-process-loss-20261024-02/host_return/` | 53932 → 16844 | unknown | 120 |
| journal_commit | `build/mcp-process-loss-20261024-02/journal_commit/` | 36916 → 23544 | committed | 120 |

Each directory contains `attempt.json`, `queued-response.json`, `journal-before-loss.json`, `terminated.json`, checkpoint files/hashes, before/after profiles and `process-loss-result.json`. For running boundaries, `loss-boundary.json` proves the private native boundary was reached before termination. No deadline expiry was counted as a crash. New-profile native hashes match all five staged modules of Scatter 0.86.9.2/Analyzer 0.14.2; all 24 frozen runtime Python/JSON files match source. After-profile artifact IDs respectively: `b2c5312436e301ea2cb5f5bef89b4a6b3f285862534bc09478451b51406e40eb`, `bd747ee2bf5277b5b7a07ed64febd5341376bfeb1a6748eaff2a6d8c8f81e17f`, `65f10c4b7f2e5b7c5c77958c02030c15ceb6728306eb192a6db15263ff6438c8`.

The first queued fixture set busy before admission, and production correctly denied it. After confirming no record for that key existed, the fixture was corrected to set busy immediately after the real admission; the same original key/validation then queued successfully. This is a fixture correction, not bypass of the busy gate. A separate PID 40904 exited during startup before readiness/bootstrap or MCP submission; its profile/listener/startup observation is preserved under run 01 `host_return/before`. Its cause is unproven, and it is not a passing loss case. A fresh directory was used only after confirming the original process was absent. All successful before hosts were terminated by their verified handles; every after host closed cleanly. No artist profile/session or original configured integration was changed.

## Reopen observation and remaining acceptance

The queued checkpoint reopens with the same **139** cached accepted rows. The two pending-configuration checkpoints do **not** preserve their old Manual populations across cold reopen: **135 → 168** and **127 → 164** accepted rows after startup presentation, with the saved authored first-layer count 120. The source's native publication is transient; this observation must not be promoted to seamless pending-publication/task restoration. Local recovery correctly reports the current cached count and configuration comparison and does not replay or silently rewrite saved settings to force the old frame.

M09 must explicitly handle reconstructed publications and returning-task context: invalidate old publication handles/claims, preserve valid intent/references, disclose changed cached results and require the appropriate fresh local authority. Do not claim the last warm Manual frame survived reopening from the fact that authored settings/IDs survived. Whether durable old-publication restoration is within the supported return contract must be resolved from native ownership/lifetime and measured costs, rather than a placement-sized Python cache or hidden recalculation.

These tests cover controlled process loss at three precise boundaries with successful disk saves, not power loss, arbitrary native/renderer crashes, damaged storage repair, every scene/resource combination, uncertain Undo failures, or task adoption/resumption. M01 and M09 remain open; M13 still requires the complete operation/workload/client/package matrix.
