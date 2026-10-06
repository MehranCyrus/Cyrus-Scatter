"""Collect current offline receipts; never launches Max or changes a profile."""
from datetime import datetime, timezone
import ast
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/"docs/Offline_Implementation_2026-10-05"
BUILD=ROOT/"build/offline-implementation-20261005"


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path,data):path.write_text(json.dumps(data,indent=2)+"\n",encoding="utf-8")


def main():
    before=json.loads((REPORT/"evidence/source_before.json").read_text())
    listed=subprocess.check_output(["git","ls-files","-co","--exclude-standard","--","AminScatter","CyrusMCP","CyrusSurfaceAnalyzer","CyrusLicensing","tools","cmake"],cwd=ROOT,text=True).splitlines()
    current={p:sha(ROOT/p) for p in sorted(set(listed)) if (ROOT/p).is_file()}
    protected=[p for p in before["files"] if p.startswith(("CyrusLicensing/","tools/licensing_lab/"))]
    protected += ["AminScatter/src/point_display.cpp","AminScatter/src/preview.cpp","CyrusMCP/cyrus_mcp/models.py","CyrusMCP/cyrus_mcp/contracts.py"]
    assert all(current.get(p)==before["files"][p] for p in protected), "Protected source changed since this campaign began"
    snapshot=dict(recorded_at_utc=datetime.now(timezone.utc).isoformat(),
                  head=subprocess.check_output(["git","rev-parse","HEAD"],cwd=ROOT,text=True).strip(),
                  branch=subprocess.check_output(["git","branch","--show-current"],cwd=ROOT,text=True).strip(),files=current,
                  changed_from_campaign_start=[p for p in before["files"] if current.get(p)!=before["files"][p]],
                  added_since_campaign_start=[p for p in current if p not in before["files"]],
                  protected_unchanged=protected,
                  git_status=subprocess.check_output(["git","status","--short"],cwd=ROOT,text=True),
                  interpretation="Inventory of the shared checkout; not all existing dirty/untracked files were authored in this campaign. Baseline includes pre-existing UI/docs/scene tooling.")
    assert snapshot["head"]==before["head"] and snapshot["branch"]==before["branch"]
    write(REPORT/"evidence/source_after.json",snapshot)
    sdk=[]
    for year in (2026,2027):
        folder=BUILD/f"max{year}"
        receipt=json.loads((folder/"receipt.json").read_text())
        assert all(s["exit_code"]==0 for s in receipt["stages"])
        assert receipt["host_launched"] is False and receipt["installed"] is False
        assert all(sha(ROOT/path)==value for path,value in receipt["sources"].items()), "Source changed after SDK receipt"
        assert all(sha(ROOT/path)==value for path,value in receipt["binaries"].items()), "Binary changed after SDK receipt"
        log=(folder/"tests.log").read_text()
        assert "100% tests passed, 0 tests failed out of 14" in log
        for original,target in ((folder/"receipt.json",f"sdk-{year}.json"),(folder/"tests.log",f"native-tests-{year}.log")):
            shutil.copyfile(original,REPORT/"evidence"/target)
        sdk.append(dict(year=year,compiled=True,native_tests=14,host_executed=False,receipt=f"sdk-{year}.json"))
    xml=ET.parse(BUILD/"python-tests.xml").getroot()
    suites=list(xml.iter("testsuite"))
    totals={k:sum(int(s.get(k,"0")) for s in suites) for k in ("tests","failures","errors","skipped")}
    assert totals["tests"]>=118 and totals["failures"]==totals["errors"]==totals["skipped"]==0
    shutil.copyfile(BUILD/"python-tests.xml",REPORT/"evidence/python-tests.xml")
    generator=json.loads((ROOT/"build/procedural-07/generated-check.json").read_text())
    assert generator["passed"] and generator["generated_sha256"]==sha(ROOT/"AminScatter/scripts/AminScatterObject.ms")
    shutil.copyfile(ROOT/"build/procedural-07/generated-check.json",REPORT/"evidence/generated-check.json")
    module=importlib.util.spec_from_file_location("generated_check",ROOT/"tools/procedural_lab/check_generated.py")
    check=importlib.util.module_from_spec(module);module.loader.exec_module(check)
    check.check_balanced((ROOT/"tools/procedural_lab/Max_Offline_Implementation_Acceptance.ms").read_text())
    tree=ast.parse((ROOT/"CyrusMCP/cyrus_mcp/server.py").read_text())
    names={kind:[] for kind in ("tool","resource")}
    for node in ast.walk(tree):
        if isinstance(node,ast.FunctionDef):
            for d in node.decorator_list:
                if isinstance(d,ast.Call) and isinstance(d.func,ast.Attribute) and d.func.attr in names:
                    names[d.func.attr].append(node.name if d.func.attr=="tool" else ast.literal_eval(d.args[0]))
    assert len(names["tool"])==12 and len(names["resource"])==7
    verification=dict(recorded_at_utc=datetime.now(timezone.utc).isoformat(),python=totals,sdk=sdk,
                      generated_script=generator,prepared_fixture_delimiters_checked=True,maxscript_compiled=False,
                      mcp=names,protected_source_files_unchanged=len(protected),computer_use=False,max_launched=False,
                      artist_profile_installation=False,packaged=False,committed=False,pushed=False,
                      source_snapshot="source_after.json",runtime_qualification="Pending the separately authorized private Max campaign.")
    write(REPORT/"evidence/verification.json",verification)
    print(json.dumps({"python":totals,"sdk":sdk,"mcp_tools":len(names["tool"]),"mcp_resources":len(names["resource"]),
                      "protected_files":len(protected),"changed_sources":len(snapshot["changed_from_campaign_start"]),
                      "new_sources":len(snapshot["added_since_campaign_start"]),"host_executed":False},indent=2))


if __name__=="__main__":main()
