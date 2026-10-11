# Point-only Spline bands check

Completed overnight 10-11 October 2026 against unchanged product commit `46374194c5dba42d643425e3810390b8ddb3f903`, Scatter 0.78.3. This follow-up adds a fixture and documentation only; no new installer or product behavior change.

## Result

Point-only Spline bands work through **Color groups**, with no geometry sources, plants, bushes, Paint Areas or brush documents. The fixture creates a receiver plane, one closed rectangle guide, three Point placeholder rows and one Scatter layer. The receiver is hidden for the saved viewport; it remains the sampling surface.

The three groups occupy two consecutive 20-unit inside bands and one 20-unit outside band around a 160-by-160 guide. Plant centres display draws exactly one marker per accepted placeholder. Point placeholders have no final model/render geometry.

**Confirmed limitation:** choosing **Assign by > Source objects** produces an empty choices list despite three Point rows. `showStroke` filters this list with `isValidNode`; `strokeSourceNodes` and the corresponding `lineInputs` branch also require scene nodes. Point rows are negative placeholder tokens in `validSources`. Thus this is not only a label issue. Color-group assignment correctly includes the placeholders. B12 records the missing direct-selection workflow; it is not repaired or counted as a passing feature here.

## Checks and measurements

| Check | Max 2026 | Max 2027 |
| --- | --- | --- |
| Focused assertions | 18 passed | 18 passed |
| Candidate budget | 10,000 | 10,000 |
| Accepted points: inner edge / next inside / outside | 1,029 / 708 / 1,413 | 1,100 / 799 / 1,325 |
| Total displayed points | 3,150 | 3,224 |
| Retained mesh faces | 0 | 0 |
| Ten unchanged reads/redraws: new epochs / candidate builds / uploads | 0 / 0 / 0 | 0 / 0 / 0 |
| Single explicit Update measurement | 145 ms | 102 ms |
| Direct Source objects choices for three Point rows | 0 - limitation | 0 - limitation |

Assertions cover actual generated Add Point and add-band callbacks; all accepted points' geometric side/distance and source group; one marker per accepted row; exclusion from final geometry output; retained point display; unchanged caches; Manual waiting for Update; Live width changes; and exact source types, choices and placement fingerprints after save/reopen.

Counts differ because new receivers have independently salted identities in each disposable scene. This is candidate-budget mode: only candidates inside the configured bands are retained, so 10,000 requested candidates do not promise 10,000 visible points. The timing is one synchronous Update call in an already active host, not a statistical benchmark, cold-process startup or presented FPS. The raw fixture labels it "Cold explicit Update"; do not infer a cold native cache from that label.

The final fixture drains queued receiver/guide creation notifications before measuring unchanged work. An earlier draft omitted that drain: `procGeometryRevision` changed from 0 to 2, and the first direct evaluation republished the same points once while reusing receiver candidates. Final runs show no repeated publication or upload over the ten unchanged evaluations. Initial fixture syntax and listbox-event invocation errors were corrected before the final successful runs.

## Reproduce and inspect

Use [spline_points.ms](../../tools/vector_brush_078/spline_points.ms) only through the [private-host workflow](../../tools/vector_brush_078/README.md). It resets an owned disposable scene. Both hosts used the previously qualified 0.78.3 script and native modules; exact hashes, loaded paths, checks and artifact hashes are preserved in [SPLINE_POINTS_EVIDENCE.json](SPLINE_POINTS_EVIDENCE.json).

- Max 2026 host: `build/vector-brush-078/spline-points2026-01`, native build `containers-max2026-02`.
- Max 2027 host: `build/vector-brush-078/spline-points2027-01`, native build `containers-max2027-02`.
- Scene in each host: `spline-points-only.max`.
- MAXScript-generated viewport image: `spline-points-only.png`.

Scenes and images are local ignored artifacts. The 2026 scene is the useful starting file for opening in either supported Max year. No computer use, pointer injection, artist-scene changes or installation into the normal Max profile occurred. Both owned hosts were closed afterward. This checks Point placeholders in rectangular bands; it does not qualify every spline shape, physical picker interaction, Point replacement, Empty rows, accepted-target mode or render output.
