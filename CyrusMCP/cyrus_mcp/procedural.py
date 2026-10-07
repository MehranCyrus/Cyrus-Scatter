"""Read-only unified recipe/last-publication export; no host evaluation calls."""

RULE_FIELDS = ("procRuleScope", "procRuleA", "procRuleB", "procRuleEnabled",
               "procRuleMultiplier", "procRuleGap", "procRulePlanar")
STAT_FIELDS = ("eligible_pool", "accepted", "protected", "protected_conflicts",
               "rejected_layer", "rejected_set", "rejected_self", "removed_cleanup",
               "not_consumed", "candidate_attempts", "target_shortfall", "neighbor_visits")


def _container_refs(owner, field):
    # An incomplete inspection fixture reports unavailable fields explicitly;
    # never synthesize membership or evaluate Max from this passive reader.
    try:
        nodes = list(getattr(owner, field))
    except (AttributeError, RuntimeError):
        return None
    result = []
    from .contracts import require
    require(len(nodes)<=32,"Container references exceed the read budget","BUDGET_EXCEEDED")
    for node in nodes:
        try:
            row={"handle": int(node.handle), "name": str(node.name)}
            try:
                row['cached_helper']={
                    'container_id':str(node.containerID),'context_root_id':str(node.contextRootID),
                    'context_set_id':str(node.contextSetID),'label':str(node.cachedLabel)[:1024],
                    'active':int(node.cachedActiveCount),'saved':int(node.cachedSavedCount),
                    'movement_status':str(node.movementStatus)[:1024],
                    'freshness':'Cached presentation from the last event reconciliation; no transform or containment query.'}
            except (AttributeError,RuntimeError,TypeError,ValueError):pass
            result.append(row)
        except (AttributeError, RuntimeError, TypeError, ValueError):
            result.append(None)  # Persisted deleted-node slot.
    return result


def _container_pool(leaf):
    try:
        mode = int(leaf.containerMode)
    except (AttributeError, RuntimeError):
        return None
    return {"mode": {1: "manual", 2: "layer_default", 3: "global", 4: "own"}.get(mode, "unknown"),
            "own_rectangles": _container_refs(leaf, "containerNodes"),
            "cached_membership": _cached_membership(leaf,mode),
            "membership": "Source pivot in rectangle local XY; parked registrations retain settings. Membership is not recomputed by inspection."}


def _cached_membership(leaf,mode):
    """Copy existing membership only. Pending registration changes are not
    reconciled, nor are stale index flags assigned to a different source node.
    """
    try:
        sources=list(leaf.sources);tracked=list(leaf.containerTrackedSources)
        active=list(leaf.containerActive);slots=list(leaf.procSourceSlots)
        points=list(leaf.sourcePoint);empty=list(leaf.sourceEmpty)
        revision=int(leaf.containerMembershipBuilds)
        pending=bool(leaf.containerScan) or len(leaf.containerPending)>0 or bool(leaf.dirty)
    except (AttributeError,RuntimeError,TypeError,ValueError):
        return None
    from .contracts import require
    require(len(sources)<=1024,"Source membership exceeds the read budget","BUDGET_EXCEEDED")
    def handle(node):
        try:return int(node.handle)
        except (AttributeError,RuntimeError,TypeError,ValueError):return None
    handles=[handle(n) for n in sources]
    aligned=len(tracked)==len(sources)==len(active) and handles==[handle(n) for n in tracked]
    rows=[]
    for i,node_handle in enumerate(handles):
        point=i<len(points) and bool(points[i]);placeholder=point or (i<len(empty) and bool(empty[i]))
        if node_handle is None:status="placeholder" if placeholder else "missing"
        elif mode==1:status="manual"
        elif aligned:status="active" if active[i] else "parked"
        else:status="unavailable_until_reconciliation"
        rows.append({"registered_row":i,"node_handle":node_handle,
                     "source_entry_id":str(slots[i]) if aligned and i<len(slots) else None,
                     "kind":"point" if point else "empty" if placeholder else "model","cached_status":status})
    return {"revision":revision,"aligned_with_registered_order":aligned,"pending_by_cached_flags":pending,"rows":rows,
            "freshness":"Last reconciliation flags; node transforms and rectangle containment are not inspected. No current membership claim."}


def require_unified_mutation(controller):
    from .contracts import require
    require(controller is None or str(getattr(controller,"calculationModel",lambda:"")())=="CyrusUnified1",
            "Only a matching unified controller may be refined. Retired scene schemas are unsupported.",
            "UNSUPPORTED_CAPABILITY")


def read_procedural(controller, metres_per_unit):
    if str(getattr(controller,"calculationModel",lambda:"")()) != "CyrusUnified1":
        return None
    parents = list(controller.logicalLayers())
    layers = []
    for parent in parents:
        sets = []
        for leaf in controller.layerSets(parent):
            stats = leaf.procStatistics()
            last = None
            if len(stats[0]) == len(STAT_FIELDS):
                last = dict(zip(STAT_FIELDS, map(int, stats[0])))
                last.update(rounds=int(stats[1][0]), round_limit_reached=bool(stats[1][1]),
                            epoch=int(stats[4]))
            self_rule = leaf.procSelfRule()
            overrides = []
            for i, key in enumerate(leaf.procRadiusIDs):
                world = int(leaf.procRadiusModes[i]) == 1
                overrides.append({"instance_id": str(key), "mode": "world_radius" if world else "multiplier",
                                  "value": float(leaf.procRadiusValues[i]) * (metres_per_unit if world else 1),
                                  "units": "metres" if world else "unitless"})
            sets.append({"set_id": str(leaf.layerID), "name": str(leaf.paintSetName),
                         "sampling_salt": int(leaf.procSamplingSalt),
                         "self_rule": {"inherited": not bool(leaf.procSelfOverride), "enabled": bool(self_rule[0]),
                                       "radius_factor": float(self_rule[1]), "gap_m": float(self_rule[2]) * metres_per_unit,
                                       "metric": "xy" if self_rule[3] else "xyz"},
                         "background": {"mode": int(leaf.procBackground), "earlier_set_ids": list(map(str, leaf.procBackgroundIDs)),
                                        "domain": "earlier siblings on the shared receiver and layer Area domain"},
                         "source_entry_ids": list(map(str, leaf.procSourceSlots)), "radius_overrides": overrides,
                         "source_pool": _container_pool(leaf),
                         "last_published": last, "prepared_builds": int(stats[2]), "prepared_hits": int(stats[3])})
        layers.append({"layer_id": str(parent.layerID), "population": "accepted_target" if int(parent.procPopulation) == 2 else "candidate_budget",
                       "attempt_factor": int(parent.procAttemptFactor), "round_limit": int(parent.procRounds),
                       "retry_cleanup_gaps": bool(parent.procRepair),
                       "default_within_sets": {"enabled": bool(parent.procLayerSelfEnabled), "radius_factor": float(parent.procLayerSelfMultiplier), "gap_m": float(parent.procLayerSelfGap)*metres_per_unit, "metric": "xy" if parent.procLayerSelfPlanar else "xyz"},
                       "default_between_sets": {"enabled": bool(parent.procSiblingEnabled),
                                                "radius_factor": float(parent.procSiblingMultiplier),
                                                "gap_m": float(parent.procSiblingGap) * metres_per_unit,
                                                "metric": "xy" if parent.procSiblingPlanar else "xyz"}, "sets_in_order": sets})
    pairs = [{"scope": "paint_sets" if int(controller.procRuleScope[i]) == 1 else "layers",
              "a": str(controller.procRuleA[i]), "b": str(controller.procRuleB[i]),
              "enabled": bool(controller.procRuleEnabled[i]), "radius_factor": float(controller.procRuleMultiplier[i]),
              "gap_m": float(controller.procRuleGap[i]) * metres_per_unit,
              "metric": "xy" if controller.procRulePlanar[i] else "xyz"} for i in range(len(controller.procRuleA))]
    return {"schema": "cyrus.procedural-configuration/1.0", "calculation_model": "CyrusUnified1",
            "global_source_containers": _container_refs(controller, "containerGlobalNodes"),
            "layers_in_order": layers, "pair_rules": pairs, "mutation_supported": False,
            "freshness": "Recipe values are current; last_published describes the last completed epoch. No solve is performed."}
