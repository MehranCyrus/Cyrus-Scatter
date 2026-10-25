"""Real SDK and owned Max scene onboarding; private fixture, no artist setup."""
import json
import sys
import uuid

from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import qualification, verify_owned


async def run(base):
    q=qualification(base)
    receipt=q.folder/("scene-"+uuid.uuid4().hex+".json")
    evidence={"status":"running","cases":[],"qualification":"Owned Max 2027 plus real SDK; scripted local UI methods, not physical artist consent"}

    def save():
        meta=verify_owned(q.folder)
        evidence.update(pid=meta["pid"],run_id=meta["run_id"],artifact_id=meta["artifact_id"])
        receipt.write_text(json.dumps(evidence,indent=2)+"\n",encoding="utf-8")

    q.local("setup")
    first=q.apply({**q.plan(q.context(),count=80,layers=1),"display":{"mode":"mesh"}})
    assert first["state"]=="succeeded",first
    cid=first["result"]["controller_id"]
    q.local("publication_snapshot",controller_id=cid)
    old_plan={**q.plan(q.context(),count=90),"controller_id":cid,"generation_id":first["result"]["generation_id"]}
    old=q.call("scatter.validate_plan",plan=old_plan)
    q.local("approve",validation_id=old["validation_id"])
    initial=q.local("scene_fixture")
    evidence["initial"]=initial;save()
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    try:
        async with Client(params) as client:
            async def call(name,**args):
                verify_owned(q.folder)
                result=await client.call_tool(name,args)
                verify_owned(q.folder)
                assert not result.is_error,result
                assert result.structured_content["ok"],result
                return result.structured_content

            async def denied(name,args,code=None):
                result=await client.call_tool(name,args)
                assert result.is_error,result
                if code:assert result.structured_content["error"]["code"]==code,result
                return result.structured_content

            tools=await client.list_tools()
            assert len(tools.tools)==14 and next(t for t in tools.tools if t.name=="scene_measure_objects").annotations.read_only_hint
            connection=await call("connection_get_status")
            scope=connection["scope_id"]
            context=await call("scene_get_context",scope_id=scope)
            cards=context["scope"]["snapshot"]["objects"]
            assert len(cards)==4 and all(c["geometry"]=="unmeasured" for c in cards)
            plane=next(c["object_id"] for c in cards if c["object_type"]=="Plane")
            source=next(c["object_id"] for c in cards if c["object_type"]=="Cone")
            region=next(c["object_id"] for c in cards if c["object_type"]=="SplineShape")
            box=next(c["object_id"] for c in cards if c["object_type"]=="Box")
            assert next(c for c in cards if c["object_id"]==source)["parent_outside_scope"]
            assert len({c["label"] for c in cards})<4 and next(c for c in cards if c["object_id"]==box)["label_truncated"]
            q.local("scene_brief",brief="A meadow here; keep the entrance clear")
            q.local("scene_role",role="receiver",object_ids=[plane])
            q.local("scene_role",role="source",object_ids=[source])
            q.local("scene_role",role="preserve",object_ids=[source,box])
            q.local("scene_role",role="context",object_ids=[box])
            q.local("scene_role",role="context",object_ids=[box],remove=True)
            context=await call("scene_get_context",scope_id=scope)
            task=context["task"]
            ui=q.local("scene_ui")
            assert task["roles"][source]==["preserve","source"] and ui["brief"]==task["brief"]
            assert ui["enabled"] and all(row["roles"]==", ".join(task["roles"].get(row["object_id"],[])) or row["roles"]=="Unassigned" for row in ui["rows"])
            reopened=q.local("scene_reopen_task")
            assert reopened["visible"] and reopened["task"]==task and ui["details_enabled"]
            assert q.local("scene_highlight",object_ids=[plane])["selected_ids"]==[plane]
            # Warm the independent existing owner before measuring passive reads.
            pub=q.local("publication_snapshot",controller_id=cid)
            state=q.local("scene_state")
            measured=await call("scene_measure_objects",scope_id=scope,object_ids=[plane,source,box])
            assert q.local("scene_state")==state
            after=q.local("publication_snapshot",controller_id=cid)
            for field in ("rows_sha256","authored_sha256","generation_id","configuration_id","cache_builds","native_retained"):
                assert after[field]==pub[field],field
            assert pub["native_retained"] is not None
            bounds=next(m for m in measured["measurements"] if m["object_id"]==plane)["world_aabb_m"]
            assert bounds=={"minimum":[-15.,-15.,0.],"maximum":[15.,15.,0.],"size":[30.,30.,0.]},bounds
            old_source=next(m for m in measured["measurements"] if m["object_id"]==source)
            await denied("scene_measure_objects",dict(scope_id=scope,object_ids=[region]),"UNSUPPORTED_CAPABILITY")
            await denied("scene_measure_objects",dict(scope_id=scope,object_ids=["outside"]),"UNKNOWN_REFERENCE")
            await denied("scatter_validate_plan",dict(plan={**old_plan,"context_id":context["context_id"]}),"UNSUPPORTED_CAPABILITY")
            await denied("scatter_validate_change",dict(change={"change_schema":"cyrus.owned-change/1.0","context_id":context["context_id"],"controller_id":cid,"generation_id":first["result"]["generation_id"],"configuration_id":first["result"]["generation_id"],"mode":"update","layers":[]}),"UNSUPPORTED_CAPABILITY")
            await denied("scatter_apply_plan",{**{k:old[k] for k in ("validation_id","digest","scene_epoch","scene_revision")},"idempotency_key":"old_design"},"STALE_CONTEXT")
            evidence["cases"].append(dict(scenario="bounded_roles_measurement_and_authority",passed=True,context=context,ui=ui,measurement=measured,publication_preserved=True))
            save()
            q.local("scene_edit",object_id=source,kind="rename")
            assert (await call("scene_get_context",scope_id=scope))["task"]==task
            q.local("scene_edit",object_id=source,kind="height")
            changed=await call("scene_measure_objects",scope_id=scope,object_ids=[source])
            new_source=changed["measurements"][0]
            assert new_source["geometry_world_sha256"]!=old_source["geometry_world_sha256"]
            assert abs(new_source["world_aabb_m"]["size"][2]-old_source["world_aabb_m"]["size"][2]-.5)<1e-5
            assert (await call("scene_get_context",scope_id=scope))["task"]==task
            q.local("scene_edit",object_id=source,kind="units")
            cm=await call("scene_measure_objects",scope_id=scope,object_ids=[plane])
            assert abs(cm["measurements"][0]["world_aabb_m"]["size"][0]-.3)<1e-6
            q.local("scene_edit",object_id=box,kind="delete_replace")
            refreshed=await call("scene_get_context",scope_id=scope)
            assert refreshed["task"]==task
            assert next(c for c in refreshed["scope"]["snapshot"]["objects"] if c["object_id"]==box)["status"]=="missing"
            await denied("scene_measure_objects",dict(scope_id=scope,object_ids=[box]),"UNKNOWN_REFERENCE")
            assert q.local("scene_over_budget")["scope_retained"]
            ui=q.local("scene_ui")
            assert next(row for row in ui["rows"] if row["object_id"]==box)["status"]=="missing"
            evidence["cases"].append(dict(scenario="rename_geometry_units_delete_replacement_and_admission",passed=True,old_source=old_source,new_source=new_source,centimetres=cm,context=refreshed,ui=ui))
            disconnected=q.local("scene_disconnect")
            assert disconnected==dict(scope=None,task=None,retained_references=0,details_enabled=False,dialog_enabled=False)
            evidence["disconnect"]=disconnected
            evidence["status"]="passed";save()
            print(json.dumps({"passed":True,"receipt":str(receipt),"tools":14,"cases":len(evidence["cases"])}),flush=True)
    except BaseException as exc:
        evidence.update(status="failed",error=str(exc));save();raise
