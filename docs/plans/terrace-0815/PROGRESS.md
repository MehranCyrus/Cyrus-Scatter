# Terrace work — current handoff, 0.81.5

13 October 2026. Read the [current report](REPORT.md) for the findings, editable
garden, exact matched builds/packages, measurements and acceptance boundaries.
The [iteration record](ITERATIONS.md) preserves earlier candidates and failures;
its pending-work statements are historical, not the current status.

The nine-layer scene has 245,664 accepted placements and passes final save/reopen
identity/transform checks. Source rectangles now open compact properties, per the
user's instruction. The old 100,000 cap is replaced by a one-million population
limit within a shared one-million controller candidate budget.

Max 2026 and Max 2027 matched host campaigns pass. Both packages are prepared;
the normal installation remains 0.81.3. The final 1920x1080 PhysCamera002 render
is complete and visually inspected; render cleanup and unchanged placement
fingerprints pass. No commit/push or
website publication has been performed. Original scene and artist profiles are
preserved. See REPORT.md for exact paths and remaining physical/renderer gates.

Subsequent [Mesh viewport testing](MESH_TEST_2026-10-13.md) found native memory
admission failure at the full saved load despite cache reuse at an admitted load.
The [vendor viewport research](VIEWPORT_POLICY_RESEARCH_2026-10-13.md) recommends
adaptive display budgets and bounded retained memory; it is a proposal only.
Neither follow-up changes the plugin implementation or qualifies presented FPS.

The subsequent [0.81.6 implementation](VIEWPORT_0816.md) records the authorized
adaptive-limit/fallback changes and their own exact qualification. The 0.81.5
builds and measurements above remain historical witnesses.
