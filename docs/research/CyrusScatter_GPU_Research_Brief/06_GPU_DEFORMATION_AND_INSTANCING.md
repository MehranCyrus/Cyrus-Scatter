# 06. GPU Deformation and Instancing

## 1. Deforming in a Vertex Shader vs Solving in Compute vs Materializing Full Meshes

Per `RESEARCH_PROMPT.md` §5, we must clearly distinguish:
1. **Solving physical collisions** (which requires spatial search, iterative root-to-tip guide projection, and reduction over contact witnesses—work that belongs on CPU workers or in GPU compute kernels), and
2. **Deforming the $V = 22{,}032$ source mesh vertices from solved guide poses** (which is a pure per-vertex mathematical function of the shared source mesh and the instance's $G = 451$ guide poses).

We compare the three ways to feed deformed plant geometry to the 3ds Max 2027 Nitrous viewport:

| Approach | VRAM per Source ($V=22\text{k}$) | VRAM for $K_{\text{posed}} = 2{,}000$ Deformed Plants | Per-Drag Bus Traffic ($K_{\text{active}} = 500$) | Preserves Instanced Draw Calls? | Requires Raw D3D11 Interop? |
|---|---|---|---|---|---|
| **M1: CPU Deforms Unique Meshes $\to$ `VertexBufferHandle::Lock`** | $1.1\text{ MiB}$ | **$1{,}344\text{ MiB}$** ($2{,}000 \times 22{,}032 \times 32\text{ B}$) | **$336\text{ MiB/drag}$** (PCIe bottleneck: $>20\text{ ms}$) | **No** (or requires massive mega-VB repack) | No |
| **M2: Compute Kernel Materializes $K_{\text{posed}} \times V$ Vertex Buffers** | $1.1\text{ MiB}$ | **$1{,}344\text{ MiB}$** | $0\text{ B}$ only if D3D11 interop exists; **$336\text{ MiB}$ round-trip** if no interop! | **No** (1 buffer / region per posed plant) | **Yes** (fatal without raw `ID3D11Buffer` access) |
| **M3: Shared-Source Instanced Draw + HLSL SM 5.0 Vertex-Shader Pose-Pull (Recommended)** | $1.1\text{ MiB}$ | **$7.3\text{ MiB}$** ($2{,}000$ plants $\times \sim 30$ changed guides $\times 8$ nodes $\times 16\text{ B}$) | **$1.83\text{ MiB/drag}$** (for $M=15{,}000$ active guides) | **Yes!** Single instanced draw call for both rest and posed instances | **No!** Uses public `TextureHandle` / `VertexBufferHandle` `Lock`/`Unlock` |

> [!IMPORTANT]
> **Why M3 (Shared-Source Instanced Draw + Vertex-Shader Pose-Pull) Is a Breakthrough for Cyrus Scatter:**
> Because Cyrus Scatter *already* uses public `MaxSDK::Graphics` custom render items, `IVirtualDevice`, and Shader Model 5.0 HLSL shaders (`AminScatter/src/mesh_display.inc`) **[PROVIDED-FACT]**, moving vertex deformation into that HLSL vertex shader requires **zero raw Direct3D 11 device hacking**, works identically whether guide poses are solved on the CPU or in CUDA, reduces per-posed-instance memory by **50× to 180×**, and keeps all instances—both undisturbed rest plants and actively bent plants—in the **same hardware-instanced draw path**!

---

## 2. Mathematical Formulation of Guide-Frame Vertex Deformation

**[PROPOSED / UNVERIFIED]**

Each vertex $v \in \{0 \dots V-1\}$ of the prepared shared source has immutable rest attributes in source-local space (metres, $+Y$ up):
- Rest position $\bar{\mathbf{x}}_v \in \mathbb{R}^3$, rest unit normal $\bar{\mathbf{n}}_v \in S^2$, rest unit tangent $\bar{\mathbf{t}}_v \in S^2$ with handedness sign $\sigma_v \in \{-1, +1\}$, UV coordinates $(u_v, w_v)$, and material ID $m_v$.
- Authoring/preparation binding:
  - `guideIdx` $g \in \{0 \dots G-1\}$ (or `0xFFFF` for fixed rigid parts such as pots/rocks/unbent trunks),
  - `segIdx` $s \in \{1 \dots Nn_g - 1\}$,
  - `paramT` $t \in [0, 1]$ along rest segment $[\bar{\mathbf{p}}_{g,s-1}, \bar{\mathbf{p}}_{g,s}]$,
  - `rootGroupIdx` $r \in \{0 \dots R_{\text{groups}}-1\}$.

### 2.1 Transporting the Guide Material Frame Without Gimbal Flip (Parallel Transport + Axial Twist)
Let the rest centerline point be $\bar{\mathbf{c}}(g,s,t) = (1 - t)\bar{\mathbf{p}}_{g,s-1} + t\bar{\mathbf{p}}_{g,s}$ and the rest unit tangent be $\bar{\mathbf{d}}_{g,s} = \frac{\bar{\mathbf{p}}_{g,s} - \bar{\mathbf{p}}_{g,s-1}}{\|\bar{\mathbf{p}}_{g,s} - \bar{\mathbf{p}}_{g,s-1}\|}$.
In the posed configuration, segment $(g,s)$ has endpoints $\mathbf{p}_{g,s-1}, \mathbf{p}_{g,s}$, unit tangent $\mathbf{e}_{g,s} = \frac{\mathbf{p}_{g,s} - \mathbf{p}_{g,s-1}}{\|\mathbf{p}_{g,s} - \mathbf{p}_{g,s-1}\|}$, and cumulative material-frame rotation quaternion $\mathbf{q}_{g,s} \in \mathbb{H}_1$ computed by chained minimal rotation (Bishop parallel transport) from root to tip plus any Stage 5 foliage twist $\Delta \theta_{g,s}$:
$$\mathbf{q}_{g,s} = \text{RotAxisAngle}(\mathbf{e}_{g,s}, \Delta \theta_{g,s}) \otimes \text{MinimalQuat}(\bar{\mathbf{d}}_{g,s}, \mathbf{e}_{g,s}) \otimes \mathbf{q}_{g,s-1}^{\text{transport}}$$
For smooth $C^1$ shading across segment joints $s-1 \leftrightarrow s$, we store at each posed guide node $i \in \{0 \dots Nn-1\}$:
1. Node position $\mathbf{p}_{g,i} \in \mathbb{R}^3$ (`float3`, $12\text{ B}$), and
2. Node rotation quaternion $\mathbf{q}_{g,i} \in \mathbb{H}_1$ packed into `uint32_t` (`smallest-three` $10:10:10:2$ format, $4\text{ B}$, angular error $< 0.0014\text{ rad} = 0.08^\circ$) **[ANALYTICAL-ESTIMATE]**.

Total storage per posed guide node: **$16\text{ bytes}$ (`float4`: `xyz` = position, `w` = `asfloat(packedQuat10_10_10_2)`)**!

### 2.2 Per-Vertex Evaluation in HLSL Shader Model 5.0
Inside the vertex shader, for vertex $v$ of instance $I$:
1. **Whole-Group Visibility Rejection (Preserving Root Group Hiding):**
   - Fetch the instance's `poseRecordOffset`. If `poseRecordOffset == REST_INSTANCE` (`-1`), the vertex uses $\bar{\mathbf{x}}_v, \bar{\mathbf{n}}_v, \bar{\mathbf{t}}_v$ directly!
   - Otherwise, check bit $r = \text{rootGroupIdx}(v)$ in the instance's hidden-group bitmask.
   - **If hidden:** set homogeneous clip position `out.posCS = float4(asfloat(0x7FC00000), 0, 0, 1)` (or collapse all vertices of the group to `float4(0,0,0,0)` out of the view frustum), which causes the hardware rasterizer to discard 100% of triangles belonging to hidden group $r$ at zero pixel-shader cost and zero index-buffer rebuild cost **[VERIFIED-PUBLIC]**!
2. **Sparse Guide Lookup:**
   - Look up `slot = guideSlotTable[poseRecordOffset * G + g]`.
   - **If `slot == -1` (guide $g$ is at rest):** use $\bar{\mathbf{x}}_v, \bar{\mathbf{n}}_v, \bar{\mathbf{t}}_v$ directly—zero math overhead for untouched guides on a partially affected plant!
   - **If `slot >= 0` (guide $g$ is deformed):**
     - Fetch node $(s-1)$ and node $s$ from `poseNodes[slot * Nn + (s - 1)]` and `poseNodes[slot * Nn + s]`.
     - Interpolate centerline $\mathbf{c} = \text{lerp}(\mathbf{p}_{g,s-1}, \mathbf{p}_{g,s}, t)$ and normalized quaternion $\mathbf{q} = \text{normalize}(\text{lerp}(\mathbf{q}_{g,s-1}, \mathbf{q}_{g,s}, t))$.
     - Rotate rest offset $\mathbf{o}_v = \bar{\mathbf{x}}_v - \bar{\mathbf{c}}(g,s,t)$, normal $\bar{\mathbf{n}}_v$, and tangent $\bar{\mathbf{t}}_v$ by $\mathbf{q}$:
       $$\mathbf{x}_v = \mathbf{c} + \text{quatRotate}(\mathbf{q}, \mathbf{o}_v), \qquad \mathbf{n}_v = \text{quatRotate}(\mathbf{q}, \bar{\mathbf{n}}_v), \qquad \mathbf{t}_v = \text{quatRotate}(\mathbf{q}, \bar{\mathbf{t}}_v)$$
     - Apply the instance's local-to-world transform $T_{\text{plant}}$ (positive uniform scale $s_{\text{plant}}$, rotation $R_{\text{plant}}$, translation $\mathbf{t}_{\text{plant}}$):
       $$\mathbf{x}_{\text{world}} = s_{\text{plant}} (R_{\text{plant}} \mathbf{x}_v) + \mathbf{t}_{\text{plant}}, \qquad \mathbf{n}_{\text{world}} = R_{\text{plant}} \mathbf{n}_v$$

---

## 3. Preserving Normals, Tangents, UV Seams, Material IDs, and Branch Attachments

**[PROPOSED / UNVERIFIED]**

| Mesh Property | Hazard in Naive GPU Deformation | How Our Pose-Pull Shader Preserves It Exactly |
|---|---|---|
| **UV Seams & Hard Creases** | Post-deformation vertex-ring normal averaging merges across UV/smoothing-group splits or breaks if indexed differently. | Because deformation is a smooth $SO(3)$ rotation field $\mathbf{q}(g,s,t)$ evaluated at the guide parameter $(g,s,t)$, two split vertices at a UV seam share the exact same $(g,s,t)$ and offset $\mathbf{o}_v$, so their positions stay **watertight ($0.0$ seam crack)** while their distinct rest normals $\bar{\mathbf{n}}_{v_1} \neq \bar{\mathbf{n}}_{v_2}$ rotate independently! |
| **Normal & Tangent Orthogonality** | Linear position skinning without inverse-transpose stretches or shears normals. | Quaternion rotation $\mathbf{q} \in SO(3)$ + uniform instance scale $s_{\text{plant}} > 0$ is strictly conformal: $\mathbf{n}_v \cdot \mathbf{t}_v = \bar{\mathbf{n}}_v \cdot \bar{\mathbf{t}}_v = 0$ and $\|\mathbf{n}_v\| = \|\mathbf{t}_v\| = 1$ without requiring matrix inversion. |
| **Material IDs & Sub-Materials** | Merging deformed instances into a dynamic soup loses per-face `MtlID` boundaries. | Shared source index buffers / sub-mesh material ranges remain 100% untouched; only vertex positions/normals are displaced in the VS. |
| **Root Anchors & Fixed Parts** | Floating-point drift in skinning moves the base of the stem off the ground. | At $(d=0, s=1, t=0)$, $\mathbf{p}_{g,0} \equiv \bar{\mathbf{p}}_{g,0}$ and $\mathbf{o}_v = \mathbf{0}$ at the root pivot. Vertices marked `guideIdx = 0xFFFF` (fixed parts) bypass rotation completely. |
| **Parent-Child Branch Attachments** | Child branch base separates from parent bough when parent bends. | During Stage 4 depth level $d$, child guide $g_c$ anchors its root $\mathbf{p}_{g_c,0}$ and base quaternion $\mathbf{q}_{g_c,0}$ directly to parent guide $g_p$'s posed segment $(s_p, t_p)$: $\mathbf{p}_{g_c,0} = \mathbf{c}(g_p, s_p, t_p) + \text{quatRotate}(\mathbf{q}_{g_p,s_p}(t_p), \bar{\mathbf{o}}_{\text{attach}})$. |

---

## 4. Delivering Pose Data Through Public `MaxSDK::Graphics` (`TextureHandle` / `Buffer`)

Because Shader Model 5.0 (`vs_5_0`) supports `Texture2D<float4>.Load(int3(x, y, 0))` (up to $16{,}384 \times 16{,}384$ texels $= 2.68 \times 10^8$ `float4` entries $= 4\text{ GiB}$ in D3D11 **[VERIFIED-PUBLIC]**), we can pass arbitrary-sized pose tables into `HLSLMaterialHandle` via standard **`MaxSDK::Graphics::TextureHandle`** parameters (`SetTextureParameter`) even if `MaxSDK::Graphics` does not expose raw `StructuredBuffer` SRVs!

### Layout of the 2D Pose Palette Texture (`DXGI_FORMAT_R32G32B32A32_FLOAT`, Width $W = 4096$):
- **Row $0 \dots R_{\text{header}}-1$ (Posed Instance Directory + Guide Slot Map):**
  - For each posed instance $p \in \{0 \dots K_{\text{posed}}-1\}$, stores `(ceil(R_groups/32) + ceil(G/4))` texels containing the hidden-group bitmask followed by `int16_t` compact slot indices for each of the $G$ guides (`-1` = rest).
- **Row $R_{\text{header}} \dots H-1$ (Compact Active Guide Nodes):**
  - Each active guide slot $m \in \{0 \dots M-1\}$ occupies $Nn$ consecutive texels `{ pos.x, pos.y, pos.z, asfloat(packedQuat) }`.
- **Upload Cost via Public SDK:** For $K_{\text{active}} = 500$ plants with $M = 15{,}000$ active guides ($Nn = 8$), only $15{,}000 \times 8 = 120{,}000$ texels ($\approx 30$ rows of a $4096$-wide texture, **$1.83\text{ MiB}$**) are dirtied and updated per drag step!
