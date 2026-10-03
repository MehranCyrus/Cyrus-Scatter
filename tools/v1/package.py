"""Package the two qualified v1 SDK builds, without rebuilding or artist installation."""
from pathlib import Path
from types import SimpleNamespace
import shutil
import sys
from build import ROOT,BASE
sys.path.insert(0,str(ROOT/'tools'))
from build_max import package,scatter_version

def main():
    version=scatter_version()
    for year in (2026,2027):
        staging=BASE/f'package-max{year}'
        native=staging/'AminScatter'
        native.mkdir(parents=True,exist_ok=True)
        names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
        for name in names:shutil.copy2(BASE/f'max{year}'/name,native/name)
        args=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=ROOT/'dist/v1')
        package('AminScatter','Cyrus Scatter',version,names,'AminScatterObject.ms',args,staging)
    shutil.copy2(ROOT/'docs/Planting_Groups_2026-10-03/ARTIST_GUIDE.md',ROOT/'dist/v1/ARTIST_GUIDE.md')
    (ROOT/'dist/v1/START_HERE.txt').write_text(
        f'Cyrus Scatter {version} trial\n\n'
        'Choose the MZP for your Max year. Scripting > Run Script, choose it, then restart Max.\n'
        'Create > Geometry > Cyrus > Cyrus Scatter, then Modify.\n'
        'Pick one shared receiving surface, then create Grass and independent flower groups.\n'
        'Coverage / Brush paints the selected group. Group spacing controls pair gaps and priority.\n'
        'Read ARTIST_GUIDE.md for the demo exercise, counts, Paint/Erase, history and limits.\n'
        'Cyrus_Scatter_1.1_Plant_Groups_Demo.max, when present, requires Max 2027.\n'
        'Existing scenes preserve legacy spacing; conversion is explicit and undoable.\n'
        'Max 2027 is interactively tested. Max 2026 is SDK/native-test qualified; host testing remains.\n'
        'MCP is optional and separately installed. Existing Analyzer scenes need Analyzer 0.14.\n',encoding='utf-8')

if __name__=='__main__':main()
