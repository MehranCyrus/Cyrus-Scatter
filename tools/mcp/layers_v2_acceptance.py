"""Real-host schema-2 settings/geometry/receipt checks through authenticated IPC."""
import argparse
import json
from pathlib import Path
from cyrus_mcp.contracts import digest
from qualify import Qualification


def run(folder):
    q=Qualification(folder);evidence=[]
    for mode in ("point_cloud","proxy","mesh","centres"):
        q.local("setup")
        protected=q.local("boundary",kind="protected_region")
        assert protected["enrolled"],protected
        context=q.context();plan=q.plan(context,count=180,layers=2)
        plan["schema_version"]="2.0"
        plan["display"]={"mode":mode,"points_per_plant":30,"instances_per_population":120,"update_mode":"real_time" if mode=="mesh" else "manual"}
        plan["pair_rules"]=[{"a":0,"b":1,"gap_m":1.2,"footprints":True,"planar":True}]
        for i,layer in enumerate(plan["layers"]):
            layer["settings"]={"priority":10-i,"collision_enabled":True,"collision_radius_m":.3,
                               "scale_x":[.8,1.2],"scale_y":[.9,1.1],"scale_z":[.7,1.3],
                               "rotation_x_degrees":[-5,5],"rotation_y_degrees":[-3,3],
                               "movement_x_m":[-.1,.1],"movement_y_m":[-.1,.1]}
            layer["sources"][0]["settings"]={"scale":.8,"z_offset_m":.02,"collision_radius_m":.2,"radius_follows_scale":True}
        operation=q.apply(plan)
        assert operation["state"]=="succeeded",operation
        receipt=operation["result"]
        assert receipt["group_policy"]==2 and receipt["plan_schema"]=="2.0" and receipt["display_mode"]==mode
        before=q.local("snapshot")
        config=q.call("scatter.get_configuration",scene_epoch=operation["scene_epoch"],controller_id=receipt["controller_id"])["configuration"]
        record=q.call("scatter.export_record",scene_epoch=operation["scene_epoch"],controller_id=receipt["controller_id"],generation_id=receipt["generation_id"])["record"]
        after=q.local("snapshot")
        assert before==after,"Configuration/export mutated the scene"
        assert config["display"]["mode"]==mode
        assert abs(config["layers"][0]["settings"]["collision_radius_m"]-.3)<1e-6
        assert abs(config["layers"][0]["assets"][0]["settings"]["z_offset_m"]-.02)<1e-6
        assert config["layers"][0]["assets"][0]["weight"]==plan["layers"][0]["sources"][0]["weight"]
        for a,b in zip(config["layers"][0]["base_variation"]["whole_scale"],plan["layers"][0]["scale"]):assert abs(a-b)<1e-6
        assert config["layers"][0]["base_variation"]["rotation_z_degrees"]==plan["layers"][0]["yaw_degrees"]
        assert record["provenance"]["training_eligible"] is False
        rows=record["layout"]["instances"]
        assert len(rows)==receipt["emitted"]>0
        assert digest([[r["transform"],r["source_index"]] for r in rows])==receipt["transform_digest"]
        assert len({r["instance_id"] for r in rows})==len(rows)
        groups={m["layer_id"]:[] for m in receipt["layers"]}
        for row in rows:
            p=[row["transform"][0][3],row["transform"][1][3]]
            assert not (-1<=p[0]<=1 and -1<=p[1]<=1),"Excluded building was planted"
            groups[row["layer_id"]].append(p)
        a,b=groups.values()
        for x in a:
            for y in b:assert sum((p-q)**2 for p,q in zip(x,y))>=1.19999**2,"Pair gap was not applied after attachment"
        evidence.append({"mode":mode,"emitted":receipt["emitted"],"post_attachment_digest":True,"exclusion":True,"shared_pair_gap":True,"read_only_export":True,"training_eligible":False})
        # Two approved publications per scope; exercise disabled/hidden settings.
        context=q.context();refined=q.plan(context,count=180,layers=2)
        refined.update(schema_version="2.0",controller_id=receipt["controller_id"],generation_id=receipt["generation_id"])
        refined["layers"][0]["settings"]={"visible":False}
        refined["layers"][1]["settings"]={"enabled":False}
        refined["layers"][1]["underfill"]="reject"
        result=q.apply(refined)
        assert result["state"]=="succeeded",result
        assert result["result"]["layers"][0]["emitted"]>0 and result["result"]["layers"][0]["displayed_samples"]==0
        assert result["result"]["layers"][1]["emitted"]==0
        q.local("undo")
    (q.folder/"layers-v2.json").write_text(json.dumps(evidence,indent=2))
    print(json.dumps(evidence,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("folder",type=Path)
    run(parser.parse_args().folder)
