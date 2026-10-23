"""Run the exact combined EXE's Install/Update handler on owned profiles only."""
from pathlib import Path
import argparse
import json
import os
import subprocess
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
import build_inputs


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--exe',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--scatter-legacy',type=Path,required=True)
    parser.add_argument('--analyzer-legacy',type=Path,required=True)
    args=parser.parse_args()
    output=args.output.resolve();executable=args.exe.resolve()
    if not output.is_relative_to(ROOT/'build') or len(str(output))>88:
        raise ValueError('Use a fresh short owned build path (at most88 characters).')
    output.mkdir(parents=True,exist_ok=False)
    receipt=build_inputs.verify_managed(executable,'installer-exe',ROOT)
    if receipt['version']!='0.86.8.7' or receipt['max_years']!=[2027]:
        raise ValueError('This fixture requires the exact Max2027-only0.86.8.7 delivery.')
    legacy=[]
    for product,archive_path in [('scatter',args.scatter_legacy),('analyzer',args.analyzer_legacy)]:
        folder=output/product;folder.mkdir();legacy.append(folder)
        names=('CyrusScatterStartup.ms','CyrusScatter.mcr') if product=='scatter' else ('CyrusSurfaceAnalyzerStartup.ms',)
        with zipfile.ZipFile(archive_path) as archive:
            if archive.testzip() is not None:raise ValueError('Legacy fixture archive CRC failed.')
            for name in names:(folder/name).write_bytes(archive.read(name))
    compiler=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
    framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
    source=ROOT/'tools/tests/fixtures/InstallerExeChecks.cs';probe=output/'InstallerExeChecks.exe'
    command=[str(compiler),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+',
             '/target:exe','/platform:x64','/out:'+str(probe),
             *('/reference:'+str(framework/name) for name in ('mscorlib.dll','System.dll','System.Core.dll','System.Drawing.dll','System.Windows.Forms.dll','System.IO.Compression.dll')),str(source)]
    subprocess.run(command,check=True,capture_output=True,text=True)
    temporary=output/'temp';temporary.mkdir();environment=dict(os.environ,TEMP=str(temporary),TMP=str(temporary))
    command=[str(probe),str(executable),build_inputs.digest(executable),str(output/'profiles'),*map(str,legacy)]
    result=subprocess.run(command,cwd=output,env=environment,capture_output=True,text=True,timeout=300)
    (output/'handler.log').write_text(result.stdout+result.stderr,encoding='utf-8')
    evidence={'schema':'cyrus.installer-exe-remediation/1','status':'pass' if result.returncode==0 else 'fail',
              'exit_code':result.returncode,'command':command,'exe_sha256':build_inputs.digest(executable),
              'exe_producer_receipt_sha256':build_inputs.digest(executable.with_suffix('.build.json')),
              'fixture_sha256':build_inputs.digest(source),'driver_sha256':build_inputs.digest(Path(__file__)),
              'compiled_fixture_sha256':build_inputs.digest(probe),
              'legacy_packages':{str(path.resolve()):build_inputs.digest(path) for path in (args.scatter_legacy,args.analyzer_legacy)},
              'scope':'Actual Primary.PerformClick handlers; Remove method direct; owned profiles and temporary directory; hostRunning delegate bypassed only after replacing targets; no Max launch or native plugin loading.'}
    (output/'receipt.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
    print(result.stdout[-16000:]+result.stderr)
    if result.returncode:raise SystemExit(result.returncode)


if __name__=='__main__':main()
