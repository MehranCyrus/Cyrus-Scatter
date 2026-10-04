"""Provider-neutral operational records. These are not training consent."""
from copy import deepcopy
from .contracts import digest, fields, identifier, require


def execution_record(context, plan, receipt, layout):
    require(layout["transform_digest"]==receipt["transform_digest"],"Receipt/layout digest mismatch","HOST_ERROR")
    require(digest([[row["transform"],row["source_index"]] for row in layout["instances"]])==receipt["transform_digest"],"Exported transforms differ from publication","HOST_ERROR")
    require(len(layout["instances"])==receipt["emitted"],"Exported count differs from publication","HOST_ERROR")
    return {"record_schema":"cyrus.execution/1.0","units":{"length":"metres","angles":"degrees","matrix":"column-vector 4x4, right-handed Z up"},
            "context":{"record_schema":"cyrus.context/1.0","snapshot":deepcopy(context)},"context_digest":digest(context),"plan":deepcopy(plan),"plan_digest":digest(plan),
            "receipt":deepcopy(receipt),"layout":deepcopy(layout),
            "lineage":{"replaces_generation_id":plan.get("generation_id"),"kind":"whole_layout_generation","instance_correspondence":None},
            "provenance":{"producer":"Cyrus Scatter MCP","ui_version":receipt.get("ui_version"),"source":"enrolled_local_scene","training_eligible":False,"consent_record_id":None},
            "missing_value_semantics":"null means unknown or not recorded; never zero or a negative example"}


def correction_record(before_generation, after_generation, changes, consent_record_id=None):
    """Explicit correction contract; no automatic labels from parameter changes."""
    identifier(before_generation);identifier(after_generation)
    require(type(changes) is list and len(changes)<=2000,"Correction budget exceeded")
    allowed={"move","hide","delete","whole_layout_replacement","parameter_change"}
    for change in changes:
        fields(change,("kind","before_id","after_id"))
        require(change["kind"] in allowed,"Unknown correction kind")
        if change["kind"] in ("whole_layout_replacement","parameter_change"):
            require(change["before_id"] is None and change["after_id"] is None,"No inferred per-instance correspondence")
        else:
            require(type(change["before_id"]) is str and 1<=len(change["before_id"])<=200,"Stable source instance identity is required")
            require(change["after_id"] is None or (type(change["after_id"]) is str and 1<=len(change["after_id"])<=200),"Invalid corrected identity")
    if consent_record_id is not None:identifier(consent_record_id)
    return {"record_schema":"cyrus.correction/1.0","before_generation_id":before_generation,"after_generation_id":after_generation,
            "changes":deepcopy(changes),"consent_record_id":consent_record_id,"training_eligible":False,
            "eligibility_note":"A separate consent, provenance and dataset review must establish eligibility."}
