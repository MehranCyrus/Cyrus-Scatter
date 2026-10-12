"""Serial developer requests to an explicitly owned landscape test host."""
from pathlib import Path
import argparse, sys
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/procedural_lab'))
from runtime_driver import run_script
p = argparse.ArgumentParser()
p.add_argument('profile', type=Path)
p.add_argument('file', type=Path)
p.add_argument('--timeout', type=int, default=240)
a = p.parse_args()
folder = a.profile.resolve()
if folder.parent != ROOT / 'build/mcp-qualification' or not folder.name.startswith('refine0795-'):
    raise ValueError('Owned landscape test host required')
path = a.file.resolve()
script = ('python.ExecuteFile @"' + path.as_posix() + '"') if path.suffix == '.py' else path.read_text(encoding='utf-8-sig')
result = run_script(folder, script, timeout=a.timeout)
print(result)
if not result.startswith('SUCCESS '):
    raise RuntimeError(result)
