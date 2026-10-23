# Cyrus operation budgets

The bundled Clipper2 retains its upstream Boost license and notices. The 0.86.8.3
refinement adds an optional explicit `OperationBudget*` to the 64-bit engine and
offset operation. Default/null callers retain their geometry and ordering; there
is no process-global allocator or thread-local active context.

Bands pass one context through input capture, clipping, nested offset cleanup,
derived output and numerical traversal. Storage admission is a **cumulative
conservative envelope**, not a measurement of live heap allocations. Its fixed
2 MiB allowance and 1,024-byte item charges cover the pinned record sizes,
allocator/container growth, stable-sort scratch and output copies. Freed items
do not earn credits. Input vertices admit their bounded vertex/minimum/scanline
data before allocation; derived points, records, intersections, joins and output
copies are separately charged. Actual traversal and comparator work is bounded.

Detached output points remain context-owned until normal retirement. Vertex
arrays, newly allocated OutRecs and not-yet-linked Active bounds use temporary
RAII ownership. Budget failures unwind without relying on linked geometry alone
to find an allocation that has not yet been attached.

Changing record sizes, allocation sites, container growth policy, new offset
modes or engine version requires reviewing this envelope and its fault tests.
Qualification must compare exact geometry with null-context execution, bounded
peak allocations, failure recovery and unaffected Paint callers. New diagnostics
report admitted storage/work, not process working set or VRAM.
