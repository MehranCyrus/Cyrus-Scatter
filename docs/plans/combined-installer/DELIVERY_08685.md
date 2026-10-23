# Combined Scatter 0.86.8.5 / Analyzer 0.14.1 installer

22 October 2026. **Scoped Max 2024 / 2026 / 2027 test delivery.**
The user explicitly requests a single shareable Windows EXE for Max 2024,
2026 and 2027, installing both products. See the
[scope and version decision](IMPLEMENTATION_08685.md).

## Implementation

The EXE embeds three Scatter MZPs and three independently versioned Analyzer
MZPs. It validates complete archive hashes and closed host descriptors, without
executing extracted scripts or downloading plugin code. Each host receives its
matching SDK/native/managed payload. Analyzer remains 0.14.1; Scatter keeps
schema 59, recipe 8, CyrusUnified2 and original Paint behavior.

Scatter and Analyzer registration preflight runs for every selected host.
Analyzer stages/verifies its native/script pair before switching its startup,
receipt and exact INI key. It reuses the existing MZP runtime identity. Legacy
startup recognition is exact, with byte-preserving backups. Unknown edits and
receipt mismatches are preserved. Runtime repeats avoid a second staged copy.
The long-backup-path limit is checked before registration publication.

Small internal filesystem/INI/journal helpers are shared with the existing
Scatter engine; its journal format is preserved. An oversized journal is rejected
before it can become unrecoverable. Scatter's explicit registration preflight
recovers its prior journal before ownership checks; passive Plan remains read-only.
The known no-receipt Scatter allowlist now also includes exact 0.86.8.4 wrappers.

Each product has its own journal. Products and hosts install serially, preserving
unrelated INI entries. This is not a global transaction across all products and
hosts. A later failure reports completed installations and permits retry.
Uninstall is explicitly Scatter-only; independent Analyzer and content remain.
The installer does not launch/restart Max or modify scenes, recipes or activation.

## Evidence

Owned run: `build/combined-installer-08685-20261022/`.

- Clean Scatter SDK builds pass 51 native tests in each of Max 2024/2026/2027.
- Analyzer 2024/2026 clean builds pass the native core test. Unchanged qualified
  2027 Analyzer source and binary hashes are reverified against its original receipt.
- Candidate03 copied EXE passes 134 filesystem/actual-handler checks, including
  three host cards, configured 100/150% rendering, both-product preflight,
  repeat/recovery/legacy backup, modified-file preservation, commit-tail cases,
  shared-target/running-host rejection and Scatter-only uninstall retaining Analyzer.
- Earlier candidate attempts and failures remain preserved. Candidate01 exposed
  the long-backup-path admission gap; candidate02 passed 110 checks before the
  additional Scatter preflight was added and qualified by candidate03.
- Final package migration tests pass **61 checks per host** on the exact current
  core/MZP pair. Full Python regression passes **192 tests**, with **16 focused
  checks** repeated after the fixture/owner-guard changes. Generated/catalog
  checks pass for 332 controls; these do not compile MAXScript.
- The exact EXE installs both products in owned profiles. Max loads their actual
  installed startup wrappers automatically; loaded paths and SHA-256 values
  match all five native modules and the paired scripts/gallery.
- **39 functional cases per host** pass, covering Analyzer ownership/freshness,
  original Paint preservation, optimized exports, dense Bands, source/material
  access, Manual state, lifecycle/Undo, and schema58 upgrade/schema59 merge.
  Max 2024 uses 38 original cases plus the explicit top-level Live successor.
- Max 2024's original fixed-delay and nested-helper Live witnesses failed and
  remain preserved. A direct trace and the top-level message-pump successor
  verify one settled update for resolution, parent transform and animation,
  unrelated-edit idleness and no repeated work. Its observed update waits are
  312/642/332 ms; this is not a latency guarantee. The exact reason for the
  nested-helper scheduling difference remains unestablished. No Analyzer
  implementation change or concealed test pass is claimed.
- Early path-separator and staged-profile assumptions in the test witness were
  corrected before acceptance. Explicit fixture successors retain predecessor
  metadata; they do not alter the frozen installed product pair.
- UI stress cases can take substantial time; the largest observed original
  case took about 175 seconds. This is functional evidence, not a responsiveness
  or presented-FPS claim. Prior panel-performance acceptance remains open.
- All six owned Max test processes are closed; artist sessions/profiles were
  not installation targets. The [delivery seal](../../../build/combined-installer-08685-20261022/delivery-seal.json)
  binds builds, exact EXE/payloads, source/loaded paths and individual results.

## Distribution and remaining limits

The user receives only the final EXE. Guarded MZPs and manifests remain available
internally as embedded payloads and recovery artifacts. The plant library is
optional, unchanged content 0.86.7, and separate from the EXE. Existing compatible
content is reused. Without it, both plugins work with scene models; a fresh
library recipient needs the separate content package. Renderer/material plug-ins
needed by that content remain external dependencies.

Final executable:
`dist/CyrusScatter-0.86.8.5-20261022/CyrusScatter-0.86.8.5-Setup.exe`
(6,034,944 bytes). SHA-256:
`aba37510f1fa5afb8ae2ae33b549c6afc790434c15a298770ed5f1b9d06e82c1`.
Close selected Max versions, run the EXE, select their cards and Install/Update.
Both products install together. Reopen Max afterward; no separate Analyzer MZP
is needed. Plant content remains optional and independent.

No Max 2025 support is inferred. Scripted SDK/control tests do not qualify physical
drag, mixed DPI, all shaders/renderers, true device loss or long-session soaks.
No artist installation/restart, Git push or website deployment is performed.
Knowledge indexing is a separate maintenance operation and is not refreshed
merely to conceal the source changes in this delivery.
