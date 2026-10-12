# Phase 2.1 experiment plan

Recorded before candidate experiments. The original corpus/evaluation bytes remain
frozen. Candidate decisions use only the original development questions, on both
original and stricter successor labels. The exposed original holdout is historical
regression evidence. The new English challenge is frozen before experiments and
is evaluated only after candidate selection; it is agent-authored, not independent.

## Diagnosis and bounded candidates

Ordinary OR token search repeats nearby passages and does not match inflections or
translated lifecycle words. Development H01's historical applicability qualifier,
B01's explicit mutation boundary and B04's issuance/import qualifier fall below
rank ten. This diagnosis uses source text and development results only.

Test at most two fixed candidates, with no parameter sweep:

1. A bounded one-hop glossary for source-grounded historical applicability,
   authoring/mutation and licensing/import terminology. Preserve exact modes and
   original query signals. Cap expansions and record every application.
2. Only if candidate 1 fails the criteria: the same glossary plus a fixed 2.0
   heading-context BM25 weight (text 1.0, path 0.25 unchanged). No current-status
   boost, source-path rule, query-ID exception or version inference is allowed.

Stop when an eligible candidate is selected, or retain plain behavior if neither
improves the tradeoff. Configuration, rationale, failures and per-question changes
are persisted. Interface/integrity fixes do not depend on retrieval improvement.

## Practical selection criteria

On development questions under both original and successor labels:

- Do not lose any previously found required evidence unit at top ten.
- Do not reduce macro coverage@5/@10, source precision@10 or top-one relevance.
- Improve development boundary coverage@10 or complete-query count, and improve
  source precision@10 or canonical MRR (at least one strict gain in each pair).
- Preserve exact lookup, filters, Unicode/citations and deterministic fixture checks.
- Keep top-k and precision denominators unchanged. No threshold-based result pruning.

Latency is observed rather than promised. The bounded 205-chunk corpus can tolerate
additional read-only integrity checks; report their cost. After selection, freeze
runtime/configuration before full regression and challenge runs. Later failures are
reported without retuning. Glossary meanings/relevance and candidate labels remain
pending human review. No Codex connection, refresh process or MCP transport is added.
