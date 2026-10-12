# Bounded mechanical refresh

`automatic_refresh.py` provides an explicitly authorized update process. It is not a
knowledge tool and is not implicitly started by a search. No production refresh
policy or background service is enabled merely by adding these files.

The implementation supplies `prepare`, `tick`, and a bounded `watch` loop, plus
optional adapter supervision for the lifetime of a Codex connection. Use the actual completion handoff for the
installed generation and activation state.

## Authorization and scope

`prepare` freezes a fresh baseline, full parent snapshots, paired evaluation
receipts, branch, current inspection policy and exact known helper hashes. It
writes a new immutable `policy.json` under `_local/rag/refresh/`. Creating that
proposal does not change registration or enable the watcher. Passing its exact
SHA256 to `tick` or `watch` authorizes mechanical activation within that scope;
it is not a human semantic-review attestation.

The registered adapter must explicitly use `--follow-project` before an automatic
activation. Its two tools remain read-only. Each call pins one generation and
reports that identity; no result combines two indexes.

The refresh process permits changes only to already enrolled current parents.
Historical, unknown and delivered evidence remains immutable. Partial ranges must
still occur exactly once as complete lines. Every required, optional and misleading
evaluation interval must also survive exactly once, with questions, qualifiers,
answerability and evidence requirements unchanged. A changed or ambiguous interval
requires review. Full-parent enrollment can include new content, but the successor
explicitly labels changed parents as mechanically refreshed and not newly
semantically reviewed. Retrieved text remains untrusted data.

No source is enrolled, authority promoted, runtime approved, threshold lowered,
reference conclusion rewritten or ranking regression accepted automatically.
Runtime, policy and catalog-provenance changes require a new explicit review.

## Execution

After preparing and reviewing a current baseline, use absolute paths from its
receipts. For example, from the repository root:

```powershell
py -3.11 -B tools/rag/automatic_refresh.py prepare --root $repo --index $index `
  --evaluation $plainReceipt --evaluation $terminologyReceipt `
  --out $freshPolicyDirectory --reason 'Approved bounded mechanical refresh scope'

py -3.11 -B tools/rag/automatic_refresh.py tick --root $repo `
  --policy $policyFile --policy-sha256 $reviewedPolicySHA256

py -3.11 -B tools/rag/automatic_refresh.py watch --root $repo `
  --policy $policyFile --policy-sha256 $reviewedPolicySHA256 `
  --interval 60 --max-seconds 43200
```

`prepare` accepts one to four evaluation definitions, each represented by both
plain and terminology receipts. It requires their exact baseline generation.
The variables above are explicit reviewed paths and identities, not automatic
selection of the most recently named output directory.

To attach the reviewed watcher to a connection, the registration's argument array
must contain the original six adapter arguments followed, in order, by
`--follow-project`, `--refresh-policy`, the absolute policy file,
`--refresh-policy-sha256`, and its exact lowercase SHA256. The matching flags must
also be present on the actual adapter process. Registration is a separate explicit
enablement step; preparation alone does not authorize a connection to start work.

The supervisor checks the policy bytes, root, registered authorization, current
inspection policy and approved helper identities before launching an owned worker.
Denied helpers are inspected as policy data before any content read. The worker
receives its start gate only after its process-tree ownership is installed.
The control pipe remains open for that connection's lifetime. Its observer polls
without retaining a buffered stdin lock and joins before interpreter shutdown,
including when another connection already owns the lease. EOF requests graceful
cancellation; after three seconds the owned process tree is stopped. Separate
connections contend for one root-scoped OS lease; they cannot concurrently refresh.
Each supervisor rechecks authorization every 30 seconds and backs off for 60 seconds
when its worker ends. A tool call remains read-only and does not await a rebuild.

For changed eligible inputs, one operation:

1. Freezes current parent bytes and rebinds exact surviving evidence locations.
2. Runs two complete audits and compares their observations and artifacts.
3. Builds and verifies two indexes; evaluates both profiles of every definition
   against both indexes; compares paired exports and each historical baseline.
4. Rejects any existing question-level coverage, precision, ranking, misleading-hit
   or unanswerable-result regression. Original shortcomings are not erased.
5. Rehashes all sources and verifies real isolated STDIO status/search responses.
6. Rechecks registration, runtime, policy, Git provenance and inputs; uses the
   existing byte-preserving activation transaction to replace only its index token.

The previous index, receipts, definitions and private configuration backup are
retained. A failure before replacement preserves registration. A failure after
replacement reports `recovery_required`; inspect the transaction journals and
actual binding instead of restoring over a later edit. A successor becomes an
automatic baseline only with matching readiness, commit and selection witnesses.

## Bounds and operation

Only one preparation and activation transaction may own their respective existing
locks. The watcher additionally uses an OS lease, which releases on process death.
That lease never authorizes removing an abandoned preparation or activation lock.

Stages use existing owned subprocesses, captured-output limits, policy guards,
SQLite deadlines and aggregate read bounds. Each stage is limited to 90 seconds;
the operation checks a 1,800-second total budget. Sources retain the detector's
64-parent, 16 MiB per-parent and 32 MiB aggregate limits. No network service, OS
scheduled task, vector database or new dependency is installed.

The watcher polls every 30–3,600 seconds. A session schedules checks for at most
12 hours; a running bounded operation finishes or fails before the loop exits.
An identical failed input signature is not rebuilt repeatedly, including after a
watcher restart. Changed input bytes or explicit `--retry` allow another attempt. Branch/HEAD, current
registration and bounded actual parent hashes contribute to that signature.
Recovery uncertainty stops the loop. Runtime or policy incompatibility stops it
for review. `watch-status.json` reports the last outcome and whether the watcher
has stopped; it is operational state, not a validation receipt.

The watcher does not infer developer intent or certify changed code. Changes to
gold evidence are deliberately held for review. Automatic refresh therefore
reduces routine maintenance while retaining a clear review boundary.

## Validation

```powershell
py -3.11 -B -m unittest discover -s tools/rag/automatic_tests -v
& '_local/rag/mcp-venv/Scripts/python.exe' -B -m unittest discover -s tools/rag/adapter_tests -v
```

The disposable tests exercise real paired builds/evaluations, regression rejection,
STDIO calls and configuration replacement. The connection lifecycle test changes
an enrolled fixture, observes the adapter's own worker activate a fully checked
successor, reads it on that same connection, and verifies worker shutdown on EOF.
Transport tests also exercise a running connection adopting a different generation and failing closed on invalid
registration. These witnesses do not establish fresh Codex desktop acceptance or
production enablement; those are separate final integration checks.
