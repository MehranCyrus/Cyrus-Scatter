# 18 — Artist UI, commands, and automation

**Status: proposed Cyrus product design, not an inventory of current Cyrus UI. Research basis: R0 §§1, 7, 9, 11.**

## 1. The interface follows ownership

The user must know whether a value belongs to the setup, layer, source, area use, paint set, or selected instance. Show the owner in the panel header. A local override displays both its authored value and resolved effective value.

Proposed workspace:

```text
CYRUS SCATTER
[Setup selector] [Live / Gesture end / Manual] [Update] [Status]

Layers / shared inputs       Active layer properties
  Trees                      Sources | Distribution | Receivers
  Grass                      Areas | Paint | Variation | Constraints
  Flowers                    Edits | Appearance | Animation | Output
  Rocks

Bottom inspector: selected candidate / field value / rejection / timing
```

This is a textual layout specification, not a generated UI image.

## 2. Basic and advanced views

Basic view exposes receiver assignment, source selection, density/pattern size, coverage, random variation, spacing, and preview quality. Advanced sections expose coordinate domains, identity epochs, exact boundary modes, field composition, cache diagnostics, and renderer capabilities.

Advanced does not mean hidden behavior. Disabled controls explain why they are unavailable: “Requires surface-attached paint,” “Not qualified for this renderer,” or “This field is sampled before placement.”

## 3. Ordered area editor

Show execution numbers and an arrow indicating evaluation direction. Independent includes have visible contribution colors. An exclusion's inspector lists the earlier contributions it affects. Linked definitions show a link badge, with local falloff controls clearly separated.

Provide `Add include`, `Add exclude`, `Create union region`, and `Link existing definition` as distinct commands. Warn when overlapping independent includes may duplicate placements.

## 4. Painting workspace

Display paint mode, receiver scope, coordinate backend, radius, hardness, strength, resolution, and memory estimate. Brush overlay and plant display have separate toggles. An Updating badge shows that coverage is newer than the accepted population.

Erase paint and delete instances use different tools/icons. Convert-to-spline previews threshold and approximation. Resolution changes preview memory and possible boundary changes before committing.

## 5. Instance inspector

For an identified item, show origin contribution, generator address, source, receiver binding, resolved transform, active override/pin state, and relevant field values. For a rejected candidate, show its first rejection reason and blocker where appropriate.

This inspector is useful for artists and automated tests. It prevents debugging solely through screenshots.

## 6. One command surface

Commands use UUIDs and stable parameter IDs, not UI control positions. Proposed commands include:

```text
CreateSetup / AddLayer / SetParameter
AssignSources / AssignReceivers
InsertArea / ReorderArea / LinkDefinition
BeginPaintGesture / AppendDabs / EndPaintGesture / CancelGesture
ApplyInstanceEdits / PinItems / DeleteItems / RepairBindings
RequestEvaluation / CancelEvaluation / GetEvaluationStatus
ExplainCandidate / GetStatistics / ExportFixture
SavePreset / LoadPreset / ValidateAssets
```

These names describe the new contract; they are not claims about current Cyrus or MCP function names.

## 7. Command envelope

```json
{
  "command": "SetParameter",
  "command_id": "persistent-idempotency-key",
  "target_uuid": "layer-uuid",
  "expected_authoring_revision": 42,
  "parameter_id": "distribution.density_probability",
  "value": 0.65,
  "transaction_label": "Adjust flower density"
}
```

Validate type, units, range, target existence, version, and supported mode. A stale expected revision returns a conflict rather than overwriting newer edits. Commands can be batched into one authoring transaction.

Idempotency prevents an automation retry from creating duplicate layers or duplicate strokes. Destructive commands support dry-run summaries and explicit scoped authorization in the calling workflow.

## 8. Automation and MCP

An automation adapter discovers schemas, reads state, issues validated commands, and inspects results. It does not directly manipulate native buffers or execute arbitrary generated MAXScript by default.

Return structured status: accepted command revision, scheduled evaluation ID, current result revision, exactness, warnings, and typed errors. “Command accepted” does not mean “population finished.” A caller can explicitly wait through a supported synchronous operation or poll the actual job state; the user-facing assistant should not pretend work is running without such an operation.

Expose bulk operations for sources, parameters, and edits. Avoid millions of round trips to set individual transforms. Rate-limit expensive rebuild requests and coalesce compatible changes.

## 9. Documentation from schemas

Each parameter schema contains title, owner, type, units, default, range, enum values, activation conditions, stage dependencies, help text, and feature/test references. Generate the reference UI and documentation from this source of truth where practical.

Chapter 22 provides the initial proposed control inventory. It is not a substitute for preserving existing serialized parameter IDs during migration.

## 10. Diagnostic language

Use messages that say what happened and what remains valid:

- “Coverage saved; population updating.”
- “12 edits inactive because their receiver topology changed.”
- “Renderer adapter lacks per-element masking; final render blocked for this layer.”
- “Collision update expanded to the full layer to preserve the exact result.”

Do not silently downgrade a feature or present a stale count as current.

## 11. Workflow tests

An artist creates a garden without opening Advanced settings, moves a path, paints a bed, pins a tree, and renders. An expert inspects exactly which field rejected a candidate. An automation client performs the same edits through commands. All routes must produce the same authoring state and Undo semantics.
