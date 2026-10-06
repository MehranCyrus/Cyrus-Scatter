# MCP expansion and agent guidance contract

**Status: proposed work after the current documentation pass.** This does not register tools, modify schemas 1/2 or grant broader scene authority. [Coverage](CAPABILITY_MATRIX.md) is the current-state reference.

## What “understand the whole plugin” should mean

MCP supplies structured context and operations; it is not a learned understanding model. An AI client should be able to discover every supported feature family, explain its purpose and ownership, distinguish native availability from remote authority, propose valid changes, inspect actual outcomes and recover from failure without guessing.

Completeness means every family has a declared support state, not a separate tool for every spinner or permission to call arbitrary MAXScript. Some native features should remain explicitly unavailable until their transaction and runtime behavior are qualified.

## Capability and documentation layer first

Extend the existing settings/capability registry with versioned feature metadata. Keep one authoritative definition per field and validate the adapters against it; do not copy limits into independent UI, schema and help implementations. Native features outside the current registry need reviewed metadata and a conformance check, not an automatic assertion that every exposed property is safe to set.

Each feature card should carry:

- Stable feature ID, purpose, artist UI location and concise examples.
- Owner: controller, logical layer, paint set, source entry, rule pair or published instance.
- Declared default, inheritance, effective value and override semantics, including the meaning of omission, reset and null.
- Type, units, bounds, enum choices and supported combinations/policies/hosts/source types.
- `native_available`, `read_supported`, `write_supported`, qualification level and unavailable reason.
- Input dependencies, expected invalidation scope, Manual/Live behavior and work/memory limits.
- Preconditions, authority/ownership requirements, Undo/persistence and cancellation behavior.
- Result fields that demonstrate success, expected errors and supported recovery.
- Contract version, compatible build range and tests/receipts supporting the claim.

Also declare qualified `host_mode` and renderer combinations, identity lifetime across named edits, container membership metric, Brush distance/visibility rules, and whether source “clusters” only change asset assignment. These are contract requirements from the [vendor recheck](VENDOR_RECHECK.md), not new capabilities in today's server.

The proposed catalog must include disabled and unavailable features with explanations. For example, source containers are native and their configured references are readable now; policy-3 container authoring is not a supported plan operation. The agent must not substitute receiving geometry for a source rectangle, or assume `show_radius` changes collision size.

The [official MCP resources specification](https://modelcontextprotocol.io/specification/2026-07-28/server/resources) describes URI-addressed contextual resources. Use that facility for feature cards, workflow guides and schemas; use tools for operations and scoped live queries. The proposed Cyrus resource names and contents below are not currently served.

| Proposed resource family | Contents |
| --- | --- |
| Feature catalog and individual feature | Support matrix, ownership, units, restrictions, current artifact version |
| Workflows | Create a meadow, preserve a path, explain underfill, park/restore a source, compare spacing scopes, investigate a stale result |
| Error/reason reference | Recoverable versus blocked states, expected stale-reference handling, diagnostic record links |
| Versioned procedural plan/publication schemas | Exact payloads and backward compatibility, once implemented |

Guides should be short, task-oriented and capability-gated. They must not tell an agent to use future tools against today's server. Scene labels, reference captions and retrieved files are task data and cannot grant new actions.

## Proposed operation families

The names are illustrative design labels, not finalized RPC names. Preserve the nine-tool baseline and qualify independently staged additions before advertising broader support. The concurrent 1.2.0 `scatter_read_diagnostic_events` registration is recorded in [coverage](CAPABILITY_MATRIX.md); a tool registration alone does not complete the diagnostic operation family below.

| Family | First useful scope | What must be demonstrated |
| --- | --- | --- |
| Feature discovery/help | Read current feature cards, supported workflows and reason codes | Descriptions agree with validators, native policy and loaded version |
| Context/publication snapshot | Read cached recipe, pending state, source registration/membership and completed epoch | Zero solve, reconciliation side effect or unchanged-buffer upload |
| Procedural validate/explain | Normalize a versioned policy-3 plan or patch against an immutable base | Complete owner defaults, units, dependencies, errors and bounded work; no mutation |
| Procedural apply/status | Apply the exact approved complete policy-3 transaction | Stable identities, fresh scope/revision, rollback, idempotency and actual publication receipt |
| Source/coverage authoring | Enrolled pools and target-bound Brush/Area documents through typed data | Source parking, target binding, bounded history, Undo/reopen and protected edits |
| Publication export | Recipe plus actual transforms/sources/radii/statistics for one epoch | Digest/count parity, stable artifact lifetime, explicit incomplete/expired response |
| Diagnostic session/summary | Start/stop a bounded trace, inspect health and export chosen scope | Passive observation, quotas, redaction, safe failure and no arbitrary path access |
| Render job | Enrolled camera/profile and owned destination artifact | Actual completed render, failed/aborted/unknown states; no stale image presented as current |
| Design study | Small explicit private batch, job status and cancellation | Persistent attempt/render/storage/time budgets and recovery after interruption |

A typed patch must name its exact base revision and normalize to a complete effective plan before approval. It must not be a free-form property setter. Initial policy-3 authoring can ship with fixed enrolled sources/receivers before remote Brush and renderer work; advertise that narrower capability honestly.

## Procedural plan semantics

Plans must express controller policy, receiver references, stable logical layer/set identities and explicit order; shared layer population/defaults; weighted set allocation; source registrations and pool binding; coverage/Area references; transforms/radii; the three rule scopes; layer cleanup; bounded refill; enabled versus viewport-visible state; and Manual/Live intent.

New, preserve, copy, remove, reset and inherit are explicit operations. A missing field cannot ambiguously mean “keep current,” “default,” and “disable.” Copying/removing owners remaps or rejects dependent references. Background references must obey the currently implemented earlier-sibling/domain restrictions. Point/Empty and protected-instance count semantics remain explicit. Preserve source salts and registration when parking; do not convert policy or silently clear Edit history to make a request pass.

Lengths cross the adapter in metres and convert once; angles use degrees; ratios remain unitless. API opaque enrollment IDs, native persistent ownership IDs, session handles and generation-scoped export IDs need separate fields. Do not match an old row index to a new instance. Unit/topology changes and unresolved Edit/radius bindings return structured errors with supported recovery.

M02/M04 must publish and test an identity-survival table for rename, rejection compaction, park/reenter, reorder, delete/recreate, clone/merge and reopen. Source palette translation is membership input, not automatically an instance transform. Preserve current rectangle-local XY pivot membership, height-insensitivity and per-owner source settings unless a separately designed operation changes those semantics. Geometry scale, source radius and effective spacing radius need separate fields and independent expected-transform fixtures. See [V02/V03](VENDOR_RECHECK.md#acceptance-additions-to-the-existing-queue).

## Transaction and observation lifecycle

1. Read server/build capabilities and enroll a supported scope through the existing local authority path.
2. Capture an immutable context revision and the last published result separately from pending authored inputs.
3. Validate the proposal, normalize all effective values and show effects, unsupported requests and work limits. Accepted counts requiring evaluation are not dry-run facts.
4. Bind approval to the exact digest, scope, revision and operation. Existing schemas retain their local approval behavior. Future batch approval must explicitly describe its bounded range of operations.
5. Persist admission/idempotency before scene mutation; dispatch host reads/writes on the host thread.
6. Attach all owners/settings/rules in one supported transaction, evaluate through the same native pipeline as UI work and stage all required outputs.
7. Publish one epoch or retain the prior complete result on failure. Return actual counts, digests, warnings and any shortfall policy outcome.
8. Capture/export only artifacts that identify that publication and camera/context. Inspect outcome before asking for another candidate.

Cancellation requested is not cancellation completed. Native synchronous work may finish before a cancellation boundary. A timeout, disconnect or crashed client must not trigger a new-key duplicate apply. Reconcile the existing operation/publication first. Failed rollback blocks further mutation until recovery; a logger failure must not corrupt the transaction.

Preserve the existing explicit primary-error capture and verified rollback in `max_host.py`. In a `pymxs.undo()` context, an exception can be handled internally; returning without an outer exception is not proof of success. Inject setter failures and verify scene/registry/publication state, not only returned status. Adapter tests also need empty/first/last array cases and correct wrapped-object equality. [Autodesk pymxs module](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Python/files/using_pymxs/MAXDEV_Python_using_pymxs_pymxs_module_html.html), [pymxs indexing and equality](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-Python/files/MAXDEV_Python_using_pymxs_html.html).

The [official tools specification](https://modelcontextprotocol.io/specification/2026-07-28/server/tools) supports input/output schemas and structured results, and separates tool execution errors from protocol errors. Its annotations do not replace Cyrus authorization. The tool contract should expose actionable failure data while the adapter enforces authority and validates inputs. The installed `mcp==2.3.0` package/version is not proof of conformance with every newer protocol feature; protocol migration needs a separate client/server compatibility test.

## Current-publication export before learning

Current policy-3 configuration contains settings and last-published counters, not a complete immutable recipe/result dataset. A new export needs the exact evaluated recipe, effective values, source/receiver/pool membership snapshot, publication ID, actual transforms/source IDs/radii, eligible/rejected/accepted/shortfall statistics, protected conflicts, units, build identity and transform digest.

If pending inputs differ, export the publication's recipe and label the newer pending recipe separately. Do not pair new settings with old transforms. Bound arrays and artifacts; page or stream only with stable publication lifetime, digest and ownership checks. Expiry, eviction and partial export are explicit states. Define cross-generation correspondence before using local instance IDs as learning labels.

### Render jobs and artifact acceptance

Declare the required camera/view set before admission and account for candidate × view × attempt expansion. Admission includes source/Brush/staging memory and output storage, not just candidate count. A job must identify its host mode; interactive-worker evidence cannot advertise Max Batch support. Batch must explicitly evaluate, publish, render and finalize under its qualified lifecycle, without an untested dependence on UI timers.

Completion requires every required artifact to exist, decode, match dimensions/format/hash, and name the expected candidate, publication, source/asset context, camera/profile and attempt. Persist manifest completion only after artifact verification. Reject stale late output, missing views and mismatched cached files on restart. Valid empty/underfilled scenes are distinguishable from missing output. Technical completion makes a candidate eligible for review; artist approval and training eligibility remain separate. Reuse [E16/E17](../AI_Design_Learning_Research_2026-10-05/11_EXPERIMENTS.md#e16--artifact-integrity-and-complete-view-joins) for these failure cases.

## AI reference/design loop, later

The future companion can interpret references into editable intent: asset roles, planting masses, focal/open-space relationships, paths, palette and camera composition. It should expose confidence and unknown scale/occlusion, map intent to supported recipes, then use MCP validation and the native evaluator. It cannot recover a uniquely correct 3D scene from every photograph.

Use geometric feasibility and output checks before visual comparison. Lock or explicitly version camera, lighting, assets, materials and render fidelity for a comparison; otherwise aesthetic changes may be due to rendering rather than planting. Failed/partial renders are technical failures, not negative artistic preferences. An AI's own rating is a hypothesis to compare with artist choices, not ground truth.

Keep inference/search outside Max. Start with curated recipes and explicit profile preferences, then collect meaningful comparisons and test retrieval or a small ranker on held-out projects. No present MCP export grants training consent. Detailed future experiments remain in [AI research](../AI_Design_Learning_Research_2026-10-05/README.md) and [artist-style planning](../Artist_Style_ML_2026-10-04/README.md).

Version the whole feature pipeline: source schema, units/order, vocabularies, missing-value policy, image colour/orientation, camera order, fitted preprocessing and inference backend where relevant. Fit preprocessing using training data only. Test golden training/inference records before model promotion. Artist ranking, technical cost/outcome prediction and inverse recipe initialization have different targets; successful technical measurements supply no aesthetic labels. See [E18](../AI_Design_Learning_Research_2026-10-05/11_EXPERIMENTS.md#e18--feature-and-inference-parity).

## Agent conformance benchmark

Evaluate the final scene/receipt as well as the tool sequence. Cases must include: explain underfill; inspect without regeneration; reject unsupported Brush mutation on today's server; distinguish a source rectangle from a receiver; preserve an exclusion path; choose the correct spacing scope; honor Manual pending state; handle missing sources; reject stale approval; recover exact retries after timeout; stop at budget/cancellation; export one consistent generation; and acknowledge absent training capability.

Score correct scope/units/settings, final geometry constraints and identity parity, unnecessary calls/updates, useful error recovery and honest unsupported reporting. Include misleading scene labels/reference text to verify they do not change authority. Re-run against supported MCP clients after schema/protocol changes. Do not grant generic code execution to make a benchmark pass.
