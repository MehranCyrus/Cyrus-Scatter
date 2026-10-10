"""Package matching lab modules; no install and no changes to Cyrus."""
from pathlib import Path
import argparse,hashlib,json,shutil,zipfile
LAB=Path(__file__).resolve().parents[1]
FOLDERS=['01-vector-regions','02-tiled-mask','03-surface-volumes','04-surface-field']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--build',type=Path,required=True);ap.add_argument('--output',type=Path,required=True);a=ap.parse_args();build=a.build.resolve();output=a.output.resolve();output.mkdir(parents=True,exist_ok=False)
    receipt=json.loads((build/'build-receipt.json').read_text());packages=[]
    for i,method in enumerate(FOLDERS,1):
        folder=output/method;folder.mkdir();dll=build/f'PaintLab{i}.dlx'
        if sha(dll)!=receipt['binaries'][dll.name]:raise RuntimeError('Binary mismatch')
        shutil.copy2(dll,folder/dll.name);shutil.copy2(LAB/'methods'/method/'scripts/Launch.ms',folder/'Launch.ms');shutil.copy2(LAB/'tools/trial.py',folder/'trial.py');shutil.copy2(LAB/'third_party/clipper2/LICENSE',folder/'Clipper2-LICENSE.txt')
        (folder/'Try.cmd').write_text('@echo off\r\ncd /d "%~dp0"\r\npython trial.py\r\nif errorlevel 1 pause\r\n')
        (folder/'README.txt').write_text('Paint Methods Lab 0.1.0 / '+method+'\n\nMax 2027 and Python 3 required. Extract the whole package, then run Try.cmd.\nThis opens a NEW Max process with a disposable profile and a sample plane.\nPick the plane in the window, choose Paint/Erase, press Start, then drag in the viewport.\nStop before changing radius/mode. Use the dedicated Undo/Redo buttons.\nPaint is saved explicitly using Save region (*.plab); normal scene saving does not embed it.\nPrecision is fixed at region creation. Display step is a separate preview approximation.\nTry larger Display step if the complete preview exceeds the display budget.\nA/B are projected; C is Euclidean; D has a restricted Euclidean footprint, not geodesic.\nReceiver edits suspend the region. Trials are experiments, not Cyrus releases.\nClose this trial process when done. Your existing Max process/profile is not modified.\n',encoding='utf-8')
        manifest={'method':i,'version':'0.1.0','max':2027,'files':{p.name:sha(p) for p in folder.iterdir() if p.is_file()},'build_receipt_sha256':sha(build/'build-receipt.json')}
        (folder/'manifest.json').write_text(json.dumps(manifest,indent=2))
        archive=output/(method+'-0.1.0-Max2027.zip')
        with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
            for p in folder.iterdir():z.write(p,p.name)
        packages.append({'method':i,'folder':str(folder),'archive':str(archive),'archive_sha256':sha(archive),'manifest':manifest})
    (output/'packages.json').write_text(json.dumps(packages,indent=2));print(output)
if __name__=='__main__':main()
