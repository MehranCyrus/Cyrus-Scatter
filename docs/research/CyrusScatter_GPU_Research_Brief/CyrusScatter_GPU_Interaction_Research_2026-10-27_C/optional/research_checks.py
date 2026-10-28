#!/usr/bin/env python3
"""Researcher A: arithmetic and analytic controls, NOT a GPU/Max benchmark.

Python 3.10+, standard library only. No third-party engine/source required.
Run: python optional/research_checks.py --output optional/executed_checks.json
"""
import argparse
import hashlib
import json
import math
import platform
import struct
from pathlib import Path


def canonical_hash(value):
    raw = json.dumps(value, sort_keys=True, separators=(",", ":"), allow_nan=False)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def f32(x):
    return struct.unpack("<f", struct.pack("<f", x))[0]


def f32_ulp(x):
    bits = struct.unpack("<I", struct.pack("<f", x))[0]
    return struct.unpack("<f", struct.pack("<I", bits + 1))[0] - f32(x)


def sub(a, b):
    return [x - y for x, y in zip(a, b)]


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def norm(v):
    return math.sqrt(dot(v, v))


def sphere_segment(a, b, center, radius, guide_radius, gap):
    direction = sub(b, a)
    denom = dot(direction, direction)
    if denom == 0:
        raise ValueError("Degenerate segment: separate point-query policy required")
    u = min(1.0, max(0.0, dot(sub(center, a), direction) / denom))
    q = [a[j] + u * direction[j] for j in range(3)]
    delta = sub(q, center)
    distance = norm(delta)
    if distance == 0:
        return {"u": u, "gap": -radius-guide_radius-gap, "normal_unique": False}
    normal = [x / distance for x in delta]
    witness = [center[j] + radius * normal[j] for j in range(3)]
    signed_gap = distance - radius - guide_radius - gap
    residual = norm(sub(sub(q, witness), [normal[j] * (signed_gap + guide_radius + gap) for j in range(3)]))
    return {"u": u, "gap": signed_gap, "normal_unique": True,
            "normal": normal, "guide_center": q, "solid_witness": witness,
            "reconstruction_residual": residual}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    checks = []

    def check(name, predicate, observed):
        if not predicate:
            raise AssertionError(name + ": " + repr(observed))
        checks.append({"id": name, "status": "PASS", "observed": observed})

    fixture = {"units": "metres", "up": "+Y", "seed": 20261027,
               "segment": [[-2.0, 0.5, 0.0], [2.0, 0.5, 0.0]],
               "sphere": {"center": [0.0, 0.0, 0.0], "radius": 1.0},
               "guide_radius": 0.1, "contact_gap": 0.05}
    a, b = fixture["segment"]
    result = sphere_segment(a, b, [0., 0., 0.], 1., .1, .05)
    check("X01_endpoints_outside_segment_contact", norm(a) > 1.15 and norm(b) > 1.15 and result["gap"] < 0,
          {"endpoint_distance": norm(a), "minimum_signed_gap": result["gap"]})
    check("X02_analytic_u_normal_witness", abs(result["u"] - .5) < 1e-14 and result["normal"] == [0., 1., 0.] and result["reconstruction_residual"] < 1e-14, result)

    root_distance, r, contact_gap, hide_margin = 1.02, 1.0, .05, 0.0
    check("X03_fixed_root_exclusion_contact_independence", root_distance > r + hide_margin and root_distance < r + contact_gap,
          {"hidden_by_inside_solid_margin": False, "violates_fixed_root_contact_clearance": True,
           "required_policy": "infeasible, retain preceding complete result"})

    # No boundary crossing is necessary when both endpoints are inside a solid.
    inside_a, inside_b = [-.1, 0., 0.], [.1, 0., 0.]
    check("X04_fully_inside_segment", norm(inside_a) < 1 and norm(inside_b) < 1,
          {"endpoints_inside": True, "segment_sphere_surface_crossings": 0,
           "empty_surface_crossings_implies_outside": False})

    # A broad leaf can intersect the sphere although its supporting line is clear.
    clear_guide = sphere_segment([-2., 1.2, 0.], [2., 1.2, 0.], [0., 0., 0.], 1., .01, .0)
    leaf_vertex = [0., .9, 0.]
    check("X05_clear_guide_penetrating_leaf", clear_guide["gap"] > 0 and norm(leaf_vertex) < 1,
          {"guide_gap": clear_guide["gap"], "leaf_vertex_signed_distance": norm(leaf_vertex) - 1})

    origin, offset = 1_000_000.0, .001
    lost = f32(origin + offset) - f32(origin)
    rebased = f32((origin + offset) - origin)
    check("X06_rebase_before_float_conversion", lost == 0.0 and abs(rebased - offset) < 1e-9,
          {"world_float_delta": lost, "double_subtract_then_float_delta": rebased,
           "world_float_ulp_m": f32_ulp(origin)})

    # 1-Lipschitz distance trilinear interpolant error bound h*sqrt(3)/2.
    # This is a deterministic sampling check of the derivation, not certification
    # of a mesh SDF builder, field sign, gradients, or an entire continuous domain.
    h = .1
    center = [.03, .02, .01]
    bound = math.sqrt(3.0) * h / 2
    worst = 0.
    for i in range(11):
        for j in range(11):
            for k in range(11):
                t = [i / 10, j / 10, k / 10]
                p = [h * z for z in t]
                approximate = 0.
                for mask in range(8):
                    bits = [(mask >> d) & 1 for d in range(3)]
                    w = math.prod(t[d] if bits[d] else 1-t[d] for d in range(3))
                    corner = [h * b for b in bits]
                    approximate += w * (norm(sub(corner, center)) - .05)
                exact = norm(sub(p, center)) - .05
                worst = max(worst, abs(approximate - exact))
    check("X07_sampled_sdf_interpolation_bound", worst <= bound + 1e-14,
          {"samples": 1331, "max_observed_error_m": worst, "derived_bound_m": bound,
           "gradient_or_solid_sign_certification": False})

    # Count/scan overflow control illustrates completeness status, not a GPU collector.
    counts, budget = [3, 4, 6], 10
    total = sum(counts)
    status = "IncompleteBudgetExceeded" if total > budget else "Complete"
    check("X08_incomplete_never_clear", status != "Complete",
          {"count": total, "budget": budget, "status": status, "clear_allowed": status == "Complete" and total == 0})

    g, nodes, vertices, triangles = 451, 8, 22032, 27501
    pose_per_instance = g * (16 + nodes * 32)
    budgets = []
    for n, k, changed_per_instance in [(1000, 1, 1), (10000, 10, 6), (100000, 100, 6), (1000000, 10, 6),
                                        (1000000, 1000, 451), (1000000, 10000, 451), (1000000, 1000000, 451)]:
        hd = k * changed_per_instance
        qd = hd * nodes
        budgets.append({"N": n, "K_assumed_D": k, "changed_guides_per_instance": changed_per_instance,
                        "instance_plus_index_bytes": n * (80 + 32 + 64),
                        "pose_bytes_excluding_instance_headers_masks": hd * 16 + qd * 32,
                        "float_pos_normal_tangent_unique_geometry_bytes": k * vertices * 40,
                        "full_guide_directory_uint32_bytes": n * g * 4})
    check("X09_dense_pose_and_geometry_arithmetic", pose_per_instance == 122672 and vertices * 40 == 881280,
          {"all_guide_pose_bytes_per_instance": pose_per_instance, "unique_vertex_bytes_per_instance": vertices*40,
           "million_full_poses_bytes": 1_000_000 * pose_per_instance,
           "million_unique_vertex_stream_bytes": 1_000_000 * vertices * 40})

    uv = [[0., 0.], [1., 0.], [0., 1.], [1., 1.]]
    simple_ribbon = {"positions": [[x, i * .1, 0.] for i in range(8) for x in [-.01, .01]],
                     "triangles": [[2*i, 2*i+1, 2*i+2] for i in range(7)] + [[2*i+1, 2*i+3, 2*i+2] for i in range(7)],
                     "guide_nodes": [[0., i * .1, 0.] for i in range(8)],
                     "root_vertex_indices": [0, 1], "units": "metres", "up": "+Y"}
    check("X10_fixture_counts", len(simple_ribbon["positions"]) == 16 and len(simple_ribbon["triangles"]) == 14,
          {"render_vertices": 16, "triangles": 14, "guide_nodes": 8,
           "geometry_sha256_canonical_json": canonical_hash(simple_ribbon)})

    output = {
        "schema": "cyrus.gpu.research.analytic-checks/1",
        "researcher": "A", "execution": "Executed Python arithmetic and analytic controls only",
        "not_executed": ["GPU kernels", "Max", "production CPU fitter", "renderers", "timing benchmark"],
        "python": platform.python_version(), "system": platform.system(),
        "passed": len(checks), "checks": checks,
        "fixture": fixture, "fixture_sha256_canonical_json": canonical_hash(fixture),
        "prepared_ribbon_fixture": simple_ribbon,
        "assumptions": {"nodes_per_guide": 8, "note": "Hypothesis; not supplied451guide source node count",
                        "pose_node_bytes": 32, "delta_guide_header_bytes": 16,
                        "mutable_graphics_vertex_bytes": 40, "transfer_rate_bytes_per_second": 16e9},
        "budgets": budgets,
        "float32_spacing_m": {str(x): f32_ulp(x) for x in [1., 10., 32., 100., 10000., 1000000.]},
        "transfer_floor_ms": {"1000_full_poses_one_way": 1000*pose_per_instance/16e9*1000,
                              "1000_full_vertex_streams_one_way": 1000*vertices*40/16e9*1000},
        "dense_sdf_bytes": {"256_cubed_float32": 256**3*4, "512_cubed_float32": 512**3*4,
                            "1024_cubed_float32": 1024**3*4},
        "dense_span_collider_pairs_10k_grass_64_colliders": 10000*g*(nodes-1)*64
    }
    serialized = json.dumps(output, indent=2, sort_keys=True, allow_nan=False) + "\n"
    if args.output:
        args.output.write_text(serialized, encoding="utf-8")
    print(json.dumps({"status": "PASS", "checks": len(checks), "output": str(args.output) if args.output else None,
                      "fixture_sha256": output["fixture_sha256_canonical_json"]}))
    if not args.output:
        print(serialized)


if __name__ == "__main__":
    main()
