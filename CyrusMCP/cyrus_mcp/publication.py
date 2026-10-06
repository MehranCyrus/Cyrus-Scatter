"""Passive procedural publication transport. Never read mutable recipe settings
to reconstruct a published instance or its effective collision radius.
"""
import hashlib
from .contracts import require, number, canonical, digest
from .geometry import max_to_column_matrix


def _key(value):
    require(type(value) is str and 1 <= len(value) <= 256 and value.isascii() and
            all(ord(c) >= 32 for c in value), "Invalid publication identity")
    return value


def _array(value, size):
    require(type(value) is list and len(value) == size, "Malformed native publication payload")


def manifest(info):
    _array(info, 9)
    publication_id = _key(info[0])
    number(info[1], 1, 2**53, True)
    number(info[2], -2**31, 2**31, True)
    number(info[3], 1e-12, 1e12)
    number(info[4], 0, 1_000_000, True)
    require(type(info[5]) is list and len(info[5]) <= 10, "Too many published populations")
    sets, ids = [], set()
    for entry in info[5]:
        _array(entry, 10)
        set_id, layer_id = _key(entry[0]), _key(entry[1])
        require(set_id not in ids, "Duplicate published set identity")
        ids.add(set_id)
        for i in range(2, 4):
            number(entry[i], 1, 10, True)
        for i in range(4, 8):
            number(entry[i], 0, 100000, True)
        number(entry[8], -2**31, 2**31, True)
        require(type(entry[9]) is list and len(entry[9]) <= 1024, "Too many source entries")
        sources = []
        for asset in entry[9]:
            _array(asset, 5)
            _key(asset[0]); number(asset[1], 0, 2**53, True)
            require(all(type(v) is bool for v in asset[2:]), "Invalid source flags")
            sources.append(dict(source_entry_id=asset[0], node_handle_at_publication=asset[1],
                                included_in_exact_output=asset[2], point=asset[3], empty=asset[4]))
        sets.append(dict(set_id=set_id, layer_id=layer_id, layer_order=entry[2], set_order=entry[3],
                         count=entry[4], requested=entry[5], attempt_limit=entry[6], admitted_pool=entry[7],
                         sampling_salt=entry[8], sources=sources))
    require(sum(v["count"] for v in sets) == info[4], "Published set counts disagree")
    require(type(info[6]) is list and len(info[6]) <= 90, "Invalid published pair rules")
    rules=[]
    for rule in info[6]:
        _array(rule, 7)
        number(rule[0], 1, 2, True); _key(rule[1]); _key(rule[2])
        require(type(rule[3]) is bool and type(rule[6]) is bool, "Invalid rule flags")
        number(rule[4], 0, 1e12); number(rule[5], 0, 1e12)
        rules.append(dict(scope="paint_sets" if rule[0] == 1 else "layers", a=rule[1], b=rule[2],
                          enabled=rule[3], radius_factor=rule[4], gap_m=rule[5]*info[3],
                          metric="xy" if rule[6] else "xyz"))
    require(type(info[7]) is str and len(info[7]) == 64 and all(c in "0123456789abcdef" for c in info[7]),
            "Loaded script identity is unavailable", "UNSUPPORTED_CAPABILITY")
    require(type(info[8]) is str and len(info[8].encode("utf-8")) <= 8*1024*1024,
            "Published input key exceeds inspection budget", "BUDGET_EXCEEDED")
    result=dict(schema="cyrus.procedural-publication/1.0", publication_id=publication_id,
                publication_epoch=info[1], host_time_value=info[2], metres_per_unit=info[3],
                count=info[4], sets=sets, pair_rules=rules, script_payload_sha256=info[7],
                input_key_sha256=hashlib.sha256(info[8].encode("utf-8")).hexdigest(),
                identity_lifetime="Publication ID is transient and replaced by each successful solve, including reconstruction after reopen. Instance identity is (set_id, instance_id), not output row index.",
                freshness="Last complete publication. Does not certify that pending inputs or source geometry are current.",
                recipe_completeness="Publication identities, budgets and pair rules; input signature is opaque. Full reconstructable recipe/asset export is not implemented.",
                units={"length":"metres","transform":"4x4 column-vector, right-handed Z-up; translation in metres"},
                training_eligible=False)
    require(len(canonical(result).encode()) <= 1_500_000, "Publication manifest exceeds byte budget", "BUDGET_EXCEEDED")
    return result


def page(raw, published, offset, limit):
    number(offset, 0, published["count"], True); number(limit, 1, 500, True)
    _array(raw, 4)
    require(raw[0] == published["publication_id"] and raw[1] == published["count"],
            "Procedural publication changed", "STALE_CONTEXT")
    expected=min(limit, published["count"]-offset)
    require(type(raw[3]) is list and len(raw[3]) == expected and raw[2] == offset+expected,
            "Incomplete procedural publication page")
    rows, seen = [], set()
    for absolute, entry in enumerate(raw[3], offset):
        _array(entry, 7)
        number(entry[0], 1, len(published["sets"]), True)
        owner=published["sets"][entry[0]-1]
        start=sum(s["count"] for s in published["sets"][:entry[0]-1])
        require(start <= absolute < start+owner["count"], "Publication row has the wrong set owner")
        number(entry[2], 1, len(owner["sources"]), True)
        source=owner["sources"][entry[2]-1]
        key=_key(entry[3])
        require((owner["set_id"],key) not in seen, "Duplicate publication row identity")
        seen.add((owner["set_id"],key))
        require(type(entry[4]) is bool and type(entry[6]) is bool and
                entry[6] == source["included_in_exact_output"], "Invalid published output/protection flags")
        number(entry[5], 0, 1e30)
        _array(entry[1], 4)
        for row in entry[1]:
            _array(row, 3)
            for value in row:number(value, -1e30, 1e30)
        matrix=max_to_column_matrix(entry[1], published["metres_per_unit"])
        rows.append(dict(set_id=owner["set_id"],layer_id=owner["layer_id"],instance_id=key,
                         source_entry_id=source["source_entry_id"],transform=matrix,
                         effective_radius_m=entry[5]*published["metres_per_unit"],
                         protected=entry[4],included_in_exact_output=entry[6]))
    result=dict(schema="cyrus.procedural-publication-page/1.0", publication_id=published["publication_id"],
                offset=offset,next_offset=raw[2],total=raw[1],has_more=raw[2]<raw[1],
                rows=rows,rows_sha256=digest(rows),training_eligible=False)
    require(len(canonical(result).encode()) <= 1_500_000, "Publication page exceeds byte budget", "BUDGET_EXCEEDED")
    return result
