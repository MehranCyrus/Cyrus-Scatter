# 18 — Versioning and Release Engineering

## Current version sources

Observed at baseline:
- product README: Cyrus Scatter 0.59;
- MZP metadata: 0.53;
- installer message: 0.59;
- CMake project: 0.1.0;
- native `LibDescription`: 0.21;
- generated scripted class version: 44;
- Analyzer README/MZP: 0.14;
- Analyzer CMake/native: 0.5;
- Analyzer scripted class version: 13;
- native binary folder names: bin55 / bin05.

These numbers have different historical meanings but are not sufficiently separated/documented for commercial entitlement logic.

## Recommended version domains

1. **Product release** — e.g. 1.0.0.
2. **3ds Max target** — 2026, 2027.
3. **Scene/script schema** — current 44 / 13 style migration numbers.
4. **Native serialization schema** — CS Edit chunk/version.
5. **License entitlement release date/version**.
6. **Provider/SDK integration version**.

## Single source

Add a machine-readable release metadata file and generate public release version into CMake, installer/package, About UI, artifact names and licensing release metadata.

Do not replace scene migration versions with SemVer; they solve a different problem.

## Release artifact identity

Every commercial release should record:
- Git commit/tag;
- generated script hash;
- native binary hashes;
- Max target;
- signing certificate identity;
- package version;
- release date;
- entitlement eligibility date;
- test log reference.
