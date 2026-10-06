# Requirement traceability and open decisions

## Requirements mapped to work

| ID | User need / existing contract | Current boundary | Proposed work and acceptance |
| --- | --- | --- | --- |
| R01 | Generate many meaningful scattering alternatives | No large public MCP batch contract | P2/P3; bounded attempts, reproducible candidates, useful diversity; E06/E07 |
| R02 | Artist/boss/team selection teaches preferences | No persistent review/training workflow | P3/P4; A/B/tie/neither/skip, profiles, explicit context; E08 |
| R03 | Improve future results from feedback | No trained Cyrus composition model | P5; grouped holdout and blind improvement over simple baselines; E09/E10 |
| R04 | Understand reference images and professional composition | Future work | P6; editable observations, masks/relationships, actual-geometry validation; E11 |
| R05 | MCP understands the whole supported plugin | Nine tools; newer policy is read-only | P2; registry-backed capability map, no invented tool support; E05 |
| R06 | AI can loop and refine | Current bounded two-apply workflow | P2/P6; durable finite workflow and explicit batch scope; E06/E12 |
| R07 | Use graphs where helpful | Existing dependency/identity structures; no new graph framework | Distinct scene/workflow/knowledge roles; E13 before extra infrastructure |
| R08 | Ordered layers and paint sets, stable identities | Native policy-3 foundation | Preserve order/defaults/salts and exact lineage in new plans; E03/E05 |
| R09 | Three collision scopes and adjustable radii | Native foundation; incomplete public mutation coverage | Export effective post-transform radii/reasons; policy-3 schema parity; E05 |
| R10 | Brush on flat/curved static surfaces | Local native workflow; API design scope narrower | Surface-bound enrolled documents and topology checks; no silent flattening; E05 |
| R11 | Coverage exclusion, between-plants fill, bounded replacement are separate | Native procedural options | Separate typed controls, diagnostics and feasibility tests; E05 |
| R12 | Each layer owns settings; sets inherit declared defaults/population | Native logical-layer system | Record declared/effective values and overrides; UI/API parity; E05 |
| R13 | Model containers preserve parked models' settings | Local implementation; MCP references only | Membership/version snapshot and stale-batch handling; E03/E06 |
| R14 | Manual/Live, Undo, persistence and statistics agree | Existing behaviour and prior evidence | Qualification fixtures and failed-successor preservation; E02/E03/E05 |
| R15 | Retain Mesh/Point Cloud improvements | Existing measured baselines | No observation/navigation regeneration or unchanged upload; E02 |
| R16 | Rendering and previews correspond to actual results | Prior production success; IR issue open | P0/P1; causal diagnosis and image/publication identity; E01/E04 |
| R17 | Logs explain how the plugin reacts | Several bounded developer tools; incomplete causal history | Unified event vocabulary and bounded ring buffer; E01/E02 |
| R18 | Test CPU, memory, bounds and threading before GPU abstraction | Native work ceilings and retained caches | P0/P7; measured budgets and host-thread boundary; E02/E14 |
| R19 | Preserve artist scenes/profiles and licensing work | Required operating boundary | Private owned study scope; no normal-profile install; E06 |
| R20 | Licensing and commercial planning remain coherent | Separate existing licensing workstream | Model/data/renderer/plugin permissions tracked separately; P7 |
| R21 | Research current late-2026 methods | Cutoff is 5 October, not the end of 2026 | Dated primary-source ledger; distinguish preprints, revisions and reproduced results |
| R22 | No invented existing ML capabilities | Planning and operational records only | All new contracts/examples marked proposed; capability tests reject training claims |
| R23 | Learn from Houdini and Autodesk without importing unsupported assumptions | Selected vendor docs/source cross-check; no vendor runtime comparison | Keep native pipeline; qualify identity, geometry semantics and host contracts; E15/E17 |
| R24 | Resume batches without corrupting the review database | New companion contract is proposed | Full artifact manifests, complete-view joins and failure recovery; E16 |
| R25 | A deployed model uses the same data meaning as training | No model pipeline implemented | Version feature preparation and test export/provider parity; E18 |

The [second-pass report](16_SECOND_PASS_REPORT.md) updates acceptance for R08/R10/R13/R14/R16/R17/R18 as well: named identity lifetimes, static-surface binding limits, callback phase/lifecycle, host mode and semantic output checks. No new runtime capability is claimed by these documentation changes.

## Risk register

| Risk | Earliest signal | Mitigation / stop rule |
| --- | --- | --- |
| Render loop produces corrupted or costly batches | Repeated starts, no stable completion receipt | P0 prerequisite; bounded jobs and separate technical-failure status |
| Dataset shows wrong image/recipe pairing | Publication/hash mismatch | Immutable IDs, artifact checksums, fail review eligibility |
| Training memorizes one scene | Strong random split, weak project holdout | Group site/asset/recipe lineage and test new projects |
| Only favourites survive | Missing rejects and comparison context | Preserve explicit feedback states and rejected metadata |
| Studio averaging erases individual taste | Opposite preferences cancel without explanation | Separate personal and studio policies; report disagreement |
| Judge or search exploits a score | Model score improves while human quality falls | Frozen audit set, human promotion gate, search cap and rollback |
| Renderer/lighting dominates preference | Different fidelity or camera profiles per pair | Match comparisons; store rendering context; ablate planting-only cues |
| More source variety breaks reconstruction | Missing assets or changed membership | Enrolled versions, content hashes, stale checks and fallback |
| Framework replay repeats scene mutation | Lost response followed by duplicate apply | Persistent host operation ledger and exact idempotency |
| Logging causes the behaviour being measured | Rebuilds appear only while monitoring | Passive cached fields, rate limits and overhead experiment |
| Large models harm interactivity | GPU/CPU contention during navigation/render | Separate process, scheduling and measured memory admission |
| “Latest” dependency changes terms or semantics | Moving README/checkpoint differs | Pin exact release/revision and check terms at adoption |
| Capability text overstates implementation | Agent requests unsupported Brush/render operation | Registry/schema/runtime conformance tests |
| Batch budget resets after failure | Repeated retries continue beyond intended scope | Persistent attempted-work accounting, expiry and cancellation |

## Open choices to decide with the studio later

These do not block this research. They should be resolved before their corresponding implementation phase.

1. Which first design family matters most: courtyard, mixed border, meadow or another recurring studio task?
2. Who defines the studio profile, and when should personal preference override it?
3. Which reference images and asset renders may be retained, used for training or sent to an external provider?
4. What is an acceptable comparison-session length, and how much artist time can the pilot use?
5. Which cameras/render profile define the first benchmark, and how much reference matching versus design adaptation is desired?
6. Which Max/renderer/hardware combinations are the first supported research hosts?
7. What practical improvement would justify adoption: faster first acceptable result, fewer manual corrections, better blind preference, or a defined combination?

## Decisions already justified by current evidence

Keep deterministic procedural execution; do not run host APIs from inference workers; preserve existing old-plan semantics; add policy-3 mutation explicitly; collect negative/tie/skip states accurately; evaluate on new projects; keep model-generated judgments separate from artist labels; and qualify rendering before unattended batches.

The remaining architecture choices are hypotheses that the experiment register can change. “Ultimate” should mean a roadmap that can learn from evidence, not a commitment to build every fashionable component.
