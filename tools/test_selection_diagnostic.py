"""Selection regression probe in an isolated Max 2027 batch process."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    folder = ROOT / "build/selection-diagnostic-test"
    folder.mkdir(parents=True, exist_ok=True)
    config = folder / "max.ini"
    if not config.exists():
        config.write_text("[Directories]\n", encoding="utf-8")
    plugins = folder / "plugins.ini"
    plugins.write_text("[Directories]\nScatter=" + str(ROOT / "build/max2027-release/AminScatter")
                       + "\nAnalyzer=" + str(ROOT / "build/max2027-release/CyrusSurfaceAnalyzer") + "\n", encoding="utf-8")
    (folder / "result.txt").write_text("PENDING\n", encoding="utf-8")
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    with (folder / "stdout.log").open("wb") as out, (folder / "stderr.log").open("wb") as err:
        result = subprocess.run(["C:/Program Files/Autodesk/3ds Max 2027/3dsmaxbatch.exe",
            str(ROOT / "tools/tests/selection_diagnostic_smoke.ms"), "-i", str(config), "-p", str(plugins),
            "-listenerlog", str(folder / "listener.log"), "-log", str(folder / "session.log")],
            cwd=ROOT, startupinfo=startup, stdout=out, stderr=err, timeout=180)
    text = (folder / "result.txt").read_text(encoding="utf-8-sig")
    print(text)
    if result.returncode or "SUCCESS" not in text:
        raise SystemExit("Selection probe failed; see build/selection-diagnostic-test logs")


if __name__ == "__main__":
    main()
