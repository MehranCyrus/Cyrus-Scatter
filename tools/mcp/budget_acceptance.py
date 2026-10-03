"""Generation near both the instance and geometry budgets."""
import argparse
import json
from pathlib import Path
from qualify import Qualification


def run(folder):
    q=Qualification(folder);q.local("setup")
    geometry=q.local("boundary",kind="complexity",x=50,y=90)
    assert geometry["enrolled"]
    operation=q.apply(q.plan(q.context(),count=2000))
    assert operation["state"]=="succeeded" and operation["result"]["emitted"]==2000,operation
    evidence={"source_triangles":9000,"requested":2000,"result":operation["result"],"publication_ms":operation["duration_ms"],"idempotent_retry":True}
    q.local("undo")
    assert q.local("snapshot")["nodes"]==4
    evidence["undo_restored"]=True
    (q.folder/"budget-generation.json").write_text(json.dumps(evidence,indent=2))
    print(json.dumps(evidence,indent=2))


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("folder",type=Path)
    run(parser.parse_args().folder)
