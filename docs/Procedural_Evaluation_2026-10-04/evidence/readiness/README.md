# Readiness evidence — 4 October 2026

Source commit: `53bfc5d1c76929958dbeb29f5d4c746b2321d0ac`.

This follow-up extends the initial documentation-only investigation. It tests the **current** numerical core and MCP implementation, then checks specific mathematical/design counterexamples. It does not implement or test the proposed full evaluation policy inside 3ds Max.

## Reproduction

From the repository root, using the existing Python environment and installed pinned compiler/Node/CMake:

```powershell
& build/mcp-venv/Scripts/python.exe docs/Procedural_Evaluation_2026-10-04/evidence/readiness/run_checks.py
& build/mcp-venv/Scripts/python.exe docs/Procedural_Evaluation_2026-10-04/evidence/readiness/contract_probes.py
```

The runner creates an ignored `build/procedural-readiness-<short-commit>/` directory. It sets `AMIN_BUILD_MAX=OFF`, builds the pure numerical library/tests and [native probe](native_readiness_probe.cpp), runs CTest, regenerates UI in a copied generator directory, compares text-normalized artifacts, and runs current MCP tests using isolated local/mock/offline-stdio fixtures. It never installs a plugin or changes a Max scene. It writes logs and [checks.json](checks.json) here. A rerun updates those logs; copy the evidence folder first if retaining multiple campaigns.

## Results and interpretation

- [native-tests.txt](native-tests.txt): 12 existing test entries plus the readiness probe, all passing. Includes the existing exhaustive group-spacing comparisons and Brush/sampling/threading tests.
- [native-probe.txt](native-probe.txt): current-code area/identity, cleanup-release and single-pass cleanup observations, plus a mathematical shear witness.
- [mcp-tests.txt](mcp-tests.txt): 61 passed; no real Max application or enrolled artist scene was used.
- [generator.txt](generator.txt): isolated generation; both script and inventory text agree with tracked artifacts.
- [contract-probes.json](contract-probes.json): exact-rational quota counterexamples, two-candidate cleanup/cache schedule illustration, repeated coverage thinning and a static control/key inventory.
- [verification.json](verification.json): source preservation, documentation-link and evidence checks for the final review.

The native probe's attribute-change counters describe an intentional old-generation dependency, not a failing native test. Improved attribute stability would be a **versioned new contract**. Its cleanup example composes native operations explicitly; it does not claim a production refill orchestration exists. The shear witness compares a known matrix bound mathematically; it does not execute the Max transform bridge.

The tiny Python replay fixture is a reasoning counterexample, not a validated implementation of the proposed layer solver. Its empty result at batch size one illustrates the bias of transaction-local suppression; it must not be presented as a recommended default schedule.

No FPS, memory scalability, Max SDK DLL load, interactive UI, renderer, production refill, or ML quality claim is supported by this campaign. Historical Max evidence remains in its original dated reports.
