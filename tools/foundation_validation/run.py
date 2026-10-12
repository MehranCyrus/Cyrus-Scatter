"""Run one regression file through an explicitly owned foundation host."""
import argparse
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/procedural_lab'))
from runtime_driver import run_script

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('profile', type=Path)
parser.add_argument('script', type=Path)
parser.add_argument('--timeout', type=float, default=90)
args = parser.parse_args()
folder = args.profile.resolve()
if folder.parent != ROOT / 'build/mcp-qualification' or not folder.name.startswith('foundation-'):
    raise ValueError('Owned foundation host required')
path = args.script.resolve()
code = 'python.ExecuteFile @"' + path.as_posix() + '"' if path.suffix == '.py' else path.read_text(encoding='utf-8-sig')
result = run_script(folder, code, timeout=args.timeout)
print(result)
raise SystemExit(0 if result.startswith('SUCCESS ') else 1)
