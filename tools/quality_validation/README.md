# Owned Max 2027 regression suite

This suite is developer test infrastructure. It is never included in plugin
packages or exposed through the product's MCP write API. It creates disposable
scenes only in explicitly launched profiles beneath the repository's `build/`.
It does not target the artist's open Max process.

`host.py launch` stages a matched Scatter/Brush/Edit/Gallery/Analyzer payload,
verifies loaded module paths, and records product, fixture and driver hashes.
`host.py run --scenario <ID>` sends one request and accepts only a complete JSON
result with the exact run/request/scenario/artifact identities and required unique
assertion IDs. Missing, malformed, duplicate, stale or empty results fail closed.
A timeout requires observation of the original request; it must not be replayed.

`bind-suite` permits an explicit successor fixture revision only after the prior
request has terminated and the staged, loaded product bytes still match. It preserves
the previous qualification metadata and creates a new run and artifact identity.
Repository edits cannot change that running candidate's frozen identity. Final
delivery separately compares its producing build receipt with current source.
Changing the loaded product pair requires a fresh owned Max process. Installer scenarios
also hash their embedded Python driver. The `installer.py` driver verifies every
destination belongs to its owned profile before executing the packaged Analyzer
installer. Its Qt notice handler dismisses only this process's Analyzer notices.

`common.ms`'s `QClick` dispatches native control mouse messages. Max `CustButton`
does not implement `BM_CLICK`. These tests exercise generated controls and their
handlers, but they do **not** establish physical mouse input, focus, DPI or viewport
responsiveness. Record separate Computer Use evidence for those claims.

The scenario manifest describes the approved acceptance targets. File presence,
a partial fixture, or a passed subset is not proof of the entire target row.
Reports must list executed scope and any missing subcases. `R1-M01` requires the
preserved legacy Analyzer pair; the mixed-pair/restart portion of `R1-M02` needs
separate profiles. `R5-M05` is the offline template extraction comparison.

Qualification builds use `offline_build.py`'s clean compilation. Retrying an
incremental build after a failed textual `.inc` compile previously allowed an old
object to survive despite current input hashes; a source hash alone cannot prove
object correspondence. Current packaging requires the clean-compilation receipt.

## Rollout and installer correction witnesses

The launcher now redirects `ADSK_3DSMAX_APPDATA_DIR`, `ADSK_3DSMAX_USERSETTINGS_DIR` and `ADSK_3DSMAX_USERTOOLS_DIR` in addition to the INI directories. `-i` alone does not isolate rollout preferences.

`build_rollout_fixture.py --output build/installer-panels-08684-20261022` builds an unregistered private Max 2027 SDK helper. `UI84-SDKORDER` uses it to seed a custom saved category, exercise the real visibility helper and reselect three times while preserving published rows and a pending Manual amount. It is an SDK reorder witness, not physical drag/DPI proof. The helper binaries and C++/C# sources are bound into the scenario identity and never packaged.

`installer_upgrade.ps1` tests exact packaged migration, byte-preserving backups, unknown/edited rejection and every registration publication checkpoint in disposable paths. `InstallerUiChecks.cs` exercises the actual EXE handler and configured 100/150% rendering; `scatter_installer.ms` loads the exact packaged installer core in owned Max 2027. The [0.86.8.4 report](../../docs/plans/installer-panels/DELIVERY_08684.md) records run identities and limitations.
