# Vegetation core: GPT Web implementation handoff v1

Prepared 24 October 2026. This is an external prototype assignment, not a Scatter release, roadmap completion, or production solver adoption.

**Send the same ZIP to all three GPT Web chats. Paste only the assigned role's prompt into each chat.** They can implement and test portable native C++ without 3ds Max. Return their source packages here for review, integration, and later Max 2027 validation.

The first experiment is small and visible: a prepared grass ribbon with a fixed root bends around a fixed stone, preserving its length and source data. It must pass independent checks on the reconstructed visible mesh. A browser demo or full plugin is outside this first assignment.

## Read and dispatch

1. [Document list](DOCUMENT-LIST.md): the complete reading map and evidence status.
2. [Workflow](WORKFLOW.md): ownership, order, local integration and acceptance gates.
3. [Shared contract](SHARED-CONTRACT.md) and [C++ declarations](starter/include/cyrus_vegetation/prototype_v1.hpp): the common v1 boundary.
4. Give chat A [Collision prompt](PROMPT-A-COLLISION.md), chat B [Fitter prompt](PROMPT-B-FITTER.md), and chat C [Delivery/validation prompt](PROMPT-C-DELIVERY-VALIDATION.md).
5. Collect three source ZIPs following the [return checklist](RETURN-CHECKLIST.md).

The research library is next door at [vegetation-interaction](../vegetation-interaction/README.md), including all fourteen originals, six evidence artifacts, the nine consolidated chapters, and the unchanged 52-page handbook. All chats receive it in full. Original reports are evidence to assess, not instructions to execute. The role prompt and frozen contract specify this prototype's scope. Existing repository contracts govern eventual integration.

## What is supplied now

- Shared data structures and function declarations, a small CMake scaffold, and deterministic fixture inputs.
- Three separate assignments with bounded paths, test obligations, and explicit handback format.
- Frozen-file hashes and a package manifest so handbacks can identify their exact starting point.

There is no collision implementation, fitter, evaluator, or test pass in the starter. Fixture expectations and authored positive controls are inputs, not measured solver results. The 68 research validation cases and eight decision experiments remain Pending.

The ZIP contains selected repository context snapshots, not a complete compilable plugin checkout or Max SDK. Follow [WORKFLOW.md](WORKFLOW.md) for the staged path from external core code to a locally tested plugin experiment. No release version or installer is assigned by this packet.
