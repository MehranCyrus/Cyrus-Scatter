from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2];out=ROOT/'build/surface-brush-0866-20261019/package02'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
receipt=json.loads((out/'exe-receipt.json').read_text());previous=Path('D:/CyrusScatterBuilds/if0866/78bc16')
assert (previous/'u2027/r/r/9829585a0cb4/bin/AminScatter.dlx').is_file()
assert sha(previous/'u2027/r/r/9829585a0cb4/bin/AminScatter.dlx')==sha(out/'payload/AminScatter.dlx')
(out/'recipient-root.txt').write_text(str(previous))
receipt['owned_test_roots']={'recipient':str(previous),'ui':receipt.pop('owned_test_root')}
(out/'exe-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
host=ROOT/'build/mcp-qualification/density0862-reliability-surface0866-03';log=host/'installer-core-host.txt'
assert log.read_text(encoding='utf-8-sig').startswith('PASS: exact MZP installer core')
(out/'installer-host-receipt.json').write_text(json.dumps({'status':'passed','max_year':2027,'artist_installation':False,'payload_core_sha256':sha(out/'payload/CyrusInstaller.dll'),'mzp_sha256':receipt['mzp_sha256'],'test_sha256':sha(ROOT/'tools/surface_brush_0866/installer_host.ms'),'log_path':str(log),'log_sha256':sha(log),'launch_sha256':sha(host/'launch.json'),'owned_recipient':'D:/CyrusScatterBuilds/if0866/maxhost03'},indent=2)+'\n')
