#!/usr/bin/env python3
"""Run an explicit argv, preserving stdout/stderr, real exit status and timing.

No shell parsing and no historical harness is involved. This helper is optional;
the exact recorded argv may also be executed directly by the coordinator.
"""
import argparse
import datetime
import json
import pathlib
import subprocess
import sys
import time

parser = argparse.ArgumentParser()
parser.add_argument("--name", required=True)
parser.add_argument("--cwd", required=True)
parser.add_argument("command", nargs=argparse.REMAINDER)
args = parser.parse_args()
command = args.command
if command and command[0] == "--":
    command = command[1:]
if not command or "/" in args.name or "\\" in args.name:
    parser.error("supply a command and a plain record name")
directory = pathlib.Path(__file__).resolve().parent
log_path = directory / (args.name + ".log")
start = datetime.datetime.now(datetime.timezone.utc).isoformat()
clock = time.monotonic()
with log_path.open("w", encoding="utf-8") as log:
    log.write("command_argv: " + json.dumps(command) + "\n")
    log.write("cwd: " + str(pathlib.Path(args.cwd).resolve()) + "\n")
    log.write("started_utc: " + start + "\n\n")
    log.flush()
    result = subprocess.run(command, cwd=args.cwd, stdout=log, stderr=subprocess.STDOUT, check=False)
    elapsed = time.monotonic() - clock
    log.write("\nexit_code: " + str(result.returncode) + "\n")
record = {
    "command_argv": command,
    "cwd": str(pathlib.Path(args.cwd).resolve()),
    "started_utc": start,
    "exit_code": result.returncode,
    "elapsed_seconds_observed": elapsed,
    "timing_scope": "command wall time; not a collision/update benchmark",
    "log_path": log_path.name,
}
(directory / (args.name + ".json")).write_text(json.dumps(record, indent=2) + "\n")
print(json.dumps(record))
lines = log_path.read_text(errors="replace").splitlines()
print("\n".join(lines[-60:] if result.returncode else lines[-15:]))
sys.exit(result.returncode)
