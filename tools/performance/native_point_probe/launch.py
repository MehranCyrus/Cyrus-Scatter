"""Launch an isolated interactive Max 2027 point-display experiment.

Does not load or save the artist scene, change installers, or modify user startup.
The visible app is intentional: viewport appearance and navigation must be inspected.
"""
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / "build/heavy-viewport-2026-10-02"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    BASE.mkdir(parents=True, exist_ok=True)
    if (BASE / "launch.json").exists():
        raise SystemExit("A launch record already exists. Inspect the existing session before launching again.")
    for name in ["startup", "plugcfg", "temp"]:
        (BASE / name).mkdir(exist_ok=True)
    config_source = ROOT / "build/viewport-round2-2026-10-01/desktop.ini"
    config = config_source.read_text(encoding="utf-16")
    for key, target in {"Additional Startup Scripts": BASE / "startup", "PlugCFG": BASE / "plugcfg", "Temp": BASE / "temp", "Page File": BASE / "temp"}.items():
        config = re.sub(rf"(?m)^{re.escape(key)}=.*$", lambda _: key + "=" + str(target), config)
    (BASE / "desktop.ini").write_text(config, encoding="utf-16")
    plugin_paths = [ROOT / "build/max2027-release/AminScatter", ROOT / "build/max2027-release/CyrusSurfaceAnalyzer", BASE / "probe-2027"]
    (BASE / "plugins.ini").write_text("[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns/\n" + "".join(f"CyrusPrivate{i}={path}\n" for i, path in enumerate(plugin_paths)) + "[Help]\n", encoding="utf-8")
    start = BASE / "desktop-start.ms"
    start.write_text(f'global HVPRoot="{ROOT.as_posix()}/"\nglobal HVPDir="{BASE.as_posix()}/"\nfileIn (HVPRoot+"tools/performance/native_point_probe/transport.ms")\n', encoding="utf-8")
    files = [ROOT / "AminScatter/src/preview.cpp", ROOT / "AminScatter/scripts/AminScatterObject.ms", ROOT / "Test Scene/SaveSelect 2.max", *[p for d in plugin_paths for p in d.glob("*.dl?")]]
    identity = {str(p.relative_to(ROOT)): {"sha256": sha(p), "bytes": p.stat().st_size} for p in files}
    (BASE / "input-identity.json").write_text(json.dumps(identity, indent=2), encoding="utf-8")
    command = ["C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe", "-q", "-i", str(BASE / "desktop.ini"), "-p", str(BASE / "plugins.ini"), "-U", "MAXScript", str(start), "-listenerlog", str(BASE / "listener.log")]
    process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    record = {"pid": process.pid, "command": command, "config_source": str(config_source)}
    (BASE / "launch.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
    print(json.dumps(record, indent=2))


if __name__ == "__main__":
    main()
