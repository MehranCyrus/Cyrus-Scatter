# Prepare model script-load correction — 0.87.3.1

**Superseded by the [tested preparation correction](PREPARATION_FIX_08731.md).**
This package fixed parsing but subsequently reproduced the `findItem` parameter-
block error. Use the later `preparefix` package for current testing.

26 October 2026. User-reported Max 2027 compilation failure in the first 0.87.3.1
package. The generated script contained:

```maxscript
local accepted=try(cyrusInteractionAccept value)catch(throw (cyrusInteractionSourceSummary value))
```

Max reports **only throws without arguments are permitted in catch expressions**.
This is a script parser error, before the interaction code can load. It is unrelated
to scene units, geometry, guide count, license activation or collider fitting.

The authoritative authoring template now calls `cyrusInteractionAccept value`
directly. A native preparation exception propagates to the existing outer UI
handler, which displays `getCurrentException()`. No argument-bearing throw is
needed inside a catch. The generated script is rebuilt from the corrected template.
Native behavior, capability 6, schema 61 and product label 0.87.3.1 remain unchanged.

[Exact corrected build/package identity](BUILD_08731_SCRIPT_LOAD_FIX.json).
Archive SHA-256: `10a9d6a2aa153297b86a060a212177e60391c86edf06712600f126b6c133a026`.
Script SHA-256: `47fa954bbcb4bdc71971548bf7db3c025685c778f0b97f8989ffb20b59e38237`.

Use the revised [Max 2027 MZP](../../../dist/CyrusScatter-0.87.3.1-20261026-scriptfix/CyrusScatter-0.87.3.1-Max2027.mzp),
through **Scripting > Run Script**, then restart Max. The earlier package under
`dist/CyrusScatter-0.87.3.1-20261026/` has the reported parser failure and must not
be used for testing; its original hashes remain historical evidence.

This remains build/package only under the user's instruction. The fresh producer
compiles matching Max 2027 modules; archive/payload/version/host integrity is checked
during packaging. Native tests and Max host execution are not performed. Max script
loading and subsequent interaction behavior still require user validation. The
reported line is corrected in source; successful Max compilation is not claimed.
