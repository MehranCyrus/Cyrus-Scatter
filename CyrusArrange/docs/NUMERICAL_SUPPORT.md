# Numerical support and imported level boards

## Status

This records the imported-shelf defect reproduced on native44 and the bounded
0.1.3 correction promoted for native45 and retained in final native46. The proposed
portable core and the native46 SDK build each pass twelve CTest executables and
117 cases, including unchanged historical goldens. Native46's original-model
probe08 passes 432/0 and imported workflow/render trial passes 612/0. The shelf
publishes twelve full-size props, and all four actual renders have been reviewed.
Historical 0.1.2 archives are unchanged.
Follow [the qualification ledger](RELEASE_VALIDATION_0.1.3.md) for exact results.

## The actual failure

The original CC0 Wooden Bookshelf Worn FBX contains broad, apparently level
boards. Their triangle vertices do not have exactly equal floating-point Z
values. The original source gives broad-board slopes of approximately
0.000028–0.000056 degrees and spans of 0.000238–0.000477 mm. Independent arithmetic
on the exported Max world-coordinate floats gives triangle spans up to about
0.00061 mm and grouped broad-board spans up to about 0.00072 mm. That CSV analysis
does not assert byte identity with the adapter's internal captured buffer.
These values are less than one micron. They are not evidence of a millimetre
warp or an intentionally inclined shelf.

The arrangement inspector requests zero-degree support for upright accessories.
Two separate gates rejected these boards:

1. The inspector's normal-angle comparison was too strict for these imported
   floats in zero-degree mode.
2. The exact footprint query accepted support triangles only when their entire
   Z span was at most 0.0001 mm. That cutoff was much smaller than its existing
   0.002 mm numerical contact tolerance.

The resulting setup found two narrow post tops, but omitted the usable broad
boards. The independent imported workflow stopped at its intended-support
assertion. It did not silently substitute procedural shelves or reduce prop
dimensions to make the test pass.

Standalone inspection at its normal five-degree threshold did find the broad
boards. That did not establish fit for a level accessory: discovery and exact
footprint validation are distinct stages.

## Correction and physical bound

The proposed shared default is **0.002 mm**, or two micrometres. This is the
existing query contact tolerance, not the inspector's separate 0.5 mm
sample-to-plane matching tolerance.

For the inspector's zero-degree mode, an upward triangle can satisfy numerical
flatness when its **entire source Z range** fits this default contact tolerance.
The normal slope path remains available, and all five support rays, winding,
overhead tests and region discovery still run. The source mesh is never flattened
or altered.

The exact query records both the projected polygon and the actual minimum and
maximum Z of its source support triangles. Its one-micron integer height key is
only an index. A candidate at height `h` can use a bin only when:

```text
abs(bin.minimum_z - h) <= contact_tolerance_mm
abs(bin.maximum_z - h) <= contact_tolerance_mm
```

Direct differences avoid admitting a larger gap through outward rounding of
`h + tolerance` at large coordinates. An explicitly configured query tolerance
remains authoritative. Every admitted source point is within the physical
contact band of the candidate's level base; adjacent bins cannot accumulate
transitively into a broad ramp.

Eligible polygons are united **before** applying edge clearance. Otherwise a
numerical height-bin seam would become a false forbidden edge across a continuous
board. The full footprint must still fit the inset union. Holes and true outer
boundaries remain present. Unmodified furniture triangles, obstacle triangles,
accepted-prop collision volumes and any required front-access sweep still run.

The stored minimum/maximum describe the whole bin. A disjoint part elsewhere in
that bin can therefore cause conservative rejection. This design favors rejecting
uncertain support over permitting a floating accessory.

## Work, memory and failures

The common single-bin path avoids the extra union. Multiple-bin queries scan a
fixed bounded height-key range, charge polygon work before copying/union, and
check input and resulting polygon complexity. The retained map allocator counts
the added inline minimum/maximum values through its actual rebound node size;
path capacities and all other retained arrays remain included.

The post-union vertex check is not a strict preallocation scratch-memory limit.
Intersecting input polygons can produce more output vertices than their summed
inputs. The existing quadratic polygon-work admission bounds the accepted input
complexity; temporary clipping buffers still exist before the resulting outline
is checked. Retained cache bytes are not total Max memory or total temporary
solver memory.

Allocation and work-limit exceptions must preserve the previous complete result.
The new native failure-injection fixture exercises temporary multi-bin union and
inset allocations, checks for unreleased allocations, and probes the same retained
query again after the failures. Exact flat-surface behavior remains checked against
the immutable 0.1.2 golden data. The portable draft run passed 113 constructor allocation-failure points and
111 multi-bin probe allocation-failure points, with cleanup and healthy-query
recovery. Those are portable-core results, separate from host publication
qualification.

## Independent evidence and limits

- `build/host-import-workflow-03`: native44 produced 340 passing assertions and
  four failures. Two were a strict test numeric-type mismatch, one was missing
  intended shelf supports, and the last was the resulting deliberate stop.
- `build/imported-workflow-draft/revision-04`: original FBX decoding and the
  explicit Double-only category-weight test repair. The geometry failure is
  separate from that test repair.
- `build/shelf-world-diagnostic-02`: original evaluated world geometry and six
  standalone inspection exports. The captured unit factor is ten millimetres per
  scene system unit; raw exported CSV coordinates must be multiplied by ten.
- `build/shelf-flatness-fix-draft`: frozen numerical support implementation and
  targeted regression fixtures; `build/numeric-support-core-01/receipt.json`
  binds the passing portable build and exact unchanged supporting inputs.
  The promoted native45 SDK build and imported workflow04 also passed.
  Final release qualification remains separate.

The numerical band does not certify gravitational stability, physical contact of
arbitrary curved feet, an intentional inclined arrangement, or a renderer's
displacement surface. Cyrus Arrange continues to place upright conservative
accessory bounds against the captured evaluated geometry. See
[placement](PLACEMENT.md), [geometry sampling](GEOMETRY.md), and
[imported-model qualification](IMPORTED_MODEL_QUALIFICATION.md).
