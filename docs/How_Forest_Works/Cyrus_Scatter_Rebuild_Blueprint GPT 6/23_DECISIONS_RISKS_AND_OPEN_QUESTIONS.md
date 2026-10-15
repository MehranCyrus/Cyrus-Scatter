# 23 — Decisions, risks, and unresolved evidence

**Status: proposed decisions for CyrusV1. Changes require explicit versioning and tests.**

## 1. Decision register

| ADR | Decision | Reason / consequence |
|---|---|---|
| ADR-01 | Host-independent pure core | Test algorithms without Max; contain SDK lifecycle risk |
| ADR-02 | Canonical semantic IDs, separate cache partitions | Performance changes cannot reseed scenes or detach edits |
| ADR-03 | Versioned keyed random channels | Independent appearance/placement variation |
| ADR-04 | Ordered include contributions | Preserve provenance and exclusion scope |
| ADR-05 | Current canonical paint tiles as initial authority | Current queries do not replay arbitrary stroke history |
| ADR-06 | Projected and surface-attached paint are separate backends | Avoid false promises about stacked/deforming geometry |
| ADR-07 | Full deterministic greedy solver first | Establish an oracle before local optimization |
| ADR-08 | Exact old/new conflict closure with global fallback | Fixed collision halos are not sufficient |
| ADR-09 | Edits before final constraints; explicit pins | Resolve manual-edit/occupancy precedence |
| ADR-10 | Immutable snapshot publication | No partially modified buffers visible to consumers |
| ADR-11 | Exact final render from current authority by default | Manual update mode cannot silently render stale state |
| ADR-12 | Capability-based renderer adapters | No blanket claims from one successful image |
| ADR-13 | Constrained staged Effects | Extensions cannot bypass dependencies or host safety |
| ADR-14 | Side-by-side migration | Protect existing scenes during a full rebuild |
| ADR-15 | Parameter schema is UI/automation source of truth | Avoid drift among panels, scripts, and documentation |

## 2. Refinements relative to the uploaded research

The research is retained as supplied; these changes are not silently written back into it.

**Collision locality:** R0 §8.3 proposes halos. The blueprint adds a counterexample, a full-solve baseline, and exact component closure. Halos remain useful for geometric queries, not as a proof of local acceptance.

**Identity:** R0 §8.4 includes a tile ID in a random key. Here only an immutable sampling-domain address may affect identity. A worker/cache tile cannot.

**Painting authority:** R0 §3.3 proposes a stroke/raster hybrid. Here current canonical tiles are authoritative for ordinary painting, with exact tile Undo and optional separate editable-path/history features.

**Manual edits:** R0's logical pipeline places edits after occupancy. This blueprint applies occupancy-relevant edits before final constraints and defines pins explicitly.

**Empty-source probabilities:** R0 §4.1 overstates non-equivalence with a separate survival gate. Chapter 03 explains the independent probabilistic factorization and its limits.

**SDK pressure/bindings:** Chapter 09 uses the callback's effective radius/strength and validates evaluated topology, following the specific official warnings [S21].

## 3. Open evidence, not undefined default behavior

| Question | What is unknown | Selected Cyrus behavior / next evidence |
|---|---|---|
| ForestPack exact pixel placement | Full numerical convention across versions | Cyrus pixel centers; compare controlled bitmap fixtures |
| ForestPack cluster algorithm | Private implementation | Specified spatial species field; compare visual/statistical behavior |
| ForestPack full stage order | Every combination not publicly established | CyrusV1 stage table; compatibility profiles only for tested differences |
| Paint/UV version combinations | Documentation contains mixed-era restrictions | Separate backends; run exact target-version tests before parity claims |
| Renderer integration ABI | Complete qualified vendor extension routes | M0/M8 capability gates; no invented API calls |
| Current Cyrus schemas | Repository not audited in this task | Read-only audit before migration/code changes |
| Surface Analyzer data contract | Existing implementation not inspected | Adapter qualification against chapter 05 |
| Current PFlow output efficiency | Not measured here | Prototype/count/memory/headless spike |
| Arbitrary host procedural maps | Safety/context varies by provider | Classify/bake/qualify; unsupported by default when unknown |
| Cross-platform bit identity | Compiler/library numerical differences | Certified profile plus tolerances; test before claiming |

## 4. Highest-risk engineering areas

Renderer/material integration can block feature parity despite a correct core. Persistent identity can break existing edits. Surface paint can fail on topology and stack mismatches. Incremental collisions can produce plausible but wrong results. Save/load and reference remapping can corrupt otherwise correct authoring data. Memory peaks can exceed budgets even when final populations fit.

Each risk has an early fixture and an explicit fallback/error policy. The response to uncertainty is a bounded experiment, not an undocumented guess embedded in production code.

## 5. What this package does not prove

It does not prove current Cyrus capabilities, ForestPack's proprietary internal architecture, one-to-one historical control parity, performance superiority, SDK binary compatibility, renderer support, or runtime correctness inside Max. It provides a detailed selected design, test obligations, and a small executed mathematical reference suite.

The distinction is practical: engineers can start implementing from explicit contracts while tracking external qualification work honestly.

<!-- Primary-source shortcut references; see chapter 25 for evidence scope. -->
[S21]: https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/cpp_ref/class_i_painter_canvas_interface___v5.html
