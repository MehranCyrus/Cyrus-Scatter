# 0.87.5.6: responsive bending and trunk control

User-selected patch, Max 2027 only. Performance and an understandable artistic
result take precedence over exact collision clearance. Preserve the user's
`Test Scene/New Plants test 22.max` and use an owned test profile.

- Replace broad-response angle searches with one bounded pass over at most four
  coarse segments per guide/collider. Reuse prepared guide bounds and collider
  geometry. No detailed vertex/triangle validation in Bend/Trim modes.
- Add per-layer Trunk bend, Fixed base and Bend fade percentages. Roots and fixed
  authored regions remain anchored; structural root guides default to rigid.
  Child branches inherit their parent pose. Changes reuse preparation.
- Keep Detailed contact as an explicit slower option. Older detailed scenes
  migrate to Bend on load in this performance-first delivery; artists can choose
  Detailed contact again. Existing bend/trim choices remain.
- Present ready GPU frames while a drag is held. This display-only wake must not
  regenerate placements, prepare sources or change Manual pending edits.
  Each new frame ticket receives its own bounded redraw allowance; an earlier
  update cannot exhaust presentation retries for later collider movements.
- Admit parallel numeric work for small groups of complex plants using prepared
  guide counts. Retain joined workers, ordered failure selection and publication.
- Ignore inactive source-history rows before creating Cyrus Edit contact patches;
  use this boundary both while dragging and when replaying edits after changing
  bend controls. Keep authored records for Undo and matching source restoration.
- Scene-collider transforms dirty only the contact pose; unsuccessful incremental
  updates keep their pending flag and last complete display. Geometry changes
  still use a complete successor.
- Move preparation sizes/limits into More settings. Keep everyday bend controls
  visible. Layer copies, saved scenes and authored Undo include the new values.

Ownership: immutable source-local geometry/bounds; layer-owned response controls;
controller-owned scene collider references; native copied numeric work; host-only
capture/publication. All successor allocations precede publication. Peak memory
retains old/new poses and GPU frames; no per-instance full meshes are created by
the interactive Bend path. Detailed-mode scratch is charged only when required.

Verification scope: compile the exact native/script pair; test scene loading,
viewport navigation and scripted collider stone movement in Max 2027, including
publication with the drag-held predicate set. Record numerical work separately
from actual presented-frame tickets. No Computer Use, older hosts, broad test
suite, renderer campaign, artist install or Git publication. Deliver a Max 2027
MZP with payload hashes and an honest record of these limits.

Version: 0.87.5.6; scene schema 65; native Interactions 15. Other independently
versioned products and Library/recipe/Edit formats remain unchanged. New bend
profiles travel through native .max/Scene presets; portable recipes still admit
their existing Detailed-contact subset and must reject unsupported profiles.
