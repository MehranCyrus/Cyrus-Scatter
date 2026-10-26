# Scatter 0.87.3 — three-host installer

26 October 2026. The user explicitly requested the current EXE for **Max 2024, 2026 and 2027**, website/knowledge updates and Git publication. This packaging does not change the product version or add collider features. Exposed-root fitting remains on hold.

## Installation

Save work and close the target Max versions. Run [CyrusScatter-0.87.3-Setup.exe](../../../dist/CyrusScatter-0.87.3-20261026/CyrusScatter-0.87.3-Setup.exe), select the intended hosts and choose **Install / Update**, then reopen Max. Standalone MZPs use **Scripting > Run Script**, followed by a restart. No artist installation or restart is performed by this task.

Scatter payloads are distinct matched SDK/native/managed packages. The Max 2027 MZP is byte-identical to the [qualified Library correction](LIBRARY_STARTUP_0873.md). Newly compiled 2024/2026 native suites run separately; no 0.87.3 host execution in those older versions is claimed. Their earlier 0.87.1 library passes retain their original identities and do not certify this successor.

The combined EXE includes independent **Surface Analyzer 0.14.2**, rebuilt from unchanged native/script source with the current shared installation helper. This is repackaging, with no new Analyzer runtime qualification. Installed plant content stays **0.86.7** and is optional; plugin-only updates preserve it. Max 2025 support is not implied.

## Evidence and limitations

Exact EXE/package hashes, matched producer receipts and verification results are in `dist/CyrusScatter-0.87.3-20261026/COMPATIBILITY_RECEIPT.json` and `SHA256SUMS.txt`. The original 0.87.3 qualification remains unchanged. Archive/embedded mapping checks are separate from running an installer transaction or exercising every host UI, renderer, drag and long-session case. Current code, static website build and selected knowledge generation retain distinct evidence.

Recipes preserve supported static assets with default OCIO and matching profiles; they explicitly reject contact roles/preparation and custom collider links. Save complete interaction Max scenes as copies. B37 copied Edit lineage, B38 installed-model merge Undo history and B40 automatic exposed-root fitting remain separate open scope.

Executed: Max 2024 **59/59** and Max 2026 **59/59** Scatter native tests; retained Max 2027 **59/59**. Rebuilt Analyzer core passes **1/1 per SDK**. The exact EXE passes **58/58 owned-profile installer checks**, including repair, altered-file rejection, cancellation rollback, retry and personal-file preservation. Tests never launch Max or target artist profiles. Receipts: `build/release0873-20261026-01/installer-tests/receipt.json`, the compatibility manifest and original native producer receipts. An initial attempt to reuse older Analyzer receipts was correctly rejected because shared build inputs had changed; fresh native producers replaced that attempt.
