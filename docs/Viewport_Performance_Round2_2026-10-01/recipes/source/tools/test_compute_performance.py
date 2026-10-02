"""Qualify compute/filter/batch changes in an isolated Max 2027 process."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    destination = ROOT / "build/compute-performance-test"
    destination.mkdir(parents=True, exist_ok=True)
    plugins = destination / "plugins.ini"
    plugins.write_text("[Directories]\nCyrusScatterTest=" + str(ROOT / "build/max2027-release/AminScatter") +
                       "\nCyrusAnalyzerTest=" + str(ROOT / "build/max2027-release/CyrusSurfaceAnalyzer") + "\n")
    config = destination / "max.ini"
    if not config.exists(): config.write_text("[Directories]\n")
    report = destination / "result.txt"
    report.write_text("PENDING\n")
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    command = ["C:/Program Files/Autodesk/3ds Max 2027/3dsmaxbatch.exe",
               str(ROOT / "tools/tests/compute_performance_smoke.ms"), "-i", str(config), "-p", str(plugins),
               "-listenerlog", str(destination / "listener.log"), "-log", str(destination / "session.log")]
    with (destination / "stdout.log").open("wb") as out, (destination / "stderr.log").open("wb") as err:
        completed = subprocess.run(command, cwd=ROOT, stdout=out, stderr=err, startupinfo=startup, timeout=240)
    text = report.read_text(encoding="utf-8-sig")
    print(text)
    if completed.returncode or "SUCCESS" not in text:
        raise SystemExit(f"Compute qualification failed; inspect {destination}")


if __name__ == "__main__":
    main()
