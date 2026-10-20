# Cyrus local exception-ownership patch

Patch `cyrus-exception-ownership-001`, 18 October 2026.

The upstream repository/commit and original checksums remain unchanged in `PROVENANCE.json`: commit `f9c5eb6e14a59f6f5d65fbfb3564519a561cf4fd` from [Clipper2](https://github.com/AngusJohnson/Clipper2). This directory contains a narrow local modification to `src/clipper.engine.cpp`, recorded separately in `LOCAL_PATCHES.json`. It is not an upstream version update. The original source copyright header and complete Boost Software License 1.0 in `LICENSE` are preserved.

- Original upstream engine SHA256: `7b2cc17d4debd3b5ee6bd2c592ecda5082253324c7dd514b5593ae1b2c7812b2`
- Locally patched engine SHA256: `6251b237d2083bed8e1716bf6670499e1325a0ab786c2d5d60e9ee8e71bd9f3a`
- License SHA256: `c9bff75738922193e67fa726fa225535870d2aa1059f91452c411736284ad566`

## Reproduced failures

A bounded query-constructor allocation-failure sweep reproduced three ownership gaps independently against immutable native26 (the 0.1.2 core). Each leaves a successful raw allocation unregistered when the next allocation throws:

| Failed allocation index, zero-based | Prior leaked request | Allocator callsite captured from baseline | Ownership gap |
| --- | --- | --- | --- |
| 78 | 77: 240 bytes (`Vertex[6]`) | `Clipper2Lib::AddPaths_` | Vertex array is registered only after minima and vector allocations. |
| 86 | 85: 136 bytes (`Active`) | `ClipperBase::InsertLocalMinimaIntoAEL` | Left bound is not linked/owned when right-bound allocation fails. |
| 88 | 87: 128 bytes (`OutRec`) | `ClipperBase::NewOutRec` | Newly allocated record is not registered when its vector grows. |

Paired baseline/current proof and stack logs are under `build/query-accounting-diagnostics-01/` and `-02/`. The immutable libraries and the original failed scoped snapshots remain preserved; no pass replaces a failed receipt.

## Local changes and ownership

Only three functions change:

1. `AddPaths_` holds the new `Vertex[]` in `unique_ptr` until `vertexLists.emplace_back` succeeds. A catch shrinks `locMinList` to its entry size before rethrow. The actual type is `vector<unique_ptr<LocalMinima>>`, so shrinking destroys new minima owners while preserving all earlier entries. Only then does the pending array owner unwind. Successful registration releases the array to the existing container cleanup.
2. `InsertLocalMinimaIntoAEL` holds pending descending/ascending bounds in local `unique_ptr`s. Raw bounds may swap, so handoff compares pointer identity and releases exactly the owner for the edge just linked. `InsertLeftEdge`/`InsertRightEdge` perform pointer linkage without allocation or deletion; subsequent throwing clipping work is covered by existing AEL cleanup.
3. `NewOutRec` keeps a local owner until the existing output-record vector accepts its raw pointer, then hands off to the existing record cleanup.

There is no numeric, topology, winding, sorting, tolerance, clipping, offset or work-budget algorithm change. Successful allocation order and the measured constructor allocation count (113) remain unchanged. No cache-specific allocation hook is added to the library.

## Primary-source check and limits

The [pinned upstream engine](https://raw.githubusercontent.com/AngusJohnson/Clipper2/f9c5eb6e14a59f6f5d65fbfb3564519a561cf4fd/CPP/Clipper2Lib/src/clipper.engine.cpp) and [current upstream main](https://raw.githubusercontent.com/AngusJohnson/Clipper2/main/CPP/Clipper2Lib/src/clipper.engine.cpp), inspected 18 October 2026, retain the demonstrated raw pending-allocation patterns. No general upstream exception guarantee is inferred; this is a local repair of reproduced callsites. The local license text governs distribution; this note is not a legal assurance.

The new native test target checks every one of the 113 allocation points in its small constructor fixture and tests failed append into an already populated Clipper, followed by exact prior-polygon execution. `build/query-accounting-diagnostics-03/run.log` passes all ten accounting suites, including those checks and the exact frozen 0.1.2 query result/build-work/probe-work fixture. Fresh scoped/full-product receipts qualify subsequent matching builds separately.

These tests do not prove exception safety for every possible Clipper operation, open path, offset or arbitrary geometry. The pinned dependency is otherwise unchanged; future reproduced gaps need their own narrow evidence and patch record.
