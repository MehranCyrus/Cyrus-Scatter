# 03 — Product positioning and workflows

**Status: product hypotheses to validate with artists.**

## Initial market focus

| User | Repeated job | Why Cyrus might matter | Evidence required |
|---|---|---|---|
| Archviz freelancer | Plant a site and absorb design revisions | Boundaries, clearances, orderly rows, local edits in one workflow | Faster completed revision task than their current method |
| Environment artist | Combine natural variation with intentional placement | Layer dependencies, source groups, precise overrides | Result quality and retained control under iteration |
| Studio lead / technical artist | Standardize scenes and reduce handoff failures | Presets, diagnostics, versioned outputs, deployment | Another artist and worker reproduce the result |
| Pipeline engineer | Batch validation/rendering with predictable failure | Headless preflight, manifests, stable APIs | Unattended job succeeds or reports an actionable failure |

Start with the first two, then prove studio handoff. Large-scale crowd simulation, vegetation modeling, GIS, and general CAD automation are separate products unless a validated workflow justifies expansion.

## Competitive reality

Chaos's official Max guidance already covers slope/altitude limits, group/hierarchy scattering, instance editing, brush workflows, clustering and edge trimming. These cannot be presented as inherently novel Cyrus ideas. [Chaos advanced workflows](https://support.chaos.com/hc/en-us/articles/4953359913617-How-to-use-Chaos-Scatter-with-Corona-for-3ds-Max-Advanced-Features)

ForestPack markets a mature scattering ecosystem with libraries, renderer integration, display controls, and supporting tools. Its public material establishes a high usability and production-integration benchmark; it does not establish comparative performance against Cyrus. [ForestPack product information](https://www.itoosoft.com/forestpack)

Autodesk is expanding native procedural tools. The implication is that Cyrus must preserve value even as host building blocks improve: better task composition, predictable revisions, understandable constraints, and dependable delivery. Use native capabilities where they improve those outcomes.

## Candidate differentiation

**Design-aware layout:** turn suitable site geometry into useful borders, center paths, spacing guides and controlled populations; combine this with editable layers and recoverable manual intervention.

This is a positioning hypothesis. We have not established that competing products cannot perform equivalent work. Benchmark complete tasks fairly, with a competent user of each tool, common assets and matching visual constraints. Never describe an untested competitor workflow as impossible or slow.

## Three flagship workflows

### W1 — Courtyard planting with protected hardscape

Input: planter surfaces, paving exclusions, three vegetation sources, a few hero trees.

Steps: analyze suitable regions → create tree/shrub/groundcover layers → set footprints and cross-layer clearances → adjust density/falloff → place a few deliberate edits → change the planter boundary → render and hand off.

Definition of success: no accidental hardscape population; understandable underfill; predictable treatment of hero edits after a base change; identical qualified render on reopen. Measure initial setup, revision, troubleshooting and render preparation separately.

### W2 — Street edges and repeated site furniture

Input: road-adjacent planar strips, street reference, tree/lamp/bollard sources.

Steps: Analyzer Street Side/centerline → ordered edge rows → spacing, corner handling and source-forward axis → local offsets → trim intersections → manually suppress conflicts → export guides or bake when needed.

Definition of success: rows align correctly around corners/holes, trims behave predictably, units are clear, no duplicate intersection objects, and a revised road does not silently attach edits to the wrong instance. Curved/nonplanar civil geometry is outside Analyzer's current general guarantee.

### W3 — Multi-layer landscape delivered to a studio

Input: moderate terrain, art-directed regions, mixed mesh/proxy assets, several scatter layers.

Steps: compose weighted sources and masks → preview within budget → perform an artist revision → preflight dependencies → render on a second workstation/worker → reopen after an update/rollback.

Definition of success: no missing assets or double population, clear version/renderer requirements, predictable memory use, and no paid authoring seat required merely by the proposed free-worker evaluation policy.

## Value proposition tests

Ask a tester to complete a task before explaining every control. Observe where they stop, misinterpret a parameter, or distrust the result. Then ask which part they would keep using on a paid project and what prevents adoption. Enthusiasm is weaker evidence than independently repeated use.

Proposed pilot targets: 4 of 5 new testers complete W1's simple first scatter in ten minutes without developer intervention; at least three complete a real revision and return to use Cyrus again. These are internal decision gates, not statistically representative market claims. See [16](16_Beta_and_Product_Validation.md).

## What to sell first

Sell the completed workflow and its support commitment. Lead demos with boundary changes, retained intent, diagnosis and handoff. Show the time saved on a named task and tested configuration. Avoid a demo that succeeds only because the developer knows hidden parameter interactions.

Use customer-owned meshes and a small original sample kit. A large paid asset library is unnecessary for proving the procedural workflow. Any distributed assets need clear redistribution rights; the plugin must work without cloud downloads.

## Expansion triggers

- More studios repeatedly need the same deployment workflow → prioritize fleet installation and floating seats.
- Artists repeatedly hit the same missing control → specify it with fixtures before expanding the UI.
- Multiple pilots need animated/deforming surfaces → fund temporal identity and motion-blur work.
- A measured transport cost dominates → fund a renderer/host adapter experiment.
- Users cannot articulate a reason to switch or add Cyrus → refine the target workflow before increasing marketing or feature breadth.
