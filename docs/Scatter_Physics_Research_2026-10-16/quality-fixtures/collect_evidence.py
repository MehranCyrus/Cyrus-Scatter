"""Verify final local evidence and collect a scoped 0.1.8 delivery receipt."""
from pathlib import Path
import hashlib
import json
import zipfile
import subprocess

ROOT = Path(__file__).resolve().parents[3]
DOC = Path(__file__).resolve().parent.parent
BUILD = ROOT / "build/physics-quality-018-20261018-01"
NATIVE = BUILD / "native-01"
DIST = ROOT / "dist/CyrusPhysicsLab-0.1.8-20261018-03"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def runtime(folder, diagnostics="diagnostics"):
    errors = list((folder / diagnostics).rglob("exception.txt"))
    assert errors and all(p.stat().st_size == 0 for p in errors), errors
    paths = list((folder / diagnostics).rglob("process-exit.json"))
    assert paths, folder
    rows = [read(p) for p in paths]
    assert all(r["exit_code"] == 0 and r["exception_notifications"] == 0 for r in rows), rows
    return {"exit_records": rows, "exception_files_empty": True}


def main():
    receipt = read(NATIVE / "receipt.json")
    assert receipt["version"] == "0.1.8" and receipt["max_year"] == 2027 and not receipt["faults"]
    for name, expected in receipt["source_hashes"].items():
        assert sha(ROOT / "CyrusPhysicsLab" / name) == expected, name
    for name, expected in receipt["shared_source_hashes"].items():
        assert sha(ROOT / name) == expected, name
    for name, expected in receipt["binaries"].items():
        assert sha(NATIVE / name) == expected, name
    assert "100% tests passed, 0 tests failed out of 6" in (NATIVE / "tests.log").read_text()
    quality = read(NATIVE / "quality-results.json")
    assert quality["pass"] and quality["rolling_sphere_mountain"]["interior_tunnels"] == 0

    package = read(DIST / "package.json")
    archive = Path(package["package"])
    assert sha(archive) == package["package_sha256"]
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        manifest = json.loads(z.read("manifest.json"))
        assert manifest["version"] == "0.1.8" and manifest["max_year"] == 2027
        for name, expected in manifest["payload"].items():
            assert hashlib.sha256(z.read(name)).hexdigest() == expected, name
        assert "licenses/VHACD-BSD-3-Clause.txt" in z.namelist()
        assert b"(maxVersion())[1]!=29000" in z.read("install.ms")
        assert set(n for n in z.namelist() if n.lower().endswith((".dlx", ".dlh"))) == {
            "native/CyrusPhysicsLab.dlx", "native/CyrusPhysicsStorage.dlh"}

    names = {"mountain": "physics-lab-quality-018-mountain-06",
             "reopen": "physics-lab-quality-018-reopen-02",
             "layout150": "physics-lab-quality-018-list150-02"}
    script = sha(ROOT / "CyrusPhysicsLab/scripts/CyrusPhysicsLab.ms")
    hosts = {}
    for key, name in names.items():
        folder = ROOT / "build" / name
        launch = read(folder / "launch.json")
        assert launch["max_year"] == 2027 and not launch["computer_use"]
        assert (folder / "completed.json").exists() and not (folder / "error.txt").exists()
        for binary, digest in launch["binaries"].items():
            assert digest == receipt["binaries"][binary]
        if key != "reopen":
            assert launch["script_sha256"] == script
        else:
            # The fresh scene was saved before the final label shortening.
            old = (folder / "scripts/CyrusPhysicsLab.ms").read_text(encoding="utf-8-sig")
            current = (ROOT / "CyrusPhysicsLab/scripts/CyrusPhysicsLab.ms").read_text(encoding="utf-8-sig")
            old = old.replace('items:#("Fast - single hull","Balanced - compound","Detailed - compound")',
                              'items:#("Fast","Balanced","Detailed")')
            old = old.replace('dropdownlist qualityList "" items:#("Fast","Balanced","Detailed") pos:[8,100] width:160',
                              'dropdownlist qualityList "" items:#("Fast","Balanced","Detailed") pos:[8,100] width:160 tooltip:"Fast uses one hull. Balanced and Detailed can use several convex pieces. Already convex solids keep one hull. All modes approximate the model."')
            assert old == current, "Reopen script differs beyond the recorded label/tooltip-only change"
        layout = read(folder / "ui-layout.json")
        assert len(layout) == 7 and not any(r["overlaps"] for r in layout)
        assert all(c["inside"] and c["glyphs_fit"] for r in layout for c in r["controls"])
        hosts[key] = {"folder": str(folder), "launch": launch, "runtime": runtime(folder)}
        if (folder / "checked-list-layout.json").exists():
            hosts[key]["managed_list"] = read(folder / "checked-list-layout.json")

    installed = ROOT / "build/physics-lab-quality-018-installed-02"
    install = read(installed / "installer-receipt.json")
    assert install["pass"] and install["package_sha256"] == package["package_sha256"]
    assert install["installed_script_sha256"] == script
    for name, record in install["installed_pair"].items():
        assert record["sha256"] == receipt["binaries"][name]
    assert (installed / "restart-completed.json").exists()
    assert not (installed / "restart-error.txt").exists()
    assert (installed / "ready-assertions.txt").read_text().startswith("PASS 19 ")
    for row in read(installed / "ui-layout.json"):
        assert not row["overlaps"] and all(c["inside"] and c["glyphs_fit"] for c in row["controls"])
    stroke = read(installed / "ready-scene-stroke.json")
    assert len(stroke["rows"]) > 1 and {r["source"] for r in stroke["rows"]} == {1}

    replay = read(BUILD / "replay-04/receipt.json")
    assert replay["no_interior_tunnels"] and len(replay["cases"]) == 11
    assert replay["core_library_sha256"] == sha(NATIVE / "cpl_core.lib")
    assert all(not r["ever_left"] and not r["wholly_below"] and r["final_normal_depth_m"] < .01
               for r in replay["cases"])
    # Freeze intentionally copies moving poses; retain, rather than hide, those
    # measurements. The endpoint gate above is distinct from immediate Freeze.
    frozen_over_10mm = [r for r in replay["cases"] if r["published_normal_depth_m"] >= .01]
    assert replay["palette_sphere_only"] and replay["palette_mixed_all_three"]

    scenes = read(DIST / "scenes.json")
    for name, data in scenes.items():
        assert sha(DIST / name) == sha(Path(data["source"])) == data["sha256"]
    original = ROOT / "Test Scene/Mountain Scene Brush Test.max"
    assert sha(original) == read(BUILD / "baseline.json")["scene_sha256"]
    normal = Path.home() / "AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini"
    assert all(h["launch"]["profile_template_sha256"] == sha(normal) for h in hosts.values())

    snapshot = BUILD / "final-source-018.zip"
    with zipfile.ZipFile(snapshot, "w", zipfile.ZIP_DEFLATED) as z:
        for path in (ROOT / "CyrusPhysicsLab").rglob("*"):
            if path.is_file() and "__pycache__" not in path.parts:
                z.write(path, path.relative_to(ROOT).as_posix())
    report = {"pass": True, "product": "CyrusPhysicsLab", "version": "0.1.8",
              "max_year": 2027, "computer_use": False, "artist_installation": False,
              "integrated_into_scatter": False,
              "git_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
              "dirty_untracked_sources": True, "build": receipt, "quality_suite": quality,
              "source_snapshot": {"path": str(snapshot), "sha256": sha(snapshot)},
              "package": package, "scenes": scenes, "original_scene_sha256": sha(original),
              "hosts": hosts, "installed": install,
              "installed_runtime": runtime(installed, "restart-diagnostics"),
              "installed_managed_list": read(installed / "checked-list-layout.json"),
              "replay": replay,
              "frozen_publications_over_10mm": frozen_over_10mm,
              "assertions": {"mountain": (ROOT / "build" / names["mountain"] / "assertions.txt").read_text(),
                             "reopen": (ROOT / "build" / names["reopen"] / "reopen-assertions.txt").read_text(),
                             "installed": (installed / "ready-assertions.txt").read_text()},
              "limits": ["16-piece teapot handle opening remains filled", "Three Detailed Finish attempts needed Freeze",
                         "Rounding error <=1mm before instance scale", "Immediate Frozen moving poses can exceed 10mm normal depth",
                         "Physical mouse/pixels/presented FPS not tested"]}
    (DOC / "COLLISION_QUALITY_018_EVIDENCE.json").write_text(json.dumps(report, indent=2) + "\n")
    print("PASS final source/pair/package/scene/host/installed/replay evidence")


if __name__ == "__main__":
    main()
