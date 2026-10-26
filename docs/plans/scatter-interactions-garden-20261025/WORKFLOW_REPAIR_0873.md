# Interaction workflow and contact repair — 0.87.3

Status: implemented with scoped Max 2027 qualification, 26 October 2026. See the
[delivery](DELIVERY_WORKFLOW_0873.md) and [exact qualification](QUALIFICATION_WORKFLOW_0873.json)
for final identities, superseded failures and remaining acceptance.

The user requests a source-first workflow, automatic contact updates, one review
toggle and fixes for missing custom collider bindings and guide iteration failures.
The current user-selected 0.87.3 revision is retained. Prior packages and receipts
remain unchanged; the successor will have its own matched payload identity.

## Required artist behavior

- Choose a single layer role: Off, Collider, or React to colliders. Collider uses
  the existing closed source by default. Custom shape is an explicit assignment;
  cancelling a pick cannot commit an incomplete collider configuration.
- Analyze the selected original source once. Show guides at that source, then
  accept after review. Its scattered copies reuse the saved local definition.
  Review visibility is a toggle; no Apply interactions step is required.
- Setting changes update contacts on the last completed scatter. Pending Manual
  amount/seed/surface changes still wait for Update scatter. Browsing must not fit.
- Keep full visual trees separate from lightweight trunk/custom colliders.
- A solver fallback must keep root positions, finite geometry, complete collision
  checks, bounded work and atomic failure retention. More iterations alone are not
  a demonstrated fix. Do not silently hide a failed plant or publish intersections.

## Ownership and boundaries

F01, F04–F11 apply. Layer parameter blocks retain role, preparation settings and
source-row binding IDs; schema 61 parameter IDs remain unchanged. Review helpers
are transient host-owned objects, excluded from render and save, bounded by the
existing 4096-guide display cap. Review uses source frames, never instance poses.
Selecting another source or changing its relevant geometry/settings invalidates
review acceptance. Selecting/closing review does not invalidate static placement.

Native copied source definitions are shared across instances. Only nearby poses
are solved. Failed successors retain the previous complete publication. UI
callbacks capture their owner before any refresh; authored changes remain
Undoable. Source data, previous scene files and the artist's running Max profile
are preserved. Max 2027 testing uses a copied scene and a disposable profile.

## Acceptance

Reproduce missing proxy mode and a numerical contact failure from the supplied
New Plants scene; record exact scene and source/module identities. Exercise actual
generated role/preparation/review callbacks, cancellation and self-source picks,
multi-source readiness, independent Manual pending changes, preview 1/25/100%,
solver separation and root anchoring, moving the sphere with Cyrus Edit,
Undo/Redo, save/reopen, retained failures, and unchanged warm browsing. Independent
full mesh audits qualify only their exact tested inputs. Package the tested pair
as a Max 2027 MZP; no EXE, older-host tests or artist installation is implied.
