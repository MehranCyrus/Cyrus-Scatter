# M03 — Independent native recipe readers

24 October 2026. Native prerequisite implemented and tested; **MCP recipe
grant/search/inspect and approved use remain pending**. This adds no public MCP
tool: current source discovery remains sixteen tools / seven resources.

## Why this boundary

Source inspection found that `cyrusRecipeLibraryStart/Page/Cancel` owns one
process-wide `Library` used by the normal recipe browser. Starting an MCP scan on
that singleton could replace a completed browser catalog; cancellation could also
interfere with another owner. Blocking the artist browser while an AI scans is
not an acceptable ownership contract.

The implementation adds `cyrus::recipes::Catalogs`, a small owner registry around
the **same existing `Library` worker and recipe `summary` engine**. The gallery's
existing API/version 4 and default limits remain intact. No alternate recipe
parser, importer, content store or placement engine is introduced.

New native bridge API, intended for the forthcoming local MCP adapter:

| API | Contract |
| --- | --- |
| `cyrusRecipeCatalogVersion()` | Returns 1; source/loaded capability probe, independent of the existing gallery API version |
| `cyrusRecipeCatalogOpen(root)` | One absolute folder, independent monotonically issued handle, file-only background scan |
| `cyrusRecipeCatalogPage(handle, search, category, page)` | Existing 13-field native page/17-field summary format; opaque owner isolation, same bounded search semantics |
| `cyrusRecipeCatalogClose(handle)` | Revoke exactly that handle and request its worker cancellation; no join of a running worker |

The raw native page includes paths and is **not** an MCP response contract. Remote
clients have no arbitrary native-call facility. The adapter must sanitize and
bound metadata before marshalling, issue opaque recipe references, explain
omissions and never treat discovery as permission to apply a recipe.

## Ownership, work and failure contracts

- At most **two readers total**, including closed workers still stopping. A third
  open rejects while both slots are occupied. Gallery ownership is separate.
- Each reader admits at most **256 candidate entries**, **8,192 directory
  entries** and **2 MiB cached native metadata**. Recipe manifests already have
  the native **8 MiB** input limit. Those are admission limits, not measured peak
  heap/RSS values; parsing, page copies and the independent gallery also cost memory.
- The registry and native bridge run on the caller/host thread. Workers receive
  copied paths and use filesystem/recipe code only; they touch no Max scene API,
  Paint hydration, selection, authored setting, placement or publication.
- A confined reader rejects relative and UNC roots and linked roots/ancestors,
  recipe files, metadata sidecars and package-manifest directories. It uses the
  existing attachment containment checks. It does not recursively traverse a
  directory tree. Mapped-drive policy and adversarial filesystem replacement
  races are not established by these checks.
- Invalid recipes are counted; entry/metadata limits are reported; a missing
  folder produces a terminal error rather than an empty success assertion.
  This is a catalog verdict, not model/map/Paint payload integrity validation.
- Open failure removes the unissued owner. Closed handles reject reads/repeated
  close; a later reader receives a larger handle. No stale handle can cancel a
  replacement or the gallery.
- Close marks its owner closed and requests cancellation. A nonterminal worker
  stays budgeted. Only terminal closed workers are reaped/joined. Shutdown destroys
  workers through the existing pre-unload notification; registration is shared
  once between the gallery and new registry to avoid duplicate registrations.
- No scene writes occur, so there is no scene Undo entry. Actual application will
  need a separate exact proposal, dependency/scale checks, effect ownership and
  tested transaction/Undo behavior.

Relevant foundation boundaries: F06 bounded work/resource lifetime, F07 host-thread
access and worker lifetime, and F11 persistence. Existing F01 layer/area owners
remain unaffected. Worker handles are transient process identities and must never
be persisted as recipe/task identity.

## Source and qualification evidence

Changed native sources: `AminScatter/include/recipe_library.h`,
`AminScatter/src/recipe_library.cpp`, `AminScatter/src/recipes_bridge.cpp`,
`AminScatter/tests/recipe_catalog_tests.cpp` and its CMake registration. Existing
gallery defaults remain unchanged. The private MCP foundation driver now expects
the actual sixteen-tool source server rather than its stale fourteen-tool count.

1. **Clean Max 2027 SDK build and all 57 native tests pass**, 23.91 s test phase:
   `build/mcp-recipe-catalog-20261024-01/receipt.json`. Native input manifest:
   `c70ffd72b008ff06cbbadf23717d4fd56ce2d222dc1c2f1357860b792d0561dc`.
   The new executable runs **30 checks**, including actual Windows linked
   root/file/sidecar/package cases, independent gallery/readers, entry/metadata
   limits, invalid/missing input, cancellation, stale handles and owner destruction.
2. Generator/control integration check passes: **333 controls**, 32 fixture
   delimiter checks, generated script hash
   `2a122fc2012b69b887363e5878b36be19ace409141da5bf5248c599332b1c17c`.
   This check alone does not compile MAXScript or qualify host UI.
3. **432 Python tests pass in 35.81 s**:
   `build/mcp-recipe-native-20261024-01/offline.xml`.
4. Owned Max 2027 **PID 32436**, verified matched internal prototype, now closed:
   `host01/recipe-native-campaign.json` and `recipe-native-result.json`.
   Gallery retains **301** recipes while an independent reader admits **256** and
   reports its limit. A second reader reports one valid and one invalid recipe.
   Closing/cancelling one leaves the other's page and full gallery page digest
   unchanged. Replacement/stale handles, relative/linked root and missing-folder
   cases pass. Before/after node count, transforms, selected handles, Undo names
   and initially false save-required flag match exactly.
   Twelve Qt timer callbacks run during the 0.947 s native fixture. This demonstrates
   event-loop progress in the case, not a UI latency/FPS benchmark or whole-session
   responsiveness guarantee. Native API artifact:
   `a1ffec23ebe2f9d06c3b253b2b3272ee01154085ce782d660b8f7bb3ee6a4d45`.
5. Existing real SDK creation/export, static time, pre-publication rollback,
   committed failure and local retirement regression passes on the new prototype:
   `host01/foundation-results-3fe884c41e4841a59ac60671ff784c55.json`.
   **201 actual accepted rows from 240 candidates** match export/publication;
   exact-key retry and unshared-trace denial pass. Recovery retirement leaves the
   native scene unchanged. Later explicit suite rebind artifact:
   `7384d8c69accf7ffc3b072f8e76e09aa6b5eb177684998219ca8a56b2fd6354c`.
6. `host01/increment-receipt.json` verifies all **26 frozen MCP runtime files**
   against current runtime source and all **five loaded native module hashes**
   against the staged matched payload. Previous qualification manifests are retained.

The staged payload uses the completed current Scatter native receipt and matching
generated script/gallery plus the verified Analyzer 0.14.2 producer. It is an
**internal prototype with the existing 0.86.9.2 caption**, distinguished by exact
hashes, not a newly versioned delivery. The earlier packaged 0.86.9.2 baseline and
its receipts remain unchanged; this does not silently replace their qualification.
No product release version, installer delivery, artist installation/restart, push
or deployment occurs. Full release impact/version selection and a matched Max
2027 MZP remain part of the later user-testing delivery workflow.

Repository knowledge status was stale on full-source verification, and the exact
recipe-library path was outside the reviewed corpus. Decisions above rely on
direct current source inspection and the named fresh receipts; no corpus refresh
was performed. These tests do not qualify physical artist interaction, all native
features, model dependencies or recipe application.

## Next implementation and acceptance

Connect these independent readers to explicit local personal/custom recipe-root
grants in the existing task panel. Add bounded/sanitized recipe search and entry
inspection, honest scan progress/error/limit states, stable snapshot references,
revocation on reset/open/disconnect/close, and capability denial on builds without
the new API. Keep worker cleanup independent of gallery use and scene writes.
Do not issue stable entry/page references while a worker is still scanning and
sorting. Publish a frozen metadata grant only after a terminal scan without a
fatal folder error; retain explicit invalid/limited/omission evidence.

Qualify those typed operations through the real SDK and matched Max pair before
enabling preset/recipe application. Then implement actual source-scale/dependency
readiness and exact approved use through the existing native engines; retain O66–O68
and the wider M03/M04/M09/M12/M13 gates as open.

Successor: [typed recipe discovery](M03_RECIPES.md) now connects local grants and SDK inspection to this reader. It also records the long-path guard/fixture correction and newer matched receipts. Evidence above retains its original identities; application remains pending.
