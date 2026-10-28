# Optional checks and proposed benchmark manifest

[Research contents](../00_README.md) · [Benchmark plan](../10_BENCHMARK_AND_VALIDATION_PLAN.md) · [Prototype specifications](../14_MINIMAL_PROTOTYPE_SPECIFICATIONS.md)

## What was actually run

`research_checks.py` is a small original Python arithmetic/analytic program, with no external packages. It was executed with **Python 3.12.14 on Linux x86_64**. All **10 checks passed**; [executed_checks.json](executed_checks.json) is the recorded machine output. This is not a CPU vegetation fitter, Jolt adapter, GPU kernel, Max plugin or performance benchmark. No C++ build was performed.

From the extracted document directory:

```bash
python optional/research_checks.py --output optional/executed_checks.json
python optional/verify_package.py .
```

To preserve the original packet hashes, write a rerun outside the extracted directory and compare it with the recorded JSON. The output is deterministic for the recorded Python environment; cross-runtime numerical differences, if any, must be inspected rather than automatically treated as solver failures.

```bash
python optional/research_checks.py --output ../rerun_checks.json
python optional/verify_package.py . --zip ../CyrusScatter_GPU_Interaction_Research_2026-10-27_A.zip
```

On Windows, substitute `py -3` if that is the local Python launcher. The scripts use the standard library and target Python 3.9+. Windows execution was **not** tested here. Commands above require the specified working directory; adjust the ZIP path if it is elsewhere. The verifier checks content hashes, required files, JSON/Python syntax, relative links/anchors, inventory, case IDs/seeds and optional ZIP paths/CRC/byte equivalence. It does not refetch external URLs or certify the scientific algorithms.

| Check | Executed scope | What it does not establish |
|---|---|---|
| X01 | Endpoints outside while an analytic segment crosses an inflated sphere | General mesh or GPU contact correctness |
| X02 | Analytic parameter `u`, outward normal, witness and signed-gap reconstruction | Engine manifold behavior or robust arbitrary-solid penetration witnesses |
| X03 | Root outside exclusion but inside the separate contact-clearance band | A successful constrained fit; the control is deliberately infeasible |
| X04 | Fully inside span has no sphere boundary crossings | A general solid classifier |
| X05 | Clear guide with a penetrating leaf vertex | Face-interior contact coverage; the harder F06 case is proposed separately |
| X06 | Large-coordinate float loss versus subtracting in double before conversion | Recovery of precision already lost in host capture |
| X07 | 1,331 deterministic samples obey the stated SDF interpolation bound for this analytic control | A mesh SDF builder, field-sign correctness, gradient quality or continuous-domain certification |
| X08 | An illustrative exceeded count budget cannot be labeled complete/clear | A real bounded collector, cancellation system or GPU allocator |
| X09 | Hypothetical memory and transfer arithmetic | Actual allocations, achieved bandwidth or latency |
| X10 | R8 geometry counts and canonical JSON fingerprint | Prepared UV/normal/binding data or CPU/GPU deformation parity |

The recorded R8 geometry has **8 nodes, 16 vertices, 14 triangles and a 0.7 m height**. Its first ring is fixed. Geometry is embedded in the output JSON so the simple prototype does not depend on a downloaded asset. The analytic sphere fixture and R8 each have a SHA-256 over `json.dumps(value, sort_keys=True, separators=(",", ":"), allow_nan=False).encode("utf-8")`; this canonicalization is a packet-local definition, not an assertion of an external JSON standard. Exact fingerprints are present in the output and benchmark manifest.

## Proposed cases — not executed

[benchmark_cases.json](benchmark_cases.json) mirrors B01–B18 in chapter 10 with explicit seeds, requested populations, source prerequisites and status. It is a **case specification**, not a complete private-asset generator or set of measured results. Only the R8 rest geometry and sphere-control data are included. The local team must capture/hash G451 and all prepared binding channels; generate and freeze R33/BR63/LEAF; choose HP; and export actual layouts, collider assets and edit traces. These pending fingerprints are `null`, not invented.

B02–B04 share one frozen active patch/edit trace; their row seeds only vary inactive placements. Before API comparisons, record actual candidate/guide/node/contact/surface work and verify that large-fitting rows contain substantive fitting rather than only clear/hidden candidates. The proposed P1 pose recipe in chapter 14 supplies two imposed test bends; it has not been evaluated here and does not claim contact clearance.

No CUDA/OpenCL/Max compiler commands are presented as executed. P0–P5 provide the exact local interfaces, inputs, gates and required log fields needed to construct those small experiments. Tool invocations in chapter 10 are version-qualified proposals and require local help/capability checks.

## Hash and archive policy

`MANIFEST.sha256` hashes every included file except itself. `RESEARCH_METADATA.json` lists every included path. `ARTIFACT_VERIFICATION.json` records actual assembly checks without hashing its own enclosing ZIP, avoiding a self-referential checksum. The final ZIP is rebuilt after that record is written and verified again; the returned archive contains identical file bytes. Altering a document or recorded output is expected to fail the original manifest, so keep reruns separate or produce a clearly versioned new packet.
