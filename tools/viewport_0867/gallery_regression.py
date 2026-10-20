"""Actual WinForms wheel regression, including a control without the fix."""
from pathlib import Path
import json,subprocess,re
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'build/viewport-0867-20261020'
receipt=json.loads((WORK/'max2024/CyrusGallery.build.json').read_text())
source=(ROOT/'AminScatter/ui/LibraryGallery.cs').read_text()
source,n=re.subn(r'        protected override void OnMouseWheel\(MouseEventArgs e\)\s*\{.*?\n        \}', '',source,count=1,flags=re.S)
assert n==1
probe=WORK/'gallery-before-wheel.cs';probe.write_text(source)
assembly=WORK/'gallery-before-wheel.dll'
command=[receipt['compiler'],'/nologo','/noconfig','/nostdlib+','/langversion:latest','/nullable:enable','/warnaserror+',
         '/target:library','/platform:x64','/out:'+str(assembly),
         *('/reference:'+p for p in receipt['references']),str(probe)]
subprocess.run(command,check=True,capture_output=True)
results=[]
for label,dll in [('without-wheel-fix',assembly),('fixed',WORK/'max2024/CyrusGallery.dll')]:
    result=subprocess.run(['powershell.exe','-NoProfile','-STA','-File',str(ROOT/'tools/viewport_0867/gallery.ps1'),
        '-Assembly',str(dll),'-Catalog',str(ROOT/'build/individual-model-library-20261020/Content/Library')],text=True,capture_output=True)
    results.append(dict(label=label,code=result.returncode,output=result.stdout+result.stderr))
assert results[0]['code']!=0 and 'THUMBNAIL STALL' in results[0]['output'],results[0]
assert results[1]['code']==0,results[1]
(WORK/'gallery-regression.json').write_text(json.dumps(dict(status='passed',cases=results),indent=2))
print(json.dumps(results,indent=2))
