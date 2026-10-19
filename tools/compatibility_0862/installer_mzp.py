"""Run the exact package wrapper inside a verified disposable host only."""
from pathlib import Path
import hashlib, json, traceback
from pymxs import runtime as r
from PySide6 import QtCore, QtWidgets
ROOT=Path(__file__).resolve().parents[2];out=Path(str(r.MCPFixtureDir)).resolve()
assert out.parent==ROOT/'build/mcp-qualification' and out.name.startswith('density0862-compat-')
for p in (r.getDir(r.Name('userScripts')),r.getDir(r.Name('userStartupScripts')),r.getDir(r.Name('userMacros')),Path(str(r.getMAXIniFile())).parent):
    assert Path(str(p)).resolve().is_relative_to(out)
year=int(r.maxVersion()[0]/1000)+1998;assert year in (2026,2027)
payload=ROOT/f'build/compatibility-0862-20261019/package01/payload{year}'
result={'status':'running','year':year,'wrapper_sha256':hashlib.sha256((payload/'install.ms').read_bytes()).hexdigest(),'dialogs':[]}
log=out/'installer-wrapper.json';assert not log.exists()
timer=QtCore.QTimer()
def notice():
    for widget in QtWidgets.QApplication.topLevelWidgets():
        if isinstance(widget,QtWidgets.QMessageBox) and widget.isVisible() and widget.windowTitle()=='Cyrus Scatter 0.86.2':
            result['dialogs'].append({'title':widget.windowTitle(),'message':widget.text()});widget.accept()
timer.timeout.connect(notice);timer.start(50)
try:
    r.fileIn(str(payload/'install.ms'))
    assert len(result['dialogs'])==1 and f'is installed for Max {year}' in result['dialogs'][0]['message']
    receipt=Path(str(r.getDir(r.Name('userScripts'))))/'CyrusScatter/installed.txt'
    release=Path(receipt.read_text(encoding='utf-8-sig').splitlines()[2]);assert release.is_relative_to(out)
    assert (release/'Library-0.86.2/inventory.json').is_file() and len(list((release/'Patterns').glob('*.png')))==3
    result.update(status='passed',release=str(release),artist_profile_modified=False)
except Exception:
    result.update(status='failed',error=traceback.format_exc());raise
finally:
    timer.stop();timer.deleteLater();log.write_text(json.dumps(result,indent=2)+'\n')
