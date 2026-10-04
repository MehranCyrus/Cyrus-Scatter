"""Run the bounded release matrix serially against one private Max host."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import time


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("folder",type=Path)
    args=parser.parse_args()
    folder=args.folder.resolve()
    root=Path(__file__).resolve().parents[2]
    if not folder.is_relative_to(root/"build/mcp-qualification"):
        raise SystemExit("A private qualification folder is required")
    scripts=[("qualify.py",["--cycles","3"]),("layers_v2_acceptance.py",[]),
             ("scenarios.py",[]),("stdio_acceptance.py",[]),("boundary_acceptance.py",[]),
             ("retained_acceptance.py",[]),("inspection_acceptance.py",[]),("budget_acceptance.py",[]),
             ("layers_inspection_acceptance.py",[])]
    results=[]
    for name,extra in scripts:
        started=time.monotonic()
        with (folder/(name+".log")).open("w",encoding="utf-8") as log:
            run=subprocess.run([sys.executable,str(Path(__file__).parent/name),str(folder),*extra],stdout=log,stderr=subprocess.STDOUT)
        record={"script":name,"exit_code":run.returncode,"seconds":round(time.monotonic()-started,3)}
        results.append(record)
        (folder/"release-campaign.json").write_text(json.dumps(results,indent=2))
        print(json.dumps(record),flush=True)
        if run.returncode:raise SystemExit(run.returncode)


if __name__=="__main__":main()
