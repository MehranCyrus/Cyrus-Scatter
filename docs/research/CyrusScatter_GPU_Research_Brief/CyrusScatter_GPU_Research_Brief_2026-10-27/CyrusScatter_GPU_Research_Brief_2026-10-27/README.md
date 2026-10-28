# GPU interaction research brief

Send the same brief to each research AI so their recommendations start from the same requirements. Give researchers distinct IDs such as A, B, and C for their returned artifact names.

- [Research prompt](RESEARCH_PROMPT.md): self-contained assignment, evidence rules, architecture questions, edge cases, and the required research ZIP structure.
- [Current system context](CURRENT_SYSTEM_CONTEXT.md): additional supplied implementation facts and narrow qualification limits.

You can paste the prompt alone, or upload this brief ZIP and paste:

> Please carry out the research assignment in RESEARCH_PROMPT.md, using CURRENT_SYSTEM_CONTEXT.md as supplied project context. Research independently with current primary sources. Compare CUDA, OpenCL, graphics deformation and CPU/hybrid options without assuming a winner. Return the specified Markdown documents in a real downloadable ZIP, with sources, measured-versus-proposed distinctions, Max 2027 interop findings, and a concrete prototype/validation plan. Use researcher ID [A/B/C].

The brief contains instructions and baseline context. The requested completed research documents are produced by the research AI in a separate ZIP. No production code, GPU benchmark, or new Max qualification is delivered by this brief.

The coordinator can compare returned reports by their decision matrices, source ledgers, Max interoperability evidence, assumptions, experiments, and falsifiable acceptance criteria. Model confidence alone is not evidence.
