# Cyrus Scatter 0.87.4.3: independent root exclusion and Wireframe

Scope: user-requested Max 2027 patch to 0.87.4.2. Qualification is pending until the successor delivery report records executed results. Version 0.87.4.3 preserves internal registration IDs and independently versioned products.

## Controls and ownership

The reacting logical layer owns Hide covered roots, Hide area, Hide margin, and Contact gap. Hide margin is stored in scene world units and converted once to metres at capture, then to source space per instance. It is nonnegative, bounded to 10 metres in world space. Contact gap retains its independent 0–10 cm range. New layers default to Under collider; hiding remains off until enabled.

- Inside solid classifies actual root points and fixed anchors against the closed collider and Hide margin.
- Under collider also projects the actual collider triangles along world up, clipping to geometry above the root. Hide margin expands that footprint laterally. This is an explicit footprint operation, including floating objects above the roots; it is unsuitable for overhead canopies if plants should remain underneath them.
- Hiding removes a rooted guide group and its attached geometry, not arbitrary fragments or roots alone. It does not remove scatter placements. Moving a collider away restores the group.
- Contact gap controls bending clearance only. A fixed root intersecting bending clearance outside the chosen hiding area is an explicit failed successor; reduce Contact gap, increase Hide margin, or move the collider. Failed fits do not silently enlarge hiding or publish penetrating geometry.
- Neither hide control changes source preparation or guide definitions. Changes restage contact for the existing published placements, including in Manual mode with pending placement edits.

## Persistence, invalidation and resources

Append-only parameters retain earlier parameter IDs. Scene schema 63 admits schema 58–62 through existing migration; the new migration assigns Inside solid and copies the old Contact gap into Hide margin to preserve prior exclusion. Layer copying transfers both fields. Native interaction capability 11 requires the new 11-field layer payload and rejects stale script/native combinations.

The interaction publication key includes both fields. Undo uses the existing layer parameter ownership and contact restage. Candidate bounds include the greater of bending clearance and enabled Hide margin. Under collider extends only the vertical upper side of reacting bounds, so both original and edited collider indexes find elevated footprints. Old and new edited neighborhoods are recalculated; distant poses remain retained. The plant BVH splits projected bounds on horizontal axes, rather than treating the artificial upward extent as spatial distribution; this preserves useful horizontal locality. Source and collider data remain immutable copied numeric objects. Host capture/publication stays on the host thread; workers perform bounded numeric queries. Existing local collider, source, query, memory and worker admissions remain in force; no new unbounded geometry allocation or placement-sized script loops are added. Projection uses bounded stack-local triangle clipping and the collider BVH.

## Retained viewport drawing

MeshItem previously forced FillSolid and used the texture opacity shader regardless of viewport visual style. Display now reads the current DrawContext's ViewExp::IsWire() flag as well as IViewportViewSetting, selects FillWireFrame for Wireframe, and uses its existing untextured mesh material and stream layout in that mode. Each viewport makes its own choice at draw time. Source/instance buffers, publications, triangle budgets, selection colors and shaded return path are retained. No raw graphics device or global active-viewport lookup is introduced. Edged Faces is outside this patch's requested Wireframe scope.

## Acceptance

Run generated-layout checks and native tests; add independent-margin, directional footprint, rotated transforms and moved-index restoration cases. In an owned Max 2027 profile, verify the exact packaged script/native identities, schema 62 migration, automatic UI changes and Undo, source preparation reuse, Manual pending edits, save/reload, elevated and moving collider coverage, Mesh and Textured mesh Wireframe and return to shading. Use an untouched copy of the existing plant fixture, plus simple geometry for unambiguous viewport evidence. Package and verify an exact-source-matched Max 2027 MZP. Preserve original scenes, artist profiles and historical receipts.
