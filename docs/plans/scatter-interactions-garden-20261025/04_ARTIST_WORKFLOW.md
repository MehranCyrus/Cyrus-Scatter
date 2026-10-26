# Proposed artist workflow and Interactions panel

Use **Interactions** as the panel name. It leaves room for rigid objects and future effects without promising that every object is vegetation or that a dynamic simulation is running. The first feature is a rooted contact fit; wind is a separate future feature.

## Main controls

The selected layer gets two independent switches with plain explanations:

| Control | Meaning |
|---|---|
| **Acts as obstacle** | This layer's published instances block enabled reacting layers |
| **Bends around obstacles** | This layer's prepared plant instances can receive independent bend poses |
| **Prepare sources…** | Analyze each changed source once, inspect inferred roots/branches, accept supported results |
| **Keep plant roots clear** | Suppress covered plant placements using the chosen cover policy |
| **Contact gap** | Desired visible surface spacing, displayed in mm; default proposal 1 mm |
| **Live contact** | Update contact on published plants during relevant obstacle motion; respect explicit mode rules |

Off is the default for existing layers/scenes. The two roles can coexist where the source supports both; a tree trunk may block grass while branches react in a later qualified tree feature. For the first garden delivery, the tree is a static obstacle only. A role switch never changes source geometry or old radius-spacing settings.

By default, reacting layers consider enabled obstacle layers **in this Scatter owner**. An advanced layer picker can restrict relationships. Scene objects or other Scatter owners require explicit additional scopes; do not silently scan the entire Max scene for anything nearby.

## Simple garden setup

1. Create the ordinary stone, grass, lavender, geranium and tree layers with existing Scatter controls.
2. On stone layers, enable **Acts as obstacle** and **Keep plant roots clear**. Display whether the collider is an exact admitted mesh or an approximation.
3. On a plant layer, choose **Prepare sources…**. The dialog lists unique sources and capabilities, not thousands of instance rows.
4. Inspect root/branch overlays for supported sources and accept them. Unsupported sources remain usable as ordinary Scatter sources with a specific reason; they do not silently receive a guessed rig.
5. Enable **Bends around obstacles**, press **Update** for a complete first result, then enable the intended live contact mode.
6. Move an individual scattered stone through **Scatter Edit**. Nearby instances bend; covered roots disappear; plants recover when the stone leaves. Far plants keep their identities/transforms and shared rest geometry. The integration follows effective edited placement matrices; moving the hidden source is a different operation.

The target is a short routine workflow. Advanced topology repair, custom guide authoring and proxy construction belong behind deliberate buttons, not in every layer's default control stack.

## Preparation status

Use states that say what is actionable: **Not prepared**, **Analyzing**, **Needs review**, **Ready**, **Source changed**, **Unsupported blade profile**, **Unresolved branches**, **Budget exceeded**, **Missing source**. Show source count and guide count separately from instance counts.

For this library, display the actual findings: A069/A068 need a blade/ribbon profile; phlox has 54 unresolved guides; A072 exceeds connected-part admission. Do not tell users that a good mesh is necessarily broken or that increasing a limit makes it supported. The source list should offer **Select source**, **Show guides**, **Analyze changed sources** and **Accept reviewed sources**. An explicit acceptance step remains appropriate while inference can be botanically wrong.

## Advanced controls

Keep these collapsed by default:

- **Detection range: Automatic**, with optional extra search padding and a bounds overlay. Explain that this affects candidate selection, not the visible contact gap.
- **Cover mode:** root support / projected footprint / disabled, limited to currently admitted receiver and collider types.
- **Obstacle detail:** actual mesh or named proxy, with approximation/error status.
- **Bend stiffness**, root direction constraint and recovery/rest weight, with admitted physical ranges.
- **Preview quality:** light/full; per-owner work and posed-geometry budget diagnostics.
- **Affecting obstacle layers**, plus debug displays for covered roots, nearby bounds, active guides and failed fits.

Do not label a conservative capsule envelope as an artist-visible contact radius. Expose a requested gap and report measured delivered clearance/quality when available. If a preview has deliberately relaxed accuracy, label it Pending refinement until the required validation completes.

## Status and mode rules

Show one compact line such as: `2 sources ready · 2,185 plants · 324 covered · 698 nearby · 83 posed`. These numbers are an illustration of distinct concepts, not final solver counts; the baseline measured nearby bounds but did not produce posed plants. In actual UI, every count must come from its corresponding publication and include underfill/unsupported/pending counts.

Existing Manual placement edits stay pending until Update. If **Live contact on published placements** is enabled while placement mode is Manual, say **Plants from last Update; contact live**. A changed pending seed/count must not leak into the display because the artist drags a collider. Full Live mode follows relevant placement and interaction dependencies together. Browsing/selecting layers never starts analysis or consumes pending edits.

One drag should create a coherent Undo operation. Undo/Redo must restore both obstacle transforms and the correct compatible mask/pose result. On failed work, retain the last complete result and display a specific reason. Saving must record authored role/relationship settings and accepted preparation state; it must not require a live worker or a solver memory dump to reopen.
