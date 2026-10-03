"""Prove that retained Mesh/Point Cloud diagnostics remain pure getters."""
import argparse
import json
from pathlib import Path
import time
from qualify import Qualification


def run(folder):
    q=Qualification(folder);q.local("setup")
    result=q.apply(q.plan(q.context(),layers=2));assert result["state"]=="succeeded",result
    evidence=[]
    for mode in (3,1):
        q.local("boundary",kind="display_mode",mode=mode)
        time.sleep(1)
        connection=q.local("boundary",kind="inspect")
        before=q.local("snapshot")
        context=q.context()
        stats=q.call("scatter.get_diagnostics",scene_epoch=connection["scene_epoch"])
        after=q.local("snapshot")
        assert before==after,(before,after)
        assert stats["retained"]["owners"][0]["available"],stats
        assert stats["retained"]["owners"][0]["state"]=="ready",stats
        evidence.append({"mode":mode,"pure_inspection":True,"statistics":stats["retained"]})
    (q.folder/"retained.json").write_text(json.dumps(evidence,indent=2))
    print(json.dumps(evidence,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("folder",type=Path)
    run(parser.parse_args().folder)
