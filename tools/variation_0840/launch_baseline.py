"""Frozen delivered 0.83.0 pair for the heavy Undo A/B witness, not current code."""
from pathlib import Path
import hashlib,json,sys,time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'));from private_host import launch
host=ROOT/'build/mcp-qualification/foundation-roadmap-variation0840-undo0830-20261016-01'
script=ROOT/'build/mcp-qualification/foundation-roadmap-orientation0830-final150-20261016-07/scripts/CyrusScatter.ms'
native=ROOT/'build/orientation-0830-20261016-01/native-integration-05'
assert hashlib.sha256(script.read_bytes()).hexdigest()=='8ed01163ebd88909bb7ce34aaffd24ff10232d13705a0c60dfa32468e8b32eb1'
assert hashlib.sha256((native/'AminScatter.dlx').read_bytes()).hexdigest()=='31bf88b97c5c3210eed157a4a66959e9c538225687589ec4b490436b907f8a12'
process,metadata=launch(host,script,native,transport=True,max_year=2027,silent_startup=True)
metadata['scope']='Immutable delivered 0.83.0 baseline; not current 0.84.0 qualification'
(host/'launch.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8');print('Owned baseline PID',process.pid,flush=True)
deadline=time.monotonic()+240
while time.monotonic()<deadline:
 if (host/'startup-error.txt').exists():raise RuntimeError((host/'startup-error.txt').read_text())
 if (host/'ready.json').exists():print('Baseline ready',flush=True);break
 if process.poll() is not None:raise RuntimeError('Baseline exited before readiness')
 time.sleep(.5)
else:raise TimeoutError('Inspect the existing baseline process')
