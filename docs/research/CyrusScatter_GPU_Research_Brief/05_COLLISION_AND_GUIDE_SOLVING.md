# 05. Collision and Guide-Solving Research

## 1. Problem Formulation: Quasistatic Rooted Vegetation Contact

Unlike game-engine grass shaders (which apply a spherical radial push or heightfield trample map) or time-integrated hair solvers (which integrate velocity $\mathbf{v}^{(t+1)} = (\mathbf{x}^{(t+1)} - \mathbf{x}^{(t)})/\Delta t$ and exhibit momentum/damping lag), Cyrus Scatter's interaction engine performs **history-free quasistatic contact fitting** **[PROVIDED-FACT]**:

Given:
- A prepared plant source with $R_{\text{groups}}$ rooted groups, $G$ guides arranged in a directed acyclic forest of depth $D_{\max} \le 4$, rest node positions $\{\bar{\mathbf{p}}_{g,0}, \dots, \bar{\mathbf{p}}_{g,Nn_g-1}\}$ in plant-local metres ($+Y$ up), rest segment lengths $L_{g,i} = \|\bar{\mathbf{p}}_{g,i} - \bar{\mathbf{p}}_{g,i-1}\|$, and bound foliage surface offsets;
- Instance transform $T_{\text{plant}} = (\mathbf{t}_{\text{plant}}, R_{\text{plant}}, s_{\text{plant}})$ with $s_{\text{plant}} > 0$;
- Relevant closed collider meshes/proxies $\{C_1, \dots, C_m\}$ ($m \le 64$) transformed into the plant's local metre frame via $\mathbf{x}_{\text{local}} = s_{\text{plant}}^{-1} R_{\text{plant}}^T (\mathbf{x}_{\text{world}} - \mathbf{t}_{\text{plant}})$;
- Local clearances $\tilde{m}_{\text{hide}} = m_{\text{hide}} / s_{\text{plant}}$ and $\tilde{g}_{\text{contact}} = g_{\text{contact}} / s_{\text{plant}}$ (each applied **exactly once**);

Compute for each candidate plant $k$:
1. **Root Group Visibility Bitmask** $\mathcal{H}_k \in \{0,1\}^{R_{\text{groups}}}$ under `Inside solid` or `Under collider` mode using $\tilde{m}_{\text{hide}}$.
2. **Posed Guide Nodes** $\{\mathbf{p}_{g,i}\}$ for all unhidden guides $g$ that intersect any collider's $\tilde{g}_{\text{contact}}$-expanded envelope, minimizing deviation from rest bending directions subject to:
   - **Fixed root / parent attachment:** $\mathbf{p}_{g,0} = \bar{\mathbf{p}}_{g,0}$ (for $d=0$) or $\mathbf{p}_{g,0} = \text{Attach}(\mathbf{p}_{\text{parent}(g)})$ (for $d > 0$);
   - **Inextensibility / Strain limit:** $\big|\|\mathbf{p}_{g,i} - \mathbf{p}_{g,i-1}\| - L_{g,i}\big| / L_{g,i} \le \varepsilon_{\text{strain}}$ (baseline audit observed $\le 9.145\%$ max stem edge change **[PROVIDED-FACT]**);
   - **Exterior contact clearance:** $d_{\text{signed}}(\mathcal{S}_{\text{guide+foliage}}(g), C_j) \ge \tilde{g}_{\text{contact}}$ for all $j \in \{1 \dots m\}$.
3. **Infeasibility Detection:** If an unhidden root anchor lies strictly inside the required bending clearance ($d_{\text{signed}}(\mathbf{p}_{g,0}, C_j) < \tilde{g}_{\text{contact}}$) or if opposing colliders trap a guide such that exterior clearance and strain limits cannot both be satisfied after $I_{\max}$ iterations, mark the update **infeasible** and retain the prior valid publication **[PROVIDED-FACT]**.

---

## 2. Broad-Phase Spatial Indexing and Old/New Neighbourhood Invalidation

### 2.1 Preserving Ground-Plane Locality Under `Under collider` Mode

In `Under collider` mode, a floating collider at height $Y = +10\text{ m}$ casts a downward exclusion footprint all the way to plants rooted below it **[PROVIDED-FACT]**. As noted in `CURRENT_SYSTEM_CONTEXT.md` (§Geometry and correctness), inflating 3D plant or collider AABBs vertically to $[-\infty, Y_{\max}]$ destroys 3D BVH split quality because bounding boxes overlap across the entire vertical column.

**Horizontal-First Spatial Index Design (CPU & Optional GPU):** **[PROPOSED / UNVERIFIED]**
1. **2D Ground-Plane BVH / Hierarchical Hash Grid (XZ Plane in Internal Frame, XY in Max Frame) + Vertical Interval `[y_min, y_max]`:**
   - Partition the $N \le 1{,}000{,}000$ scatter instances primarily by their **horizontal ground-plane bounding circles** $(c_x, c_z, r_{\text{horiz}})$, storing `[y_min, y_max]` as a secondary filter inside each BVH node/leaf.
   - For **`Inside solid`**, a query with collider AABB $[x_{\min}, x_{\max}] \times [y_{\min}, y_{\max}] \times [z_{\min}, z_{\max}]$ expanded by $\max(g_{\text{contact}}, m_{\text{hide}})$ tests both horizontal overlap and vertical overlap $[y_{\min}, y_{\max}]$.
   - For **`Under collider`**, the horizontal query range is identical ($[x_{\min} - \Delta, x_{\max} + \Delta] \times [z_{\min} - \Delta, z_{\max} + \Delta]$), while the vertical filter simply tests $y_{\text{plant\_root}} \le y_{\text{collider},\max} + m_{\text{hide}}$. Because the tree is split horizontally, **vertical footprint projection has zero impact on tree split quality or horizontal culling selectivity**!
2. **Incremental Old $\cup$ New Neighbourhood Lookup:**
   - When collider $c$ moves from $T_{c,\text{old}}$ to $T_{c,\text{new}}$:
     - Query $S_{\text{old}} = \text{Query}(B(T_{c,\text{old}}))$ and $S_{\text{new}} = \text{Query}(B(T_{c,\text{new}}))$.
     - For plants $k \in S_{\text{old}} \setminus S_{\text{new}}$: if no other active collider overlaps plant $k$, reset plant $k$'s pose handle to `REST_POSE_HANDLE` ($O(1)$ per plant, zero solver work).
     - For plants $k \in S_{\text{new}}$ (plus any plant in $S_{\text{old}}$ still overlapping another collider): include $k$ in the active candidate batch $K$.

---

## 3. Collider Representations: Exact Mesh BVH vs Narrow-Band SDF vs Analytic Proxies

Colliders in Cyrus Scatter are closed triangle meshes or proxies, up to $C \le 16{,}384$ instances ($C_k \le 64$ per plant) **[PROVIDED-FACT]**. Crucially, many collider instances share a few unique collider source meshes (instanced rocks, walls, stepping stones, spheres/boxes).

We compare the three collider representations for GPU evaluation:

| Representation | Construction Cost (per unique collider mesh) | VRAM per Unique Collider ($10\text{k}$ tris) | Per-Node Query Cost on GPU | Accuracy vs CPU Reference (`0.87.4.3`) | Hazards & Mitigation |
|---|---|---|---|---|---|
| **1. Analytic Primitives & Compound Capsules/OBBs** | $0\text{ ms}$ (direct parameters) | $64\text{ B}$ | $\sim 15\text{ FLOPs}$ (closed-form point/segment to sphere/capsule/OBB) | Exact for primitive proxies; approximate for arbitrary meshes | Use as fast outer bounding hull or when collider source is an authored box/sphere/capsule. |
| **2. Collider-Local Linear BVH (LBVH / SAH BVH) + GWN Sign** | $0.5\text{--}3.0\text{ ms}$ on GPU (`cuBQL` / Karras 2012) or uploaded once from existing CPU BVH! | $\sim 640\text{ KiB}$ ($10\text{k}$ tris $\times 32\text{ B}$ + $20\text{k}$ BVH nodes $\times 16\text{ B}$) | $\sim 40\text{--}120\text{ steps}$ stackless/short-stack traversal (`closestPoint` + inside/outside sign) | **Exact match to CPU mesh queries** (down to FP32 rounding $\le 10^{-6}\text{ m}$); handles razor-thin features | Coplanar/grazing edges can flip pseudo-normal sign $\to$ use angle-weighted pseudonormal (Baerentzen & Aanaes 2005) or generalized winding number (Barill et al. 2018) at BVH nodes. |
| **3. Dense / Sparse Narrow-Band SDF (`3D Texture` / `NanoVDB`)** | $5\text{--}40\text{ ms}$ per unique collider mesh | $64^3 \times 4\text{ B} = 1.0\text{ MiB}$; $128^3 \times 4\text{ B} = 8.0\text{ MiB}$ | **$\sim 1$ hardware trilinear fetch** (or 4 fetches for tetrahedral gradient) — **10–25× faster** than BVH traversal | Trilinear interpolation smooths sharp corners and under-resolves features thinner than $2 \times \text{voxel size}$ | Apply a conservative outward offset $+\frac{\sqrt{3}}{2} h_{\text{voxel}}$ during interactive drag, or run 1 final exact BVH projection pass (`Hybrid Arch 5`). |

### Recommended Dual-Representation Collider Strategy **[PROPOSED / UNVERIFIED]**
1. **Upload the Existing CPU Collider BVH Once per Unique Collider Mesh:**
   - Cyrus Scatter already builds a CPU BVH over closed collider meshes in `interactions_geometry.cpp` **[PROVIDED-FACT]**. Flattening that BVH into two GPU arrays (`float4 bvhNodes[2*T]` in 32-byte LBVH layout + `float4 triangles[3*T]` with precomputed angle-weighted vertex/edge normals) takes $< 1\text{ MiB}$ per 10k-triangle collider mesh and requires **zero new BVH builder algorithms** in Phase 1!
2. **Instance-Space Reuse:**
   - If 5,000 stepping-stone collider instances share 1 mesh, its BVH is stored **once** in VRAM. Each collider instance stores only its world transform ($48\text{ B}$). During Stage 1, the composite transform $T_{\text{collider}\to\text{plant}} = T_{\text{plant}}^{-1} \circ T_{\text{collider}}$ is computed once per `(plant k, collider c)` pair ($m \le 64$).

---

## 4. Evaluating `Inside solid` and `Under collider` on the GPU

**[PROPOSED / UNVERIFIED]**

For each rooted group $r \in \{0 \dots R_{\text{groups}}-1\}$ with local root anchor $\mathbf{r}_0 \in \mathbb{R}^3$:

1. **`Inside solid` Test (with `Hide margin` $\tilde{m}_{\text{hide}}$):**
   - Transform $\mathbf{r}_0$ into collider $c$'s local mesh space: $\mathbf{q} = T_{c\to\text{plant}}^{-1}(\mathbf{r}_0)$.
   - Query the collider BVH for:
     - Unsigned closest-point distance $d(\mathbf{q}, \partial C_c) = \min_{\mathbf{y} \in \partial C_c} \|\mathbf{q} - \mathbf{y}\|$, and
     - Inside/outside occupancy sign $s(\mathbf{q}) \in \{-1, +1\}$ (computed via ray-parity count along $+Y$/$+X$ or fast dipole/winding number approximation at BVH nodes).
   - Signed distance in plant-local metres is $d_{\text{signed}}(\mathbf{r}_0, C_c) = s_{\text{collider}\to\text{plant}} \cdot s(\mathbf{q}) \cdot d(\mathbf{q}, \partial C_c)$.
   - If $d_{\text{signed}}(\mathbf{r}_0, C_c) \le \tilde{m}_{\text{hide}}$, group $r$ is marked **hidden** (`hiddenMask |= (1u << (r & 31))`).

2. **`Under collider` Downward Footprint Test (with `Hide margin` $\tilde{m}_{\text{hide}}$):**
   - Let $\mathbf{u}_{\text{up}}$ be the world-up vector ($+Z$ in Max, $+Y$ in internal engine) expressed in collider $c$'s local space.
   - A root $\mathbf{r}_0$ is excluded under collider $c$ if and only if:
     1. It satisfies the `Inside solid` condition ($d_{\text{signed}}(\mathbf{r}_0, C_c) \le \tilde{m}_{\text{hide}}$), **OR**
     2. The upward ray / cylinder of radius $\tilde{m}_{\text{hide}}$ starting at $\mathbf{r}_0$ along $+\mathbf{u}_{\text{up}}$ intersects collider $c$ at any point $\mathbf{y} \in C_c$ with height $(\mathbf{y} - \mathbf{r}_0) \cdot \mathbf{u}_{\text{up}} \ge -\tilde{m}_{\text{hide}}$ **[PROVIDED-FACT]**.
   - On the GPU, this is a single ray/cylinder-vs-BVH traversal along $+\mathbf{u}_{\text{up}}$ clipped to $t \in [-\tilde{m}_{\text{hide}}, +\infty)$.

---

## 5. Rooted-Guide Quasistatic Solver Comparison

We compare the candidate guide-solving formulations requested in `RESEARCH_PROMPT.md` §7:

| Formulation | Core Update Equations | Quasistatic / History-Free? | Branching & Twist Support | GPU Register & Shared Memory Footprint | Suitability for Cyrus Scatter |
|---|---|---|---|---|---|
| **1. Quasistatic XPBD + Follow-The-Leader (FTL) Length + Bending Target (Recommended)** | Initialize $\mathbf{p}_i^{(0)} = \bar{\mathbf{p}}_i$. For $it = 1 \dots I_{\text{iters}}$, sweep $i = 1 \dots Nn-1$:<br/>1) Pull toward parent-rotated rest vector: $\mathbf{p}_i \leftarrow \mathbf{p}_i + k_{\text{bend}}(\mathbf{p}_{i-1} + R_{i-1}(\bar{\mathbf{p}}_i - \bar{\mathbf{p}}_{i-1}) - \mathbf{p}_i)$<br/>2) Project out of colliders: if $d_{\text{signed}}(\text{seg}_{i-1,i}) < \tilde{g}_{\text{contact}} + r_{\text{stem}}$, push $\mathbf{p}_i$ along surface normal $\mathbf{n}$<br/>3) Enforce FTL length from anchored $\mathbf{p}_{i-1}$: $\mathbf{p}_i \leftarrow \mathbf{p}_{i-1} + L_i \frac{\mathbf{p}_i - \mathbf{p}_{i-1}}{\|\mathbf{p}_i - \mathbf{p}_{i-1}\|}$ | **Yes.** Initialized from rest $\bar{\mathbf{p}}_i$ every solve; zero velocity state; exact rest restoration when clear. | **Yes.** Propagates frame $R_i = \text{MinimalRotation}(\bar{\mathbf{e}}_i, \mathbf{e}_i) R_{i-1}$ from root to tip and across parent-child branch attachments. | **Tiny:** $Nn \le 12$ requires only $36$ `float` registers per thread; $0\text{ B}$ shared memory needed per guide. | **Primary Choice.** Fast convergence ($6\text{--}10$ iterations), exact root anchor ($0.0$ drift), bounded edge strain. |
| **2. Position & Orientation Based Cosserat Rods (Kugelstadt & Schömer 2016)** | Stores both node positions $\mathbf{p}_i \in \mathbb{R}^3$ and segment material-frame quaternions $\mathbf{q}_i \in \mathbb{H}_1$; projects stretch/shear constraint $\mathbf{C}_s = \frac{1}{L_i}(\mathbf{p}_i - \mathbf{p}_{i-1}) - \mathbf{q}_i \mathbf{d}_3$ and Darboux bend/twist $\mathbf{C}_b = \bar{\mathbf{\Omega}}_i - \mathbf{\Omega}_i$. | Can be run quasistatically (damping velocities each step), though originally dynamic. | **Excellent** for coupled bend-twist of woody branches and asymmetric broad leaves under torque. | **Moderate:** Adds $4 \times Nn$ floats for quaternions ($64\text{--}80$ registers/thread). | **Recommended Extension** for Stage 5 foliage twist refinement when a broad leaf hits a collider off-center and twists its stem. |
| **3. Direct Tridiagonal Stiff Rod Solver (Deul et al. 2018) / Projective Dynamics (Bouaziz et al. 2014)** | Solves global/per-rod linear system $(\mathbf{M} + \sum \mathbf{S}_j^T \mathbf{A}_j \mathbf{S}_j)\mathbf{p} = \mathbf{b}$ per iteration. | Can be formulated as static energy minimization $\min E_{\text{bend}}(\mathbf{p}) + E_{\text{ext}}(\mathbf{p})$. | Coupling non-linear inextensibility + unilateral inequalities requires ADMM/Newton inner loops; slow when many contacts activate. | **High:** Per-thread $3Nn \times 3Nn$ Cholesky/Thomas factors spill to local memory (`ldl`/`stl`), hurting GPU occupancy. | **Not Recommended** as primary contact solver due to local-memory register spilling under unilateral contact. |
| **4. Analytical Single-Hinge / Bezier Deflection (Jahrmann & Wimmer 2017)** | Models each blade as a quadratic/cubic Bezier curve with tip/control point pushed radially away from sphere center. | Yes (analytic). | **Cannot wrap** around non-convex mesh colliders, steps, or multiple squeezing obstacles; fails on branched bushes. | Minimal. | **Rejected** for final quality (violates Cyrus Scatter's exact surface clearance invariants). |

---

## 6. Whole-Segment / Capsule Contact and Visible-Surface Foliage Refinement

**[PROPOSED / UNVERIFIED]**

A key requirement in `RESEARCH_PROMPT.md` §2 and §7 is that **a clear guide centerline does not prove clear leaf surfaces**, and **point-only node sampling misses thin collider edges crossing mid-segment**.

### 6.1 Whole-Segment Capsule Queries (Avoiding Mid-Segment Edge Misses)
- During Stage 4 (Guide Solve), each guide span $s_i = [\mathbf{p}_{i-1}, \mathbf{p}_i]$ is queried as a **line segment (capsule of radius $r_{\text{stem},i} + \tilde{g}_{\text{contact}}$)** against the collider BVH, not merely at endpoint $\mathbf{p}_i$.
- Specifically, the BVH traversal computes the closest point pair $(\mathbf{x}^* \in [\mathbf{p}_{i-1}, \mathbf{p}_i], \, \mathbf{y}^* \in \partial C_c)$ using Ericson's segment-triangle closest-point primitive (`Real-Time Collision Detection` §5.1.9) **[VERIFIED-PUBLIC]**.
- If parameter $t^* = \|\mathbf{x}^* - \mathbf{p}_{i-1}\| / L_i \in (0, 1]$ has signed distance $d_{\text{signed}}(\mathbf{x}^*, C_c) < \tilde{g}_{\text{contact}} + r_{\text{stem},i}$:
  - For $i = 1$ (first segment out of fixed root $\mathbf{p}_0$): because $\mathbf{p}_0$ cannot move, the required clearance displacement $\Delta \mathbf{x} = (\tilde{g}_{\text{contact}} + r_{\text{stem},1} - d_{\text{signed}}) \mathbf{n}$ at $t^*$ is amplified onto tip $\mathbf{p}_1$ by $\Delta \mathbf{p}_1 = \frac{\Delta \mathbf{x}}{\max(t^*, 0.15)}$ followed by FTL length normalization around $\mathbf{p}_0$.
  - If $t^* \to 0$ (i.e., the fixed root $\mathbf{p}_0$ itself violates $\tilde{g}_{\text{contact}}$ and was not hidden by `Hide margin`), the kernel sets `infeasibleFlag[k] = ERR_ROOT_INSIDE_CONTACT_GAP`.

### 6.2 Two-Level Foliage Surface Refinement
Prepared plant sources bind leaf/flower vertices to guide segments with known lateral offsets $\mathbf{o}_v \in \mathbb{R}^3$ **[PROVIDED-FACT]**:
1. **Level 1 (In-Loop Conservative Foliage Envelope):** During source preparation, precompute for each guide segment $(g, i)$ a bounding capsule or oriented bounding box (OBB) enclosing all foliage vertices bound to $(g, i)$, plus directional width radii $(r_{+u}, r_{-u}, r_{+v}, r_{-v})$ in the segment's material frame. Including this anisotropic radius in Stage 4 clears $>90\%$ of leaf penetrations during the primary guide solve at zero extra BVH traversal cost.
2. **Level 2 (Post-Guide Visible-Surface Witness Refinement — Stage 5):**
   - For active guides that carry broad leaves ($r_{\text{foliage}} > r_{\text{stem}}$), launch Stage 5 over a pre-sampled set of **boundary witness vertices** (e.g., leaf tips and lateral margin vertices, or all $V_{\text{active}}$ vertices of active guides).
   - Each witness vertex $w$ is deformed by the tentative guide pose and queried against the plant's surviving local colliders.
   - Any witness with penetration $\delta_w = \tilde{g}_{\text{contact}} - d_{\text{signed}}(\mathbf{x}_w) > 0$ generates a **contact lever arm** $\mathbf{r}_w = \mathbf{x}_w - \mathbf{p}_{g,i-1}$:
     - **Normal lift:** $\Delta \mathbf{p}_{g,i} \mathrel{+}= \delta_w \mathbf{n}_w$ (bends the guide further away from the collider).
     - **Axial twist:** $\Delta \theta_{g,i} = \text{clamp}\big(\frac{(\mathbf{r}_w \times \delta_w \mathbf{n}_w) \cdot \mathbf{e}_{g,i}}{\|\mathbf{r}_w_\perp\|^2}, -\theta_{\max}, +\theta_{\max}\big)$ (rotates the leaf around the stem axis so its blade lies tangent to the collider surface rather than slicing into it!).
   - Run 2–3 refinement passes; if any visible vertex still penetrates beyond tolerance $\varepsilon_{\text{pen}}$ (e.g., trapped between two squeezing colliders), set `infeasibleFlag[k] = ERR_SURFACE_SQUEEZE_INFEASIBLE` so the host retains the previous valid publication rather than publishing penetrating or silently deleted geometry **[PROVIDED-FACT]**.
