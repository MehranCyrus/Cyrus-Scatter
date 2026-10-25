#!/usr/bin/env python3
"""Run B's actual builds/tests and preserve command receipts. No third-party Python packages."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cmake", default=shutil.which("cmake"))
    parser.add_argument("--compiler", default=shutil.which("c++"))
    parser.add_argument("--profile", choices=("all", "release", "sanitized"), default="all")
    parser.add_argument("--leak-detection", choices=("on", "off"), default="on",
                        help="Disable only for environments where LeakSanitizer cannot inspect processes; retain that limitation")
    parser.add_argument("--evidence-dir")
    parser.add_argument("--build-root")
    args = parser.parse_args()
    module = Path(__file__).resolve().parents[1]
    scaffold = module.parent
    evidence = Path(args.evidence_dir).resolve() if args.evidence_dir else module / "evidence" / "executed"
    build_root = Path(args.build_root).resolve() if args.build_root else module / "build-checks"
    evidence.mkdir(parents=True, exist_ok=True)
    if not args.cmake or not args.compiler:
        parser.error("CMake and a C++20 compiler must be available; no execution receipt was invented.")
    cmake = str(Path(args.cmake).resolve())
    compiler = str(Path(args.compiler).resolve())
    ctest = str(Path(cmake).with_name("ctest" + (".exe" if os.name == "nt" else "")))
    records = []
    numerical = []
    metadata = {
        "scope": "Executed owner-B headless tests with authored analytic/fake CollisionWorld; no A/C/Max/Jolt run",
        "utc_started": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "environment": {"os": platform.platform(), "machine": platform.machine(),
                        "python": sys.version, "compiler_executable": compiler,
                        "cmake_executable": cmake, "dependencies": ["C++20 standard library", "frozen cyrus_prototype_contract"]},
        "executions": records, "numerical_records": numerical,
    }
    compiled_inputs = [module / "CMakeLists.txt", module / "fitter.cpp", module / "private" / "math.hpp",
                       module / "tests" / "CMakeLists.txt", module / "tests" / "test_fitter.cpp",
                       module / "tests" / "test_analytic_world.cpp", module / "tests" / "analytic_world.hpp",
                       scaffold / "include" / "cyrus_vegetation" / "prototype_v1.hpp"]
    metadata["compiled_input_hashes"] = [
        {"path_from_starter": str(p.relative_to(scaffold)), "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
         "bytes": p.stat().st_size} for p in compiled_inputs]

    def receipt():
        (evidence / "execution_summary.json").write_text(json.dumps(metadata, indent=2, allow_nan=False) + "\n")

    def run(label, command, overrides=None):
        env = os.environ.copy()
        env.update(overrides or {})
        started = datetime.datetime.now(datetime.timezone.utc).isoformat()
        print("RUN " + label + ": " + shlex.join(command), flush=True)
        completed = subprocess.run(command, cwd=scaffold, env=env, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, text=True, errors="replace")
        log = evidence / (label + ".log")
        log.write_text("command: " + shlex.join(command) + "\ncwd: " + str(scaffold) +
                       "\nenvironment_overrides: " + json.dumps(overrides or {}) +
                       "\nstarted_utc: " + started + "\n\n" + completed.stdout +
                       "\nexit_code: " + str(completed.returncode) + "\n")
        records.append({"label": label, "command": command, "cwd": str(scaffold),
                        "environment_overrides": overrides or {}, "exit_code": completed.returncode,
                        "log_path": str(log.relative_to(module)), "started_utc": started})
        if label.endswith("ctest"):
            for line in completed.stdout.splitlines():
                match = re.match(r"^\d+: (\{.*\})$", line)
                if match:
                    numerical.append({"profile": label.split("_")[0], **json.loads(match.group(1))})
            summary = re.search(r"\d+% tests passed, \d+ tests failed out of \d+", completed.stdout)
            records[-1]["observed_summary"] = summary.group(0) if summary else "No CTest pass summary; inspect log"
        receipt()
        print("EXIT " + label + " " + str(completed.returncode), flush=True)
        if completed.returncode:
            print(completed.stdout[-12000:], flush=True)
        return completed.returncode

    failure = run("compiler_version", [compiler, "--version"])
    failure |= run("cmake_version", [cmake, "--version"])
    profiles = ("release", "sanitized") if args.profile == "all" else (args.profile,)
    for profile in profiles:
        build = build_root / profile
        sanitized = profile == "sanitized"
        configure = [cmake, "-S", str(scaffold), "-B", str(build),
                     "-DCMAKE_CXX_COMPILER=" + compiler,
                     "-DCMAKE_BUILD_TYPE=" + ("Debug" if sanitized else "Release"),
                     "-DBUILD_TESTING=ON", "-DCYRUS_FITTER_SANITIZERS=" + ("ON" if sanitized else "OFF")]
        code = run(profile + "_configure", configure)
        failure |= code
        if code:
            continue
        code = run(profile + "_build", [cmake, "--build", str(build), "--parallel", "4"])
        failure |= code
        if code:
            continue
        overrides = {"ASAN_OPTIONS": "detect_leaks=" + ("1" if args.leak_detection == "on" else "0") + ":halt_on_error=1", "UBSAN_OPTIONS": "halt_on_error=1:print_stacktrace=1"} if sanitized else {}
        failure |= run(profile + "_ctest", [ctest, "--test-dir", str(build), "-R", "^fitter_", "-V", "--output-on-failure", "-j1"], overrides)
    metadata["utc_finished"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    metadata["all_invoked_commands_succeeded"] = failure == 0
    receipt()
    return 0 if failure == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
