# 03 — Data contracts, stable identity, and deterministic randomness

**Status: proposed Cyrus design. Research basis: R0 §§2, 4, 8.**

## 1. Types express different identities

Use persistent UUIDs for authored entities: setup, layer, source, receiver, area, paint set, Effect, collection, and manual item. Store references through Max's host reference mechanisms plus persistent Cyrus identifiers; never serialize raw pointers.

Use compact dense indices only inside an immutable snapshot. A `sourceIndex` speeds array access but is not a saved source identity. The snapshot provides `sourceIndex -> SourceUUID`.

Candidate identity describes a semantic sampling address. Cache placement describes where an implementation stores the candidate. They are unrelated.

## 2. Canonical candidate key

A conceptual key is:

```cpp
// Contract sketch, not a complete SDK header.
struct CandidateKey {
    Uuid layer;
    Uuid includeContribution;
    Uuid generator;
    uint32_t identityEpoch;
    GeneratorAddress address;
    ReceiverBindingKey receiverSlot;
};
```

`GeneratorAddress` is a tagged value, not always a position:

| Generator | Canonical address |
|---|---|
| Image grid | Pattern tile integer coordinates + pixel/sample address |
| Progressive density | Fixed sampling-domain cell address + progressive sample rank |
| Path spacing | Curve UUID + sample rank within the saved spacing scheme |
| Path vertices | Persistent knot ID when available; otherwise topology epoch + knot index |
| Reference pivot | Referenced object UUID |
| Reference face | Object UUID + topology epoch + face ID + within-face sample rank |
| Particle | System/event UUID + persistent particle birth ID; adapter must verify availability |
| Manual placement | Saved manual-item UUID |

A projected sample expanded onto two receivers produces two bound candidate IDs. Include the receiver UUID and deterministic hit/sheet slot. Array position in a current ray-hit list is insufficient when a new receiver is inserted.

The canonical tuple is authoritative. A 128-bit digest can be used for storage and lookup; the system detects digest collisions and never merges distinct tuples silently. Debug exports retain the expanded key. Do not use implementation-defined `std::hash` for persisted IDs.

## 3. What remains stable

| Edit | Identity policy |
|---|---|
| Tint, display budget, camera orbit without population rules | Preserve candidate and instance IDs |
| Weight change or source replacement | Preserve candidate IDs; source choices/constraints may change |
| Source-list UI reorder | Preserve IDs and selection because evaluation uses canonical source UUID order |
| Density probability slider within a fixed candidate domain | Preserve universe; gate candidates using stable random values |
| Distribution offset/rotation | Preserve sampling addresses but move their positions |
| Pattern physical scale | Preserve integer sampling addresses; scene-bound enumeration may expose a different finite subset |
| Image resolution or generator type | Explicitly increment identity epoch; report affected overrides |
| Receiver rigid transform | Preserve receiver ID and compatible bindings; positions follow configured coordinate frame |
| Receiver topology change | Invalidate topology-dependent bindings; never assume face indices remain meaningful |
| Path spacing | Preserve rank identities under the same scheme but move positions; warn that semantic neighbors may change |
| Seed change | Preserve candidate addresses unless the generator's saved policy explicitly uses a new domain; regenerate random properties |
| Area-list reorder | Preserve area IDs; change eligibility/contribution composition |
| Cache tile size or worker count | No authoritative change whatsoever |

An identity can persist while an instance becomes rejected. An override remains stored and can become active again. “Stable ID” does not mean “the object is always visible.”

## 4. Random channels

Generate values from immutable keys:

```text
random(seed, candidateKey, channel, optionalSourceOrElementKey)
```

Use separate channels for density acceptance, source selection, cluster-site labels, yaw, pitch, roll, axis scale, translation, tint, animation phase, collision priority, and preview sampling.

No worker owns a mutable shared random stream. No rejection consumes a value that would otherwise belong to the next candidate. Preview budget changes never advance a source-choice RNG.

Define byte order, integer overflow behavior, hash/version identifier, string encoding, and conversion to floating-point values. A simple reference uses a stable digest of length-delimited fields; a production implementation can substitute a faster specified keyed generator only as an explicit algorithm-version change validated against its own golden vectors.

Convert an integer to `[0,1)` without producing 1. For inverse-CDF operations requiring an open interval, use a conversion explicitly bounded away from both endpoints. Do not allow `log(0)` into source selection or probability sampling.

## 5. Statistical equivalence is not layout equivalence

A weighted source list `{A:50, B:30, Empty:20}` has the same independent selection probabilities as an 80% survival gate followed by `{A:62.5%, B:37.5%}`. This does not ensure the same random arrangement, and spatial clustering or other conditional dependencies can make a separated gate inappropriate.

Therefore preserve an explicit `Empty` choice, but do not claim that factoring the probabilities is mathematically impossible. This narrows an overstatement in R0 §4.1.

## 6. Candidate and instance records

A candidate retains provenance and enough information to reevaluate affected stages:

```cpp
struct ResolvedCandidate {
    CandidateId id;
    ContributionId contribution;
    Vec3d resolvedPosition;
    SurfaceBinding binding;
    FieldCoordinates coordinates;
    float densityProbability;
    CandidateFlags flags;
};

struct SurfaceBinding {
    Uuid receiver;
    uint64_t topologyRevision;
    uint32_t triangle;
    Vec2f barycentricUV; // third weight is 1-u-v
    uint32_t evaluationStackFingerprint;
};
```

A final logical instance stores source identity, transform, optional binding, output attributes, and edit state. It need not retain every intermediate sampled field. Optional attributes are separate streams requested by the compiled plan.

## 7. Coordinate and matrix conventions

The core uses meters, radians, and double-precision positions. The Max boundary converts scene units and angle UI values. Frame names are explicit: world, setup-local, receiver-local, source-local, UV, and paint-domain.

Use one documented internal affine convention. For example, column vectors with `world = placement * sourceLocal * point`. The Max adapter performs the required transpose/order conversion; do not copy multiplication expressions between conventions without tests.

Normals transform with the inverse transpose of the linear transform and are renormalized. Negative scale changes handedness. A source or inherited reference can contain shear; either preserve the full affine transform or explicitly reject/decompose it with a documented approximation. Never silently pretend a sheared matrix is pure TRS.

Slope is measured against a saved reference up vector, not the current viewport. Source scale, setup scale, random scale, and output scale must not be applied twice through both host node transforms and instance transforms.

## 8. Memory representation

The authoring model can be object-oriented. Hot data uses contiguous arrays or blocked arrays, selected by benchmarks rather than ideology.

An illustrative TRS instance payload contains:

| Field | Bytes per instance |
|---|---:|
| 128-bit candidate ID | 16 |
| Double XYZ position | 24 |
| Float quaternion | 16 |
| Float XYZ scale | 12 |
| Source dense index | 4 |
| Receiver dense index | 4 |
| Flags | 4 |
| **Total payload** | **80** |

This is payload arithmetic, not a guaranteed `sizeof` for a C++ struct. Container alignment, capacities, bindings, tint, source samples, indices, renderer caches, and old/new snapshots add memory. Five million such payloads require 400 MB decimal, approximately 381.5 MiB, before those extras.

A full affine stream can replace TRS for sheared instances. Do not allocate both for every instance by default. Optional barycentric and authoring metadata can live in cold arrays or sparse stores.

## 9. Snapshot contract

```text
PopulationSnapshot
    scene epoch
    setup/layer UUID
    authoring revision
    input dependency fingerprint
    behavior / algorithm versions
    exactness state
    immutable instance pages
    dense-ID dictionaries
    stage statistics
    diagnostics
```

`exactnessState` distinguishes complete exact output from an intentionally approximate preview. The default publication policy publishes only complete exact populations; brush overlays may update independently.

Renderer and viewport consumers retain shared ownership until use finishes. GPU upload completion is not necessarily GPU use completion; resource retirement follows the output API's synchronization contract.

## 10. Numerical policy

Use explicit tolerances by purpose: geometric length tolerance, angular tolerance, UV tolerance, and probability quantization. Never use one global epsilon for everything.

Hard equality decisions use a saved policy. Collision tangency is non-overlap under the default strict inequality; a user clearance value expands radii explicitly. Polygon boundary points count as inside for include regions and inside for exclusion regions, so an applicable exclusion wins at its boundary.

Exact ID equality is required within the certified deterministic profile. Cross-platform floating-point identity is not promised without testing. Canonical fingerprints may include the numerical profile/compiler family when necessary.

## 11. Tests that block integration

Generate the same fixture with one and several workers; change cache tiles; sort input collections differently; save/reload; change tint; remove a source; raise and lower density; add a vertically stacked receiver. Verify the identity policy above, not merely the final count.

The executable reference in `examples/reference_oracle.py` tests a small subset of these mathematical contracts. It is not a Max implementation or a proof of all geometry behavior.
