"""Launch a private Max 2027 qualification session. Never touches artist configuration."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

ROOT=Path(__file__).resolve().parents[2]


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--run",required=True)
    parser.add_argument("--installed-host",type=Path,help="Test the installed startup script and default connection in a fresh private Max")
    args=parser.parse_args()
    if not re.fullmatch(r"[a-z0-9-]+",args.run):
        raise SystemExit("Use a lowercase run name")
    output=ROOT/"build/mcp-qualification"/args.run
    output.mkdir(parents=True,exist_ok=False)
    for folder in ("startup","plugcfg","temp","bin","autoback"):
        (output/folder).mkdir()
    for name in ("AminScatter.dlx","CyrusScatterEdit.dlm"):
        shutil.copy2(ROOT/"build/brush-lab-2026-10-03/max2027"/name,output/"bin"/name)
    shutil.copy2(ROOT/"build/codebase-research-2026-10-01/max2027/CyrusSurfaceAnalyzer/CyrusSurfaceAnalyzer.dlx",output/"bin/CyrusSurfaceAnalyzer.dlx")
    source=Path(os.environ["LOCALAPPDATA"])/"Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini"
    config=source.read_text(encoding="utf-16")
    for key,folder in {"Additional Startup Scripts":"startup","PlugCFG":"plugcfg","Temp":"temp","Page File":"temp","AutoBackup":"autoback"}.items():
        config,n=re.subn(rf"(?m)^{re.escape(key)}=.*$",lambda _:key+"="+str(output/folder),config)
        if n!=1:
            raise SystemExit("Unrecognized Max configuration: "+key)
    (output/"desktop.ini").write_text(config,encoding="utf-16")
    (output/"plugins.ini").write_text("[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns/\nCyrus="+str(output/"bin")+"\n[Help]\n")
    host=(args.installed_host or ROOT/"CyrusMCP").resolve()
    if not (host/"Start_Cyrus_Automation.ms").is_file():
        raise SystemExit("Missing host startup script")
    entry="host_fixture.start("+repr(str(output))+")"
    if args.installed_host:
        entry="host_fixture.start_installed("+repr(str(output))+","+repr(str(host/"Start_Cyrus_Automation.ms"))+")"
    py="import sys, faulthandler\n_cyrus_fault_log=open("+repr(str(output/"python-fault.log"))+",'w')\nfaulthandler.enable(_cyrus_fault_log)\nsys.path.insert(0,"+repr(str(host))+")\nsys.path.insert(0,"+repr(str(ROOT/"tools/mcp"))+")\nimport host_fixture\nfrom PySide6.QtCore import QTimer\nQTimer.singleShot(1500,lambda:"+entry+")"
    pyfile=output/"start.py"
    pyfile.write_text(py,encoding="utf-8")
    script=output/"start.ms"
    script.write_text('global MCPFixtureDir="'+output.as_posix()+'/"\nfileIn @"'+str(ROOT/"tools/mcp/development_transport.ms")+'"\nfileIn @"'+str(ROOT/"CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms")+'"\nfileIn @"'+str(ROOT/"AminScatter/scripts/AminScatterObject.ms")+'"\npython.ExecuteFile @"'+str(pyfile)+'"\n',encoding="utf-8")
    command=["C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe","-q","-i",str(output/"desktop.ini"),"-p",str(output/"plugins.ini"),"-U","MAXScript",str(script),"-listenerlog",str(output/"listener.log")]
    proc=subprocess.Popen(command,cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    metadata={"pid":proc.pid,"output":str(output),"host_package":str(host),"binaries":{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (output/"bin").iterdir()}}
    (output/"launch.json").write_text(json.dumps(metadata,indent=2))
    print(json.dumps(metadata,indent=2))


if __name__=="__main__":main()
