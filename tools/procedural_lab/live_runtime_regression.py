"""Run existing real-host assertions on one explicitly launched private host.

Does not launch Max, install software or address an artist process. Generated
fixtures only broaden their historical *test directory* prefix to the verified
current private directory. Their product assertions remain unchanged.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import time

from runtime_driver import ROOT, run_script


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder",type=Path)
    parser.add_argument("--navigation",action="store_true")
    args=parser.parse_args()
    folder=args.folder.resolve()
    if folder.parent!=ROOT/"build/mcp-qualification":
        raise ValueError("Private fixture root required")
    metadata=json.loads((folder/"launch.json").read_text())
    if Path(metadata["output"]).resolve()!=folder or not metadata["development_transport"]:
        raise ValueError("Not a development fixture host")
    stages=[]
    def execute(label,code,source=None):
        start=time.monotonic()
        result=run_script(folder,code,timeout=300)
        row={"stage":label,"seconds":time.monotonic()-start,"result":result,
             "fixture_sha256":hashlib.sha256(code.encode()).hexdigest()}
        if source:row["source"]=source
        stages.append(row)
        (folder/"live-regression-stages.json").write_text(json.dumps(stages,indent=2)+"\n")
        print(label+": "+result.strip(),flush=True)
        if not result.startswith("SUCCESS "):raise RuntimeError(result)
    def fixture(name):
        text=(ROOT/"tools/procedural_lab"/name).read_text(encoding="utf-8-sig")
        # One pass: the new folder may itself contain the historical prefix.
        return re.sub(r"/procedural07-ui-(?:071-)?",lambda _:"/"+folder.name,text)
    execute("identity",'CSPWriteText (MCPFixtureDir+"live-loaded-script.txt") CyrusLoadedScriptFingerprint')
    execute("definitions",fixture("Max_Procedural_07_Acceptance.ms"))
    execute("procedural core","P07Acceptance()")
    for name in ("Max_Procedural_07_Bindings.ms","Max_Layer_Editor_071_Acceptance.ms",
                 "Max_Layer_Editor_071_BrushLive.ms","Max_Procedural_07_Regression.ms",
                 "Max_Source_Containers_Acceptance.ms","Max_Source_Containers_EdgeCases.ms",
                 "Max_Source_Containers_Output.ms"):
        execute(name,fixture(name),name)
    execute("event definitions",fixture("Max_Source_Containers_Events.ms"))
    execute("event setup","SCEventSetup()")
    for name in ("SCEventPark","SCEventReturn","SCEventEnroll","SCEventFinish","SCEventGroupFinish",
                 "SCEventContainerReturn","SCEventGeometry","SCEventGeometryFinish"):
        time.sleep(1)
        execute(name,name+"()")
    if args.navigation:
        execute("navigation definitions",fixture("Max_Procedural_07_Navigation.ms"))
        execute("retained navigation 100k",'P07Navigation "live-runtime-100k" 100000 procedural:true frames:30 modes:#(0,1,3,4) containers:true')
    print("PASS: private runtime regression campaign",flush=True)


if __name__=="__main__":main()
