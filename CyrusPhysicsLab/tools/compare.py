"""Run isolated CPU engine experiments; preserve quality failures as results."""
from pathlib import Path
import argparse
import hashlib
import json
import platform
import subprocess
import statistics
import shutil


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--max-bodies", type=int, choices=(100,1000), default=1000)
    parser.add_argument("--process-timeout", type=int, default=180)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    executable = (args.output / "cpl_compare.exe").resolve()
    shutil.copy2(args.build / "cpl_compare.exe", executable)
    runs = []
    for engine in ("jolt", "physx"):
        for scene in ("flat", "pile", "curb", "fast"):
            output = args.output / f"{engine}-{scene}.json"
            status = "completed"
            with output.with_suffix(".txt").open("w", encoding="utf-8") as log:
                try:
                    result = subprocess.run([str(executable), str(output.resolve()), str(args.max_bodies), engine, scene],
                                            stdout=log, stderr=subprocess.STDOUT, timeout=args.process_timeout)
                    if result.returncode:
                        status = f"process_exit_{result.returncode}"
                except subprocess.TimeoutExpired:
                    status = "timeout"
            if output.exists():
                data = json.loads(output.read_text())
            else:
                data = []
                for line in output.with_suffix(".txt").read_text().splitlines():
                    try:
                        item = json.loads(line)
                        if isinstance(item, dict) and "repeat" in item:
                            data.append(item)
                    except json.JSONDecodeError:
                        continue
            seen = {(x["count"],x["repeat"]) for x in data}
            first_missing = True
            for count in (1,100,1000):
                if count>args.max_bodies:
                    continue
                for repeat in range(5):
                    if (count,repeat) not in seen:
                        data.append({"engine":engine,"scenario":scene,"count":count,"repeat":repeat,
                                     "pass":False,"outcome":status if first_missing else "not_run_after_process_failure",
                                     "error":"Process did not complete this experiment; no quality result claimed"})
                        first_missing=False
            output.write_text(json.dumps(data,indent=2)+"\n")
            runs.extend(data)
            print(f"{engine}/{scene}: {sum(x['pass'] for x in data)}/{len(data)} quality passes; process {status}", flush=True)
    summary = []
    for engine in ("jolt", "physx"):
        for scene in ("flat", "pile", "curb", "fast"):
            selected = [x for x in runs if x["engine"] == engine and x["scenario"] == scene and x["count"] == args.max_bodies]
            passed = [x for x in selected if x["pass"]]
            summary.append({"engine": engine, "scene": scene, "count": args.max_bodies, "passes": len(passed),
                            "median_solve_ms": statistics.median(x["solve_ms"] for x in passed) if passed else None,
                            "same_build_repeatable": (len({x["transforms_fnv64"] for x in selected}) == 1
                                                      if selected and all("transforms_fnv64" in x for x in selected) else None)})
    receipt = {"system": platform.platform(), "processor": platform.processor(),
               "executable_sha256": hashlib.sha256(executable.read_bytes()).hexdigest(),
               "memory_scope": "Process peak includes runtime and preceding smaller tiers; engines/scenarios use separate processes",
               "runs": runs, "summary": summary}
    (args.output / "comparison.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(summary, indent=2), flush=True)


if __name__ == "__main__":
    main()
