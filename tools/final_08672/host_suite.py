"""Run serialized checks only in an existing owned Max profile."""
from pathlib import Path
import argparse, json, subprocess, sys
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser()
p.add_argument('--year',type=int,choices=(2024,2026,2027),required=True)
p.add_argument('--name',required=True)
a=p.parse_args()
assert a.name.startswith('update08671-test-')
folder=ROOT/'build/mcp-qualification'/a.name
assert json.loads((folder/'launch.json').read_text())['max_year']==a.year
steps=[
 ('update_08671/preview.ms','preview.txt'),
 ('final_08672/identity.ms','loaded-identity.json'),
 ('update_08671/panel_acceptance.ms','panel-acceptance.txt'),
 ('update_08671/preview.ms','preview.txt'),
 ('final_08672/viewport.ms','viewport-08672.txt'),
 ('update_08671/preview.ms','preview.txt'),
 ('update_08671/source_controls.ms','source-controls.txt'),
 ('update_08671/preview.ms','preview.txt'),
 ('repair_08671/lists_and_library.ms','lists-and-library.txt'),
 ('update_08671/gallery_host.ms','gallery-host.txt'),
 ('final_08672/library_binding.ms','library-binding.txt'),
 ('update_08671/texture_acceptance.ms','texture-acceptance.txt'),
]
if a.year==2027:
 steps += [
  ('update_08671/leaf_probe.ms','leaf-probe.txt'),
  ('update_08671/leaf_acceptance.ms','leaf-acceptance.txt'),
  ('final_08672/library_layers.ms','library-layers-08672.txt'),
 ]
steps += [('final_08672/installer_host.ms','installer-corrected.txt')]
for script,receipt in steps:
 result=subprocess.run([sys.executable,'-X','utf8',str(ROOT/'tools/update_08671/host.py'),'send','--name',a.name,'--year',str(a.year),'--script',str(ROOT/'tools'/script)],cwd=ROOT,capture_output=True,text=True,encoding='utf-8')
 if result.returncode:raise RuntimeError(result.stdout+result.stderr)
 path=folder/receipt
 text=path.read_text(encoding='utf-8-sig')
 if receipt.endswith('.json'):json.loads(text)
 elif 'SUCCESS' not in text or 'FAIL:' in text or 'ERROR --' in text:raise RuntimeError(script+'\n'+text)
 print('PASS',a.year,script,flush=True)
