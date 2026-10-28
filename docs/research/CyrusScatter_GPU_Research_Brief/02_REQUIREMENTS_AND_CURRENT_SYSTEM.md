# 02. Requirements and Current System Baseline

## 1. Provided Baseline Facts (`0.87.4.3`, Capability `11`, Schema `63`)

All statements in this section are **[PROVIDED-FACT]** from `RESEARCH_PROMPT.md` and `CURRENT_SYSTEM_CONTEXT.md` unless tagged otherwise:

1. **Target Host and Toolchain:**
   - **Host:** Autodesk 3ds Max 2027 on Windows x64 **[PROVIDED-FACT]**.
   - **Verified SDK Requirements for 3ds Max 2027:** Visual Studio 2022 (`17.14.x`), Platform Toolset `v143` pinned to **MSVC `14.38` (`19.38.33130`)** for C++ ABI compatibility, C++20 standard, Windows SDK `10.0.19041.0`, Qt `6.8.3`, and `.NET 10` **[VERIFIED-PUBLIC]** ([Autodesk Max 2027 Developer Blog](https://blog.autodesk.io/whats-new-in-3ds-max-2027/)).
   - **Architecture Split:** Native C++ owns bulk numerical work, spatial indexing, contact fitting, and retained viewport buffers; generated MAXScript/managed code owns UI, persisted recipe state, and bounded coordination **[PROVIDED-FACT]**.

2. **Present End-to-End Data Flow:**
   ```mermaid
   flowchart TD
       A["Original Max Scene Source"] --> B["Copied Geometry + Authored Preparation"]
       B --> C["Immutable Shared Source Definition + Fingerprint<br/>(Geometry, Guides, Anchors, Hierarchy, Bindings, Fixed Parts)"]
       D["Published Scatter Placements (N <= 1,000,000)<br/>+ Instance Transforms"] --> F["Old / New Collider Neighbourhood Lookup<br/>(Horizontal-Split Spatial Index)"]
       E["Independently Edited Collider Transforms<br/>(C <= 16,384 global, <= 64 per plant)"] --> F
       C --> G["Native CPU Fitter (Up to 8 Workers)<br/>1. Transform Colliders to Plant Local Frame (+Y Up, Metres)<br/>2. Root Exclusion (Inside Solid / Under Collider + Hide Margin)<br/>3. Guide Contact Fit (+ Contact Gap) & Parent->Child Hierarchy<br/>4. Visible-Surface Foliage Refinement"]
       F --> G
       G --> H["Complete Successor Pose & Visibility Snapshot<br/>(Retains Old Publication if Infeasible)"]
       H --> I["Retained Viewport Preview<br/>(MaxSDK::Graphics Custom Render Items, IVirtualDevice, SM 5.0 HLSL)"]
       H --> J["Offline Renderer / Bake / Export Materialization<br/>(Arnold, V-Ray, Corona via CPU Mesh Delivery)"]
   ```

3. **Shared Source vs Per-Instance Pose Representation:**
   - Each unique plant asset is prepared once into immutable shared geometry, polyline guide chains, parent-child guide hierarchy, fixed anchors, foliage vertex bindings, and a cryptographic/structural source fingerprint **[PROVIDED-FACT]**.
   - Authoring overrides (inferred roles, roots, parents, guide points) are baked into the prepared source and must never be re-inferred per instance or per drag frame **[PROVIDED-FACT]**.
   - A posed plant stores an array indexed by source guides ($0 \dots G-1$), shared pointers to changed guide poses, hidden-root group bitmasks, and sparse rigid-part transforms; unchanged guides reference the rest definition **[PROVIDED-FACT]**.
   - Crucially, while the logical pose object is sparse, materializing differently deformed instances into explicit vertex buffers for viewport preview or offline rendering can still generate $K \times V$ unique vertices unless vertex deformation is pushed into a shader that reads compact guide poses **[PROVIDED-FACT]**.

---

## 2. Non-Negotiable Geometric and Semantic Invariants

Any GPU or hybrid architecture must preserve the following eight functional contracts **[PROVIDED-FACT]**:

| # | Contract | Exact Specification | GPU Architectural Implication |
|---|---|---|---|
| **I-1** | **Quasistatic History-Free Semantics** | Contact fitting is a static/quasistatic equilibrium solve for the current collider configuration. Leaving a collider restores the exact rest pose. | Solver must initialize from rest (or prove that any warm-start converges to the identical rest pose when clear) and must not introduce velocity/momentum drift when stationary. |
| **I-2** | **Coordinate & Scale Conversion** | Internal numerical engine uses **metres** and **+Y up**; 3ds Max uses scene units and **+Z up**. Admitted instance transforms have **positive uniform scale** $s > 0$, rotation $R \in SO(3)$, and translation $\mathbf{t}$. | Convert collider geometry into each candidate plant's local metre frame via $\mathbf{x}_{\text{local}} = s^{-1} R^T (\mathbf{x}_{\text{world}} - \mathbf{t})$. Scale world clearances (`Contact gap`, `Hide margin`) by $s^{-1}$ exactly once. |
| **I-3** | **Independent `Contact gap` vs `Hide margin`** | `Contact gap` ($g_{\text{contact}} \ge 0$) expands the surface clearance used to bend guides/foliage. `Hide margin` ($m_{\text{hide}} \ge 0$) independently expands the root-group exclusion volume. Each is applied **exactly once**. | Never add `Contact gap` and `Hide margin` together; evaluate root exclusion against $d_{\text{solid}}(\mathbf{r}_0) \le m_{\text{hide}}$ (or footprint + $m_{\text{hide}}$) and guide bending against $d_{\text{solid}}(\mathbf{x}) \ge g_{\text{contact}}$. |
| **I-4** | **`Inside solid` vs `Under collider` Hiding Modes** | `Inside solid` hides a rooted group when its root/anchor lies within `Hide margin` of the closed collider solid. `Under collider` adds a downward projection along world up ($+\mathbf{U}_{\text{world}}$), clipped to collider geometry **above** the root, so floating colliders also exclude roots beneath them. | Broad-phase spatial indexes must split projected footprint bounds **horizontally** (in the ground plane) so artificial vertical extent does not degrade BVH/grid culling. |
| **I-5** | **Whole-Group Hiding vs Solver Failure** | Hiding removes an entire rooted group and all its attached branches/foliage. If a root is fixed *inside* the required bending clearance ($d < g_{\text{contact}}$) but *outside* the hidden region ($d > m_{\text{hide}}$), or if multiple colliders squeeze a guide into an infeasible state, the solve is **infeasible**. | A GPU kernel must **never** mask a failed/unconverged guide fit by setting its visibility bit to hidden. Infeasible updates must flag an error code, abort publication, and retain the last valid complete publication. |
| **I-6** | **Foliage Surface Clearance** | A collision-free guide centerline does not guarantee collision-free attached leaves or broad petals. Visible-surface refinement checks/adjusts bound foliage geometry. | Guide-only point/segment clearance is insufficient; GPU fitting must include conservative capsule/ribbon envelopes or a secondary foliage-vertex surface check. |
| **I-7** | **Old + New Neighbourhood Invalidation** | Moving a collider from $T_{\text{old}}$ to $T_{\text{new}}$ (or deleting/undoing it) invalidates plants in $B(T_{\text{old}}) \cup B(T_{\text{new}})$. Plants leaving $B(T_{\text{old}}) \setminus B(T_{\text{new}})$ return to rest; plants outside both keep cached poses. | Never rebuild the $N$-instance spatial index or re-solve unaffected plants during a local collider drag. |
| **I-8** | **Viewport Style Independence** | Toggling Wireframe (`F3`, `ViewExp::IsWire()`) or camera/viewport navigation reads retained GPU buffers and must never trigger a new collision solve or re-upload unchanged geometry. | Keep collision state keyed strictly to `(source_fingerprint, placement_revision, collider_transform_revision, interaction_settings_revision)`. |

---

## 3. Current Safeguard Admissions and Observed Baseline Numbers

### 3.1 Admission Limits **[PROVIDED-FACT]**
- Maximum scatter instances in a native interaction layout: $N_{\max} = 1{,}000{,}000$.
- Maximum global collider instances: $C_{\max} = 16{,}384$.
- Maximum relevant colliders per candidate plant: $C_{\text{plant},\max} = 64$.
- Maximum transient edited-instance overrides: $4{,}096$.
- Synchronous CPU worker participation: up to $8$ worker threads on automatic batches.

### 3.2 Scoped Qualification Fixture (`0.87.4.3 r3`) **[PROVIDED-FACT]**
- **Source complexity:** $1$ grass clump source with $G = 451$ guides, $V = 22{,}032$ vertices, $T = 27{,}501$ triangles.
- **Scene fixture:** $N = 200$ scattered plants, $C = 1$ collider.
- **Single localized update workload:** $K = 3$ nearby candidate plants found; $M = 6$ guides fitted; $62$ rooted groups hidden.
- **Observed native contact evaluation time:** $\approx 4.05\text{ ms}$ (single run; excludes host capture, viewport buffer upload, and presentation).
- **Double-precision audit on 1 fitted plant:** $23{,}497$ visible triangles, $0$ penetrating vertex pairs, $0$ touching triangle pairs, $0.0$ root-anchor drift, maximum stem edge length change $\approx 9.145\%$.

> [!IMPORTANT]
> **Critical Insight from the Baseline (`4.05 ms` for $K=3$ candidates, $6$ fitted guides):**
> Why did evaluating just $3$ candidate plants ($6$ fitted guides, $62$ hidden groups) take $4.05\text{ ms}$ on the CPU?
> Two structural factors in `CURRENT_SYSTEM_CONTEXT.md` explain this:
> 1. **Per-Update Successor Map Cloning:** *"The current successor copies maps of retained poses/root counts before updating affected entries."*
> 2. **Fine-Grained Double-Precision Mesh Queries & Surface Auditing:** Testing $3 \times 451 = 1{,}353$ roots/guides and refining up to $22{,}032$ foliage vertices against closed triangle meshes in double precision.
> This confirms that **both host data-structure overhead (O(N) map copies) and per-plant query/refinement density** must be addressed together—moving arithmetic to a GPU while leaving an $O(N)$ host map copy in place will still bottleneck at large $N$.
