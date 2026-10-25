"""Controlled process loss and fresh-host recovery, confined to owned profiles."""
from pathlib import Path
import argparse
import asyncio
import ctypes
from ctypes import wintypes
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
import uuid
from foundation_campaign import ROOT, HERE, stage_package_payload, launch_owned, verify_owned, run_case, close_owned


def write(path, value):
    path.write_text(json.dumps(value,indent=2)+"\n",encoding="utf-8")


def prepare_runtime(base):
    if (base/"source").exists():
        return
    base.mkdir(parents=True,exist_ok=True)
    packages=ROOT/"dist/CyrusScatter-0.86.9.2-20261023"
    stage_package_payload(base/"payload",2027,packages/"CyrusScatter-0.86.9.2-Max2027.mzp",packages/"CyrusSurfaceAnalyzer-0.14.2-Max2027.mzp")
    shutil.copytree(ROOT/"CyrusMCP/cyrus_mcp",base/"source/cyrus_mcp",ignore=shutil.ignore_patterns("__pycache__"))
    (base/"fixtures").mkdir()
    for name in ("foundation_host.py","host_fixture.py","loss_host.py"):
        shutil.copy2(HERE/name,base/"fixtures"/name)


def launch(base, stage, after=False):
    prepare_runtime(base)
    case=base/stage
    case.mkdir(exist_ok=True)
    phase="after" if after else "before"
    folder=case/phase
    if (folder/"qualification.json").exists():
        raise RuntimeError("Profile already launched; use resume to observe its original PID")
    if after and not (case/"terminated.json").exists():
        raise RuntimeError("Original owned process must be confirmed terminal before restart")
    boot=case/("boot-"+phase+".py")
    boot.write_text("import sys\n"+"sys.path.insert(0,"+repr(str(base/"source"))+")\n"+
                   "sys.path.insert(0,"+repr(str(base/"fixtures"))+")\n"+
                   "from PySide6.QtCore import QTimer\nimport loss_host\n"+
                   "QTimer.singleShot(100,lambda:loss_host.start("+repr(str(folder))+","+repr(str(case/"connection"))+",restore="+repr(after)+"))\n",encoding="utf-8")
    bindings={"loss-driver":Path(__file__),"foundation-driver":HERE/"foundation_campaign.py","loss-boot":HERE/"loss_boot.ms","python-boot":boot}
    for path in [*base.joinpath("source").rglob("*.py"),*base.joinpath("source").rglob("*.json"),*base.joinpath("fixtures").glob("*.py")]:
        bindings["frozen-"+path.relative_to(base).as_posix().replace("/","_")]=path
    if after:
        bindings["owned-scene-checkpoint"]=case/"checkpoint.max"
    launch_owned(folder,2027,base/"payload",bindings=bindings,require_edit_version=True,timeout=60)
    resume(base,stage,after)


def resume(base,stage,after=False):
    case=base/stage;phase="after" if after else "before";folder=case/phase
    metadata=verify_owned(folder)
    if (folder/"ready.json").exists():
        requests=[json.loads(p.read_text(encoding="utf-8")) for p in folder.glob("request-*.json")]
        if not any(r.get("scenario_id")==phase for r in requests):
            run_case(folder,HERE/"loss_boot.ms",phase,["boot_scheduled"],entrypoint="MCPLossRun",timeout=30)
    if (folder/"foundation-error.txt").exists():
        raise RuntimeError((folder/"foundation-error.txt").read_text(encoding="utf-8"))
    print(json.dumps(dict(pid=metadata["pid"],phase=phase,ready=(folder/"loss-startup.json").exists(),folder=str(folder))),flush=True)


def qualification(base,stage,after=False):
    sys.path.insert(0,str(base/"source"));sys.path.insert(0,str(HERE))
    from qualify import Qualification
    from cyrus_mcp.transport import Client
    folder=base/stage/("after" if after else "before")
    class Owned(Qualification):
        def local(self,action,**args):
            verify_owned(self.folder);result=super().local(action,**args);verify_owned(self.folder);return result
        def call(self,method,**args):
            verify_owned(self.folder);result=super().call(method,**args);verify_owned(self.folder);return result
    q=Owned(folder);q.client=Client(base/stage/"connection")
    return q


def arm(base,stage):
    case=base/stage
    if (case/"attempt.json").exists():
        raise RuntimeError("Original apply already recorded; inspect its state, never create a replacement attempt")
    q=qualification(base,stage)
    first=q.apply(q.plan(q.context(),count=80,layers=2))
    assert first["state"]=="succeeded",first
    owner=first["result"]
    checkpoint=q.local("loss_checkpoint")
    shutil.copy2(case/"checkpoint.max",case/"checkpoint-before.max")
    context=q.context()
    change=dict(change_schema="cyrus.owned-change/1.0",context_id=context["context_id"],controller_id=owner["controller_id"],
                generation_id=owner["generation_id"],configuration_id=owner["configuration_id"],mode="configure",
                layers=[dict(layer_id=owner["layers"][0]["layer_id"],count=120)])
    value=q.call("scatter.validate_change",change=change)
    q.local("approve",validation_id=value["validation_id"])
    q.local("loss_arm",stage=stage)
    args={key:value[key] for key in ("validation_id","digest","scene_epoch","scene_revision")}
    args["idempotency_key"]="loss_"+uuid.uuid4().hex
    # Persist the original key before submission so an observation timeout cannot
    # result in a second mutation request with a new key.
    write(case/"attempt.json",dict(stage=stage,args=args,change=change,before=checkpoint))
    queued=q.call("scatter.apply_plan",**args)
    write(case/"queued-response.json",queued)
    print(json.dumps(dict(queued=True,operation_id=queued["operation"]["operation_id"],stage=stage)),flush=True)


def terminate(base,stage):
    case=base/stage;folder=case/"before"
    if (case/"terminated.json").exists():
        raise RuntimeError("Process loss already confirmed; do not terminate another process")
    metadata=verify_owned(folder)
    attempt=json.loads((case/"attempt.json").read_text(encoding="utf-8"))
    journal=json.loads((case/"connection/operations.json").read_text(encoding="utf-8"))
    record=next(r for r in journal if r["idempotency_key"]==attempt["args"]["idempotency_key"])
    if stage=="queued":
        assert record["state"]=="queued" and record["effects"]=="none",record
    else:
        marker=json.loads((case/"loss-boundary.json").read_text(encoding="utf-8"))
        assert marker["pid"]==metadata["pid"] and marker["stage"]==stage
        assert record["state"]=="running" and record["effects"]==("committed" if stage=="journal_commit" else "unknown"),record
    write(case/"journal-before-loss.json",journal)
    write(case/"checkpoint-before-loss.json",dict(sha256=hashlib.sha256((case/"checkpoint.max").read_bytes()).hexdigest()))
    kernel=ctypes.WinDLL("kernel32",use_last_error=True)
    kernel.OpenProcess.argtypes=[wintypes.DWORD,wintypes.BOOL,wintypes.DWORD];kernel.OpenProcess.restype=wintypes.HANDLE
    kernel.CloseHandle.argtypes=[wintypes.HANDLE]
    kernel.QueryFullProcessImageNameW.argtypes=[wintypes.HANDLE,wintypes.DWORD,wintypes.LPWSTR,ctypes.POINTER(wintypes.DWORD)]
    kernel.TerminateProcess.argtypes=[wintypes.HANDLE,wintypes.UINT]
    kernel.WaitForSingleObject.argtypes=[wintypes.HANDLE,wintypes.DWORD]
    handle=kernel.OpenProcess(0x101001,False,metadata["pid"])
    if not handle:raise OSError("Cannot obtain an owned process handle")
    try:
        verify_owned(folder)
        path=ctypes.create_unicode_buffer(32768);size=wintypes.DWORD(len(path))
        if not kernel.QueryFullProcessImageNameW(handle,0,path,ctypes.byref(size)):
            raise OSError("Cannot verify opened process image")
        if Path(path.value).resolve()!=Path(metadata["command"][0]).resolve():
            raise RuntimeError("Owned process image mismatch")
        if not kernel.TerminateProcess(handle,0xC0DEC0DE):
            raise OSError("Controlled owned-process termination failed")
        if kernel.WaitForSingleObject(handle,10000)!=0:
            raise RuntimeError("Original process handle is not terminal; observe it without restarting")
    finally:
        kernel.CloseHandle(handle)
    write(case/"terminated.json",dict(pid=metadata["pid"],stage=stage,status="original_handle_terminal",operation_id=record["operation_id"],
          checkpoint_sha256=hashlib.sha256((case/"checkpoint.max").read_bytes()).hexdigest()))
    print(json.dumps(dict(terminated_owned_pid=metadata["pid"],stage=stage)),flush=True)


async def check(base,stage):
    q=qualification(base,stage,True);case=base/stage
    from mcp import Client
    from mcp.client.stdio import StdioServerParameters
    attempt=json.loads((case/"attempt.json").read_text(encoding="utf-8"));args=attempt["args"]
    original=json.loads((case/"queued-response.json").read_text(encoding="utf-8"))["operation"]
    startup=json.loads((case/"after/loss-startup.json").read_text(encoding="utf-8"))
    assert startup["recovery_required"] and not startup["scope"] and not startup["enroll_enabled"] and not startup["approve_enabled"] and startup["review_enabled"],startup
    assert "local review" in startup["message"]
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(case/"connection")])
    async with Client(params) as client:
        connection=(await client.call_tool("connection_get_status",{})).structured_content
        assert connection["recovery_required"] and connection["scope_id"] is None and connection["scene_epoch"]!=args["scene_epoch"]
        status=(await client.call_tool("scatter_get_status",dict(scene_epoch=args["scene_epoch"],operation_id=original["operation_id"]))).structured_content["operation"]
        assert status["state"]=="outcome_unknown" and status["effects"]==("committed" if stage=="journal_commit" else "unknown"),status
        assert (await client.call_tool("scatter_apply_plan",args)).structured_content["operation"]==status
        denied=await client.call_tool("scatter_apply_plan",{**args,"idempotency_key":"new_"+uuid.uuid4().hex})
        assert denied.is_error and denied.structured_content["error"]["code"]=="OUTCOME_UNKNOWN"
        assert status["target_identity"]=={key:attempt["change"][key] for key in ("controller_id","generation_id","configuration_id")}
        before=q.local("loss_state")
        assert len(before["roots"])==1
        expected=attempt["before"] if stage=="queued" else json.loads((case/"loss-boundary.json").read_text(encoding="utf-8"))["scene"]
        for field in ("owner","generation","configuration","layers","root_update_mode"):
            assert before["roots"][0][field]==expected["roots"][0][field],field
        q.local("loss_select",controller_id=attempt["change"]["controller_id"])
        review=q.local("loss_review",operation_id=original["operation_id"])
        selected=review["evidence"]["selected_controller"]
        assert selected["recorded_identity_basis"]==("commit" if stage=="journal_commit" else "approved_base_before_execution")
        if stage=="journal_commit":
            assert selected["recorded_configuration_matches"] is True
        elif stage=="host_return":
            assert selected["recorded_configuration_matches"] is False
        retirement=q.local("confirm_recovery",review_id=review["review_id"],digest=review["digest"])
        assert not retirement["recovery_required"]
        after=q.local("loss_state")
        assert after==before,"Local retirement changed the restored native scene"
        retired=(await client.call_tool("scatter_get_status",dict(scene_epoch=args["scene_epoch"],operation_id=original["operation_id"]))).structured_content["operation"]
        assert retired["state"]==status["state"] and retired["effects"]==status["effects"] and retired["resolution"]["status"]=="locally_retired"
        assert (await client.call_tool("connection_get_status",{})).structured_content["scope_id"] is None
        metadata=verify_owned(q.folder)
        write(case/"process-loss-result.json",dict(status="passed",stage=stage,startup=startup,original=status,retired=retired,
              review=review,restored_scene=before,scene_unchanged_by_retirement=True,artifact_id=metadata["artifact_id"],
              qualification="Actual owned process termination, fresh Max 2027 + exact checkpoint, real SDK client; scripted local retirement, not artist consent"))
        print(json.dumps(dict(passed=True,stage=stage,receipt=str(case/"process-loss-result.json"))),flush=True)


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("action",choices=["launch","resume","arm","terminate","check","close"])
    p.add_argument("--base",required=True,type=Path);p.add_argument("--case",required=True,choices=["queued","host_return","journal_commit"]);p.add_argument("--after",action="store_true")
    a=p.parse_args();base=a.base.resolve()
    if not base.is_relative_to(ROOT/"build"):raise ValueError("Owned build directory required")
    if a.action in ("launch","resume"):globals()[a.action](base,a.case,a.after)
    elif a.action=="check":asyncio.run(check(base,a.case))
    elif a.action=="close":close_owned(base/a.case/("after" if a.after else "before"))
    else:globals()[a.action](base,a.case)
