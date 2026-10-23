"""Stage frozen host pairs or construct the 0.86.9 three-host installer.

This recipe never builds native modules, installs into Max, or copies content.
Original producer directories remain required by the version-2 receipts.
"""
from pathlib import Path
from types import SimpleNamespace
import argparse
import importlib.util
import json
import shutil
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
import build_inputs
import build_max

VERSION = "0.86.9"
ANALYZER_VERSION = "0.14.2"
YEARS = (2024, 2026, 2027)
SCATTER_NATIVE = ("AminScatter.dlx", "CyrusScatterEdit.dlm", "CyrusBrush.dlx", "CyrusBrushStorage.dlh")
ANALYZER_NATIVE = ("CyrusSurfaceAnalyzer.dlx",)
SCRIPTS = {"CyrusScatter.ms": ROOT / "AminScatter/scripts/AminScatterObject.ms",
           "CyrusSurfaceAnalyzer.ms": ROOT / "CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms"}


def owned_output(path):
    path = Path(path).resolve()
    if not path.is_relative_to(ROOT / "build") and not path.is_relative_to(ROOT / "dist"):
        raise ValueError("A fresh owned build/dist output is required")
    if path.exists():
        raise FileExistsError(path)
    return path


def copy_artifact(source, destination, sidecars=()):
    source, destination = Path(source), Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    for original, target in [(source, destination), *[(source.with_suffix(s), destination.with_suffix(s)) for s in sidecars]]:
        if target.exists():
            raise FileExistsError(target)
        shutil.copy2(original, target)
        if build_inputs.digest(original) != build_inputs.digest(target):
            raise ValueError("Staged bytes differ: " + str(original))


def verify_pair(year, scatter, analyzer):
    if year not in YEARS or build_max.scatter_version() != VERSION:
        raise ValueError("Expected the frozen 0.86.9 product source and a supported host")
    scatter, analyzer = Path(scatter).resolve(), Path(analyzer).resolve()
    receipts = {"AminScatter": scatter / "receipt.json", "CyrusSurfaceAnalyzer": analyzer / "receipt.json"}
    for project, directory, names in (("AminScatter", scatter, SCATTER_NATIVE),
                                      ("CyrusSurfaceAnalyzer", analyzer, ANALYZER_NATIVE)):
        build_max.verify_native_receipt(receipts[project], project, year, {n: directory / n for n in names})
        for name in names:
            build_max.reject_development_binary(name, (directory / name).read_bytes())
    build_max.verify_gallery(scatter / "CyrusGallery.dll", VERSION, year)
    return receipts


def stage_payload(output, year, scatter, analyzer):
    """Create a flat, exact pair consumed by compatibility_host.launch_owned."""
    output = owned_output(output)
    scatter, analyzer = Path(scatter).resolve(), Path(analyzer).resolve()
    receipts = verify_pair(year, scatter, analyzer)
    recipe_hash = build_inputs.digest(Path(__file__))
    before = {p: build_inputs.digest(p) for p in (*receipts.values(), *SCRIPTS.values())}
    output.mkdir(parents=True)
    origins = {name: scatter / name for name in SCATTER_NATIVE}
    origins.update({name: analyzer / name for name in ANALYZER_NATIVE})
    origins.update(SCRIPTS)
    origins["CyrusGallery.dll"] = scatter / "CyrusGallery.dll"
    for name, source in origins.items():
        sidecars = (".build.json", ".build.log", ".identity.cs") if name == "CyrusGallery.dll" else ()
        copy_artifact(source, output / name, sidecars)
    verify_pair(year, scatter, analyzer)
    if any(build_inputs.digest(path) != value for path, value in before.items()) or build_inputs.digest(Path(__file__)) != recipe_hash:
        raise ValueError("A producer changed while staging")
    manifest = {"schema": "cyrus.edit-host-payload/1", "status": "complete", "max_year": year,
                "version": VERSION, "analyzer_version": ANALYZER_VERSION,
                "files": {n: build_inputs.digest(output / n) for n in origins},
                "origins": {n: str(p) for n, p in origins.items()},
                "native_receipts": {p: {"path": str(r), "sha256": build_inputs.digest(r)} for p, r in receipts.items()},
                "recipe_sha256": recipe_hash, "qualification": "Staging identity only; no host launched"}
    (output / "payload.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def stage_package_payload(output, year, scatter_package, analyzer_package, historical=False):
    """Stage exact package bytes; historical mode is for baseline scenes only."""
    output = owned_output(output)
    archives, origins, files = {}, {}, {}
    recipe_hash = build_inputs.digest(Path(__file__))
    versions = {}
    for product, package, names in (("scatter", Path(scatter_package).resolve(), (*SCATTER_NATIVE, "CyrusScatter.ms", "CyrusGallery.dll")),
                                    ("analyzer", Path(analyzer_package).resolve(), (*ANALYZER_NATIVE, "CyrusSurfaceAnalyzer.ms"))):
        with zipfile.ZipFile(package) as archive:
            manifest = json.loads(archive.read("manifest.json"))
            if (archive.testzip() is not None or len(archive.namelist()) != len(set(archive.namelist()))
                    or set(archive.namelist()) != set(manifest["files"]) | {"manifest.json"}
                    or manifest["max_year"] != year):
                raise ValueError("Invalid or wrong-host archive: " + str(package))
            for name, expected in manifest["files"].items():
                if build_max.sha(archive.read(name)) != expected:
                    raise ValueError("Package member differs: " + name)
            if not historical:
                build_inputs.verify_package_receipt(package, ROOT)
            else:
                receipt = json.loads(package.with_suffix(".build.json").read_text(encoding="utf-8"))
                if (receipt.get("schema") != "cyrus.package-build/2" or receipt.get("status") != "complete"
                        or receipt.get("artifact_sha256") != build_inputs.digest(package)
                        or receipt.get("producer_receipts") != manifest.get("producer_receipts")):
                    raise ValueError("Historical package lacks a matching completed v2 producer receipt")
            versions[product] = manifest["version"]
            for name in names:
                files[name] = archive.read(name)
                origins[name] = str(package) + "!" + name
            archives[product] = {"path": str(package), "sha256": build_inputs.digest(package),
                                 "receipt_sha256": build_inputs.digest(package.with_suffix(".build.json"))}
    if year not in YEARS or (not historical and versions != {"scatter": VERSION, "analyzer": ANALYZER_VERSION}):
        raise ValueError("Only the exact current versions may stage for delivery qualification")
    for name in (*SCATTER_NATIVE, *ANALYZER_NATIVE):
        build_max.reject_development_binary(name, files[name])
    output.mkdir(parents=True)
    for name, data in files.items():
        (output / name).write_bytes(data)
    if build_inputs.digest(Path(__file__)) != recipe_hash:
        raise ValueError("Staging recipe changed during execution")
    manifest = {"schema": "cyrus.edit-host-payload/1", "status": "complete", "max_year": year,
                "version": versions["scatter"], "analyzer_version": versions["analyzer"], "historical_baseline": historical,
                "files": {n: build_inputs.digest(output / n) for n in files}, "origins": origins,
                "packages": archives, "recipe_sha256": recipe_hash,
                "qualification": "Historical baseline only" if historical else "Exact package staging; host acceptance pending"}
    (output / "payload.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def verify_payload(folder, year=None, current_producers=True):
    folder = Path(folder).resolve()
    manifest = json.loads((folder / "payload.json").read_text(encoding="utf-8"))
    required = {*SCATTER_NATIVE, *ANALYZER_NATIVE, *SCRIPTS, "CyrusGallery.dll"}
    if (manifest.get("schema") != "cyrus.edit-host-payload/1" or manifest.get("status") != "complete"
            or manifest.get("max_year") not in YEARS or (year is not None and manifest["max_year"] != year)
            or (not manifest.get("historical_baseline") and (manifest.get("version") != VERSION or manifest.get("analyzer_version") != ANALYZER_VERSION))
            or set(manifest.get("files", {})) != required):
        raise ValueError("Incomplete or mismatched staged host payload")
    for name, expected in manifest["files"].items():
        if build_inputs.digest(folder / name) != expected:
            raise ValueError("Staged payload differs: " + name)
    for entry in manifest.get("native_receipts", {}).values():
        if build_inputs.digest(entry["path"]) != entry["sha256"]:
            raise ValueError("Original native receipt changed")
    if "packages" in manifest:
        for entry in manifest["packages"].values():
            package = Path(entry["path"])
            if (build_inputs.digest(package) != entry["sha256"]
                    or build_inputs.digest(package.with_suffix(".build.json")) != entry["receipt_sha256"]):
                raise ValueError("Original package or receipt changed")
            if current_producers and not manifest.get("historical_baseline"):
                build_inputs.verify_package_receipt(package, ROOT)
    elif current_producers:
        receipts = manifest["native_receipts"]
        verify_pair(manifest["max_year"], Path(receipts["AminScatter"]["path"]).parent,
                    Path(receipts["CyrusSurfaceAnalyzer"]["path"]).parent)
        for name, original in manifest["origins"].items():
            if build_inputs.digest(original) != manifest["files"][name]:
                raise ValueError("Staged payload no longer matches its producer: " + name)
    return manifest


def build_delivery(output, scatter_builds, analyzer_builds, core, content):
    recipe_hash = build_inputs.digest(Path(__file__))
    if set(scatter_builds) != set(YEARS) or set(analyzer_builds) != set(YEARS):
        raise ValueError("The combined delivery requires distinct builds for 2024, 2026 and 2027")
    if len({Path(p).resolve() for p in scatter_builds.values()}) != 3 or len({Path(p).resolve() for p in analyzer_builds.values()}) != 3:
        raise ValueError("A native producer directory cannot be reused across SDK years")
    output, core, content = owned_output(output), Path(core).resolve(), Path(content).resolve()
    build_max.verify_installer(core)
    for year in YEARS:
        verify_pair(year, scatter_builds[year], analyzer_builds[year])
    output.mkdir(parents=True)
    receipt_path = output / "recipe-receipt.json"
    receipt_path.write_text(json.dumps({"status": "pending", "version": VERSION}) + "\n", encoding="utf-8")
    artifacts = output / "artifacts"
    scatter_packages, analyzer_packages, producers = [], [], {}
    for year in YEARS:
        scatter, analyzer = Path(scatter_builds[year]).resolve(), Path(analyzer_builds[year]).resolve()
        receipts = verify_pair(year, scatter, analyzer)
        stage = output / "staging" / str(year)
        copy_artifact(core, stage / "AminScatter/CyrusInstaller.dll", (".build.json", ".build.log"))
        for name in SCATTER_NATIVE:
            copy_artifact(scatter / name, stage / "AminScatter" / name)
        copy_artifact(scatter / "CyrusGallery.dll", stage / "AminScatter/CyrusGallery.dll", (".build.json", ".build.log", ".identity.cs"))
        copy_artifact(analyzer / ANALYZER_NATIVE[0], stage / "CyrusSurfaceAnalyzer" / ANALYZER_NATIVE[0])
        for project, path in receipts.items():
            copy_artifact(path, stage / project / "receipt.json")
        args = SimpleNamespace(max_year=year, tools_version="14.38.33130", windows_sdk="10.0.19041.0",
                               team_trust_header=ROOT / "CyrusLicensing/team/team_public_key.h", output=artifacts,
                               content_dir=content, native_receipts=receipts)
        build_max.package("CyrusSurfaceAnalyzer", "Cyrus Surface Analyzer", ANALYZER_VERSION,
                          list(ANALYZER_NATIVE), "CyrusSurfaceAnalyzer.ms", args, stage)
        build_max.package("AminScatter", "Cyrus Scatter", VERSION, list(SCATTER_NATIVE), "AminScatterObject.ms", args, stage)
        scatter_packages.append(artifacts / f"CyrusScatter-{VERSION}-Max{year}.mzp")
        analyzer_packages.append(artifacts / f"CyrusSurfaceAnalyzer-{ANALYZER_VERSION}-Max{year}.mzp")
        producers[str(year)] = {p: {"path": str(r), "sha256": build_inputs.digest(r)} for p, r in receipts.items()}
    spec = importlib.util.spec_from_file_location("edit_delivery_installer", ROOT / "AminScatter/tools/build_installer.py")
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    executable = artifacts / f"CyrusScatter-{VERSION}-Setup.exe"
    builder.build_exe(executable, scatter_packages, core, analyzer_packages)
    for year in YEARS:
        verify_pair(year, scatter_builds[year], analyzer_builds[year])
    build_max.verify_installer(core)
    for package in scatter_packages + analyzer_packages:
        build_inputs.verify_package_receipt(package, ROOT)
        with zipfile.ZipFile(package) as archive:
            if archive.testzip() is not None:
                raise ValueError("Archive integrity failure: " + str(package))
    exe_receipt = build_inputs.verify_managed(executable, "installer-exe", ROOT)
    if exe_receipt.get("max_years") != list(YEARS):
        raise ValueError("EXE does not advertise exactly the three requested hosts")
    if build_inputs.digest(Path(__file__)) != recipe_hash:
        raise ValueError("Delivery recipe changed during execution")
    receipt = {"schema": "cyrus.edit-delivery/1", "status": "complete", "version": VERSION,
               "analyzer_version": ANALYZER_VERSION, "max_years": list(YEARS),
               "native_producers": producers, "core": {"path": str(core), "sha256": build_inputs.digest(core),
               "receipt_sha256": build_inputs.digest(core.with_suffix(".build.json"))},
               "files": {p.name: build_inputs.digest(p) for p in sorted(artifacts.iterdir()) if p.is_file()},
               "recipe_sha256": recipe_hash, "content_copied": False,
               "host_launched": False, "artist_install": False, "qualification": "Pending exact package and host acceptance"}
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    return receipt


def build_map(values):
    result = {}
    for value in values:
        year, path = value.split("=", 1)
        year = int(year)
        if year in result or year not in YEARS:
            raise ValueError("Duplicate or unsupported host in build map")
        result[year] = Path(path).resolve()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_subparsers(dest="action", required=True)
    stage = actions.add_parser("stage")
    stage.add_argument("--year", type=int, choices=YEARS, required=True)
    stage.add_argument("--scatter-output", type=Path, required=True)
    stage.add_argument("--analyzer-output", type=Path, required=True)
    stage.add_argument("--output", type=Path, required=True)
    archive = actions.add_parser("stage-packages")
    archive.add_argument("--year", type=int, choices=YEARS, required=True)
    archive.add_argument("--scatter-package", type=Path, required=True)
    archive.add_argument("--analyzer-package", type=Path, required=True)
    archive.add_argument("--historical-baseline", action="store_true")
    archive.add_argument("--output", type=Path, required=True)
    package = actions.add_parser("package")
    package.add_argument("--scatter", action="append", required=True, help="YEAR=original native producer directory")
    package.add_argument("--analyzer", action="append", required=True, help="YEAR=original native producer directory")
    package.add_argument("--core", type=Path, required=True)
    package.add_argument("--content-dir", type=Path, default=ROOT / "dist/CyrusScatter-0.86.7-20261020/Content")
    package.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.action == "stage":
        result = stage_payload(args.output, args.year, args.scatter_output, args.analyzer_output)
    elif args.action == "stage-packages":
        result = stage_package_payload(args.output, args.year, args.scatter_package, args.analyzer_package, args.historical_baseline)
    else:
        result = build_delivery(args.output, build_map(args.scatter), build_map(args.analyzer), args.core, args.content_dir)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
