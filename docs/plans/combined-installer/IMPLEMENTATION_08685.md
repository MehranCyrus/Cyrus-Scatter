# Combined three-host installer — 0.86.8.5

22 October 2026. The user explicitly requests one shareable EXE for Max 2024,
2026 and 2027, installing both Scatter and Surface Analyzer. This request
authorizes these older-host builds and owned tests for this delivery only.

## Version and scope

Use Scatter 0.86.8.5 because the already-delivered 0.86.8.4 installer gains a
second installed product and two target hosts. Preserve the old artifacts.
Analyzer stays 0.14.1; its calculation/script contract and schema remain unchanged.
Scatter keeps schema 59, recipe 8, CyrusUnified2 and original Paint. The EXE
contains all six matched plugin payloads; plant content remains separately
versioned 0.86.7 and optional. Deliver only the EXE link to the user.

## Ownership, publication and bounds

The existing Scatter installation engine owns Scatter registration and shared
library configuration. A small Analyzer installer owns only its immutable
script/native runtime, startup wrapper, receipt and exact Analyzer INI key.
Both use bounded local paths, verified payloads, filesystem helpers and checked
registration recovery. No downloaded code or extracted MAXScript is executed.

Analyzer preparation verifies its complete native/script/startup set before
changing bindings. Known original startup wrappers are recognized exactly;
unknown or receipt-mismatched edits are retained. Original legacy wrappers are
backed up. Runtime copies stream with bounded buffers and conservative disk
admission; no plant library is unpacked to temporary storage by default.

Preflight every selected host and both products before publication. Each product
has its own recovery journal and complete matching runtime. Products and hosts
publish serially because they share host registration files. This is not a
global transaction across independent products/hosts: a later failure reports
which earlier installations completed and can be retried without duplicate
runtime copies. Scatter-only Uninstall stays explicitly labeled and retains
the independently installed Analyzer. Existing scenes, recipes, activation and
runtime recovery folders are preserved. Installation has no scene Undo work.

No Max process is launched or restarted by the installer. Tests use redirected
owned profiles, loaded-path/hash witnesses, and explicit process ownership.
No artist-profile installation, Git backup or website deployment is authorized.

## Implementation and acceptance

1. Record baseline identities; update Scatter labels/catalog to 0.86.8.5.
2. Add managed Analyzer preparation/installation and embedded host descriptors.
   Reuse existing bounded filesystem/INI primitives; preserve Scatter journal
   format and behavior. Give failures host/product/file context.
3. Build matched Scatter modules/gallery and Analyzer modules with each SDK.
   Require clean source-bound native receipts; do not substitute a neighboring
   host's native binary. Retain unchanged qualified Analyzer 2027 bytes only if
   all producing source and artifact hashes still match.
4. Produce guarded MZPs internally and embed all six in one EXE. Verify archive
   CRCs, manifests, script/native correspondence, embedded package identities,
   version/host guards and absence of private diagnostic modules.
5. Run meaningful filesystem/actual-EXE tests for fresh/repeat/legacy migration,
   edited target rejection, tamper, cancellation, publication interruption,
   recovery and independent product status. Check three host cards and title
   layout with scripted scale checks, separately from physical DPI acceptance.
6. Validate exact installed script/native pairs and Analyzer functionality in
   owned Max 2024/2026/2027 processes. Cover representative clearance, optimized
   export, dense Bands, Manual state, save/load, Undo/Redo and startup reuse.
7. Seal exact EXE/payload/build/loaded/test identities, document scoped results
   and remaining physical/renderer/soak limits, and provide only the final EXE.

This plan is not a qualification receipt. Record actual failures and final
acceptance separately without rewriting previous receipts.
