"""Strict, provider-neutral contracts shared by Max and the external MCP process."""
import hashlib
import json
import math
import re


class Fault(Exception):
    def __init__(self, code, message, **details):
        super().__init__(message)
        self.code, self.message, self.details = code, message, details

    def result(self):
        return {"ok": False, "error": {"code": self.code, "message": self.message, **self.details}}


def require(condition, message, code="INVALID_PLAN"):
    if not condition:
        raise Fault(code, message)


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True, allow_nan=False)


def digest(value):
    return hashlib.sha256(canonical(value).encode()).hexdigest()


def decode(raw, limit=65536):
    require(len(raw) <= limit, "Request exceeds the byte limit", "BUDGET_EXCEEDED")
    def pairs(items):
        result = {}
        for key, value in items:
            require(key not in result, "Duplicate JSON key")
            result[key] = value
        return result
    try:
        result = json.loads(raw, object_pairs_hook=pairs, parse_constant=lambda _: (_ for _ in ()).throw(ValueError()))
        def walk(value, depth=0):
            require(depth <= 16, "JSON nesting exceeds the limit")
            if isinstance(value, dict):
                for item in value.values():
                    walk(item, depth + 1)
            elif isinstance(value, list):
                require(len(value) <= 2048, "Array exceeds the limit")
                for item in value:
                    walk(item, depth + 1)
            elif isinstance(value, float):
                require(math.isfinite(value), "Non-finite number")
        walk(result)
        return result
    except (ValueError, RecursionError, UnicodeError) as exc:
        raise Fault("INVALID_PLAN", "Malformed JSON") from exc


def fields(value, required, optional=()):
    require(type(value) is dict, "Expected an object")
    require(set(required) <= value.keys(), "Missing fields: " + ", ".join(sorted(set(required) - value.keys())))
    require(value.keys() <= set(required) | set(optional), "Unknown fields: " + ", ".join(sorted(value.keys() - set(required) - set(optional))))


def number(value, low, high, integer=False):
    require(type(value) in ((int,) if integer else (int, float)), "Expected a numeric value")
    require(low <= value <= high and math.isfinite(value), f"Number must be in [{low}, {high}]")
    return value


def label(value):
    require(type(value) is str and 1 <= len(value) <= 80 and not any(ord(c) < 32 for c in value), "Expected a short display label")
    return value


def identifier(value):
    require(type(value) is str and re.fullmatch(r"[A-Za-z0-9_-]{1,96}", value), "Invalid identifier")
    return value


def pair(value, low, high):
    require(type(value) is list and len(value) == 2, "Expected a range of two numbers")
    number(value[0], low, high)
    number(value[1], low, high)
    require(value[0] <= value[1], "Range is reversed")
    return value


def validate_shape(plan):
    try:
        encoded = canonical(plan)
    except (ValueError, TypeError, RecursionError) as exc:
        raise Fault("INVALID_PLAN", "Plan must contain finite JSON data") from exc
    require(len(encoded.encode()) <= 32768, "Plan exceeds 32 KiB", "BUDGET_EXCEEDED")
    require(type(plan) is dict and plan.get("schema_version")=="0.73", "Unsupported plan schema")
    fields(plan, ("schema_version", "context_id", "name", "layers"), ("controller_id", "generation_id", "clearance_m")+("display","pair_rules"))
    identifier(plan["context_id"])
    label(plan["name"])
    require(type(plan["layers"]) is list and 1 <= len(plan["layers"]) <= 3, "Choose one to three layers")
    require(("controller_id" in plan) == ("generation_id" in plan), "Refinement requires both controller and generation IDs")
    for key in ("controller_id", "generation_id"):
        if key in plan:
            identifier(plan[key])
    number(plan.get("clearance_m", 0.0), 0, 100)
    total = 0
    names = set()
    for layer in plan["layers"]:
        fields(layer, ("name", "region_id", "count", "seed", "sources", "scale", "yaw_degrees", "underfill"), ("settings","exclude_region_ids"))
        label(layer["name"])
        require(layer["name"] not in names, "Layer names must be distinct")
        names.add(layer["name"])
        identifier(layer["region_id"])
        total += number(layer["count"], 0, 2000, True)
        number(layer["seed"], 0, 2147483646, True)
        pair(layer["scale"], 0.01, 10)
        pair(layer["yaw_degrees"], -360, 360)
        require(layer["underfill"] in ("allow", "reject"), "Underfill must be allow or reject")
        require(type(layer["sources"]) is list and 1 <= len(layer["sources"]) <= 3, "Choose one to three sources")
        ids, weight = set(), 0
        for source in layer["sources"]:
            fields(source, ("source_id", "weight"), ("settings",))
            identifier(source["source_id"])
            require(source["source_id"] not in ids, "Duplicate source")
            ids.add(source["source_id"])
            weight += number(source["weight"], 0, 1)
        require(weight > 0, "At least one source weight must be positive")
        ids=layer.get("exclude_region_ids",[])
        require(type(ids) is list and len(ids)<=6,"At most six enrolled exclusions")
        for value in ids:identifier(value)
        require(len(set(ids))==len(ids),"Duplicate exclusion")
    from .settings import normalize_plan
    normalize_plan(plan)
    rules=plan.get("pair_rules",[])
    require(type(rules) is list and len(rules)<=3,"At most three layer pair rules")
    pairs=set()
    for rule in rules:
        fields(rule,("a","b","gap_m","radius_factor","planar"),("enabled",))
        number(rule["a"],0,len(plan["layers"])-1,True);number(rule["b"],0,len(plan["layers"])-1,True)
        require(rule["a"]!=rule["b"],"Pair must refer to different layers")
        key=tuple(sorted((rule["a"],rule["b"])))
        require(key not in pairs,"Duplicate pair rule");pairs.add(key)
        number(rule["gap_m"],0,100)
        number(rule["radius_factor"],0,100)
        require(type(rule.get("enabled",True)) is bool and type(rule["planar"]) is bool,"Pair flags must be boolean")
    require(total <= 2000, "At most 2,000 requested instances", "BUDGET_EXCEEDED")
    return total
