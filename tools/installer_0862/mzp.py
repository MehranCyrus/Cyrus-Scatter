"""Execute the complete MZP through Max's real package extraction path."""
from pathlib import Path
import hashlib,json,traceback
from pymxs import runtime as r
try:from PySide2 import QtCore,QtWidgets
except ImportError:from PySide6 import QtCore,QtWidgets
ROOT=Path(__file__).resolve().parents[2];out=Path(str(r.MCPFixtureDir));meta=json.loads((out/'launch.json').read_text())
assert out.name.startswith('density0862-installer-');profile=Path(meta['short_profile']);assert profile.parent==ROOT/'build'
for p in (r.getDir(r.Name('userScripts')),r.getDir(r.Name('userStartupScripts')),r.getDir(r.Name('userMacros')),Path(str(r.getMAXIniFile())).parent):assert Path(str(p)).resolve().is_relative_to(profile)
year=int(r.maxVersion()[0]/1000)+1998
package=ROOT/f'build/installer-0862-20261019-01/package03/CyrusScatter-0.86.2-Max{year}.mzp'
result={'status':'running','year':year,'mzp_sha256':hashlib.sha256(package.read_bytes()).hexdigest(),'dialogs':[]}
timer=QtCore.QTimer()
def notice():
 for w in QtWidgets.QApplication.topLevelWidgets():
  if isinstance(w,QtWidgets.QMessageBox) and w.isVisible() and w.windowTitle().startswith('Cyrus Scatter'):
   result['dialogs'].append({'title':w.windowTitle(),'text':w.text()});w.accept()
timer.timeout.connect(notice);timer.start(50)
try:
 r.fileIn(str(package))
 receipt=profile/'scripts/CyrusScatter/installed.txt'
 release=Path(receipt.read_text(encoding='utf-8-sig').splitlines()[2]);assert release.is_relative_to(profile)
 assert (release/'Library-0.86.2/inventory.json').is_file()
 result.update(status='passed',release=str(release),max_path=max(len(str(p)) for p in release.rglob('*') if p.is_file()),artist_installation=False)
except Exception:result.update(status='failed',error=traceback.format_exc());raise
finally:timer.stop();timer.deleteLater();(out/'mzp.json').write_text(json.dumps(result,indent=2)+'\n')
