# Owned configure and Update transactions

Implementation increment for M01/M05. The scoped native/API cases below pass; this does not close either milestone or qualify an installed release.

## Contract

`scatter_validate_change` proposes `cyrus.owned-change/1.0` with the current context, controller, published generation and configuration IDs. It reuses local exact-digest approval, `scatter_apply_plan`, durable operation records, original-key retry, queued cancellation and status queries. No approval or enrollment tool is added.

- `configure`: change explicit count/seed fields on existing owned layer IDs. Require Manual on root and children. Keep the previous complete publication, its generation and export; report the newer configuration as pending. No solve or replacement of layers/masks is allowed.
- `update`: calculate the current owned configuration, without implicit patches. Preserve layer/source/mask identities and update modes; publish a new generation only after final row/constraint verification.
- `configure_and_update`: apply the explicit patches and calculate atomically in the same hold. Restore the previous authored state and complete publication on a failed successor.

This increment exposes count and seed patches. All other native settings, adoption and richer targeted changes remain explicit M05/M06/M07 work. The complete Plan 0.73 replacement path stays distinct and preserves its existing semantics.

Schemas are closed on both sides. Patches must reference current unique owned layers; unchanged values, duplicate/unknown IDs, unsupported fields and stale configuration/publication/context tokens are rejected. The effective plan retains the existing 2,000-candidate aggregate budget, masks, constraints and underfill policy. Configure-only never changes Live to Manual implicitly.

Published and authored state have separate IDs. Export while pending returns the previous publication's plan/layout with `publication_pending=true` and the current configuration ID. Count still means candidate budget. Stable candidate/layer IDs do not promise identical accepted placements after a seed/count change. Operation effects `committed` can mean authored settings committed without calculation; the operation kind and pending flag identify this explicitly.

## Ownership, bounds and failure

The service holds one bounded effective authored plan/compiled mask definition per owned controller, separate from the last published execution record. Definitions contain settings and polygons, not placement arrays. Native storage/publication, retained previews and Undo lifetimes stay with the existing engine. The adapter shares creation's bounded final-row verifier for Update; it adds no second evaluator.

Native `cyrusPresetTrackPublication` joins the same authored hold before any edit. Updates operate in place on existing child owners. Native publication generations remain retained by reference until their Undo history is discarded. Failure recovery checks the old authored fingerprint, immutable publication and owner/generation/configuration tags. Unknown recovery remains blocked; it is not reclassified as rollback.

The current design scope allows two committed publication applications (including initial creation) and eight configure-only commits, with the existing normal-read/request and paging/capture budgets. Status polling and exact-key retries no longer consume the normal-call budget; a genuinely new apply is charged once. These outcome reads cannot cause calculation or gain authority.

## Required evidence for this increment

Run a fresh owned Max 2027 profile with the exact 0.86.9.2/Analyzer 0.14.2 payload, frozen current MCP source and a real SDK stdio client. Verify configuration proposal/approval/execution, pending reads/export, explicit Update, complete native rows and unchanged layer/mask/source identities and unrelated objects. Exercise proxy, retained Mesh and Point Cloud; configure-only must leave native publication IDs, cache build counts and warm upload counters unchanged. Verify own Undo/Redo and failures before/after native publication, plus Live configure denial. Preserve all failing receipts and distinguish native API/scripted local approval from physical artist interaction.

## Evidence — 24 October 2026, run 07

- **338 offline tests passed in 38.41 s**, `build/mcp-foundation-20261024-07/offline.xml`. Sixteen new cases cover the production change validator/service, pending export versus authored definition, budgets, stale configuration tokens, closed patches, approval, queued cancellation, Live configure denial and repeated polls/retries. Native behavior is qualified separately below.
- Owned Max 2027 PID **49552**, exact Scatter **0.86.9.2** / Analyzer **0.14.2**. All five loaded native module hashes match the staged payload; **23 frozen runtime Python/JSON files** match current source. No native C++ or packaged MAXScript change was needed.
- A real external SDK stdio client discovers **13 tools** and executes locally approved changes. In proxy/Mesh/Point Cloud, the first layer changes from 80 candidates/seed 42 to 120/123; every other authored field, layer/mask/source reference and unrelated artist-object snapshot stays unchanged. Configure preserves the exact old publication ID, every published row, cache builds and generation; configuration/export report pending and retain the old published plan.
- Explicit Update produces **137 → 170**, **130 → 165**, and **139 → 161** accepted rows respectively from authored totals **160 → 200**. Every final exported transform matches the new native publication. Layer identities, update modes and the newer configuration ID remain unchanged. These are candidate-budget results, not exact-target or library-asset qualification.
- Mesh configure keeps build counters **[2,2]**, retained owner revision **1**, prepares/node updates **3/3**, upload count **31** and upload bytes **42,768** unchanged. Point Cloud keeps builds **[1,1]**, revision **1**, prepares/node updates **3/3**, upload count **38** and upload bytes **234,468** unchanged. Owners are ready before/after; these are process counters in the owned fixture, not universal latency/FPS or VRAM measurements.
- Update Undo/Redo restores exact pending/complete rows and authored state in all three modes. Separate configure-only Undo/Redo restores old/new authored settings and configuration tags without changing the publication. Live configure-only is denied; Live configure-and-Update succeeds with mode 2 and stable layers.
- Injected `change_settings`, `change_preview` and `change_publish` faults all return `failed` / `verified_rollback`, preserving old authored hash, publication ID/rows, generation/configuration tags, layer IDs, node count and unrelated-object state. Exact-key retries return the original receipt. The existing complete replacement/refinement/Undo/failure campaign also passes after sharing the row verifier.
- Primary receipts under `build/mcp-foundation-20261024-07/host01`: `changes-a9477d52d61a4a8d9d91f11499121c8f.json` and `refinement-4e8ed74b8ed241ad958c8862b6143fa4.json`, artifact **`45a0c3d0525e07cde086e18e087bf90e8113739481799c8038f4251a8259f829`**. The additional edge fixture is `change-edges-75831a8fb85a464580e23fdbdd556f50.json`, artifact **`5611404e2e84a8e083fd0eaeb1ffa1ebb9c22de8ea58ee6a5337d1587ce407cb`**. Its explicit driver rebind archives the preceding qualification and changes only private fixture code; the frozen runtime/native payload stays unchanged.

These are small synthetic owned scenes with scripted local approval and real SDK/native execution. Physical panel interaction, intended installed-client upgrade, persistence/adoption/conflict workflows, configure-specific crash/durability cases, larger-workload memory/performance and broader typed settings remain open. New settings must enter typed contracts and their native acceptance cases; do not infer write authority from the feature catalog.
