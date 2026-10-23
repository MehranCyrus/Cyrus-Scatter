"""Execute exact MZP adapters only in a bound, redirected owned Max process."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import traceback
import zipfile
from pymxs import runtime as r
try:
    from PySide6 import QtCore, QtWidgets
except ImportError:
    from PySide2 import QtCore, QtWidgets

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.is_relative_to(ROOT / "build")
YEAR = int(r.maxVersion()[0]) // 1000 + 1998
digest = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
metadata = json.loads((OUT / "qualification.json").read_text(encoding="utf-8"))
config_path = OUT / "mzp-config.json"
assert Path(metadata["paths"]["input:mzp-config"]).resolve() == config_path
assert metadata["hashes"]["input:mzp-config"] == digest(config_path)
config = json.loads(config_path.read_text(encoding="utf-8"))
assert config["schema"] == "cyrus.edit-mzp-config/1" and config["max_year"] == YEAR == metadata["max_year"]
assert str(r.QScenarioID) == "EC-I"
scripts, startup, macros = [Path(str(r.getDir(r.Name(n)))).resolve() for n in ("userScripts", "userStartupScripts", "userMacros")]
profile = Path(str(r.getMAXIniFile())).resolve().parent
assert all(p.is_relative_to(OUT) for p in (scripts, startup, macros, profile))
assert all(Path(os.environ[k]).resolve().is_relative_to(OUT) for k in ("ADSK_3DSMAX_APPDATA_DIR", "ADSK_3DSMAX_USERSETTINGS_DIR", "ADSK_3DSMAX_USERTOOLS_DIR"))
ini = profile / "Plugin.UserSettings.ini"
report = OUT / ("mzp-result-" + str(r.QRequestID) + ".json")
result = {"schema": "cyrus.edit-mzp-install/1", "status": "running", "max_year": YEAR,
          "request_id": str(r.QRequestID), "run_id": str(r.QRunID), "config_sha256": digest(config_path),
          "checks": [], "notices": [], "artist_install": False}


def save():
    report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")


def check(value, index, detail):
    name = "EC-I-" + str(index).zfill(2)
    result["checks"].append({"id": name, "pass": bool(value), "detail": detail})
    save()
    r.QAssert(bool(value), name, detail)


def notice():
    for widget in QtWidgets.QApplication.topLevelWidgets():
        if isinstance(widget, QtWidgets.QMessageBox) and widget.isVisible() and widget.windowTitle().startswith(("Cyrus Scatter", "Cyrus Surface Analyzer", "Surface Analyzer")):
            result["notices"].append({"title": widget.windowTitle(), "text": widget.text()})
            save()
            widget.accept()


def extract(product):
    descriptor = config[product]
    archive_path = Path(descriptor["path"])
    assert digest(archive_path) == descriptor["sha256"]
    output = OUT / ("mzp-" + product + "-" + str(r.QRequestID))
    output.mkdir()
    with zipfile.ZipFile(archive_path) as archive:
        manifest = json.loads(archive.read("manifest.json"))
        assert manifest["version"] == descriptor["version"] and manifest["max_year"] == YEAR
        assert archive.testzip() is None and len(archive.namelist()) == len(set(archive.namelist()))
        assert set(archive.namelist()) == set(manifest["files"]) | {"manifest.json"}
        assert len(archive.infolist()) <= 520 and sum(i.file_size for i in archive.infolist()) <= 512 * 1024 * 1024
        for name, expected in manifest["files"].items():
            target = (output / name).resolve()
            assert target.is_relative_to(output) and not Path(name).is_absolute()
            raw = archive.read(name)
            assert len(raw) <= 128 * 1024 * 1024 and hashlib.sha256(raw).hexdigest() == expected
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(raw)
    return output, manifest


def snapshot():
    # Excludes installer failure logs and extraction; all registration/script/
    # runtime bytes are protected. Runtime directories may remain after refusal.
    roots = [scripts, startup, macros, profile / "cs/r"]
    values = {str(ini): digest(ini) if ini.exists() else None}
    for base in roots:
        if base.exists():
            for path in base.rglob("*"):
                if path.is_file():
                    values[str(path)] = digest(path)
    return values


def control(payload, label, filename, transform):
    output = OUT / ("control-" + label + "-" + str(r.QRequestID))
    shutil.copytree(payload, output)
    path = output / filename
    before = path.read_bytes()
    after = transform(before)
    assert after != before
    path.write_bytes(after)
    return output


def install(payload):
    before = len(result["notices"])
    r.execute('ECMzpClicked=false; ECMzpStatus=""; ECMzpDetails=""; ECMzpDeadline=timeStamp()+90000')
    r.fileIn(str(payload / "install.ms"))
    return {"status": str(r.ECMzpStatus), "details": str(r.ECMzpDetails), "notices": result["notices"][before:]}


timer = QtCore.QTimer()
r.execute('''
global ECMzpTimer,ECMzpTick,ECMzpClicked=false,ECMzpStatus="",ECMzpDetails="",ECMzpDeadline=0
fn ECMzpTick sender event = (
 local forms=(dotNetClass "System.Windows.Forms.Application").OpenForms
 if forms.Count>64 do throw "Owned form inspection exceeds allowance"
 for i=0 to forms.Count-1 do (
  local window=forms.Item[i]
  if window.Text=="Cyrus Scatter 0.86.9" do (
   local view=undefined
   for j=0 to window.Controls.Count-1 do (
    local candidate=window.Controls.Item[j]
    if (candidate.GetType()).FullName=="Cyrus.Setup.InstallerView" do view=candidate
   )
   if view!=undefined do (
    if not ECMzpClicked then (
     ECMzpClicked=true
     (dotNetClass "System.Threading.SynchronizationContext").SetSynchronizationContext (dotNetObject "System.Windows.Forms.WindowsFormsSynchronizationContext")
     view.Primary.PerformClick()
    ) else if view.Primary.Enabled then (
     ECMzpStatus=view.Status.Text;ECMzpDetails=view.Details.Text
     if matchPattern ECMzpStatus pattern:"Installation completed*" or matchPattern ECMzpStatus pattern:"Installation could not finish*" or matchPattern ECMzpStatus pattern:"Cancelled*" do (window.Close();return true)
    ) else if timeStamp()>ECMzpDeadline do view.CloseButton.PerformClick()
   )
  )
 )
)
ECMzpTimer=dotNetObject "System.Windows.Forms.Timer"
ECMzpTimer.Interval=50
dotNet.addEventHandler ECMzpTimer "Tick" ECMzpTick
ECMzpTimer.Start()
''')
try:
    timer.timeout.connect(notice)
    timer.start(40)
    scatter, scatter_manifest = extract("scatter")
    analyzer, analyzer_manifest = extract("analyzer")
    assert not (scripts / "CyrusScatter/installed.txt").exists() and not (scripts / "CyrusSurfaceAnalyzer/installed.txt").exists()
    before = snapshot()
    needle = ("(maxVersion())[1]!=" + str((YEAR - 1998) * 1000)).encode()
    wrong = control(scatter, "scatter-host", "install.ms", lambda b: b.replace(needle, b"(maxVersion())[1]!=25000", 1))
    reply = install(wrong)
    check(any("requires 3ds Max" in n["text"] for n in reply["notices"]) and snapshot() == before, 1, "Wrong-host Scatter control refuses before registration")
    wrong = control(analyzer, "analyzer-host", "install.ms", lambda b: b.replace(needle, b"(maxVersion())[1]!=25000", 1))
    reply = install(wrong)
    check(any("requires 3ds Max" in n["text"] for n in reply["notices"]) and snapshot() == before, 2, "Wrong-host Analyzer control refuses before registration")
    reply = install(scatter)
    scatter_receipt = (scripts / "CyrusScatter/installed.txt").read_text(encoding="utf-8-sig").splitlines()
    scatter_runtime = Path(scatter_receipt[2]).resolve()
    assert scatter_runtime.is_relative_to(OUT)
    same = all(digest(scatter_runtime / ("bin/" + n if n.endswith((".dlx", ".dlm", ".dlh")) else n)) == scatter_manifest["files"][n]
               for n in ("AminScatter.dlx", "CyrusScatterEdit.dlm", "CyrusBrush.dlx", "CyrusBrushStorage.dlh", "CyrusGallery.dll", "CyrusScatter.ms"))
    check(reply["status"].startswith("Installation completed") and scatter_receipt[1] == "0.86.9" and same, 3, "Exact Scatter MZP actual Install button publishes every matched payload in owned runtime")
    # Recognized loose startup repair exercises v2 Flush/verify/publication in
    # this Max runtime while preserving an old poisoned final backup.
    wrapper = startup / "CyrusSurfaceAnalyzerStartup.ms"
    original = (analyzer / wrapper.name).read_bytes()
    wrapper.write_bytes(original)
    poison = scripts / "CyrusSurfaceAnalyzer/Backups" / ("startup-" + hashlib.sha256(original).hexdigest() + ".ms")
    poison.parent.mkdir(parents=True)
    poison.write_bytes(b"owned interrupted old backup")
    reply = install(analyzer)
    backup = poison.parent / "v2" / poison.name
    record = backup.with_suffix(".txt")
    check(any("0.14.2 installed" in n["text"] for n in reply["notices"]) and backup.read_bytes() == original
          and poison.read_bytes() == b"owned interrupted old backup" and str(poison) in record.read_text(encoding="utf-8-sig"), 4,
          "Exact Analyzer MZP repairs recognized startup with verified v2 backup while retaining poisoned legacy bytes")
    analyzer_receipt = (scripts / "CyrusSurfaceAnalyzer/installed.txt").read_text(encoding="utf-8-sig").splitlines()
    analyzer_runtime = scripts / "CyrusSurfaceAnalyzer/r" / analyzer_receipt[3]
    check(analyzer_receipt[1:3] == [str(YEAR), "0.14.2"] and digest(analyzer_runtime / "bin/CyrusSurfaceAnalyzer.dlx") == analyzer_manifest["files"]["CyrusSurfaceAnalyzer.dlx"]
          and digest(analyzer_runtime / "CyrusSurfaceAnalyzer.ms") == analyzer_manifest["files"]["CyrusSurfaceAnalyzer.ms"], 5,
          "Independent Analyzer receipt and installed native/script identify the exact host package")
    before = snapshot()
    scatter_repeat, analyzer_repeat = install(scatter), install(analyzer)
    check(scatter_repeat["status"].startswith("Installation completed") and any("0.14.2 installed" in n["text"] for n in analyzer_repeat["notices"]) and snapshot() == before, 6,
          "Repeated exact MZPs preserve all registrations, payloads and backups")
    tampered = control(analyzer, "helper", "CyrusInstaller.dll", lambda b: b + b"owned tamper")
    reply = install(tampered)
    check(any("helper differs" in n["text"] for n in reply["notices"]) and snapshot() == before, 7, "Analyzer helper hash refusal preserves current installation")
    saved_ini = ini.read_bytes()
    r.setINISetting(str(ini), "Directories", "CyrusScatter" + str(YEAR), str(OUT / "custom-plugin"))
    custom = snapshot()
    reply = install(scatter)
    check(reply["status"].startswith("Installation could not finish") and snapshot() == custom, 8, "Actual Scatter MZP preserves an unknown custom registration")
    ini.write_bytes(saved_ini)
    result.update(status="passed", scatter_runtime=str(scatter_runtime), analyzer_runtime=str(analyzer_runtime),
                  scatter_sha256=config["scatter"]["sha256"], analyzer_sha256=config["analyzer"]["sha256"])
except Exception:
    result.update(status="failed", error=traceback.format_exc())
    raise
finally:
    timer.stop()
    timer.deleteLater()
    r.execute('ECMzpTimer.Stop(); dotNet.removeAllEventHandlers ECMzpTimer; ECMzpTimer.Dispose(); ECMzpTimer=undefined')
    save()
