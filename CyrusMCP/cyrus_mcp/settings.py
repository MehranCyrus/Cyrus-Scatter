"""Closed, unit-labelled settings for unified plan 0.73; no arbitrary Max properties.

This registry is shared by host validation, tool schemas and capability docs.
Length values cross the adapter boundary exactly once (metres -> Max units).
"""
from copy import deepcopy
from .contracts import fields, number, pair, require


LAYER_SETTINGS = {
    "visible": ("bool", True, (), None),
    "enabled": ("bool", True, (), None),
    "self_spacing_enabled": ("bool", False, (), "procLayerSelfEnabled"),
    "self_radius_factor": ("number", 1, (0, 100), "procLayerSelfMultiplier"),
    "self_gap_m": ("number", 0, (0, 100), "procLayerSelfGap"),
    "self_planar": ("bool", False, (), "procLayerSelfPlanar"),
    "cleanup_enabled": ("bool", False, (), "finalCleanup"),
    "neighbor_radius_m": ("number", 1, (.000001, 1000), "finalNeighborRadius"),
    "minimum_neighbors": ("int", 2, (0, 10000), "finalMinNeighbors"),
    "minimum_island": ("int", 5, (0, 100000), "finalMinIsland"),
    "planar_cleanup": ("bool", True, (), "cleanupPlanar"),
    "align_normal": ("bool", True, (), "alignNormal"),
    "scale_x": ("range", [1, 1], (.01, 10), ("sclXMin", "sclXMax")),
    "scale_y": ("range", [1, 1], (.01, 10), ("sclYMin", "sclYMax")),
    "scale_z": ("range", [1, 1], (.01, 10), ("sclZMin", "sclZMax")),
    "rotation_x_degrees": ("range", [0, 0], (-360, 360), ("rotXMin", "rotXMax")),
    "rotation_y_degrees": ("range", [0, 0], (-360, 360), ("rotYMin", "rotYMax")),
    "movement_x_m": ("range", [0, 0], (-100, 100), ("movXMin", "movXMax")),
    "movement_y_m": ("range", [0, 0], (-100, 100), ("movYMin", "movYMax")),
}
SOURCE_SETTINGS = {
    "scale": ("number", 1, (.01, 10), "sourceScales"),
    "z_offset_m": ("number", 0, (-100, 100), "sourceZOffsets"),
    "radius_m": ("number", 0, (0, 100), "sourceRadii"),
    "radius_follows_scale": ("bool", True, (), "sourceFollowScale"),
    "show_radius": ("bool", False, (), "sourceShowRadius"),
    "forward_axis": ("int", 1, (1, 4), "sourceForwardAxes"),
}
DISPLAY_SETTINGS = {
    "mode": ("enum", "proxy", ("point_cloud", "proxy", "mesh", "centres"), None),
    "proxy_shape": ("enum", "box", ("box", "sphere", "pyramid"), None),
    "instances_per_population": ("int", 2000, (1, 100000), "viewportInstances"),
    "faces_per_population": ("int", 2000000, (12, 20000000), "viewportFaces"),
    "point_budget": ("int", 20000, (1000, 500000), "previewBudget"),
    "points_per_plant": ("int", 80, (10, 10000), "pointsPerPlant"),
    "show_preview": ("bool", True, (), "showPoints"),
    "update_mode": ("enum", "manual", ("manual", "real_time"), None),
}


def normalize_settings(value, registry):
    fields(value, (), registry)
    result={name:deepcopy(spec[1]) for name,spec in registry.items()}
    for name,item in value.items():
        kind,_,bounds,_=registry[name]
        if kind=="bool":require(type(item) is bool, name+" must be boolean")
        elif kind=="enum":require(type(item) is str and item in bounds, "Unsupported "+name)
        elif kind=="range":pair(item,*bounds)
        else:number(item,*bounds,integer=kind=="int")
        result[name]=deepcopy(item)
    return result


def normalize_plan(plan):
    result=deepcopy(plan)
    result["display"]=normalize_settings(plan.get("display",{}),DISPLAY_SETTINGS)
    result["pair_rules"]=deepcopy(plan.get("pair_rules",[]))
    for rule in result["pair_rules"]:
        rule.setdefault("enabled",True)
    for layer in result["layers"]:
        layer["settings"]=normalize_settings(layer.get("settings",{}),LAYER_SETTINGS)
        layer["exclude_region_ids"]=layer.get("exclude_region_ids",[])
        for source in layer["sources"]:
            source["settings"]=normalize_settings(source.get("settings",{}),SOURCE_SETTINGS)
    return result


def capability_manifest():
    def registry(entries):
        return {key:{"type":value[0],"default":value[1],"bounds_or_choices":value[2],
                     "units":"metres" if key.endswith("_m") else "degrees" if key.endswith("_degrees") else "unitless"}
                for key,value in entries.items()}
    return {"schema_version":"1.0","plan_versions":["0.73"],"calculation_model":"CyrusUnified1",
            "layer_settings":registry(LAYER_SETTINGS),"source_settings":registry(SOURCE_SETTINGS),"display_settings":registry(DISPLAY_SETTINGS),
            "supported":["count","seed","source_weights","uniform_scale_yaw","xyz_scale_xy_tilt","projected_xy_movement",
                         "enrolled_convex_include_exclude","ordered_layer_pair_spacing","set_self_spacing","cleanup","visibility","enable","cached_configuration","published_layout_export","unified_recipe_read_only"],
            "source_candidate_pending_host_qualification":["shared_diagnostic_event_pages","procedural_publication_pages","local_diagnostic_recording_export"],
            "help_resources":["cyrus://feature-catalog","cyrus://agent-workflows","cyrus://error-guide"],
            "unavailable":{"brush_history_mutation":"Native local UI only; MCP has no enrolled paint-document mutation contract.",
                           "full_procedural_recipe_mutation":"Plan 0.73 authors/refines only its own bounded independent layers. Full paint-set/background/Edit/container recipes remain local; inspection cannot mutate artist controllers.",
                           "brush_set_creation":"Native local UI only; automated plans currently create independent logical layers.",
                           "relax":"Candidate Relax is available locally; no remote Relax authoring contract is qualified.",
                           "density_texture_and_falloff":"Local maps/curves require a separately enrolled, bounded reference contract.",
                           "spline_diversity_analyzer":"Existing native controls remain local; automation scope is convex horizontal sites.",
                           "bake_render_cs_edit":"Local actions; no remote mutation of renderer, scene modifiers or baked nodes.",
                           "training_or_ml_inference":"Versioned records only; no training, inference, provider uploads or training consent implied."}}
