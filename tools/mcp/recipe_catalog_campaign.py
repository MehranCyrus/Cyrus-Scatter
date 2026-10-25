"""Isolated native catalog API on a matched internal Max 2027 prototype.

Payload is staged from completed native receipts, never overlaid on an old pair.
This campaign does not qualify model-callable recipe tools or a release package.
"""
import argparse
import asyncio
import json
from pathlib import Path
import shutil
import sys
import time

from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import ROOT, HERE, resume, qualification, verify_owned, launch_owned, close_owned, run_case


def launch(base):
    if not base.is_relative_to(ROOT/"build"):raise ValueError("Owned build output required")
    if (base/"host01").exists():raise FileExistsError("Observe the existing host; do not relaunch")
    defaults=json.loads((ROOT/"AminScatter/tests/data/recipe_v1_defaults.json").read_text())
    layer=dict(id="grass",name="Grass",enabled=True,visible=True,settings=defaults,paint=None,areas=[])
    document=dict(format="cyrus.planting-recipe",formatVersion=1,evaluationContract="CyrusUnified1",sceneSchema=58,
                  hostYear=2027,id="catalog-fixture",name="Meadow",unitsPerMetre=100,exportScope="complete-setup",
                  rootSettings=defaults,roles=[],layers=[layer],spacingRelationships=[])
    data=base/"data";large=data/"large";small=data/"small"
    large.mkdir(parents=True);small.mkdir()
    for i in range(301):
        copy=dict(document,id="meadow_"+str(i),name="Meadow "+str(i))
        (large/(str(i)+".csrecipe.json")).write_text(json.dumps(copy),encoding="utf-8")
    (small/"one.csrecipe.json").write_text(json.dumps(document),encoding="utf-8")
    (small/"broken.csrecipe.json").write_text("{",encoding="utf-8")
    (data/"linked").symlink_to(small,target_is_directory=True)
    roots={"large":str(large),"small":str(small),"linked":str(data/"linked"),"absent":str(data/"absent")}
    (base/"roots.json").write_text(json.dumps(roots,indent=2)+"\n",encoding="utf-8")
    source=base/"source";fixtures=base/"fixtures";fixtures.mkdir()
    shutil.copytree(ROOT/"CyrusMCP/cyrus_mcp",source/"cyrus_mcp",ignore=shutil.ignore_patterns("__pycache__"))
    for name in ("foundation_host.py","host_fixture.py","recipe_catalog_host.py"):shutil.copy2(HERE/name,fixtures/name)
    boot=base/"boot.py";folder=base/"host01"
    boot.write_text("import sys\n"+"sys.path.insert(0,"+repr(str(source))+")\n"+
                    "sys.path.insert(0,"+repr(str(fixtures))+")\n"+
                    "from PySide6.QtCore import QTimer\nimport foundation_host\n"+
                    "QTimer.singleShot(100,lambda:foundation_host.start("+repr(str(folder))+"))\n",encoding="utf-8")
    bindings={"prototype-driver":Path(__file__),"prototype-roots":base/"roots.json","python-boot":boot,
              "foundation-boot":HERE/"foundation_boot.ms","clean-fixture":HERE/"scene_passive.ms"}
    for path in [*source.rglob("*.py"),*source.rglob("*.json"),*fixtures.glob("*.py"),*data.rglob("*.json")]:
        bindings["prototype-"+path.relative_to(base).as_posix().replace("/","_")]=path
    launch_owned(folder,2027,base/"payload",bindings=bindings,require_edit_version=True,timeout=60)
    resume(base)


async def exercise(base):
    q=qualification(base)
    q.local("setup");q.local("scene_fixture")
    run_case(q.folder,HERE/"scene_passive.ms","clean",["clean_before_reads"],timeout=30,entrypoint="MCPScenePassiveRun")
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    meta=verify_owned(q.folder);observations=[]
    async with Client(params) as client:
        tools=await client.list_tools();assert len(tools.tools)==18
        q.local("recipe_catalog_native",roots=json.loads((base/"roots.json").read_text()))
        deadline=time.monotonic()+60
        while True:
            verify_owned(q.folder)
            response=await client.call_tool("connection_get_status",{})
            verify_owned(q.folder)
            assert not response.is_error,response
            connection=response.structured_content
            for module in connection["host"]["loaded_modules"]:
                assert module["loaded"] and module["loaded_file_sha256"]==meta["hashes"][module["module"]],module
            observations.append(connection)
            result=json.loads((q.folder/"recipe-native-result.json").read_text())
            if result["status"]!="running":break
            assert time.monotonic()<deadline,"Observe the same owned process/request; do not restart"
            await asyncio.sleep(.5)
        assert result["status"]=="passed",result
    evidence={"status":"passed","pid":meta["pid"],"artifact_id":meta["artifact_id"],"run_id":meta["run_id"],
              "scope":"Isolated native reader API / source SDK connection responsiveness only; no remote recipe discovery/import or physical artist consent.",
              "native_result":result,"sdk_connection_observations":observations,"tool_count":16}
    (q.folder/"recipe-native-campaign.json").write_text(json.dumps(evidence,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"status":"passed","pid":meta["pid"],"artifact_id":meta["artifact_id"],"cases":len(result["cases"])}),flush=True)


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("action",choices=("launch","resume","exercise","close"))
    parser.add_argument("--base",type=Path,required=True);args=parser.parse_args();base=args.base.resolve()
    if args.action=="launch":launch(base)
    elif args.action=="resume":resume(base)
    elif args.action=="exercise":asyncio.run(exercise(base))
    else:close_owned(base/"host01")
