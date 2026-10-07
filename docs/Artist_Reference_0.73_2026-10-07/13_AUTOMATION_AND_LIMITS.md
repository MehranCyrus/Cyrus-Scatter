# 13. Automation and current limits

[Guide contents](README.md)

## What the assistant connection is for

The optional Cyrus Automation panel lets an assistant inspect an allowed scene scope and propose a limited planting setup for your review. It does not give the assistant unrestricted control of every Scatter button.

You can use Scatter, source containers, Brush, rendering and local diagnostic recording without opening this panel.

## Automation panel controls

| Control | Meaning |
| --- | --- |
| Inspect selected Cyrus scatter (read-only) | Shares inspection of the selected existing setup. This does not authorize changing it. |
| Use selected site | Assigns the selected supported ground as the design site. |
| Use selected assets (1–3) | Assigns up to three supported source models for the proposed planting. |
| Use selected planting splines (1–3) | Assigns the supported planting regions. |
| Use selected protected splines (optional) | Assigns areas the assistant-created planting must avoid. |
| Assigned-object labels | Shows what was chosen for each role. Selecting different objects in Max alone does not replace these assignments. |
| Allow this assistant to receive viewport images | Permits viewport captures to be sent to the connected assistant. Images can include other visible scene objects. It is separate from ordinary setting inspection. |
| Connect selected scope | Connects the selected design inputs after checking their supported limits. |
| Connected-scope information | Identifies the current shared site or read-only inspection. |
| Proposal dropdown | Selects a received proposal to inspect. |
| Proposal details | Displays the proposed settings for review; it is not a free-form editing box. |
| Approve displayed proposal | Approves that exact displayed proposal. A changed proposal needs its own approval. Approval and the assistant's subsequent apply action are separate steps. |
| Cancel pending proposal / revoke approval | Cancels waiting work or withdraws approval. It cannot interrupt every calculation already underway. |
| Undo last result / reject refinement | Requests reversal of the appropriate assistant-owned result. It should not undo unrelated artist work. |
| Disconnect scope and continue manually | Ends that connection scope so you can continue editing. It does not delete all planting. |
| Start recording / Stop / Save report... | Controls the same local diagnostic recorder described in the Scatter guide. MCP is not required just to record. |
| Share this recording with the connected assistant | Separately permits reading the current recording. It may include activity from other Scatter setups in the same Max session. Starting recording alone does not grant this permission. |
| Status | Reports connection, proposal and operation outcomes. A timeout is not confirmation that an operation succeeded or failed. |

Current assistant design work is deliberately small: up to three supported mesh assets, three regions/layers and 2,000 requested candidates in total. The design site must fit the supported simple static-ground workflow. Existing artist geometry stays outside the assistant's edit ownership.

The assistant can inspect settings and completed results and adjust its own supported planting proposal. It cannot currently author every paint set, freehand Brush stroke, source container, CS Edit operation or Analyzer arrangement. Rendering and arbitrary scene saving are also outside the public assistant actions.

## What is not complete yet

| Area | Current position |
| --- | --- |
| Complete AI scene design | There is no trained reference-image composition system that autonomously learns a professional artist's style and finishes scenes. Small offline experiments are research, not that feature. |
| Permanent debugging database | Local reports exist. An automatically searchable history of every action across sessions is not implemented. |
| Commercial licensing | The licensing foundation exists, but commercial activation, enforcement and recovery are not a finished release workflow. There is no complete licensing-control section to document in this Scatter UI. |
| Every-button qualification | Controls are documented here. That is different from testing every possible interaction, context, input and combination. |
| Container movement Undo | A first move lost Undo history in an earlier test. Controlled repeats passed, but that original case remains unresolved. |
| Extremely heavy viewport scenes | Mesh, points and guides still have drawing costs. Very large Proxy displays are a known expensive case. |
| All renderer and host combinations | The existing development evidence does not qualify all renderers, docking/DPI combinations, long sessions or Max 2026 runtime. |
| Example-scene materials | Some supplied grass/lavender materials had missing maps in the test environment. A successful Scatter render does not restore those maps. |

## Saving, updating and older scenes

Save the Max scene to preserve the setup's settings, source relationships, paint and supported edits. Use a separate test copy for experiments. Save/reopen is still part of the walkthrough for each feature combination, not something this documentation round reran.

Current 0.73 corrections keep the existing 0.73 setup format. Older unpublished Scatter/CS Edit formats were deliberately retired. Ordinary models can still be reused, but do not expect an automatic conversion of an old Scatter setup.

For the latest Add-layer correction, use the dated **Layer_Actions_Fix_0.73_2026-10-07** installer folder and restart Max after installation. Several builds say 0.73 in the UI; that caption alone does not identify the correction. This documentation round does not install anything.
