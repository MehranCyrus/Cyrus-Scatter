# 14 — Product UX and artist workflow

**Status: PROPOSED design. No UI has been implemented.**

## Main workflow

**Select site → choose sources → add reference → confirm intent/regions → review plan → generate → compare → refine once → accept → continue manually.**

Use a compact assistant panel integrated with the existing workflow. The ordinary plugin remains usable throughout. Do not require artists to understand MCP, tokens, JSON, model checkpoints or array indices.

## Before generation

1. **Site:** show the selected surface and eligibility. If unsupported, explain the concrete condition and offer a manual/simplified-site route.
2. **Sources:** show approved thumbnails, dimensions and roles. Flag an unknown footprint or unsupported asset rather than silently choosing something else.
3. **Reference:** label it as inspiration or calibrated layout reference. Show whether it will leave the machine.
4. **Intent:** summarize proposed tree/shrub/ground roles and open space in ordinary language.
5. **Regions:** highlight confirmed planting/locked regions in the viewport. “Left” becomes a visible region, not a hidden guess.
6. **Plan:** show affected objects, layer roles, expected count/ranges, allowed changes, assumptions and any hard validation failure.

The first prototype can use artist-authored regions. Automated zoning is a later feature, not a prerequisite for evaluating reference-informed parameter choice.

## Controls and honest semantics

| Control | Artist-facing meaning | Initial availability |
| --- | --- | --- |
| Assist | Review proposal before scene changes | Default |
| Automatic refinement | Allow one small revision within displayed limits | Optional explicit envelope |
| Autonomous | Larger bounded run on approved scope | Deferred |
| Conservative / creative | Amount of allowed variation from the brief/recipe | Proposed soft preference; never changes hard constraints |
| Preserve current layout | Protect existing manual/owned state | MVP protects existing controllers by scope exclusion |
| Locked areas | No candidate footprint may enter these regions | Required |
| Maximum change | Cap affected layers/regions/count or allowed parameter delta | Required for refinement |
| Style strength | How strongly the reference influences soft composition goals | Later calibrated UX; not a fake exact match percentage |
| Density target | Population or coverage intention with units explained | Count in first tool subset; density after qualification |
| Allowed source list | Only these enrolled assets may be used | Required |
| Iterations | Maximum candidates, including initial generation | Two in prototype |
| Regenerate selected zone | Change only this region, preserving others | Deferred until partial-regeneration identity is qualified |

Do not show a control as functioning before its API contract exists. A future feature can be described in the roadmap without appearing as an enabled product option.

## Comparison screen

Show candidate A and B from the same camera/display mode with:

- Layer and source summaries.
- Actual requested/emitted/displayed counts and cap/stale warnings.
- What changed and why.
- Hard-constraint results.
- Approximate wait/cost information only when measured.
- Accept, Reject Refinement, Undo and Continue Manually.

A points/proxy preview is labelled as such. It can help judge distribution but cannot establish final leaf/material appearance. Renderer previews are a later separately qualified workflow.

Avoid a single “AI quality 94%” score. Show concrete observations and uncertainty: “The reference suggests a dense edge; source size differs, so count is approximate.”

## Progress and failure

Use understandable stages: Reading selected site, Preparing proposal, Waiting for approval, Building layout, Capturing view, Comparing, Stopped.

On errors, preserve the last usable result where possible and say what the artist can do next. Examples:

- “The selected surface changed. Review an updated proposal.”
- “This source could not be evaluated as a supported mesh.”
- “The layout did not meet the protected-area clearance.”
- “The connection ended after submission; checking whether the layout was created.”

Never label a failed preview as a successful empty design. Never silently retry a possibly completed creation.

## Feedback with little burden

After acceptance/rejection, optionally ask one reason: composition, density, wrong asset, clearance, performance, changed brief or other. Let the artist skip. A separate data-use setting controls whether any record enters research/training.

Artist edits remain useful even without training consent: they can inform an in-session explanation or an explicitly saved local preference. Do not imply that every action is being learned.

## Questions for pilot artists

Use the pilot to learn:

- Which setup step is actually slow: regions, assets, density, variation or revisions?
- Is reference interpretation useful when regions are already confirmed?
- Do they trust and understand the proposed changes?
- How often do they keep the initial/refined result?
- Would saved recipes solve most of the same problem?
- Is cloud imagery permitted in their work?
- Does the feature help enough to use again on a different project?

**REQUIRES EXPERIMENT:** repeat use and willingness to pay. Do not infer these from an attractive internal demonstration.

