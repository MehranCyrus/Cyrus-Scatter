"""Build an offline Windows/Python 3.11 handoff from the tested dependency pins."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
from packaging.utils import parse_wheel_filename

ROOT=Path(__file__).resolve().parents[2]


def main():
    parser=argparse.ArgumentParser();parser.add_argument("--output",type=Path,required=True)
    args=parser.parse_args()
    output=args.output.resolve()
    output.mkdir(parents=True,exist_ok=False)
    wheels=output/"wheels";wheels.mkdir()
    subprocess.run([sys.executable,"-m","pip","download","--only-binary=:all:","--no-deps","-r",str(ROOT/"CyrusMCP/requirements-pinned.txt"),"-d",str(wheels)],check=True)
    subprocess.run([sys.executable,"-m","pip","wheel",str(ROOT/"CyrusMCP"),"--no-deps","-w",str(wheels)],check=True)
    host=output/"host";host.mkdir()
    shutil.copytree(ROOT/"CyrusMCP/cyrus_mcp",host/"cyrus_mcp",ignore=shutil.ignore_patterns("__pycache__"))
    shutil.copy2(ROOT/"CyrusMCP/Start_Cyrus_Automation.ms",host)
    for name in ("README.md","Install_Cyrus_MCP.ps1"):
        shutil.copy2(ROOT/"CyrusMCP"/name,output/name)
    lock=[]
    for wheel in sorted(wheels.glob("*.whl")):
        name,version,_,_=parse_wheel_filename(wheel.name)
        lock.append(f"{name}=={version} --hash=sha256:{hashlib.sha256(wheel.read_bytes()).hexdigest()}")
    (output/"requirements-windows-py311.lock").write_text("# Qualified offline artifacts: Windows x64 / CPython 3.11.\n"+"\n".join(lock)+"\n")
    files=[{"path":p.relative_to(output).as_posix(),"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"bytes":p.stat().st_size} for p in sorted(output.rglob("*")) if p.is_file()]
    fingerprint=hashlib.sha256(json.dumps(files,sort_keys=True).encode()).hexdigest()[:12]
    manifest={"version":"1.0.0","build_id":"1.0.0-"+fingerprint,"qualified_host":"3ds Max 2027.1","external_runtime":"CPython 3.11 x64","files":files}
    (output/"package-manifest.json").write_text(json.dumps(manifest,indent=2))
    print(json.dumps({"folder":str(output),"build_id":manifest["build_id"],"files":len(files),"bytes":sum(v["bytes"] for v in files)},indent=2))


if __name__=="__main__":main()
