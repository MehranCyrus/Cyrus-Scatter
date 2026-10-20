"""Send one inspected fixture to a recorded compatibility host, serialized."""
from pathlib import Path
import argparse, json, sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('script',type=Path);a=p.parse_args()
assert a.host.startswith(('density0862-compat-','density0862-installer-'))
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
assert json.loads((host/'launch.json').read_text())['max_year'] in (2024,2026,2027)
send(host,a.script.resolve(),a.script.stem)
