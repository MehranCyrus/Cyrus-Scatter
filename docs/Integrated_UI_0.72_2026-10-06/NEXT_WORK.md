# Next work and acceptance criteria

6 October 2026. 0.72 is a development candidate. Complete the bounded UI/runtime slice before opening more abstraction, GPU-compute or ML work.

| Priority | Next loop | Acceptance |
| --- | --- | --- |
| 1 | Artist-visible UI qualification, when computer-use is permitted | Narrow/wide native columns, actual expand/collapse and scrolling, 100/125/150/200% DPI, two monitors, short tooltips, empty controller, many layers, optional popup. No hidden unused pages, overlap or unreachable fields. Repeated browsing preserves publication/preparation/upload counters. Measure cold construction and warm interaction separately. |
| 1 | Animation/draw cost measurement in the artist workload | Same saved scene copy/camera/output limits: disabled, Manual and Live; editor closed/open; Point Cloud/Proxy/Mesh. Track median/p95 CPU and presented FPS independently. Static relevant inputs permit no resampling/upload; animated sources/receivers still update. Proxy's cached immediate drawing has a real per-draw cost; optimize only a measured bottleneck. |
| 1 | Supported hosts and renderer lifecycle | Max 2026 actual runtime/install/restart, successful docked Corona IR, repeated floating/docked save/reopen/reset, mixed edits and long sessions, other intended renderers. Pin loaded binaries first. Stop failure preserves renderer-owned bridge geometry; no retry loop after a terminal failure. |
| 1 | Brush BR-01 compatibility | Reproduce signed-zero/subnormal/tiny-coordinate save/reopen identities; ordinary and transformed curved fixtures are controls. Preserve old documents and reject genuine geometry/topology changes. Do not weaken the existing guard to get a pass. |
| 2 | Reporting beyond bounded event pages | Action/batch correlation, useful failure summary, optional local searchable index. Explicit disk limits; test real denied/disk-full/interrupted exports and history loss. Keep health, provenance, sharing and training eligibility distinct. |
| 2 | Narrow policy-3 MCP authoring | Enrolled typed scope, validate/explain/local approval/apply, stable IDs, work limits, stale approval rejection, transactional failure and Undo/reopen parity. Preserve closed schemas 1/2 and cached passive readers. Add one qualified feature family at a time. |
| 3 | Render studies / artist feedback / ML pilot | Bounded jobs with asset preflight and real artifacts tied to a generation; interruption/recovery cannot count as success. Explicit accept/reject/tie/neither and dataset eligibility. Compare held-out quality/time with a useful deterministic baseline before claiming learned artistic behavior. |

Licensing remains on the separate [commercial release roadmap](../licensing/ROADMAP.md). The current default-off foundation is unchanged. No commercial entitlement, account service, trained model or unrestricted AI tool boundary is implied by 0.72.

Use this loop: pin identity → reproduce the changed and unchanged states → make the smallest correction → run affected positive/failure cases → freeze and rerun → record receipts → stop expanding that slice once its acceptance passes. A passing inventory, SDK build, mock renderer or synchronous redraw timer cannot stand in for missing runtime, image, GUI or presented-FPS evidence.
