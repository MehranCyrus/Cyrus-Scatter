# 12 — Security, privacy and studio constraints

**Status: PROPOSED architecture and qualification requirements. No new enforcement or telemetry exists yet.**

## Authority boundaries

The artist enrolls specific scene objects, regions, sources, view and allowed operations. The local API enforces that scope on every request. A model's plan, explanation, confidence or tool annotation cannot enlarge it.

Untrusted input includes scene/asset names, custom metadata, reference-image text, retrieved recipes and model output. Treat those as data, never instructions that can change the tool policy or cause shell/script execution.

## Threat and control matrix

| Risk | Proposed control | Required test |
| --- | --- | --- |
| Destructive edits or lost manual work | New owned controller in MVP; explicit scope, locks, revision checks and undo/recovery | Interleaved artist edits, stale plan, deleted owner and reject/undo |
| Arbitrary MAXScript/native execution | No eval, code-string, raw property or opcode endpoint | Script payloads in names, IDs, text fields and unknown fields rejected/inert |
| Filesystem/shell access | No generic file/shell tools; managed artifact IDs and fixed storage policy | Traversal, UNC paths, URL handlers and malicious filenames |
| Malicious asset metadata/prompt injection | Minimized context, quoted data fields, strict schemas and server policy | “Ignore policy” text in scene names, thumbnails and retrieved recipes |
| Proprietary asset/project leakage | Local geometry; allowlisted summaries/images; upload preview and studio controls | Unapproved paths/objects/hidden metadata never exported |
| Runaway loops/object creation | Call/iteration/count/byte/time admission limits and one scene mutation at a time | Repeated apply, huge/negative/NaN counts, deeply nested payloads |
| Memory exhaustion | Geometry/image/output caps before allocation; staged work and resource diagnostics | Oversized mesh/map, decompression bomb and recursive metadata |
| Render spam | No MVP render endpoint; later named preset, separate budget and renderer qualification | Duplicate start, abort, queue exhaustion and farm context |
| Scene corruption/partial publication | Transaction snapshots, complete generation publication, failure recovery | Fault injection at each mutation/publication stage |
| Duplicate request after disconnect | Request digest/idempotency ledger and outcome reconciliation | Disconnect before/after commit; helper restart |
| Local adapter hijacking | Same-user/process IPC permissions, pairing secret, session scope and least privilege | Wrong user/process, expired pairing, nonce replay |
| Cross-studio data/model leakage | Isolated libraries, dataset rights and scoped model artifacts | Unauthorized retrieval and split/model publication checks |
| Supply-chain/model risks | Pinned signed/hashed packages, reviewed runtime/checkpoint license and rollback | Tampered checkpoint/package, unexpected download or executable content |

Sandboxing a helper limits its access; it does not make Max or loaded third-party plugins a complete sandbox. Use disposable fixtures for destructive/fault tests.

## Data movement modes

1. **Local-only:** scene, references, records, recipes and any qualified local inference stay on the workstation or approved studio infrastructure.
2. **Cloud reasoning with summaries:** send only artist-approved text/structured summaries. If no image is allowed, do not claim reference-image analysis occurred.
3. **Cloud reasoning with images:** upload explicitly approved reference and viewport crops plus bounded context. Show the actual payload categories.
4. **Hybrid:** local segmentation/retrieval/geometry, approved compact summaries or images to reasoning provider. A mask/embedding is still potentially sensitive project data.

Do not assume a cloud model can access a local MCP server. The proposed local orchestrator owns outbound model calls and local execution. An internet-facing adapter is a separate architecture and security decision.

## Provider data controls

**Primary-source fact, retrieved 2026-09-30:** OpenAI's [API data guidance](https://developers.openai.com/api/docs/guides/your-data) states that API content is not used for training by default unless opted in, but retention and endpoint/application-state controls are separate; approved zero-retention options have eligibility and feature limitations.

**PROPOSED:** evaluate the exact provider, model, endpoint, storage setting, caching, region and contract for the chosen pilot. “Not used for training” does not mean “nothing is retained.” Do not promise zero retention or studio compliance based solely on a model name. Other providers require their own review.

No vendor is selected in this package. Pricing, availability and legal terms must be rechecked at implementation/procurement time.

## Permissions and consent

Keep these independent:

- Local mutation authority for the selected scene scope.
- Upload of text/summaries.
- Upload of reference/viewport imagery.
- Local operational diagnostics.
- Research dataset inclusion.
- Per-studio model/profile training.
- Global product training.

The artist must be able to use ordinary Cyrus without consenting to research/training. Licensing activation should not carry scene content. Follow the existing [licensing privacy plan](../CyrusScatter_Licensing_Implementation_Package_2026-09-27/26_Privacy_Legal_and_Data_Minimization.md), keeping future AI policy separate.

Credentials belong in an appropriate OS credential store or studio-managed secret mechanism, outside scene files, MAXScript, model prompts and logs. Approval receipts and provider secrets are never reusable text returned to the model.

## Local artifacts and retention

Use a fixed, access-controlled artifact store. Exports are bounded by bytes/count/time and contain a manifest. Strip unneeded metadata from images; capture the viewport, not the desktop or other applications.

Retention/deletion must cover local records, uploads, retrieval indexes, derived features, dataset snapshots and models where applicable. Embeddings and salted IDs do not guarantee anonymity. Record limitations of deleting already-trained contributions.

## Studio deployment policy

**PROPOSED:** studio administrators can disable AI entirely, disallow uploads, restrict providers, enforce local-only mode and define recipe/data sharing. Ordinary scene load, save and rendering must not trigger model calls or training.

Render workers/farm machines should consume normal qualified Cyrus scene output without needing an AI session or AI GPU. This is a future design requirement, not proof that current renderer/farm/licensing support is qualified. Resolve it under the existing renderer and licensing plans.

**UNKNOWN:** which intended studios permit any cloud processing, which asset licenses allow training use and which geographic/provider constraints apply. These are pilot enrollment questions, not reasons to guess permissions.

