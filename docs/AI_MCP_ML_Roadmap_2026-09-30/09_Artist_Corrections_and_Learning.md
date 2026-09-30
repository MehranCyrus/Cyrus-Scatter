# 09 — Artist corrections and learning

**Status: PROPOSED signal design. “AI completes 70–90%” is an untested hypothesis, not a planning assumption.**

## Corrections are observations with context

A correction may improve aesthetics, fix a technical defect, meet a changed brief, reduce render cost or compensate for the wrong asset. These imply different targets.

Measure unchanged instances, accepted regions, changed parameters and time saved separately. None is a universal “percentage completed.” Dense ground cover must not dominate a score just because it has more instances than the hero trees.

## Edit-to-label map

| Observed event | Possible useful signal | Ambiguity and required context |
| --- | --- | --- |
| Move | Preferred position/orientation under the same brief | Could repair overlap, path clearance, camera composition or changed intent |
| Delete | Rejected placement/source or excessive density | Budget reduction, hidden duplicates and temporary cleanup are different reasons |
| Clone | Missing local population or a repeated design motif | Preserve parent/copy lineage; a clone is not a wholly independent example |
| Source swap | Preference for source/category/size | May reflect licensing, render performance or unavailable asset |
| Count/density change | Preferred population given site and assets | Count and canopy coverage are not interchangeable |
| Scale change | Preferred scale or correction to source units | Record asset dimensions and whether unit normalization was wrong |
| Cluster change | Preferred source grouping or positional density pattern | Record which semantics changed; current source diversity is not positional clumping |
| Boundary correction | Wrong region/mask or desired clearance | Geometry repair should train validation/zoning, not taste |
| Undo/rejection | Proposal not accepted | Can mean experimentation, accidental action or unrelated scene work |
| Final acceptance | Whole-layout preference under a brief | Acceptance threshold, deadline and degree of manual work remain relevant |
| No interaction | Unknown | Do not label as approval |
| Save/close scene | Workflow event | Does not prove design acceptance |

Ask for an optional lightweight reason such as composition, density, clearance, wrong asset, performance, changed brief or other. Never require per-point explanation to use the plugin.

## Identity is a prerequisite

**VERIFIED IN CURRENT CODE:** CS Edit has internal base/copied-row identity and signature handling, but the public script selection path uses visible row numbers. The existing [edit stack](../../AminScatter/src/cyrus_edit_stack.inc) and [storage](../../AminScatter/src/cyrus_edit_storage.inc) do not provide the proposed automation event contract.

**PROPOSED:** events reference scene epoch, controller/layer ID, generation, stable instance ID and before/after revisions. Clone events record parent identity. Source removal/replacement preserves semantic correspondence or declares it broken.

If generation changes invalidate instance matching, emit a parameter or layout-level event. A nearest-neighbor guess is not ground truth. Store any inferred mapping separately with a method and uncertainty, and exclude low-confidence matches from supervised labels.

## Three useful learning targets

1. **Parameter preference:** given pre-edit context and a valid proposal, predict a bounded direction or range for density/scale/spacing. Compare with per-studio medians and nearest-recipe defaults first.
2. **Pairwise layout ranking:** among two valid layouts for the same brief, predict the explicitly preferred one. Preserve ties and insufficient-information labels.
3. **Candidate ranking:** among feasible placements or moves under the same context, rank explicit accepted alternatives. Selection bias must be documented.

Supervised imitation of edit sequences is a later option. It needs meaningful action identity, a stable state representation and proof that sequencing adds value over a simple final-parameter predictor.

## Weak labels and selection bias

Artists only edit what they notice or what matters. Untouched points are not universal positive labels; deleted points are not universal negatives. The assistant's own candidate generator determines what was available to judge.

Record which candidates were shown, how they were sampled, and selection propensity when known. Separate explicit ratings from inferred labels. Do not fabricate propensities or claim an unbiased causal effect from opportunistic edits.

Training on corrected output while using final state as an input leaks the answer. Features must represent the context available when the prediction would be made.

## Personalization levels

| Level | Initial method | Permission / isolation |
| --- | --- | --- |
| Current session | Remember an explicitly stated density/style preference | Artist can inspect/reset it; no training required |
| Individual artist | Saved editable settings and preferred recipes | Local opt-in; no hidden behavioral profile |
| Studio | Curated shared recipes, then optional small ranker | Studio approval, project permissions and separate index/model |
| Global product | Aggregated consenting research dataset | Explicit separate permission and rights review |

The first useful personalization may be a settings profile, not a learned model. Distinguish a persistent preference from an instruction for one project.

## Proposed review pipeline

Raw local event → identity/revision validation → optional reason → ambiguity classification → purpose/rights check → candidate label → human spot-check → project-group dataset split → baseline comparison.

Never train automatically after every edit in an early product. Online updates can drift, amplify mistakes and make results irreproducible. Freeze a model version, evaluate it, then release it with rollback.

## Evaluation

Use held-out projects to compare:

- Explicit pairwise preference accuracy, including ties and abstention.
- Reduction in weighted correction workload per layer/region.
- Time to artist acceptance, including review and recovery.
- Hard-constraint failures and preserved manual edits.
- Performance across different studios rather than only the training studio.

**REQUIRES EXPERIMENT:** [E-09](11_Evaluation_and_Benchmarks.md) tests whether explicit correction labels improve upon saved preferences and retrieval. Reject custom learning if those simpler methods perform as well.

