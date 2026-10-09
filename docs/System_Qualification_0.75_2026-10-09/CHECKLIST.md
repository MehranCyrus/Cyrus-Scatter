# System qualification checklist

Current campaign: 0.75 / Max 2027 / 9 October 2026. A checkmark means the stated bounded test passed on the recorded build. It does not certify every setting combination or physical interaction. See [evidence](EVIDENCE.json) and the [234-control register](CONTROL_REGISTER.md).

## Qualification families

Statuses below refer to concrete passing scenarios in the evidence index. A family pass covers its stated assertions, not all combinations or every physical control interaction.

| ID | Feature / relationship | Required evidence | Status |
| --- | --- | --- | --- |
| F01 | Enable, disable, viewport visibility | Core/publication and playback skipped owners | [x] Core/publication + final 942-assertion Scatter/Analyzer playback |
| F02 | Layer-owned receivers, missing targets | Plane + sphere, removal/restoration/Undo, no-receiver state | [x] Regions: 45 assertions, core and persistence |
| F03 | Layer copy/remove/order and identities | Core copy/remap/rules/Undo | [x] Core copy/order/remap/Undo and region-copy checks |
| F04 | Paint Areas versus older model groups | Independent targets, shared models, union, layer copy | [x] Regions and 22 consolidation assertions; old multi-set conversion remains open |
| F05 | Models, aliases, weights, ID colors | Source callback tests and persistence | [x] Sources-final: aliases/colors/weights and reopen |
| F06 | Add Point / Empty / Replace Point | Actual handlers, Undo/Redo, selected-row isolation | [x] Actual source handlers, Undo/Redo and metadata isolation |
| F07 | Source containers and shared consumers | Membership, park/reentry, hierarchy/lock guards, cache reuse | [x] Behavior-final containers, core container edges and movement |
| F08 | Source scale, offset, radius, forward axis | Native orientation/radius suites; source callback tests | [x] Native geometry/radius + current source settings checks |
| F09 | Fixed amount, density, seed | Determinism/count growth/native distribution and host geometry | [x] Core/native and arrangement assertions; receiver-add stability remains open |
| F10 | Bounded target, retry, underfill | Core shortfall, cleanup failure retention, narrow bands | [x] Core + bounded cleanup rejection/previous-publication retention |
| F11 | Texture sampling and inversion | Density/map mutation including nested texture and playback | [x] Publication nested-map mutation and playback texture changes |
| F12 | Include/Exclude and boundary falloff | Host geometry containment; native falloff suite | [x] Core containment and native boundary falloff; physical curve editor remains open |
| F13 | Analyzer bindings and producer ownership | Real publication, channels, warm reuse and explicit update | [x] Current Analyzer assignment/area publication and final timeline/Manual/parent/failure lifecycle |
| F14 | Flat/curved painting, Paint/Erase/Fill/Empty | Brush geometry, selected sphere among receivers, Undo | [x] Core Brush + selected plane/sphere region checks; tablet acceptance remains open |
| F15 | Paint persistence, inactive targets, topology | Save/reopen, target guard, preserved history on failure | [x] Region/core topology guards, inactive targets and reopen |
| F16 | Older-group background coverage | Complement, disabled coverage and bounded replacement | [x] Core background/complement assertions |
| F17 | Random and cluster assignment/groups | Weight/seed/position witnesses; separate ID colors | [x] Arrangement + source metadata separation |
| F18 | Spline bands, Analyzer channel assignment | Width/side/source isolation, overlap priority, stable growth | [x] Arrangement modes + advanced Line/Analyzer host scenarios |
| F19 | XYZ/uniform transforms and resets | Native tests; real paired bounds and reset callbacks | [x] Native transforms + 94 Layout assertions including paired bounds/reset callbacks |
| F20 | Within/between-owner collisions | Geometric clearance against radii/gaps and evaluation order | [x] Core clearance + consolidation independent scope checks |
| F21 | CS Edit/protected instances/radius overrides | Identity guards, zero quota, rollback, persistence | [x] Edit bindings/persistence, protected zero-quota and radius override cases |
| F22 | Cleanup neighbors/islands/work bounds | Native procedural suite; host admission/atomic retention | [x] Native procedural suite + host bounded failure/retention |
| F23 | Candidate Relax and final constraints | Native suite; deterministic Relax + Brush host case | [x] Native Relax suite + advanced Relax/Brush geometry |
| F24 | Manual/Live/Undo/idle/animation | Passive counters, relevant/unrelated changes, failure/recovery | [x] Manual/Live core, consolidation, 942 Scatter/Analyzer playback assertions and eight idle windows with node callbacks restored |
| F25 | Preview modes, limits, retained buffers | 100k navigation and playback counters; timings separated | Partial: 100k navigation and isolated retained reuse pass; one post-UI playback failure remains open |
| F26 | UI bindings/grips/shared views/captions | All mapped controls, layout/grip/lifecycle host tests | [x] 234 bindings; 23 list grips; lifecycle; Layout and eight caption/layout cases. Physical all-control acceptance remains open |
| F27 | Cached statistics and errors | Publication/shortfall/epochs and failure recovery | [x] Publication, errors, shortfall and recovery assertions |
| F28 | Render lifecycle | Stop failure matrix; separate actual-render campaign | [x] Eight mocked Stop cases and actual Corona floating IR/edit/save/resume/Stop/production/reset; visual/other-renderer acceptance remains open |
| F29 | Exact/PFlow/baked output mapping | Active-source count, transforms and owned output guards | [x] Behavior-final exact, PFlow and baked source/transform mapping |
| F30 | Persistence/Undo/units | Current scene reopen, guarded rescale, exact recovery | [x] Core units, current reopen, old 0.74 retention and source metadata Undo |
| F31 | MCP publication and authoring boundary | Python closed-schema/approval/rollback tests; native contracts | Offline passed; no fresh end-to-end MCP authoring claim |
| F32 | Local diagnostic recording | Start/Stop/idle overhead and passive counter checks | [x] Start/Stop, eight idle windows and current Statistics diagnostic export |
| F33 | Licensing | Separate default-off foundation | Outside product qualification; unchanged |
| F34 | ML/reference-image design | Separate experimental work | Not a production feature; unchanged |

## Required remaining acceptance, independent of passing scripts

- [ ] Resolve the intermittent retained-buffer counter failure after the mixed UI/legacy sequence; clean playback and isolated repeat passes do not erase it.
- [x] Final clean Analyzer timeline and actual Corona recovery qualification: 942 playback assertions and the complete renderer lifecycle passed. Prior failed runs remain in the evidence.
- [ ] Physically exercise every still-unchecked control in the register: picker dialogs, multi-selection, graph handles, keyboard editing, spinners, focus changes, docking and alternate DPI.
- [ ] Long continuous Brush sessions with tablet, nearby/folded sheets, many regions, and measured aggregate memory.
- [ ] Stable per-receiver placement design: adding surface 21 must preserve unaffected Density populations; Fixed Total needs an explicit quota/survivor policy. Current implementation does not provide this.
- [ ] Canonical final-region storage and end-to-end brush latency measurements. Prepared-stroke reuse alone is not a complete brush performance solution.
- [ ] Isolate the historical first-cold-container physical Move/Undo stack loss. Scripted movement passes do not close it.
- [ ] Validate complex real-plant scenes and full material fidelity; older private-scene evidence had seven missing maps.
- [ ] Final artist render inspection, longer interactive rendering and other render engines.
- [ ] Max 2026 runtime, tablet/high DPI and multi-hour scene editing.
- [ ] Explicit older multi-set conversion design and acceptance; preserve existing scenes until then.
- [ ] More adversarial extreme radii, complex spline boundaries, cleanup/refill combinations and Proxy draw cost.
- [ ] Refresh the standalone visual website's historical teaching diagrams and interactive examples for Paint Areas. The current guide here supersedes its 0.73 ownership examples.

## Strong implementation areas to preserve

Atomic publication, guarded stable Edit identities, bounded retries/work, copied worker inputs, separation of model metadata from palette membership, independent spacing relationships, and shared UI ownership are explicit contracts. Tests must assert their outcomes, not merely count controls or accept an empty error log.

## Test interpretation

Native suites test algorithms; Python tests cover tools/contracts; Max fixtures exercise real plugin objects and scripted handlers. Binding checks prove that a named control exists in its mounted view. Scripted events do not reproduce all mouse/tablet/modal behavior. Camera plus synchronous redraw time is not presented FPS, and whole-process memory is not VRAM. Reports retain failures and retries rather than rewriting them as passes.
