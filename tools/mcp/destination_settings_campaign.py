"""Actual scoped settings readback, passive pending state and unavailable tracks."""
import argparse
import asyncio
import json
from pathlib import Path
import shutil
import sys
import time
import uuid
from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import ROOT,HERE,qualification,resume,verify_owned,close_owned,run_case
from recipe_catalog_campaign import launch as launch_native
from compatibility_host import bind_suite


def launch(base):
    from package import stage_payload
    stage_payload(base/"payload",2027,ROOT/"build/mcp-destination-units-20261024-01",ROOT/"build/ui-edit-08691-20261023/analyzer-2027-02")
    launch_native(base)


async def run(base):
    q=qualification(base);module=base/"fixtures/destination_settings_host.py";shutil.copy2(HERE/"destination_settings_host.py",module)
    meta=bind_suite(q.folder,{"destination-driver":Path(__file__),"destination-module":module,"destination-clean":HERE/"scene_passive.ms"})
    path=q.folder/"destination-settings.json";assert not path.exists(),"Observe original requests/receipts before rerunning"
    result=dict(status="running",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],cases=[],
        qualification="Real external SDK / owned Max 2027; scripted local enrollment/approval and owned parameter/controller probes. Not preset application or physical artist interaction.")
    def save():path.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    save();q.local("setup",kind=1)
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    try:
        async with Client(params) as client:
            assert len((await client.list_tools()).tools)==23
            async def call(name,expected=None,**args):
                verify_owned(q.folder);response=await client.call_tool(name,args);verify_owned(q.folder)
                value=response.structured_content
                if expected:assert response.is_error and value["error"]["code"]==expected,value
                else:assert not response.is_error,value
                return value
            connection=await call("connection_get_status");epoch=connection["scene_epoch"]
            ctx=await call("scene_get_context",scope_id=connection["scope_id"])
            plan=q.plan(ctx,count=100,layers=2);plan["name"]="Owned destination inspection"
            value=await call("scatter_validate_plan",plan=plan);q.local("approve",validation_id=value["validation_id"])
            args={key:value[key] for key in ("validation_id","digest","scene_epoch","scene_revision")};args["idempotency_key"]="destination_create_"+uuid.uuid4().hex
            queued=await call("scatter_apply_plan",**args);deadline=time.monotonic()+60
            while True:
                operation=(await call("scatter_get_status",scene_epoch=epoch,operation_id=queued["operation"]["operation_id"]))["operation"]
                if operation["state"] not in ("queued","running"):break
                assert time.monotonic()<deadline,"Observe original owned creation";await asyncio.sleep(.3)
            assert operation["state"]=="succeeded",operation
            cid=operation["result"]["controller_id"];lid=operation["result"]["layers"][0]["layer_id"]
            result["creation"]=operation;save()
            q.local("destination_step_pending",controller_id=cid)
            run_case(q.folder,HERE/"scene_passive.ms","clean",["clean_before_reads"],entrypoint="MCPScenePassiveRun",timeout=30)
            q.local("destination_step_guard")
            before=q.local("destination_step_state",controller_id=cid)
            listed=await call("scatter_get_settings",scene_epoch=epoch,controller_id=cid)
            assert listed["settings_targets"]["targets"][0]["layer_id"]==lid
            full=await call("scatter_get_settings",scene_epoch=epoch,controller_id=cid,layer_id=lid)
            settings=full["settings"];assert settings["metres_per_system_unit"]==.01 and settings["pending_by_cached_flag"]
            groups={row["category"]:row for row in settings["categories"]};assert len(groups)==5
            population={row["name"]:row for row in groups["population"]["fields"]}
            transforms={row["name"]:row for row in groups["transforms"]["fields"]}
            assert population["amount"]["value"]==125 and population["randomSeed"]["value"]==305
            assert abs(transforms["movXMinWU"]["value"]+.15)<1e-6 and abs(transforms["movXMaxWU"]["value"]-.35)<1e-6
            assert abs(groups["spacing"]["effective_self_rule"]["gap_m"]-.4)<1e-6
            assert groups["density_curve"]["stored_samples"]==groups["scale_curve"]["stored_samples"]==[]
            assert not groups["density_curve"]["exportable_as_preset"] and not groups["scale_curve"]["exportable_as_preset"]
            assert (await call("scatter_get_settings",scene_epoch=epoch,controller_id=cid,layer_id=lid))["settings"]==settings
            after=q.local("destination_step_state",controller_id=cid);assert before==after and not after["save_required"]
            result["cases"].append(dict(case="five_categories_pending_clean_passive_read",settings=settings,scene_and_publication_unchanged=True,geometry_guard=True));save()
            q.local("destination_step_override",controller_id=cid);before=q.local("destination_step_state",controller_id=cid)
            spacing=(await call("scatter_get_settings",scene_epoch=epoch,controller_id=cid,layer_id=lid,categories=["spacing"]))["settings"]["categories"][0]
            assert abs(spacing["effective_self_rule"]["gap_m"]-.25)<1e-6
            assert abs(next(row["value"] for row in spacing["fields"] if row["name"]=="procLayerSelfGap")-.4)<1e-6
            assert q.local("destination_step_state",controller_id=cid)==before
            result["cases"].append(dict(case="explicit_override_vs_layer_default",settings=spacing));save()
            identical=q.local("destination_step_roundtrip",controller_id=cid,categories=["population","transforms","spacing"])
            result["cases"].append(dict(case="centimetre_native_preset_noop_roundtrip",probe=identical));save()
            q.local("destination_step_curves",controller_id=cid);before=q.local("destination_step_state",controller_id=cid)
            curves=(await call("scatter_get_settings",scene_epoch=epoch,controller_id=cid,layer_id=lid,categories=["density_curve","scale_curve"]))["settings"]["categories"]
            assert all(row["exportable_as_preset"] for row in curves) and curves[0]["stored_samples"]==[0,.25,1] and curves[1]["stored_samples"]==[.5,1,2]
            assert curves[0]["width_m"]==2 and curves[1]["width_m"]==3 and q.local("destination_step_state",controller_id=cid)==before
            result["cases"].append(dict(case="stored_global_curve_read_without_editor",curves=curves));save()
            tracks=q.local("destination_step_tracks",controller_id=cid);assert tracks["animated_keys"]>=2
            before=q.local("destination_step_state",controller_id=cid)
            unavailable=(await call("scatter_get_settings",scene_epoch=epoch,controller_id=cid,layer_id=lid,categories=["transforms"]))["settings"]["categories"][0]
            fields={row["name"]:row for row in unavailable["fields"]}
            assert not fields["movXMinWU"]["available"] and fields["movXMinWU"]["value"] is None
            assert not fields["movXMaxWU"]["available"] and fields["movXMaxWU"]["key_count"]>=2 and not unavailable["exportable_as_preset"]
            assert q.local("destination_step_state",controller_id=cid)==before
            result["cases"].append(dict(case="unsupported_and_animated_tracks_not_sampled",settings=unavailable,track_probe=tracks));save()
            await call("scatter_get_settings",expected="STALE_CONTEXT",scene_epoch=epoch,controller_id=cid,layer_id="missing_layer",categories=["population"])
            q.local("destination_step_restore",keep_skip=True)
            observed=q.local("destination_step_observe",controller_id=cid);epoch=observed["scene_epoch"]
            # Connection returns the scope, while the local observe snapshot owns
            # its new controller ID. Read context is intentionally avoided here.
            # The public context would fingerprint all input settings. This probe
            # obtains the explicitly enrolled ID from a local fixture action below.
            observed_id=q.local("destination_step_observed_id")["controller_id"]
            q.local("destination_step_guard")
            targets=await call("scatter_get_settings",scene_epoch=epoch,controller_id=observed_id)
            assert targets["settings_targets"]["targets"][0]["layer_id"]==lid
            readonly=await call("scatter_get_settings",scene_epoch=epoch,controller_id=observed_id,layer_id=lid,categories=["spacing"])
            assert readonly["settings"]["layer_id"]==lid
            result["cases"].append(dict(case="explicit_inspection_scope_read_only",scope_kind=observed["scope_kind"],settings=readonly));save()
            q.local("destination_step_duplicate",controller_id=observed_id)
            await call("scatter_get_settings",expected="STALE_CONTEXT",scene_epoch=epoch,controller_id=observed_id)
            await call("scatter_get_settings",expected="STALE_CONTEXT",scene_epoch=epoch,controller_id=observed_id,layer_id=lid,categories=["population"])
            q.local("destination_step_restore")
            result["cases"].append(dict(case="duplicate_layer_identity_denied",status="passed"));save()
        result["status"]="passed";save()
    except Exception as exc:result.update(status="failed",error=repr(exc));save();raise
    print(json.dumps(dict(status="passed",cases=len(result["cases"]),artifact_id=meta["artifact_id"])),flush=True)


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("action",choices=("launch","resume","exercise","close"));p.add_argument("--base",type=Path,required=True)
    a=p.parse_args();base=a.base.resolve()
    if a.action=="launch":launch(base)
    elif a.action=="resume":resume(base)
    elif a.action=="exercise":asyncio.run(run(base))
    else:close_owned(base/"host01")
