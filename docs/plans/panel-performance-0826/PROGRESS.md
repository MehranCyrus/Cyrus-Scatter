# I01/I02 — diagnostics, responsive panels and scaling, 0.82.6

Status: Max 2027 qualification and installer verification passed. Delivered without installation. Phase 6 remains paused.

**20 October follow-up investigation:** [panel loading and threading research](PANEL_THREADING_20261020.md)
inspects the retained architecture and adds a small frozen 0.86.6.2 / Max 2027
timing probe. It separates two-section/all-open construction from warm binding,
documents safe worker boundaries and recommends reduced UI work before thread
offloading. It implements no performance correction and does not relabel the
historical qualification below. B21 remains open.

**20 October planning follow-up:** the [combined UI/content implementation plan](../preset-gallery-improvements/UI_AND_CONTENT_IMPLEMENTATION_PLAN.md)
defines current-baseline measurement, affected-page updates, independent layout,
deeper lazy construction and conditional queued work, with lifecycle and
three-host delivery gates. That planning report claims no new speedup by itself.
The later [0.86.7.1 delivery](../preset-gallery-improvements/DELIVERY_08671.md)
records scoped refresh/layout caching, queued section creation, measured results
and remaining cold construction limits. It preserves the historical evidence below.

## Scope and delivery identity

The user authorized I01/I02, panel clipping/scaling corrections, Max 2027 testing
and a runnable installer. No installation or restart of the artist's Max is
included. No later Forest improvement or Phase 6 work is implemented.

0.82.6 follows 0.82.5 using the user's small-step version policy. This delivery
changes diagnostics and presentation, not planting rules, scene schema 58,
CyrusUnified1, or recipe schema 1. Analyzer and MCP versions remain independent.
Contracts: F01, F04–F08, F11.

Baseline branch: `codex/workflow-0.75`; HEAD:
`a4af303b0902886e975c96b6900f047f37198a92`.
Existing unrelated changes, artist profiles, installed plugins and `Test Scene/`
are preserved. The implementation/testing stage performed no commit, push, installation or deployment. The user subsequently authorized a Git checkpoint of this delivery; that checkpoint preserves the original qualification identities below.

The exact final source/native/host identities are sealed in
`build/panel-0826-20261015-01/final-receipt.json`; archive identities are in
[PACKAGE.json](PACKAGE.json). These receipts supplement source inspection.

## Implemented behavior

### I01: bounded measurements and action correlation

The existing opt-in recorder now aggregates calls, inclusive microseconds,
maximum duration and exception failures for 15 stages: receiver extraction,
mesh-channel extraction, candidate generation, mask and surface filters,
attributes/radii, spacing, preview preparation, upload, publication, map baking,
and UI creation/binding/layout/list synchronization. Nested stage durations must
not be added as independent wall time. Stages describe their measured scopes,
not every instruction in the application.

Recording retains the existing event/byte/time bounds. Disabled scoped timers
check recording state before reading a clock or taking the recorder mutex.
Recording generations prevent late completions entering a newer session.
UI action IDs follow relevant edits through invalidation and deferred publication.
Export adds a passive snapshot of cached setup/layer status. Reading a report
never evaluates meshes or refreshes scatter. Failed-stage counts represent
exceptions; early rejected operations need not emit a publication-stage event.

### I02: construct controls when opened; retain them while mounted

Twelve lightweight native command-panel slots replace eager construction of all
heavy pages. A page creates its controls on first opening and retains them until
Max unmounts the Modify panel. Switching owners rebinds the existing controls.
The first binding occurs after Max initializes rollout locals. Selection, Undo,
Paint Area and Band callbacks retain explicit setup/layer ownership.

Native and managed lists avoid replacing unchanged items. Managed list styling
and drag-grip initialization run once per control lifetime. Paint status only
requests a new layout when its text changes. The generated control inventory
still contains all 281 semantic controls; the authoritative templates and
modules generate the delivered script.

### Clipping and display scaling

Layout uses the smaller of the visible column's usable width and the nested
body's actual width. Narrow rows reflow; narrow paired Min/Max fields put captions
above their fields. MAXScript's runtime rollout heights are converted to physical
pixels, while control placement stays in logical UI units. The outer slot supplies
the visible header; the nested header is cropped using its measured logical
extent while Max retains normal subrollout ownership.

Managed lists use the native control font instead of multiplying font size by
UI scaling again. Row/swatch geometry follows UI scaling. Labels and multiline
checkboxes use actual native-font measurements, cached by control/text/width.
The generated script has a UTF-8 BOM so icon captions are read correctly.

## Evidence and limits

Final profiles (owned, disposable; Max 2027 only):

- `build/mcp-qualification/foundation-roadmap-panel0826-final100-20261015-01`
- `build/mcp-qualification/foundation-roadmap-panel0826-final150-20261015-01`

Baseline profile:
`build/mcp-qualification/foundation-roadmap-panel0826-baseline-20261015-01`.
It contains the exact 0.82.5 pair and the saved eight-layer fixture.

Native build: `build/panel-0826-20261015-01/native-03`: 33/33 native suites passed.
`script-delivery-final` reuses those binaries after verifying every compiled input and
hashes the final interpreted script separately. Generated checks are under
`generated-delivery`. Python tests: 163 passed in 11.87 s. The script identity test accepts the UTF-8 BOM while still verifying the exact payload hash.

### Host results

- Exact ordered eight-field placement rows match the saved 0.82.5 fixture.
- 100 page/owner cycles at 100%, plus 20 at 150%, retain the same controls and
  do not extract geometry, solve placements, prepare previews or upload buffers.
- Actual Amount handlers preserve Manual pending edits and publish on Update;
  Live edits publish through the host event loop with correlated action IDs.
- Unrelated object animation and 20 timeline changes do not rebuild static scatter.
- Actual Remove plus native Undo restores all eight layer IDs and complete rows.
- An invalid mesh-channel successor retains the prior epoch/result; correcting
  it recovers the same complete rows.
- 100 passive diagnostic/status reads invoke none of the 15 measured stages.
- Paint/Band owner switching, actual density/width handlers, recipe Save Everything
  with exact Paint bytes, scene save and reopen pass at both scales.
- The heavy fixture has 200,000 placements, an 180,000-face receiver, mesh-channel
  filtering and retained Mesh output. Recorder-off idle is 60.9887 s; recorder-on
  idle is 60.0103 s. Solve/preparation/upload counters and full rows are unchanged;
  all 15 measured stage call counts are zero during recorder-on idle.

Warm setup reselection, same local eight-layer fixture/procedure:

| Case | Samples | Median | p95 |
|---|---:|---:|---:|
| 0.82.5 baseline, recording off | 10 | 10,114.18 ms | See baseline receipt |
| 0.82.6, recording off | 30 | 1,407.01 ms | 2,098.72 ms |
| 0.82.6, recording on | 30 | 1,285.55 ms | 2,015.38 ms |

The recording-off median is about 86% lower in this fixture. The on/off runs
were separate observations; their difference is noise, not proof that recording
makes the plugin faster. Relevant-edit tests added ten placements before the
candidate timing run (40,010 versus 40,000 baseline). This is a scoped local
comparison, and a roughly 1.4-second reselection is not an instant-response claim.
B21 remains open for further profiling of residual panel costs.

The final caption follow-up corrects three previously corrupted Band glyphs,
shortens two panel headings and fixes one comment. `presentation-only.diff` and
`receipt.py` prove the rest of the generated script is unchanged from the behavior
campaign (`76ea2e…176a`). The exact delivered script (`c1be0c…61c7a`) is loaded in
fresh `foundation-roadmap-panel0826-delivery100-20261015-01` and
`foundation-roadmap-panel0826-delivery150-20261015-01` profiles. Both verify complete
rows and actual glyph strings, then check all 12 panels with populated Paint and
Band owners. Control edges, text heights and overlaps all pass after Max's queued
column layout settles. Preparation and measurement run on separate host turns.
Native binaries are identical across these campaigns.

Scaling qualification uses Max's supported `CustomControlsOptions.UIUserScaleFactor`
in private profiles at 1.0 and 1.5. It checks real native control rectangles,
wrapped text heights and overlaps at narrow command-panel widths, with populated
Paint and Band owners. It does not change Windows display settings and is not a
physical 3840×2160 monitor or mixed-DPI monitor-transition certification. Initial
child-window bitmap captures did not render usable controls and are not visual
acceptance evidence; final main-window captures are identified separately.

Local synthetic-scene timings do not guarantee arbitrary scene/renderer
performance or presented FPS. No render, tablet or Max 2026 certification is made.

## Rejected iterations retained as evidence

The first lazy-panel candidate passed interaction/performance checks but still
clipped controls and exposed empty nested headers. Removing those headers by
mounting a body through `addRollout` into a subrollout floater produced access
violations on reselection. That approach was removed; final code uses normal
`addSubRollout` ownership throughout. A detached-factory experiment also exposed
a MAXScript forward-declaration compile error and was removed.

Later visual checks found the logical/physical height mismatch and managed font
double scaling at 150%. Edge-only checks initially missed empty HWNDs and caption
versus field overlaps; the final audit ignores zero-area caption placeholders,
requires measured controls on every page, and checks text height and overlaps.
These earlier passes do not by themselves qualify the delivery pair. Logs are retained in the
owned candidate profiles. An immediate post-reopen bounds audit observed queued,
not settled, Qt positions; separate preparation/observation requests resolved that
measurement error without product changes. A local caption-edit command used an
incompatible encoding and truncated the template; it was reconstructed from the
baseline and saved generated evidence, then verified to regenerate the prior
qualified script byte-for-byte before the caption-only corrections. An earlier native build receipt was rejected because
its script changed during compilation; subsequent frozen builds/staging succeeded.

## Verified installer and final views

- Package: `dist/CyrusScatter-0.82.6-20261015/CyrusScatter-0.82.6-Max2027.mzp`
- Size: 996,405 bytes. SHA-256:
  `7b70913dca6d1454a7762d7a88a4ee0076fcf48434abd68dc38a8c6c8a9b7c90`
- ZIP integrity, exact members, every payload hash, script/native identities,
  Max 2027 host guard, native destination identity, version and restart instructions
  passed. The installer was never executed.
- Final main-window captures: `delivery100.png` and `delivery150.png` in the two
  delivery profiles. They show the final normal/narrow scaled layout and corrected
  Band captions. Bounds/text/overlap receipts cover the remaining panels and lower
  controls; screenshots alone are not the complete qualification.
- Website source synchronization, reference checks and production build passed.
  The existing large-chunk advisory remains; no website was published.

## User acceptance after installation

Run the delivered `.mzp` using **Scripting > Run Script** in Max 2027, then restart
Max as the installer instructs. This task does not run the installer.

1. Open an existing setup, select different layers, and expand every panel and
   Advanced section. Resize the Modify panel; labels, controls and Min/Max fields
   should stay readable and reachable by normal scrolling.
2. At your usual 4K/150% Windows display setting, check text, list rows, Paint,
   Bands, Transforms and bottom controls. Physical-monitor acceptance is yours.
3. In Manual, change Amount, Paint density or a Band width; browsing must leave
   the previous result until Update. In Live, relevant edits should refresh.
4. Leave a heavy scene idle and browse panels. Diagnostics should attribute UI
   work without new placement/preparation/upload work. Export a bounded report
   if your own scene still shows lag.
5. Check recipe Save Everything and reopen a scene containing Paint and Bands.

## Delivery follow-up

The user reports smoother interaction and faster loading after delivery. This is
a qualitative artist observation; it does not close the physical 4K/mixed-monitor,
long-session or renderer acceptance limits above. The Git checkpoint includes
source, generated UI, tests, guides, roadmap and package/qualification receipts.
Ignored installers, binaries and local host evidence remain separate from Git.
The knowledge-search generation is stale; this follow-up verified current files
directly and did not refresh or activate a new index. Phase 6 remains paused.

## Reproduction entry points

`tools/panel_performance_0826/launch.py` creates private hosts; `run.py` serializes
correlated requests. `qualification.py`, `undo.ms`, `idle.ms`, `layout_audit.py` and
`capture.py` contain the fixtures. `receipt.py` validates the final source/host
receipts before `package.py` constructs and verifies the archive without installing.

## Relevant host API references

- [Subrollout ownership and mounting](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-CDE5B06D-4BB4-4DEA-96C1-6BAB98709F09.html)
- [Rollout properties and width limitations](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Utilities-and-Rollouts/GUID-DC435555-362D-4A03-BCF2-21179C5442F2.html)
- [Windows coordinates and explicit UI scaling](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/Interaction-With-The-Operating/GUID-282F32AC-5A80-4FDB-B8C0-275D2CC15845.html)
- [Max custom UI scale](https://help.autodesk.com/cloudhelp/2018/ENU/MAXScript-Help/files/GUID-AC26099B-60BF-4C99-997B-DF65F8D47DC1.htm)
