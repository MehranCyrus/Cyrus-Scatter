# Explicit activation and rollback

`activate.py` prepares a read-only plan or applies an explicitly confirmed plan.
It is outside the installed retrieval fingerprint. It never rebuilds an index,
changes the corpus, installs packages, edits global configuration, reloads desktop
consumers or schedules work. Use Python 3.11 and the existing pinned MCP environment.

## Prepare first

From the repository root, use explicit paths and a fresh output identity:

```powershell
py -3.11 -B tools/rag/activate.py prepare `
  --root F:/Cursor/_Cyrus_Apps/CyrusScatter `
  --action activate `
  --target F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/indexes/20261012-phase4b-final-02-candidate-01 `
  --evidence F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/candidates/20261012-phase4b-final-02/receipt.json `
  --review F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/verification/20261012-phase4c-01/REVIEW_PACKET.md `
  --out F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/activations/my-activation-plan-01 --json
```

Preparation writes new local evidence only. `plan.json` binds the action, resolved
root and filesystem identity, exact `.codex/config.toml` server/binding/fingerprint,
target path/generation, all runtime/corpus/parent/evaluation identities, pinned
noncache environment files and review packet. It reports the previous generation's
sealed integrity, compatibility and freshness separately. A stale previous source
does not prevent a fresh successor. Integrity is not freshness or human approval.

Required Phase 4B evidence includes the complete stage inputs/results/command
receipts, paired sealed publications, both profiles for every explicit definition,
matching evaluation snapshots/configurations and recomputed meaningful historical
comparisons. Missing evidence, invalid targets, policy denial, incomplete checks
and unresolved regressions block preparation/apply. Frozen labels are never repaired.
This is local integrity checking, not authentication against coordinated forgery by
someone who can edit all local code and evidence.

## Approval and apply

Preparation is not approval. A JSON field, agent review or successful test cannot
establish human consent. After the user authorizes the concrete action, or explicitly
delegates completion including activation, use the corresponding confirmation
route below. For direct terminal confirmation, the operator runs:

```powershell
py -3.11 -B tools/rag/activate.py apply `
  --root F:/Cursor/_Cyrus_Apps/CyrusScatter `
  --plan F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/activations/my-activation-plan-01/plan.json `
  --out F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/activations/my-approved-apply-01
```

Apply requires a terminal and the exact displayed `APPROVE <action> <plan SHA256>
<generation>` phrase. Piped terminal approval is rejected.
The terminal witness binds the reviewed packet and exact plan; it does not prove
personal identity or replace the human authorization in the surrounding workflow.
The mutation worker itself reads the confirmation from its inherited terminal;
its owned start-gate JSON carries no consent and supplied approval claims are
discarded. This is not an authentication boundary against someone who can modify
the code as the same OS user. Fixture approval has an explicit TEST ONLY schema and is accepted
only beneath this checkout's `_local/rag/test-data` with an exact disposable marker;
it cannot authorize this checkout or another arbitrary root.

For an existing explicit user delegation, `apply --delegated-approval <record>`
uses a different, auditable consent kind. The record must be inside this root's
`_local/rag/activations` and contain exactly: `schema` (`cyrus.delegated-activation/1`),
`root`, `plan_sha256`, `target_generation`, `action`, `review_packet_sha256`,
`semantic_review` (`agent; human review not performed`), `user_instruction`, and
`decision_reason`. All identities must match the prepared plan; the instruction
must record the user's real authorization and the reason must explain the reviewed
decision. This route never attests a human semantic review. The worker rereads and
freezes the record rather than trusting caller-supplied consent. It is a record of
authorization in the surrounding conversation, not independent authentication.

Immediately before replacement, apply repeats target integrity/current-policy/
runtime/corpus/all-parent and evidence verification, compares every sealed input
and dependency identity, confirms configuration and lock ownership, and verifies
the approved plan's own bytes and identity. Changed inputs require a new preparation
and a new confirmation. An already selected target is a no-op plan; apply rejects it.

The supported configuration layout is the existing ordinary
`[mcp_servers.cyrus_knowledge]` table with the six explicit adapter arguments (and
optional seventh `--follow-project` argument, followed when enabled by the four
refresh-policy arguments described in [AUTOMATIC_REFRESH.md](AUTOMATIC_REFRESH.md)) in a
single-line array of single-quoted literal strings, matching `cwd` and two-tool
allowlist. Unsupported launch settings, multiline/double-quoted arrays, inline
flags, duplicate arguments/tables and ambiguous layouts are rejected. Only the
index token's byte span is replaced; unrelated bytes and parsed values are preserved.

## Transaction and outcomes

One exclusive `_local/rag/activation.lock` owns each operation. Existing or
abandoned ownership is never automatically removed. Output directories and receipt
names are exclusive, including empty existing destinations. Prior configuration is
fsynced to `prior-config.bin`, protected with owner/system-only Windows DACL or POSIX
0600. Treat that backup as sensitive; never attach or render it. An adjacent fresh
temporary file receives the previous configuration's access policy. `os.replace`
publishes on the same filesystem, followed by parsing, exact byte/binding checks
and a `journal-replaced.json` witness. POSIX directory fsync is used; Windows
power-loss durability is not certified. Partial files/journals are retained.

| State | Meaning |
| --- | --- |
| `prepared` | Read-only plan; human approval pending. |
| `configuration_unchanged` | No successful change observed in this attempt. |
| `configuration_switched_verified` | Binding and isolated client verified; existing desktop sessions unobserved. |
| `configuration_switched_consumer_pending` | Binding changed, acceptance incomplete. Do not assume failure preserved the old binding. |
| `previous_binding_restored` | Explicit rollback completed; target verified usable under current inputs. |
| `recovery_blocked` | Later edit, inaccessible configuration or ownership uncertainty; preserve state. |
| `interrupted_configuration_unknown` | Outer guard stopped/reaped its owned process tree; inspect actual configuration/journals. |

Exit 0 means prepared or successful isolated acceptance, 2 means blocked/failed or
uncertain, 130 means cancellation. No automatic retry or restoration occurs.
Default wall deadline is 90 seconds (including confirmation), maximum 180; owned process trees use Windows
kill-on-close jobs or POSIX process groups. STDIO frames cap 128 KiB, total captured
stdout 1 MiB and stderr 64 KiB; stderr is hashed, never exposed. Readiness bounds
are 3,000 observations/384 MiB, 64 MiB artifacts, existing 16 MiB parents/64-parent
publication scope, and 5,000 noncache environment files/256 MiB. Sealed SQLite
verification retains its progress/read deadlines. These are individually observed
inputs and wall/size bounds, not an atomic snapshot or a count of all kernel I/O.

## Rollback and interrupted recovery

After a switch, prepare a **new** plan with `--action rollback`, the explicit previous
index as `--target`, the same supporting Phase 4B receipt and reviewed packet, and
a new output identity. Run apply against that new plan only after explicit rollback
approval. Rollback verifies its target under current policy/runtime/corpus/parents;
restoring a binding cannot restore old source files. An unusable old target blocks.

Before replacement, interruption normally leaves the old configuration plus backup
and prepared journal. After replacement but before confirmation, the new binding
may already exist even without `journal-replaced.json`. Inspect actual parsed
binding/hash and the prepared proposed hash. Do not infer the state from a missing
success receipt. After consumer failure, retain the switched binding and response
evidence for a reviewed decision. Never blindly copy the backup over configuration.

For a confirmed replacement with no later edit, a fresh approved rollback may add
`--recover-from <prior apply directory>`. It additionally requires exact current
configuration identity matching that operation's replacement journal. A later edit
blocks this recovery path. For an unconfirmed replacement or later edit, inspect
the actual configuration and prepare a separately reviewed fresh rollback; omit
`--recover-from` only as an explicit new decision, preserving the later unrelated
bytes through the new plan. Abandoned locks require checking the recorded PID and
all journals before an operator manually releases that exact lock. The CLI never
does this. Uncertain process identity is grounds to leave it blocked.

A cooperative lock cannot exclude a noncooperating editor. An edit detected before
replace blocks; a later detected edit is preserved. A last-check/replace interval
remains: an external edit in it can be overwritten. There is no portable filesystem
compare-and-swap claim. Serialize editors operationally during an approved switch.

## Consumer acceptance after approval

Preparation verifies the explicit proposed selection using a fresh actual SDK STDIO
server. Apply rereads the actual selected binding and runs full-source status and
`forRanges` identifier search, checking generation, scope and current citations.
This proves only that isolated client's behavior. Existing sessions retain their
original binding until supported reload/restart unless launched with the explicit
`--follow-project` option. That mode pins the current project selection for each
request; configuration alone still proves no actual consumer adoption.

After approval and a successful switch, start a fresh Codex CLI session from this
trusted root (`codex -C F:/Cursor/_Cyrus_Apps/CyrusScatter`), inspect `/mcp`, then
request `knowledge_status` with `verify_sources=true` and `knowledge_search` with
`query="forRanges", mode="identifier", top_k=1`. Retain actual tool events/responses
identifying the target generation and citations. A registration listing or model
statement is insufficient.

For desktop, use the user-controlled supported **Settings > MCP servers > Restart**
behavior after verifying the selected project binding; saving is part of the
documented configuration workflow, not permission to rewrite global settings. Then
open a fresh conversation in this project, inspect `/mcp` and retain the same two
actual tool events. Do not restart existing consumers or create chats without their
separate authorization. [Official MCP guidance](https://learn.chatgpt.com/docs/extend/mcp)
documents project trust, shared host configuration, Restart and `/mcp`. Both fresh
client acceptance checks remain pending until the real switch is approved.
