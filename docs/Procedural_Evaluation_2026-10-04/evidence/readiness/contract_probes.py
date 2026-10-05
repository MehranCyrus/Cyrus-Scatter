"""Design counterexamples and source inventory; NOT the proposed production solver.

Uses exact rational quota arithmetic and tiny, exhaustive fixtures. This tests
the reasoning behind the documented contracts, not Max UI/runtime behavior.
"""
from fractions import Fraction
from pathlib import Path
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def allocate(weights, budget, stable_tie_keys):
    exact = [Fraction(budget * w, sum(weights)) for w in weights]
    result = [int(v) for v in exact]
    remainder = budget - sum(result)
    ranked = sorted(range(len(weights)), key=lambda i: (-(exact[i] - result[i]), stable_tie_keys[i]))
    for i in ranked[:remainder]:
        result[i] += 1
    return result


def replay(cache, logical_batch, consume_whole_cache=False):
    # Two neighboring candidates; cleanup needs one neighbor. A suppressed
    # isolated point is not restored later in this deliberately tiny model.
    stream = [0.0, 0.1]
    available = list(cache)
    suppressed = set()
    final = []
    for end in range(logical_batch, len(stream) + 1, logical_batch):
        if len(available) < end:
            available = stream[:end]
        prefix = available if consume_whole_cache else available[:end]
        accepted = [i for i in range(len(prefix)) if i not in suppressed]
        final = [i for i in accepted if any(j != i and abs(prefix[i] - prefix[j]) < 0.2 for j in accepted)]
        suppressed.update(set(accepted) - set(final))
    return final


def main():
    before = allocate([1500, 1500, 900, 500, 500, 200], 25, list(range(6)))
    after = allocate([1500, 1500, 900, 500, 500, 200], 26, list(range(6)))
    assert before == [7, 7, 4, 3, 3, 1] and after == [8, 8, 5, 2, 2, 1]
    names = ["red", "blue", "yellow"]
    shares = dict(zip(names, allocate([1, 1, 1], 500, [0, 1, 2])))
    reordered = dict(zip(names[::-1], allocate([1, 1, 1], 500, [2, 1, 0])))
    assert shares == reordered
    bad_cold = replay([], 1, True)
    bad_warm = replay([0.0, 0.1], 1, True)
    good_cold = replay([], 1)
    good_warm = replay([0.0, 0.1], 1)
    assert bad_cold != bad_warm and good_cold == good_warm
    assert replay([], 1) != replay([], 2)
    single = sum(a < 50 for a in range(100) for b in range(100))
    double = sum(a < 50 and b < 50 for a in range(100) for b in range(100))
    assert single == 5000 and double == 2500

    inventory = json.loads((ROOT / "AminScatter/tools/ui/layers-control-inventory.json").read_text(encoding="utf-8"))
    counts = {owner: {rollout: len(controls) for rollout, controls in rollouts.items()} for owner, rollouts in inventory.items() if isinstance(rollouts, dict)}
    generated = (ROOT / "AminScatter/scripts/AminScatterObject.ms").read_text(encoding="utf-8")
    fields_line = next(line for line in generated.splitlines() if line.startswith("AminScatterLayerFields=#("))
    base_key = generated.split("fn paintBaseInputKey plants previewOnly = (", 1)[1].split("fn paintCacheStats", 1)[0]
    presentation_in_key = {name: f"#{name}" in fields_line and f"#{name}" not in base_key for name in ("paintSetName", "paintSetVisible")}
    assert all(presentation_in_key.values())
    report = {
        "scope": "Design counterexamples and static inventory; not new-policy implementation or UI execution",
        "quota_25": before, "quota_26": after,
        "reorder_with_stable_allocation_ties": shares,
        "naive_available_cache_cold": bad_cold, "naive_available_cache_warm": bad_warm,
        "fixed_logical_prefix_cold": good_cold, "fixed_logical_prefix_warm": good_warm,
        "batch_one_result": replay([], 1), "batch_two_result": replay([], 2),
        "coverage_50_percent_once": single / 10000,
        "coverage_50_percent_twice_independent": double / 10000,
        "inventory_counts": counts,
        "set_owned_rollouts_within_layer_inventory": inventory["set"],
        "inventory_total_entries": sum(sum(rollouts.values()) for rollouts in counts.values()),
        "presentation_fields_in_prepared_base_key": presentation_in_key,
        "literal_policy_2_sites_in_generated_script": len(re.findall(r"groupPolicy\s*(?:==|!=)\s*2", generated)),
    }
    (HERE / "contract-probes.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
