# Cyrus Arrange 0.2.0 workflow simplification

Status: qualified for the documented Max 2027 workflow; see the exact runtime and installer evidence in RELEASE_VALIDATION_0.2.0.md.

The artist's first trial required a long explanation to select a hidden setup,
manage seeds and distinguish Apply, Generate, Reroll, Analyze and Preview. The
main window must make arranging furniture the immediate activity.

## Delivery decision

Use independent Arrange version **0.2.0** for the substantial visible workflow
change. Preserve all 0.1.3 installers, receipts and example originals. Keep native
document schema 4 and the existing solver, class IDs, scene ownership and five
installed scripts. The old detailed controls remain available as Advanced;
they are not a second placement engine.

## Main workflow and ownership

- Opening the window discovers saved arrangements. Selecting bound furniture,
  its geometry or generated output resolves the real native owner automatically.
  Multiple matches require the artist to choose an arrangement. Names and user
  properties do not establish ownership. Discovery never analyzes or generates.
- For new furniture, the artist chooses its type and presses Use selected furniture.
  Generation already analyzes the current furniture, so no separate Analyze step
  is required in the main workflow.
- A compact Props window lists registered assets and adds one selected model or
  group with its explicit category and real scale. Detailed per-asset controls
  remain available from that window.
- Main controls are arrangement, furniture type, Amount, Spacing, Generate and
  Keep seed. Amount presents the native density as a percentage without changing
  its definition. More room/edge/rotation/surface/preview controls are Advanced.
- Generate uses a native staged command. By default it chooses a new nonnegative
  63-bit seed different from the supplied seed. Keep seed repeats the supplied
  seed. Last-used seed is the existing saved arrangement setting; Keep seed is
  a window/session preference, defaults off and is not a new scene field.
- Failed generation preserves the old authored settings, seed, output and
  revision. One Undo restores settings and output together. Live, Preview and
  Commit do not invent new seeds. Passive UI opening and selection do no solve.
- Advanced remains a view of the same setup. Explicit Refresh reads settings
  changed there. The simple view generates all eligible regions; selective
  regeneration remains explicit in Advanced.

## Acceptance

Exercise the actual main-window handlers in a fresh Max 2027 private profile:
automatic binding from owners/furniture/outputs, ambiguous/shared furniture,
unrelated and spoofed-name selection, scene switching, empty library guidance,
explicit new setup, positive new seeds, Keep seed repeat, atomic failure,
Undo/Redo, locks, save/reopen and preserved scene sources. Re-run the existing
native and functional suites against the exact new pair. Qualify the actual MZP
and automatic installed startup in disposable profiles. Preserve artist sessions.

The three supplied YouTube references are research inputs. Record actual access,
transcript and visual coverage separately from creator documentation; do not
describe metadata or a few sampled frames as watching an entire video.
