# 24 — Open Questions and Risk Register

## Must verify before code changes

### CS Edit module loading
Why are the same CS Edit implementation/descriptor relationships split between `AminScatter.dlx` and `CyrusScatterEdit.dlm`? Verify actual Max load behavior before refactor.

### Render farm identity
Determine reliable native/runtime signals for network/render workers across Max command line, Deadline and target renderers. Do not use a script-editable flag.

### PFlow cancellation/error cleanup
Source contains cleanup logic, but cancellation/distributed/multi-frame behavior needs current runtime evidence.

### Analyzer during render
Identify which Analyzer data must be recomputed on workers versus saved scene data, especially in Manual mode.

### Generated schema migration
Document every historical scripted class migration needed for pre-0.59 scenes. Current generator visibly handles some migrations, but the repository does not contain a formal schema table.

### Export/bake commercial policy
Bake exists and creates permanent instances. Decide whether it is always included or a tiered entitlement before implementing capability gates.

### Public repository exposure
If proprietary, confirm when visibility changed and whether source/secrets were ever public. No secret was identified in this static pass, but a proper history scan is still required.

## Medium risks

- textual generator anchors are fragile;
- fragmented versions can break maintenance entitlement logic;
- current installer can leave old binaries loaded;
- renderer-specific proxy/PFlow behavior may differ;
- very large scenes can stress scripted orchestration despite native cores.

## Non-risks / avoid unnecessary rewrites

- scatter math does not need migration from MAXScript: it is already native;
- Analyzer core is already native;
- preview already has native acceleration;
- CS Edit is already native.

The commercialization project should preserve these strengths.
