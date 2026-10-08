# Cyrus Scatter product discussion

Started 8 October 2026. This folder keeps the artist's reported issues, agreed behavior, proposed additions and useful references together as the discussion continues.

The current focus is to fix what Cyrus Scatter already has and decide how it should be presented. Forest's many options are useful references; they do not establish a requirement to reproduce every feature.

The artist subsequently authorized the **0.74 UI refinement implementation and Git push**. See [completed work and remaining acceptance](../UI_Refinements_0.74_2026-10-08/README.md), and [the models/painting recommendation](MODELS_AND_PAINTING.md). Source renaming is confirmed to change only the label inside Scatter.

## Working list

See [the discussion backlog](BACKLOG.md) for the current items and their status:

- Issue 1: receiving-surface selection and management.
- Issue 2: restore expanded and collapsed UI sections when the artist reselects Scatter.
- Issue 3: resize list height using a drag handle.
- Issue 4: fold inner settings groups independently of their main sections.
- Issue 5: simplify naming and decide the role and location of paint-set controls; the painting-only proposal is still under discussion.
- Issue 6: compact action icons with clear editable names and identification colors.

The Forest library manager and settings overview are reference observations awaiting further discussion.

## How we will work

- Continue recording the discussion while completing the authorized 0.74 refinements. The layer/set ownership decision remains open; normal-profile installation and broader feature work are not part of this pass.
- Record reported behavior separately from source-confirmed behavior, host-tested results and desired changes.
- Give each issue or idea a stable number. Update its description as the user clarifies it, retaining unresolved questions rather than inventing decisions.
- Keep confirmed changes separate from ideas and reference observations. A new idea does not automatically become an implementation task.
- When the conversation spreads into feature comparisons, return to the current workflow and ask what problem the feature would solve for the artist. Remind us of the focus without discarding the idea.
- Start future planning from this list, alongside the repository's current engineering handoff. These notes define product intent; they do not certify plugin behavior or supersede preservation rules.

## Current priority

Improve the existing UI workflow: make receiving surfaces easy to manage, retain the artist's expanded/collapsed sections, allow useful list heights, let related settings groups fold independently, and simplify naming and ownership presentation. Implementation order and additional priorities will be decided as the artist explains the current system and workflow.

## References

Screenshots supplied during this conversation are preserved under [references](references/). They illustrate current UI and desired interaction. Forest screenshots are comparison material, not Cyrus Scatter acceptance evidence.
