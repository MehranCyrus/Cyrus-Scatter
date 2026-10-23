"""Execute the exact Analyzer installer only inside the owned Max profile.

Qt notices are observed and dismissed within this test process. No artist profile,
global registration, shared library or existing Max process is an install target.
"""
from pathlib import Path
import hashlib
import json
import shutil
import traceback
import zipfile
from pymxs import runtime as r
from PySide6 import QtCore, QtWidgets

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.is_relative_to(ROOT/'build/refinement-08683-20261022')
for directory in (r.getDir(r.Name('userScripts')),r.getDir(r.Name('userStartupScripts')),Path(str(r.getMAXIniFile())).parent):
    assert Path(str(directory)).resolve().is_relative_to(OUT)
report=OUT/('installer-'+str(r.QRequestID)+'.json')
result={'status':'running','dialogs':[],'checks':[]}
timer=QtCore.QTimer()


def notice():
    for widget in QtWidgets.QApplication.topLevelWidgets():
        if isinstance(widget,QtWidgets.QMessageBox) and widget.isVisible() and widget.windowTitle().startswith(('Cyrus Surface Analyzer','Surface Analyzer')):
            result['dialogs'].append({'title':widget.windowTitle(),'message':widget.text()})
            report.write_text(json.dumps(result,indent=2),encoding='utf-8')
            widget.accept()


def snapshot():
    ini=Path(str(r.getMAXIniFile())).parent/'Plugin.UserSettings.ini'
    startup=Path(str(r.getDir(r.Name('userStartupScripts'))))/'CyrusSurfaceAnalyzerStartup.ms'
    return tuple(path.read_bytes() if path.exists() else None for path in (ini,startup))


def install(payload):
    before=len(result['dialogs'])
    r.fileIn(str(payload/'install.ms'))
    assert len(result['dialogs'])==before+1,'Installer did not produce exactly one terminal notice'
    return result['dialogs'][-1]


try:
    archive=ROOT/'dist/CyrusScatter-0.86.8.3-20261022/CyrusSurfaceAnalyzer-0.14.1-Max2027.mzp'
    payload=OUT/('analyzer-install-'+str(r.QRequestID));payload.mkdir()
    with zipfile.ZipFile(archive) as source:
        assert source.testzip() is None
        manifest=json.loads(source.read('manifest.json'))
        assert manifest['version']=='0.14.1' and manifest['max_year']==2027
        for name,digest in manifest['files'].items():
            assert not Path(name).is_absolute() and '..' not in Path(name).parts
            data=source.read(name);assert hashlib.sha256(data).hexdigest()==digest
            target=payload/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
    result['package_sha256']=hashlib.sha256(archive.read_bytes()).hexdigest()
    timer.timeout.connect(notice);timer.start(40)
    before=snapshot()
    wrong=payload/'wrong-host';wrong.mkdir()
    text=(payload/'install.ms').read_text(encoding='utf-8-sig')
    assert '(maxVersion())[1]!=29000' in text
    (wrong/'install.ms').write_text(text.replace('(maxVersion())[1]!=29000','(maxVersion())[1]!=28000',1),encoding='utf-8')
    assert 'requires 3ds Max' in install(wrong)['message'] and snapshot()==before
    result['checks'].append('Wrong-host guard preserves registration/startup')
    assert 'installed' in install(payload)['message']
    installed=snapshot();assert all(installed)
    ini=Path(str(r.getMAXIniFile())).parent/'Plugin.UserSettings.ini'
    bins=Path(str(r.getINISetting(str(ini),'Directories','CyrusSurfaceAnalyzer2027')))
    assert bins.is_relative_to(OUT)
    for name in ('CyrusSurfaceAnalyzer.dlx','CyrusSurfaceAnalyzer.ms'):
        target=bins/name if name.endswith('.dlx') else bins.parent/name
        assert hashlib.sha256(target.read_bytes()).hexdigest()==manifest['files'][name]
    result['runtime']=str(bins.parent)
    result['checks'].append('Exact pair installed and verified in immutable runtime')
    assert 'installed' in install(payload)['message'] and snapshot()==installed
    result['checks'].append('Repeated install preserves identical bindings and payload')
    tamper=payload/'tampered';tamper.mkdir()
    for path in payload.iterdir():
        if path.is_file():shutil.copy2(path,tamper/path.name)
    with (tamper/'CyrusSurfaceAnalyzer.dlx').open('ab') as stream:stream.write(b'tamper')
    assert 'hash differs' in install(tamper)['message'] and snapshot()==installed
    result['checks'].append('Tampered native rejected before binding publication')
    startup=Path(str(r.getDir(r.Name('userStartupScripts'))))/'CyrusSurfaceAnalyzerStartup.ms'
    blocker=Path(str(startup)+'.cyrus-stage');assert not blocker.exists();blocker.mkdir()
    try:
        failure=install(payload)
        assert 'installation failed' in failure['title'].lower() and snapshot()==installed
    finally:blocker.rmdir()
    result['checks'].append('Failure after INI switch restores previous registration/startup')
    assert 'installed' in install(payload)['message'] and snapshot()==installed
    result['checks'].append('Valid install recovers after injected publication failure')
    result['status']='passed'
except Exception:
    result.update(status='failed',error=traceback.format_exc())
    raise
finally:
    timer.stop();timer.deleteLater()
    report.write_text(json.dumps(result,indent=2),encoding='utf-8')
