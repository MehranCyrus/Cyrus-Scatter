"""Offline policy-3 draft compiler. No host adapter or apply authorization.

Keep this separate from the shipped closed plan 1/2 validators. This compiler
checks ownership, ordering, units and work admission before a future host slice
is qualified; it cannot validate actual geometry or promise accepted counts.
"""
from copy import deepcopy
from .contracts import Fault, canonical, digest, fields, identifier, label, number, pair, require

VERSION="3.0-draft1"


def boolean(value):
    require(type(value) is bool, "Expected a boolean")
    return value


def sequence(value, minimum, maximum):
    require(type(value) is list and minimum <= len(value) <= maximum, "Array length exceeds the draft contract")
    return value


def distance(value):
    fields(value, ("enabled","radius_factor","gap_m","metric"))
    boolean(value["enabled"]);number(value["radius_factor"],0,100);number(value["gap_m"],0,1000)
    require(value["metric"] in ("xy","xyz"), "Distance metric must be xy or xyz")
    return deepcopy(value)


def allocate(count, sets):
    """Largest remainder in declared creation order; disabled sets get zero."""
    import math
    weights=[s["weight"] if s["enabled"] else 0 for s in sets]
    total=sum(weights)
    if total<=0:return [0]*len(sets)
    exact=[count*w/total for w in weights]
    quotas=[math.floor(v) for v in exact]
    order=sorted(range(len(sets)),key=lambda i: (-(exact[i]-quotas[i]),i))
    for i in order[:count-sum(quotas)]:quotas[i]+=1
    return quotas


def compile_draft(plan, enrollment):
    try: encoded=canonical(plan).encode()
    except (ValueError,TypeError,RecursionError) as exc:raise Fault("INVALID_PLAN","Draft must contain finite JSON data") from exc
    require(len(encoded) <= 131072, "Procedural draft exceeds 128 KiB", "BUDGET_EXCEEDED")
    fields(plan,("schema_version","name","receiver_id","layers","pair_rules","max_candidates"))
    require(plan["schema_version"]==VERSION,"Unsupported procedural draft version")
    label(plan["name"]);identifier(plan["receiver_id"])
    require(plan["receiver_id"]==enrollment.get("receiver_id"),"Receiver is not enrolled","UNKNOWN_REFERENCE")
    number(plan["max_candidates"],1,20000,True)
    assets={s["source_id"]:s for s in enrollment.get("sources",[])}
    coverages={c["coverage_id"]:c for c in enrollment.get("coverages",[])}
    result=deepcopy(plan)
    owners, all_ids, population_count, work = {},set(),0,0
    layer_ids=set()
    for layer in sequence(result["layers"],1,3):
        fields(layer,("layer_id","name","seed","population","defaults","sets"))
        lid=identifier(layer["layer_id"]);label(layer["name"]);number(layer["seed"],0,2147483646,True)
        require(lid not in all_ids,"Duplicate recipe identity");all_ids.add(lid);layer_ids.add(lid)
        pop=layer["population"]
        fields(pop,("mode","count","attempt_factor","rounds","refill_after_cleanup","underfill"))
        require(pop["mode"] in ("candidate_budget","accepted_target"),"Unsupported population mode")
        number(pop["count"],0,20000,True);number(pop["attempt_factor"],1,32,True);number(pop["rounds"],1,16,True)
        boolean(pop["refill_after_cleanup"]);require(pop["underfill"] in ("allow","reject"),"Unsupported underfill policy")
        defaults=layer["defaults"]
        fields(defaults,("self_rule","between_sets","scale","yaw_degrees","cleanup"))
        distance(defaults["self_rule"]);distance(defaults["between_sets"])
        pair(defaults["scale"],.01,10);pair(defaults["yaw_degrees"],-360,360)
        cleanup=defaults["cleanup"]
        fields(cleanup,("enabled","radius_m","minimum_neighbors","minimum_island","metric"))
        boolean(cleanup["enabled"]);number(cleanup["radius_m"],1e-6,1000)
        number(cleanup["minimum_neighbors"],0,10000,True);number(cleanup["minimum_island"],0,100000,True)
        require(cleanup["metric"] in ("xy","xyz"),"Unsupported cleanup metric")
        earlier=[]
        for s in sequence(layer["sets"],1,10):
            fields(s,("set_id","name","weight","enabled","sampling_salt","sources","self_rule","coverage","background"))
            sid=identifier(s["set_id"]);label(s["name"])
            require(sid not in all_ids,"Duplicate recipe identity");all_ids.add(sid)
            number(s["weight"],0,1000);boolean(s["enabled"]);number(s["sampling_salt"],0,2147483646,True)
            if s["self_rule"]!="inherit":distance(s["self_rule"])
            own_assets=set()
            for source in sequence(s["sources"],1,3):
                fields(source,("source_id","weight","radius_m","radius_follows_scale"))
                aid=identifier(source["source_id"])
                require(aid in assets,"Source is not enrolled","UNKNOWN_REFERENCE")
                require(aid not in own_assets,"Duplicate source in a paint set");own_assets.add(aid)
                number(source["weight"],0,1);number(source["radius_m"],0,100);boolean(source["radius_follows_scale"])
                if pop["mode"]=="accepted_target" and s["enabled"] and source["weight"]>0:
                    require(assets[aid].get("kind","mesh")!="empty", "Accepted targets cannot refill weighted Empty sources")
            require(not s["enabled"] or sum(a["weight"] for a in s["sources"])>0,"Enabled set has no positive source weights")
            coverage=s["coverage"]
            fields(coverage,("mode",),("coverage_id",))
            require(coverage["mode"] in ("whole_surface","existing_brush"),"Unknown coverage mode")
            if coverage["mode"]=="existing_brush":
                cid=identifier(coverage.get("coverage_id"))
                require(cid in coverages and coverages[cid].get("receiver_id")==plan["receiver_id"],
                        "Brush coverage is not enrolled on this receiver","UNKNOWN_REFERENCE")
                require(coverages[cid].get("topology_id")==enrollment.get("topology_id") and
                        enrollment.get("topology_id") is not None,"Brush topology is stale","STALE_CONTEXT")
            else:require("coverage_id" not in coverage,"Whole-surface coverage cannot reference a Brush document")
            background=s["background"]
            fields(background,("mode","earlier_set_ids"))
            require(background["mode"] in ("off","outside_coverage","between_plants","both"),"Unknown background mode")
            refs=sequence(background["earlier_set_ids"],0,9)
            for ref in refs:identifier(ref)
            require(len(set(refs))==len(refs) and set(refs)<=set(earlier),"Background references must name earlier siblings")
            require((background["mode"]=="off")==(len(refs)==0),"Background mode and references disagree")
            if background["mode"] in ("outside_coverage","both"):
                require(all(owners[r]["set"]["coverage"]["mode"]=="existing_brush" for r in refs),
                        "Outside coverage requires earlier enrolled Brush coverage in this draft")
            owners[sid]={"layer":layer,"set":s}
            earlier.append(sid);population_count+=1
        quotas=allocate(pop["count"],layer["sets"])
        for s,quota in zip(layer["sets"],quotas):
            pool=min(100000,quota*(pop["attempt_factor"] if pop["mode"]=="accepted_target" else 1))
            owners[s["set_id"]]["quota"]=quota
            owners[s["set_id"]]["admitted_pool"]=pool
            work+=pool
    require(population_count<=10,"Procedural policy supports ten populations","BUDGET_EXCEEDED")
    require(work<=plan["max_candidates"],"Candidate admission exceeds the declared work budget","BUDGET_EXCEEDED")
    pairs={}
    for rule in sequence(result["pair_rules"],0,45):
        fields(rule,("scope","a","b","distance"))
        require(rule["scope"] in ("paint_sets","layers"),"Unknown rule scope")
        a,b=identifier(rule["a"]),identifier(rule["b"])
        require(a!=b,"A pair requires distinct owners")
        if rule["scope"]=="paint_sets":
            require(a in owners and b in owners and owners[a]["layer"] is owners[b]["layer"],"Set pairs require sibling owners")
        else:require(a in layer_ids and b in layer_ids,"Layer pair references an unknown layer")
        key=(rule["scope"],*sorted((a,b)))
        require(key not in pairs,"Duplicate symmetric pair rule")
        pairs[key]=distance(rule["distance"])
    effective=[]
    for sid,owner in owners.items():
        s,layer=owner["set"],owner["layer"]
        if s["background"]["mode"] in ("between_plants","both"):
            for ref in s["background"]["earlier_set_ids"]:
                rule=pairs.get(("paint_sets",*sorted((sid,ref))),layer["defaults"]["between_sets"])
                require(rule["enabled"] and (rule["radius_factor"]>0 or rule["gap_m"]>0),
                        "Between plants requires a nonzero applicable sibling spacing rule")
        effective.append(dict(set_id=sid,layer_id=layer["layer_id"],quota=owner["quota"],admitted_pool=owner["admitted_pool"],
                              self_rule=deepcopy(layer["defaults"]["self_rule"] if s["self_rule"]=="inherit" else s["self_rule"])))
    return dict(schema="cyrus.procedural-draft-compilation/1.0",normalized=result,plan_sha256=digest(result),
                populations=effective,admitted_candidates=work,mutation_supported=False,
                qualification="Offline ownership/order/units/work validation only. Host application, geometry constraints, final counts and Undo remain unqualified.")
