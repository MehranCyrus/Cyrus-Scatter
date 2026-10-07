"""Create a separate analysis-project copy and launch the already installed backend.

This does not execute the vendor plugin, install tools, or modify its original
analysis project. Stop/save/close the owned server explicitly after inspection.
"""
import argparse
import json
import os
import shutil
import socket
import subprocess
from pathlib import Path


def main():
    p = argparse.ArgumentParser()
    p.add_argument("analysis_root", type=Path)
    p.add_argument("output", type=Path)
    args = p.parse_args()
    root, out = args.analysis_root.resolve(), args.output.resolve()
    if not out.is_relative_to(root) or out == root:
        raise ValueError("Output must be a new descendant of the private analysis workspace")
    with socket.socket() as probe:
        if probe.connect_ex(("127.0.0.1", 18089)) == 0:
            raise RuntimeError("Port 18089 is already in use; do not replace another process")
    out.mkdir(parents=True, exist_ok=False)
    project = out / "project"
    project.mkdir()
    original = root / "projects/tyFlowArchitecture"
    shutil.copy2(original.with_suffix(".gpr"), project / "tyFlowArchitecture.gpr")
    shutil.copytree(original.with_suffix(".rep"), project / "tyFlowArchitecture.rep")
    config = json.loads((root / "tools.json").read_text())
    ghidra, java = Path(config["ghidra"]), Path(config["java"]) / "bin/java.exe"
    cp = config["mcp_jars"] + [str(x / "*") for x in (ghidra / "Ghidra").glob("*/*/lib")]
    cp += [str(x / "*") for x in (ghidra / "Ghidra").glob("*/lib")]
    user = out / "userhome"
    user.mkdir()
    arguments = ["-Xmx8g", "-XX:+UseG1GC", "-Dghidra.home=" + str(ghidra),
                 "-Duser.home=" + str(user), "-Dapplication.name=GhidraMCP",
                 "-classpath", os.pathsep.join(cp), "com.xebyte.headless.GhidraMCPHeadlessServer",
                 "--bind", "127.0.0.1", "--port", "18089"]
    argfile = out / "launch.args"
    argfile.write_text("\n".join('"' + a.replace("\\", "/").replace('"', '\\"') + '"' for a in arguments))
    env = os.environ.copy()
    env["GHIDRA_MCP_FILE_ROOT"] = str(root)
    env["GHIDRA_MCP_ALLOW_SCRIPTS"] = "1"
    with (out / "headless.log").open("w", encoding="utf-8") as log:
        process = subprocess.Popen([str(java), "@" + str(argfile)], cwd=ghidra, env=env,
                                   stdout=log, stderr=subprocess.STDOUT,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
    state = {"pid": process.pid, "url": "http://127.0.0.1:18089",
             "project_copy": str(project / "tyFlowArchitecture.gpr"), "argv_file": str(argfile),
             "original_project_preserved": str(original.with_suffix(".gpr"))}
    (out / "process.json").write_text(json.dumps(state, indent=2))
    print(json.dumps(state), flush=True)


if __name__ == "__main__":
    main()
