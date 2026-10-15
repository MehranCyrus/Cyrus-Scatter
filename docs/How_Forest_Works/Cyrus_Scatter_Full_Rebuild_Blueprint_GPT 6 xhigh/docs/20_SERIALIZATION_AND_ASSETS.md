# 20 — Serialization, scene versioning, assets, missing references and presets

## 1. Authoring data, not caches, is the save contract

Persist the logical scatter configuration, geometry/material references, stroke authority, override transactions, data version, units and user-facing settings. Candidate reservoirs, acceleration BVHs, GPU buffers and render handles are derived and normally not authoritative; they can be serialized as optional verified caches but must be recomputable.

## 2. Native scene ownership

The host plugin may need native 3ds Max save/load chunks or parameter-block integration; choose exact structure after auditing existing Cyrus and Max SDK interfaces. Preserve stable 64/128-bit UUIDs across save/load and copy/merge. Avoid raw pointer persistence. Merge into another scene must handle duplicate IDs by remapping namespaces while preserving internal references.

## 3. Proposed versioned manifest (illustrative)

```json
{
  "format": "CyrusScatterDocument",
  "schemaVersion": 3,
  "generatorAlgorithmVersion": 5,
  "sceneGuid": "<uuid>",
  "unitSystem": "centimeter-system-unit",
  "scatterObjects": [
    {
      "id": "<uuid>",
      "name": "Lawn",
      "seed": 1001,
      "generator": {"type":"Image", "version":2, "params":{}},
      "sources": ["<source-id-A>", "<source-id-B>"],
      "receivers": ["<receiver-node-binding>"],
      "areasOrderedBottomToTop": ["<include-uuid>","<exclude-uuid>"],
      "overrides": "<override-layer-id>"
    }
  ],
  "externalAssets": [],
  "unknownExtensionFields": {}
}
```

Illustrative JSON; do not assume this is the desired physical `.max` storage format. Chunked binary or host-native parameter persistence may be more practical, with JSON for external export/debug interchange.

## 4. UUID and cloning behavior

- **Save/reopen:** IDs unchanged.
- **Clone scatter in same scene:** new scatter namespace; source library references may be shared or duplicated by explicit policy. Preserve internal override mapping to cloned candidate namespace.
- **Merge external scene:** avoid ID collision across copied documents; relink scene references.
- **XRef/linked asset:** treat external node stable ID/namespace differently from local node ID; record unresolved state.
- **Copy source record:** new source definition UUID unless the user chooses shared reference alias.
- **Delete source:** keep tombstones/repair hints for downstream references.

## 5. Asset reference format

Recommended metadata: logical asset UUID, display name, source type, original path/URI, relative project path, content hash/size if available, required renderer family/version, material references and optional license metadata. Paths must handle Windows case normalization, UNC networks and relocation; do not assume absolute artist workstation directories remain valid.

Asset resolver priority: embedded/portable packaged asset if present and authorized → project-relative path → configured shared library roots → approved remapping table → manual repair. Never auto-download untrusted executable/code assets into an active Max scene.

## 6. Three different preset types

**Settings preset:** value/curves only; doesn't overwrite scene bindings unless explicitly requested.

**Scatter recipe:** source selection, distribution, Areas and Effects rules, with asset references that may need resolution.

**Scene setup:** recipe plus actual receiving surface/spline/node bindings and manual states, requiring per-scene relinking.

**[FP-DOC]** ForestPack distinguishes parameter presets from complete library presets; its newer versions offer additional portable geometry functionality. [General](https://docs.itoosoft.com/forestpack/forest-plugin/general), [Library](https://docs.itoosoft.com/forestpack/forest-library/library-browser).

## 7. Migration engine

Each schema migration is a pure, repeatable transformation `Version N -> N+1`, with fixtures of actual older scenes where legal. Preserve unknown future fields when feasible. Migration report must say: changed control mapping, dropped/unsupported behavior, altered random algorithm version, missing references, manual edit orphan count and renderer fallback.

A new C++ random or placement algorithm can change every generated source assignment even if user seed is unchanged. Therefore serialize an **algorithm version** and support compatibility mode or explicit regeneration option. A migration tool should not silently replace existing authored composition.

## 8. Save/load integrity

- Detect corrupted or partial data with checksums/lengths before reading arrays.
- Bound allocation sizes to protect against malformed files.
- Reject duplicate persistent IDs unless explicitly remapped.
- Restore all object references after host load, not while nodes are still unavailable.
- Mark unknown/unsupported effects inactive with retained source definition.
- Rebuild derived caches lazily; do not block scene load on unnecessary expensive regions.
- Avoid blocking UI forever on missing network asset; preserve authored structure.

## 9. Undo policy for preset/asset operations

Loading a preset or replacing a set of sources is one coherent transaction; source import operations that instantiate host nodes must also participate in appropriate host Undo. External cache generation is not an Undo change, but it must respond to reversion of authored state.

## 10. Persistence tests

- Same scene after save/reload, cleared caches, identical accepted state.
- Move/copy across machines with relinked assets and identical unit system.
- Merge two scenes with deliberately colliding UUID values; IDs safely remap.
- Delete and re-create source object, recover manually or via explicit binding procedure.
- Undo preset import and redo without orphan references.
- Load future-schema document; retain unknown fields or show explicit incompatibility rather than corrupting.
- Clone scatter with manual overrides and linked areas; no cross-link to original unless chosen.
- Import damaged/truncated data safely with repair report.
