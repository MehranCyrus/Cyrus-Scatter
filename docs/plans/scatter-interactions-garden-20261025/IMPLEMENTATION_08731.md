# Complete stem contact and automatic preparation — 0.87.3.1

26 October 2026. User-selected four-part patch label;
Max 2027 only. Supersedes the source workflow's projection-based root exclusion.
Previous receipts remain historical. F01/F04–F11 apply.

The user subsequently requested code/package only and will perform testing. The
initial test-enabled build was cancelled before native tests ran. A fresh producer
uses `--build-only`; no Max host is launched for this delivery. Current runtime,
Undo/Redo, visual correctness and performance acceptance remain unverified. A
generator consistency check completed before this steering, on an intermediate
script hash; it does not qualify the final script. See the delivery for exact bytes.

The primary defect is the root-footprint classification in `fitSource`: a root
under an overhead solid is excluded from solving even when hiding is off. Replace
it with signed contact of actual fixed root points/anchors. All other contacting
guides enter the fitter; no fraction is omitted. Hiding is optional and only applies
to roots in the solid or its Contact gap boundary. Actual fixed-root conflicts with
hiding disabled fail explicitly and retain the previous complete publication.

Use a single Prepare model command to capture, validate and store source-local
guides. Native preparation remains shared per unique geometry/settings definition.
Stage all changed definitions before an Undoable parameter-block commit. Preserve
previous definitions on failed analysis; geometry/publication failure keeps the
previous complete result. Source/settings changes must not consume Manual pending
scatter placement edits. Guide visibility is optional inspection, not an approval
gate. Preparation-affecting UI edits automatically refresh previously prepared
sources; unprepared new sources still require Prepare. Contact/display edits reuse
accepted definitions. No repeated analysis on idle or browsing.

Keep source geometry and all Max API access on the host thread. Native work uses
owned copied inputs; no asynchronous scene references. Source admission, native
fit work, memory bounds and explicit error reporting remain. All contacting stems
participate within admitted work; resource exhaustion must never silently drop
stems or publish an incomplete result. Root checks use bounded source anchors and
nearby collider bounds. No instance-sized guide duplication or new persistent
schema is required. Parameter block schema 61 remains; native capability becomes
6 so stale script/native combinations are rejected.

Remove Interactions hover tooltips, including generator-added Advanced/list help,
while retaining visible status text. Replace Analyze/Accept with Prepare model.
Setting edits and resulting definition changes belong to one Undo action. Test
actual generated callbacks, Undo/Redo, failure retention, Manual pending edits and
save/reopen, in owned Max 2027 profiles with matched payloads.

Acceptance: overhead-contact roots remain visible and react with hiding on or off;
inside roots hide only when requested; Gap expands exclusion only when hiding is
enabled; moving away restores original geometry; full visible-mesh audits and root
anchoring pass on the supplied grass. Compare all contacting guide identities,
not just bent-plant counts. Record numerical/host timings separately from FPS.
Deliver a matched Max 2027 MZP and saved trial. Artist source scenes/profiles,
unrelated products, Git publication and website deployment remain outside scope.
