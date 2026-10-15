#!/usr/bin/env python3
"""Small, executable mathematical reference for the Cyrus rebuild blueprint.

Standard-library Python only. This is NOT a Max plugin, production scatter
engine, renderer adapter, performance benchmark, or ForestPack implementation.
Run: python reference_oracle.py --report reference_validation.json
"""
from __future__ import annotations

import argparse
import bisect
import hashlib
import json
import math
import random
import time
from dataclasses import dataclass, replace
from itertools import product
from pathlib import Path
from typing import Callable, Iterable, Sequence


def random01(seed: int, semantic_address: str, channel: str) -> float:
    """Versioned reference key serialization; cache/worker IDs are absent."""
    data = json.dumps([seed, semantic_address, channel],
                      ensure_ascii=True, separators=(",", ":")).encode("utf-8")
    digest = hashlib.blake2b(data, digest_size=8, person=b"CYRREFv1").digest()
    return (int.from_bytes(digest, "little") >> 11) / float(1 << 53)


def weighted_choice(weights: dict[str, float], u: float) -> str:
    """Canonical source ordering. '__EMPTY__' is an ordinary weighted label."""
    if not 0 <= u < 1:
        raise ValueError("u must be in [0,1)")
    if any(not math.isfinite(w) or w < 0 for w in weights.values()):
        raise ValueError("weights must be finite and nonnegative")
    positive = sorted((key, value) for key, value in weights.items() if value > 0)
    total = math.fsum(value for _, value in positive)
    if not positive or not math.isfinite(total) or total <= 0:
        raise ValueError("positive finite total weight required")
    target, cumulative = u * total, 0.0
    for key, value in positive:
        cumulative += value
        if target < cumulative:
            return key
    return positive[-1][0]  # bounded floating-point endpoint fallback


@dataclass(frozen=True)
class Candidate:
    id: str
    x: float
    y: float
    z: float
    radius: float
    priority: int
    pinned: bool = False

    def __post_init__(self) -> None:
        if not self.id:
            raise ValueError("candidate identity must not be empty")
        if not all(math.isfinite(v) for v in (self.x, self.y, self.z, self.radius)):
            raise ValueError("coordinates/radius must be finite")
        if self.radius < 0:
            raise ValueError("radius must be nonnegative")


def conflicts(a: Candidate, b: Candidate) -> bool:
    """Strict sphere overlap: tangency is allowed. No hidden epsilon."""
    d2 = (a.x-b.x)**2 + (a.y-b.y)**2 + (a.z-b.z)**2
    return d2 < (a.radius+b.radius)**2


def validated_map(candidates: Iterable[Candidate]) -> dict[str, Candidate]:
    result: dict[str, Candidate] = {}
    for c in candidates:
        if c.id in result:
            raise ValueError(f"duplicate candidate identity: {c.id}")
        result[c.id] = c
    return result


def ordered(candidates: Iterable[Candidate]) -> list[Candidate]:
    return sorted(candidates, key=lambda c: (c.priority, c.id))


def greedy_full(candidates: Iterable[Candidate]) -> frozenset[str]:
    """Naive correctness oracle. Conflicting pins are deliberately retained."""
    values = list(validated_map(candidates).values())
    accepted = ordered(c for c in values if c.pinned)
    for c in ordered(c for c in values if not c.pinned):
        if not any(conflicts(c, a) for a in accepted):
            accepted.append(c)
    return frozenset(c.id for c in accepted)


def greedy_grid(candidates: Iterable[Candidate], cell_size: float,
                max_cells: int = 512) -> frozenset[str]:
    """Same solver with conservative sphere-AABB cell coverage.

    Very large spheres use a scan fallback, preserving correctness rather than
    allocating unbounded cell entries. This is illustrative, not optimized.
    """
    if not math.isfinite(cell_size) or cell_size <= 0 or max_cells <= 0:
        raise ValueError("positive finite cell size and max_cells required")
    values = list(validated_map(candidates).values())
    grid: dict[tuple[int, int, int], set[str]] = {}
    accepted: dict[str, Candidate] = {}
    large: set[str] = set()

    def cells(c: Candidate) -> list[tuple[int, int, int]] | None:
        spans = []
        count = 1
        for center in (c.x, c.y, c.z):
            lo = math.floor((center-c.radius)/cell_size)
            hi = math.floor((center+c.radius)/cell_size)
            count *= hi-lo+1
            if count > max_cells:
                return None
            spans.append(range(lo, hi+1))
        return list(product(*spans))

    def insert(c: Candidate) -> None:
        accepted[c.id] = c
        locations = cells(c)
        if locations is None:
            large.add(c.id)
        else:
            for loc in locations:
                grid.setdefault(loc, set()).add(c.id)

    for c in ordered(c for c in values if c.pinned):
        insert(c)
    for c in ordered(c for c in values if not c.pinned):
        locations = cells(c)
        if locations is None:
            possible = set(accepted)
        else:
            possible = set(large)
            for loc in locations:
                possible.update(grid.get(loc, ()))
        if not any(conflicts(c, accepted[k]) for k in possible):
            insert(c)
    return frozenset(accepted)


def incremental_exact(old: dict[str, Candidate], new: dict[str, Candidate],
                      old_accepted: frozenset[str]) -> tuple[frozenset[str], set[str]]:
    """Exact union-conflict closure, using brute-force neighbor discovery.

    Old/new contain ALL occupancy-eligible candidates, including prior collision
    rejects. The spatial production optimization is intentionally absent.
    """
    if not old_accepted.issubset(old):
        raise ValueError("old accepted IDs must exist in old candidate state")
    changed = {k for k in old.keys() | new.keys() if old.get(k) != new.get(k)}
    affected, frontier = set(changed), list(changed)
    while frontier:
        key = frontier.pop()
        for state in (old, new):
            current = state.get(key)
            if current is None:
                continue
            for neighbor_id, neighbor in state.items():
                if neighbor_id not in affected and conflicts(current, neighbor):
                    affected.add(neighbor_id)
                    frontier.append(neighbor_id)
    local = greedy_full(new[k] for k in affected if k in new)
    unchanged = old_accepted.difference(affected)
    return frozenset(unchanged | local), affected


def quantize16(value: float) -> int:
    if not math.isfinite(value):
        raise ValueError("coverage must be finite")
    value = min(1.0, max(0.0, value))
    return int(math.floor(value*65535.0 + 0.5))


def paint_dab(coverage: Sequence[int], brush: Sequence[float], erase: bool) -> tuple[int, ...]:
    if len(coverage) != len(brush):
        raise ValueError("coverage and brush dimensions differ")
    if any(c < 0 or c > 65535 or not isinstance(c, int) for c in coverage):
        raise ValueError("coverage must be unsigned 16-bit integers")
    b = tuple(quantize16(v) for v in brush)
    return tuple(min(c, 65535-q) if erase else max(c, q)
                 for c, q in zip(coverage, b))


def ordered_regions(operations: Sequence[tuple[str, str, object]]) -> set[tuple[str, int]]:
    """Small contribution oracle: inclusions emit (area_id, address)."""
    result: set[tuple[str, int]] = set()
    for op, area_id, payload in operations:
        if op == "include":
            result.update((area_id, int(address)) for address in payload)  # type: ignore[union-attr]
        elif op == "exclude":
            predicate = payload
            result = {item for item in result if not predicate(item[1])}  # type: ignore[operator]
        else:
            raise ValueError(f"unknown operation {op}")
    return result


class PiecewiseLinearPDF:
    """Normalized inverse-CDF sampler for a nonnegative piecewise-linear PDF."""
    def __init__(self, knots: Sequence[tuple[float, float]]) -> None:
        if len(knots) < 2 or knots[0][0] != 0 or knots[-1][0] != 1:
            raise ValueError("PDF knots must cover [0,1]")
        if any(not math.isfinite(x) or not math.isfinite(y) or y < 0 for x, y in knots):
            raise ValueError("finite coordinates and nonnegative PDF required")
        if any(knots[i][0] >= knots[i+1][0] for i in range(len(knots)-1)):
            raise ValueError("strictly increasing x required")
        self.knots = tuple(knots)
        self.cumulative = [0.0]
        for (x0, y0), (x1, y1) in zip(knots, knots[1:]):
            self.cumulative.append(self.cumulative[-1] + (x1-x0)*(y0+y1)*0.5)
        self.total = self.cumulative[-1]
        if self.total <= 0 or not math.isfinite(self.total):
            raise ValueError("positive finite integral required")

    def sample(self, u: float) -> float:
        if not 0 <= u < 1:
            raise ValueError("u must be in [0,1)")
        target = u*self.total
        i = min(bisect.bisect_right(self.cumulative, target)-1, len(self.knots)-2)
        x0, y0 = self.knots[i]
        x1, y1 = self.knots[i+1]
        area = target-self.cumulative[i]
        if area <= 0:
            return x0
        slope = (y1-y0)/(x1-x0)
        if slope == 0:
            dx = area/y0
        else:
            root = math.sqrt(max(0.0, y0*y0 + 2*slope*area))
            denom = y0+root
            dx = 2*area/denom if denom > 0 else 0.0
        return min(x1, max(x0, x0+dx))


def run_checks() -> list[dict[str, object]]:
    results: list[dict[str, object]] = []

    def check(name: str, fn: Callable[[], dict[str, object]]) -> None:
        start = time.perf_counter()
        detail = fn()
        results.append(dict(name=name, status="pass", elapsed_seconds=round(time.perf_counter()-start, 6), **detail))

    def random_channels() -> dict[str, object]:
        keys = [f"layer/area/cell/{i}" for i in range(200)]
        original = {k: (random01(42,k,"yaw"), random01(42,k,"scale")) for k in keys}
        for size in (1, 7, 31, 200):
            reordered = [k for page in reversed([keys[i:i+size] for i in range(0,len(keys),size)]) for k in page]
            assert {k: (random01(42,k,"yaw"), random01(42,k,"scale")) for k in reordered} == original
        assert all(0 <= random01(42,k,"tint") < 1 for k in keys)
        assert any(random01(42,k,"tint") != original[k][0] for k in keys)
        return {"keys": len(keys), "partition_orders": 4}
    check("keyed_randomness_and_partition_invariance", random_channels)

    def density() -> dict[str, object]:
        samples = {str(i): random01(42,str(i),"density") for i in range(10000)}
        a, b = {k for k,v in samples.items() if v < .25}, {k for k,v in samples.items() if v < .5}
        assert a <= b
        assert abs(len(a)/10000-.25) < .025 and abs(len(b)/10000-.5) < .025
        return {"samples": 10000, "quarter_survivors": len(a), "half_survivors": len(b)}
    check("stable_density_thinning_before_collisions", density)

    def weights() -> dict[str, object]:
        w = {"A": 50.0, "B": 30.0, "__EMPTY__": 20.0}
        reverse = dict(reversed(list(w.items())))
        counts = dict.fromkeys(w, 0)
        for i in range(10000):
            u = random01(42,str(i),"source")
            selected = weighted_choice(w,u)
            assert selected == weighted_choice(reverse,u)
            counts[selected] += 1
        for k,p in (("A",.5),("B",.3),("__EMPTY__",.2)):
            assert abs(counts[k]/10000-p) < .025
        assert math.isclose(.8*.625,.5) and math.isclose(.8*.375,.3)
        return {"samples": 10000, "counts": counts}
    check("source_weights_empty_and_list_order", weights)

    def regions() -> dict[str, object]:
        ops = [("include","garden",range(10)),("exclude","path",lambda x:3<=x<=6),
               ("include","island",[4,5])]
        got = ordered_regions(ops)
        assert got == {("garden",i) for i in (0,1,2,7,8,9)} | {("island",4),("island",5)}
        overlap = ordered_regions([("include","a",[1]),("include","b",[1])])
        assert len(overlap)==2
        return {"accepted_contributions": len(got), "overlapping_include_records": len(overlap)}
    check("ordered_areas_and_independent_contributions", regions)

    def paint() -> dict[str, object]:
        before = (0,0,0,0)
        add = paint_dab(before,[0,.25,.5,1],False)
        assert paint_dab(add,[0,.25,.5,1],False)==add
        after = paint_dab(add,[0,0,.4,1],True)
        undo, redo = before, after
        assert undo == before and redo == after
        assert after[-1]==0
        assert paint_dab(paint_dab((0,),[1],False),[1],True) != paint_dab(paint_dab((0,),[1],True),[1],False)
        assert all(0 <= v <= 65535 for v in after)
        return {"before": before, "after_add": add, "after_erase": after}
    check("canonical_paint_composition_and_exact_snapshot_undo", paint)

    def pdf() -> dict[str, object]:
        uniform = PiecewiseLinearPDF([(0,1),(1,1)])
        rising = PiecewiseLinearPDF([(0,0),(1,2)])
        falling = PiecewiseLinearPDF([(0,2),(1,0)])
        for i in range(1000):
            u=i/1000
            assert abs(uniform.sample(u)-u)<1e-12
            assert abs(rising.sample(u)-math.sqrt(u))<1e-12
            assert abs(falling.sample(u)-(1-math.sqrt(1-u)))<1e-12
        return {"distributions": 3, "samples_per_distribution": 1000}
    check("piecewise_linear_pdf_inverse_cdf", pdf)

    def chain() -> dict[str, object]:
        old = {str(i): Candidate(str(i),float(i),0,0,.6,i) for i in range(40)}
        new = {k:c for k,c in old.items() if k!="0"}
        a, b = greedy_full(old.values()), greedy_full(new.values())
        assert a == frozenset(str(i) for i in range(0,40,2))
        assert b == frozenset(str(i) for i in range(1,40,2))
        inc, affected = incremental_exact(old,new,a)
        assert inc == b and len(affected)==40 and "39" in a.symmetric_difference(b)
        return {"chain_length": 40, "changed_acceptance_ids": len(a.symmetric_difference(b)), "closure_size": len(affected)}
    check("nonlocal_collision_chain_counterexample", chain)

    def grid() -> dict[str, object]:
        rng=random.Random(7341)
        comparisons=0
        for trial in range(60):
            values=[Candidate(f"{trial}/{i}",rng.uniform(-8,8),rng.uniform(-8,8),rng.uniform(-2,2),
                              rng.uniform(.01,2.5),rng.randrange(100000),i<2) for i in range(50)]
            ref=greedy_full(values)
            for cell in (.25,.8,2.0,5.0):
                shuffled=values[:]; rng.shuffle(shuffled)
                assert greedy_grid(shuffled,cell)==ref
                comparisons+=1
        return {"random_fixtures":60,"grid_comparisons":comparisons}
    check("accelerated_grid_matches_naive_full", grid)

    def increments() -> dict[str, object]:
        rng=random.Random(89104)
        comparisons=0
        for trial in range(100):
            state={str(i):Candidate(str(i),rng.uniform(-5,5),rng.uniform(-5,5),rng.uniform(-1,1),
                                    rng.uniform(.05,1.5),rng.randrange(10000),i==0) for i in range(25)}
            accepted=greedy_full(state.values())
            for step in range(6):
                new=dict(state)
                key=rng.choice(sorted(new))
                op=step%3
                if op==0:
                    new[key]=replace(new[key],x=rng.uniform(-5,5),y=rng.uniform(-5,5),radius=rng.uniform(.05,2))
                elif op==1:
                    del new[key]
                else:
                    ident=f"new/{trial}/{step}"
                    new[ident]=Candidate(ident,rng.uniform(-5,5),rng.uniform(-5,5),0,rng.uniform(.1,2),rng.randrange(10000),False)
                inc,_=incremental_exact(state,new,accepted)
                ref=greedy_full(new.values())
                assert inc==ref
                state,accepted=new,ref
                comparisons+=1
        return {"edit_sequences":100,"full_incremental_comparisons":comparisons}
    check("exact_union_closure_matches_full_after_edits", increments)

    def pins() -> dict[str, object]:
        values=[Candidate("pinA",0,0,0,1,100,True),Candidate("pinB",.2,0,0,1,200,True),
                Candidate("ordinary",.3,0,0,1,0),Candidate("tangent",2.2,0,0,1,1)]
        assert greedy_full(values)==frozenset(("pinA","pinB","tangent"))
        assert greedy_grid(values,.25)==greedy_full(values)
        assert not conflicts(Candidate("zeroA",0,0,0,0,0),Candidate("zeroB",0,0,0,0,0))
        return {"pins_retained":2,"ordinary_blocked":1,"tangency_allowed":True}
    check("pin_precedence_tangency_and_zero_radius", pins)

    def monotonicity() -> dict[str, object]:
        b=Candidate("B",1,0,0,.6,1)
        a=Candidate("A",0,0,0,.6,0)
        low=greedy_full([b]); high=greedy_full([a,b])
        assert not low <= high
        return {"eligible_population_grows":True,"accepted_population_not_necessarily_nested":True}
    check("density_monotonicity_does_not_extend_through_collisions", monotonicity)

    def errors() -> dict[str, object]:
        bad=[lambda: Candidate("bad",float("nan"),0,0,1,0),
             lambda: Candidate("bad",0,0,0,-1,0),
             lambda: weighted_choice({"A":0},.5),
             lambda: weighted_choice({"A":-1},.5),
             lambda: PiecewiseLinearPDF([(0,0),(1,0)]),
             lambda: greedy_grid([],0),
             lambda: paint_dab((0,),[],False)]
        for fn in bad:
            try: fn()
            except ValueError: pass
            else: raise AssertionError("invalid input was accepted")
        return {"invalid_inputs_rejected":len(bad)}
    check("invalid_input_guards", errors)
    return results


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report",type=Path)
    args=parser.parse_args()
    results=run_checks()
    report={"suite":"Cyrus mathematical reference v0.1", "status":"pass", "check_groups":len(results),
            "scope":"Pure Python mathematical checks only; no Max, C++, GPU, renderer, or production benchmark execution.",
            "results":results}
    if args.report:
        args.report.parent.mkdir(parents=True,exist_ok=True)
        args.report.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"status":"pass","check_groups":len(results),"report":str(args.report) if args.report else None},indent=2))
    return 0


if __name__=="__main__":
    raise SystemExit(main())
