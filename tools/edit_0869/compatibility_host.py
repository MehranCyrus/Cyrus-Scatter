"""Owned 0.86.9 Max hosts. Publish each request once; observe timeouts.

The caller supplies a staged payload from package.py and explicit fixture inputs.
No normal Max profile is written, and a PID alone never authorizes a command.
"""
from pathlib import Path
import argparse
import json
import os
import re
import subprocess
import sys
import time
import uuid
import zipfile

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
QUALITY = ROOT / "tools/quality_validation"
sys.path.insert(0, str(ROOT / "tools/procedural_lab/layer_editor_071"))
from private_host import launch as private_launch
sys.path.insert(0, str(QUALITY))
from results import Expected, artifact_identity, read_result
sys.path.insert(0, str(HERE))
from package import verify_payload
from build_inputs import digest, verify_package_receipt


def owned_folder(path):
    path = Path(path).resolve()
    if not path.is_relative_to(ROOT / "build"):
        raise ValueError("An owned build profile is required")
    return path


def suite_paths(bindings=None):
    paths = {"fixture:" + p.name: p.resolve() for p in sorted(HERE.iterdir())
             if p.suffix in (".py", ".ms", ".cs", ".ps1")}
    for relative in ("tools/quality_validation/protocol.ms", "tools/quality_validation/results.py",
                     "tools/quality_validation/common.ms", "tools/mcp/development_transport.ms",
                     "tools/procedural_lab/layer_editor_071/private_host.py",
                     "tools/procedural_lab/source_container_preview/launch.py"):
        paths["driver:" + relative] = ROOT / relative
    for name, source in (bindings or {}).items():
        if not re.fullmatch(r"[a-zA-Z0-9_.-]+", name):
            raise ValueError("Unsafe binding name")
        paths["input:" + name] = Path(source).resolve()
    return paths


def command_line(pid):
    return subprocess.check_output(["powershell", "-NoProfile", "-Command",
        f'(Get-CimInstance Win32_Process -Filter "ProcessId={int(pid)}").CommandLine'], text=True).strip()


def verify_owned(folder, hashes=True):
    folder = owned_folder(folder)
    metadata = json.loads((folder / "qualification.json").read_text(encoding="utf-8"))
    current = command_line(metadata["pid"])
    expected = subprocess.list2cmdline(metadata["command"])
    if (not current or current.lower() != expected.lower()
            or str(folder / "max.ini").lower() not in current.lower()
            or f"3ds Max {metadata['max_year']}".lower() not in current.lower()):
        raise RuntimeError("Recorded owned Max command/profile no longer matches")
    if hashes:
        _, now = artifact_identity({n: Path(p) for n, p in metadata["paths"].items()})
        if now != metadata["hashes"]:
            raise RuntimeError("Bound product or fixture bytes changed: " + ", ".join(n for n in now if now[n] != metadata["hashes"].get(n)))
    return metadata


def prior_terminal(folder):
    pointer, response = folder / "dev-request.txt", folder / "dev-result.txt"
    if pointer.exists():
        previous = pointer.read_text(encoding="utf-8-sig")
        state = response.read_text(encoding="utf-8-sig") if response.exists() else ""
        if previous not in state or not state.startswith(("SUCCESS ", "ERROR ")):
            raise RuntimeError("Previous request remains unresolved; observe it before another mutation")


def wait_ready(folder, timeout=120):
    deadline = time.monotonic() + timeout
    while not (folder / "ready.json").is_file():
        if (folder / "startup-error.txt").is_file():
            raise RuntimeError((folder / "startup-error.txt").read_text(encoding="utf-8-sig"))
        if time.monotonic() >= deadline:
            raise TimeoutError("Startup unresolved; observe the recorded PID without launching a replacement")
        time.sleep(.15)


def launch_owned(folder, year, native, script=None, *, bindings=None, visible=False,
                 interactive_startup=False, require_edit_version=False, timeout=120):
    folder, native = owned_folder(folder), Path(native).resolve()
    payload = verify_payload(native, year)
    script = Path(script).resolve() if script is not None else native / "CyrusScatter.ms"
    if script.read_bytes() != (native / "CyrusScatter.ms").read_bytes():
        raise ValueError("Script differs from the staged exact pair")
    paths = {name: native / name for name in payload["files"]}
    paths["payload_manifest"] = native / "payload.json"
    paths.update(suite_paths(bindings))
    identity, hashes = artifact_identity(paths)
    extra = 'fileIn (MCPFixtureDir+"scripts/CyrusSurfaceAnalyzer.ms")\n'
    extra += f'global EWHostYear={year}\n'
    if require_edit_version:
        extra += 'if cyrusEditVersion==undefined or cyrusEditVersion()!=2 do throw "Missing 0.86.9 Edit interface"\n'
    process, launch = private_launch(folder, script, native, transport=True, max_year=year,
        visible=visible, silent_startup=not interactive_startup, extra_modules=("CyrusSurfaceAnalyzer.dlx",),
        script_assets=("CyrusGallery.dll", "CyrusSurfaceAnalyzer.ms"), extra=extra)
    origins = {name: str(path) for name, path in paths.items()}
    for name in payload["files"]:
        paths[name] = folder / ("scripts" if name in ("CyrusScatter.ms", "CyrusSurfaceAnalyzer.ms", "CyrusGallery.dll") else "bin") / name
        if artifact_identity({name: paths[name]})[1][name] != hashes[name]:
            raise RuntimeError("Private launch copy differs: " + name)
    metadata = {"schema": "cyrus.edit-host/1", "run_id": uuid.uuid4().hex, "artifact_id": identity,
                "pid": process.pid, "max_year": year, "command": launch["command"],
                "version": payload["version"], "analyzer_version": payload["analyzer_version"],
                "historical_baseline": payload.get("historical_baseline", False),
                "hashes": hashes, "paths": {n: str(p) for n, p in paths.items()}, "origins": origins,
                "bindings": {n: str(Path(p).resolve()) for n, p in (bindings or {}).items()},
                "require_edit_version": bool(require_edit_version), "artist_profile_modified": False}
    (folder / "qualification.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"pid": process.pid, "folder": str(folder), "max_year": year}), flush=True)
    wait_ready(folder, timeout)
    verify_owned(folder)
    return metadata


def bind_suite(folder, bindings=None):
    folder = owned_folder(folder)
    metadata = verify_owned(folder, hashes=False)
    prior_terminal(folder)
    paths = {n: Path(p) for n, p in metadata["paths"].items() if not n.startswith(("fixture:", "driver:", "input:"))}
    _, now = artifact_identity(paths)
    if any(now[n] != metadata["hashes"][n] for n in now):
        raise RuntimeError("Cannot rebind changed loaded product bytes")
    inputs = dict(metadata.get("bindings", {}))
    inputs.update(bindings or {})
    paths.update(suite_paths(inputs))
    identity, hashes = artifact_identity(paths)
    target = folder / "qualification.json"
    (folder / ("qualification-" + metadata["run_id"] + ".json")).write_bytes(target.read_bytes())
    metadata.update(parent_run_id=metadata["run_id"], run_id=uuid.uuid4().hex, artifact_id=identity,
                    paths={n: str(p) for n, p in paths.items()}, hashes=hashes,
                    bindings={n: str(Path(p).resolve()) for n, p in inputs.items()})
    target.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    return metadata


def bind_library(folder, registration):
    """Bind existing content through a copied registration, without copying assets."""
    folder, registration = owned_folder(folder), Path(registration).resolve()
    metadata = verify_owned(folder)
    prior_terminal(folder)
    data = registration.read_bytes()
    if len(data) > 16384:
        raise ValueError("Library registration exceeds its bound")
    fields = data.decode("utf-8-sig").splitlines()
    if len(fields) != 8 or fields[0] != "CyrusLibrary1" or int(fields[5]) > metadata["max_year"]:
        raise ValueError("Invalid or incompatible content registration")
    library = Path(fields[1]).resolve()
    catalog = library / "model-catalog.json"
    if digest(catalog) != fields[3]:
        raise ValueError("Existing content catalog differs from its registration")
    local_state, binding = folder / "library-state.txt", folder / "scripts/LibraryBinding.txt"
    if local_state.exists() or binding.exists():
        raise FileExistsError("Choose a fresh host or preserve/review its existing library binding")
    local_state.write_bytes(data)
    binding.write_text("CyrusLibraryBinding1\n" + str(local_state) + "\n", encoding="utf-8")
    return bind_suite(folder, {"library-state": local_state, "library-binding": binding, "library-catalog": catalog})


def bind_mzp_packages(folder, scatter_package, analyzer_package):
    """Select exact current archives for the owned MZP adapter scenario."""
    folder = owned_folder(folder)
    metadata = verify_owned(folder)
    prior_terminal(folder)
    config = {"schema": "cyrus.edit-mzp-config/1", "max_year": metadata["max_year"]}
    bindings = {}
    for product, path, version in (("scatter", scatter_package, "0.86.9"), ("analyzer", analyzer_package, "0.14.2")):
        path = Path(path).resolve()
        verify_package_receipt(path, ROOT)
        with zipfile.ZipFile(path) as archive:
            manifest = json.loads(archive.read("manifest.json"))
        if manifest["version"] != version or manifest["max_year"] != metadata["max_year"]:
            raise ValueError("MZP does not match the owned host")
        config[product] = {"path": str(path), "sha256": digest(path), "version": version}
        bindings[product + "-package"] = path
    target = folder / "mzp-config.json"
    if target.exists():
        raise FileExistsError("Preserve the previous MZP selection; use a fresh profile")
    target.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    bindings["mzp-config"] = target
    return bind_suite(folder, bindings)


def publish(folder, request):
    temporary = folder / ("pointer-" + uuid.uuid4().hex + ".tmp")
    temporary.write_text(request.as_posix(), encoding="utf-8-sig")
    deadline = time.monotonic() + 5
    while True:
        try:
            os.replace(temporary, folder / "dev-request.txt")
            return
        except PermissionError:
            if not temporary.exists() or time.monotonic() >= deadline:
                raise
            time.sleep(.05)


def run_case(folder, fixture, case, assertions, timeout=120, setup="", entrypoint="EWRun"):
    folder, fixture = owned_folder(folder), Path(fixture).resolve()
    if not 1 <= timeout <= 600 or not re.fullmatch(r"[A-Za-z0-9_-]+", case) or not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", entrypoint):
        raise ValueError("Invalid bounded scenario request")
    metadata = verify_owned(folder)
    prior_terminal(folder)
    if str(fixture) not in metadata["paths"].values():
        raise ValueError("Scenario fixture must be explicitly bound before execution")
    if not assertions or len(assertions) != len(set(assertions)):
        raise ValueError("A unique nonempty assertion manifest is required")
    request_id = uuid.uuid4().hex
    expected = Expected(metadata["run_id"], request_id, case, metadata["artifact_id"], tuple(assertions))
    wrapper = folder / ("case-" + request_id + ".ms")
    wrapper.write_text(f'global {entrypoint}\n' + setup + '\nfileIn @"' + fixture.as_posix() + '"\n' +
                       f'{entrypoint} "{case}"\n', encoding="utf-8-sig")
    result, request = folder / ("result-" + request_id + ".json"), folder / ("scenario-" + request_id + ".ms")
    prefix = f'global QRunID="{expected.run_id}",QRequestID="{request_id}",QScenarioID="{case}",QArtifactID="{expected.artifact_id}"\n'
    request.write_text(prefix + 'fileIn @"' + (QUALITY / "protocol.ms").as_posix() + '"\nQExecute @"' +
                       wrapper.as_posix() + '" @"' + result.as_posix() + '"\n', encoding="utf-8-sig")
    (folder / ("request-" + request_id + ".json")).write_text(json.dumps({**expected.__dict__, "fixture": str(fixture),
        "entrypoint": entrypoint, "wrapper_sha256": artifact_identity({"wrapper": wrapper})[1]["wrapper"]}, indent=2) + "\n", encoding="utf-8")
    publish(folder, request)
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            state = (folder / "dev-result.txt").read_text(encoding="utf-8-sig") if (folder / "dev-result.txt").exists() else ""
        except PermissionError:
            time.sleep(.1)
            continue
        if request.as_posix() in state:
            if not state.startswith("SUCCESS "):
                raise RuntimeError(state)
            outcome = read_result(result, expected)
            verify_owned(folder)
            return outcome
        time.sleep(.15)
    raise TimeoutError("Observe original request without replay: " + str(request))


def close_owned(folder, timeout=60):
    folder = owned_folder(folder)
    metadata = verify_owned(folder, hashes=False)
    prior_terminal(folder)
    request = folder / ("close-" + uuid.uuid4().hex + ".ms")
    request.write_text("quitMAX #noPrompt\n", encoding="utf-8-sig")
    publish(folder, request)
    deadline = time.monotonic() + timeout
    while True:
        current = command_line(metadata["pid"])
        if not current:
            break
        if current.lower() != subprocess.list2cmdline(metadata["command"]).lower():
            raise RuntimeError("Recorded owned Max command changed during close")
        if time.monotonic() >= deadline:
            raise TimeoutError("Owned close remains pending; observe its recorded PID")
        time.sleep(.2)
    (folder / "closed.json").write_text(json.dumps({"pid": metadata["pid"], "request": str(request), "status": "closed"}) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("launch", "run", "bind-suite", "observe", "close"))
    parser.add_argument("--folder", type=Path, required=True)
    parser.add_argument("--year", type=int, choices=(2024, 2026, 2027))
    parser.add_argument("--native", type=Path)
    parser.add_argument("--fixture", type=Path)
    parser.add_argument("--case")
    parser.add_argument("--assertion", action="append", default=[])
    parser.add_argument("--entrypoint", default="EWRun")
    parser.add_argument("--bind", action="append", default=[], help="NAME=explicit file input")
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--visible", action="store_true")
    parser.add_argument("--interactive-startup", action="store_true")
    parser.add_argument("--require-edit-version", action="store_true")
    args = parser.parse_args()
    folder, bindings = owned_folder(args.folder), dict(item.split("=", 1) for item in args.bind)
    if args.action == "launch":
        if args.year is None or args.native is None:
            parser.error("launch requires --year and --native")
        result = launch_owned(folder, args.year, args.native, bindings=bindings, visible=args.visible,
                              interactive_startup=args.interactive_startup, require_edit_version=args.require_edit_version, timeout=args.timeout)
    elif args.action == "bind-suite":
        result = bind_suite(folder, bindings)
    elif args.action == "run":
        if args.fixture is None or args.case is None:
            parser.error("run requires --fixture and --case")
        result = run_case(folder, args.fixture, args.case, args.assertion, args.timeout, entrypoint=args.entrypoint)
    elif args.action == "close":
        close_owned(folder)
        result = {"status": "closed"}
    else:
        result = {name: (folder / name).read_text(encoding="utf-8-sig") for name in ("startup-error.txt", "dev-result.txt") if (folder / name).exists()}
    print(json.dumps(result, indent=2), flush=True)


if __name__ == "__main__":
    main()
