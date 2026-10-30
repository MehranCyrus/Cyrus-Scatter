# Measurements and decisions — 0.87.6.1

All runtime measurements use owned Max 2027 profiles on the same Ryzen 5 5600X
(6 cores / 12 logical processors) and RTX 3090. The comparison payload is the
exact 0.87.6 installer-r2; 0.87.5.6 remains the artist-endorsed response reference.
The final candidate is 0.87.6.1. See [machine-readable evidence](QUALIFICATION.json)
and `evidence/` for identities and raw samples. Native fit, CPU redraw and displayed
ticket readiness are different measurements. None is a physical mouse FPS claim.

## UI

The real Band-assignment handler reproduced a Point caption that stayed
Unassigned after assignment. The candidate refreshes the Models page immediately.
A setting changed while its panel was closed was also current on reopening.
The final packaged pair repeats those two checks.

For repeated warm opens across fourteen panels, the baseline performed 84 binds,
12 layouts and 19 list updates. The candidate performed zero binds, zero layouts
and one list update. Placement epoch stayed 2; placement/publication counters did
not advance. Mounted views are reused only while owner and revision remain valid.

| Warm opening | Before median | After median |
| --- | ---: | ---: |
| Layout | 592.6 ms | 413.1 ms |
| Layers | 398.2 ms | 302.3 ms |
| Models | 345.5 ms | 308.3 ms |
| Source containers | 250.6 ms | 182.4 ms |
| Viewport | 306.2 ms | 256.6 ms |

The full panel table is in the receipt. These include a requested message-pump
delay. Native Max rollout reflow still costs time. Cold construction and visual
flicker under physical input were not independently measured; reduced rebinding
does not establish that every possible flash is gone.

## 1. Work that cannot change the result

The same saved sixteen-tree fixture and eighteen-step stone path were replayed
for each response. Medians/p95 below exclude the first two samples.

| Response | Before median / p95 | After median / p95 | After contact queries |
| --- | ---: | ---: | ---: |
| Bend | 49.54 / 57.72 ms | 44.62 / 49.96 ms | up to 3,401 |
| Fixed base 100%, Bend only | 16.17 / 22.42 ms | 6.32 / 6.88 ms | 0 |
| Bend strength 0 | 13.74 / 20.98 ms | 6.54 / 7.75 ms | 0 |
| Fixed base + Trim | 6.92 / 7.83 ms | 6.82 / 7.14 ms | up to 1,106 |
| Bend 0 + root hiding | 7.65 / 12.63 ms | 6.33 / 7.23 ms | 0 bending queries; coverage remains separate |

The fixed and zero-strength cases remove a demonstrated waste (about 61% and
52% lower median fit time here). Ordinary Bend guide counts match across all
eighteen samples. Its smaller timing difference is not claimed as a general
speedup. Native regressions check independent Trim/coverage and move-away state.

## 2. Branch selection and parent motion

The new per-guide gate uses response, strength, fixed height and guide bounds.
It skips local contact only when neither Bend nor Trim can act. A guide with a
moving parent still inherits the parent pose, including a child below the fixed
height. The added native regression covers that non-obvious case. No new spatial
branch hierarchy was added; finer rejection remains a measured follow-up target.

## 3. Cheaper colliders

An 84-triangle stone gave 41.94 ms median fit; a 12-triangle box proxy gave
42.95 ms on the same path (fourteen warm samples). Both affected nine plants.
The proxy was **not adopted as a general optimization**.

Separately, the supplied Rock_10 visual mesh has an open bottom and cannot serve
as a closed solid. The saved landscape explicitly assigns a 140-triangle closed
convex envelope to that 752-triangle visual mesh. This is an asset-admission
choice, not a performance result. Convex envelopes bridge openings; doorway,
root-gap and other concave assets need an appropriate separate shape.

## 4. Distant vegetation

| Setup | Local affected maximum | Median / p95 fit |
| --- | ---: | ---: |
| 16 local trees | 9 | 43.27 / 52.67 ms |
| Plus 1,000 distant reacting trees | 9 | 53.07 / 61.72 ms |
| Plus 10,000 distant reacting trees | 9 | 50.73 / 62.31 ms |
| Two nearby colliders | 11 | 43.40 / 49.28 ms |

The local set and single-collider query maximum (3,387) stay the same with the
distant population. Total fit cost does not stay identical. This supports local
contact selection, not constant-time scaling. The saved 10,000-distant fixture
is separate from the landscape. Accepted counts were explicitly checked; an
initial fixture with inherited Paint restrictions accepted no distant instances
and was corrected before these results were recorded.

## 5. Held movement and hitches

A 40 ms requested host timer performs twelve movements followed by twelve orbit
steps. The held-input predicate stays true during the test. Ordinary scene motion
presents ten distinct sampled tickets during movement; Cyrus Edit presents twelve.
Final requested/presented tickets match (29/29 and 54/54, ready state 2).
Native fit median/p95/max is 41.25/51.16/86.33 ms for ordinary motion and
40.59/51.31/52.15 ms for Edit. A requested timer interval is not a guaranteed
update rate. Source Scale changes after Edit also passed their recorded check.

In the final landscape, twelve Hero-boulder Edit moves publish twelve new contact
generations with no layer errors. Native fit median/p95/max is
**17.85/19.42/20.52 ms**. There are 160 prepared grass placements and 22 stone
colliders in this controller; the rest of the garden is static planting. These
numbers do not mean all 18,229 garden instances are bending simultaneously.

The landscape test harness initially created duplicate Edit modifiers and stale
feedback while rebuilding the test setup. Those attempts are retained separately.
After removing the duplicate, saving/reloading and using the real Edit modifier,
the complete movement replay passed. No production guard was bypassed or relaxed.
This campaign did not instrument every transient allocation or run a long soak.

## 6. Navigation and practical draw budgets

The planted garden was orbited for 24 scripted steps at each budget:

| Budget | Idle mesh triangles | Navigating triangles | CPU redraw median / p95 |
| --- | ---: | ---: | ---: |
| Light | 8,500,744 | 903,656 | 17.12 / 20.25 ms |
| Balanced | 24,569,988 | 4,496,845 | 14.67 / 16.81 ms |
| Detail | 40,601,757 | 8,500,744 | 14.93 / 16.58 ms |

All three retain unchanged placement epochs, unchanged contact-work counters and
zero deltas in all nine stream-upload counters. Static orbit of the separately
posed real-tree fixture also leaves contact work unchanged. CPU timings are not
monotonic with triangle counts; they do not prove a GPU frame-rate improvement.
The small automated host viewport differs from the artist's full-size viewport.

An earlier combined preview of roughly 104 million triangles exceeded the
existing 2 GiB device-resource fallback allowance after rendering. The final
scene uses finite per-controller budgets: woodland 10M idle / 2M navigation,
others 6M / 1M. The allowance is plugin admission, not the physical 3090 VRAM
capacity. Native estimates of live/device bytes are estimates, not measured
process peaks or GPU residency. Full automatic rendering retains all planting.

## Decisions and remaining limits

Keep the guide skip and UI invalidation/reuse changes. Keep explicit finite draw
budgets for the artist scene. Do not add a blanket box/convex conversion, new
solver, extra threads or GPU compute on the basis of these results. Further work
should target observed worst updates, total-population overhead, finer branch
selection and graphics submission separately.

Max 2027 passed 62/62 native tests plus the listed host checks. The three-host
EXE passed archive/source/payload verification; Max 2024/2026 were not launched.
The garden image is a scoped Corona visual check, not renderer equivalence or
qualification of arbitrary materials. Unrelated roadmap work, physical mouse
latency, million-instance realtime, device loss and long-session memory remain
outside this acceptance. Original receipts and failed setup probes are retained.
