# 10 — Readiness review and corrections before implementation

4 October 2026 · source checkpoint `53bfc5d1c76929958dbeb29f5d4c746b2321d0ac` · next product label **Cyrus Scatter 0.7 pre-release**

**Ready to start the staged implementation.** The current architecture is a sound foundation: keep its native numerical core, procedural Brush history, protected editing, retained Point Cloud/Mesh and cached Proxy paths. Add explicit ownership/order/rules and measured cache boundaries. This review does not qualify the unimplemented policy, current artist scene, Max 2026/2027 runtime or a new performance result.

## What was checked

Traced the final generated MAXScript alongside its generators/templates, because late transformations change the effective behavior. Reviewed layer/set ownership and allocation; candidate RNG/identity; area/Brush/transforms; source radii; protected Edit inputs/clones; ordered spacing and union cleanup; cache keys, Manual display and publication; UI control inventory; MCP schemas/host mapping; and the implementation/test plans.

Built the current SDK-independent numeric core in an isolated ignored build directory. Ran existing tests plus a dedicated numerical probe. Reproduced both generated UI artifacts in an isolated copy. Ran current MCP tests with mock hosts, temporary local transport and offline stdio fixtures. Added small design counterexamples for quota allocation, cache/round determinism and duplicate coverage sampling.

No production implementation, installed plugin or Max scene was edited or launched by this review. New executable code is limited to reproducible review probes under this documentation package. Other concurrent untracked licensing work was left alone.

## Fresh evidence

| Check | Result | What it establishes |
| --- | --- | --- |
| Current numerical core, clean isolated build | Passed | Current pure-data source builds with the pinned MSVC environment, `AMIN_BUILD_MAX=OFF` |
| Native CTest | **13/13 passed** | Twelve existing native tests plus one readiness probe; not thirteen Max runtime scenarios |
| MCP pytest | **61 passed** | Current contracts/service/local transport/offline stdio behavior; no real Max application test |
| UI regeneration in isolated directory | Both artifacts match | Generated MAXScript and control inventory reproduce after text newline normalization |
| Native area-filter probe | 68 retained candidates: positions unchanged; 66 changed scale/orientation, 41 changed source | Candidate identity stability is weaker than attribute stability in this current generation mode |
| Cleanup-release probe | Two blocked lower candidates become valid after the isolated blocker is removed | Supports the need for bounded sibling reconsideration; not an implemented host refill loop |
| One-pass cleanup probe | One centre survives a three-point chain | Current neighbor threshold is evaluated before removal; it is not an iterative surviving-degree guarantee |
| Shear witness | Unit vector transforms to length 1.58114 while max row length is 1.41421 | Current row-length formula is not a general conservative shear bound |
| Logical schedule counterexample | Naive cold/warm cache gives different results; fixed exposed prefix agrees | Cache capacity must not decide logical batch/cleanup boundaries |
| UI inventory and key audit | 194 inventory entries; set name/visibility found in prepared-base key | Full control-family map and a concrete invalidation classification to qualify |

Raw commands, logs and exact observations: [evidence README](evidence/readiness/README.md), [native/generator/MCP checks](evidence/readiness/checks.json), [contract probes](evidence/readiness/contract-probes.json). [Review verification](evidence/readiness/verification.json) records preserved source hashes, links and evidence digests.

## Corrections made to the plan

### 1. Stable IDs do not guarantee stable plants

In `scatter.cpp`, rejected area/density candidates can skip random draws used by assignment/transforms. An unchanged candidate key may subsequently refer to the same position but a different source or scale. Use versioned candidate/purpose random channels for the new policy, preserving existing output under the old policy. Separate sampling seeds from ownership UUIDs so copying and reordering have intentional behavior.

Largest-remainder allocation also needs its own stable tie key. A collision reorder must not transfer a remainder quota. Increasing a total from 25 to 26 in the documented six-weight fixture decreases two set shares; do not promise monotone set populations or final membership merely because the candidate stream has a stable prefix.

### 2. Coverage tests the supporting surface position

The former wording could reject a deliberately lifted plant because its final mesh origin was off the receiver. The updated pipeline records latent anchors, resolved support anchors and final instance transforms separately. Test painted eligibility at the declared support coordinate; apply source offsets and artist edits without conflating their origins with coverage anchors. Repeated probabilistic filtering must not accidentally square coverage strength.

### 3. Protected records need active, validated bindings

Current CS Edit resolves incoming IDs and gives clones distinct output IDs. Stored records do not unconditionally create blockers. Erasing an eligible input suppresses its edited result; a valid manual move outside coverage is a separate protected exception. Radius overrides must identify the final instance, including clones. The proposed over-target/zero-quota protection needs a qualified input-reconstruction adapter before release.

### 4. Cleanup/refill has an observable logical schedule

Union cleanup can release space after another set was rejected. Bounded replay addresses that, but temporary suppression depends on which candidates were exposed in each round. Fix and version the logical sequence; physical CPU chunks and resident cache size may not choose it. Report limits and suppression bias. This algorithm is not maximal packing and needs its own quality/work experiment before choosing defaults.

### 5. New policy integration spans UI, display and automation

There are 80 literal policy-2 condition sites in the generated program, partly due to repeated UI factories. Updating only the solver would miss Paint Set creation, Manual display, copying, Edit visibility and Relax guards. Introduce explicit policy capabilities and audit dispatch. Keep existing MCP plan versions unchanged until their extension is qualified.

Set names and visibility currently participate in a base cache key despite their presentation purpose. The source finding is confirmed; interactive cost needs a Max mutation fixture. Key building/configuration should be pure, and publishing the new result must include transient Edit and statistics/display state, with failure rollback tests.

### 6. Option ownership is now explicit

[11 — Option contracts](11_OPTION_CONTRACTS.md) covers General versus Layer versus Set controls, Base versus child switches, source transforms, masks, two fill concepts, zero weights, visibility, statistics and unsupported combinations. Background references do not invent a second hidden collision radius; zero clearance and whole-surface exclusions must be explained clearly.

## Confidence and remaining gates

| Area | Confidence / readiness |
| --- | --- |
| Current source ownership, evaluation trace and known guards | High; source traced and pure core/MCP suites rerun |
| Intended three-scope rule and option semantics | High enough for P1–P2 implementation with an independent oracle |
| Existing per-mode viewport architecture | Source understood; preserve it, but obtain a new controlled runtime baseline before changing integration |
| New random channels, Edit conversion and per-instance radii | Defined contracts; still require code and correspondence/Undo fixtures |
| Cleanup/refill quality and useful work caps | Bounded design established; heuristic quality, schedules and caps still need P3 experiments |
| Incremental invalidation and multi-consumer publication | Concrete risks identified; forced-fresh/mutation/failure tests required |
| New MCP operations, Max 2026 support, renderer qualification | Not established by local tests; separate integration gates |

The next delivery remains P0 baseline/observability followed by P1 normalization and P2 independent collision scopes. The first artist fixture is a Garden layer with red/blue/yellow sets and a separate tree layer, each relationship adjustable independently. Only after that works should Background and Target replenishment be integrated. No general graph editor, GPU placement or ML implementation is required for this milestone.

The updated [roadmap](07_IMPLEMENTATION_ROADMAP.md) and [validation matrix](08_VALIDATION_AND_EXPERIMENTS.md) specify the remaining work. Ready to implement means the boundaries and tests are clear; it does not mean the future feature has already passed them.
