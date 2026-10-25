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
from .settings import normalize_plan, capability_manifest
from .library import summary as catalog_summary
from .recipes import summary as recipe_summary
from .presets import summary as preset_summary
from . import __version__


def uid(prefix):
    return prefix + "_" + uuid.uuid4().hex


def needs_recovery(record):
    if record.get("recovery_required", False):
        return True
    if record.get("resolution", {}).get("status") == "locally_retired":
        return False
    return (record["state"] == "outcome_unknown"
            or (record["state"] == "failed" and record.get("effects") == "committed")
            or (record.get("effects") == "unknown" and record["state"] not in ("queued", "running")))


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
                    identifier(item["operation_id"])
                    require(item["operation_id"] not in self.records, "Duplicate operation identity in journal")
                    require(item.get("state") in ("queued","running","succeeded","failed","cancelled","outcome_unknown"), "Invalid journal state")
                    item.setdefault("effects", "committed" if item["state"] == "succeeded" else
                                    "none" if item["state"] in ("queued", "cancelled") else
                                    "verified_rollback" if item.get("error", {}).get("rollback") == "verified" else "unknown")
                    require(item["effects"] in ("none","committed","verified_rollback","unknown"), "Invalid journal effects")
                    require("recovery_required" not in item or type(item["recovery_required"]) is bool, "Invalid recovery flag")
                    if "resolution" in item:
                        require(type(item["resolution"]) is dict and item["resolution"].get("status") in ("locally_retired","storage_failed"), "Invalid recovery resolution")
                    if item["state"] in ("queued", "running"):
                        item["state"] = "outcome_unknown"
                        # A persisted commit witness survives a later crash.
                        if item["effects"] != "committed":
                            item["effects"] = "unknown"
                        item["error"] = {"code": "OUTCOME_UNKNOWN", "message": "Host restarted before its outcome was recorded. Inspect the scene; do not replay."}
                    item["recovery_required"] = needs_recovery(item)
                    self.records[item["operation_id"]] = item
            except Exception as exc:
                raise Fault("OUTCOME_UNKNOWN", "Operation journal is damaged. Local inspection and recovery are required.") from exc

    def save(self):
        while len(self.records) > 128:
            removable = next((key for key, record in self.records.items()
                              if record["state"] not in ("queued", "running") and not needs_recovery(record)), None)
            require(removable is not None, "Journal is full of unresolved operations; inspect locally", "JOURNAL_FAILED")
            del self.records[removable]
        self.path.parent.mkdir(parents=True, exist_ok=True)
        encoded = canonical(list(self.records.values()))
        require(len(encoded.encode("utf-8")) <= 2_000_000, "Operation journal exceeds its reload byte budget", "JOURNAL_FAILED")
        temp = self.path.with_suffix(".tmp")
        with temp.open("w", encoding="utf-8") as stream:
            stream.write(encoded)
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
        self.recovery_reviews = OrderedDict()
        self.recovery_required = any(needs_recovery(record) for record in journal.records.values())
        self.approved = set()
        self.owned = {}
        self.observed = {}
        self.records = {}
        self.authored = {}
        self.configurations = 0
        self.last_fingerprint = None
        self.last_undo = None
        self.task = None
        self.task_design_review=None
        self.library_grant=None
        self.installed_source_grant=None
        self.source_preparations=OrderedDict()
        self.recipe_grant=None
        self.recipe_deadline=None
        self.preset_grant=None
        self.preset_deadline=None
        self.asset_grant=None
        self.calls = self.captures = self.applications = 0
        self.diagnostic_session = None  # Explicit, local grant for one process-wide trace.
        self.publications = {}
        self.publication_pages = 0
        self.last_message = ("A previous operation needs local review. Query its original receipt; do not replay or enroll another task."
                             if self.recovery_required else "Enroll a site, sources and regions to begin.")

    def require_reconciled(self):
        require(not self.recovery_required, "An operation needs local reconciliation. Query its original operation; do not start another mutation.", "OUTCOME_UNKNOWN")

    def unresolved_operations(self):
        return [{key: record.get(key) for key in ("operation_id", "scene_epoch", "state", "effects", "persistence")}
                for record in self.journal.records.values() if needs_recovery(record)]

    def prepare_local_recovery(self, operation_id, selected):
        """Local UI only. Reviewing evidence never mutates the scene or grants authority."""
        require(self.pending is None, "Finish or cancel queued work before recovery", "HOST_BUSY")
        require(type(selected) is list and len(selected) <= 1, "Select at most one controller for recovery review")
        record = self.journal.records.get(operation_id)
        require(record is not None and needs_recovery(record), "No unresolved operation with this ID", "UNKNOWN_REFERENCE")
        require(hasattr(self.host, "recovery_snapshot"), "This host cannot inspect recovery evidence", "UNSUPPORTED_CAPABILITY")
        evidence = self.host.recovery_snapshot(record, selected)
        require(type(evidence) is dict and len(canonical(evidence).encode()) <= 8192,
                "Recovery evidence exceeds its bounded metadata contract", "BUDGET_EXCEEDED")
        # Store native references only in the short-lived local review, never in the journal.
        review_id = uid("recovery")
        review = {"review_id": review_id, "operation_id": operation_id, "scene_epoch": self.epoch,
                  "record_sha256": digest(record), "evidence": evidence,
                  "effects": record["effects"], "state": record["state"],
                  "action": "retire_without_replay", "unknown_effects_remain_unknown": record["effects"] == "unknown"}
        review["digest"] = digest(review)
        self.recovery_reviews[review_id] = {"review": deepcopy(review), "selected": list(selected), "deadline": time.monotonic()+300}
        while len(self.recovery_reviews) > 8:
            self.recovery_reviews.popitem(last=False)
        return review

    def confirm_local_recovery(self, review_id, review_digest):
        """Requires the local artist's concrete review; deliberately absent from dispatch."""
        require(self.pending is None, "Finish or cancel queued work before recovery", "HOST_BUSY")
        pending = self.recovery_reviews.pop(review_id, None)
        require(pending and pending["deadline"] >= time.monotonic(), "Recovery review expired", "STALE_CONTEXT")
        review = pending["review"]
        require(review["digest"] == review_digest and review["scene_epoch"] == self.epoch,
                "Recovery review changed or scene reset", "STALE_CONTEXT")
        record = self.journal.records.get(review["operation_id"])
        require(record is not None and needs_recovery(record) and digest(record) == review["record_sha256"],
                "Operation changed since recovery review", "STALE_CONTEXT")
        evidence = self.host.recovery_snapshot(record, pending["selected"])
        require(digest(evidence) == digest(review["evidence"]), "Scene evidence changed since recovery review", "STALE_CONTEXT")
        record["resolution"] = {"status": "locally_retired", "action": "retire_without_replay", "actor": "local_artist",
                                "scene_epoch": self.epoch, "reviewed_unix": time.time(), "evidence": deepcopy(evidence),
                                "review_digest": review_digest, "original_state": record["state"], "original_effects": record["effects"]}
        record["recovery_required"] = False
        if not self.save_operation(record):
            record["resolution"]["status"] = "storage_failed"
            raise Fault("JOURNAL_FAILED", record["error"]["message"], operation_id=record["operation_id"])
        # Scope/approvals are discarded, never restored from a retired operation.
        self.recovery_required = any(needs_recovery(item) for item in self.journal.records.values())
        self.reset()
        self.last_message = "Operation retired locally without replay. Existing scene state was kept. Fresh enrollment and approval are required."
        return {"operation_id": record["operation_id"], "resolution": deepcopy(record["resolution"]),
                "recovery_required": self.recovery_required}

    def invalidate_after_failure(self):
        self.recovery_required = True
        self.approved.clear()
        self.last_undo = None
        if self.scope is not None:
            self.scope["stale"] = True

    def save_operation(self, record):
        """Keep outcome queries alive even when durable storage becomes unavailable."""
        record["persistence"] = "confirmed"
        try:
            self.journal.save()
            return True
        except Exception:
            record.update(state="failed", persistence="unconfirmed", recovery_required=True,
                          error={"code": "JOURNAL_FAILED", "message": "Operation storage failed. Inspect this operation and the scene locally before continuing."})
            self.invalidate_after_failure()
            self.last_message = record["error"]["message"]
            return False

    def record_commit(self, record, result, definition=None):
        # Record the effect before inspecting/copying the host receipt: even a
        # malformed receipt cannot turn a known commit into unknown/no effects.
        record.update(effects="committed", phase="host_committed")
        if record.get("operation_kind")=="import_sources":
            self.revision+=1;record["scene_revision"]=self.revision
            if isinstance(result,dict):record["commit_identity"]={"asset_use_id":result.get("asset_use_id"),"package_revision":result.get("package_revision")}
            canonical(result);record["result"]=deepcopy(result)
            self.asset_grant["uses"]+=1
            for item in result["sources"]:self.task["roles"][item["object_id"]]=["source"]
            self.task["task_revision"]+=1
            self.approved.clear();self.contexts.clear();self.task_design_review=None
            return
        configuring = record.get("operation_kind") == "configure"
        if configuring:
            self.configurations += 1
        else:
            self.applications += 1
        self.revision += 1
        record["scene_revision"] = self.revision
        if isinstance(result, dict):
            record["commit_identity"] = {key: result[key] for key in ("controller_id", "generation_id", "configuration_id")
                                         if isinstance(result.get(key), str)}
        canonical(result)  # Keep non-JSON/non-finite values out of outcome queries and the journal.
        record["result"] = deepcopy(result)
        self.owned[result["controller_id"]] = deepcopy(result)
        if definition is not None:
            self.authored[result["controller_id"]] = deepcopy(definition)
        # Never associate a prior export with a newly committed generation.
        if not configuring:
            self.records.pop(result["controller_id"], None)

    def reset(self, *, keep_scene_selection=False, keep_recipe_grant=False,keep_preset_grant=False):
        self.cancel()
        self.revoke_source_package()
        if not keep_recipe_grant:self.revoke_recipe_catalog()
        if not keep_preset_grant:self.revoke_preset_catalog()
        self.epoch = uid("scene")
        self.revision += 1
        self.scope = None
        self.contexts.clear()
        self.validations.clear()
        self.approved.clear()
        self.owned.clear()
        self.observed.clear()
        self.records.clear()
        self.authored.clear()
        self.task=None
        self.task_design_review=None
        self.library_grant=None
        self.installed_source_grant=None
        self.source_preparations.clear()
        self.configurations = 0
        self.last_undo = self.last_fingerprint = None
        self.diagnostic_session = None
        self.publications.clear()
        self.publication_pages = 0
        self.recovery_reviews.clear()
        if hasattr(self.host,"clear_undo_witness"):
            self.host.clear_undo_witness()
        if not keep_scene_selection and hasattr(self.host,"clear_scene_selection"):
            self.host.clear_scene_selection()

    def enroll(self, site, sources, regions, excluded=(), capture=False):
        self.require_reconciled()
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
        if self.scope["kind"]=="scene_inspection":
            snapshot=self.host.scene_snapshot()
            current=digest(snapshot)
            if current!=self.last_fingerprint:
                self.revision+=1
                self.approved.clear();self.contexts.clear();self.last_undo=None
                self.last_fingerprint=current
            self.scope["snapshot"]=snapshot
            return
        current = self.host.fingerprint()
        if current != self.last_fingerprint:
            self.revision += 1
            self.last_fingerprint = current
            self.approved.clear()
            self.last_undo = None
            # Scene geometry cards cannot be reused after an external edit.
            self.scope["stale"] = True
        require(not self.scope.get("stale"), "Approved scene inputs changed. Re-enroll locally before continuing.", "STALE_CONTEXT")

    def inspect_scene(self, selected, intent=""):
        from .scene import brief
        self.require_reconciled()
        require(self.pending is None, "Finish or cancel queued work before connecting", "HOST_BUSY")
        intent=brief(intent)
        snapshot=self.host.inspect_scene(selected)
        self.reset(keep_scene_selection=True)
        self.scope={"scope_id":uid("scope"),"kind":"scene_inspection","allow_capture":False,"snapshot":snapshot}
        self.task={"task_id":uid("task"),"task_revision":0,"brief":intent,"roles":{},
                   "stage":"inspection",
                   "role_evidence":"artist_assigned","authority":"read_only; roles never grant editing permission",
                   "persistence":"transient; disconnect, scene reset/open or another enrollment clears this task"}
        self.calls=self.captures=self.applications=0
        self.last_fingerprint=digest(snapshot)
        self.last_message="Read-only scene task connected. Assign roles or describe the result; no design setup is required to inspect."
        return self.scope

    def extend_scene(self, selected):
        self.require_reconciled()
        require(self.scope and self.scope["kind"]=="scene_inspection" and self.pending is None,
                "Extend an idle read-only scene task locally", "APPROVAL_REQUIRED")
        before=self.scope["snapshot"]
        snapshot=self.host.extend_scene(selected)
        if snapshot!=before:
            self.scope["snapshot"]=snapshot;self.last_fingerprint=digest(snapshot)
            self.task["task_revision"]+=1;self.revision+=1
            self.contexts.clear();self.approved.clear();self.task_design_review=None
        self.last_message="Selected context added without replacing the task or granting authoring permission."

    def prepare_task_design(self):
        """Local scope grant review, deliberately absent from public dispatch."""
        self.require_reconciled()
        require(self.scope and self.scope["kind"]=="scene_inspection" and self.pending is None,
                "Connect an idle read-only scene task first", "APPROVAL_REQUIRED")
        self.fresh()
        cards={card["object_id"]:card for card in self.scope["snapshot"]["objects"]}
        bindings={role:[oid for oid,roles in self.task["roles"].items() if role in roles]
                  for role in ("receiver","source","boundary","exclusion")}
        require(len(bindings["receiver"])==1 and 1<=len(bindings["source"])<=3,
                "Assign one receiver and 1–3 source prototypes before enabling design proposals", "UNSUPPORTED_CAPABILITY")
        require(len(bindings["boundary"])<=3 and len(bindings["exclusion"])<=3,
                "Design enrollment supports at most three boundaries/exclusions", "BUDGET_EXCEEDED")
        ids=[oid for group in bindings.values() for oid in group]
        require(len(ids)==len(set(ids)),"Receiver, sources, boundaries and exclusions must be distinct; preserve/context may overlap", "UNSUPPORTED_CAPABILITY")
        require(all(oid in cards and cards[oid]["status"]=="available" for oid in ids),
                "A bound design input is missing; correct its role locally", "STALE_CONTEXT")
        review={"review_id":uid("grant"),"scene_epoch":self.epoch,"scope_id":self.scope["scope_id"],
                "task_sha256":digest(self.task),"metadata_sha256":digest(self.scope["snapshot"]),"bindings":bindings,
                "inputs":{role:[{"object_id":oid,"label":cards[oid].get("label",""),"object_type":cards[oid].get("object_type","")}
                                for oid in group] for role,group in bindings.items()},
                "region_policy":"explicit_boundaries" if bindings["boundary"] else "whole_verified_horizontal_convex_receiver",
                "effects":"Bounded input inspection and a new design grant only; no scene nodes created. Every later write requires exact local approval.",
                "capture_allowed":False,"expires_in_seconds":300}
        review["digest"]=digest(review)
        self.task_design_review={"review":deepcopy(review),"deadline":time.monotonic()+300}
        return review

    def connect_task_design(self, review_id, review_digest):
        self.require_reconciled()
        require(self.pending is None,"Finish or cancel queued work first","HOST_BUSY")
        pending=self.task_design_review
        self.task_design_review=None
        require(pending and pending["deadline"]>=time.monotonic(),"Design grant review expired","STALE_CONTEXT")
        review=pending["review"]
        require(review["review_id"]==review_id and review["digest"]==review_digest and review["scene_epoch"]==self.epoch
                and self.scope and self.scope["kind"]=="scene_inspection" and self.scope["scope_id"]==review["scope_id"],
                "Design grant review changed","STALE_CONTEXT")
        self.fresh()
        require(digest(self.task)==review["task_sha256"] and digest(self.scope["snapshot"])==review["metadata_sha256"],
                "Task inputs or roles changed after review","STALE_CONTEXT")
        snapshot=self.host.connect_task_inputs(deepcopy(review["bindings"]))
        fingerprint=snapshot.pop("_fingerprint")
        task=deepcopy(self.task)
        task.update(stage="design",authority="Task roles remain annotations. Only this separate bounded design grant permits exact approved owned writes.")
        task["task_revision"]+=1
        task["persistence"]="Transient task retained across this explicit handoff; disconnect, reset/open or unrelated enrollment clears it."
        metadata=deepcopy(self.scope["snapshot"])
        library_grant=deepcopy(self.library_grant)
        self.reset(keep_scene_selection=True,keep_recipe_grant=True,keep_preset_grant=True)
        self.task=task
        self.library_grant=library_grant
        self.scope={"scope_id":uid("scope"),"kind":"design",**snapshot,"allow_capture":False,"task_snapshot":metadata}
        self.calls=self.captures=self.applications=0
        self.last_fingerprint=fingerprint
        self.last_message="Same task connected for bounded design proposals. Review and approve each exact change locally."
        return self.scope

    def update_scene_brief(self, intent):
        from .scene import brief
        require(self.task is not None and self.scope and self.scope["kind"] in ("scene_inspection","design") and self.pending is None,
                "Connect an idle scene task first", "APPROVAL_REQUIRED")
        intent=brief(intent)
        if self.task["brief"]!=intent:
            self.task["brief"]=intent
            self.task["task_revision"]+=1
            if self.scope["kind"]=="scene_inspection":self.revision+=1
            self.approved.clear();self.contexts.clear();self.validations.clear();self.task_design_review=None
        self.last_message="Task brief saved. Scene objects were not changed."

    def assign_scene_role(self, role, object_ids, remove=False):
        from .scene import ROLES, references
        require(self.scope and self.scope["kind"]=="scene_inspection", "Connect a scene task first", "APPROVAL_REQUIRED")
        require(role in ROLES and type(remove) is bool, "Unsupported role correction")
        references(object_ids)
        self.fresh()
        known={item["object_id"] for item in self.scope["snapshot"]["objects"]}
        available={item["object_id"] for item in self.scope["snapshot"]["objects"] if item["status"]=="available"}
        require(all(oid in known and (remove or oid in available) for oid in object_ids), "Choose available shared objects", "UNKNOWN_REFERENCE")
        updated=deepcopy(self.task["roles"])
        for oid in object_ids:
            values=set(updated.get(oid,[]))
            values.discard(role) if remove else values.add(role)
            if values:updated[oid]=sorted(values)
            else:updated.pop(oid,None)
        if updated!=self.task["roles"]:
            self.task["roles"]=updated
            self.task["task_revision"]+=1;self.revision+=1
            self.approved.clear();self.contexts.clear()
            self.task_design_review=None
        self.last_message="Task roles corrected. Role meaning does not grant editing permission."

    def measure_scene(self, scope_id, object_ids, purpose="receiver_and_bounds"):
        from .scene import references
        require(self.scope and self.scope["kind"]=="scene_inspection" and self.scope["scope_id"]==scope_id,
                "Measurements require the current read-only scene task", "UNKNOWN_REFERENCE")
        references(object_ids,3)
        require(purpose in ("receiver_and_bounds","source"),"Unsupported geometry measurement purpose")
        self.fresh()
        available={item["object_id"] for item in self.scope["snapshot"]["objects"] if item["status"]=="available"}
        require(all(oid in available for oid in object_ids), "Unknown or missing shared objects", "UNKNOWN_REFERENCE")
        result=self.host.measure_sources(object_ids) if purpose=="source" else self.host.measure_scene(object_ids)
        require(len(canonical(result).encode())<=32768,"Measurement response exceeds its byte budget","BUDGET_EXCEEDED")
        return {"scene_epoch":self.epoch,"scope_id":scope_id,"scene_revision":self.revision,**result}

    def share_source_package(self,directory):
        self.require_reconciled()
        require(self.scope and self.scope["kind"]=="scene_inspection" and self.task and self.pending is None,
                "Share prepared sources from an idle selected scene task locally","APPROVAL_REQUIRED")
        self.revoke_source_package()
        try:self.host.begin_source_package(directory)
        except Exception:
            self.host.release_source_package()
            raise
        self.asset_grant=dict(grant_id=uid("source_grant"),status="preparing",uses=0)
        self.last_message="Preparing the selected source package locally; no scene nodes created."

    def revoke_source_package(self):
        require(self.pending is None,"Cancel queued work before revoking prepared sources","HOST_BUSY")
        self.asset_grant=None
        if hasattr(self.host,"release_source_package"):self.host.release_source_package()
        self.approved.clear();self.contexts.clear()
        for key in [key for key,value in self.validations.items() if "asset_use" in value]:self.validations.pop(key)

    def poll_source_package(self):
        if not self.asset_grant or self.asset_grant["status"]!="preparing":return False
        try:
            value=self.host.poll_source_package()
            if value is None:return True
            from .asset_use import ready_snapshot
            origin={key:self.asset_grant[key] for key in ("origin","permission_id","request_key") if key in self.asset_grant}
            self.asset_grant={**ready_snapshot(value,self.asset_grant["grant_id"]),**origin}
            self.last_message="Prepared sources shared. Only an exact locally approved proposal can create hidden source copies."
            return False
        except Exception as exc:
            self.asset_grant.update(status="failed",error="Package preparation or source/dependency admission failed; review locally")
            self.host.release_source_package()
            self.last_message=self.asset_grant["error"]
            if isinstance(exc,Fault):raise
            raise Fault("UNSUPPORTED_CAPABILITY",self.last_message) from exc

    def validate_asset_use(self,use):
        from .asset_use import proposal
        self.require_reconciled();self.fresh()
        require(self.pending is None,"Finish or cancel queued work before proposing sources","HOST_BUSY")
        value=proposal(use,self.asset_grant,self.task,self.scope,self.revision)
        vid=uid("validation")
        result=dict(validation_id=vid,digest=digest(value),scene_epoch=self.epoch,scene_revision=self.revision,
                    expires_in_seconds=300,approval="required_in_local_panel",effect=value["effect"],
                    sources=deepcopy(value["sources"]),package_revision=value["package_revision"],
                    effects_summary=value["effects_summary"],undo=value["undo"],resources=value["resources"])
        self.validations[vid]={**result,"asset_use":value,"deadline":time.monotonic()+300}
        while len(self.validations)>8:
            removed,_=self.validations.popitem(last=False);self.approved.discard(removed)
        self.last_message="Review new source copies: "+", ".join(row["name"] for row in value["sources"])
        return result

    def require_asset_use_current(self,value):
        from .asset_use import proposal
        require(proposal(value["use"],self.asset_grant,self.task,self.scope,self.revision)==value,
                "Source proposal or prepared grant changed","STALE_CONTEXT")

    def share_installed_catalog(self):
        """Local action only: replace/revoke the grant before potentially failing IO."""
        from . import library
        require(self.scope and self.task is not None and self.pending is None,
                "Share installed models from an idle scene task locally", "APPROVAL_REQUIRED")
        self.revoke_installed_sources()
        self.library_grant=None
        value=library.snapshot(self.host.installed_model_catalog())
        value["library_id"]=uid("library")
        self.library_grant=value
        self.last_message="Installed plant metadata shared. Import, dimensions, units and renderer dependencies remain unqualified."
        return library.summary(value)

    def revoke_installed_catalog(self):
        self.revoke_installed_sources()
        self.library_grant=None
        self.last_message="Installed catalog sharing revoked. Scene objects and task roles are unchanged."

    def enable_installed_sources(self):
        """Explicit local action, never a model-callable grant."""
        self.require_reconciled()
        require(self.scope and self.scope["kind"]=="scene_inspection" and self.task and self.pending is None,
                "Enable installed source proposals from an idle selected scene task locally","APPROVAL_REQUIRED")
        require(self.library_grant and any(row.get("prepared_source",{}).get("status")=="prepared" for row in self.library_grant["entries"]),
                "Share an installed catalog with prepared source derivatives first","UNSUPPORTED_CAPABILITY")
        require(self.host.version().get("prepared_source_use_api")==1,"Matching native prepared-source APIs are required","UNSUPPORTED_CAPABILITY")
        require(self.host.version().get("prepared_source_cohort_api")==1,"Installed source selection requires native retained snapshot API 1","UNSUPPORTED_CAPABILITY")
        if self.installed_source_grant is not None:return deepcopy(self.installed_source_grant)
        self.installed_source_grant=dict(permission_id=uid("source_permission"),library_id=self.library_grant["library_id"],
            snapshot_sha256=self.library_grant["snapshot_sha256"],scope_id=self.scope["scope_id"],task_id=self.task["task_id"],
            preparations_remaining=8-len(self.source_preparations),max_sources_per_preparation=3)
        self.last_message="Installed source proposals enabled for this catalog. Preparation creates no scene objects; import still requires exact local approval."
        return deepcopy(self.installed_source_grant)

    def revoke_installed_sources(self):
        require(self.pending is None,"Cancel queued work before revoking installed source permission","HOST_BUSY")
        if self.asset_grant and self.asset_grant.get("origin")=="installed_catalog":self.revoke_source_package()
        self.installed_source_grant=None

    def prepare_installed_sources(self,scope_id,library_id,permission_id,asset_refs,request_key):
        """Bound selected opaque catalog refs to serial native preparation; no scene writes."""
        from .asset_use import summary
        self.require_reconciled()
        for key in (scope_id,library_id,permission_id,request_key):identifier(key)
        require(type(asset_refs) is list and 1<=len(asset_refs)<=3,"Choose 1–3 distinct catalog sources")
        for ref in asset_refs:identifier(ref)
        require(len(set(asset_refs))==len(asset_refs),"Choose distinct catalog sources")
        catalog=self.shared_catalog(scope_id,library_id);permission=self.installed_source_grant
        require(permission and permission["permission_id"]==permission_id,"Enable installed source proposals locally for this catalog","APPROVAL_REQUIRED")
        require(self.scope["kind"]=="scene_inspection" and self.task and permission["scope_id"]==scope_id
                and permission["task_id"]==self.task["task_id"] and permission["library_id"]==library_id
                and permission["snapshot_sha256"]==catalog["snapshot_sha256"],"Installed source permission changed","STALE_CONTEXT")
        signature=digest([scope_id,library_id,permission_id,asset_refs])
        previous=self.source_preparations.get(request_key)
        if previous:
            require(previous["signature"]==signature,"Preparation key already belongs to a different selection","IDEMPOTENCY_CONFLICT")
            if self.asset_grant and self.asset_grant["grant_id"]==previous.get("grant_id"):
                return dict(request_key=request_key,prepared_sources=summary(self.asset_grant))
            return dict(request_key=request_key,status=previous.get("status","retired"),grant_id=previous.get("grant_id"),replayed=False)
        self.fresh()
        require(self.pending is None,"Finish or cancel queued work before preparing sources","HOST_BUSY")
        require(not self.asset_grant or self.asset_grant["status"]!="preparing","Observe the current preparation before choosing another selection","HOST_BUSY")
        require(permission["preparations_remaining"]>0 and len(self.source_preparations)<8,"This task reached its installed-source preparation budget","BUDGET_EXCEEDED")
        by_ref={row["asset_ref"]:row for row in catalog["entries"]}
        require(all(ref in by_ref for ref in asset_refs),"Asset is outside this shared catalog","UNKNOWN_REFERENCE")
        entries=[by_ref[ref] for ref in asset_refs]
        require(all(row.get("prepared_source",{}).get("status")=="prepared" for row in entries),
                "Some selected models have no vetted prepared derivative; inspect their availability","UNSUPPORTED_CAPABILITY")
        require(sum("source" in roles for roles in self.task["roles"].values())+len(entries)<=3
                and len(self.scope["snapshot"]["objects"])+len(entries)<=32,"Task source/object budget exceeded","BUDGET_EXCEEDED")
        self.revoke_source_package()
        permission["preparations_remaining"]-=1
        record=dict(signature=signature,status="failed")
        self.source_preparations[request_key]=record
        try:self.host.begin_installed_sources(entries)
        except Exception as exc:
            self.host.release_source_package()
            raise Fault(exc.code if isinstance(exc,Fault) else "UNSUPPORTED_CAPABILITY",
                        "Installed sources could not be prepared; inspect the local content and choose a new request key after repair") from exc
        self.asset_grant=dict(grant_id=uid("source_grant"),status="preparing",uses=0,origin="installed_catalog",
                              permission_id=permission_id,request_key=request_key)
        record.update(grant_id=self.asset_grant["grant_id"],status="retired")
        self.last_message="Preparing selected installed sources. Observe prepared_sources in connection status; no scene objects created."
        return dict(request_key=request_key,prepared_sources=summary(self.asset_grant))

    def shared_catalog(self, scope_id, library_id):
        require(self.scope and self.scope["scope_id"]==scope_id,"Unknown scene scope","UNKNOWN_REFERENCE")
        require(self.library_grant is not None,"Share installed plant metadata locally in Task details first","APPROVAL_REQUIRED")
        require(library_id==self.library_grant["library_id"],"Catalog grant changed; read the current context","STALE_CONTEXT")
        # Deliberately do not fingerprint geometry or touch the filesystem.
        return self.library_grant

    def search_catalog(self, scope_id, library_id, query="", category="", offset=0, limit=12):
        from . import library
        return library.search(self.shared_catalog(scope_id,library_id),query,category,offset,limit)

    def inspect_catalog_entry(self, scope_id, library_id, asset_ref):
        from . import library
        return library.inspect(self.shared_catalog(scope_id,library_id),asset_ref)

    def share_recipe_catalog(self,kind,root=None):
        """Local-only root grant; the model never supplies a path or starts scans."""
        require(self.scope and self.task is not None and self.pending is None,
                "Share recipes from an idle scene task locally","APPROVAL_REQUIRED")
        require(kind in ("personal_recipes","custom_recipes"),"Unsupported recipe folder kind")
        self.revoke_recipe_catalog()
        self.host.start_recipe_catalog(kind,root)
        self.recipe_grant={"library_id":uid("recipes"),"kind":kind,"status":"scanning",
                           "scanned":0,"entry_count":0,"invalid":0,"limited":False}
        self.recipe_deadline=time.monotonic()+60
        self.last_message="Recipe folder shared for metadata scanning only. Application and dependency readiness remain unchecked."
        return recipe_summary(self.recipe_grant)

    def revoke_recipe_catalog(self):
        self.recipe_grant=None;self.recipe_deadline=None
        if hasattr(self.host,"stop_recipe_catalog"):self.host.stop_recipe_catalog()

    def poll_recipe_catalog(self):
        """Local event-loop work only, independent of remote reads and their budget."""
        from . import recipes
        grant=self.recipe_grant
        if grant is None or grant["status"]!="scanning":return
        try:
            require(time.monotonic()<=self.recipe_deadline,"Recipe scan timed out; refresh locally","CATALOG_UNAVAILABLE")
            result=self.host.poll_recipe_catalog()
            counts=recipes.progress(result)
            require(result["state"]!="cancelled" and not result["has_error"],"Recipe folder scan failed; review and refresh locally","CATALOG_UNAVAILABLE")
            grant.update(counts)
            if result["state"]=="complete":
                snapshot=recipes.snapshot(result)
                self.host.stop_recipe_catalog()
                grant.update(snapshot);self.recipe_deadline=None
                self.last_message="Recipe metadata snapshot ready. Invalid/limited entries and omissions are reported; no recipe is approved for use."
        except Exception as exc:
            # Native filesystem errors can contain private paths. No raw exception
            # text is placed in a shared summary or entry response.
            self.host.stop_recipe_catalog();self.recipe_deadline=None
            grant.update(status="failed",error={"code":exc.code if isinstance(exc,Fault) else "CATALOG_UNAVAILABLE",
                                               "message":"Recipe metadata could not be completed. Review the local folder and refresh; no entries are shared."})
            grant.pop("entries",None);grant.pop("snapshot_sha256",None)
            self.last_message=grant["error"]["message"]

    def shared_recipes(self,scope_id,library_id):
        require(self.scope and self.scope["scope_id"]==scope_id,"Unknown scene scope","UNKNOWN_REFERENCE")
        require(self.recipe_grant is not None,"Share a recipe folder locally in Task details first","APPROVAL_REQUIRED")
        require(library_id==self.recipe_grant["library_id"],"Recipe grant changed; read the current connection/context","STALE_CONTEXT")
        return self.recipe_grant

    def search_recipes(self,scope_id,library_id,query="",category="",offset=0,limit=12):
        from . import recipes
        return recipes.search(self.shared_recipes(scope_id,library_id),query,category,offset,limit)

    def inspect_recipe(self,scope_id,library_id,recipe_ref):
        from . import recipes
        return recipes.inspect(self.shared_recipes(scope_id,library_id),recipe_ref)

    def share_preset_catalog(self,kind,root=None):
        require(self.scope and self.task is not None and self.pending is None,"Share settings presets from an idle scene task locally","APPROVAL_REQUIRED")
        require(kind in ("personal_presets","custom_presets"),"Unsupported settings preset folder kind")
        self.revoke_preset_catalog();self.host.start_preset_catalog(kind,root)
        self.preset_grant=dict(library_id=uid("presets"),kind=kind,status="scanning",scanned=0,entry_count=0,invalid=0,limited=False)
        self.preset_deadline=time.monotonic()+60
        self.last_message="Settings preset folder shared for native metadata and selected frozen settings inspection only. Application is not authorized."
        return preset_summary(self.preset_grant)

    def revoke_preset_catalog(self):
        self.preset_grant=None;self.preset_deadline=None
        if hasattr(self.host,"stop_preset_catalog"):self.host.stop_preset_catalog()

    def poll_preset_catalog(self):
        from . import presets
        grant=self.preset_grant
        if grant is None or grant["status"]!="scanning":return
        try:
            require(time.monotonic()<=self.preset_deadline,"Settings preset scan timed out; refresh locally","CATALOG_UNAVAILABLE")
            value=self.host.poll_preset_catalog()
            # The host freezes multiple bounded pages before returning entries.
            counts=presets.progress({**value,"entries":[]})
            require(value["state"]!="cancelled" and not value["has_error"],"Settings preset scan failed","CATALOG_UNAVAILABLE")
            grant.update(counts)
            if value["state"]=="complete":
                grant.update(presets.snapshot(value));self.preset_deadline=None
                self.last_message="Settings preset snapshot ready. Inspect actual typed settings; no application or scene changes are authorized."
        except Exception as exc:
            self.host.stop_preset_catalog();self.preset_deadline=None
            grant.update(status="failed",error=dict(code=exc.code if isinstance(exc,Fault) else "CATALOG_UNAVAILABLE",
                message="Settings preset snapshot could not be completed; review the local folder and refresh"))
            grant.pop("entries",None);grant.pop("snapshot_sha256",None);self.last_message=grant["error"]["message"]

    def shared_presets(self,scope_id,library_id):
        require(self.scope and self.scope["scope_id"]==scope_id,"Unknown scene scope","UNKNOWN_REFERENCE")
        require(self.preset_grant is not None,"Share settings presets locally in Task details first","APPROVAL_REQUIRED")
        require(self.preset_grant["library_id"]==library_id,"Settings preset grant changed","STALE_CONTEXT")
        return self.preset_grant

    def search_presets(self,scope_id,library_id,query="",category="",offset=0,limit=24):
        from . import presets
        return presets.search(self.shared_presets(scope_id,library_id),query,category,offset,limit)

    def inspect_preset(self,scope_id,library_id,preset_ref):
        from . import presets
        grant=self.shared_presets(scope_id,library_id);row=presets.entry(grant,preset_ref)
        return presets.inspect(grant,row,self.host.inspect_preset_entry(row["entry_key"]))

    def check_epoch(self, epoch):
        require(epoch == self.epoch, "The scene session changed", "STALE_CONTEXT")

    def dispatch(self, method, args):
        require(type(args) is dict, "Tool arguments must be an object")
        methods = {
            "scene.get_context": self.context,
            "scene.measure_objects": self.measure_scene,
            "library.search": self.search_catalog,
            "library.inspect_entry": self.inspect_catalog_entry,
            "recipes.search": self.search_recipes,
            "recipes.inspect_entry": self.inspect_recipe,
            "presets.search":self.search_presets,
            "presets.inspect_entry":self.inspect_preset,
            "scatter.validate_plan": self.validate,
            "scatter.validate_change": self.validate_change,
            "scatter.apply_plan": self.apply,
            "scatter.get_status": self.status,
            "scatter.get_diagnostics": self.diagnostics,
            "scatter.read_diagnostic_events": self.diagnostic_events,
            "scatter.get_publication": self.publication,
            "scatter.read_publication_page": self.publication_page,
            "scatter.get_configuration": self.configuration,
            "scatter.get_settings":self.destination_settings,
            "scatter.export_record": self.export_record,
            "scene.capture_viewport": self.capture,
            "connection.get_status": self.connection,
            "assets.validate_use":self.validate_asset_use,
            "assets.prepare_sources":self.prepare_installed_sources,
        }
        require(method in methods, "Unsupported operation", "UNSUPPORTED_CAPABILITY")
        if method not in ("connection.get_status", "scatter.get_status", "scatter.get_diagnostics", "scatter.apply_plan", "scatter.read_publication_page"):
            require(self.calls < 24, "This scope reached its 24-call budget; re-enroll locally", "BUDGET_EXCEEDED")
        if method not in ("connection.get_status", "scatter.read_publication_page", "scatter.get_status", "scatter.apply_plan"):
            self.calls += 1
        import inspect
        try:
            inspect.signature(methods[method]).bind(**args)
        except TypeError as exc:
            raise Fault("INVALID_PLAN", "Missing or unsupported tool arguments") from exc
        return {"ok": True, **methods[method](**args)}

    def connection(self):
        from .asset_use import summary as prepared_summary
        from .installed_sources import permission_summary
        return {"version": __version__, "scene_epoch": self.epoch, "scene_revision": self.revision,
                "scope_id": self.scope["scope_id"] if self.scope else None,
                "scope_kind":self.scope["kind"] if self.scope else None,
                "shared_diagnostic_session_id": self.diagnostic_session,
                "installed_catalog": catalog_summary(self.library_grant),
                "recipe_catalog":recipe_summary(self.recipe_grant),
                "preset_catalog":preset_summary(self.preset_grant),
                "prepared_sources":prepared_summary(self.asset_grant),
                "installed_source_permission":permission_summary(self.installed_source_grant),
                "recovery_required": self.recovery_required,
                "unresolved_operations": self.unresolved_operations(),
                "message": self.last_message, "host": self.host.version(),
                "support": "Read-only selected-object onboarding (32 objects); bounded static mesh measurements. Design: static horizontal convex sites, three assets/regions, two approved publications."}

    def context(self, scope_id):
        self.fresh()
        require(scope_id == self.scope["scope_id"], "Unknown scope", "UNKNOWN_REFERENCE")
        cid = uid("context")
        if self.scope["kind"]=="scene_inspection":
            from .asset_use import summary as prepared_summary
            from .installed_sources import permission_summary
            result={"context_id":cid,"scene_epoch":self.epoch,"scene_revision":self.revision,
                    "revision_semantics":"Metadata/task revision only; does not certify unchanged geometry",
                    "scope":deepcopy(self.scope),"task":deepcopy(self.task),"installed_catalog":catalog_summary(self.library_grant),"recipe_catalog":recipe_summary(self.recipe_grant),
                    "units":{"length":"metres","angles":"degrees","coordinates":"right-handed Z up"},
                    "prepared_sources":prepared_summary(self.asset_grant),
                    "preset_catalog":preset_summary(self.preset_grant),
                    "installed_source_permission":permission_summary(self.installed_source_grant),
                    "capabilities":["scoped_scene_metadata","explicit_static_mesh_measurement","local_role_correction"],
                    "budget":{"calls_remaining":max(0,24-self.calls),"shared_objects":32,"measurement_objects_per_call":3,
                              "candidates_remaining":0,"configurations_remaining":0,"captures_remaining":0}}
            require(len(canonical(result).encode())<=65536,"Scene context exceeds its byte budget","BUDGET_EXCEEDED")
            return result
        result = {"context_id": cid, "scene_epoch": self.epoch, "scene_revision": self.revision,
                  "units": {"length": "metres", "angles": "degrees", "coordinates": "right-handed Z up"},
                  "scope": deepcopy(self.scope), "owned_controllers": deepcopy(self.owned),"installed_catalog":catalog_summary(self.library_grant),"recipe_catalog":recipe_summary(self.recipe_grant),
                  "observed_controllers": deepcopy(self.observed),
                  "preset_catalog":preset_summary(self.preset_grant),
                  "viewport_id": self.host.viewport_id(),
                  "capabilities": ["count", "seed", "random_source_weights", "uniform_scale_yaw", "convex_footprint_masks", "owned_create", "approved_refine", "viewport_capture"],
                  "settings_contract":capability_manifest(),
                  "budget": {"calls_remaining": max(0,24-self.calls), "candidates_remaining": 2-self.applications, "configurations_remaining": 8-self.configurations, "captures_remaining": 2-self.captures}}
        if self.scope["kind"]=="inspection":
            result["capabilities"]=["cached_inspection","viewport_capture"]
            result["budget"]["candidates_remaining"]=0
        if self.task is not None:
            result["task"]=deepcopy(self.task)
            result["task_scene_snapshot"]=self.host.scene_snapshot()
            self.scope["task_snapshot"]=deepcopy(result["task_scene_snapshot"])
            result["scope"].pop("task_snapshot",None)
            result.pop("settings_contract",None)
            result["settings_contract_resource"]="cyrus://capabilities"
        require(len(canonical(result)) <= 65536, "Context exceeds its limit", "BUDGET_EXCEEDED")
        self.contexts[cid] = (self.revision, time.monotonic()+300)
        while len(self.contexts) > 8:
            self.contexts.popitem(last=False)
        return result

    def validate(self, plan):
        self.require_reconciled()
        total = validate_shape(plan)
        plan=normalize_plan(plan)
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
            settings=layer["settings"]
            tilt=any(settings[key]!=[0,0] for key in ("rotation_x_degrees","rotation_y_degrees"))
            radius=max(sources[s["source_id"]].get("bounding_radius_m",sources[s["source_id"]]["radius_m"]) * s["settings"]["scale"] if tilt else sources[s["source_id"]]["radius_m"] * s["settings"]["scale"] for s in layer["sources"] if s["weight"]>0)
            radius*=layer["scale"][1]*max(settings[axis][1] for axis in ("scale_x","scale_y","scale_z"))
            clearance = plan.get("clearance_m", 0)
            movement=0.0
            import math
            movement=math.hypot(max(abs(x) for x in layer["settings"]["movement_x_m"]),max(abs(x) for x in layer["settings"]["movement_y_m"]))
            exclusions=[];validation_exclusions=[]
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

    def validate_change(self, change):
        self.require_reconciled()
        self.fresh()
        require(self.scope["kind"] == "design", "Inspection cannot change setups", "UNSUPPORTED_CAPABILITY")
        require(type(change) is dict, "Change must be an object")
        for key in ("context_id", "controller_id", "generation_id", "configuration_id"):
            identifier(change.get(key))
        existing = self.owned.get(change.get("controller_id"))
        definition = self.authored.get(change.get("controller_id"))
        require(existing and definition, "No current owned definition", "UNKNOWN_REFERENCE")
        ctx = self.contexts.get(change.get("context_id"))
        require(ctx and ctx[0] == self.revision and ctx[1] >= time.monotonic(), "Context expired or changed", "STALE_CONTEXT")
        from .changes import prepare_change
        plan, review = prepare_change(change, definition, existing)
        self.require_change_budget(change["mode"])
        normalized = deepcopy(change)
        normalized.setdefault("layers", [])
        vid = uid("validation")
        result = {"validation_id": vid, "digest": digest(normalized), "scene_epoch": self.epoch,
                  "scene_revision": self.revision, "expires_in_seconds": 300, "effect": change["mode"],
                  "derived_masks": 0, "approval": "required_in_local_panel", "changes": review,
                  "requested_instances": sum(layer["count"] for layer in plan["layers"]), "layers": len(plan["layers"]),
                  "publication_effect": "keep_previous_pending" if change["mode"] == "configure" else "calculate_and_replace_complete_publication"}
        self.validations[vid] = {**result, "plan": plan, "compiled": deepcopy(definition["compiled"]),
                                 "change": normalized, "deadline": time.monotonic()+300}
        while len(self.validations) > 8:
            removed, _ = self.validations.popitem(last=False)
            self.approved.discard(removed)
        self.last_message = "Review " + change["mode"].replace("_", " ") + ": " + str(len(review)) + " setting changes."
        return result

    def require_change_budget(self, mode):
        require(self.configurations < 8 if mode == "configure" else self.applications < 2,
                "Configuration budget exhausted" if mode == "configure" else "Candidate budget exhausted", "BUDGET_EXCEEDED")

    def approve(self, validation_id):
        self.require_reconciled()
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
        self.require_reconciled()
        require(self.calls < 24, "Tool-call budget exhausted; outcome queries and exact retries remain available", "BUDGET_EXCEEDED")
        self.calls += 1
        self.check_epoch(scene_epoch)
        self.fresh()
        require(scene_revision == self.revision, "Scene changed", "STALE_CONTEXT")
        require(self.pending is None, "An operation is already pending", "HOST_BUSY")
        value = self.validations.get(validation_id)
        require(value and value["digest"] == digest and value["scene_revision"] == self.revision and value["deadline"] >= time.monotonic(), "Validation expired or changed", "STALE_CONTEXT")
        mode = "import_sources" if "asset_use" in value else value.get("change", {}).get("mode", "generate")
        if "asset_use" in value:self.require_asset_use_current(value["asset_use"])
        else:self.require_change_budget(mode)
        require(validation_id in self.approved, "Approve this exact proposal in the local panel", "APPROVAL_REQUIRED")
        oid = uid("operation")
        record = {"operation_id": oid, "scene_epoch": self.epoch, "scene_revision": self.revision,
                  "idempotency_key": idempotency_key, "signature": signature, "state": "queued", "created_unix": time.time(),
                  "effects": "none", "phase": "admitted", "recovery_required": False}
        record["operation_kind"] = mode
        if "change" in value:
            record["target_identity"] = {key:value["change"][key] for key in
                                         ("controller_id", "generation_id", "configuration_id")}
            record["target_identity_semantics"] = "Approved base before execution; not a commit witness or current-scene authority."
        if "asset_use" in value:
            record["target_identity"]={key:value["asset_use"]["use"][key] for key in ("scope_id","task_id","grant_id","asset_refs")}
            record["target_identity_semantics"]="Approved prepared source references; new source identities are recorded only after native commit."
        self.journal.records[oid] = record
        if not self.save_operation(record):  # Persist admission before any scene mutation.
            raise Fault("JOURNAL_FAILED", record["error"]["message"], operation_id=oid, effects="none")
        self.pending = (oid, deepcopy(value))
        self.approved.discard(validation_id)
        return {"operation": deepcopy(record)}

    def cancel(self):
        self.approved.clear()
        if self.pending:
            oid, _ = self.pending
            record = self.journal.records[oid]
            if record["state"] == "queued":
                record.update(state="cancelled", effects="none", phase="cancelled")
                self.pending = None
                self.save_operation(record)

    def step(self):
        if self.pending is None:
            return
        oid, value = self.pending
        record = self.journal.records[oid]
        entered_host = False
        started = time.perf_counter()
        try:
            self.require_reconciled()
            self.fresh()
            require(value["scene_revision"] == self.revision and value["deadline"] >= time.monotonic(), "Scene or validation changed while queued", "STALE_CONTEXT")
            require(not self.host.busy(), "Host is busy; operation was not applied", "HOST_BUSY")
            if "asset_use" in value:self.require_asset_use_current(value["asset_use"])
            record.update(state="running", effects="unknown", phase="executing")
            if not self.save_operation(record):
                record["effects"] = "none"  # Native execution has not started.
                return
            entered_host = True
            definition = None if "asset_use" in value else {"plan": value["plan"], "compiled": value["compiled"]}
            try:
                if "asset_use" in value:
                    result=self.host.use_source_assets(value["asset_use"])
                elif "change" in value:
                    result = self.host.change(value["change"], value["plan"], value["compiled"],
                                              deepcopy(self.owned[value["change"]["controller_id"]]))
                else:
                    result = self.host.generate(value["plan"], value["compiled"])
            except Fault as exc:
                if exc.details.get("effects") == "committed" and isinstance(exc.details.get("result"), dict):
                    self.record_commit(record, exc.details["result"], definition)
                raise
            self.record_commit(record, result, definition)
            if not self.save_operation(record):
                return
            if "asset_use" in value:
                self.scope["snapshot"]=self.host.scene_snapshot()
                self.last_fingerprint=digest(self.scope["snapshot"])
            else:self.last_fingerprint = self.host.fingerprint()
            configuring = record["operation_kind"] == "configure"
            if "asset_use" not in value and not configuring and hasattr(self.host,"layouts") and result["controller_id"] in self.host.layouts:
                from .records import execution_record
                self.records[result["controller_id"]]=execution_record(self.scope,value["plan"],result,self.host.layouts[result["controller_id"]])
            record.update(state="succeeded", phase="verified", recovery_required=False)
            self.last_undo = (self.revision, result["undo_label"])
            self.last_message = (f"Imported {len(result['sources'])} hidden source copies into this task. Review roles, then enable design proposals separately." if "asset_use" in value else
                                "Settings saved; previous publication retained. Update is pending. Undo is available locally."
                                 if configuring else f"Published {result['emitted']} plants. Undo is available locally.")
        except Fault as exc:
            if record["effects"] == "committed":
                record.update(state="failed", recovery_required=True,
                              error={"code": "POST_COMMIT_FAILED", "cause_code": exc.code,
                                     "message": "Native changes committed, but completion checks failed. Inspect the recorded result locally; do not replay."})
            else:
                effects = ("none" if not entered_host or exc.details.get("effects") == "none" else
                           "verified_rollback" if exc.details.get("rollback") == "verified" else "unknown")
                record.update(state="outcome_unknown" if effects == "unknown" else "failed", effects=effects,
                              recovery_required=effects == "unknown", error=exc.result()["error"])
            if record["recovery_required"]:
                self.invalidate_after_failure()
            self.last_message = record["error"]["message"]
        except Exception:
            committed = record["effects"] == "committed"
            record.update(state="failed" if committed or not entered_host else "outcome_unknown",
                          effects="committed" if committed else "unknown" if entered_host else "none",
                          recovery_required=True,
                          error={"code": "POST_COMMIT_FAILED" if committed else "OUTCOME_UNKNOWN",
                                 "message": "Completion could not be verified. Inspect the operation and scene locally before continuing; do not replay."})
            self.invalidate_after_failure()
            self.last_message = record["error"]["message"]
        finally:
            record["duration_ms"] = (time.perf_counter()-started)*1000
            self.pending = None
            self.save_operation(record)

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
        owner = self.owned[controller_id]
        return {"controller": deepcopy(owner), "freshness": "previous_publication_pending_update" if owner.get("publication_pending") else "last_publication"}

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

    def destination_settings(self,scene_epoch,controller_id,layer_id=None,categories=None):
        from .destination_settings import request_categories
        self.check_epoch(scene_epoch);identifier(controller_id)
        require(self.scope and (controller_id in self.owned or controller_id in self.observed),"Unknown scoped controller","UNKNOWN_REFERENCE")
        if layer_id is None:
            require(categories is None,"Omit categories when listing settings targets")
            return dict(settings_targets=self.host.settings_targets(controller_id),scene_epoch=self.epoch,scene_revision=self.revision)
        identifier(layer_id)
        if categories is None:
            from .presets import CATEGORIES
            categories=list(CATEGORIES)
        request_categories(categories)
        # This read intentionally does not call fresh(): task fingerprinting can
        # evaluate input geometry. Actual values carry their own snapshot hash.
        value=self.host.destination_settings(controller_id,layer_id,categories)
        require(len(canonical(value).encode())<=160*1024,"Destination settings exceed their response budget","BUDGET_EXCEEDED")
        return dict(settings=value,scene_epoch=self.epoch,scene_revision=self.revision,
            revision_semantics="MCP metadata counter only; the current native settings snapshot does not certify unchanged geometry or publications")

    def configuration(self,scene_epoch,controller_id):
        self.check_epoch(scene_epoch);self.fresh()
        require(controller_id in self.owned or controller_id in self.observed,"Unknown scoped controller","UNKNOWN_REFERENCE")
        result = {"configuration":self.host.configuration(controller_id)}
        if controller_id in self.owned:
            owner = self.owned[controller_id]
            result.update(configuration_id=owner.get("configuration_id", owner["generation_id"]),
                          generation_id=owner["generation_id"], publication_pending=owner.get("publication_pending", False))
        return result

    def export_record(self,scene_epoch,controller_id,generation_id):
        self.check_epoch(scene_epoch);self.fresh()
        receipt=self.owned.get(controller_id)
        require(receipt and receipt["generation_id"]==generation_id,"Unknown published generation","UNKNOWN_REFERENCE")
        require(controller_id in self.records,"No recorded final layout for this generation","UNSUPPORTED_CAPABILITY")
        record=deepcopy(self.records[controller_id])
        require(len(canonical(record).encode())<=1500000,"Export exceeds its 1.5 MiB budget","BUDGET_EXCEEDED")
        return {"record":record,"training_eligible":False,
                "publication_pending":receipt.get("publication_pending", False),
                "current_configuration_id":receipt.get("configuration_id",receipt["generation_id"])}

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
                "freshness":"cached preview; source geometry not regenerated or certified" if self.observed else
                            "previous complete publication; authored settings pending Update" if any(v.get("publication_pending") for v in self.owned.values()) else "validated publication"}

    def undo(self):
        self.require_reconciled()
        require(self.pending is None,"Finish or cancel queued work before Undo","HOST_BUSY")
        self.fresh()
        require(self.last_undo and self.last_undo[0] == self.revision, "The scene changed; use Max's Undo history to review", "STALE_CONTEXT")
        label=self.last_undo[1]
        oid=uid("operation")
        record=dict(operation_id=oid,idempotency_key=uid("local_undo"),
                    signature=canonical(["local_undo",self.epoch,self.revision,label]),
                    scene_epoch=self.epoch,scene_revision=self.revision,created_unix=time.time(),
                    operation_kind="undo",state="queued",effects="none",phase="admitted",recovery_required=False)
        if self.owned:
            owner=next(iter(self.owned.values()))
            record["target_identity"]={key:owner[key] for key in ("controller_id","generation_id","configuration_id") if key in owner}
            record["target_identity_semantics"]="Owned result before local Undo; not a restored-state witness."
        self.journal.records[oid]=record
        if not self.save_operation(record):
            raise Fault("JOURNAL_FAILED",record["error"]["message"],operation_id=oid,effects="none")
        record.update(state="running",effects="unknown",phase="executing")
        if not self.save_operation(record):
            record["effects"]="none"
            raise Fault("JOURNAL_FAILED",record["error"]["message"],operation_id=oid,effects="none")
        try:
            try:
                result=self.host.undo(label)
            except Fault as exc:
                if exc.details.get("effects")=="committed":
                    self.record_undo_commit(record,exc.details.get("result",{}))
                raise
            require(type(result) is dict and result.get("native_undo_verified") is True,
                    "Host did not provide a verified Undo witness","UNDO_UNVERIFIED")
            self.record_undo_commit(record,result)
            if self.save_operation(record):
                self.reset()
                record.update(state="succeeded",phase="verified")
                self.last_message="Layout undone. Re-enroll before another proposal."
        except Exception as exc:
            none=isinstance(exc,Fault) and exc.details.get("effects")=="none"
            record.update(state="failed" if none or record["effects"]=="committed" else "outcome_unknown",
                          effects="none" if none else "committed" if record["effects"]=="committed" else "unknown")
            record["recovery_required"]=record["effects"]!="none"
            record["error"]={"code":"POST_COMMIT_FAILED" if record["effects"]=="committed" else exc.code if isinstance(exc,Fault) else "OUTCOME_UNKNOWN",
                             "message":str(exc)[:300] if none else "Local Undo completion needs review. Do not repeat Undo or start another mutation."}
            if record["recovery_required"]:self.invalidate_after_failure()
            self.last_message=record["error"]["message"]
        self.save_operation(record)
        return {"operation":deepcopy(record)}

    def record_undo_commit(self,record,result):
        record.update(effects="committed",phase="native_undo_verified")
        self.revision+=1;record["scene_revision"]=self.revision
        if isinstance(result,dict):
            record["commit_identity"]={key:result[key] for key in ("controller_id","generation_id","configuration_id") if isinstance(result.get(key),str)}
        canonical(result)
        record["result"]=deepcopy(result)
