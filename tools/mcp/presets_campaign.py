"""Native settings-preset discovery through the real SDK and owned Max 2027 UI."""
import argparse
import asyncio
import hashlib
import json
from pathlib import Path
import re
import shutil
import sys
import time
from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import ROOT,HERE,qualification,resume,verify_owned,close_owned,run_case
from recipe_catalog_campaign import launch as launch_native
from compatibility_host import bind_suite


def documents():
    source=(ROOT/"AminScatter/src/presets.cpp").read_text()
    defaults=json.loads((ROOT/"AminScatter/tests/data/recipe_v4_defaults.json").read_text())
    result={}
    for category in ("population","transforms","spacing"):
        block=re.search(r"static const std::vector<Field> "+category+r"=\{(.*?)\};",source,re.S).group(1)
        fields=re.findall(r'\{"([^\"]+)",K::(\w+),([^,}]+),([^,}]+)(?:,true)?\}',block)
        values={}
        for name,kind,low,high in fields:
            value=defaults.get(name,True if kind=="boolean" else max(0,float(low)))
            if kind=="boolean":value=bool(value)
            elif kind=="integer":value=int(value)
            else:value=float(value)
            values[name]=value
        if category=="spacing":values.update(enabled=True,multiplier=1.25,gap=.15,planar=True)
        result[category]=dict(format="cyrus.settings-preset",version=3,category=category,name="Owned "+category,values=values)
    for category,domain,samples in (("density_curve","unit",[0,.2,1]),("scale_curve","multiplier",[.5,1,2])):
        result[category]=dict(format="cyrus.settings-preset",version=3,category=category,name="Owned "+category,
                             values=dict(domain=domain,samples=samples,graph=[]))
    old=json.loads(json.dumps(result["transforms"]));old.update(version=1,name="Old transform")
    for key in ("orientationMode","orientationBlend","orientationX","orientationY","orientationZ"):old["values"].pop(key)
    result["old_transform"]=old
    return result


def launch(base,old=False):
    from package import stage_payload,stage_package_payload
    if old:
        packages=ROOT/"dist/CyrusScatter-0.86.9.2-20261023"
        stage_package_payload(base/"payload",2027,packages/"CyrusScatter-0.86.9.2-Max2027.mzp",packages/"CyrusSurfaceAnalyzer-0.14.2-Max2027.mzp",historical=True)
    else:stage_payload(base/"payload",2027,ROOT/"build/mcp-preset-catalog-20261024-01",ROOT/"build/ui-edit-08691-20261023/analyzer-2027-02")
    seed=base/"preset-seed";seed.mkdir(parents=True)
    for key,document in documents().items():(seed/(key+".cspreset.json")).write_text(json.dumps(document,indent=2)+"\n",encoding="utf-8")
    (seed/"bad.cspreset.json").write_text("{broken",encoding="utf-8")
    (seed/"oversized.cspreset.json").write_text(" "*65537,encoding="utf-8")
    (seed/"unknown.cspreset.json").write_text('{"format":"unsupported"}',encoding="utf-8")
    shutil.copytree(seed,base/"preset-small")
    large=base/"preset-large";large.mkdir()
    document=documents()["spacing"]
    for index in range(520):
        value={**document,"name":"Preset "+str(index).zfill(4)}
        (large/(str(index)+".cspreset.json")).write_text(json.dumps(value),encoding="utf-8")
    (base/"preset-linked").symlink_to(base/"preset-small",target_is_directory=True)
    launch_native(base)


async def run(base,old=False):
    q=qualification(base)
    bindings={"settings-preset-driver":Path(__file__),"settings-preset-clean":HERE/"scene_passive.ms"}
    bindings.update({"settings-preset-seed-"+str(i):p for i,p in enumerate((base/"preset-seed").glob("*"))})
    meta=bind_suite(q.folder,bindings);receipt=q.folder/("presets-old.json" if old else "presets-workflow.json")
    assert not receipt.exists(),"Observe original requests/receipts before rerunning this campaign"
    result=dict(status="running",pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"],cases=[],
        qualification="Real external SDK / owned Max 2027; scripted local sharing widgets/pickers, not physical artist interaction or preset application")
    def save():receipt.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    save();q.local("setup");q.local("scene_fixture")
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    try:
        async with Client(params) as client:
            assert len((await client.list_tools()).tools)==22
            async def call(name,expected=None,**args):
                verify_owned(q.folder);response=await client.call_tool(name,args);verify_owned(q.folder)
                value=response.structured_content
                if expected:assert response.is_error and value["error"]["code"]==expected,value
                else:assert not response.is_error,value
                return value
            async def ready():
                deadline=time.monotonic()+60
                while True:
                    connection=await call("connection_get_status")
                    if connection["preset_catalog"]["status"]!="scanning":break
                    assert time.monotonic()<deadline,"Observe original native preset reader; do not restart";await asyncio.sleep(.3)
                assert connection["preset_catalog"]["status"]=="ready",connection
                return dict(scope_id=connection["scope_id"],library_id=connection["preset_catalog"]["library_id"])
            connection=await call("connection_get_status")
            if old:
                before=q.local("scene_state");ui=q.local("preset_unsupported",root=str(base/"does-not-exist"));after=q.local("scene_state")
                assert before==after and not ui["native_reader"] and not ui["catalog"]["shared"] and connection["host"]["preset_catalog_api"] is None
                await call("presets_search",expected="APPROVAL_REQUIRED",scope_id=connection["scope_id"],library_id="not_shared")
                result["cases"].append(dict(case="old_native_denied_before_filesystem",ui=ui,scene_preserved=True))
            else:
                await call("presets_search",expected="APPROVAL_REQUIRED",scope_id=connection["scope_id"],library_id="not_shared")
                q.local("recipe_gallery_start",root=str(base/"data/small"));q.local("recipe_share",root=str(base/"data/small"))
                deadline=time.monotonic()+60
                while True:
                    gallery=q.local("recipe_gallery_snapshot");c=await call("connection_get_status")
                    if gallery["state"]=="complete" and c["recipe_catalog"]["status"]=="ready":break
                    assert time.monotonic()<deadline;await asyncio.sleep(.3)
                run_case(q.folder,HERE/"scene_passive.ms","clean",["clean_before_reads"],entrypoint="MCPScenePassiveRun",timeout=30)
                before=q.local("scene_state");q.local("preset_share",root=str(base/"preset-small"));args=await ready()
                page=await call("presets_search",**args)
                assert page["entry_count"]==6 and page["invalid"]==3 and not page["limited"],page
                inspected=[]
                for entry in page["entries"]:
                    value=await call("presets_inspect_entry",**args,preset_ref=entry["preset_ref"])
                    assert value["document"]["version"]==3 and not value["evidence"]["ready_for_application"]
                    assert "F:" not in json.dumps(value) and "C:" not in json.dumps(value)
                    if entry["category"]=="spacing":assert value["document"]["values"]["gap"]==.15
                    inspected.append(value)
                assert q.local("scene_state")==before and q.local("recipe_gallery_snapshot")==gallery
                result["cases"].append(dict(case="all_categories_native_typed_inspection",catalog=page,inspected=inspected,scene_clean=True,gallery_and_recipe_reader_preserved=True));save()
                # Native inspection stays immutable when an unbound working file changes.
                (base/"preset-small/spacing.cspreset.json").write_text("changed",encoding="utf-8")
                spacing=next(item for item in page["entries"] if item["category"]=="spacing")
                frozen=await call("presets_inspect_entry",**args,preset_ref=spacing["preset_ref"])
                assert frozen["document"]["values"]["gap"]==.15
                q.local("preset_share",root=str(base/"preset-small"));fresh=await ready()
                assert fresh["library_id"]!=args["library_id"]
                await call("presets_search",expected="STALE_CONTEXT",**args)
                refreshed=await call("presets_search",**fresh);assert refreshed["entry_count"]==5 and refreshed["invalid"]==4
                q.local("preset_revoke");await call("presets_search",expected="APPROVAL_REQUIRED",**fresh)
                result["cases"].append(dict(case="frozen_changed_file_refresh_and_revoke",refreshed=refreshed));save()
                denied=q.local("preset_denied",root=str(base/"preset-linked"));assert denied["code"]=="CATALOG_UNAVAILABLE" and not denied["catalog"]["shared"]
                result["cases"].append(dict(case="linked_root_denied",denial=denied));save()
                q.local("setup");q.local("scene_fixture");q.local("preset_share",root=str(base/"preset-large"));large=await ready()
                rows=[];offset=0;pages=0
                while offset is not None:
                    page=await call("presets_search",**large,offset=offset);rows+=page["entries"];offset=page["next_offset"];pages+=1
                    assert page["entry_count"]==512 and page["limited"] and len(page["entries"])<=24
                assert len(rows)==512 and len({row["preset_ref"] for row in rows})==512 and pages==22
                result["cases"].append(dict(case="512_entry_catalog_pages",entries=len(rows),pages=pages,limited=True,one_scope=True));save()
                q.local("scene_disconnect");c=await call("connection_get_status");assert not c["preset_catalog"]["shared"] and not q.local("preset_ui")["native_reader"]
                result["cases"].append(dict(case="disconnect_releases_native_reader",status=c["preset_catalog"]));save()
            result["status"]="passed";save()
    except Exception as exc:result.update(status="failed",error=repr(exc));save();raise
    print(json.dumps(dict(status=result["status"],cases=len(result["cases"]),artifact_id=meta["artifact_id"])),flush=True)


async def lifecycle(base):
    q=qualification(base);module=base/"fixtures/presets_lifecycle_host.py";shutil.copy2(HERE/"presets_lifecycle_host.py",module)
    meta=bind_suite(q.folder,{"preset-lifecycle-driver":Path(__file__),"preset-lifecycle-module":module,"preset-lifecycle-script":HERE/"presets_lifecycle.ms"})
    cases=[]
    for case in ("reset","open","close"):
        q.local("setup");q.local("scene_fixture")
        if case=="open":run_case(q.folder,HERE/"scene_passive.ms","clean",["clean_before_reads"],entrypoint="MCPScenePassiveRun",timeout=30)
        q.local("preset_share",root=str(base/"preset-large"),pause=True)
        run_case(q.folder,HERE/"presets_lifecycle.ms",case,["preset_grant_revoked","preset_handle_released","native_handle_rejected","task_refs_released","lifecycle_boundary"],entrypoint="MCPPresetsLifecycleRun",timeout=30)
        value=json.loads((q.folder/("presets-lifecycle-"+case+".json")).read_text());assert value["status"]=="passed";cases.append(value)
    result=dict(status="passed",cases=cases,pid=meta["pid"],artifact_id=meta["artifact_id"],run_id=meta["run_id"])
    (q.folder/"presets-lifecycle.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(dict(status="passed",cases=len(cases),artifact_id=meta["artifact_id"])),flush=True)


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__);p.add_argument("action",choices=("launch","resume","exercise","lifecycle","close"));p.add_argument("--base",type=Path,required=True);p.add_argument("--old-pair",action="store_true")
    a=p.parse_args();base=a.base.resolve()
    if a.action=="launch":launch(base,a.old_pair)
    elif a.action=="resume":resume(base)
    elif a.action=="exercise":asyncio.run(run(base,a.old_pair))
    elif a.action=="lifecycle":asyncio.run(lifecycle(base))
    else:close_owned(base/"host01")
