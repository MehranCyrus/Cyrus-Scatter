"""Collect an explicit allowlist of runtime receipts; never copy IPC credentials."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT=Path(__file__).resolve().parents[2]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def collect(candidate="final03"):
    campaign=ROOT/"build/live-runtime-20261006"
    private=ROOT/"build/mcp-qualification"/("procedural07-ui-071-live-runtime-"+candidate)
    output=ROOT/"docs/Live_Runtime_2026-10-06/evidence"
    output.mkdir(exist_ok=True)
    def copy(source,name=None):
        target=output/(name or source.name)
        shutil.copy2(source,target)
    names=("launch.json","live-regression-stages.json","live-runtime-100k-navigation.json",
           "procedural-acceptance.json","review-regressions.json","source-containers.json",
           "source-container-edge-cases.json","source-container-events.json","source-container-output.json",
           "layer-editor-071-brush-live.json","idle-qualification.json","diagnostic-overhead.json",
           "panel-runtime-result.json","panel-diagnostics.json","courtyard-runtime.json",
           "courtyard-ir-stats.json","courtyard-production.json","courtyard-ir-trace.json",
           "docked-unavailable.json","relink.json","transport-paused-verified.json",
           "transport-paused-start.json","transport-paused-end.json","visual-ui-review.json","pointer-ui-end.json",
           "private-host-shutdown.json")
    for name in names:copy(private/name)
    # These are intentionally separate from final receipts, including a failed
    # intermediate build that revealed the Manual pending redraw loop.
    for name in ("idle-closed-start.json","idle-closed-end.json","idle-open-start.json","idle-open-end.json",
                 "courtyard-idle-start.json","courtyard-idle-end.json","courtyard-ir-stats.json"):
        copy(campaign/"baseline"/name,"baseline-"+name)
    for name in ("manual-close-loop.json","manual-close-loop-end.json","manual-loop-events.json"):
        copy(ROOT/"build/mcp-qualification/procedural07-ui-071-live-runtime-final01"/name,"intermediate-"+name)
    copy(ROOT/"build/mcp-qualification/procedural07-ui-071-live-runtime-final02/failed-resume-resources-before-fix.json")
    for name in ("Courtyard_IR.png","Courtyard_Production.png","editor-resized-scrolled.png"):
        copy(private/name)
    for year in (2026,2027):
        copy(ROOT/f"build/offline-implementation-20261005/max{year}/Testing/Temporary/LastTest.log",f"native-{year}-tests.log")
    copy(campaign/candidate/"python-tests.xml")
    copy(ROOT/"build/procedural-07/generated-check.json")
    before=json.loads((campaign/"before.json").read_text())
    changed=[];protected=[]
    for name,info in before["files"].items():
        p=ROOT/name
        current=digest(p) if p.exists() else None
        if current!=info["sha256"]:changed.append(dict(path=name,before=info["sha256"],after=current))
        if name.startswith(("CyrusLicensing/","tools/licensing_lab/","docs/licensing/","Test Scene/")):
            assert current==info["sha256"],"Protected file changed: "+name
            protected.append(name)
    paths=subprocess.check_output(["git","ls-files","--cached","--others","--exclude-standard","-z"],cwd=ROOT).decode().split("\0")
    paths=[p for p in paths if p]
    new=sorted(set(paths)-set(before["files"]))
    identities={}
    for name in paths:
        if name.startswith(("AminScatter/","CyrusMCP/","tools/procedural_lab/")):
            p=ROOT/name
            if p.is_file():identities[name]=digest(p)
    launch=json.loads((private/"launch.json").read_text())
    assert launch["script_sha256"]==digest(ROOT/"AminScatter/scripts/AminScatterObject.ms")==digest(private/"scripts/CyrusScatter.ms")
    native=json.loads((ROOT/"build/offline-implementation-20261005/max2027/receipt.json").read_text())
    for name,expected in native["sources"].items():
        if name.endswith((".cpp",".h",".inc")) or name=="AminScatter/CMakeLists.txt":assert digest(ROOT/name)==expected,name
    for name,expected in launch["binaries"].items():assert digest(private/"bin"/name)==expected,name
    for p in (campaign/candidate/"CyrusMCP/cyrus_mcp").rglob("*"):
        if p.is_file() and p.suffix in (".py",".json"):
            assert digest(p)==digest(ROOT/"CyrusMCP/cyrus_mcp"/p.relative_to(campaign/candidate/"CyrusMCP/cyrus_mcp")),p
    scope={"head_at_start":before["head"],"head_now":subprocess.check_output(["git","rev-parse","HEAD"],cwd=ROOT,text=True).strip(),
           "branch":subprocess.check_output(["git","branch","--show-current"],cwd=ROOT,text=True).strip(),
           "status_at_start":before["status"],"status_now":subprocess.check_output(["git","status","--short"],cwd=ROOT,text=True),
           "changed_during_campaign":changed,"new_during_campaign":new,"protected_originals_unchanged":protected,
           "source_fingerprints":identities,"script_and_native_identity_checked":True,
           "private_python_matches_workspace":True,"installed":False,"packaged":False,"committed":False,"pushed":False}
    assert scope["head_at_start"]==scope["head_now"],"Unexpected commit during the campaign"
    (output/"scope-and-identities.json").write_text(json.dumps(scope,indent=2)+"\n")
    index={p.name:{"bytes":p.stat().st_size,"sha256":digest(p)} for p in output.iterdir() if p.is_file() and p.name!="index.json"}
    (output/"index.json").write_text(json.dumps(index,indent=2)+"\n")
    print(json.dumps(dict(receipts=len(index),changed=len(changed),new=len(new),protected_unchanged=len(protected),script=launch["script_sha256"])))


if __name__=="__main__":collect()
