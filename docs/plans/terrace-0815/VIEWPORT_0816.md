# Adaptive viewport — 0.81.6 implementation and qualification

13 October 2026. Implemented and tested in disposable Max 2026/2027 profiles.
This is scoped development qualification, not release certification. The initial
qualification did not package or install into normal profiles. The subsequent
user-authorized [0.81.6 delivery](INSTALLATION_0816.md) packages these exact tested
modules and installs them for Max 2026/2027. No commit, push or website deployment
was performed.

## Scope and version

The user authorized the Mesh fallback fix, independent navigating/idle limits
with **0 = unlimited**, terrace testing and version **0.81.6**. The new viewport
capability would normally justify a minor version; the explicit requested label
is recorded as the override. Saved schema 58, Band interface 10, publication
interface 2 and calculation model CyrusUnified1 remain unchanged. The matched
script additionally requires native viewport policy capability 1. Analyzer and
MCP version domains are unchanged.

Work started on `codex/workflow-0.75`, HEAD
`2b9ad12b24f9d91241db4567037f64db71fe9726`, with existing changes preserved under
`build/viewport-0816-20261013-01/baseline-source` and its hash/status receipts.
The prior [vendor research](VIEWPORT_POLICY_RESEARCH_2026-10-13.md) and
[0.81.5 Mesh investigation](MESH_TEST_2026-10-13.md) remain historical evidence.
The knowledge index rejected retrieval because its source manifest was stale;
current source and SDK inspection supplied the engineering evidence instead.

## Implemented behavior

| Representation | Navigating default | Idle default | Unit |
| --- | ---: | ---: | --- |
| Point Cloud / Centres | 10,000 | 20,000 | Drawn points |
| Proxy | 500 | 2,000 | Drawn instances |
| Mesh | 500,000 | 2,000,000 | Drawn triangles |

Limits belong to the Scatter controller and are shared across its visible
layers. Existing saved idle values are retained. Each phase can be larger than
the other; preparation serves both. Zero removes that phase's artist cap. It
does not remove finite source/input bounds, memory admission or allocation
failure handling. Inspection overlays retain their separate bounded policy.

Source groups receive deterministic quotas. Expensive Mesh sources use cached
boxes when they cannot fit their triangle share, instead of disappearing. If
retained full geometry exceeds memory admission, native planning tries boxes.
A graphics fallback draws at most 2,048 centre markers per cache, with **no CPU
source-triangle loop**. GPU graphics still has to draw admitted geometry every
frame; this is not GPU placement calculation or a promise of unlimited FPS.

Mesh source snapshots are independent of draw limits. Quota changes reuse them;
view movement selects already prepared idle/navigating quotas and buffers. A
stable permutation spreads shorter draw prefixes across each source group. The
native draw context detects the first moving frame; a 400 ms script settling
timer requests the idle redraw without scheduling a solve. Manual pending edits,
accepted identities/transforms, and final output placement policy are preserved.

Current resource bounds remain: Point Cloud 64 MiB owner / 128 MiB process;
Mesh 512 MiB owner / 1 GiB process. Reservations include CPU caches, upload
scratch and conservative hardware/system-buffer copies; these are not measured
VRAM occupancy. Machine-wide configurable memory limits and indexed source
geometry were not added. Per-controller draw limits are not a global FPS target.

## Exact candidate and tests

Final generated script SHA-256:
`a7f11f2d960cc0eae26f3a4a41ce5271d4f8527c6b074b0e0ee527da171efce6`.

Build receipts:
- `build/viewport-0816-20261013-01/native-2026-01/receipt.json`
- `build/viewport-0816-20261013-01/native-2027-01/receipt.json`

Final isolated hosts:
- `build/mcp-qualification/foundation-viewport0816-max2026-02`
- `build/mcp-qualification/foundation-viewport0816-max2027-02`

Each launcher checked every recorded source/binary hash and rejected mixed
loaded module paths. `build/viewport-0816-20261013-01/delivery-evidence.json`
records the exact module hashes, script, profile preservation and test counts.
Native compilation and 28 CTest checks pass for each SDK year. Generator/layout
checks pass with 252 inventoried controls. The Python suite had 160 passes and
one outdated control-count assertion; updating the assertion from 249 to 252
and rerunning that test passed. No product test was waived.

Each final host passes 15 policy checks, 17 retained-publication checks and 49
atomic-publication checks. These cover independent totals across two layers,
navigation greater than idle, zero in all three representations, oversized
sources, Manual pending edits, bounded emergency drawing, setting persistence,
native admission failure/recovery and unchanged sibling buffer reuse.

The Max 2027 terrace run passes another **58 navigation checks plus 10 recovery,
UI and persistence checks**. It uses a copied nine-layer input from
`Test Scene/Terraces_0815/Terraces_0815_Final.max`, SHA-256
`54b006f2cd40183bcdb048d3ab040eaee066ad67728d5e3b76b381685ab65801`.
All **245,664** accepted placements retain their exact identity/transform
fingerprints. The original scene and both artist profile hashes remain unchanged.
Only the owned copy was saved as `Terrace_0816_verified.max` in the final host.

## Terrace observations

At 2,000,000 idle / 500,000 navigating Mesh triangles, native quotas are
**1,998,120 / 499,346**. Cached bounds keep oversized sources represented; 9,591
box instances occur in each phase at these settings. The full cached placement
stream references 6,484,693,331 triangles, while the draw quota determines actual
work. It does not submit that virtual total each frame.

Across 180 warm camera steps in two reversed-order passes through all modes:
- No placement solve, prepared-input rebuild or preview rebuild.
- No retained preparation/revision change, new upload or native failure.
- No CPU fallback and no retained Mesh memory growth.
- Navigation and return-to-idle draw paths both execute automatically.

At zero/zero Mesh limits, full geometry exceeds retained admission. The plugin
successfully draws cached boxes for all 245,664 instances: 2,947,968 triangles in
each phase. It reports the reduction, remains GPU-ready, and submits no CPU
source triangles. Returning to finite limits recovers admitted full geometry.
The final unlimited switch took 0.479 seconds. Real rollout handlers accepted a
navigation value and zero idle value, and terrace save/reopen preserved settings
and all accepted identity/transform fingerprints.

A separate 80-step/window comparison measured these median synchronous redraw
wall times on the owned Max 2027 host (1302 x 750 viewport):

| Mode | Scripted redraw median |
| --- | ---: |
| Scatter preview off, navigating | 42.96 ms |
| Point Cloud, navigating | 41.58 ms |
| Proxy, navigating | 40.59 ms |
| Mesh, navigating | 41.04 ms |
| Mesh, idle | 48.17 ms |

These timings include Max's existing scene and message processing. Differences
around the baseline are within the uncontrolled desktop workload; they are not
an isolated speedup claim. The earlier two-pass Mesh navigation medians were
44.61 and 46.07 ms. First Mesh mode preparation took 1.39 seconds; an unchanged
Mesh mode switch took 0.283 seconds. Cold scene load, initial calculation and
first whole-scene redraw still took 15.32, 7.23 and 21.41 seconds respectively.
This change does not eliminate cold scene/asset initialization.

PresentMon 2.6.0 captured 964 presentation events in the final attempt. Windows
refused foreground activation of the owned test window and only 4–9 display
intervals were available per measured window. The sparse/occluded composition
trace cannot establish presented FPS. Raw CSV, exact QPC windows and
`present-summary.json` preserve this limitation. Actual artist interaction,
device loss, prolonged sessions and broad hardware/material combinations remain
acceptance gates. Max 2026 received the focused policy/publication tests, not the
full terrace performance campaign. No new render/material qualification is
claimed.

## Corrections made during testing

1. The first compile found an int/size_t mismatch after widening triangle
   diagnostic counters. It was fixed; `build-failed-01.log` preserves the result.
2. The first candidate rebuilt source snapshots when Mesh limits changed. An
   unlimited-to-finite switch exhausted the process allowance while older GC
   caches remained alive. Separating Mesh geometry keys from draw limits fixed
   this; the final host repeats the recovery successfully.
3. The extra test initially inspected a transient native owner immediately after
   save had correctly removed it. Moving the expected-placement capture before
   save fixed the fixture. The failed fixture receipt is preserved separately.

The maintained UI template/generators, native display, catalog, artist guide,
architecture, version table and website source explanations are aligned. Website
source import and verification pass; no website build or live publication was
performed.
