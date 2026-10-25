"""Closed edits of an already owned bounded setup; no arbitrary property access."""
from copy import deepcopy
from .contracts import fields, identifier, number, require, validate_shape


def prepare_change(change, definition, receipt):
    fields(change, ("change_schema", "context_id", "controller_id", "generation_id", "configuration_id", "mode"), ("layers",))
    require(change["change_schema"] == "cyrus.owned-change/1.0", "Unsupported owned-change schema", "UNSUPPORTED_CAPABILITY")
    for key in ("context_id", "controller_id", "generation_id", "configuration_id"):
        identifier(change[key])
    require(change["mode"] in ("configure", "update", "configure_and_update"), "Unknown change mode")
    require(change["controller_id"] == receipt["controller_id"]
            and change["generation_id"] == receipt["generation_id"]
            and change["configuration_id"] == receipt.get("configuration_id", receipt["generation_id"]),
            "Owned configuration or publication changed", "STALE_CONTEXT")
    patches = change.get("layers", [])
    require(type(patches) is list and len(patches) <= 3, "Change supports at most three layer patches")
    require((not patches) if change["mode"] == "update" else bool(patches),
            "Update has no patches; configure operations require a concrete patch")
    plan = deepcopy(definition["plan"])
    if change["mode"] == "configure":
        require(plan["display"]["update_mode"] == "manual", "Configure-only requires Manual mode", "UNSUPPORTED_CAPABILITY")
    identities = [layer["layer_id"] for layer in receipt["layers"]]
    require(len(identities) == len(plan["layers"]) and len(set(identities)) == len(identities),
            "Owned layer correspondence is unavailable", "STALE_CONTEXT")
    seen, review = set(), []
    for patch in patches:
        fields(patch, ("layer_id",), ("count", "seed"))
        identifier(patch["layer_id"])
        require(patch["layer_id"] in identities and patch["layer_id"] not in seen,
                "Unknown or repeated owned layer", "UNKNOWN_REFERENCE")
        seen.add(patch["layer_id"])
        require(len(patch) > 1, "Layer patch is empty")
        target = plan["layers"][identities.index(patch["layer_id"])]
        for key, maximum in (("count", 2000), ("seed", 2147483646)):
            if key not in patch:
                continue
            number(patch[key], 0, maximum, True)
            require(patch[key] != target[key], "Patch contains an unchanged value")
            review.append({"layer_id": patch["layer_id"], "name": target["name"], "field": key,
                           "before": target[key], "after": patch[key]})
            target[key] = patch[key]
    plan.update(context_id=change["context_id"], controller_id=change["controller_id"], generation_id=change["generation_id"])
    validate_shape(plan)  # Preserve aggregate candidate admission and every untouched contract.
    return plan, review
