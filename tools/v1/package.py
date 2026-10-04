"""Package the two qualified v1 SDK builds, without rebuilding or artist installation."""
from pathlib import Path
from types import SimpleNamespace
import shutil
import sys
import argparse
from build import ROOT,BASE
sys.path.insert(0,str(ROOT/'tools'))
from build_max import package,scatter_version

def main():
    parser=argparse.ArgumentParser()
    version=scatter_version()
    parser.add_argument('--output',type=Path,default=ROOT/f'dist/classic-layout-{version}')
    output=parser.parse_args().output.resolve()
    output.mkdir(parents=True,exist_ok=True)
    for year in (2026,2027):
        staging=BASE/f'package-max{year}'
        native=staging/'AminScatter'
        native.mkdir(parents=True,exist_ok=True)
        names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
        for name in names:shutil.copy2(BASE/f'max{year}'/name,native/name)
        args=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=output)
        package('AminScatter','Cyrus Scatter',version,names,'AminScatterObject.ms',args,staging)
    guide=(ROOT/'docs/Classic_Layout_2026-10-04/ARTIST_GUIDE.md').read_text(encoding='utf-8')
    guide=guide.replace('[scrolling report](SCROLLING_1.2.3.md)','scrolling qualification report in the source repository')
    (output/'ARTIST_GUIDE.md').write_text(guide.replace('../Layers_First_2026-10-03/CAPABILITIES.md','CAPABILITIES.md'),encoding='utf-8')
    shutil.copy2(ROOT/'docs/Layers_First_2026-10-03/CAPABILITIES.md',output/'CAPABILITIES.md')
    (output/'START_HERE.txt').write_text(
        f'Cyrus Scatter {version} trial\n\n'
        'Choose the MZP for your Max year. Scripting > Run Script, choose it, then restart Max.\n'
        'Create > Geometry > Cyrus > Cyrus Scatter, then Modify.\n'
        'Choose Surface Scatter > Pick receiving surface, then Layer Manager > Add Layer.\n'
        'Name your layers Grass and Flowers. Open their headers directly below Layer Manager.\n'
        'Scroll with the wheel over section backgrounds/headers, or left-drag blank grey panel space.\n'
        'Expand Flowers: Paint sets holds Red, Blue and Yellow. Each has its own assets and Brush history.\n'
        'Population, area, randomization and spacing belong to the whole Flowers layer.\n'
        'Read ARTIST_GUIDE.md for the demo exercise, counts, Paint/Erase, history and limits.\n'
        'Cyrus_Scatter_1.2_Layers_Demo.max, when present, requires Max 2027.\n'
        'Existing scenes preserve legacy spacing; conversion is explicit and undoable.\n'
        'Max 2027 is interactively tested. Max 2026 is SDK/native-test qualified; host testing remains.\n'
        'MCP is optional and separately installed. Existing Analyzer scenes need Analyzer 0.14.\n',encoding='utf-8')

if __name__=='__main__':main()
