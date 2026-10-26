# Workflow: three external cores, one local integration

The Web chats do not need Max access. They need the same packet, a frozen source interface, independent tests, and narrow ownership. The coordinator here owns contract changes and final integration.

## Responsibilities

| Owner | Implements | Allowed implementation directory | Tests independently with |
| --- | --- | --- | --- |
| GPT Web A | Primitive collision queries, owned immutable scene and Jolt lifecycle | `starter/collision/` | Analytic sphere/box controls, lifetime and generation tests |
| GPT Web B | Static rooted guide fitting | `starter/fitter/` | Its own analytic/fake CollisionWorld implementation |
| GPT Web C | Prepared ribbon evaluation and independent visible mesh validation | `starter/delivery/` | Authored feasible/bad poses and analytic triangle/primitive geometry |
| Local coordinator | Source review, combined build, integration harness, missing fixes, host adapter and qualification | Later authorized local scope | Combined fixtures, then owned Max 2027 scenes and output checks |

All implementations link the same `cyrus_prototype_contract` CMake interface target. A must export `cyrus_vegetation_collision`, B `cyrus_vegetation_fitter`, C `cyrus_vegetation_delivery`. Each creates only its own directory's CMakeLists, source, private headers and tests. Test names begin `collision_`, `fitter_`, or `delivery_`. No target name collisions, shared helper edits, or changes to the top-level scaffold. Private helpers can be duplicated initially and consolidated during integration if warranted.

## Dispatch and handback

1. Upload the same complete ZIP to each chat. Ask it to unpack and inspect files, including originals relevant to its claims. If uploads cannot be extracted, provide the contract, header, assigned prompt and required reading separately; do not assume it saw the archive.
2. Paste its assigned prompt. It must first state role, edition and frozen contract hash. These are implementation assignments, not another open-ended research round.
3. Each chat implements its module without needing the other two implementations. If a shared contract issue blocks correct code, it returns a precise change request; it must not silently fork the interface. The coordinator can issue v2 to all three.
4. Each returns a source ZIP, structured manifest and short report with exact commands/results. Missing execution capabilities must be explicit. “Expected to pass” is not “passed.”
5. Bring all three returns to this local chat. Preserve each original handback. Review scripts and build files before executing them, verify frozen hashes and allowed paths, then combine in a fresh isolated review directory. The dirty production checkout is not the merge workspace.

ZIP handback is the default. No GitHub access is assumed. If the user later chooses Git, use separate feature branches with these same ownership limits and return commit IDs/diffs. Do not merge, push main or publish from an external chat.

## Gates and review order

**G0 — packet/contract.** Same edition and frozen hashes; finite inputs, units and status semantics understood. Starter declarations and fixture inputs are not implemented modules.

**G1 — independent modules.** Each module builds/tests headlessly in its documented environment. Real tests cover both acceptance and rejection; source inspection verifies no fabricated metrics or stubbed success. A mock collision world qualifies B's algorithm tests only. A standalone Linux Jolt build does not qualify Windows or Max runtime sharing.

**G2 — combined core.** Build A+B+C together locally with the available Windows C++ toolchain. Add a coordinator-owned integration runner: snapshot → fit → evaluate → independent validation. Begin with the supplied clear/rest, known-feasible one-sphere, and root-conflict cases. Then cover whole-segment crossing, visible-width failure, rotated box, two obstacles, cancellation, resource limits and stale generation. Record exact source/build/input hashes. Inspect geometry dumps if useful; pictures alone do not establish contact acceptance.

**G3 — local host feasibility.** Only after G2, build a small Max 2027 adapter in an owned disposable profile/scene. Copy all scene inputs on the host thread; workers see owned snapshots; publish a complete checked successor on the host thread. First prove a single prepared ribbon through viewport, actual renderer geometry and Bake, plus Undo/reset, failure retention and source preservation. This early output gate can reject the design before any scale work. No artist session is installed into or restarted by this packet.

**G4 — product decision.** Measure representative assets and bounded patches, memory, invalidation and interaction cost. Compare alternatives at equivalent visible acceptance. Only then choose integration breadth, presets and delivery. A research prototype is not a new Scatter release; release version selection, exact script/native pairing and a runnable Max 2027 MZP belong to a later qualified delivery.

## Local acceptance rules

- A solver's `ConvergedCandidate` is not publication approval. Independent C validation, exact snapshot/source identity and current host dependencies must all agree.
- Preserve original accepted placement IDs and planted roots; fit source-derived geometry without modifying the source asset or silently deleting/reseeding instances.
- Failure, timeout, cancellation, unsupported data and stale input retain the previous complete accepted output.
- No hidden persistent simulation history. Repeated static fits start from the same immutable rest state. Dynamics, self-contact, draping and rigid settling need separate contracts and experiments.
- None of these gates automatically checks off the research library's 68 cases or eight comparisons. Record actual mappings and limits separately after execution.
