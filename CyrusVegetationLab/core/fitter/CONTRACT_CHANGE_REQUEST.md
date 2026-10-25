# Contract change request — bounded collision-query storage

**Owner:** B, rooted static fitter.  
**Edition:** `CyrusScatter_Vegetation_Core_Handoff_v1`.  
**Starting frozen header SHA-256:** `f5c9b72e513a1c6ceea74f79bc0005175381691b65c99af47dc2debaebc7e42f`.

**Disposition:** request for the coordinator's next interface revision; no frozen file is changed by this handback. The current implementation remains usable with its explicitly scoped accounting. This request is not a claim that a new interface or a production collision backend has been executed.

## Gap in the frozen interface

`CollisionWorld::classify_point` and `CollisionWorld::query_capsule` return owning `std::vector` objects. Their `Issue` entries also own `std::string` objects. A backend allocates these objects, and any temporary scratch space, before B receives the return value. Neither call accepts a remaining byte budget, caller-owned output storage, an allocation resource, or an observable backend allocation counter.

B can reject a returned result with excessive element counts or capacities, and can decline to accept a candidate after that rejection. B cannot prevent those already-completed allocations, observe the backend's earlier scratch peak, cancel an allocation or an opaque backend loop, or infer those costs from the final vector capacities. `max_contacts_per_query` limits contact count; it is not a bound on vector capacity, issue text, or backend scratch.

Consequently the frozen interface cannot support a strict aggregate, per-call allocation cap spanning B and an arbitrary `CollisionWorld`. This is a precise interface limitation, rather than a reason to replace whole-span queries with weaker contact tests.

## What this B implementation can enforce and report

The implementation admits its large private buffers against the supplied budget, uses a counting allocator for private numerical buffers, accounts for output pose vector capacities, reserves a declared fixed allowance for the context and bounded diagnostic/local state, and inspects returned query vector and issue-string capacities. It rejects over-budget observed query payloads instead of accepting a candidate.

`peak_owned_and_scratch_bytes` is therefore a high-water accounting value for the declared B-controlled and observable payload scope. Fixed allowance bytes are a bound, not a measured stack watermark. Requested payload bytes and container capacities are not allocator metadata, operating-system resident memory, or an opaque backend's transient allocation peak. Borrowed inputs and the pre-existing collision world's persistent storage are not B-owned allocations. Admission failures may occur before working storage is established; the return report describes that accounting convention separately.

A returned query can already have exceeded the requested aggregate budget before B detects it. That unavoidable v1 behavior must remain visible in integration documentation; post-return rejection is not a strict total-memory guarantee. Cancellation latency likewise depends on the backend honoring the supplied cancellation token during its work.

## Smallest useful next-interface extension

Add a synchronous, budget-aware query path without changing the geometric semantics:

1. The caller supplies bounded output storage for contacts or point hits. The returned metadata contains outcome, generation, completeness and written/required counts. Diagnostics use bounded caller storage or fixed-size codes; unconstrained owning diagnostic strings must not bypass the budget.
2. The same call receives a remaining allocation-budget resource or reservation interface for all backend-owned temporary allocation requests. It must refuse a request before allocation when the shared remaining payload budget would be exceeded. Backend workspaces may instead be supplied entirely by the caller where that is practical.
3. The backend reports the query's instrumented temporary high-water mark and any opaque/unaccounted allocation category. Its reported accounting scope uses the same payload-byte convention as B. A high-water report alone is useful evidence but is insufficient to enforce a cap after allocation has happened.
4. Buffer or scratch exhaustion returns `ResourceLimit`, `complete=false`, and no usable clearance certificate. Partial output is diagnostic. Query cancellation remains explicit and must be checked in bounded backend loops.

An equivalent design can use an explicitly shared, budget-enforcing memory resource for both owning results and backend scratch. Merely adding that resource as an argument while retaining uninstrumented allocations through ordinary `std::vector`/`std::string` does not close the gap. A caller-owned-output overload avoids forcing a change to the frozen owning-result types and provides a narrow migration path.

The coordinator should define whether the cap covers only the solve plus transient query work, or also admission/build and persistent world storage. Persistent snapshot/backend memory should be reported by A and counted once at its owning scope, not guessed or repeatedly charged by B. A strict allocator-request payload cap still does not claim an exact operating-system memory cap.

## Acceptance experiments for the revised interface

- A fake backend attempts a scratch reservation larger than the shared remaining budget: reservation fails before allocation; B cannot return `ConvergedCandidate`.
- Contact or point output exceeds borrowed capacity: non-Ok incomplete result, with no out-of-bounds write and no fallback allocation.
- Backend diagnostic output reaches its bound: a bounded diagnostic code remains possible and no unbudgeted string is created.
- B and the backend simultaneously hold temporary data: the shared high-water value reflects their overlapping live payloads, without double-counting borrowed output storage.
- Cancellation during backend enumeration releases all temporary reservations, leaves caller-owned previous results untouched, and returns no candidate.

These are proposed next-interface acceptance tests. They are not executed results of this v1 handback.

## Other frozen wording

`SHARED-CONTRACT.md` says not to report convergence while the independent visible-mesh check is missing. The user assignment explicitly requires B to return `ConvergedCandidate` after its own complete guide/constraint checks, with C's independent validation still pending. This module follows that explicit candidate distinction. Clarifying the sentence to distinguish a B candidate from final integration acceptance would remove the wording ambiguity; no flag, mesh-validation claim or header change is added here.

## Source basis

This request follows the inspected frozen header's `CollisionWorld`, `PointResult`, `ContactResult`, `Issue`, `Limits` and `SolveMetrics` declarations, and the frozen shared contract's admission, failure-isolation and memory-reporting requirements. It is a source-level interface analysis. It does not rely on a claim about Jolt allocation behavior, an implementation by owner A, or a renderer/host run.
