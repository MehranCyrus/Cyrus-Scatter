# 25 — Concrete native C++ core API sketch and key algorithms

> Code here is **architecture-level C++20-style pseudocode**, not code verified against a particular 3ds Max SDK, renderer or current Cyrus repository. Its purpose is to make module boundaries, memory ownership and algorithms clear before coding.

## 1. CMake/library boundaries

```text
cyrus_math         vectors, matrices, scalar types, RNG, curves
cyrus_geometry     immutable triangles, splines, BVH, UV sampler
cyrus_fields       bitmap/procedural/paint/distance field evaluators
cyrus_distribution image/path/reference/particle candidate writers
cyrus_population   eligibility, source selection, transforms, collision, overrides
cyrus_runtime      dependency graph, cache keys, scheduler, telemetry
cyrus_max_bridge   scene snapshots, host plugin, Paint, Undo, serialization
cyrus_viewport     preview buffers and picking
cyrus_renderers    generic stream, SDK-specific adapters
cyrus_tests        standalone unit/property/differential tests
```

The portability goal is to build and test `cyrus_math`, `cyrus_geometry`, `cyrus_fields`, `cyrus_distribution`, `cyrus_population`, `cyrus_runtime` **without launching Max**. `max_bridge`, viewport and actual renderer adapters naturally require host toolchains.

## 2. Immutable snapshot structure

```cpp
struct SceneSnapshot {
    RevisionVector versions;
    double canonicalTimeSeconds;
    std::shared_ptr<const SourceTable> sources;
    std::shared_ptr<const PreparedReceiverSet> receivers;
    std::shared_ptr<const SplineTable> splines;
    std::shared_ptr<const ImmutableFieldTable> fields;
};

struct ScatterRecipe {
    Uuid id;
    uint64_t seed;
    GeneratorSpec generator;
    std::vector<AreaSpec> areasBottomToTop;
    SourceSelectionSpec diversity;
    TransformSpec transforms;
    ConstraintSpec constraints;
    std::vector<EffectSpec> effects;
    ManualEditLayer edits;
};
```

Immutable shared pointers are not enough if the referenced objects wrap mutable Max internals; enforce deep ownership for worker inputs. `RevisionVector` can track independent source, receiver, region, material, camera and time revisions so cache invalidation is granular.

## 3. Candidate generation and deterministic IDs

```cpp
uint64_t Hash64(uint64_t a, uint64_t b, uint64_t c);

float StableRandom01(CandidateId id, PropertyChannel channel, uint64_t seed) {
    uint64_t h = Hash64(id.value, uint64_t(channel), seed);
    return FloatFromHighBits(h); // canonical [0,1), platform-tested
}

void ImageProvider::Generate(const CandidateRequest& q, CandidateWriter& out) {
    for (TileKey tile : EnumerateTilesCanonical(q.bounds)) {
        for (uint32_t ordinal : EnumeratePixelCandidates(tile)) {
            CandidateId id = MakeCandidateId(q.scatterId, q.generatorId, tile, ordinal);
            Vec2 xy = PixelToWorld(tile, ordinal, q.params);
            float coverage = q.map.Sample(xy);
            if (StableRandom01(id, PropertyChannel::Density, q.seed) >= coverage) continue;
            out.Push({id, xy, ...});
        }
    }
}
```

The hash and float mapping require fixed-width integer types and deterministic test vectors across compilers. Use a candidate budget, tile count overflow guards and cancellation checks. Include generator algorithm version in ID/caches.

## 4. Surface projection algorithm

```cpp
SurfaceHit ProjectXY(const PreparedReceiverSet& receivers,
                     Vec2 scatterLocalXY, const Mat4& scatterTransform) {
    Ray ray = RayAlongScatterLocalZ(scatterLocalXY, scatterTransform);
    HitList hits = receivers.Raycast(ray);
    auto best = ChooseHit(hits, declaredPolicy); // e.g. nearest, target receiver
    if (!best) return SurfaceHit::Missing();
    return InterpolateFaceAttributes(best);
}
```

UV version builds UV-space triangle acceleration and uses barycentric interpolation. Receiver validity and selected face are explicit. Never silently return `{0,0,0}` for a miss.

## 5. Ordered area contributions

```cpp
CandidateBuffer EvaluateAreas(const Recipe& r, const GeneratorOutput& g) {
    CandidateBuffer active;
    for (const AreaSpec& area : r.areasBottomToTop) {
        if (!area.enabled) continue;
        if (area.mode == Include) {
            auto generated = RestrictAndTagCandidates(g, area.id, area.region);
            ApplyLocalAreaOverrides(generated, area);
            active.Append(generated);
        } else {
            active.RemoveIf([&](auto& c) { return area.region.Contains(c.position); });
        }
    }
    return active;
}
```

**Important limitation:** `RestrictAndTagCandidates(g, area)` assumes one common generator reservoir. Forest-style Include areas can contribute their own independent candidate sets with local distribution parameters. Production implementation must support `GenerateForArea(area, sharedGeneratorSpec)` instead of merely filtering one global `g`, and preserve contribution provenance. This sketch only illustrates ordered inclusion/exclusion structure, not the final production algorithm.

## 6. Source chooser and transform evaluator

```cpp
SourceId SelectSource(const Candidate& c, SourceSelectionContext s) {
    if (s.mode == MatchColorID) return FindClosestColorSource(s.field.Sample(c));
    if (s.mode == Clusters) return SampleCategorical(ClusterWeights(c.position),
                                                     StableRandom01(c.id, Species, s.seed));
    return s.aliasSampler.Pick(StableRandom01(c.id, Species, s.seed));
}

Transform EvaluateTransform(const Candidate& c, const SurfaceHit& hit,
                            const SourceDefinition& source, const Settings& s) {
    auto rotation = SampleProbabilityCurves(c.id, s.rotationCurves);
    auto scale = SampleScale(c.id, s.scaleParams, s.valueMaps);
    auto offset = SampleRelativeTranslation(c.id, source.dimensions);
    return ComposeUsingDeclaredOrder(hit.frame, rotation, scale, offset,
                                     source.pivotTransform);
}
```

Explicitly specify field domains, source bounds, unit scaling, handedness and transformation order. Sample source first if collision radius depends on source.

## 7. Occupancy solver

```cpp
std::vector<Item> ResolveGreedy(std::vector<Item> items) {
    StableSortByPriorityThenId(items);
    SpatialHash accepted;
    std::vector<Item> winners;
    for (const Item& i : items) {
        if (i.empty || !i.valid) continue;
        auto shape = EffectiveCollisionProxy(i);
        if (accepted.AnyOverlap(shape, i.compatibilityMask)) {
            RecordReject(i.id, COLLISION);
            continue;
        }
        accepted.Insert(i.id, shape);
        winners.push_back(i);
    }
    return winners;
}
```

This produces a reproducible greedy result **only if** sort, shape, floating-point tie rules and hashing are deterministic. Grid ownership and neighboring cells must account for variable source radii. Local updates require conflict propagation or fallback to a full solve.

## 8. Manual editing overlay

```cpp
void ApplyEdits(FinalPopulation& out, const ManualEditLayer& edits) {
    for (auto& tombstone : edits.suppressedIds) out.Remove(tombstone);
    for (auto& [id, ov] : edits.overrides) {
        if (auto* item = out.Find(id)) ApplyOverride(*item, ov);
        else MarkOrphan(ov); // preserve authored data, do not delete it
    }
    for (auto& item : edits.explicitManualItems) out.Add(item);
}
```

Placement in pipeline matters: if pinned edits are collision winners, insert them before/generated occupancy and rerun constraints. The above illustrates the data overlay, not a complete collision-aware merge.

## 9. Job cancellation and publication

```cpp
void Scheduler::Submit(ScatterId id, RevisionVector v, DirtySet dirty) {
    CancelObsoleteJobs(id, v);
    auto snapshot = host.CaptureOnMainThread(id, dirty);
    pool.Enqueue([this, id, v, snapshot=std::move(snapshot), dirty]() {
        auto next = Evaluate(snapshot, dirty);
        PostToHostMainThread([this, id, v, next=std::move(next)]() {
            if (host.CurrentRevisionVector(id) != v) return;
            published[id].Store(std::move(next));
            viewport.RequestRedraw(id);
        });
    });
}
```

Avoid raw `this` lifetime across shutdown, callback reentrancy, exception leaking out of threads and blocking host with long locks. Actual implementation uses ownership/cancellation types and safe main-thread task dispatch verified with SDK.

## 10. Fast bitmap/paint evaluator

```cpp
struct CompiledPaintTile {
    TileKey key;
    uint64_t strokeRevision;
    std::vector<uint16_t> coverage;
    std::vector<int16_t> signedDistance;  // quantized with known scene-unit scale
};

void ApplyStroke(CompiledPaintTile& tile, Span<const Dab> dabs) {
    for (Pixel p : AffectedPixels(tile, dabs)) {
        for (auto& dab : RelevantDabs(p, dabs)) {
            float alpha = BrushFootprint(dab, p.worldPosition);
            tile.coverage[p] = Quantize(Compose(tile.coverage[p], alpha, dab.op));
        }
    }
    RecomputeDistanceFieldWithNeighborHalo(tile);
}
```

For a high-frequency brush stream, spatially partition dabs, rasterize touched tiles and avoid repeated evaluation of all historical strokes against every pixel. Compilation semantics and blur/tolerance must match the authoritative paint evaluator. Erase/add order is material.

## 11. Rendering stream example

```cpp
RenderStream PrepareForRenderer(const FinalPopulation& pop,
                                const SourceRegistry& sources,
                                const Camera& camera,
                                const RendererCapabilities& caps) {
    RenderStream result;
    for (const auto& item : pop) {
        if (!ConservativelyVisible(item, camera)) continue;
        auto lod = ResolveLOD(item, camera, caps);
        auto source = ResolveRenderSource(sources, item.source, lod, caps);
        result.AddInstance(source, item.transform, item.attributes, item.id);
    }
    return result;
}
```

Renderer submission, source lifetime, motion blur, material attributes, and specific native instances are implemented in dedicated adapters rather than inside this function. This is not a substitute for renderer SDK integration.

## 12. Practical code organization standards

- Deterministic core tests and checksums for every algorithm version.
- No Max SDK headers in portable `core/` public interfaces.
- No per-instance scene nodes or heap-allocated polymorphic objects on hot paths.
- All math uses clear coordinate-space and unit conventions.
- Diagnostics by stage and rejection reason in debug/production-safe form.
- Safe cancellation/version checks at every asynchronous publication.
- Instrument every fast path before claiming it is faster than baseline.
- Keep a full-rebuild reference implementation permanently for correctness comparison.

## 13. MVP compilation target

An independent test executable should be able to load a fixture description, generate candidate IDs/positions, apply a spline exclusion, select weighted sources, solve collisions, apply manual pin, and emit a canonical JSON summary **without launching Max**. A host plugin then supplies scene geometry to that same core and renders a preview. This vertical slice validates the architecture before hundreds of UI controls are built.
