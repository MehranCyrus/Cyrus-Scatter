# 06 Houdini and tyFlow workflow comparison

**Status: documented building blocks and unexecuted recipe proposals.** R09 HTML and R10 PDF are the latest supplied practical study. Use their detailed node/operator order for reproduction, with the limitations below. R05-R07 remain preserved earlier research.

## How to read the vendor evidence

The latest study separates documented controls (D), saved example structures reportedly inspected by its author (I), assembled recipe proposals (P), and executed DCC tests (X). It reports no X-level Houdini, Max/tyFlow, renderer or round-trip tests. Downloaded-asset hashes and arithmetic fixture checks are useful provenance; they do not establish simulation success. This consolidation has not independently repeated the author's HDA decompression.

The HTML has 14 sections. The PDF is a 64-page presentation of the same study, with cover/contents, page furniture and some presentation/text differences. Both originals are retained; they are not treated as identical files or independent corroborating experiments.

## Corrected comparison

| Scenario | Houdini candidate | tyFlow candidate | Qualification limit |
| --- | --- | --- | --- |
| One fixed stone, rooted grass | H1B static Guide Collide; H1C separate rest/current Vellum setup | C clear guide with Particle Bind/Angle Bind and fixed stone | Full roots, frames and decoded mesh need checking |
| Two fixed stones | H2B joint VDB candidate; H2C joint fixed-collider Vellum | C2 joint guide bindings and both colliders | Simultaneous contacts; no guaranteed unique route |
| Conditioned grass | H1A/H2A moving collider then hold | A/B direct ribbon with moving collider then hold | Explicitly history-dependent loading |
| Rigid pebbles | Packed geometry with RBD Configure/Bullet | PhysX Shape plus PhysX Collision | Clear initial bodies, correct hulls and terrain |
| Rigid leaves | Thin rigid proxies and transformed render source | TF-LR rigid PhysX route | Shape remains rigid; cannot fold |
| Deforming leaves | H4D Vellum cloth surface | TF-LD Cloth Bind with CCCS | Unique deformation, thickness and cache/output validation |

See the [corrected planning matrix](checklists/RECIPE-COMPARISON.md). It is a synthesis, not a replacement claim that the recipes were run.

## Three distinct evaluation models

A static geometry operation recooks from its current input without a normal timeline simulation. A frame-local internally settled result still performs integration/relaxation inside the evaluation. A timeline simulation uses earlier states and can later be frozen or cached.

Houdini's Vellum Simulation Type Quasistatic rolls current inputs forward internally. H22's Orientation Solve Quasistatic is a separate hair bend/twist control. Guide Deform Preserve Shape is another distinct relaxation feature; its documentation does not establish obstacle contact. Avoid merging the three meanings into a claim of an automatic universal fitter. [Vellum Solver](https://www.sidefx.com/docs/houdini/nodes/sop/vellumsolver.html), [H22 Vellum changes](https://www.sidefx.com/docs/houdini/news/22/vellum.html), [Guide Deform](https://www.sidefx.com/docs/houdini/nodes/sop/guidedeform.html).

tyFlow's history-independent mode restarts at each frame; that description does not establish equilibrium fitting. A held cached frame can be a static deliverable from a history-dependent simulation. [Main settings](https://docs.tyflow.com/tyflow_objects/tyFlow/mainSettings/), [reset behavior](https://docs.tyflow.com/faq/reset/).

## Root and decoder details that matter

The latest Houdini fixed-stone recipe explicitly keeps straight-rest constraints separate from a clear bent initial guide and reinitializes its orientation. This is a substantial improvement over assuming that an already bent rest guide will spontaneously seek the stone at zero gravity. It remains an assembled, unexecuted scene proposal.

Its named Path Deform route is a practical decoder candidate for straight prepared strips. A constant-up geometric frame does not transfer arbitrary simulated material twist and can fail near a parallel tangent. The two-stone recipe therefore retains a guide-level qualification boundary until the visible strip's frame and contact pass. [Path Deform](https://www.sidefx.com/docs/houdini/nodes/sop/pathdeform.html).

tyFlow's guide route uses Particle Bind and Angle Bind. Hair Bind attaches particles to Ornatrix strands; its name is not evidence of a general grass solver. Bind-segment collision must be enabled explicitly, and the Collision operator's absolute radius supplies its object envelope. A root particle's rotation is not equivalent to a solved rod material frame. [Hair Bind](https://docs.tyflow.com/tyflow_operators/particles/hair_bind/), [Particle Bind](https://docs.tyflow.com/tyflow_operators/particles/particle_bind/), [Rotation](https://docs.tyflow.com/tyflow_operators/particles/rotation/).

For detailed meshes, isolate blade association and inspect every decoder. A good low-resolution driver is not proof that tyParticleSkin, spline meshing or another binding preserves final contact.

## Versions and prerequisites

As checked on 24 October 2026, current SideFX pages identify Houdini 22 and tyFlow's release history lists 2.101 dated 8 October 2026. Earlier minimum node versions do not imply every current parameter existed then. Keep exact build and node versions in each experiment. [SideFX documentation](https://www.sidefx.com/docs/houdini/nodes/sop/vellumsolver.html), [tyFlow release history](https://docs.tyflow.com/download/version/).

Current tyFlow download/release information specifies CUDA 12.8, while older system/FAQ pages contain older requirements. The general bind solver and CCCS have different CPU/GPU boundaries. FREE license restrictions also affect GPU acceleration and tyCache export. Verify the selected package, driver and license rather than copying an older requirement into a support promise. [Download](https://docs.tyflow.com/download/), [system requirements](https://docs.tyflow.com/download/system_requirements/), [FREE license](https://docs.tyflow.com/license/free/), [CCCS FAQ](https://docs.tyflow.com/faq/CUDA_collisions/).

Local project development and host validation remain Max 2027 only. A vendor's broader support does not authorize a different host for our tests.

## Reproduction checklist

Record physical geometry, coordinate conversion, scene units/fps, original rest state, clear initialization or conditioning history, root/frame controls, solver budgets and inherited defaults. The latest report deliberately avoids assigning a guessed SI meaning to tyFlow's native gravity values; use its documented real-world-value action and record the resulting value.

Run one blade/body first. Show the driver or hull beside the visible mesh. Then run two obstacles together, move an obstacle away, reset from the declared state, freeze/cache, reopen, render and export/reimport. Keep reset, in-memory hold, disk cache and baked mesh distinct. Cache loading can intentionally continue showing old output after upstream edits.

The written task counts are planned task groups, with unequal preparation boundaries between recipes. They are not measured clicks, artist time, performance rankings or product UX targets.

## Missing companion data

R09/R10 refer to common_grass_initialization.json, also named CyrusScatter_Common_Grass_Initialization.json, and to an example-download manifest. Neither was supplied among the ten files, and neither JSON filename was found in Downloads during this organization. The study prints some construction directions and arithmetic results, but that does not restore the missing artifact's exact bytes or provenance.

Retain the recipe IDs and report the dependency as missing. A later reconstruction can be useful if explicitly labeled newly derived fixture data. Do not present it as the author's original or a validated .hip/.max scene.
