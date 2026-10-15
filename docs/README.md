# Cyrus Scatter documentation

Use this small set for the current codebase. Update it in place instead of creating another competing handoff or roadmap.

| Question | Document |
| --- | --- |
| How should the browser landscape studio and exported presentation work? | [Presentation-only Three.js/Vite MVP plan](plans/landscape-presentation/README.md) and [dated research](plans/landscape-presentation/RESEARCH_2026-10-15.md) — documentation only; implementation has not started; existing website remains separate |
| How should evaluated Max data, masks and portable multi-layer recipes connect? | [Sourced architecture study, proposed recipe data and validation plan](Scatter_Data_Recipes_Research_2026-10-15/README.md) — dated research; current recipe/browser implementation is recorded in [0.82.6.1](plans/improvement-program/I03_08261.md); the remaining program resumes Phase 6 |
| Which GitHub research tools do we have, where are they, and how can a new conversation continue? | [Nine-project tool inventory, local paths, documentation and handoff](GitHub_Tools_Inventory_2026-10-15/README.md) |
| How do I use the current development version? | [Artist guide](ARTIST_GUIDE.md) |
| How do I install and manually test the completed first five phases? | [0.82.6.1 Max 2027 installer instructions](Max_2027_Installation.md), [phase-by-phase artist checklist](plans/eleven-phase-roadmap/ARTIST_ACCEPTANCE_0822.md) |
| How do Layout, Analyzer and falloff controls interact? | [Detailed feature reference](LAYOUT_AND_FALLOFF.md) |
| Who owns data and where is the implementation? | [Architecture](ARCHITECTURE.md) |
| Which principles guide behavior and engineering decisions? | [Engineering foundation](ENGINEERING_FOUNDATION.md) |
| What is changing in current source 0.82.6.1/schema 58? | [I03 recipe library, thumbnails and four examples](plans/improvement-program/I03_08261.md); preceding [I01/I02 panel performance and diagnostics](plans/panel-performance-0826/PROGRESS.md); preceding [Complete static recipes including Paint](plans/recipes-0825/PROGRESS.md); preceding [Mesh channel density and Paint help](plans/eleven-phase-roadmap/MESH_MASK_0824.md); preceding [Idle and panel performance correction](plans/eleven-phase-roadmap/PERFORMANCE_0823.md); preceding [Phase 5 Paint/spline conversion](plans/eleven-phase-roadmap/P05.md); preceding [Phase 4 density mapping](plans/eleven-phase-roadmap/P04.md); preceding [Phase 3 slope and altitude](plans/eleven-phase-roadmap/P03.md); preceding [Phase 1 feedback](plans/eleven-phase-roadmap/P01.md); preceding [Zero-limit points and mode switching](plans/terrace-0815/VIEWPORT_0817.md); preceding [Adaptive viewport limits and fallback](plans/terrace-0815/VIEWPORT_0816.md); preceding [Terrace scene, capacity and performance evidence](plans/terrace-0815/PROGRESS.md); preceding [Spline Bands implementation evidence](plans/spline-bands/PROGRESS.md) |
| What did the preceding publication/units correction establish? | [0.79.6 bounded historical foundation evidence](Foundation_0.79.6_2026-10-12/README.md); old-schema migration is retired in 0.80.0 |
| What is unfinished or next? | [Current backlog](BACKLOG.md) |
| What is the authorized eleven-phase improvement program? | [Implementation roadmap](plans/eleven-phase-roadmap/README.md), [phase specifications](plans/eleven-phase-roadmap/IMPLEMENTATION.md), [validation](plans/eleven-phase-roadmap/VALIDATION.md) and [live TODO](plans/eleven-phase-roadmap/TODO.md). The [Forest-informed improvement plan](plans/eleven-phase-roadmap/FOREST_IMPROVEMENTS.md) ranks 18 proposed steps by difficulty, with performance/testing gates; I01/I02 are implemented in [0.82.6](plans/panel-performance-0826/PROGRESS.md), I03 is delivered in [0.82.6.1](plans/improvement-program/I03_08261.md). The [active goal/ledger](plans/improvement-program/PROGRESS.md) resumes Phase 6 and tracks remaining features, presets and EXE. |
| Why were source rectangles slow to create or select? | [0.81.3 investigation](Source_Containers_Performance_2026-10-13.md) and [0.81.5 compact-panel correction and measured limits](plans/terrace-0815/PROGRESS.md) |
| How are alternative brush architectures being compared? | [Four standalone painting trials](../experiments/paint-methods/README.md) — isolated results and known failures; vector A selected for integration |
| How do I install/build? | [Max 2026/2027 installation/build](Max_2027_Installation.md) |
| How should code changes be tested? | [Agent workflow](AGENT_WORKFLOW.md) |
| What changed in 0.79.5? | [Latest creation-icon correction](Terrace_Workflow_0.79.5_2026-10-11/CREATION_FIX.md); [terraced garden, partial preview reuse and original host results](Terrace_Workflow_0.79.5_2026-10-11/README.md) |
| What changed in 0.79.2? | [Layer cache ownership, navigation and Manual radius fixes](Layer_Navigation_0.79.2_2026-10-11/README.md) |
| What changed in 0.79.1? | [Point workflow, source controls and falloff qualification](Point_Workflow_0.79.1_2026-10-11/README.md) |
| What happened to layers and Point/model sources? | [0.79.1 layer investigation](Point_Workflow_0.79.1_2026-10-11/LAYER_INVESTIGATION.md): confirmed Manual display-cache defect; Live picker report remains open |
| Why can the point-example scene navigate slowly? | [0.79.1 navigation measurements](Point_Workflow_0.79.1_2026-10-11/NAVIGATION_PERFORMANCE.md): radius overlays and layer checks, with unchanged placement/upload caches |
| What was actually tested? | [0.79.5 coverage](Terrace_Workflow_0.79.5_2026-10-11/COVERAGE.md), [241-control register](Terrace_Workflow_0.79.5_2026-10-11/CONTROL_REGISTER.md), and historical [0.75 results](System_Qualification_0.75_2026-10-09/README.md) |
| How did the features work together in a landscape? | [Courtyard scene, painting/layout checklist and performance study](Courtyard_Study_0.75_2026-10-09/README.md) |
| What did we fix after that study? | [Retained Proxy, Update and Analyzer fixes, measurements and matched packages](Courtyard_Fixes_0.75_2026-10-10/README.md) |
| What is in the 0.78 vector integration? | [Vector brush, clean schema, curves and qualification](Vector_Brush_0.78_2026-10-10/README.md) |
| What fixes rectangle selection and brush radius? | [0.78.3 container controls, painting layout and cursor sizing](Container_and_Radius_0.78.3_2026-10-10/README.md) |
| What improves drawing responsiveness? | [0.78.2 drawing measurements and qualification](Brush_Responsiveness_0.78.2_2026-10-10/README.md) |
| What changed in 0.76 receiver sampling? | [Receiver stability, research, qualification and matching packages](Receiver_Stability_0.76_2026-10-10/README.md) |
| What preceded receiver stability? | [Bounded Brush preparation and faster history indexing](Brush_Scaling_0.76_2026-10-10/README.md) |
| What can automation do? | [MCP guide](../CyrusMCP/README.md), [capability matrix](Current_System_2026-10-05/CAPABILITY_MATRIX.md) |
| How should the website describe the product, MCP and ML roadmap? | [Current product and AI direction](PRODUCT_AND_AI_ROADMAP.md) |
| How does the separate Analyzer work? | [Analyzer guide](../CyrusSurfaceAnalyzer/README.md) |
| What is the version/delivery policy? | [Versioning](Release_Versioning.md), [workspace and backup scope](Workspace_Organization.md) |

0.79 implements the [offline team licensing pilot](licensing/TEAM_PILOT_0.79_2026-10-11.md), with matched Max 2026/2027 candidates and bounded activation/expiry/render evidence. Read its anti-bypass and host-coverage limits before distribution. The offline [Design Lab](Offline_Implementation_2026-10-05/DESIGN_LAB.md) is experimental, not an integrated production learning feature.

[History and evidence](HISTORY.md) lists prior implementation snapshots. The original paths are retained where test fixtures, frozen manifests, research or the website depend on them. Do not follow their old installation or next-task instructions as current guidance.

Website and research collections were outside the earlier codebase-documentation cleanup. The [canonical website](../website/README.md) now has its own consolidation workstream using the maintained guides and [product/AI direction](PRODUCT_AND_AI_ROADMAP.md); supplied `Landing Page Design/` variants are design references. Research remains separate from current feature claims. See [documentation maintenance](DOCUMENTATION.md) for the retention rules and cleanup record.
