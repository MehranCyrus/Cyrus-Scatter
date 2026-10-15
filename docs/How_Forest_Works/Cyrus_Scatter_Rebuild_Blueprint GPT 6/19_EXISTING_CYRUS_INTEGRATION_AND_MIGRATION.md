# 19 — Existing Cyrus integration and migration

**Status: proposed rebuild strategy. No current repository audit was performed for this package.**

## 1. Rebuild the engine without sacrificing existing scenes

The user has explicitly requested a full rebuild of the researched functionality. That authorizes a new architecture plan, not untested changes to old production scenes. Develop vNext alongside the existing implementation until migration has been demonstrated.

Use separate engine/profile versions, fixtures, and build artifacts. Existing scenes select their saved evaluator until an explicit conversion. A new file format or class registration must not hijack existing serialized identifiers.

## 2. First repository audit

Before changing code, record the actual branch/commit and locate:

| Area | Required findings |
|---|---|
| Persistent controller | Class IDs, ParamBlocks, save chunks, reference ownership |
| Native scatter | Candidate identity, generators, masks, transforms, collisions |
| Painting | Authority, coordinate space, Undo, update triggers |
| Surface Analyzer | Snapshot data, topology identity, query API, thread/lifetime rules |
| CS Edit | ID mapping, transform storage, pin/delete semantics |
| Viewport | Buffer ownership, display interfaces, selection mapping |
| PFlow transport | Prototype/particle mapping, materials, animation, headless path |
| Automation | Current schema, permissions, transaction boundaries |
| Tests | Reproducible fixtures, benchmarks, existing guarantees |

Mark each finding as read from code, documented only, or reproduced in Max. Old project summaries are not current-code evidence.

## 3. Reuse by contract, not by name

Surface Analyzer can become the shared surface provider if it supplies compatible immutable geometry, bindings, normals, attributes, and revisions. Otherwise add an adapter or extend its contract. Do not rewrite it solely because the new design has a differently named cache.

CS Edit can become a client of the new override store if its current target identity can be mapped. When that mapping is impossible, preserve old edits through an explicit manual-item conversion with a report.

PFlow transport can remain the first production output path if it passes the new capability fixtures. Native renderer adapters can be added without changing the core instance schema.

MAXScript panels can be migrated gradually to the command API while retaining familiar workflows. Hot loops move only after profiling and tests identify their cost.

## 4. Branch and build isolation

Use a dedicated rebuild branch/worktree and separate plugin output directory. Do not overwrite the installed production plugin during development. Test loading and unloading the correct binary in an isolated Max profile/fixture environment.

Pin Max SDK, compiler toolset, renderer SDK, and dependencies per target. C++17 is a proposed core baseline; host/renderer adapters must use the toolchain their actual SDK requires. Using a newer IDE does not by itself establish binary compatibility.

## 5. Scene conversion

A converter reads the old authoritative state and creates a new setup beside it. It reports mapped controls, unsupported semantics, source/receiver references, paint conversions, edit mappings, and expected differences.

Use three outcomes: exact mapping under a tested rule, approximate mapping requiring artist review, and unsupported mapping. Never silently discard a feature because the new schema lacks it.

Keep the original setup untouched until comparison and acceptance. Saving the new scene to a separate file is the default workflow. A rollback does not depend on reversing an irreversible baked conversion.

## 6. Population comparison

When old and new generators differ, compare declared behavior rather than demanding identical random coordinates. Measure coverage boundaries, density/statistics, source proportions, transform ranges, spacing, manual-edit preservation, and visual output in fixed cameras.

For controls whose identity/behavior is expected to match, compare canonical mappings directly. Distinguish intended design differences from regressions.

## 7. Migration checkpoints

First migrate a flat single-layer setup. Then a terrain with exclusions. Then paint and Undo. Then manual edits. Then linked layers and shared surfaces. Finally materials, animation, and farm rendering.

Do not start migration testing with the largest studio scene. Small fixtures localize mismatches and produce useful compatibility records.

## 8. Definition of migration completion

A migrated scene saves/reopens, rebuilds with caches deleted, retains recoverable authoring data, renders through a qualified adapter, and reports all intentional differences. Performance alone cannot compensate for lost paint or edits.
