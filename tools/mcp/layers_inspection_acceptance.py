"""Read effective parent settings from an artist-modified multi-set controller."""
import argparse
import json
from pathlib import Path
import time
import uuid
from qualify import Qualification


def run(folder):
    q=Qualification(folder.resolve());q.local("setup")
    plan=q.plan(q.context(),count=100);plan["schema_version"]="2.0"
    assert q.apply(plan)["state"]=="succeeded"
    # Test-only setup travels through the private development transport, never MCP.
    nonce=uuid.uuid4().hex
    script=q.folder/("inspection-"+nonce+".py")
    script.write_text('''from pymxs import runtime as rt
import host_fixture
import cyrus_mcp.max_host as installed_host
import json
panel=host_fixture.PANEL
node=next(iter(panel.host.controllers.values()))
parent=node.layerObjects[0]
child=node.addPaintSet(parent,label="Blue")
child.sources=parent.sources
rt.cyrusBrushFill(child.paintDocument,1.0)
node.updateMode=1
node.refreshAll()
parent.sclXMin=1.5
parent.sclXMax=1.5
(host_fixture.OUTPUT/"logical-inspection-setup.json").write_text(json.dumps({"parent_id":str(parent.layerID),"child_id":str(child.layerID),"stored_child_scale":float(child.sclXMin),"host_module":installed_host.__file__}))
''',encoding="utf-8")
    ms=script.with_suffix(".ms")
    ms.write_text('python.ExecuteFile @"'+script.as_posix()+'"',encoding="utf-8")
    (q.folder/"dev-request.txt").write_text(ms.as_posix())
    deadline=time.monotonic()+30
    while time.monotonic()<deadline:
        result=q.folder/"dev-result.txt"
        if result.exists() and ms.as_posix() in result.read_text():
            assert result.read_text().startswith("SUCCESS"),result.read_text()
            break
        time.sleep(.1)
    else:raise TimeoutError("private multi-set setup")
    setup=json.loads((q.folder/"logical-inspection-setup.json").read_text())
    connection=q.local("boundary",kind="inspect")
    context=q.context();cid=next(iter(context["observed_controllers"]))
    before=q.local("snapshot")
    config=q.call("scatter.get_configuration",scene_epoch=connection["scene_epoch"],controller_id=cid)["configuration"]
    after=q.local("snapshot")
    assert before==after,"Configuration mutated the observed controller"
    assert len(config["layers"])==2
    child=next(row for row in config["layers"] if row["layer_id"]==setup["child_id"])
    assert child["parent_id"]==setup["parent_id"] and child["set_name"]=="Blue"
    assert child["settings"]["scale_x"]==[1.5,1.5],child
    assert child["allocation"]["parent_candidate_budget"]==100 and child["allocation"]["count_mode_candidates"]==50
    evidence={"pure_read":True,"effective_parent_settings":True,"membership_and_shared_budget":True,"setup":setup}
    (q.folder/"logical-inspection.json").write_text(json.dumps(evidence,indent=2))
    print(json.dumps(evidence,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("folder",type=Path)
    run(parser.parse_args().folder)
