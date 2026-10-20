# Qualification scopes

**Status: 0.1.3 has actual installation/startup qualification on the exact native46 archive.** Its sixteen functional host suites and complete source map use the strict default policy. Historical 0.1.1 r3 and 0.1.2 archives remain preserved. `build/installer-policy-offline-02/result.json` records 24 passing offline policy checks against that earlier frozen packaging implementation, including input-inventory changes, copied native/UI mismatches, a self-consistent archive/UI rewrite, historical evidence preservation and rejection of incomplete finalization. Those historical policy checks alone do not establish current installer success; each actual run below has separate evidence. An external final `qualification-receipt.json` remains the authority for one exact archive.

| Exact qualified delivery | Actual installer/startup evidence |
| --- | --- |
| [0.1.1 r3 external receipt](../dist/CyrusArrange-0.1.1-r3/qualification-receipt.json) | `build/installer-qualification-03`: 43 installer and 12 automatic-startup assertions; exact native21 runtime pair and preserved functional receipts |
| [0.1.2 external receipt](../dist/CyrusArrange-0.1.2/qualification-receipt.json) | `build/installer-qualification-012-01`: 43 installer and 12 automatic-startup assertions; native28 and all thirteen matching functional suites |
| [0.1.3 external receipt](../dist/CyrusArrange-0.1.3/qualification-receipt.json) | `build/installer-final-013-01`: 43 installer and 12 automatic-startup assertions; native46 and all sixteen matching functional suites |

Version 0.1.3 changes native behavior, headers and functional tests, so deployment-only reuse cannot substitute for its new native/functional evidence. Final native46 supplies its own complete campaign, two paired-performance orders, imported workflow/render trial and fresh book-row gallery. See [0.1.3 release validation](RELEASE_VALIDATION_0.1.3.md). Frozen archive documentation may still say installation was pending at packaging time; the adjacent external receipt records the later result without rewriting that archive. The matching source archive includes current post-qualification documentation and explicitly records its differences from the immutable MZP snapshot.

## Strict default and explicit reuse

Strict qualification remains the default: the current complete input map must match the native build and functional host receipts. The opt-in `--reuse-functional-runtime` permits deployment-only changes while reusing an unchanged, previously tested runtime pair and its original functional receipts. Reuse does not claim those historical runs tested the revised installer.

Only these eight exact paths may differ from the original input map:

| Deployment input | Purpose |
| --- | --- |
| `installer/install.ms` | Actual MZP installation and rollback |
| `installer/mzp.run` | MZP execution entry |
| `installer/CyrusArrangeStartup.ms` | Installed startup verification and loading |
| `installer/CyrusArrange.mcr` | Installed actions |
| `tools/package.py` | Package creation and qualification policy |
| `tools/run_installer_tests.py` | Isolated installer/startup runner |
| `tests/max/installer_tests.ms` | Actual installer tests |
| `tests/max/installed_startup_tests.ms` | Fresh-process installed startup tests |

Every other original input remains frozen, including `CMakeLists.txt`, native source/headers, all five UI scripts, third-party code/provenance, native tests, functional Max tests, shared fixtures, test data, `tools/build.py`, `tools/run_max_tests.py`, `tools/verify_exports.py` and the fixture generator. Path inventories as well as hashes must match; unknown additions, missing inputs and changes outside the allowlist reject reuse. An entire tools, tests or installer directory is not an exemption. Startup/actions must remain deployment glue; moving arrangement behavior into them requires a new dependency/qualification assessment.

## Evidence that must remain unchanged

Original native build and functional receipts are retained byte-for-byte with their complete historical input maps. Each reused functional receipt must match its original build map, exact test identity and both PE hashes, and retain its success, actual loaded-module, private-profile and artist-preservation checks. The current frozen inputs, including all functional fixtures and tests, must still match those original hashes.

Under this reuse policy, a new archive contains the exact original `CyrusArrange.dlx` and `CyrusArrangeStorage.dlh` bytes. The historical 0.1.1 r3 reuse of native21 preserved its ten functional suites and 654 assertions; it did not manufacture new build or test runs. The native21 gallery/visual examples remain artifacts of that exact runtime, with their own manifest hashes and recorded qualification scope. Later changed native sources, including 0.1.2 and working 0.1.3, require their own runtime qualification.

Independent inspector JSON revalidation uses fresh byte-identical copies of the original exports and the unchanged validator, writing new derived evidence outside the historical run. It must not overwrite the original `json-validation.json` or receipts.

## New candidate and deployment qualification

The new candidate records its full current input map, the original map, exact old/new deployment deltas, policy identity and hashes of original build/functional receipts. Its provenance explicitly identifies reused functional evidence. Delivered documentation/examples and every archive member are independently hashed in the payload manifest.

Candidate creation does not qualify installation. The revised archive still requires fresh actual MZP execution in an owned private Max 2027 profile, payload/tamper checks, real publication-failure rollback, repeat/conflict checks and artist-profile preservation. A second fresh process must automatically discover the installed modules, startup script and actions, verify their actual paths/hashes, exercise installed UI/generation and save/reopen, without manually loading startup to conceal discovery failures. The revised installer, test scripts, runner and candidate/archive hashes must match the new evidence.

Candidate validation and finalization continue to require the complete new input map and unchanged archive. Historical failed installer runs and candidates remain preserved; correction produces a fresh candidate and run. Negative policy tests must reject changed runtime/UI/build inputs, fixtures/tests, native modules, historical receipts and unclassified paths. The strict model remains available when scoped reuse cannot establish these boundaries.

Historical 0.1.1 qualification passed in `build/installer-qualification-03`: 43 installer and 12 automatic-startup assertions for unchanged r3 archive `3b39b92867b9fed0984fde8555ff3533adc8f448f03cb34b417600df3b67e55d`. Qualified 0.1.2 separately passed `build/installer-qualification-012-01` with the same assertion counts for archive `6d50cc1e2511851c907a1ab8f3b7bce146acce0c33de583b5248c4a98a03d703`. Their adjacent external receipts are authoritative. Prior failed r1/r2 archives and runs remain preserved; neither success qualifies the working 0.1.3 candidate.
