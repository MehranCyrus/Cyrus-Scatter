# Candidate evaluation change log

## Initial freeze — 12 October 2026, before retrieval implementation

- Corpus SHA-256: 7b024e916f1f1b1ceab4771b70c6d952efcc0cd67695b88186eedf68638f08aa
- Evaluation SHA-256: 1ce9c61d4700ae29369dc338fa6a05e708f26e8e6112ef24da011fcbf28174dd
- Immutable copies: `_local/rag/verification/20261012-phase2-01/initial-corpus.json`
  and `initial-evaluation.json`.
- Forty base questions, stratified 25 development / 15 holdout; 30 language views
  of ten anchors reported separately. Same agent authored corpus and labels.
- All required/optional/negative evidence hashes and locators were validated
  against enrolled spans before indexing (124 locators across base/anchor views).
- Candidate gold and translations await human review. No independent benchmark
  or human approval is implied.

No label, question, source-selection or ranking adjustment has been made after
observing retrieval metrics. The first fixture runs corrected explicit UTF-8 test
decoding and exact dotted-identifier matching before the first corpus evaluation.
These were general correctness fixes, with failed logs preserved. No glossary,
query-ID rules, query-to-file expansions or holdout-driven tuning are implemented.

Later corrections must preserve the old snapshot, record the reason and exact
change here, and use fresh output directories. Difficult questions must not be
removed or labels weakened to improve scores.

## Phase 2.1 successor freeze — 12 October 2026

The previous section describes the preserved Phase 2 implementation. Original
corpus/evaluation bytes and their hashes above remain unchanged. The original
67 tests and original evaluation were reproduced before runtime edits; receipts
and the exact old source copy are under
`_local/rag/verification/20261012-phase2-1-01/`.

All forty labels were semantically inspected against source text, independently
of mechanical validation (124 original hash/line locators). This was agent review
by the implementation author, with human acceptance pending. Complete old/new
question records, evidence, reasons, reviewer type and status are in
label-review-v2.1.json (SHA-256
297d1c73d34ac49211996108a4abc6084f09227797543a397f241b391820f461).

Four stricter corrections in evaluation-v2.1.json:

- W10 promotes optional layout first-match/world-XY evidence to required.
- H07 promotes the explicitly requested 120-assertion qualification to required.
- C03 removes the non-interchangeable roadmap alternative for capture labels;
  the roadmap interval remains optional context.
- C04 removes the packaging-only content README alternative for importer stripping;
  that interval remains optional context.

Questions, splits and languages are unchanged; no question was removed or difficult
negative interval suppressed. H05's rank-six interval remains a conditional
wrong-build substitution risk, although it is useful comparison evidence for the
actual question. Overlap is not evidence of an erroneous answer. The W08 language
tag/English product terminology inconsistency is noted, preserving historical data.

Successor evaluation SHA-256:
d07b18cebfbe15cc7932d558fa7dee0ad1a6a872482892ef0965f60e605aecf8.
Twelve English challenge questions (ten answerable, two unanswerable) were frozen
before experiments; SHA-256:
905501de2357d6ea9a8fad44d24cb9d304c6ea152ab041dcf33b02801a199491.
Both were authored by this agent, not independently approved. The original holdout
is exposed historical evidence. Candidate 1 was selected on the original
development subset using both label definitions; candidate 2 was skipped under
the predeclared stopping rule. The selected glossary/configuration were frozen
before full regression and challenge evaluation. See EXPERIMENT_PLAN.md,
SELECTION.md and GLOSSARY_REVIEW.md. No post-challenge tuning is permitted here.

Evaluation output schema 2 adds counts, ranks, full text and diagnostics. Existing
metric definitions remain version 1, with original results preserved. Plain and
selected profiles are recomputed on identical original, successor and challenge
inputs; the frozen old runtime also evaluates the successor for baseline parity.
