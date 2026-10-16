"""Real process-exit recovery, locked registration and delivered-wrapper upgrade."""
from pathlib import Path
import argparse,hashlib,json,subprocess,uuid,zipfile
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--core',required=True,type=Path);p.add_argument('--payload',required=True,type=Path);a=p.parse_args()
core,payload=a.core.resolve(),a.payload.resolve()
assert core.is_relative_to(ROOT/'build') and payload.is_relative_to(ROOT/'build')
out=ROOT/'build/gallery-0851-20261016-01'/('installer-crash-'+uuid.uuid4().hex);out.mkdir()
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
inventory=sha(payload/'InstallInventory.txt');results=[]
for case,phase in [('crash-first','publishing:1'),('crash-before-ini','publishing:3'),('external-edit','publishing:1'),('lock',''),('cancel',''),('upgrade','')]:
 folder=out/case;(folder/'profile').mkdir(parents=True)
 ini=folder/'profile/Plugin.UserSettings.ini';ini.write_text('[Directories]\nOther=F:/Preserved\n',encoding='utf-16');old=ini.read_bytes()
 common=['-CorePath',str(core),'-PackageDir',str(payload),'-InventoryHash',inventory,'-Root',str(folder)]
 if phase:
  proc=subprocess.run(['pwsh','-NoProfile','-NonInteractive','-File',str(ROOT/'tools/gallery_0851/installer_crash_child.ps1'),*common,'-Phase',phase],capture_output=True,text=True)
  assert proc.returncode==86,(case,proc.stdout,proc.stderr)
  assert (folder/'scripts/CyrusScatter/install-transaction.bin').exists()
 if case=='external-edit':
  edited=folder/'startup/CyrusScatterStartup.ms';edited.write_text('External user edit',encoding='utf-8')
 if case=='upgrade':
  old_package=ROOT/'dist/CyrusScatter-0.85.0-20261016/CyrusScatter-0.85.0-Max2027.mzp'
  assert sha(old_package)=='53764753ce3e320aeafd977328788323cdaad8a9919736056089d2e07cdc64d0'
  with zipfile.ZipFile(old_package) as archive:
   for name,relative in [('CyrusScatterStartup.ms','startup'),('CyrusScatter.mcr','macros')]:
    (folder/relative).mkdir();(folder/relative/name).write_bytes(archive.read(name))
  (folder/'scripts/CyrusScatter/Library-0.85.0').mkdir(parents=True)
  (folder/'scripts/CyrusScatter/Library-0.85.0/personal-marker.txt').write_text('Preserve',encoding='utf-8')
 proc=subprocess.run(['pwsh','-NoProfile','-NonInteractive','-File',str(ROOT/'tools/gallery_0851/installer_recover.ps1'),*common,'-Mode',case],capture_output=True,text=True)
 assert proc.returncode==0,(case,proc.stdout,proc.stderr)
 result=json.loads((folder/'result.json').read_text(encoding='utf-8-sig'))
 if case=='external-edit':
  assert result['status']=='rejected' and edited.read_text(encoding='utf-8')=='External user edit' and ini.read_bytes()==old
 elif case in ('lock','cancel'):
  assert result['status']=='rejected' and ini.read_bytes()==old and not (folder/'startup/CyrusScatterStartup.ms').exists() and not (folder/'macros/CyrusScatter.mcr').exists(),result
  assert not (folder/'scripts/CyrusScatter/install-transaction.bin').exists(),result
 else:
  assert result['status']=='installed' and 'Other=F:/Preserved' in ini.read_text(encoding='utf-16'),result
  assert not (folder/'scripts/CyrusScatter/install-transaction.bin').exists()
  if case=='upgrade':assert (folder/'scripts/CyrusScatter/Library-0.85.0/personal-marker.txt').read_text(encoding='utf-8')=='Preserve'
 results.append({'case':case,'status':'passed','observed':result})
(out/'summary.json').write_text(json.dumps({'core_sha256':sha(core),'inventory_sha256':inventory,'cases':results,'scope':'Owned folders; actual process exit and locked file; no artist install'},indent=2),encoding='utf-8')
print('PASS',len(results),'installer cases',out)
