# Research verification receipts

These files qualify the research package's provenance and consistency. They do not qualify a new plugin build or a trained model.

| File | Meaning |
| --- | --- |
| [source_snapshot.json](source_snapshot.json) | SHA-256 inventory of 488 source/tool files, HEAD and branch at research start |
| [git_status_before.txt](git_status_before.txt) | Tracked/untracked status before research documents were populated; the new research directory already existed |
| [docs_index_before.sha256](docs_index_before.sha256) | Hash of the pre-existing documentation index before its one-link addition |
| [mcp_offline_tests.txt](mcp_offline_tests.txt) | Fresh existing-suite result: 66 tests passed in 8.15 seconds |
| [renderer_log_observation.json](renderer_log_observation.json) | Hash and bounded count from an existing private-session Corona log; not a new runtime test |
| [source_ledger_index.json](source_ledger_index.json) | Machine-readable extraction of the 40 annotated primary-source entries |
| [package_validation.json](package_validation.json) | Local links, examples, source preservation and documentation consistency checks |
| [package_validation_first_pass.json](package_validation_first_pass.json) | Preserved first-pass validation, before vendor-documentation amendments |
| [second_pass_before.json](second_pass_before.json) | Starting document hashes, source comparison and Git scope for the second pass |
| [docs_index_second_pass_before.json](docs_index_second_pass_before.json) | Preserves the newer shared-index baseline outside our paragraph; other documentation updates since the first pass remain intact |
| [vendor_source_index.json](vendor_source_index.json) | Machine-readable extraction of 25 selected official vendor documentation entries |
| [vendor_sdk_crosscheck.json](vendor_sdk_crosscheck.json) | Local SDK header and CMake-cache fingerprints; no build or loaded-DLL verification |
| [second_pass_completion.json](second_pass_completion.json) | Additional fragment-link/heading check, changed-package scope and ending Git status |

## Fresh offline test

Executed during the **first pass** from the repository root using the existing virtual environment; no dependencies installed. This unchanged-suite result was not rerun or relabelled as fresh during the second pass:

```powershell
& 'build/mcp-venv/Scripts/python.exe' -m pytest CyrusMCP/tests -q -p no:cacheprovider --basetemp build/research-20261005-pytest
```

The suite includes an actual local stdio protocol handshake and test-host service/transport checks. It does not launch Max or qualify renderer/UI behaviour. The source audit describes its coverage and limitations.

## Package check

The documentation-only [validator](../validate_package.py) checks local Markdown targets, JSON parsing, synthetic example references, ineligible training defaults, both source ledgers, the 18 experiment IDs and current source/inspected-SDK hashes. It checks that our second-pass index amendment preserves all content outside the research paragraph against its separately captured baseline. The shared index received other documentation updates after the first pass; the original hash and first-pass receipt remain preserved, and the validator reports that difference explicitly rather than erasing those updates.

```powershell
& 'build/mcp-venv/Scripts/python.exe' 'docs/AI_Design_Learning_Research_2026-10-05/validate_package.py'
```

The validator writes the current validation and two extracted-ledger JSON receipts inside this folder. Source preservation is a **point-in-time** check against this research snapshot. Future intentional source edits will make that historical comparison fail; that does not imply the later edits are incorrect. Markdown-link existence does not validate the contents of historical reports, and public URLs are research citations rather than remotely fetched by this validator.

## Boundaries

No Max host was launched, controlled or closed. No scene/profile/installer/licensing implementation was changed. No model or external dataset was downloaded, trained or evaluated. Research findings were synthesized from primary sources; no paper result is presented as a Cyrus reproduction. Production runtime risks remain open until their planned experiments are executed.
