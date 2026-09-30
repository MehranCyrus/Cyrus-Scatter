# Landing page claims matrix

This register controls public copy, videos, badges, captions, trial wording and sales material. **Default: HOLD.** Source presence is not approval of the complete user workflow.

Use [feature inventory](03_Product_Feature_Inventory.md), [support matrix](07_Product_Support_Matrix.md), [media register](13_Presentation_Asset_Production.md) and [content plan](14_Landing_Page_Content_Plan.md).

## How to use it

1. Attach a claim ID to each proposed statement/media item.
2. Record exact supporting build, test, scene, environment and result.
3. Write the narrow wording the evidence actually supports.
4. Engineering reviews technical scope; the owner approves publication.
5. Recheck after relevant product, host, renderer, entitlement or offer changes.

**Evidence labels:** VERIFIED IN SOURCE; VERIFIED BY TEST; DOCUMENTED BUT NOT VERIFIED; PROPOSED; UNKNOWN; REQUIRES MANUAL 3DS MAX TEST.

**Claim approval states:** HOLD / READY FOR REVIEW / APPROVED / RETIRED. These are copy-approval states, not the Stage 02 manual-test results. All product-value claims below remain HOLD.

## Current register

The allowed wording column is a future narrow wording boundary unless it explicitly says internal/development fact. It does not grant permission to publish.

| ID / claim topic | Current evidence | Proof required / controlling row | Wording boundary | Blocked wording | Approval |
|---|---|---|---|---|---|
| CL01 Lead landscape/revision workflow | PROPOSED positioning; source controls present | Qualified S02/S04 and beta repeat-use evidence | Name the tested task and scope | “Essential for every artist/studio”; universal best tool | HOLD |
| CL02 Count/seed/repeatability | VERIFIED IN SOURCE; Core + narrow smoke | MT04/05; F02; exact build/settings | Repeatable setup for unchanged inputs on tested build | Bit-identical on every host/compiler; every requested count always emitted | HOLD |
| CL03 Density/map variation | VERIFIED IN SOURCE; numeric core tests | MT06/07; F03/04, units/UV1 | Tested physical density and UV1 texture-density workflow; explain filtering | Arbitrary shader support; unlimited-resolution density | HOLD |
| CL04 Area/falloff | VERIFIED IN SOURCE; core/falloff tests | MT11/12; F14/19/20 | Tested pivot masking and edge ramp behavior | Exact mesh trimming/clipping; all final edits automatically constrained | HOLD |
| CL05 Street/edge placement | VERIFIED IN SOURCE; Edge/Orient tests | MT29 + S04; F21–24 | Tested ordered rows, spacing/offsets and input limitations | Guaranteed exact corner count or general civil solver | HOLD |
| CL06 Surface Analyzer | VERIFIED IN SOURCE; Analyzer tests | MT28 + S05; F38/39 | Eligible open planar input, tested path/point output | CAD precision, volumetric/general terrain analysis | HOLD |
| CL07 Analyzer exports | VERIFIED IN SOURCE; UI commands | MT30; F40 | Tested snapshot spline/helper output | Live bidirectional round trip; unimplemented USD export | HOLD |
| CL08 CS Edit mutations | VERIFIED IN SOURCE; broader old guide unverified | MT19–25; F35/36 | Tested per-instance move/rotate/scale/clone/delete/undo | All actions certified because an empty modifier loaded | HOLD |
| CL09 Edit persistence/invalidation | VERIFIED IN SOURCE; empty-stack persistence only | MT26/27 nonempty + legacy fixture; F37 | Edits persist under stated build/base-identity conditions | Edits survive arbitrary seed/source/layer/topology changes | HOLD |
| CL10 Max compatibility | VERIFIED BY TEST: Max 2027.1 narrow batch smoke; targets 2024–2027 | Exact version rows in Stage 07 | Internal/development fact: “Max 2027.1 batch smoke passed on 2026-09-28”; qualified support wording requires full suite | “Supports Max 2024–2027” today; every 2027 update automatically supported | HOLD |
| CL11 Production renderers | VERIFIED IN SOURCE: PFlow/Corona handling; no retained actual render | MT32 per renderer/build; production rows | Name only qualified renderer/build/mode | “All renderers supported”; V-Ray/Corona certification inferred from vendor docs | HOLD |
| CL12 IR/farm/Deadline/workers | Source timer/transport; PROPOSED farm policy | MT33, actual command-line/farm/Deadline/licensing rows | Exact tested IR or worker combination | Universal IR/farm support; free nodes already implemented | HOLD |
| CL13 Preview/proxies | VERIFIED IN SOURCE; narrow box/cache smoke | MT17; Point Cloud/Proxy/Mesh and source-transform cases | Tested display modes and budgets; separate viewport shapes from renderer proxies | Full material preview, every renderer proxy or guaranteed FPS | HOLD |
| CL14 CPU multithreading | PROPOSED; no product executor found | Implemented backend + correctness/responsiveness/performance evidence | Describe only a delivered, measured backend | “Multithreaded” as an existing product feature | HOLD |
| CL15 GPU/OpenCL | PROPOSED; no product backend found | Feasibility, implementation, parity and fallback qualification | Named delivered backend/device/operation if later proved | “GPU accelerated,” “all GPUs,” or GPU rendering implies GPU placement | HOLD |
| CL16 Speed/FPS/benchmark | UNKNOWN comparative result | S07 protocol/raw data, matched builds/workloads | Exact measured operation, configuration, count and spread | Invented speedup; “millions at 60 FPS”; only best sample shown | HOLD |
| CL17 RAM/minimum hardware | Required 32 GB target; not qualified envelope | Real 32 GB S07 including renderer peak; OS/hardware rows | Tested workload envelope on named configuration | 32 GB sufficient for every scene/render; all hardware compatible | HOLD |
| CL18 Trial/offline/transfer | PROPOSED, no authority implemented | Approved Stage 09 terms + Stage 10/11/12 tests | Exact delivered duration/recovery/offline restrictions | Trial ready; permanent offline/activation allowance assumed | HOLD |
| CL19 Price/perpetual/maintenance | UNKNOWN final price; PROPOSED model | Owner Stage 09/15 decision and tested eligibility | Exact approved offer/currency/rights/update period | Invented price; lifetime updates/support; unconditional perpetual continuity | HOLD |
| CL20 Scatter bake/USD | Bake code exists; creation UI absent; USD PROPOSED | Guided MT31 + future UX/authority/output test | Tested evaluated bake only if accessible/qualified | Bake available from a nonexistent button; USD export delivered | HOLD |
| CL21 Superiority/time saved/ROI | UNKNOWN; no matched competitor task or customer result | Stage 06 matched task + beta data | Attributed, consented and scoped measured result | “Faster/better than ForestPack/Chaos”; invented studio savings | HOLD |
| CL22 Studio/enterprise/SLA | PROPOSED | Approved offer + floating/air-gap/admin/support operational tests | Exact qualified seat/support deployment | Enterprise ready, on-prem/SLA promise without operations | HOLD |
| CL23 Huge populations/layer limits | VERIFIED IN SOURCE: ten layers and bounded paths | Actual emitted/displayed/rendered counts, S07 memory/lifecycle | Stated path/workload and counts | Unlimited layers/counts; point display count equals final instances | HOLD |
| CL24 Package security/availability | Fresh hashes/ZIP checks; licensing/signing/paid delivery UNKNOWN | Final signing/release/delivery tests and owner availability decision | Internal fact: named development MZPs exist and passed integrity checks | Hash equals publisher authentication; paid/trial release available now | HOLD |

## Claim approval card

~~~text
Claim ID:
Exact proposed public wording:
Placement: page / video / caption / badge / sales:
Evidence label and exact test/scene/log:
Build/package hash, Max/renderer/hardware:
Manual result and qualification scope:
Known limitations shown with the claim:
Asset ID / rights:
Technical reviewer/date:
Owner approval/date:
Approved wording:
Retest/review trigger:
Approval state:
~~~

## Rule for partial evidence

A mathematical test, empty-modifier smoke or vendor feature can support a narrow factual statement about that evidence. It cannot support an entire artist workflow or compatibility promise. Keep narrow development facts clearly labelled and approved separately.

Do not convert NOT TESTED into NOT APPLICABLE to make a support badge pass. Required Max 2024–2027 ports and 32 GB qualification remain tracked even if an earlier beta uses less scope.

## Initial status

No final public claim has been approved by this documentation task. Use actual observations from the walkthrough before changing a HOLD row.

