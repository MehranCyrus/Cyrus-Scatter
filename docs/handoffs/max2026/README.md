# Max 2026 review handoff

The prepared local package is now at:

```text
_local/handoffs/Boss Handoff - Max 2026/
```

It contains Scatter 0.62 and Analyzer 0.14 installers, the Max 2026-format demo, `Compare Viewport.ms`, instructions and checksums. This whole local folder can still be zipped for the reviewer. The packages and scene are intentionally excluded from the source Git backup.

The versioned documents are [original instructions](START%20HERE.txt) and [package checksums](CHECKSUMS.txt). The comparison script's source is preserved as [historical evidence](../../plans/spline-bands/retired-fixtures/CompareViewport.ms); it uses the removed 0.62 batching API and must not be run with current builds. These text copies do not replace the complete local install folder.

The package was built with the Max 2026 SDK and its native suites passed. The demo and helper were checked in Max 2027; Max 2026 application runtime qualification remains pending. The later retained-point prototype is not included. See [current build status](../../Max_2027_Installation.md) and [retained-point results](../../Heavy_Scene_Viewport_2026-10-02/RESULTS.md).
