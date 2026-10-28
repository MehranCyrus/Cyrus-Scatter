# Interaction performance patch — 0.87.5.2

Install the complete **Max 2027 MZP** through **Scripting > Run Script**, then
restart Max. Existing prepared sources rebuild their derived native caches on
load; there is no new preparation step, contact setting or GPU panel.

Use the existing Collider / React to colliders roles and move a collider instance
through Cyrus Scatter Edit. Contact gap controls bending clearance; Hide margin
controls exclusion separately. Manual placement edits still wait for Update.
Scene presets, portable recipes and the Source Preparation Editor are retained.

This patch avoids repeated geometric classification, triangle-address searches
and identical stem/leaf frame calculations. It retains full triangle contact
checks. It does not lower blade percentage, hide failed bends or replace real
geometry with a larger collision hull.

The diagnostic contact report now distinguishes actual preview-build duration
from a cached read and includes work counters. Those numbers describe their
recorded scope; they are not viewport FPS. Deep overlaps can still produce an
edge-strain warning even when the visible mesh clears the collider. Use the full
visible-mesh check when assessing a difficult plant/contact pose.
