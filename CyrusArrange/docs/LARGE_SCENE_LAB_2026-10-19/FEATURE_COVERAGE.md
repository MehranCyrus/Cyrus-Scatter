# Integrated feature coverage

This matrix describes this particular large scene. “Actual handlers” means the native Modify view was mounted in an owned normal 3ds Max session and its real handler was invoked. It does not mean mouse or keyboard gestures were automated. No computer-use tools were used.

Final acceptance identities and follow-up results are in [technical results](TECHNICAL_RESULTS.md).

| Feature | Scene exercise | Evidence / limit |
| --- | --- | --- |
| Geometry-only placement | Shelves, tables, stairs, TV console and cabinet | No furniture-type filter; actual meshes checked independently. |
| Bulk original prop intake | Mixed books, complete plant/decor groups and simple props | Actual handlers; duplicate source intake also preserved catalog and output. |
| Reusable compound prop | Sixteen copies of a candle/vases arrangement | Actual copied source/group intake; full source-shape check. |
| Quantity | Four libraries of 100 books, 72 stair objects and other owners | Final actual counts, not inferred from requested settings. |
| Fill available space | Coffee 4, 45% | Computed target 7, placed 7. |
| Min copies | Coffee 1 and stairs | Asset-ID ledger: all four nonzero policies satisfied. |
| Automatic new seed | Dense library regeneration | Seed changed; protected placement retained. |
| Repeat seed | Dense library and restored coffee obstacle | Full accepted pose/state comparisons. |
| Random uniform scale | Books, decor, TV props, stairs | Actual source/output affine transform and permitted final range. |
| Original size preferred | Cabinet's first full-size device and cars | Observed original size where accepted. |
| Shrink to fit | Two cabinet devices, minimum 60% | Original-size rejection followed by two fitting outputs; independent shape/scale/support checks. |
| Gap / collision | All owners and relevant cross-owner pairs | 216,235 reviewed pairs; four coarse candidates separately resolved using closed components. |
| Automatic base support | Complete real plants and other props | Actual output bottom triangles against receiving triangle unions. |
| Edge gap | Different saved values across the scene | Applied and preserved; separate independent boundary-inset proof not performed here. |
| Explicit Keep clear obstacles | Tray, screen and cabinet obstruction | Geometry review includes explicit obstacles. Follow-up Remove/Add and stale revision handling exercised. |
| Clear approach | TV console | Draft/commit/Undo exercised. Same final layout with option off; this fixture does not isolate geometric access rejection. |
| Protect selected | First library book across a new variation | Protected pose preserved. Unprotect interaction not separately repeated in this scene. |
| Invalid draft handling | Reversed random-scale range | Rejected without replacing accepted state. |
| Fit-space highlight | Failed cabinet attempt | Actual current boxes, hide toggle, no scene-node or selection changes. |
| Use checked size | Same cabinet attempt | Unavailable: diagnostic found no checked suggestion. Do not count as passed. |
| Curved path, two directions | Complete modeled cars on receiving road | Twelve cars, six each direction; [independent integrated-road proof](../../build/large-scene-lab-20261019-review01/integrated-road-review01.json) passed, including all five negative controls. |
| Offset / sideways / along variation | Curved car lanes and plant line | Seeded controls applied; complete-car lane/headings/spacing proof passed independently. |
| Center spacing / reverse / front axis | Fifteen plants along a supported straight path | Counts/settings and exact reopened-repeat poses checked; no separate plant-heading mathematical proof. |
| Undo / Redo | Generated library layouts | Full pose/state checks; TV approach generation also undone. |
| Save / reopen | All fifteen owners | References, settings, minima, path controls and full poses retained; both reopened paths regenerated. |
| Original source preservation | All registered unique source hierarchies | Actual source geometry/transforms; follow-up includes source topology and authored map arrays. |
| Materials / maps | Real prepared models; 131 adjacent map files | Copied bytes and assigned paths checked; actual Corona previews inspected. Effective flattened-source face material/UV mapping is not fully proved by the main export. |
| Compatibility viewing copy | Fresh core meshes from generated output | All 590 copies passed separate bake/readback checks in experiment05; it is not an editable arrangement and was not executed with the artist's older plugin runtime. |

## Not a substitute for other tests

Interactive picker gestures, path-to-surface switching, source deletion/replacement, imported corrupted topology, historical-scene migration, non-millimetre scene units, all alternate lane/scale combinations, controlled performance and installer behavior are not requalified by this scene. Existing focused tests remain separate evidence with their own exact source maps. Legacy row/stack recipes are not used here. There is no gravity, soft-body or cloth simulation.
