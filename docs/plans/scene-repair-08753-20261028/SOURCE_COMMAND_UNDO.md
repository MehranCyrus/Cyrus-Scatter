# Bounded source-command Undo

Implementation notes for 0.87.5.3. The [delivery](DELIVERY_08753.md) and
[exact qualification](QUALIFICATION_08753.json) record the scoped Max 2027 pass.

## Cause and ownership

The replacement command changed scripted parameter-block arrays inside `undo on`, but did not explicitly register an authored restore object. Autodesk documents that scripted parameter-block values do not automatically participate in Max Undo. A named script context alone therefore does not prove that a source command was recorded. See [Scripted Plug-in Clauses, Parameters](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Plug-ins/GUID-461915FA-31A2-49CE-84AF-2544B782ACA3.html).

`source_authoring_undo.cpp` uses the repository's existing `RestoreObj` and `ValueHolderMember` ownership pattern. It captures only explicitly allowed authored fields. It does not retain another copy of the scene's geometry, placements, guides, or published render buffers.

## Protocol

The script helpers `sourceCommandBegin label scope`, `sourceCommandCommit context`, and `sourceCommandCancel context` own the command boundary. They join an existing hold or create and finish their own; they preserve the previous `CyrusPointSuspended` state. The native protocol is:

- `cyrusSourceCommandBegin owner scope` captures the previous state, registers a restore object, and returns an opaque rooted ticket.
- `cyrusSourceCommandSeal ticket` captures the completed state before the command commits.
- `cyrusSourceCommandCancel ticket` restores the previous authored state and marks the record cancelled.
- `cyrusSourceCommandUndoVersion()` returns `1` for this protocol.

Scopes are fixed in native code. Scope 1 covers source membership, source settings, source correspondence slots, radius/clearance ownership, prepared definitions, and custom proxy bindings. Scope 2 covers source scale and Z offset. Scope 3 covers only `viewportNavigationFaces`.

Both source-list views use the shared add/remove/replace/Point/Empty methods. Replacing a model preserves its source-row ID and removes only that ID's prepared definition and custom proxy. Undo restores those exact saved definitions and bindings. Point creation is one command rather than nested overlapping Empty/Point snapshots.

## Bounds and lifetime

Each captured field admits at most 1,024 rows. A record admits 4,096 node references across its snapshots and 256 MiB of charged authored payload. These are journal admission bounds, not a claim about total process memory. Existing PB data and the native publication coexist with the journal. Max's Undo history controls the lifetime of committed records.

Arrays and node wrappers are rooted with `ValueHolderMember`. Private immutable strings are interned within a record, so unchanged rig strings share a single journal copy across the previous and completed snapshots. No rig is parsed for Undo. Capturing reference wrappers suspends derived Undo recording; restoring values also suspends derived recording. Only fields which changed are reapplied during Undo/Redo.

Body or sealing failures restore the saved authored state before an owned hold is cancelled, restore the prior publication-suspension flag, and propagate the failure. The existing scene Undo/Redo callback handles UI refresh and the applicable Live/Manual publication policy. No global Undo behavior is rewritten.

## Guarded static boundary

This journal handles static authored source settings. A captured parameter controller whose `NumKeys()` is nonzero is rejected before source changes, with the field name in the message. The original controller and values remain intact. Arbitrary animated-controller editing and its full Undo history are not qualified by this implementation.

Source-node transform animation is outside the whitelist and remains on its independent existing dependency route. The journal does not sample, replace, or clone node transform controllers.

## Host acceptance

Use the owned Max 2027 copy of the artist scene and the exact matched script/native pair. Check one-step Undo/Redo after a real UI command, outside any Python or picker hold. Verify source IDs, source handles, preparation hashes, proxy handles, unrelated bindings, and both displayed source lists. Check removal, replacement, adding models, Empty/Point rows, source scale/Z offset, rollback, and the guarded animated-setting rejection. Keep scripted harness hold-state observations separate from actual GUI Undo evidence.

The bounded test runner `tools/procedural_lab/interactions08753/run_journal.py` dispatches `journal_native.ms` through the owned transport. Its Python process runs outside Max. The native script preserves history and records raw hold state; it neither clears history nor accepts unexpected holds. Each source action, deferred record, standalone Undo, read-only check, standalone Redo, and read-only check occupies a separate host callback. The source snapshot is limited to 16 fixture rows and includes canonical IDs, node handles, preparation SHA-256 hashes, proxy references, source settings, and navigation allowance. UI checks read both source views without rebinding them.

Prepare the already loaded small role-Off replacement fixture with at least one prepared source/proxy, valid `AuditStone`, and bound Models/Interactions pages. The runner creates one owned instanced stone candidate and sets the test navigation baseline to zero in its preparation phase. Actions cover model/Empty/Point enrollment, removal of a prepared source/proxy, model scale/Z offset, Fast navigation, owned-command failure rollback, and caller-owned cancellation. Historical `journal_host.py` receipts remain Python-bridge diagnostics and are not promoted to native host qualification.

Final package host-11 passes actual GUI picker replacement with Ctrl-Z/Ctrl-Y and all seven native command cases, rollback and caller cancellation. Snapshots verify exact IDs, handles, preparation hashes, proxy references and both UI views. No history clearing or unexpected-hold acceptance is used. The keyed-controller guard remains source-inspected and unqualified in this Max campaign. The final trial save/reload is repeated outside the Python bridge in host-12 with clean raw hold gates.
