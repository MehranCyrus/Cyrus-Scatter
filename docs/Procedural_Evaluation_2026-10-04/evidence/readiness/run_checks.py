"""Isolated current-code qualification, not Max runtime or new-policy validation.

Run from any directory with the repository's build/mcp-venv Python. It uses the
existing pinned compiler environment, writes only an ignored build directory and
this evidence folder, and never regenerates/installs the production plugin.
"""
from pathlib import Path
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys

EVIDENCE=Path(__file__).resolve().parent
ROOT=EVIDENCE.parents[3]

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    commit=subprocess.check_output(["git","rev-parse","HEAD"],cwd=ROOT,text=True).strip()
    run=ROOT/"build"/("procedural-readiness-"+commit[:7])
    run.mkdir(parents=True,exist_ok=True)
    spec=importlib.util.spec_from_file_location("cyrus_build",ROOT/"tools/build_max.py")
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    env=module.compiler_environment(Path("C:/Program Files/Microsoft Visual Studio/2022/Community"),"14.38.33130","10.0.19041.0")
    commands=[]
    def execute(label,args,cwd=ROOT,environment=env):
        result=subprocess.run([str(x) for x in args],cwd=cwd,env=environment,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        (EVIDENCE/(label+".txt")).write_text(result.stdout,encoding="utf-8")
        commands.append({"name":label,"args":[str(x) for x in args],"exit_code":result.returncode})
        print(label+": "+str(result.returncode),flush=True)
        if result.returncode:raise RuntimeError(label+" failed; see evidence log")
        return result.stdout

    cmake=shutil.which("cmake");ctest=shutil.which("ctest");node=shutil.which("node")
    if not all((cmake,ctest,node)):raise RuntimeError("Missing installed cmake/ctest/node")
    harness=run/"harness";harness.mkdir(exist_ok=True)
    (harness/"CMakeLists.txt").write_text(
        'cmake_minimum_required(VERSION 3.24)\nproject(CyrusReadiness LANGUAGES CXX)\nenable_testing()\n'
        'set(AMIN_BUILD_MAX OFF CACHE BOOL "" FORCE)\n'
        f'add_subdirectory("{(ROOT/"AminScatter").as_posix()}" core)\n'
        f'add_executable(readiness_probe "{(EVIDENCE/"native_readiness_probe.cpp").as_posix()}")\n'
        'target_link_libraries(readiness_probe PRIVATE amin_scatter)\n'
        'add_test(NAME readiness_claims COMMAND readiness_probe)\n',encoding="utf-8")
    native=run/"native"
    execute("configure",[cmake,"-S",harness,"-B",native,"-G","NMake Makefiles","-DCMAKE_BUILD_TYPE=Release"])
    execute("build",[cmake,"--build",native])
    execute("native-tests",[ctest,"--test-dir",native,"--output-on-failure"])
    observations=json.loads(execute("native-probe",[native/"readiness_probe.exe"]))
    generator=run/"generator";generator.mkdir(exist_ok=True)
    shutil.copytree(ROOT/"AminScatter/tools/ui",generator/"tools/ui",dirs_exist_ok=True)
    (generator/"scripts").mkdir(exist_ok=True)
    execute("generator",[node,"tools/ui/generate.cjs"],cwd=generator)
    generated=["scripts/AminScatterObject.ms","tools/ui/layers-control-inventory.json"]
    comparisons={name:(ROOT/"AminScatter"/name).read_text(encoding="utf-8")== (generator/name).read_text(encoding="utf-8") for name in generated}
    if not all(comparisons.values()):raise RuntimeError("Generated artifact mismatch")
    pyenv=dict(os.environ);pyenv["PYTHONPATH"]=str(ROOT/"CyrusMCP");pyenv["PYTHONDONTWRITEBYTECODE"]="1"
    execute("mcp-tests",[sys.executable,"-m","pytest","CyrusMCP/tests","-q","-p","no:cacheprovider","--basetemp",run/"pytest"],environment=pyenv)
    report={"source_commit":commit,"scope":"Native core, isolated generator and MCP local/mock/stdio tests; no Max runtime or viewport benchmark", "commands":commands,"generated_artifacts_match":comparisons,"native_observations":observations,"probe_executable_sha256":digest(native/"readiness_probe.exe")}
    (EVIDENCE/"checks.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(report,indent=2),flush=True)

if __name__=="__main__":main()
