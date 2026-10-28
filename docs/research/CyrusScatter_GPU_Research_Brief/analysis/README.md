# Reproduce analytical estimates

Researcher A ran this small Python 3 program on the available Linux CPU environment. It evaluates byte formulas, FP32 spacing and frame periods. It does not implement a collision solver, dispatch GPU work, benchmark PCIe, or use Max.

From the document directory:

```bash
python3 analysis/estimate_memory.py > analysis/calculated_estimates.json
```

Python 3 standard library only; no install or compilation. The output is included. Proposed strides and eight-node guides are hypotheses, not the private source layout. Source counts 451/22,032/27,501 come from the supplied brief. Transfer times divide bytes by explicitly hypothetical 12/24 GB/s effective bandwidth and exclude latency/serialization. Memory excludes items stated in [chapter09](../09_MEMORY_PRECISION_AND_HARDWARE.md).
