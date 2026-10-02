"""Submit a local fixture recipe to the already-running private Max session."""
from pathlib import Path
import argparse
import time
import uuid

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / "build/heavy-viewport-2026-10-02"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("script", type=Path)
    parser.add_argument("--timeout", type=float, default=240)
    args = parser.parse_args()
    if not (BASE / "transport-ready.txt").exists():
        raise SystemExit("Private Max transport is not ready")
    target = BASE / f"recipe-{args.script.stem}-{uuid.uuid4().hex[:8]}.ms"
    target.write_bytes(args.script.read_bytes())
    command = target.as_posix()
    temporary = BASE / "request-next.txt"
    temporary.write_text(command, encoding="utf-8")
    temporary.replace(BASE / "request.txt")
    deadline = time.monotonic() + args.timeout
    while time.monotonic() < deadline:
        response_file = BASE / "response.txt"
        response = response_file.read_text(encoding="utf-8-sig") if response_file.exists() else ""
        if command in response and response.startswith(("SUCCESS", "ERROR")):
            print(response)
            if response.startswith("ERROR"):
                raise SystemExit(1)
            return
        time.sleep(.25)
    raise SystemExit(f"Timed out; inspect the Max session and {BASE / 'response.txt'} before submitting another recipe")


if __name__ == "__main__":
    main()
