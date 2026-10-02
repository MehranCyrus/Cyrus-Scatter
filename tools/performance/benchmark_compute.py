"""Build a frozen/current CPU comparison and verify every ordered numeric field.

Reference sources are preserved before edits, without Git. Runs standalone cores;
these timings exclude MAXScript, viewport, renderer and scene evaluation costs.
"""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from build_max import compiler_environment


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", type=Path, default=ROOT / "build/performance-reference/20261001-cpu-v1")
    parser.add_argument("--output", type=Path, default=ROOT / "build/cpu-benchmark-v1")
    parser.add_argument("--threads", type=int, nargs="+", default=[1, 2, 4, 6, 8, 12, 0])
    parser.add_argument("--trials", type=int, default=5)
    args = parser.parse_args()
    if not 1 <= args.trials <= 30 or any(not 0 <= limit <= 64 for limit in args.threads):
        parser.error("trials must be 1..30; thread limits must be 0..64")
    reference = args.reference.resolve()
    manifest = json.loads((reference / "manifest.json").read_text())
    for name, expected in manifest["files"].items():
        if hashlib.sha256((reference / name).read_bytes()).hexdigest() != expected:
            raise SystemExit(f"Frozen reference changed: {name}")
    env = compiler_environment(Path("C:/Program Files/Microsoft Visual Studio/2022/Community"), "14.38.33130", "10.0.19041.0")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    results = {}
    identities = {}
    started = datetime.now(timezone.utc).isoformat()
    for label, source in (("reference", reference), ("candidate", ROOT)):
        measured_files = sorted((source / "AminScatter/src").glob("*")) + sorted((source / "AminScatter/include").glob("*"))
        identities[label] = {str(path): hashlib.sha256(path.read_bytes()).hexdigest()
                             for path in measured_files if path.is_file()}
        project = output / f"{label}-project"
        project.mkdir(exist_ok=True)
        extra = f'"{source.as_posix()}/AminScatter/src/execution.cpp"' if label == "candidate" else ""
        definition = "target_compile_definitions(scatter_benchmark PRIVATE CYRUS_BENCH_EXECUTION=1)" if label == "candidate" else ""
        (project / "CMakeLists.txt").write_text(f'''cmake_minimum_required(VERSION 3.24)
project(CyrusComputeBenchmark LANGUAGES CXX)
find_package(Threads REQUIRED)
add_executable(scatter_benchmark "{source.as_posix()}/AminScatter/src/scatter.cpp" {extra}
 "{ROOT.as_posix()}/AminScatter/tests/compute_benchmark.cpp")
target_include_directories(scatter_benchmark PRIVATE "{source.as_posix()}/AminScatter/include")
target_compile_features(scatter_benchmark PRIVATE cxx_std_17)
target_compile_options(scatter_benchmark PRIVATE /W4 /WX /permissive-)
target_link_libraries(scatter_benchmark PRIVATE Threads::Threads)
{definition}
''')
        build = output / f"{label}-build"
        with (output / f"{label}-build.log").open("w") as log:
            for command in (["cmake", "-S", str(project), "-B", str(build), "-G", "NMake Makefiles", "-DCMAKE_BUILD_TYPE=Release"],
                            ["cmake", "--build", str(build)]):
                subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, check=True)
        for threads in ([1] if label == "reference" else args.threads):
            name = f"{label}-{threads}"
            fixtures = output / name
            completed = subprocess.run([str(build / "scatter_benchmark.exe"), str(fixtures), str(threads), str(args.trials)],
                                       check=True, capture_output=True, text=True)
            (output / f"{name}.jsonl").write_text(completed.stdout)
            rows = [json.loads(line) for line in completed.stdout.splitlines() if line]
            results[name] = rows
            if label == "candidate":
                for path in fixtures.glob("*.bin"):
                    original = output / "reference-1" / path.name
                    if path.read_bytes() != original.read_bytes():
                        raise SystemExit(f"Ordered output changed: {name}/{path.name}")
                if rows[-1] != results["reference-1"][-1]:
                    raise SystemExit(f"Failure changed: {name}")
            print(f"PASS {name}: {len(rows)-1} cases; exact ordered output verified", flush=True)
        if any(hashlib.sha256(Path(path).read_bytes()).hexdigest() != expected
               for path, expected in identities[label].items()):
            raise SystemExit(f"Measured sources changed during {label}")
    baseline = {row["case"]: row for row in results["reference-1"] if "case" in row}
    for key, rows in results.items():
        if key.startswith("candidate"):
            for row in rows:
                if "case" in row:
                    row["speedup_vs_reference"] = baseline[row["case"]]["median_ms"] / row["median_ms"]
    report = dict(scope="standalone native core; not end-to-end scene editing", trials=args.trials,
                  toolset="MSVC 14.38.33130 Release", reference=str(reference), results=results,
                  started_utc=started, measured_files=identities,
                  runner_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  benchmark_sha256=hashlib.sha256((ROOT / "AminScatter/tests/compute_benchmark.cpp").read_bytes()).hexdigest())
    (output / "results.json").write_text(json.dumps(report, indent=2) + "\n")
    for key, rows in results.items():
        print(key, "; ".join(f'{r["case"]}: {r["median_ms"]:.2f} ms' for r in rows if r.get("case") in ("clover_32000", "clover_64000")))


if __name__ == "__main__":
    main()
