# 01 — Executive assessment

## Where we stand

The work so far has been worthwhile. We have moved from a difficult-to-understand collection of features into a documented system, a performance plan, a licensing proposal, and a build that loads and exercises core functionality in Max 2027.1. The source has enough separation to improve incrementally. A rewrite would discard valuable behavior and create unnecessary scene-compatibility risk.

The documents are ahead of the verification. They describe a much more complete commercial operation than currently exists. That is useful planning, provided we stop treating a written requirement as a delivered capability. The next investment should create product evidence: real artist tasks, saved scenes, renderer results, and measured latency.

### Assessment by area

| Area | Judgment | What changes the judgment |
|---|---|---|
| Native foundations | Strong basis: independently testable Scatter and Analyzer cores | More adversarial fixtures and host integration coverage |
| Feature depth | Promising, particularly boundaries, streets, layered composition, editing | Artists finish difficult revision tasks without developer help |
| Maintainability | Workable hybrid; generated UI reproduces exactly | Guarded generator stages, explicit contracts, smaller readable modules |
| Performance | Several plausible targets; no comparative speedup evidence | Whole-operation profiles and matched before/after runs |
| Scene reliability | Good intentions and persistence mechanisms; limited host coverage | Old/current scene, mutation, undo, clone, merge and failure tests |
| Rendering | Existing PFlow transport and Corona-specific handling | Actual renderer, IR, cancellation, animation and farm qualification |
| Compatibility | Max 2027.1 smoke-tested; broad support remains work | Per-year builds and qualified update/renderer combinations |
| Commercial readiness | Detailed proposal, no implemented licensing system | Policy decisions, operational tests, signed distribution and support |

## The product promise I recommend

**Create precise, believable environments; revise them procedurally; preserve intentional edits; deliver the same result to another workstation or render worker.**

This gives development a useful test: does a change shorten a real task, prevent rework, or make the result easier to trust? A new checkbox that does none of these should wait.

Our strongest initial audience is architectural visualization and environment artists doing controlled landscaping, courtyards, roadsides, borders, and repeated site furniture. Studio pipeline staff become the second buyer when those artists need deployment and reliable handoff. “Every artist” is an ambition; it is too broad to define the first release.

## What to preserve

- The host-independent C++ cores and native preview/editing work.
- Deterministic behavior, source order and saved identifiers.
- The combination of automated layout and deliberate manual overrides.
- Existing scene data and the ability to diagnose why an update changed the result.
- Separate display budgets and final output population.
- A CPU path that can operate without an optional compute runtime.

## What to change first

1. **Make correctness observable.** Show requested/generated/displayed counts, stale state, errors, cache rebuild reasons, and build identity. Add bounded local diagnostics.
2. **Prove a complete workflow.** Install, create, edit, render, save, reopen, and hand off a scene. Passing a mathematical test is one part of this chain.
3. **Fix reproducible correctness failures before optimizing their code.** Prioritize the specific investigation cases in [02](02_Current_System_and_Evidence.md).
4. **Improve the measured slow operation.** Preserve the current result and demonstrate the gain in the artist's full interaction.
5. **Package one excellent starting experience.** A short quick start and a few useful procedural recipes can make existing depth accessible.

## Important strategic changes from the older plans

- Start measurements on the working **2027.1** baseline. Continue the required 2024–2027 qualification program; do not wait for every host to become available before measuring.
- Give renderer preparation and scene lifecycle equal status with placement math. A faster sampler cannot eliminate expensive render transport.
- Investigate **2027.2 Point Instance** as a bounded transport experiment. Autodesk documents its arrival, but our installed/tested baseline and renderer evidence do not prove that it can replace Cyrus's PFlow path. See [06](06_Max_2024_2027_and_Autodesk_Opportunities.md).
- Keep licensing policy design active, but introduce enforcement after saved-scene and rendering contracts are tested. A licensing failure must not become a geometry failure.
- Keep the first commercial offer simple. Studio floating, on-premises services, multiple renderer adapters, USD, brush tools, and GPU execution each create lasting support obligations.

## What I would postpone

A full Qt rewrite, a universal node graph, a proprietary asset marketplace, generative AI features, simulation/crowds, and several competing GPU backends. None has earned priority from current evidence. The same applies to promising millions of interactive instances without specifying source complexity, display workload, hardware, and renderer.

Postponing an idea is a resource decision. Revisit it when a pilot workflow demonstrates an unmet need and the acceptance test is clear.

## How to allocate effort

Until the first qualified beta, keep roughly half of engineering attention on correctness, integration, diagnostics and releases; the remainder on measured performance and artist workflow improvements. Treat this as a planning guideline, not a time estimate. Limit active implementation to one risky subsystem change at a time so regressions have an identifiable cause.

A smaller release that artists can confidently use on paid work creates a better foundation for growth than a broad release with uncertain rendering or scene recovery. We should aim for excellence in a few repeatable workflows, then expand using customer evidence.

## What success would look like

An artist creates a planted courtyard, adjusts its boundaries, keeps a few hand-positioned trees, renders correctly, and gives the scene to a colleague without rebuilding the work. A studio can identify the installed version, reproduce a failure, roll back a package, and render existing jobs during a licensing outage. Those outcomes are the practical meaning of an indispensable plugin.

The next step is the [Baseline and Trust milestone](12_First_Implementation_Milestone.md), followed by the first measured optimization and a focused artist beta. No credible release date or speed multiplier can be promised from the current evidence.
