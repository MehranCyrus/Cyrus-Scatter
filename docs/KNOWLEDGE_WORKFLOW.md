# Compact knowledge workflow

The standard-library front door is `python -B tools/rag/context.py`. It consumes
the existing verified retrieval worker unchanged and prints one model-facing
JSON object. The original `knowledge_search` / `knowledge_status` MCP schemas and
their compatibility transport remain available for existing consumers.

```powershell
python -B tools/rag/context.py facts
python -B tools/rag/context.py status --verify-sources
python -B tools/rag/context.py search "Scene preset" --top-k 1
python -B tools/rag/context.py search "docs/ENGINEERING_FOUNDATION.md" --mode path --top-k 1
python -B tools/rag/context.py --legacy status --verify-sources
python -B tools/rag/context.py --detail full --max-chars 100000 search "F10" --mode identifier --top-k 1
```

Global options precede the command. Default search returns at most two results;
choose one for a precise question. The response target is 24,000 JSON characters,
not a tokenizer or billed-token measurement. Raise it explicitly when complete
required evidence is larger. Over-budget responses return no partial result.
Required source text and applicability are never silently truncated.

Compact views remove duplicate indexing text/excerpts, the repeated complete
configuration block and the status inventory's duplicate path list. Exact
originals, source metadata, citations, hashes, canonical/duplicate provenance,
historical limits, expansion diagnostics and verification scope remain. Full
provenance can be requested explicitly; failures are not converted to success.

## Scope and selection

`facts` reads the delivered baseline against its scoped qualification receipt,
then reports the actual working version separately. Current interaction facts and
the separately qualified Library foundation retain their own scope. It does not infer that
newer code, every source file or the entire plugin is qualified.

If `_local/rag/harness/selected.json` exists, it explicitly pins a reviewed
generation and review receipt. Read its declared scope rather than assuming
Library-only coverage. The command never scans for newest
indexes. Without this selection it reports that it is using the original project
index. A malformed or changed configured selection fails instead of falling back.
`--legacy` chooses the original project binding deliberately; `--index` selects
one explicit local generation. The original project MCP registration is unchanged.

The compact selection now includes core contracts, Scene/Library owners and the
reviewed interaction performance baseline/source owners. Independent product
implementation and unexecuted future optimizations remain outside that scope.
See the source/review receipt for exact parents and ranges. Full-source status
checks all parents in the selected scope; a successful scoped status does not
establish freshness of the legacy 64-parent enrollment or the whole repository.

The worker still verifies publication artifacts/runtime, root/generation identity
and every returned parent/duplicate source. Code runs in its existing network-denied
worker with a bounded deadline. This interface cannot mutate Max, publish an
index, activate a watcher or alter the project binding.

## Review and measurement

Use the [stage-one delivery record](../tools/rag/HARNESS_STAGE1.md) for the exact
candidate, tests, context measurements and remaining limits. Candidate creation,
semantic review and selection are explicit separate steps. A full broad-index
refresh waits for its own current source review; companion coverage is not a
workaround for stale evidence in another scope.

Benchmark cases measure retrieval/presentation correctness and serialized context
size. Actual agent accuracy, billed tokens and total engineering cost require
matched real task runs; they are not inferred from a smaller response.
