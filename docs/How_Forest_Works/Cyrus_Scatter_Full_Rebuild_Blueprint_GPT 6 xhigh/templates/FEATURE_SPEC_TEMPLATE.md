# Feature specification — TEMPLATE

**Feature ID:** `[SYSTEM]-[NNN]`

**Name:**

**Reference version/date:**

**Evidence classification:** `[FP-DOC]` / `[CYRUS-DESIGN]` / `[TEST-NEEDED]` / `[SDK-VERIFY]`

**Owner and status:** `Proposed / Implemented / Tested / Blocked`

## 1. Artist intent

- User problem and example scene:
- Control label, tooltip and expected response:
- Demo scene and before/after reference:

## 2. Exact contract

| Property | Definition |
|---|---|
| Input types | |
| Units and coordinate frame | |
| Default and allowed range | |
| UI enable/disable conditions | |
| Domain: generator/surface/area/source/output | |
| Processing stage/order | |
| Combination with global/local settings | |
| Deterministic ID/random-channel policy | |
| Unsupported modes | |
| Version differences | |

## 3. Data and algorithms

- Authoritative persistent representation:
- Derived cache representation:
- Numerical/geometry algorithm and pseudocode:
- Complexity and memory behavior:
- Error and ambiguity handling:
- Candidate/boundary/collision interaction:

## 4. Dependency and change propagation

- Reads:
- Writes:
- Cache keys and revisions:
- Normal changes invalidated:
- Unexpected dependencies / Effects / linked scatters:
- Incremental vs full correctness policy:

## 5. 3ds Max and renderer integration

- SDK API and version verified:
- Host main-thread calls:
- Worker-safe immutable data:
- Viewport/selection/brush contract:
- Renderer-specific capabilities / fallback:
- Undo/Redo and clone/merge behavior:
- Save/load and missing reference behavior:

## 6. Evidence and acceptance tests

| Case | Scene | Operation | Expected result | Evidence | Pass? |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |

- Differential ForestPack test version and output (if applicable):
- Cyrus unit/property tests:
- Full rebuild equals incremental: criteria and tolerance:
- Performance profile: cold/warm, p50/p95 latency, allocations, GPU upload:
- Known exceptions and documentation:

## 7. Implementation tasks

- [ ] Data contract and serialization
- [ ] Core algorithm
- [ ] Spatial/runtime integration
- [ ] UI and artist feedback
- [ ] Renderer and host tests
- [ ] Performance gate
- [ ] Documentation and release note

## 8. Unresolved decisions

| Question | Options | Evidence required | Owner / target decision |
|---|---|---|---|
| | | | |
