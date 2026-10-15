# Idle and interaction qualification

Use only a matched, disposable **Max 2027** host created by
`tools/eleven_phases/launch.py`, with a fresh name starting
`foundation-roadmap-idle-` (or `foundation-roadmap-p05-idle-` when following the
inherited regressions in that same disposable host). The fixture asserts ownership before
resetting or creating scene objects. It never saves into the original terrace.

Write `idle-request.json` in that profile with `{"operation":"setup"}` for eight
layers, 40,000 placements and 1,000 unrelated objects. Add `"terrace":true` to
copy and load the current `Test Scene/Terraces_0815/Terraces_0815_Final.max`
instead. Submit `fixture.py` using `tools/eleven_phases/request.py`. Setup is
**once per host** because it instruments the original synchronization functions.

Run `python tools/performance/live_idle/run.py <profile>` for idle, navigation,
panel/selection, unrelated event, relevant parameter, hidden native helper and
explicit recovery witnesses. Requests are serialized and correlated. A timeout
does not cancel a running host request; inspect it before doing anything else.
After completion, run `python tools/performance/live_idle/verify.py <profile>`;
`--baseline <profile>` compares a saved scene's hash and position/source
fingerprints. It requires the same saved scene: fresh synthetic receivers get
new IDs that deliberately salt random placement. `cyrusEditFingerprint` hashes
positions and source indices; it is not a full matrix/identity hash.
After submitting the `mesh` operation, repeat the run and verifier with
`--prefix mesh-` to preserve the Point Cloud receipts alongside Mesh witnesses.

The idle observer runs 50 bounded 100 ms ticks, with no scene queries in its
tick callback. It stops itself. Counter snapshots and position/source fingerprints
are outside that window. CPU samples include the entire Max process, the private
transport and observer; they are not plugin CPU measurements. Native draw counts
may change on OS repaints without a new upload or placement calculation.
Navigation timings measure synchronous script/redraw calls, not presented FPS.

`panel_profile`, `panel_detail`, `trace` and `trace_result` are optional diagnostic
operations. They are not release acceptance substitutes. The diagnostic trace is
bounded to 180 input events. Preserve failed/probe receipts and distinguish a
corrected fixture from a corrected product. For example, do not mount an already
selected object twice. Panel timings include an explicit bind because setting
`.open` alone does not establish delivery of a physical rolledUp event.

The shared lifecycle and prior feature regressions remain in
`tools/eleven_phases/qualify_p05.py` and require a separate owned P05 profile.
See `docs/plans/eleven-phase-roadmap/PERFORMANCE_0823.md` for exact qualified
identities, counters, timings and outstanding acceptance.
