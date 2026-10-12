# Phase 2.1 candidate selection

Candidate 1, the bounded one-hop terminology glossary, was selected using only
the original development subset on original and stricter successor labels.
The fixed heading-weight candidate was not run or implemented because candidate 1
met the predeclared criteria. No parameter search or challenge-driven change occurred.

Original-label development coverage@10 rose from 93.48% to 100% (20/23 to 23/23
complete queries); precision@10 rose from 20.43% to 21.74%. Top-one relevance
stayed 82.61%, and canonical MRR stayed 0.8601. Revised-label development results
also met all selection checks. No previously found required unit at top ten was
lost under either definition. Top-k and denominators were unchanged.

Exact inputs, per-question results and applied hints are preserved in
`_local/rag/verification/20261012-phase2-1-01/experiment-01.json`.
The plan and glossary/review/challenge definitions were frozen before that run.
Selected configuration: ranking-v2.1.json, default profile terminology, unchanged
BM25 weights 1/1/0.25. The plain profile remains available for comparable regression.

Candidate selection is an engineering decision by the implementation author, not
independent or human approval. Final regression, challenge and integrity tests may
expose limitations; those results must be reported without silently retuning.
