# 02 — Requirements and supplied current system

[Contents](00_README.md) · [Decision](01_EXECUTIVE_DECISION.md) · [Data layout](03_PARALLELISM_AND_DATA_LAYOUT.md)

## Evidence boundary

**Supplied project context (S).** This chapter records the coordinator's baseline, not an independent repository or Max inspection. The assignment and context bytes were checked against the supplied SHA-256 manifest; all four listed files matched. The upload suffixes `(2)` and `(4)` were transport filenames, not document revisions. Input hashes are in [research metadata](RESEARCH_METADATA.json). The earlier tree-generation HTML is not used to establish this plugin's present implementation or GPU performance.

**Verified public evidence (V), executed checks (X), analytical estimates (E), proposals (P), and unresolved questions (U)** have separate meanings throughout this set. A current public SDK method is V; whether it works in the plugin's actual Nitrous path is U until a local proof. Repeating a supplied test result does not turn it into X.

## Product behavior that acceleration must preserve

| Requirement | Supplied baseline and consequence |
|---|---|
| Host and version | Cyrus Scatter 0.87.4.3, capability 11, schema 63; Windows x64, Max 2027 only. No new support claim or migration is authorized. |
| Author once | Shared immutable source geometry, guides, hierarchy, anchors, foliage bindings, author overrides, fingerprints. No per-placement skeleton discovery. |
| Independent collider edits | Both published and edited transforms matter. Query old and new neighborhoods, including restoration when a collider leaves. |
| Static fitting | Recompute a collision-dependent static fit against current obstacles. No inertia, velocity history, permanent bend, or dependence on animation playback. |
| Root attachment | Positions or fixed root rings remain constrained; orientation stiffness is a separate property. Leaves and children follow authored parents. |
| Contact gap | Bending clearance, independent of root exclusion. Apply once in a defined metric space. |
| Hide margin | Separate Inside solid or explicit Under collider exclusion. Hide the complete rooted group and attachments. A solver failure is not permission to hide geometry. |
| Infeasible fit | A fixed root can be inside contact clearance yet outside the selected hidden region. Retain the previous complete publication and report failure. |
| Geometry quality | Guide clearance alone does not prove a broad leaf or swept ribbon clear. Existing bounded visible-surface refinement remains part of the quality comparison. |
| Coordinates | Numerical metres and +Y up; Max scene units and +Z up. Positive uniform instance scale only; mirrored, sheared and nonuniform instances are unqualified. |
| Ownership | Host capture/evaluation and publication on Max's host thread. Workers use owned numeric snapshots. No SDK calls from kernels or arbitrary workers. |
| Editing model | Pending Manual placements do not become published because a collider moved. Contact changes operate on the appropriate last-published population. |
| Display | Retained buffers survive Wireframe/style changes. Camera motion, selection, UI browsing and unrelated animation must not solve static contact again. |

The current CPU executor joins its workers before publication; up to eight participants can be used under the supplied large-batch policy. This is not an established asynchronous scheduler. Copying maps of retained poses/root counts can cost time proportional to previously changed data even when the new contact neighborhood is tiny. Both facts require measurement before selecting a GPU algorithm. [S01](17_SOURCE_LEDGER.md#s01)

## What is already shared, and what can still multiply

The supplied pose representation refers to shared source guides, changed guide poses, hidden-root masks and sparse rigid-part results. It does not inherently duplicate every vertex. However, source-guide-indexed tables can still grow with **instances × guides**, and materialized preview or renderer meshes can grow with **distinct poses × vertices**. The report proposes an additional sparse GPU representation; it does not assert that the present C++ structures already use those byte layouts.

The existing display path uses public Max custom render items, `IVirtualDevice`, vertex/HLSL material handles and instanced triangle drawing with shader model 5.0. The provided description says it neither exposes nor uses a raw Direct3D device or compute runtime. This is a statement about current Cyrus code, not a statement that all Max public native-device interfaces are absent. The distinction matters because [chapter 07](07_MAX_2027_INTEROP_FEASIBILITY.md) finds public D3D11 interfaces whose applicability still needs proof. [S01](17_SOURCE_LEDGER.md#s01)

## Admissions are limits, not capacity measurements

| Supplied admission | Value | Interpretation |
|---|---:|---|
| Instances in one native interaction layout | 1,000,000 | An admission ceiling, not a realtime draw or fit guarantee |
| Collider instances | 16,384 | Global count; distinct collider geometry may be shared |
| Relevant colliders per plant | 64 | Overflow cannot become a complete clear result |
| Transient instance overrides | 4,096 | A different population from active guides or collider contacts |
| Fit, query, snapshot and scratch work | Bounded | Exact current limits require the named local source probes |

Under collider uses a downward, geometry-clipped footprint relative to world up. Its artificial vertical extent must not make the spatial index useless. The supplied horizontal split correction is evidence of a real requirement: use ground-plane locality for footprint candidate selection and then apply the actual height/geometry rule. Do not voxelize an unbounded vertical column or trigger a full-layout rebuild on each drag. [S01](17_SOURCE_LEDGER.md#s01)

## Narrow observations supplied by the coordinator

| Observation (S, not rerun here) | What it establishes | What it does not establish |
|---|---|---|
| 61 native tests and a scoped private-profile Max campaign passed | Coordinator reports a qualified release scope | External replication or GPU/async qualification |
| Source: 451 guides, 22,032 vertices, 27,501 triangles | One source's complexity | Node count per guide or every library asset's cost |
| 200 plants, one collider; three candidates, six fitted guides, 62 hidden groups | A sparse edit can touch very little solve work | All 200 plants deforming, much less millions |
| Native contact evaluation about 4.05 ms in one run | A single native-stage observation | p95, physical pointer latency, frame time or GPU speedup |
| One fitted plant: 23,497 audited visible triangles; zero penetrating vertex pairs/touching triangle pairs/root-anchor error | One double-precision audit under its particular checks | Universal geometry proof or a GPU-equivalence threshold |
| Maximum checked stem edge change about 9.145% | A reported deformation measure | Permission to silently relax strain further; ideal inextensibility |
| Raised collider hides 0 / 81 / 451 groups for the cited exclusion settings | Hide mode/margin are separate from zero contact gap | Full-shape collision quality at other settings |
| 5,000-instance numerical footprint test finds one neighborhood | Locality/candidate correctness in that test | 5,000 complex simultaneous fits |

These numbers stay labelled S everywhere. No fitted-node count, per-instance preparation time, GPU memory use, throughput, or compiler performance is inferred from them. [S01](17_SOURCE_LEDGER.md#s01)

## Population definitions used in the design

| Symbol | Definition |
|---|---|
| `N` | Resident published scatter instances in the interaction layout |
| `K` | Instances considered for one successor after old/new neighborhood invalidation |
| `D` | Instances with retained non-rest poses or non-default visibility; can exceed `K` |
| `G_i`, `V_i`, `T_i` | Source guide, render-vertex and triangle counts for instance `i`; homogeneous shorthand `G,V,T` |
| `H`, `Q` | Guides and guide nodes actually processed in a successor; include changed descendants and required validation, not just directly contacting spans |
| `H_D`, `Q_D` | Changed guides/nodes retained in the published sparse pose store |
| `C`, `c_i` | Global collider instance count and relevant count for plant `i` |
| `P` | Generated candidate contact work items, explicitly tagged as span–collider or triangle–collider pairs |
| `V_A`, `T_A` | Vertices/triangles evaluated for active surface validation or materialization |
| `V_draw`, `T_draw` | Visible geometry processed in drawing, which is different from active collision work |

Four workload classes follow. A million resident instances with `K=3` is a locality/storage problem; thousands of complex affected plants are a guide/contact scheduling problem; millions of changing vertices are a deformation/bandwidth problem; a million 451-guide clumps all changing are a hundreds-of-millions-of-guides and tens-of-billions-of-vertices problem. The last class must pass admission arithmetic before any dispatch. It is not a promise hidden behind the term GPU instancing.

## Acceptance ownership

**P.** The local coordinator freezes the CPU reference evaluator, quality profiles, supported source contract and fixture fingerprints before backend comparisons. Researcher A supplies the alternative architectures, public evidence and falsifiable gates. This set does not certify local source files, renderer integrations, device ownership or performance. The exact blocked decisions and local file probes are in [chapter 16](16_OPEN_QUESTIONS_FOR_LOCAL_CODEX.md).
