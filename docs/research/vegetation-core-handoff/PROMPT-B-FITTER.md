# Paste into GPT Web chat B: rooted static fitter

You are implementation owner B for CyrusScatter Vegetation Core Handoff v1. Owners A and C receive the identical ZIP but cannot see this chat. Implement your independent module against the frozen contract; no 3ds Max or other owner's implementation is required.

Read `START-HERE.md`, handoff `DOCUMENT-LIST.md`, `WORKFLOW.md`, `SHARED-CONTRACT.md`, `FROZEN-FILES.json`, the frozen header and `fixtures/catalog.json`. State role, edition and the header's actual SHA-256. Read synthesis 01/03/04/05/07/08/09 and relevant R11–R14 reviews/originals. Preserve the distinction between report-local claims and your executed tests.

Implement `fit_rooted_guide`. You own **only** `docs/research/vegetation-core-handoff/starter/fitter/`. Export CMake target `cyrus_vegetation_fitter`, link `cyrus_prototype_contract`, and prefix test names `fitter_`. Put implementation, private helpers, fake/analytic CollisionWorld tests, README and evidence there. Do not depend on A, Jolt, C, the Max SDK or production plugin code. Do not edit the shared header/scaffold/catalog. Report necessary interface changes in your module's `CONTRACT_CHANGE_REQUEST.md`.

Target a bounded one-way static fit of a prepared rooted grass guide around fixed obstacles, starting afresh from rest on every call. Keep the planted root, source data, node/span identities and length constraints. This is optimization/projection with a declared numerical strategy, not a time-stepped animation that must settle eventually.

Required behavior:

- Validate all array, numeric, frame, source revision and budget contracts before solving. Match the world generation. Use a privately staged pose; never mutate input or publish externally.
- Implement PositionOnly root mode first. Implement ClampFrame and SoftFrame with honest independent tests, or return Unsupported for missing modes. Fixing root position does not by itself fix root angle. Report each mode's precise residual and behavior.
- Use whole-span capsule queries, all relevant contacts, conservative width envelopes, local qualified witnesses and repeated refresh. A witness is not a permanent attachment; zero gradient and local root conflicts need explicit handling. Couple contacts with length, rest-shape and bending terms. Explain the chosen discretization and numerical coefficients; do not label them real material properties.
- Bound proposal length, iterations, query count and owned/scratch memory. Check cancellation at bounded loops. Incomplete/ambiguous queries must not produce ConvergedCandidate. Failed search is not proof that no feasible configuration exists.
- Regenerate unit tangent-aligned material frames without accidental flips or hidden full-turn assumptions. Enforce length and root tolerances. Compute actual final residuals and honest memory/work metrics. Empty/clear cases preserve rest exactly.
- Return `ConvergedCandidate` only after your final complete collision/constraint checks. This still needs C's independent visible-mesh validator at integration. No invented “mesh validated” flag or claim is permitted here.

Build your own deterministic analytic/fake CollisionWorld for tests. Include the catalog's clear/rest, known-feasible one-sphere scene and root-inside failure, whole-segment contacts, width-envelope admission, generation mismatch, multiple simultaneous obstacles, cancellation and work exhaustion. Test a zero-denominator local conflict, frame/quaternion signs, repeated static calls from rest and input immutability. For feasible tests, verify actual constraints; a harness that accepts every failure status does not prove the fitter works. Supplied authored feasible poses are positive controls, not permission to hardcode the solver's answer. Include tests away from the supplied geometry.

Explain how first-root span orientation behaves and how the rest objective prevents gratuitous deformation. A local feasible control can establish existence in that fixture; unresolved cases must retain diagnostic status. No deletion/reseeding of vegetation, guide extraction, draping, self-collision, rigid settling, GPU, web demo or full Max plugin is requested.

Return your complete source ZIP and manifest per `RETURN-CHECKLIST.md`, with exact file hashes, starting contract hash, build/test commands, compiler, observed results, numerical limitations and any unsupported modes. If no compiler is available, mark execution Not executed and still supply complete code. Do not fabricate logs, timings, renderer images or host passes. End with a concise integration note.
