"""Exact MZP adapter checks in a redirected owned Max 2027 process.

The runner binds OUT/installer-remediation-config.json as installer_config in
qualification.paths/hashes and recomputes artifact_id before dispatch. Config:
schema=cyrus.installer-remediation/1, mode=main|stale-helper|scatter-stale-helper|restart,
package={path,sha256,version}; main also legacy_package={path,sha256,version};
stale-helper also stale_helper={path,sha256}; restart also expected_runtime.
All package/control extraction and writes stay inside MCPFixtureDir. The parent
runner owns launches/restarts; this fixture never starts or terminates a process.
"""
from pathlib import Path
import hashlib
import json
import os
import shutil
import traceback
import zipfile
from pymxs import runtime as r
from PySide6 import QtCore, QtWidgets

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.is_relative_to(ROOT/'build')
assert int(r.maxVersion()[0])==29000
config_path=OUT/'installer-remediation-config.json'
qualification=json.loads((OUT/'qualification.json').read_text(encoding='utf-8'))
assert Path(qualification['paths']['installer_config']).resolve()==config_path
digest=lambda path:hashlib.sha256(Path(path).read_bytes()).hexdigest()
assert digest(config_path)==qualification['hashes']['installer_config']
config=json.loads(config_path.read_text(encoding='utf-8'))
assert config['schema']=='cyrus.installer-remediation/1'
mode=config['mode']
assert {'main':'R7-I01','stale-helper':'R7-I02','restart':'R7-I03',
        'scatter-stale-helper':'R7-I04'}[mode]==str(r.QScenarioID)
directories=[Path(str(r.getDir(r.Name(name)))).resolve() for name in ('userScripts','userStartupScripts','userMacros')]
profile=Path(str(r.getMAXIniFile())).resolve().parent
assert all(path.is_relative_to(OUT) for path in [*directories,profile])
assert all(Path(os.environ[name]).resolve().is_relative_to(OUT) for name in
           ('ADSK_3DSMAX_APPDATA_DIR','ADSK_3DSMAX_USERSETTINGS_DIR','ADSK_3DSMAX_USERTOOLS_DIR'))
for path in [*directories,profile]:
    for parent in [path,*path.parents]:
        if parent==OUT.parent:break
        assert not parent.is_symlink() and not (parent.exists() and parent.stat().st_file_attributes & 0x400)
scripts,startup,macros=directories
analyzer=scripts/'CyrusSurfaceAnalyzer'
wrapper=startup/'CyrusSurfaceAnalyzerStartup.ms'
receipt=analyzer/'installed.txt'
ini=profile/'Plugin.UserSettings.ini'
report=OUT/('installer-remediation-'+str(r.QRequestID)+'.json')
result={'schema':'cyrus.installer-host/1','status':'running','mode':mode,'run_id':str(r.QRunID),
        'request_id':str(r.QRequestID),'config_sha256':digest(config_path),'dialogs':[],'checks':[],
        'scope':'Exact MZP adapter and file publication; no power-loss claim'}
timer=QtCore.QTimer()


def save():report.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')


def check(value,index,detail):
    result['checks'].append({'id':str(r.QScenarioID)+'-'+str(index).zfill(2),'pass':bool(value),'detail':detail})
    save()
    r.QAssert(bool(value),result['checks'][-1]['id'],detail)


def notice():
    for widget in QtWidgets.QApplication.topLevelWidgets():
        if (isinstance(widget,QtWidgets.QMessageBox) and widget.isVisible()
                and widget.windowTitle().startswith(('Cyrus Surface Analyzer','Surface Analyzer','Cyrus Scatter'))):
            result['dialogs'].append({'title':widget.windowTitle(),'message':widget.text()})
            save();widget.accept()


def extract(descriptor,name):
    package=Path(descriptor['path']).resolve()
    assert digest(package)==descriptor['sha256']
    destination=OUT/(name+'-'+str(r.QRequestID));destination.mkdir()
    with zipfile.ZipFile(package) as archive:
        assert archive.testzip() is None
        manifest=json.loads(archive.read('manifest.json'))
        assert manifest['version']==descriptor['version'] and manifest['max_year']==2027
        assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
        assert len(archive.infolist())<=128 and sum(info.file_size for info in archive.infolist())<=256*1024*1024
        for filename,expected in manifest['files'].items():
            target=(destination/filename).resolve()
            assert target.is_relative_to(destination) and not Path(filename).is_absolute()
            raw=archive.read(filename);assert hashlib.sha256(raw).hexdigest()==expected
            target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(raw)
    return destination,manifest


def snapshot():
    return tuple(path.read_bytes() if path.exists() else None for path in (wrapper,receipt,ini))


def scatter_snapshot():
    # Protect every installation destination, including added empty directories
    # or failure logs. Package extraction and the stale control stay outside it.
    captured = {}
    for base in directories:
        for path in [base, *base.rglob('*')]:
            captured[str(path)] = digest(path) if path.is_file() else 'directory'
    captured[str(ini)] = ini.read_bytes().hex() if ini.exists() else None
    return captured


def install(payload):
    before=len(result['dialogs'])
    r.fileIn(str(payload/'install.ms'))
    assert len(result['dialogs'])==before+1,'Expected exactly one terminal installer notice'
    return result['dialogs'][-1]


def failed(dialog):return 'failed' in dialog['title'].lower()


def loaded_helpers():
    # PyMXS cannot reliably index .NET collection Item properties. The bounded
    # host expression converts only the required locations to a MAXScript array.
    return [Path(str(value)).resolve() for value in r.execute('''(
        local all=(dotNetClass "System.AppDomain").CurrentDomain.GetAssemblies(),found=#()
        if all.count>8192 do throw "Assembly inspection exceeds fixture allowance"
        for assembly in all do (
            local identity=assembly.GetName()
            if identity.Name=="CyrusInstaller" do append found assembly.Location
        )
        found
    )''')]


def loaded_analyzer_modules():
    return [Path(str(value)).resolve() for value in r.execute('''(
        local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),found=#()
        if process.Modules.Count>8192 do throw "Module inspection exceeds fixture allowance"
        for index=0 to process.Modules.Count-1 do (
            local module=process.Modules.Item[index]
            if toLower module.ModuleName=="cyrussurfaceanalyzer.dlx" do append found module.FileName
        )
        found
    )''')]


def control(payload,name,filename,mutate):
    target=OUT/(name+'-'+str(r.QRequestID));target.mkdir()
    for source in payload.iterdir():
        assert source.is_file();shutil.copy2(source,target/source.name)
    path=target/filename;path.write_bytes(mutate(path.read_bytes()))
    result.setdefault('derived_controls',{})[name]={'changed_file':filename,'sha256':digest(path)}
    return target


try:
    scatter_stale = mode == 'scatter-stale-helper'
    payload,manifest=extract(config['package'],'scatter-package' if scatter_stale else 'analyzer-package')
    assert manifest['version']==('0.86.8.7' if scatter_stale else '0.14.2')
    result.update(package_sha256=config['package']['sha256'],payload=str(payload),payload_hashes=manifest['files'])
    timer.timeout.connect(notice);timer.start(40)
    if mode in ('stale-helper','scatter-stale-helper'):
        assert not loaded_helpers()
        stale=Path(config['stale_helper']['path']).resolve()
        assert digest(stale)==config['stale_helper']['sha256'] and digest(stale)!=manifest['files']['CyrusInstaller.dll']
        owned_helper=OUT/('stale-helper-'+str(r.QRequestID));owned_helper.mkdir()
        shutil.copy2(stale,owned_helper/'CyrusInstaller.dll')
        r.dotNet.loadAssembly(str(owned_helper/'CyrusInstaller.dll'))
        loaded=loaded_helpers()
        check(len(loaded)==1 and digest(loaded[0])==config['stale_helper']['sha256'],1,'The fresh owned host loaded only the bound historical helper control')
        capture=scatter_snapshot if scatter_stale else snapshot
        before=capture();dialog=install(payload)
        refused=dialog['title']=='Cyrus Scatter installation' if scatter_stale else failed(dialog)
        check(refused and 'different Cyrus installer is already loaded' in dialog['message'] and capture()==before,2,
              'Exact '+('Scatter' if scatter_stale else 'Analyzer')+' MZP refuses a stale loaded helper with restart guidance and preserves destinations')
    elif mode=='restart':
        runtime=Path(config['expected_runtime']).resolve();assert runtime.is_relative_to(OUT)
        loaded=loaded_analyzer_modules()
        check(loaded==[runtime/'bin/CyrusSurfaceAnalyzer.dlx'] and digest(loaded[0])==manifest['files']['CyrusSurfaceAnalyzer.dlx'],1,
              'Restart loaded the exact installed Analyzer native from its immutable registered runtime')
        assert digest(runtime/'CyrusSurfaceAnalyzer.ms')==manifest['files']['CyrusSurfaceAnalyzer.ms']
        assert digest(wrapper)==manifest['files']['CyrusSurfaceAnalyzerStartup.ms']
        r.fileIn(str(wrapper))
        check(int(r.cyrusAnalyzerContractVersion())==1 and r.CyrusSurfaceAnalyzer is not None,2,
              'Installed exact startup resolves and loads the script adjacent to its verified native module')
        result['runtime']=str(runtime)
    else:
        assert not wrapper.exists() and not receipt.exists(),'Use a fresh redirected installation profile'
        assert not str(r.getINISetting(str(ini),'Directories','CyrusSurfaceAnalyzer2027'))
        before=snapshot()
        wrong=control(payload,'wrong-host','install.ms',lambda raw:raw.replace(b'(maxVersion())[1]!=29000',b'(maxVersion())[1]!=28000',1))
        assert (wrong/'install.ms').read_bytes()!=(payload/'install.ms').read_bytes()
        dialog=install(wrong)
        check('requires 3ds Max' in dialog['message'] and snapshot()==before,1,'Wrong-host derived control refuses before touching destinations')
        bad_helper=control(payload,'tampered-helper','CyrusInstaller.dll',lambda raw:raw+b'owned tamper control')
        dialog=install(bad_helper)
        check(failed(dialog) and 'helper differs' in dialog['message'] and snapshot()==before,2,'Changed helper is rejected before assembly loading or registration')
        custom=b'-- Owned custom Analyzer startup; preserve exactly.\r\n';wrapper.write_bytes(custom)
        before=snapshot();dialog=install(payload)
        check(failed(dialog) and snapshot()==before and str(wrapper) in dialog['message'],3,'Exact MZP preserves an unknown custom startup and reports its path')
        old,old_manifest=extract(config['legacy_package'],'analyzer-legacy')
        assert old_manifest['version'] in ('0.14','0.14.1')
        legacy_wrapper=(old/'CyrusSurfaceAnalyzerStartup.ms').read_bytes()
        assert wrapper.read_bytes()==custom;wrapper.write_bytes(legacy_wrapper)
        analyzer.mkdir(exist_ok=True)
        receipt.write_bytes(b'Owned unknown receipt control\n');before=snapshot();dialog=install(payload)
        check(failed(dialog) and snapshot()==before,4,'Exact MZP preserves unknown receipt and all registration bytes')
        assert receipt.read_bytes()==b'Owned unknown receipt control\n';receipt.unlink()
        r.setINISetting(str(ini),'Directories','UnrelatedOwnedProbe',str(OUT/'unrelated-plugin'))
        r.setINISetting(str(ini),'Directories','CyrusSurfaceAnalyzer2027',str(OUT/'custom-plugin'))
        before=snapshot();dialog=install(payload)
        check(failed(dialog) and snapshot()==before,5,'Exact MZP preserves custom Analyzer plugin registration')
        native=(old/'CyrusSurfaceAnalyzer.dlx').read_bytes();script=(old/'CyrusSurfaceAnalyzer.ms').read_bytes()
        legacy_relative=('r/'+hashlib.sha256(native+script).hexdigest()[:16]+'/bin' if old_manifest['version']=='0.14.1'
                         else 'bin-max2027-'+hashlib.sha256(native).hexdigest()[:12])
        legacy_bins=analyzer/legacy_relative;legacy_bins.mkdir(parents=True)
        (legacy_bins/'CyrusSurfaceAnalyzer.dlx').write_bytes(native);(legacy_bins.parent/'CyrusSurfaceAnalyzer.ms').write_bytes(script)
        r.setINISetting(str(ini),'Directories','CyrusSurfaceAnalyzer2027',str(legacy_bins))
        poison=analyzer/'Backups'/('startup-'+hashlib.sha256(legacy_wrapper).hexdigest()+'.ms')
        poison.parent.mkdir();poison.write_bytes(b'owned interrupted old final backup')
        dialog=install(payload)
        check(not failed(dialog) and 'installed' in dialog['message'],6,'Exact MZP upgrades recognized legacy bytes despite a poisoned old backup')
        runtime=Path(str(r.getINISetting(str(ini),'Directories','CyrusSurfaceAnalyzer2027'))).resolve().parent
        assert runtime.is_relative_to(analyzer/'r')
        check(digest(runtime/'bin/CyrusSurfaceAnalyzer.dlx')==manifest['files']['CyrusSurfaceAnalyzer.dlx']
              and digest(runtime/'CyrusSurfaceAnalyzer.ms')==manifest['files']['CyrusSurfaceAnalyzer.ms']
              and receipt.read_text(encoding='utf-8-sig').splitlines()[2]=='0.14.2',7,
              'Installed runtime, script and independent receipt identify the exact package pair')
        backup=analyzer/'Backups/v2'/poison.name;metadata=backup.with_suffix('.txt')
        check(backup.read_bytes()==legacy_wrapper and poison.read_bytes()==b'owned interrupted old final backup'
              and str(poison) in metadata.read_text(encoding='utf-8-sig') and str(backup) in metadata.read_text(encoding='utf-8-sig'),8,
              'Verified migration backup and path record survive success while old differing final bytes remain')
        check((legacy_bins/'CyrusSurfaceAnalyzer.dlx').read_bytes()==native and (legacy_bins.parent/'CyrusSurfaceAnalyzer.ms').read_bytes()==script
              and str(r.getINISetting(str(ini),'Directories','UnrelatedOwnedProbe'))==str(OUT/'unrelated-plugin'),9,
              'Old runtime and unrelated plugin entry remain unchanged')
        installed=snapshot();backups={str(path):digest(path) for path in (analyzer/'Backups').rglob('*') if path.is_file()}
        dialog=install(payload)
        check(not failed(dialog) and snapshot()==installed and backups=={str(path):digest(path) for path in (analyzer/'Backups').rglob('*') if path.is_file()},10,
              'Repeated exact MZP install retains the same registrations and backup set')
        tampered=control(payload,'tampered-native','CyrusSurfaceAnalyzer.dlx',lambda raw:raw+b'owned tamper control')
        dialog=install(tampered)
        check(failed(dialog) and snapshot()==installed,11,'Tampered native package is rejected before replacing current registration')
        tampered=control(payload,'tampered-descriptor','AnalyzerPackage.txt',lambda raw:raw+b'owned tamper control')
        dialog=install(tampered)
        check(failed(dialog) and snapshot()==installed,12,'Tampered descriptor is rejected before replacing current registration')
        result.update(runtime=str(runtime),legacy_package_sha256=config['legacy_package']['sha256'],backup=str(backup))
    result['status']='passed'
except Exception:
    result.update(status='failed',error=traceback.format_exc());raise
finally:
    timer.stop();timer.deleteLater();save()
