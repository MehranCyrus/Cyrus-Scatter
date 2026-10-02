"""Run the compatibility smoke test in a separate Max batch process.

Does not install plugins or send commands to an existing interactive Max session.
"""
from pathlib import Path
import argparse
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--max-dir', type=Path, default=Path('C:/Program Files/Autodesk/3ds Max 2027'))
    args = parser.parse_args()
    build = ROOT / 'build'
    for file in ('AminScatter/AminScatter.dlx', 'AminScatter/CyrusScatterEdit.dlm',
                 'CyrusSurfaceAnalyzer/CyrusSurfaceAnalyzer.dlx'):
        if not (build / 'max2027-release' / file).is_file():
            raise SystemExit('Run tools/build_max.py for Max 2027 first')
    config = build / 'max2027-test.ini'
    if not config.exists():
        config.write_text('[Directories]\n')
    plugins = build / 'max2027-plugins.ini'
    plugins.write_text('[Directories]\nCyrusScatterTest=' + str(build / 'max2027-release/AminScatter') +
                       '\nCyrusAnalyzerTest=' + str(build / 'max2027-release/CyrusSurfaceAnalyzer') + '\n')
    result = build / 'max2027-smoke-result.txt'
    result.write_text('PENDING\n')  # Never accept a stale success report.
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    command = [str(args.max_dir / '3dsmaxbatch.exe'), str(ROOT / 'tools/tests/max2027_smoke.ms'),
               '-i', str(config), '-p', str(plugins),
               '-listenerlog', str(build / 'max2027-listener.log'),
               '-log', str(build / 'max2027-session.log')]
    with (build / 'max2027-batch-stdout.log').open('wb') as out, (build / 'max2027-batch-stderr.log').open('wb') as err:
        completed = subprocess.run(command, cwd=ROOT, stdout=out, stderr=err, startupinfo=startup, timeout=240)
    (build / 'max2027-batch-exit.txt').write_text(str(completed.returncode) + '\n')
    report = result.read_text(encoding='utf-8-sig')
    print(report)
    if completed.returncode != 0 or 'SUCCESS' not in report:
        raise SystemExit('Max compatibility test failed; inspect build/max2027-*.log')


if __name__ == '__main__':
    main()
