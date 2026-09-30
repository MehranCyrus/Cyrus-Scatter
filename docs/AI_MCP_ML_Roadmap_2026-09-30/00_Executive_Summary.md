# 00 — Executive judgment

**Status: PROPOSED recommendation, grounded in the [source audit](01_Current_Cyrus_Automation_Audit.md).**

## Decision

This direction deserves a small, gated research track. The most credible product promise is: **help an artist reach an editable first layout faster using their own site, assets and reference**.

A strong general model can propose intent, layer roles, asset choices and bounded settings. Cyrus should remain responsible for deterministic generation; the automation API should own validation and scene authority. MCP is the interface between a client and that API. It does not supply geometry understanding, transactions, permissions or artistic quality by itself.

**Custom ML is not needed for the MVP.** It is premature before we know which failures remain after good scene context, asset metadata, rules, templates and a small feedback loop.

## What makes the idea strong

**VERIFIED IN CURRENT CODE:** Cyrus already has layers, source weights, repeatable seeded generation, masks, orientation, spacing, falloff, Analyzer outputs, editable instances and several previews. These provide useful controls for a design assistant. The model can choose among a rich procedural vocabulary without generating every transform itself.

**RESEARCH HYPOTHESIS:** an artist could express “keep this courtyard open; make the edge denser; use these two shrubs” faster than configuring many controls. The benefit must include review and correction time, not just time to the first generated image.

A stable automation API also serves presets, reproducible tests and studio tools. That work has value even if the reference-driven experiment fails.

## What is weak or premature

- One reference image does not specify hidden vegetation, real-world scale, precise species, terrain, all camera views or the artist's priorities.
- “AI completes 70–90%” has no useful meaning without a denominator: unchanged instances, saved time, accepted area and accepted design intent are different outcomes.
- Learned point scores cannot independently guarantee spacing, coherent groups or protected open space. Geometric constraints and set-level selection remain necessary.
- A screenshot that looks similar can conceal invalid geometry, off-camera errors, excessive counts or overwritten edits.
- Approximately 1,000 images are not a foundation-model training strategy. Rights, independent projects, labels and paired outcomes matter more than the headline count.
- An autonomous assistant, arbitrary MAXScript endpoint, render-driven loop and full landscape generation model all add cost before basic value has been demonstrated.

## Minimum viable prototype

**PROPOSED:** one selected, static horizontal planar site; three approved mesh source assets; artist-confirmed simple convex planting regions separated from protected space; a single new Cyrus controller with at most three layers and up to three owned derived mask shapes. Start on the existing Max 2027.1 test host, not a simultaneous four-host AI rollout.

The prototype should:

1. Read a bounded context snapshot and reference.
2. Explain the interpretation and uncertainties.
3. Produce a typed plan containing only supported features.
4. Validate and show a concise change preview.
5. Apply an artist-approved proposal with a verified undo path.
6. Capture the designated viewport at the published scene revision.
7. Propose at most one constrained refinement, apply only within the approved scope, then stop.

Initial scope: count, seed, approved source weights, uniform scale and yaw ranges, simple pre-existing include/exclude regions, and explicit source-assignment semantics. More advanced Cyrus capabilities stay available manually; the API does not advertise them until their automation contracts pass tests.

Start with a **2,000 total requested-instance ceiling, three layers, three approved sources and two candidate applications**. These are conservative experiment limits, not engine maxima, measured capacity or eventual product minimums. A smaller scene is acceptable. Initial and refined candidates must both satisfy local geometric checks.

The API must compile each confirmed planting region into a smaller eligible-centre mask using a conservative scaled asset footprint, persist that mask through existing area references, and validate the final output. Merely rejecting boundary violations after every random generation is not a useful implementation. Empty/infeasible insets or unsupported region/exclusion arrangements are rejected before mutation.

### First five proposed MCP tools

| Tool | Purpose |
| --- | --- |
| `scene.get_context` | Units, selected site, approved sources, regions, ownership, revisions and capabilities |
| `scatter.validate_plan` | Schema, references, geometry feasibility, limits and a proposed change summary |
| `scatter.apply_plan` | Apply a validated, locally approved plan once |
| `scene.capture_viewport` | Capture an explicit viewport with camera and freshness metadata |
| `scatter.get_status` | Operation state, structured failures and requested/emitted/displayed counts |

These endpoints do not exist today. Local Cancel, Undo and Reject controls are mandatory prototype features even though they are not additional model-callable tools.

## Work that must come first

**VERIFIED IN CURRENT CODE:** current convenience queries can trigger updates; layer identity is positional; several source arrays must stay synchronized; CS Edit's script selection is by visible row; preview failures can discard previous display data; PFlow has broad lifecycle side effects. These make direct wrapping unsafe.

**PROPOSED:** complete the relevant [Baseline and Trust](../Product_Strategy_2026-09-29/12_First_Implementation_Milestone.md) work, then implement pure inspection, explicit ownership, revision checks, typed mutations and transaction tests. A friendly language interface cannot compensate for an unreliable scene boundary.

## Later ML: earn each addition

**FUTURE / OPTIONAL:**

1. Retrieve accepted layouts and parameter recipes.
2. Use pretrained segmentation if zoning correction is the measured bottleneck.
3. Try a small parameter or preference model for repeated studio-specific choices.
4. Investigate candidate ranking only if a stable candidate interface and edit identities exist.
5. Treat learned full-layout generation as a separate research project.

None of these stages requires committing now to a cloud vendor, a training framework, a GPU brand or proprietary scene uploads.

## Evidence and decision gates

**VERIFIED BY TEST — retained evidence only:** seven native test executables passed on 2026-09-29; a Max 2027.1 smoke run on 2026-09-28 exercised loading, basic scatter, previews, a limited CS Edit path, Analyzer execution and save/reopen. Those tests did not exercise AI, MCP, comprehensive edit recovery or actual renderer output. See [01](01_Current_Cyrus_Automation_Audit.md).

**UNKNOWN:** actual model success rate, artist acceptance, cost per accepted layout, older-host automation behavior and any custom-model advantage. The [ten experiments](11_Evaluation_and_Benchmarks.md) are the route to evidence.

## First three actions after this documentation task

1. Build three owned, reproducible fixtures and record manual artist baselines while completing the relevant Baseline and Trust fixes.
2. Implement and test the provider-neutral API on one host: pure context, validation, owned creation, undo/recovery and truthful status.
3. Add the five-tool MCP adapter and run the bounded three-layer experiment against a manual preset baseline.

Proceed only if the artist reaches an acceptable result faster without losing control or scene reliability.

