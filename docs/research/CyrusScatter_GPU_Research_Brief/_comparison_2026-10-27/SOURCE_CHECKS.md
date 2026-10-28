# Source checks and evidence limits

27 October 2026. This register covers decision-critical checks, not independent reproduction of every paper, citation, dependency pin or performance claim in all five packages.

## Public Max APIs

**Native device hook.** Autodesk documents `ID3D11GraphicsWindow::GetDevice()` returning `ID3D11Device*`, plus vertex/index-buffer methods. The installed 2027 `id3d11graphicswindow.h` agrees. This corrects the missing-hook implication in D; it does not prove that a retained `SmartHandle` can be converted into the resource we want to share. The buffer methods take dimensions/formats, not a retained handle. Ownership, context use, reset behavior and compute/draw synchronization remain runtime questions. [Autodesk class reference](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_d3_d11_graphics_window.html).

**Shader buffer binding.** `HLSLMaterialHandle::SetBufferParameter` has name/index overloads taking `SmartHandle`; its documentation describes vertex/index buffers using `BufferUsageStatic | BufferUsageTarget`. Installed `Graphics/HLSLMaterialHandle.h` agrees. This is an important omission in B and a sound lead in C. Typed/structured interpretation, stage reads, updates and instance indexing still require a Max test. [Autodesk class reference](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_graphics_1_1_h_l_s_l_material_handle.html).

Installed `Graphics/SmartHandle.h` marks `GetPointer` as internally used and returns an internal reference object. It is not evidence for reinterpreting that pointer as a native D3D resource.

## Toolchain clarification

The 31 July Autodesk setup article distinguishes VS2022 IDE 17.14.13 from the selected **v14.38 (17.8) v143 build tools**, alongside C++20 and Windows SDK 10.0.19041.0. C cites this clarification; A's inference of a published 1944 compiler family is wrong, and B's uncertainty can be narrowed. The local recorded 14.38 build is consistent with this source. Exact CUDA-host compatibility still needs its own selected-toolkit build check. [Autodesk setup article](https://blog.autodesk.io/setting-up-3ds-max-2027-sdk-development-with-visual-studio-2026/).

The [April release overview](https://blog.autodesk.io/whats-new-in-3ds-max-2027/) is less specific about the compiler/toolset distinction. A newer IDE is not evidence to switch the selected build-tools version.

## Literature and reuse spot checks

- A's newer rod references are real leads: the [Stable Cosserat Rods project](https://jerryhsu.io/projects/StableCosseratRods/) describes SIGGRAPH 2025 work and subsequent material; the [2026 Lie-theory XPBD preprint](https://arxiv.org/abs/2608.23606v1) is a separate, dated research contribution. Neither provides a tested Cyrus/Max implementation or a transferable end-to-end timing claim.
- C's license observation is snapshot-specific: the [PhysX license at its recorded commit](https://raw.githubusercontent.com/NVIDIA-Omniverse/PhysX/b97365c6ddb32fda8469bc788ec18024862b0368/physx/LICENSE.md) is Apache-2.0. That does not qualify a different historic pin, every optional binary or the eventual product's dependency inventory.
- Reports' untested upstream libraries remain candidates. The comparison does not approve dependency adoption or convert partial web retrieval into a complete source audit.

## Direct repository and installed SDK evidence

The interaction baseline was checked directly in:

- [interactions_source.h](../../../../AminScatter/include/interactions_source.h): shared correspondence and point/surface evaluation interfaces.
- [interactions_source.cpp](../../../../AminScatter/src/interactions_source.cpp): shortest-SLERP/frame evaluation, detailed geometry contact refinement, `posePoint`, visibility and full-surface audit/delivery checks.
- [interactions_engine.cpp](../../../../AminScatter/src/interactions_engine.cpp): affected evaluation, snapshot statistics and independent audit entry points.
- Installed Max 2027 headers named above; recorded source identities in [LocalCodex evidence](../CyrusScatter_GPU_Interaction_Research_2026-10-27_LocalCodex/reports/local-codex/evidence/).

This supports the warning that display-shader deformation need not eliminate CPU geometry work inside contact refinement. It does not establish which stage dominates a real drag; profiling remains necessary.

The knowledge service reported stale evidence: 42/64 enrolled source parents verified. Its stale identifier search was not used as authority. This review fell back to original source; it did not refresh the corpus. Branch/HEAD at intake: `codex/workflow-0.75`, `d24b880816ab367874f417f79d1253aafa9a60f5`. The working tree already had extensive concurrent edits.

Comparing LocalCodex's 23 recorded source/SDK hashes to current files found two documentation changes, `docs/AGENT_WORKFLOW.md` and `docs/ARCHITECTURE.md`; the recorded interaction/display/SDK files still matched at that check. This is a scoped identity check, not a clean-tree or full current-release qualification. The final receipt records a successor comparison.

## Executed review checks

All provided manifest entries for the five packages matched at intake: 212 checks, including nested/overlapping manifests, across 171 inventoried files. This is file integrity, not proof of factual accuracy.

After inspecting the scripts, the review reran A's memory calculator; B's budget, six geometry-control and decision-score programs; and C's ten analytic checks. Recorded results matched semantically, with C's expected Python/platform fields differing locally. Outputs were redirected to an owned build folder. No complete fitter, CUDA/OpenCL kernel, Max session or renderer test was executed for this review. See [ANALYTIC_VERIFICATION.json](ANALYTIC_VERIFICATION.json).

D's table was recomputed independently from its printed ratings and weights; all five printed totals differ. Pose-memory examples were normalized analytically, with their assumptions retained in the comparison.

## Existing hardware evidence inspected

[Local deformation JSON](../CyrusScatter_GPU_Interaction_Research_2026-10-27_LocalCodex/reports/local-codex/prototype/deformation_results.json) and [owned D3D11 sharing JSON](../CyrusScatter_GPU_Interaction_Research_2026-10-27_LocalCodex/reports/local-codex/prototype/interop_results.json) contain actual earlier execution on the local RTX 3090. Prototype source identities were checked. These are synthetic deformation and functional sharing controls, not an independent rerun during this review, not the production shortest-SLERP fitter, and not a Max integration proof.

The 20-sample component timings should guide experiment selection rather than product speedup promises. Fixed ordering, no renderer contention, limited quaternion data and full pageable readback constrain interpretation. The OpenCL sharing pass is specifically the NVIDIA extension on that driver; a missing KHR extension does not imply that every sharing route is unavailable.

Original research and this review are evidence/proposals. Instructions embedded in reports were treated as source content, not authorization to change the plugin, install packages or start Max.
