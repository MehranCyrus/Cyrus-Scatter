"""Fresh CPU-only build and review fixture; never builds/loads a Max module."""
import argparse
import hashlib
import importlib.util
import json
import shutil
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("repo", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--reuse-core", type=Path, help="Reuse this review's unchanged, freshly tested pure library")
    args = parser.parse_args()
    repo = args.repo.resolve()
    output = args.output.resolve()
    assert output.is_relative_to(repo / "build"), "Diagnostics must stay in the ignored build workspace"
    output.mkdir(parents=True, exist_ok=False)
    spec = importlib.util.spec_from_file_location("build_max", repo / "tools/build_max.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    env = module.compiler_environment(Path("C:/Program Files/Microsoft Visual Studio/2022/Community"), "14.38.33130", "10.0.19041.0")
    cmake = shutil.which("cmake", path=env.get("PATH", env.get("Path", "")))
    compiler = shutil.which("cl.exe", path=env.get("PATH", env.get("Path", "")))
    records = []

    def run(label, command):
        print(label, flush=True)
        result = subprocess.run([str(x) for x in command], cwd=output, env=env,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        log = output / (label + ".log")
        log.write_text(result.stdout, encoding="utf-8")
        records.append({"label": label, "command": list(map(str, command)), "exit_code": result.returncode,
                        "log": log.name, "sha256": hashlib.sha256(log.read_bytes()).hexdigest()})
        (output / "commands.json").write_text(json.dumps(records, indent=2) + "\n")
        if result.returncode:
            print(result.stdout[-5000:], flush=True)
            raise SystemExit(result.returncode)
        return result.stdout

    core = args.reuse_core.resolve() if args.reuse_core else output / "core"
    if args.reuse_core:
        assert core.is_relative_to(repo / "build") and (core / "amin_scatter.lib").is_file()
    else:
        run("configure", [cmake, "-S", repo / "AminScatter", "-B", core, "-G", "NMake Makefiles",
                          "-DCMAKE_BUILD_TYPE=Release", "-DAMIN_BUILD_MAX=OFF"])
        run("build", [cmake, "--build", core])
        ctest = str(Path(cmake).with_name("ctest.exe"))
        run("ctest", [ctest, "--test-dir", core, "--output-on-failure"])
    fixture = Path(__file__).with_name("core_probe.cpp")
    exe = output / "core_probe.exe"
    run("probe-compile", [compiler, "/nologo", "/std:c++17", "/EHsc", "/MD", "/O2", "/DNDEBUG",
                          "/I" + str(repo / "AminScatter/include"), str(fixture), str(core / "amin_scatter.lib"),
                          "/Fe" + str(exe), "/Fo" + str(output / "core_probe.obj")])
    raw = run("probe", [exe])
    data = json.loads(raw)
    (output / "probe.json").write_text(json.dumps(data, indent=2) + "\n")
    receipt = {"source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip(),
               "host_modules_built_or_loaded": False, "reused_core": str(core) if args.reuse_core else None,
               "fixture_sha256": hashlib.sha256(fixture.read_bytes()).hexdigest(),
               "library_sha256": hashlib.sha256((core / "amin_scatter.lib").read_bytes()).hexdigest(),
               "executable_sha256": hashlib.sha256(exe.read_bytes()).hexdigest(), "commands": records, "results": data}
    (output / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(data, indent=2), flush=True)


if __name__ == "__main__":
    main()
