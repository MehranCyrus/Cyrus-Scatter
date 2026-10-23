"""Run the exact delivered installer core in Max 2027, only in owned paths."""
from pathlib import Path
import hashlib,json,os,zipfile
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.is_relative_to(ROOT/'build/installer-panels-08684-20261022')
assert Path(os.environ['ADSK_3DSMAX_APPDATA_DIR']).resolve().is_relative_to(OUT)
package=ROOT/'dist/CyrusScatter-0.86.8.4-20261022/CyrusScatter-0.86.8.4-Max2027.mzp'
payload=OUT/('scatter-install-'+str(r.QRequestID));payload.mkdir()
with zipfile.ZipFile(package) as archive:
    assert archive.testzip() is None
    manifest=json.loads(archive.read('manifest.json'))
    assert manifest['version']=='0.86.8.4' and manifest['max_year']==2027
    for name,digest in manifest['files'].items():
        assert not Path(name).is_absolute() and '..' not in Path(name).parts
        raw=archive.read(name);assert hashlib.sha256(raw).hexdigest()==digest
    archive.extractall(payload)
directories=[Path(str(r.getDir(r.Name(name)))).resolve() for name in ('userScripts','userStartupScripts','userMacros')]
profile=Path(str(r.getMAXIniFile())).resolve().parent
assert all(p.is_relative_to(OUT) for p in [*directories,profile])
with zipfile.ZipFile(ROOT/'dist/CyrusScatter-0.81.6-20261013/CyrusScatter-0.81.6-Max2027.mzp') as old:
    for target,name in [(directories[1],'CyrusScatterStartup.ms'),(directories[2],'CyrusScatter.mcr')]:
        assert not (target/name).exists();(target/name).write_bytes(old.read(name))
r.dotNet.loadAssembly(str(payload/'CyrusInstaller.dll'))
paths=r.dotNetClass('Cyrus.Setup.InstallPaths').ForMax(*(str(p) for p in [*directories,profile]),'2027')
engine=r.dotNetObject('Cyrus.Setup.InstallEngine',str(payload),hashlib.sha256((payload/'InstallInventory.txt').read_bytes()).hexdigest())
release=Path(str(engine.Install(paths)))
receipt=directories[0]/'CyrusScatter/installed.txt'
assert receipt.read_text(encoding='utf-8-sig').splitlines()[1]=='0.86.8.4'
backups=list((directories[0]/'CyrusScatter/Backups').iterdir());assert len(backups)==1
assert (backups[0]/'CyrusScatter.mcr').is_file() and (backups[0]/'CyrusScatterStartup.ms').is_file()
assert Path(str(engine.Install(paths)))==release
assert len(list((directories[0]/'CyrusScatter/Backups').iterdir()))==1
(OUT/('scatter-installer-'+str(r.QRequestID)+'.json')).write_text(json.dumps({'status':'passed',
    'package_sha256':hashlib.sha256(package.read_bytes()).hexdigest(),'release':str(release),'backup':str(backups[0]),'max_year':2027},indent=2))
r.QAssert(True,'INSTALL84-HOST-01','Exact delivered core migrates and backs up old wrappers in Max 2027; repeat reuses runtime')
