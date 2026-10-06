"""Single-threaded application service; host access occurs only through its adapter."""
from collections import OrderedDict
from copy import deepcopy
from pathlib import Path
import json
import os
import time
import uuid

from .contracts import Fault, canonical, decode, digest, fields, identifier, number, require, validate_shape
from .geometry import contains, convex, inset, overlaps, outset
from .settings import normalize_v2, capability_manifest
from . import __version__


def uid(prefix):
    return prefix + "_" + uuid.uuid4().hex


class Journal:
    """Atomic bounded operational records. No prompts, assets, credentials or telemetry."""
    def __init__(self, path):
        self.path = Path(path)
        self.records = OrderedDict()
        if self.path.exists():
            try:
                data = decode(self.path.read_bytes(), 2_000_000)
                require(type(data) is list and len(data) <= 128, "Invalid journal")
                for item in data:
                    require(type(item) is dict and "operation_id" in item, "Invalid journal record")
                    if item["state"] in ("queued", "running"):
                        item["state"] = "outcome_unknown"
                        item["error"] = {"code": "OUTCOME_UNKNOWN", "message": "Host restarted before its outcome was recorded. Inspect the scene; do not replay."}
                    self.records[item["operation_id"]] = item
            except Exception as exc:
                raise Fault("OUTCOME_UNKNOWN", "Operation journal is damaged. Local inspection and recovery are required.") from exc

    def save(self):
        while len(self.records) > 128:
            self.records.popitem(last=False)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        temp = self.path.with_suffix(".tmp")
        with temp.open("w", encoding="utf-8") as stream:
            stream.write(canonical(list(self.records.values())))
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp, self.path)


class Service:
    def __init__(self, host, journal):
        self.host, self.journal = host, journal
        self.epoch = uid("scene")
        self.revision = 0
        self.scope = None
        self.contexts = OrderedDict()
        self.validations = OrderedDict()
        self.pending = None
        self.approved = set()
        self.owned = {}
        self.observed = {}
        self.records = {}
        self.last_fingerprint = None
        self.last_undo = None
        self.calls = self.captures = self.applications = 0
        self.diagnostic_session = None  # Explicit, local grant for one process-wide trace.
        self.publications = {}
        self.publication_pages = 0
        self.last_message = "Enroll a site, sources and regions to begin."

    def reset(self):
        self.cancel()
        self.epoch = uid("scene")
        self.revision += 1
        self.scope = None
        self.contexts.clear()
        self.validations.clear()
        self.approved.clear()
        self.owned.clear()
        self.observed.clear()
        self.records.clear()
        self.last_undo = self.last_fingerprint = None
        self.diagnostic_session = None
        self.publications.clear()
        self.publication_pages = 0

    def enroll(self, site, sources, regions, excluded=(), capture=False):
        require(self.pending is None, "Finish or cancel the pending operation", "HOST_BUSY")
        snapshot = self.host.enroll(site, sources, regions, excluded)
        self.reset()
        self.scope = {"scope_id": uid("scope"), "kind":"design", **snapshot, "allow_capture": capture}
        self.calls = self.captures = self.applications = 0
        self.last_fingerprint = self.host.fingerprint()
        self.last_message = "Connected. Proposals require local approval before generation."
        return self.scope

    def observe(self, controller, capture=False):
        require(self.pending is None, "Finish or cancel the pending operation", "HOST_BUSY")
        snapshot=self.host.observe(controller)
        self.reset()
        self.scope={"scope_id":uid("scope"),"kind":"inspection","allow_capture":capture}
        self.observed={snapshot["controller_id"]:snapshot}
        self.calls=self.captures=self.applications=0
        self.last_fingerprint=self.host.fingerprint()
        self.last_message="Read-only inspection connected. Existing layout cannot be modified by this scope."
        return self.scope

    def fresh(self):
        require(self.scope is not None, "Enroll a scope in the Cyrus Automation panel", "APPROVAL_REQUIRED")
        current = self.host.fingerprint()
        if current != self.last_fingerprint:
            self.revision += 1
            self.last_fingerprint = current
            self.approved.clear()
            self.last_undo = None
            # Scene geometry cards cannot be reused after an external edit.
            self.scope["stale"] = True
        require(not self.scope.get("stale"), "Approved scene inputs changed. Re-enroll locally before continuing.", "STALE_CONTEXT")

    def check_epoch(self, epoch):
        require(epoch == self.epoch, "The scene session changed", "STALE_CONTEXT")

    def dispatch(self, method, args):
        require(type(args) is dict, "Tool arguments must be an object")
        methods = {
            "scene.get_context": self.context,
            "scatter.validate_plan": self.validate,
            "scatter.apply_plan": self.apply,
            "scatter.get_status": self.status,
            "scatter.get_diagnostics": self.diagnostics,
            "scatter.read_diagnostic_events": self.diagnostic_events,
            "scatter.get_publication": self.publication,
            "scatter.read_publication_page": self.publication_page,
            "scatter.get_configuration": self.configuration,
            "scatter.export_record": self.export_record,
            "scene.capture_viewport": self.capture,
            "connection.get_status": self.connection,
        }
        require(method in methods, "Unsupported operation", "UNSUPPORTED_CAPABILITY")
        if method not in ("connection.get_status", "scatter.get_status", "scatter.get_diagnostics", "scatter.apply_plan", "scatter.read_publication_page"):
            require(self.calls < 24, "This scope reached its 24-call budget; re-enroll locally", "BUDGET_EXCEEDED")
        if method not in ("connection.get_status", "scatter.read_publication_page"):
            self.calls += 1
        import inspect
        try:
            inspect.signature(methods[method]).bind(**args)
        except TypeError as exc:
            raise Fault("INVALID_PLAN", "Missing or unsupported tool arguments") from exc
        return {"ok": True, **methods[method](**args)}

    def connection(self):
        return {"version": __version__, "scene_epoch": self.epoch, "scene_revision": self.revision,
                "scope_id": self.scope["scope_id"] if self.scope else None,
                "shared_diagnostic_session_id": self.diagnostic_session,
                "message": self.last_message, "host": self.host.version(),
                "support": "Static horizontal convex sites; up to three mesh assets and convex regions; two approved candidates."}

    def context(self, scope_id):
        self.fresh()
        require(scope_id == self.scope["scope_id"], "Unknown scope", "UNKNOWN_REFERENCE")
        cid = uid("context")
        result = {"context_id": cid, "scene_epoch": self.epoch, "scene_revision": self.revision,
                  "units": {"length": "metres", "angles": "degrees", "coordinates": "right-handed Z up"},
                  "scope": deepcopy(self.scope), "owned_controllers": deepcopy(self.owned),
                  "observed_controllers": deepcopy(self.observed),
                  "viewport_id": self.host.viewport_id(),
                  "capabilities": ["count", "seed", "random_source_weights", "uniform_scale_yaw", "convex_footprint_masks", "owned_create", "approved_refine", "viewport_capture"],
                  "settings_contract":capability_manifest(),
                  "budget": {"calls_remaining": max(0,24-self.calls), "candidates_remaining": 2-self.applications, "captures_remaining": 2-self.captures}}
        if self.scope["kind"]=="inspection":
            result["capabilities"]=["cached_inspection","viewport_capture"]
            result["budget"]["candidates_remaining"]=0
        require(len(canonical(result)) <= 65536, "Context exceeds its limit", "BUDGET_EXCEEDED")
        self.contexts[cid] = (self.revision, time.monotonic()+300)
        while len(self.contexts) > 8:
            self.contexts.popitem(last=False)
        return result

    def validate(self, plan):
        total = validate_shape(plan)
        plan=normalize_v2(plan) if plan["schema_version"]=="2.0" else deepcopy(plan)
        self.fresh()
        require(self.scope["kind"]=="design", "This scope permits inspection only. Enroll a design site locally to create a layout.", "UNSUPPORTED_CAPABILITY")
        ctx = self.contexts.get(plan["context_id"])
        require(ctx and ctx[0] == self.revision and ctx[1] >= time.monotonic(), "Context expired or changed", "STALE_CONTEXT")
        require(self.applications < 2, "Two candidate applications are allowed per scope", "BUDGET_EXCEEDED")
        if "controller_id" in plan:
            existing = self.owned.get(plan["controller_id"])
            require(existing and existing["generation_id"] == plan["generation_id"], "Unknown controller or generation", "UNKNOWN_REFERENCE")
        else:
            require(not self.owned, "A scope owns one controller; supply its IDs for refinement", "BUDGET_EXCEEDED")
        sources = {s["source_id"]:s for s in self.scope["sources"]}
        regions = {r["region_id"]:r for r in self.scope["regions"]}
        available_regions={r["region_id"]:r for r in [*self.scope["regions"],*self.scope["excluded"]]}
        compiled = []
        for layer in plan["layers"]:
            require(layer["region_id"] in regions, "Region was not enrolled", "UNKNOWN_REFERENCE")
            require(all(s["source_id"] in sources for s in layer["sources"]), "Source was not enrolled", "UNKNOWN_REFERENCE")
            region = regions[layer["region_id"]]["polygon_m"]
            radius = max(sources[s["source_id"]]["radius_m"] for s in layer["sources"] if s["weight"] > 0) * layer["scale"][1]
            if plan["schema_version"]=="2.0":
                settings=layer["settings"]
                tilt=any(settings[key]!=[0,0] for key in ("rotation_x_degrees","rotation_y_degrees"))
                radius=max(sources[s["source_id"]].get("bounding_radius_m",sources[s["source_id"]]["radius_m"]) * s["settings"]["scale"] if tilt else sources[s["source_id"]]["radius_m"] * s["settings"]["scale"] for s in layer["sources"] if s["weight"]>0)
                radius*=layer["scale"][1]*max(settings[axis][1] for axis in ("scale_x","scale_y","scale_z"))
            clearance = plan.get("clearance_m", 0)
            movement=0.0
            if plan["schema_version"]=="2.0":
                import math
                movement=math.hypot(max(abs(x) for x in layer["settings"]["movement_x_m"]),max(abs(x) for x in layer["settings"]["movement_y_m"]))
            exclusions=[];validation_exclusions=[]
            if plan["schema_version"]=="1.0":
                require(not any(overlaps(region, p["polygon_m"]) for p in self.scope["excluded"]), "Planting region intersects protected space; author separate convex planting regions", "GEOMETRY_CONSTRAINT")
            else:
                ids=set(layer["exclude_region_ids"])|{r["region_id"] for r in self.scope["excluded"]}
                require(ids<=available_regions.keys(),"Exclusion was not enrolled","UNKNOWN_REFERENCE")
                exclusions=[outset(available_regions[key]["polygon_m"],radius+clearance+movement+1e-5) for key in sorted(ids)]
                validation_exclusions=[outset(available_regions[key]["polygon_m"],radius+clearance) for key in sorted(ids)]
            compiled.append({"polygon_m": inset(region, radius+clearance+movement+1e-5), "footprint_m": radius,
                             "original_m": region, "clearance_m": clearance,"exclusions_m":exclusions,"validation_exclusions_m":validation_exclusions})
        vid = uid("validation")
        normalized = deepcopy(plan)
        result = {"validation_id": vid, "digest": digest(normalized), "scene_epoch": self.epoch,
                  "scene_revision": self.revision, "expires_in_seconds": 300,
                  "requested_instances": total, "layers": len(plan["layers"]),
                  "effect": "replace_owned_layers" if "controller_id" in plan else "create_owned_controller",
                  "derived_masks": sum(1+len(m["exclusions_m"]) for m in compiled), "approval": "required_in_local_panel",
                  "warnings": ["Count is sampled over the site before masks; actual output can be lower. Underfill follows each layer's explicit policy."]}
        self.validations[vid] = {**result, "plan": normalized, "compiled": compiled, "deadline": time.monotonic()+300}
        while len(self.validations) > 8:
            removed, _ = self.validations.popitem(last=False)
            self.approved.discard(removed)
        self.last_message = f"Review {plan['name']}: {len(plan['layers'])} layers, {total} requested plants."
        return result

    def approve(self, validation_id):
        self.fresh()
        record = self.validations.get(validation_id)
        require(record and record["scene_revision"] == self.revision and record["deadline"] >= time.monotonic(), "Proposal expired", "STALE_CONTEXT")
        self.approved.add(validation_id)
        self.last_message = "Proposal approved. Waiting for the client to apply it."

    def apply(self, validation_id, digest, scene_epoch, scene_revision, idempotency_key):
        identifier(validation_id)
        identifier(scene_epoch)
        require(type(digest) is str and len(digest) == 64, "Invalid plan digest")
        number(scene_revision,0,2**53,True)
        identifier(idempotency_key)
        signature = canonical([validation_id,digest,scene_epoch,scene_revision])
        for record in self.journal.records.values():
            if record["idempotency_key"] == idempotency_key:
                require(record["signature"] == signature, "Key already belongs to a different request", "IDEMPOTENCY_CONFLICT")
                return {"operation": deepcopy(record)}
        require(self.calls <= 24, "Tool-call budget exhausted; outcome queries and exact retries remain available", "BUDGET_EXCEEDED")
        self.check_epoch(scene_epoch)
        self.fresh()
        require(scene_revision == self.revision, "Scene changed", "STALE_CONTEXT")
        require(self.pending is None, "An operation is already pending", "HOST_BUSY")
        require(self.applications < 2, "Candidate budget exhausted", "BUDGET_EXCEEDED")
        value = self.validations.get(validation_id)
        require(value and value["digest"] == digest and value["scene_revision"] == self.revision and value["deadline"] >= time.monotonic(), "Validation expired or changed", "STALE_CONTEXT")
        require(validation_id in self.approved, "Approve this exact proposal in the local panel", "APPROVAL_REQUIRED")
        oid = uid("operation")
        record = {"operation_id": oid, "scene_epoch": self.epoch, "scene_revision": self.revision,
                  "idempotency_key": idempotency_key, "signature": signature, "state": "queued", "created_unix": time.time()}
        self.journal.records[oid] = record
        self.journal.save()  # Persist admission before any scene mutation.
        self.pending = (oid, deepcopy(value))
        self.approved.discard(validation_id)
        return {"operation": deepcopy(record)}

    def cancel(self):
        if self.pending:
            oid, _ = self.pending
            record = self.journal.records[oid]
            if record["state"] == "queued":
                record["state"] = "cancelled"
                self.pending = None
                self.journal.save()
        self.approved.clear()

    def step(self):
        if self.pending is None:
            return
        oid, value = self.pending
        record = self.journal.records[oid]
        try:
            self.fresh()
            require(value["scene_revision"] == self.revision and value["deadline"] >= time.monotonic(), "Scene or validation changed while queued", "STALE_CONTEXT")
            require(not self.host.busy(), "Host is busy; operation was not applied", "HOST_BUSY")
            record["state"] = "running"
            self.journal.save()
            started = time.perf_counter()
            result = self.host.generate(value["plan"], value["compiled"])
            self.applications += 1
            self.revision += 1
            self.last_fingerprint = self.host.fingerprint()
            self.owned[result["controller_id"]] = deepcopy(result)
            if hasattr(self.host,"layouts") and result["controller_id"] in self.host.layouts:
                from .records import execution_record
                self.records[result["controller_id"]]=execution_record(self.scope,value["plan"],result,self.host.layouts[result["controller_id"]])
            record.update(state="succeeded", result=result, scene_revision=self.revision, duration_ms=(time.perf_counter()-started)*1000)
            self.last_undo = (self.revision, result["undo_label"])
            self.last_message = f"Published {result['emitted']} plants. Undo is available locally."
        except Fault as exc:
            record.update(state="failed", error=exc.result()["error"])
            self.last_message = exc.message
            if exc.code in ("ROLLBACK_FAILED", "OUTCOME_UNKNOWN"):
                self.scope["stale"] = True
        except Exception:
            record.update(state="outcome_unknown", error={"code": "OUTCOME_UNKNOWN", "message": "Unexpected host failure. Inspect the scene locally before retrying."})
            self.scope["stale"] = True
            self.last_message = record["error"]["message"]
        finally:
            self.pending = None
            self.journal.save()

    def status(self, scene_epoch, operation_id=None, controller_id=None):
        require(bool(operation_id) != bool(controller_id), "Supply exactly one operation or controller ID")
        if operation_id:
            record = self.journal.records.get(operation_id)
            require(record and record["scene_epoch"] == scene_epoch, "Unknown operation for this epoch", "UNKNOWN_REFERENCE")
            return {"operation": deepcopy(record)}
        self.check_epoch(scene_epoch)
        if controller_id in self.observed:
            return {"controller":deepcopy(self.observed[controller_id]),"freshness":"last_inspection; cached preview, no regeneration"}
        require(controller_id in self.owned, "Unknown owned controller", "UNKNOWN_REFERENCE")
        return {"controller": deepcopy(self.owned[controller_id]), "freshness": "last_publication"}

    def diagnostics(self, scene_epoch):
        self.check_epoch(scene_epoch)
        return {"scene_revision": self.revision, "counters": self.host.diagnostics(),
                "retained":self.host.retained_diagnostics() if hasattr(self.host,"retained_diagnostics") else None,
                "calls": self.calls, "captures": self.captures, "applications": self.applications,
                "pending_operation": self.pending[0] if self.pending else None,
                "timing_semantics": "cached host counters; no regeneration or FPS measurement"}

    def diagnostic_events(self, scene_epoch, session_id, after_sequence=0, limit=100):
        self.check_epoch(scene_epoch)
        require(self.scope is not None and self.diagnostic_session == session_id,
                "Share this diagnostic session locally before reading its events", "APPROVAL_REQUIRED")
        from .diagnostics import validate_page
        identifier(session_id)
        number(after_sequence, 0, 2**53, True)
        number(limit, 1, 500, True)
        # Do not call fresh(): fingerprint inspection can evaluate geometry in
        # design scopes. Diagnostic reads only copy the already recorded ring.
        page = validate_page(self.host.diagnostic_page(after_sequence, limit), session_id, after_sequence, limit)
        return {"page": page, "scope": "explicitly shared process-wide engineering trace"}

    def publication(self, scene_epoch, controller_id):
        self.check_epoch(scene_epoch)
        require(self.scope is not None and (controller_id in self.owned or controller_id in self.observed),
                "Unknown scoped controller", "UNKNOWN_REFERENCE")
        require(hasattr(self.host,"publication_manifest"),"Publication reader unavailable","UNSUPPORTED_CAPABILITY")
        published=self.host.publication_manifest(controller_id)
        self.publications[controller_id]=(deepcopy(published),time.monotonic()+300)
        return {"manifest":published,"expires_in_seconds":300,"page_limit":500,
                "pages_remaining":max(0,2048-self.publication_pages)}

    def publication_page(self, scene_epoch, controller_id, publication_id, offset=0, limit=100):
        self.check_epoch(scene_epoch)
        require(self.scope is not None and (controller_id in self.owned or controller_id in self.observed),
                "Unknown scoped controller", "UNKNOWN_REFERENCE")
        cached=self.publications.get(controller_id)
        require(cached is not None and cached[1]>time.monotonic() and cached[0]["publication_id"]==publication_id,
                "Read the current publication manifest first; handles expire after five minutes", "STALE_CONTEXT")
        number(offset,0,cached[0]["count"],True);number(limit,1,500,True)
        require(self.publication_pages<2048,"Publication paging budget exhausted; reconnect locally","BUDGET_EXCEEDED")
        self.publication_pages+=1  # Failed and stale attempts consume the budget.
        from .publication import page
        raw=self.host.publication_page(controller_id,publication_id,offset,limit)
        return {"page":page(raw,cached[0],offset,limit),"pages_remaining":2048-self.publication_pages}

    def configuration(self,scene_epoch,controller_id):
        self.check_epoch(scene_epoch);self.fresh()
        require(controller_id in self.owned or controller_id in self.observed,"Unknown scoped controller","UNKNOWN_REFERENCE")
        return {"configuration":self.host.configuration(controller_id)}

    def export_record(self,scene_epoch,controller_id,generation_id):
        self.check_epoch(scene_epoch);self.fresh()
        receipt=self.owned.get(controller_id)
        require(receipt and receipt["generation_id"]==generation_id,"Unknown published generation","UNKNOWN_REFERENCE")
        require(controller_id in self.records,"No recorded final layout for this generation","UNSUPPORTED_CAPABILITY")
        record=deepcopy(self.records[controller_id])
        require(len(canonical(record).encode())<=1500000,"Export exceeds its 1.5 MiB budget","BUDGET_EXCEEDED")
        return {"record":record,"training_eligible":False}

    def capture(self, scene_epoch, scene_revision, viewport_id, generation_id):
        number(scene_revision,0,2**53,True)
        self.check_epoch(scene_epoch)
        self.fresh()
        require(scene_revision == self.revision, "Capture revision changed", "STALE_CONTEXT")
        require(self.scope["allow_capture"], "Enable viewport sharing locally", "APPROVAL_REQUIRED")
        require(self.captures < 2, "Two captures per scope", "BUDGET_EXCEEDED")
        snapshots=[*self.owned.values(),*self.observed.values()]
        require(any(v["generation_id"] == generation_id for v in snapshots), "Unknown generation", "UNKNOWN_REFERENCE")
        require(viewport_id == self.host.viewport_id(), "Designated viewport is no longer active", "STALE_CONTEXT")
        result = self.host.capture()
        self.fresh()  # A deliberate redraw may rebuild an observed dirty preview.
        self.captures += 1
        return {**result, "scene_epoch": self.epoch, "scene_revision": self.revision, "generation_id": generation_id, "viewport_id": viewport_id,
                "freshness":"cached preview; source geometry not regenerated or certified" if self.observed else "validated publication"}

    def undo(self):
        self.fresh()
        require(self.last_undo and self.last_undo[0] == self.revision, "The scene changed; use Max's Undo history to review", "STALE_CONTEXT")
        self.host.undo(self.last_undo[1])
        self.reset()
        self.last_message = "Layout undone. Re-enroll before another proposal."
