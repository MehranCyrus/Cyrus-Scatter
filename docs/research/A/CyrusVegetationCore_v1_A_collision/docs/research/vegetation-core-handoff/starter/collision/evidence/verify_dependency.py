#!/usr/bin/env python3
"""Verify the exact upstream archive, then exercise positive/negative source admission.

The negative fixture changes a temporary hash manifest, never engine source.
No downloaded executable or historical harness is run.
"""
import argparse
import hashlib
import json
import pathlib
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--archive", required=True)
parser.add_argument("--source", required=True)
parser.add_argument("--cmake", required=True)
args = parser.parse_args()
module = pathlib.Path(__file__).resolve().parent.parent
archive = pathlib.Path(args.archive).resolve()
source = pathlib.Path(args.source).resolve()
expected = "6bb6d626b7b70096cd07f1b25c0c223df035ab6386885f07f77baa88ae7d3998"
actual = hashlib.sha256(archive.read_bytes()).hexdigest()
print(json.dumps({"archive": str(archive), "bytes": archive.stat().st_size,
                  "expected_sha256": expected, "actual_sha256": actual}), flush=True)
if actual != expected:
    raise SystemExit("Archive SHA-256 mismatch")
verifier = module / "cmake" / "VerifyJoltSource.cmake"
manifest = module / "cmake" / "jolt-source.sha256"
positive = [args.cmake, "-DCYRUS_JOLT_VERIFY_ROOT=" + str(source), "-P", str(verifier)]
print("POSITIVE argv=" + json.dumps(positive), flush=True)
success = subprocess.run(positive, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
print(success.stdout, end="", flush=True)
print("POSITIVE observed_exit=" + str(success.returncode), flush=True)
if success.returncode:
    raise SystemExit(success.returncode)
with tempfile.TemporaryDirectory(prefix="cyrus_collision_wrong_hash_") as temporary:
    root = pathlib.Path(temporary)
    records = manifest.read_text().splitlines()
    for index, record in enumerate(records):
        if record and not record.startswith("#"):
            records[index] = "0" * 64 + record[64:]
            break
    wrong = root / "wrong.sha256"
    wrong.write_text("\n".join(records) + "\n")
    script = root / "negative.cmake"
    # CMake bracket arguments preserve literal paths; these paths are local
    # arguments supplied by the coordinator, not content evaluated from reports.
    script.write_text('include([==[' + str(verifier) + ']==])\n'
        'cyrus_collision_verify_jolt_source([==[' + str(source) + ']==] [==[' + str(wrong) + ']==])\n')
    negative = [args.cmake, "-P", str(script)]
    print("NEGATIVE argv=" + json.dumps(negative), flush=True)
    rejected = subprocess.run(negative, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(rejected.stdout, end="", flush=True)
    print("NEGATIVE observed_exit=" + str(rejected.returncode), flush=True)
    if rejected.returncode == 0 or "pinned Jolt source mismatch" not in rejected.stdout:
        raise SystemExit("Expected wrong-hash rejection was not observed")
print(json.dumps({"archive_hash": "passed", "source_admission": "passed",
                  "wrong_hash_rejection": "passed", "engine_source_mutated": False}), flush=True)
