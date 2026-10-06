# Candidate generation, search and learning

## The optimization object

Let context `c` contain the site, enrolled asset versions, brief, references, camera set and profile. Let recipe `x` contain permitted procedural settings and spatial annotations. Cyrus evaluates `x` under `c` into layout `L`, diagnostics `d` and images `I`. The learning system estimates preference from `(c, x, L, d, I)`.

Optimize recipes and meaningful structural choices first. Searching every plant's XYZ transform creates a much larger problem, weakens editability and risks bypassing the engine's stable identities and constraints. Specific locked/manual instances remain explicit constraints.

Feasibility is a separate gate. A model score cannot compensate for an invalid reference, missing asset, forbidden region, wrong generation image or exhausted execution budget. Underfill may be valid when disclosed by the chosen population policy; it is not automatically a crash or aesthetic failure.

## Baselines and escalation order

| Method | First use | Strength | Cost/limitation | Promotion condition |
| --- | --- | --- | --- | --- |
| Curated recipe library | Day-one baseline | Artist knowledge, explainability, no training | Limited coverage | Always retain as a control |
| Stratified or low-discrepancy variation | Initial candidate batches | Broad coverage of permitted ranges | Wastes samples in unhelpful regions without semantic constraints | Valid, visibly varied candidates at acceptable cost |
| Local mutation / interactive evolution | “More like this” | Intuitive refinement around favourites | Can collapse to one family | Better artist time-to-result than plain variation |
| Retrieval from approved examples | Reuse studio knowledge | Can work with modest data | Similarity is not approval; asset/site transfer matters | Better results than hand-selected recipes |
| Pairwise linear or small nonlinear ranker | First trained model | Directly matches comparison labels | Features can miss visual structure | Held-out calibration and blinded artist improvement |
| Preference Bayesian optimization | Expensive low-dimensional search | Models uncertainty and chooses informative trials | Mixed discrete structure and high dimensions need care | Benefit under equal render/review budgets |
| Quality-diversity archive | Preserve multiple valid styles | Offers alternatives across chosen descriptors | Descriptor choice can bias diversity; no guarantee all cells reachable | Improves useful variety without reducing acceptance |
| Personalized multimodal ranker | Rich references and sufficient data | Uses image/context signals | More data, inference cost and potential shortcuts | Beats geometry/recipe features on new projects |
| Fine-tuned recipe proposer, possibly DPO | Many valid comparison pairs exist | Learns to propose good structured recipes | Can learn syntax/data biases; not direct geometry supervision | Beats retrieval plus search on executable success and taste |
| Sequential RL | A demonstrated multi-step editing task | Can optimize action sequences | Expensive environment interaction, unstable reward and exploration | Clear advantage over bounded search and imitation |

Preference BO and BOPE are established approaches for choosing expensive designs using human comparisons; their tutorials are methodological references, not Cyrus benchmarks. MAP-Elites motivates keeping a repertoire across user-defined variation dimensions rather than returning only one maximum. [Interactive preference BO](https://proceedings.mlr.press/v108/astudillo20a.html), [BOPE tutorial](https://botorch.org/docs/v0.17.0/tutorials/bope), [MAP-Elites](https://arxiv.org/abs/1504.04909).

## Generate meaningful variation

Create recipe families from artist examples: formal edge, loose meadow, layered border, sparse specimen planting, clustered shrubs. Vary only approved dimensions within each family. Initially these may be asset weights, height/scale bands, explicit zones, spacing rules, population target and supported randomness. Unsupported clustering primitives must be marked future work rather than encoded as imaginary API fields.

Separate structural variation from stochastic repeats. A different seed is useful for testing robustness, but 1,000 seeds of one recipe do not equal 1,000 independent design concepts. Track recipe family, parent mutation, seed and site family.

Use matched seeds when comparing a specific parameter change where stable sampling permits it. Use additional seeds to test whether the preference survives stochastic variation. Avoid selecting a recipe solely because one lucky seed looks good.

## First preference model

This is the first **taste-learning** model. Keep it distinct from a technical surrogate that predicts cost/counts and from an inverse initializer that proposes recipes from desired descriptors. Qualified execution can collect technical measurements early, but those values are not aesthetic labels. The [Houdini follow-up](14_HOUDINI_ENGINEERING_LESSONS.md#three-different-learning-tasks) defines the three targets and their separate baselines. Reference-to-recipe inversion must handle multiple plausible answers and still execute the exact procedural checks.

Begin with a regularized pairwise model. A simple baseline estimates `P(A preferred to B) = sigmoid(score(A,c,u) - score(B,c,u))`, where `u` is the selected profile. A linear score over standardized features is interpretable; a small nonlinear model is the next comparison. Fit transformations using training data only.

Features should include effective settings and actual outcomes: accepted density, species/role mix, height quantiles, path/edge proximity, clustering measures, negative space, coverage, underfill and visible composition descriptors. Renderer failures never enter as low aesthetic scores. Recipe intent and actual outcome are distinct inputs.

Pin the feature contract with the model, including field order, units, missing values, preprocessing and image conventions. [E18](11_EXPERIMENTS.md#e18--feature-and-inference-parity) must pass before model promotion or changing an inference backend. ONNX and GPU inference are optional deployment experiments, not prerequisites for a small ranker.

Handle ties explicitly or exclude them from the binary baseline with a reported count; do not pretend ties are contradictory wins. “Neither” can feed a separate acceptability model if enough explicit labels exist. Missing values need missing indicators, not zeros. Weighting by reviewer/session must not let one long session dominate silently.

Use a conservative default for a new profile. Learn personal offsets or profile embeddings only when data supports them. A model can express low confidence and fall back to retrieval. Do not claim uncertainty from a raw sigmoid alone; assess calibration, disagreement and out-of-distribution behaviour on held-out data.

## Active comparison selection

Start with a transparent mixture: uncertain pairs, diverse recipe families, refinements near favourites and randomly chosen audit comparisons. A proposed pilot allocation is 40/25/25/10 percent; tune it using artist effort and improvement, not as a fixed research result.

Query uncertainty should be relevant to the current task. Comparing two unacceptable failures wastes attention. Conversely, showing only top-ranked candidates hides model blind spots. Preserve a random audit stream to estimate performance outside the model's preferred region.

Store the selection algorithm/version and candidate pool. If selection probabilities are defined, store them; if deterministic or unknown, say so. This enables analysis of selection bias and prevents later claims of unbiased off-policy evaluation without the required support.

CRED suggests constructing comparisons that distinguish plausible preferences. NAOD warns that active selection can expose residual model-judge bias. Our first experiment therefore uses human labels and tests acquisition policies before adding synthetic judge labels. [CRED](https://arxiv.org/abs/2603.08531), [NAOD](https://arxiv.org/abs/2609.38860).

## Preserve multiple good directions

An archive could organize accepted candidates by occupied area and height variation, with additional tags for formal/informal structure. These are proposed descriptors; artists must decide whether they correspond to useful choices. Keep several candidates per brief/profile rather than a single numerical champion.

Diversity can be measured in recipe space and rendered outcome space. Similar recipes may produce different appearances, while different parameters may produce near-identical images. Report both, with near-duplicate thresholds calibrated on artist judgments. More variety is not automatically better if it creates irrelevant designs.

## Where large models help

A language/vision model can interpret a brief, retrieve documented capabilities, propose a typed recipe, explain warnings and suggest an edit. Its proposal must pass the same compiler and validator as a human-authored recipe. A short grounded explanation should cite changed controls and observed outcomes; it need not expose or store hidden reasoning.

Personalized image research such as PrefGen and PreferThinker offers representation ideas, while DPPMG studies modality-specific graph representations and discrete preference tokens. These are research candidates. Their image/text generation tasks do not establish that a GNN, diffusion model or reasoning-trained judge is the best first model for editable 3D planting. [PrefGen](https://arxiv.org/abs/2512.06020), [PreferThinker](https://arxiv.org/abs/2511.00609), [DPPMG](https://arxiv.org/abs/2604.20434).

## When DPO or RL becomes appropriate

DPO can train a model that assigns probabilities to chosen/rejected recipe sequences, provided pairs share the relevant context and both recipes are valid. It does not directly optimize an arbitrary C++ scatter engine. A sequence model would still need constrained output, execution validation and held-out testing. [DPO](https://arxiv.org/abs/2305.18290).

Use supervised imitation of explicit successful corrections before sequential RL. Consider a contextual bandit if choosing one recipe family or adjustment per context is sufficient. Consider full RL only when a state/action/reward/termination definition exists and multi-step credit assignment matters. Possible state includes published configuration and diagnostics; actions are typed bounded edits; success is a reviewed task outcome; budgets limit every episode.

An artist repeatedly choosing preferred results is human preference learning. It becomes RL only when a policy is trained through a reward-driven interaction process. The user does not need full RL to get the desired improvement loop. [Human preference RL](https://arxiv.org/abs/1706.03741).

## Prevent score chasing

Freeze the evaluator for an experiment, retain a separate human test set, and inspect top-scoring failures. Do not train a proposer and judge indefinitely on each other's outputs. Increasing search volume can exploit scorer errors. Both reward-model optimization and direct alignment have published overoptimization evidence. [Reward overoptimization](https://arxiv.org/abs/2210.10760), [direct alignment overoptimization](https://arxiv.org/abs/2406.02900).

Stop or roll back when model score rises but blind artist preference, feasibility, diversity or correction time worsens. Keep the last accepted model and the recipe-only path available. Automatic model promotion is outside the first product.
