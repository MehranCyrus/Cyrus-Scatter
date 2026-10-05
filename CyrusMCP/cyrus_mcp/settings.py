"""Closed, unit-labelled settings for plan 2.0; no arbitrary Max properties.

This registry is shared by host validation, tool schemas and capability docs.
Length values cross the adapter boundary exactly once (metres -> Max units).
"""
from copy import deepcopy
from .contracts import fields, number, pair, require


LAYER_SETTINGS = {
    "visible": ("bool", True, (), None),
    "enabled": ("bool", True, (), None),
    "priority": ("int", 0, (-100000, 100000), "groupPriority"),
    "collision_enabled": ("bool", False, (), "collisionEnabled"),
    "collision_radius_m": ("number", .1, (0, 100), "collisionRadius"),
    "cleanup_enabled": ("bool", False, (), "finalCleanup"),
    "neighbor_radius_m": ("number", 1, (.000001, 1000), "finalNeighborRadius"),
    "minimum_neighbors": ("int", 2, (0, 10000), "finalMinNeighbors"),
    "minimum_island": ("int", 5, (0, 100000), "finalMinIsland"),
    "planar_cleanup": ("bool", True, (), "overlapPlanar"),
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
    "collision_radius_m": ("number", 0, (0, 100), "sourceRadii"),
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


def normalize_v2(plan):
    result=deepcopy(plan)
    result["display"]=normalize_settings(plan.get("display",{}),DISPLAY_SETTINGS)
    result["pair_rules"]=deepcopy(plan.get("pair_rules",[]))
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
    return {"schema_version":"1.0","plan_versions":["1.0","2.0"],
            "layer_settings":registry(LAYER_SETTINGS),"source_settings":registry(SOURCE_SETTINGS),"display_settings":registry(DISPLAY_SETTINGS),
            "supported":["count","seed","source_weights","uniform_scale_yaw","xyz_scale_xy_tilt","projected_xy_movement",
                         "enrolled_convex_include_exclude","shared_pair_spacing","collision","cleanup","visibility","enable","cached_configuration","published_layout_export","procedural_policy_3_read_only"],
            "unavailable":{"brush_history_mutation":"Native local UI only; MCP has no enrolled paint-document mutation contract.",
                           "procedural_policy_3_mutation":"Read-only recipe and cached diagnostics. Plan schemas 1/2 retain policies 1/2; they cannot convert or overwrite a policy-3 controller.",
                           "brush_set_creation":"Native local UI only; automated plans currently create independent logical layers.",
                           "relax":"Not qualified through automation; painted/shared Boundary Relax remains paused in the UI.",
                           "density_texture_and_falloff":"Local maps/curves require a separately enrolled, bounded reference contract.",
                           "spline_diversity_analyzer":"Existing native controls remain local; automation scope is convex horizontal sites.",
                           "bake_render_cs_edit":"Local actions; no remote mutation of renderer, scene modifiers or baked nodes.",
                           "training_or_ml_inference":"Versioned records only; no training, inference, provider uploads or training consent implied."}}
