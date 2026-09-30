# Cyrus Scatter — your commercialization playbook

**Prepared 2026-09-30. Start with [Stage 01](01_Understand_the_Current_Product.md).**

This is your working guide for taking responsibility for the product. Open one stage, do your tasks, record the result, and follow its next-stage link. The engineering specifications already exist; these pages explain what you need to do with them.

The current product is a development build with useful implemented features and limited retained runtime evidence. This playbook does not authorize public compatibility, performance, licensing, or pricing claims merely because they appear in a plan.

## Your first three actions

1. Open Stage 01 and write down your Max update/build, renderer/build, and the exact two installer filenames. If the plugins already load, record that and continue.
2. In a disposable new Max scene, make a 10 m plane, a small box source, and a 200-instance scatter using the verified UI names in [Stage 02](02_Manual_Product_Walkthrough.md). Save a scene and a screenshot.
3. Reopen that scene, record the actual result in Stage 02, and add one entry to [the progress log](99_Progress_Log.md). Report a specific failure with its reproduction instead of trying to finish every test in one sitting.

No business decision is needed to begin these actions.

## Reading order and outputs

| Stage | Open this file | What you finish with |
|---|---|---|
| 01 | [Understand the current product](01_Understand_the_Current_Product.md) | One-page explanation and environment record |
| 02 | [Manual product walkthrough](02_Manual_Product_Walkthrough.md) | Your own test results, scenes and screenshots |
| 03 | [Feature inventory](03_Product_Feature_Inventory.md) | A maintained feature/readiness table |
| 04 | [Problems and missing pieces](04_Problems_and_Missing_Pieces.md) | Reproductions and a prioritized issue list |
| 05 | [Define the product](05_Define_the_Product.md) | Primary user, promise and three lead workflows |
| 06 | [Competitors and positioning](06_Competitor_and_Positioning_Review.md) | Evidence-based task comparison |
| 07 | [Support qualification](07_Product_Support_Matrix.md) | Exact configurations we can demonstrate or advertise |
| 08 | [Demo and benchmark scenes](08_Demo_and_Benchmark_Scenes.md) | Seven reusable scene briefs and build records |
| 09 | [Commercial decisions](09_Commercial_and_Licensing_Decisions.md) | Owner decision sheet with unresolved items visible |
| 10 | [Licensing technical preparation](10_Licensing_Technical_Preparation.md) | Scoped engineering brief and capability policy |
| 11 | [Provider evaluation](11_Licensing_Provider_Evaluation.md) | A later experiment plan and evidence-based selection record |
| 12 | [Beta readiness](12_Beta_Readiness.md) | Go/no-go decision and a small pilot plan |
| 13 | [Presentation asset production](13_Presentation_Asset_Production.md) | A practical shot list and approved media |
| 14 | [Landing page content](14_Landing_Page_Content_Plan.md) | Section briefs, proof links and draft copy |
| 15 | [Pricing and offer](15_Pricing_and_Offer_Preparation.md) | Cost/offer worksheet and owner decision |
| 16 | [Commercial launch](16_Commercial_Launch_Readiness.md) | Release checklist, delivery/recovery evidence and launch decision |

Also use [00 — Master checklist](00_Master_Checklist.md), [the claims matrix](Landing_Page_Claims_Matrix.md), [98 — Repository review and exact deliverables](98_Repository_Review_and_Deliverables.md), and [99 — Progress log](99_Progress_Log.md).

## How to record evidence

Two different status systems serve different purposes.

**Evidence labels**

| Label | Meaning |
|---|---|
| VERIFIED IN SOURCE | The inspected implementation supports the statement; user experience still needs testing |
| VERIFIED BY TEST | A named retained test/result supports the statement within its exact scope/date |
| DOCUMENTED BUT NOT VERIFIED | A document reports it; adequate supporting evidence has not been established here |
| PROPOSED | A future feature, policy, experiment or recommendation |
| UNKNOWN | Information has not been established |
| REQUIRES MANUAL 3DS MAX TEST | Interactive, scene or renderer behavior you must exercise in the stated configuration |

**Your result labels**

Use WORKS, PARTIAL, BROKEN, NOT TESTED, NOT APPLICABLE, or UNCLEAR. WORKS requires the expected result in a named build/configuration. NOT APPLICABLE requires a reason and a scope decision; an unavailable renderer is normally NOT TESTED. UNCLEAR is useful when a control or expected behavior cannot be understood.

Tables start untested unless they explicitly cite retained evidence. Your stage is complete when its completion criteria are met. Stage 02 can be complete with recorded failures; outside beta and paid release have stricter gates.

For each observation keep: test ID, date, operator, host/renderer/build, scene, action, expected/actual result, status, evidence path, and next action. Put screenshots/video/scenes in a folder you choose, such as **build/commercialization-review/2026-09-30/**. This is a suggested future evidence location, not an existing demo kit. Record paths as text until files exist.

## Responsibilities

**MY TASKS:** use Max, observe workflows, preserve evidence, coordinate fixes, draft presentation, and maintain decisions.

**CODEX / ENGINEERING TASKS:** diagnose source behavior, build fixtures, fix confirmed defects in a separately authorized implementation task, measure operations, qualify packages and implement approved licensing.

**BOSS / BUSINESS DECISIONS:** product scope, paid terms, price, vendor purchase, public release and support commitments. The stage worksheets prepare concrete decisions; they do not mean approval has already been given.

**OPTIONAL / LATER:** useful expansion that is outside the current completion gate.

## Which documentation is authoritative?

Follow this precedence:

1. Current source and observed tests, with exact evidence limits.
2. [Product Strategy 2026-09-29](../Product_Strategy_2026-09-29/README.md).
3. This dated operational playbook.
4. [Performance roadmap](../Performance_Roadmap_2026-09-28/README.md).
5. [Licensing implementation package](../CyrusScatter_Licensing_Implementation_Package_2026-09-27/README.md).
6. [Complete codebase documentation](../CyrusScatter_Complete_Codebase_Documentation_2026-09-27/README.md).
7. Older historical research.

Use [the installation guide](../Max_2027_Installation.md) for the delivered 2027 test packages. It is an operational reference whose factual claims still depend on source/tests.

When documents disagree, record both statements and the deciding evidence in [98](98_Repository_Review_and_Deliverables.md) or the progress log. Preserve historical documents. A test from an older build is never automatically promoted to current production support.

## Scheduling the journey

Do 01–04 first, using several short Max sessions. Draft 05–08 while engineering addresses confirmed problems. Prepare decisions in 09–11, then use 12 to choose a controlled feature beta or a later licensing beta. Raw screenshots can be collected early; polished presentation follows qualified workflows. Stage 14 prepares content only; pricing from 15 and all release gates from 16 are required before public purchase/download promises.

The governing engineering assignment remains [Baseline and Trust](../Product_Strategy_2026-09-29/12_First_Implementation_Milestone.md). This review created documentation and checked existing artifacts. Product source, algorithms, UI, Class IDs, schemas, licensing and website implementation were not changed.

