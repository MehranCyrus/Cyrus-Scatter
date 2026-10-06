# Offline Design Lab foundations

This is an explicit local command-line prototype for engineering the future learning loop. It **does not launch Max, generate a scatter, render, run a model provider, upload data or connect to the running artist scene**. Job claims describe work; a qualified host/renderer worker and artist review gallery still need implementation and runtime validation.

Source: [store/state machine](../../CyrusMCP/cyrus_mcp/design_lab/store.py), [features/ranker](../../CyrusMCP/cyrus_mcp/design_lab/ranking.py), [CLI](../../CyrusMCP/cyrus_mcp/design_lab/__main__.py), [tests](../../CyrusMCP/tests/test_design_lab.py). These modules are separate from the closed MCP apply schemas and grant no scene authority.

## Run locally

Use an isolated Python environment. Pillow is an optional extra for full PNG decoding; the tested version is 12.3.0. The engineering environment installed it only under the repository's ignored `build/mcp-venv`.

```powershell
build/mcp-venv/Scripts/python.exe -m pip install -e "CyrusMCP[design-lab]"
build/mcp-venv/Scripts/python.exe -m cyrus_mcp.design_lab --help
build/mcp-venv/Scripts/python.exe -m cyrus_mcp.design_lab validate-draft plan.json enrollment.json
```

`validate-draft` checks `3.0-draft1` offline. It reports `mutation_supported: false`; it cannot apply a plan to Max. The tests in [test_procedural_plan.py](../../CyrusMCP/tests/test_procedural_plan.py) contain a complete small draft/enrollment example. A draft is a new-recipe contract, not a patch protocol for existing scene identity/order.

To create a study, prepare a JSON list of one to eight **required** views. Each view contains `view_id`, `camera_sha256`, `profile_sha256`, `width`, `height` and a short explicit `colour` label. The camera/profile hashes must come from the real enrolled settings when a host worker exists; do not invent hashes and call them host evidence.

```powershell
build/mcp-venv/Scripts/python.exe -m cyrus_mcp.design_lab init build/my-study --name "Garden comparison" --views views.json --candidates 32 --attempts 2
build/mcp-venv/Scripts/python.exe -m cyrus_mcp.design_lab status build/my-study
build/mcp-venv/Scripts/python.exe -m cyrus_mcp.design_lab add build/my-study candidate.json
```

A candidate file contains `recipe`, `publication_id`, `features`, `project_id`, `task_id`, `lineage_id`, plus explicit optional `synthetic`/`consent` booleans (both default false). `features` uses `cyrus.layout-features/1.0`; generate it from actual exported exact-output rows with `features rows.jsonl --bounds minX minY maxX maxY`. The feature file is JSONL, at most 20,000 rows/16 MiB. Column-vector transforms and radii are already in metres; do not convert them twice.

The journal keeps unsuccessful jobs and artistic rejections. It does not delete undesirable examples. Technical failure and aesthetic judgment remain separate records.

## Worker and artifact contract

`claim` admits one queued/failed job, consumes an attempt, and returns a new token/deadline plus the expected candidate/publication/recipe/view identity. There can be only one running job in a study. This is not yet a multi-process Max farm or a global lock across independent study directories.

`finish` requires that exact active token and matching receipt: candidate ID, publication ID, recipe SHA, view ID, camera/profile SHA, colour label, `assets_complete: true` and `host_qualified: true`. Those last flags are explicit importer/worker assertions; the library cannot certify a renderer from a Boolean. The image must fully decode as a non-animated RGB/RGBA PNG, with matching dimensions and bounded size. Content-addressed bytes are fsynced before the completed database row is committed. Interrupted unjoined files remain unjoined and count against storage; they are not silently adopted or broadly cleaned up.

Failed attempts consume the same budget. Expired output cannot complete a job. `recover --worker-stopped` marks interrupted attempts `outcome_unknown`; `resolve-unknown` records local inspection before a retry can be claimed. A new token rejects late output from an old attempt. Cancellation of a running job requires confirmation that its worker stopped; this command does not kill a process.

A candidate is reviewable only after **every required view** succeeds. Review and dataset assembly recheck actual file digests and decodeability. A missing, modified, wrong-camera or incomplete artifact is not a valid artistic training sample.

## Artist feedback and learning

```powershell
build/mcp-venv/Scripts/python.exe -m cyrus_mcp.design_lab compare build/my-study CANDIDATE_A CANDIDATE_B --choice a --reviewer artist_01 --reason "Clearer foreground" --consent
build/mcp-venv/Scripts/python.exe -m cyrus_mcp.design_lab decide build/my-study CANDIDATE_A approve --reviewer artist_01
build/mcp-venv/Scripts/python.exe -m cyrus_mcp.design_lab dataset build/my-study --output dataset.json
build/mcp-venv/Scripts/python.exe -m cyrus_mcp.design_lab fit build/my-study --output preference-experiment.json
```

Choices are `a`, `b`, `tie`, `neither` and `skip`. Approval/rejection/defer is a separate explicit decision; winning a comparison never implies approval. The latest vote by a reviewer for an unordered pair supersedes their previous vote without erasing history. Candidates must belong to the same project/task to be compared.

Dataset inclusion requires consent on both candidates **and** on the comparison, completed verified views, and non-synthetic provenance. Neither/skip and technical failures remain in the journal but do not become pairwise preference labels. Ties use a 0.5 target. Revocation (`consent … --revoke`) removes a candidate's pairs from future dataset exports. Previously exported copies/models are not remotely recalled: rebuild them and verify the new dataset digest. The scoring function rejects a supplied current dataset digest that differs from training.

The model is a small regularized pairwise logistic baseline with ten features: log density, 4×4 grid occupancy, normalized centre/spread/covariance, source-entry entropy, radius fraction and protected fraction. It measures coarse layout statistics; it has no understanding of flower colour, image lighting, material fidelity, sightlines or professional photographic composition. Source-entry entropy counts entries, not deduplicated mesh species.

Training requires at least six eligible comparisons across three independent projects, with at least four training comparisons and two decisive ones. Whole projects are held out; repeated candidate IDs or lineages cannot cross projects. Scaling is fitted on training candidates only. The result records held-out log loss/decisive accuracy and a constant-probability comparison. This simple benchmark is not a substitute for the required strong recipe baseline and artist time-to-approved-result evaluation.

All saved models are `deployable: false`. Tests with synthetic data demonstrate algorithm and recovery behaviour only. No real artist dataset was collected, no trained production taste model was delivered, and no claim of better-looking scenes follows from the offline pass. A review gallery, validated recipes/style profiles, richer reference features, production renderer jobs and held-out artist studies remain later slices.
