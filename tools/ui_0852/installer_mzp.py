"""Execute the exact packaged MZP wrapper; dismiss only its owned Qt notice."""
from pathlib import Path
import json,hashlib,traceback,uuid
from pymxs import runtime as r
from PySide6 import QtCore,QtWidgets
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-ui0852-')
for path in (r.getDir(r.Name('userScripts')),r.getDir(r.Name('userStartupScripts')),r.getDir(r.Name('userMacros')),Path(str(r.getMAXIniFile())).parent):
 assert Path(str(path)).resolve().is_relative_to(OUT)
payload=Path((OUT/'installer-pilot-payload.txt').read_text(encoding='utf-8-sig'));assert payload.resolve().is_relative_to(ROOT/'build')
result={'status':'running','wrapper_sha256':hashlib.sha256((payload/'install.ms').read_bytes()).hexdigest(),'dialogs':[]};out=OUT/('installer-wrapper-'+uuid.uuid4().hex+'.json')
timer=QtCore.QTimer()
def notice():
 for widget in QtWidgets.QApplication.topLevelWidgets():
  if isinstance(widget,QtWidgets.QMessageBox) and widget.isVisible() and widget.windowTitle().startswith('Cyrus Scatter'):
   result['dialogs'].append({'title':widget.windowTitle(),'message':widget.text()});out.write_text(json.dumps(result,indent=2),encoding='utf-8');widget.accept()
timer.timeout.connect(notice);timer.start(50)
try:
 r.fileIn(str(payload/'install.ms'))
 assert len(result['dialogs'])==1 and result['dialogs'][0]['title']=='Cyrus Scatter 0.85.2'
 assert 'is installed for Max 2027' in result['dialogs'][0]['message']
 receipt=Path(str(r.getDir(r.Name('userScripts'))))/'CyrusScatter/installed.txt'
 release=Path(receipt.read_text(encoding='utf-8-sig').splitlines()[2]);assert release.is_relative_to(OUT)
 assert (release/'CyrusScatter.ms').is_file() and (release/'Library-0.85.2/inventory.json').is_file()
 result.update(status='passed',release=str(release))
except Exception:result.update(status='failed',error=traceback.format_exc());raise
finally:timer.stop();timer.deleteLater();out.write_text(json.dumps(result,indent=2),encoding='utf-8')
