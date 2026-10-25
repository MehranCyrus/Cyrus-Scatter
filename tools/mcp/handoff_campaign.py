"""Real task-to-design workflow: explicit grant, whole-site/regions and retained intent."""
import asyncio
import json
from pathlib import Path
import sys
import uuid

from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import qualification, verify_owned, run_case
from compatibility_host import bind_suite


async def run(base):
    q=qualification(base)
    here=Path(__file__).resolve().parent
    meta=bind_suite(q.folder,{"handoff-driver":Path(__file__),"handoff-clean-fixture":here/"scene_passive.ms"})
    receipt=q.folder/("handoff-"+uuid.uuid4().hex+".json")
    evidence={"status":"running","pid":meta["pid"],"artifact_id":meta["artifact_id"],"run_id":meta["run_id"],"cases":[],
              "qualification":"Owned Max 2027 and real SDK; local grant/proposal dialogs scripted, not artist consent."}
    def save():receipt.write_text(json.dumps(evidence,indent=2)+"\n",encoding="utf-8")
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    try:
        async with Client(params) as client:
            async def call(name,**args):
                verify_owned(q.folder)
                response=await client.call_tool(name,args)
                verify_owned(q.folder)
                assert not response.is_error,response
                return response.structured_content
            async def context():
                connection=await call("connection_get_status")
                return await call("scene_get_context",scope_id=connection["scope_id"])
            async def execute(plan):
                value=await call("scatter_validate_plan",plan=plan)
                q.local("approve",validation_id=value["validation_id"])
                args={key:value[key] for key in ("validation_id","digest","scene_epoch","scene_revision")}
                args["idempotency_key"]="handoff_"+uuid.uuid4().hex
                queued=await call("scatter_apply_plan",**args)
                import time
                deadline=time.monotonic()+45
                while True:
                    op=(await call("scatter_get_status",scene_epoch=value["scene_epoch"],operation_id=queued["operation"]["operation_id"]))["operation"]
                    if op["state"] not in ("queued","running"):break
                    if time.monotonic()>deadline:raise TimeoutError("Observe original operation "+op["operation_id"])
                    await asyncio.sleep(.2)
                assert (await call("scatter_apply_plan",**args))["operation"]==op
                assert op["state"]=="succeeded",op
                return op
            for policy in ("whole_site","explicit_regions"):
                q.local("setup");q.local("scene_fixture")
                first=await context()
                task_id=first["task"]["task_id"]
                cards=first["scope"]["snapshot"]["objects"]
                receiver=next(c["object_id"] for c in cards if c["object_type"]=="Plane")
                source=next(c["object_id"] for c in cards if c["object_type"]=="Cone")
                boundary=next(c["object_id"] for c in cards if c["object_type"]=="SplineShape")
                q.local("scene_role",role="receiver",object_ids=[receiver])
                q.local("scene_role",role="source",object_ids=[source])
                q.local("scene_role",role="preserve",object_ids=[source])
                q.local("scene_brief",brief="Plant this area; preserve the existing context")
                before_extension=await context()
                extended=q.local("task_extend_fixture")
                after_extension=await context()
                assert after_extension["task"]["task_id"]==task_id and after_extension["task"]["roles"]==before_extension["task"]["roles"]
                assert after_extension["task"]["brief"]==before_extension["task"]["brief"]
                assert set(c["object_id"] for c in cards)<=set(c["object_id"] for c in after_extension["scope"]["snapshot"]["objects"])
                assert after_extension["budget"]["calls_remaining"]<before_extension["budget"]["calls_remaining"]
                exclusion=next(c["object_id"] for c in extended["objects"] if c.get("label")=="Keep entrance clear")
                point=next(c["object_id"] for c in extended["objects"] if c.get("label")=="Unsupported mesh prototype")
                if policy=="explicit_regions":
                    q.local("scene_role",role="boundary",object_ids=[boundary])
                    q.local("scene_role",role="exclusion",object_ids=[exclusion])
                q.local("scene_role",role="source",object_ids=[point])
                rejected=q.local("task_connect_expected_failure")
                assert rejected["code"]=="UNSUPPORTED_CAPABILITY"
                q.local("scene_role",role="source",object_ids=[point],remove=True)
                old_review=q.local("task_prepare_grant")
                q.local("scene_role",role="context",object_ids=[receiver])
                assert q.local("task_connect_expect_stale",review_id=old_review["review_id"],digest=old_review["digest"])["scope_retained"]
                cancelled=q.local("task_grant_dialog",confirm=False)
                assert cancelled["scope_kind"]=="scene_inspection" and cancelled["dialog"]["default"]=="Cancel"
                q.local("task_source_transform")
                measured=await call("scene_measure_objects",scope_id=first["scope"]["scope_id"],object_ids=[receiver,source])
                source_facts=next(item for item in measured["measurements"] if item["object_id"]==source)
                receiver_facts=next(item for item in measured["measurements"] if item["object_id"]==receiver)
                assert abs(source_facts["source_geometry"]["height_m"]-2)<1e-5
                assert abs(source_facts["source_geometry"]["radius_xy_from_pivot_m"]-.4)<1e-5
                assert receiver_facts["receiver_geometry"]["eligible"] and receiver_facts["receiver_geometry"]["area_m2"]==900
                task_before=(await context())["task"]
                run_case(q.folder,here/"scene_passive.ms","clean",["clean_before_reads"],timeout=30,entrypoint="MCPScenePassiveRun")
                native_before=q.local("scene_state")
                assert not native_before["save_required"]
                connected=q.local("task_grant_dialog",confirm=True)
                native_after=q.local("scene_state")
                assert native_after==native_before,"Handoff changed native authored scene"
                assert connected["scope_kind"]=="design"
                design=await context()
                assert design["task"]["task_id"]==task_id and design["task"]["brief"]==task_before["brief"] and design["task"]["roles"]==task_before["roles"]
                assert design["scope"]["scope_id"]!=first["scope"]["scope_id"] and not design["scope"]["allow_capture"]
                assert design["scope"]["sources"][0]["task_object_id"]==source and "settings_contract" not in design
                assert design["settings_contract_resource"]=="cyrus://capabilities"
                assert 'scene_onboarding' in (await client.read_resource("cyrus://capabilities")).contents[0].text
                if policy=="whole_site":assert design["scope"]["regions"][0]["origin"]=="verified_receiver_polygon"
                else:assert design["scope"]["regions"][0]["task_object_id"]==boundary and design["scope"]["excluded"][0]["task_object_id"]==exclusion
                ui=q.local("scene_ui")
                assert ui["enabled"] and not ui["roles_enabled"] and not ui["grant_enabled"] and not ui["share_more_enabled"]
                plan=q.plan(design,count=80,layers=2)
                not_approved=await call("scatter_validate_plan",plan=plan)
                denied=await client.call_tool("scatter_apply_plan",{**{k:not_approved[k] for k in ("validation_id","digest","scene_epoch","scene_revision")},"idempotency_key":"no_grant_approval_"+uuid.uuid4().hex})
                assert denied.is_error and denied.structured_content["error"]["code"]=="APPROVAL_REQUIRED"
                created=await execute(plan)
                cid=created["result"]["controller_id"]
                published=q.local("publication_snapshot",controller_id=cid)
                case=dict(policy=policy,task_id=task_id,measurement=measured,rejected_source=rejected,cancelled=cancelled,
                          native_before=native_before,native_after=native_after,design=design,created=created,published=published)
                evidence["cases"].append(case);save()
                ctx=await context()
                refine=q.plan(ctx,count=100,layers=2)
                refine.update(controller_id=cid,generation_id=created["result"]["generation_id"])
                old=await call("scatter_validate_plan",plan=refine)
                q.local("approve",validation_id=old["validation_id"])
                q.local("scene_brief",brief="Add more flowers; keep the same references")
                assert q.local("publication_snapshot",controller_id=cid)["rows_sha256"]==published["rows_sha256"]
                stale=await client.call_tool("scatter_apply_plan",{**{k:old[k] for k in ("validation_id","digest","scene_epoch","scene_revision")},"idempotency_key":"old_brief_"+uuid.uuid4().hex})
                assert stale.is_error
                current=await context();refine["context_id"]=current["context_id"]
                refined=await execute(refine)
                assert current["task"]["task_id"]==task_id and current["task"]["roles"]==task_before["roles"]
                case.update(refined=refined,brief_after=current["task"]["brief"],passed=True);save()
            evidence["status"]="passed";save()
            print(json.dumps({"passed":True,"receipt":str(receipt),"cases":len(evidence["cases"])}),flush=True)
    except BaseException as exc:
        evidence.update(status="failed",error=str(exc));save();raise


if __name__=="__main__":
    import argparse
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base",type=Path,required=True)
    args=parser.parse_args()
    asyncio.run(run(args.base.resolve()))
