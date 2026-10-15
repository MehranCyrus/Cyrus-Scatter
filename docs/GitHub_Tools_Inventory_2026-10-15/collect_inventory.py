"""Read-only local tool inventory. Writes receipts only in this report folder."""
import hashlib
import importlib.metadata
import json
import os
import re
import shutil
import socket
import subprocess
import zipfile
from datetime import datetime, timezone
from pathlib import Path

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
LAB=Path('C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis')

def record(path, digest=False):
    p=Path(path);r=dict(path=p.as_posix(),exists=p.exists(),kind='directory' if p.is_dir() else 'file')
    if p.is_file():
        r['bytes']=p.stat().st_size
        if digest:r['sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
    return r

def main():
    config=json.loads((LAB/'tools.json').read_text());ghidra=Path(config['ghidra']);java=Path(config['java'])
    paths=[LAB/'tools.json',ghidra,ghidra/'ghidraRun.bat',ghidra/'support/analyzeHeadless.bat',
           ghidra/'GettingStarted.md',ghidra/'GettingStarted.html',ghidra/'docs/CheatSheet.html',
           ghidra/'docs/GhidraAPI_javadoc.zip',ghidra/'docs/README_PDB.html',ghidra/'Ghidra/application.properties',
           java,java/'bin/java.exe',java/'release',Path(config['mcp_jars'][0]),
           LAB/'tools/ghidra-mcp/GhidraMCP/extension.properties',
           LAB/'tools/downloads/GhidraMCP-6.0.0.zip',LAB/'tools/downloads/ghidra_mcp_bridge-6.0.0-py3-none-any.whl',
           LAB/'tools/downloads/ghidra.zip',LAB/'tools/downloads/jdk21.zip',
           LAB/'tools/reference-source',LAB/'start_headless.py',LAB/'mcp_request.py',LAB/'prepare_tools.py',
           LAB/'inspect_pe.py',LAB/'FULL-HANDOFF-REPORT.txt',LAB/'decompilation-findings.txt',LAB/'mcp-schema.json',
           LAB/'projects/tyFlowArchitecture.gpr',LAB/'projects/tyFlowArchitecture.rep',LAB/'decompiled',
           LAB/'inputs/tyFlow_2027.dlo',LAB/'research-20261006',LAB/'research-072-rnd-20261006']
    research=['TyFlow_Architecture_Research_2026-10-06/README.md','TyFlow_Architecture_Research_2026-10-06/CONTINUATION.md',
              'TyFlow_CyrusScatter_RnD_2026-10-06/README.md','ForestPack_Research_2026-10-08/README.md',
              'ForestPack_Research_2026-10-08/HANDOFF.md','ForestPack_Research_2026-10-08/brush/README.md',
              'Vendor_Surface_Paint_Research_2026-10-09/README.md','Vendor_Native_Deep_Research_2026-10-09/README.md',
              'Vendor_Native_Deep_Research_2026-10-09/CODE_MAP.md','Vendor_Native_Deep_Research_2026-10-09/reproduce/README.md',
              'Vendor_Native_Deep_Research_2026-10-09/reproduce/prepare_projects.py',
              'ForestPack_Research_2026-10-08/reproduce/backend.py','ForestPack_Research_2026-10-08/reproduce/export_selected.py',
              'TyFlow_Architecture_Research_2026-10-06/reproduce/static_pe.py']
    paths += [ROOT/'docs'/p for p in research]
    paths += [ROOT/'build'/run for run in ['forestpack-research-20261008-01','forest-brush-research-20261008-01',
              'vendor-surface-paint-20261009-01','vendor-native-deep-20261009-01']]
    for name in ['ChaosOwnership','ReceivingSurfaceCore','ForestPack943']:
        paths += [ROOT/'build/vendor-native-deep-20261009-01/projects'/(name+suffix) for suffix in ['.gpr','.rep']]
    path_records=[record(p,p.is_file() and p.stat().st_size<20_000_000) for p in paths]
    properties=dict(line.split('=',1) for line in (ghidra/'Ghidra/application.properties').read_text().splitlines() if '=' in line and not line.startswith('#'))
    release=dict(line.split('=',1) for line in (java/'release').read_text().splitlines() if '=' in line)
    executables=['ida.exe','ida64.exe','idat.exe','idat64.exe','ILSpy.exe','ilspycmd.exe','Cpp2IL.exe','Cpp2IL-Win.exe','rea.cmd','rea','um.exe','um.cmd','um']
    command_paths={n:shutil.which(n) for n in executables}
    roots=[Path(p) for p in ['C:/Program Files','C:/Program Files (x86)','C:/Users/Mehran/AppData/Local/Programs',
           'C:/Users/Mehran/Downloads','C:/Users/Mehran/Documents/ChatGPT/Play','F:/Cursor/_Cyrus_Apps']]
    pattern=re.compile(r'ghidra|hex.?rays|\bida\b|ilspy|cpp2il|universal.modder|(^|[-_])rea($|[-_])|anyps5|portps5|modding',re.I)
    matches=[]
    for root in roots:
        if root.is_dir():matches += [p.as_posix() for p in root.iterdir() if p.is_dir() and pattern.search(p.name)]
    candidate_files=[Path('C:/Users/Mehran/AppData/Roaming/npm')/n for n in ['rea.cmd','um.cmd']]
    candidate_files += [Path('C:/Users/Mehran/.dotnet/tools')/n for n in ['ilspycmd.exe','Cpp2IL.exe']]
    ports={}
    for port in [18089,18091]:
        with socket.socket() as sock:
            sock.settimeout(.5);ports[str(port)]=dict(connectable=sock.connect_ex(('127.0.0.1',port))==0)
    archives={}
    for name in ['GhidraMCP-6.0.0.zip','ghidra_mcp_bridge-6.0.0-py3-none-any.whl']:
        archive=LAB/'tools/downloads'/name
        with zipfile.ZipFile(archive) as z:
            archives[name]=dict(entries=z.namelist(),integrity_error=z.testzip())
    distributions=[dict(name=d.metadata['Name'],version=d.version) for d in importlib.metadata.distributions() if re.search('ghidra|cpp2il|ilspy',d.metadata.get('Name',''),re.I)]
    data=dict(checked_date='2026-10-15',checked_utc=datetime.now(timezone.utc).isoformat(),
              scope='Nine original GitHub references, installed native-analysis stack and associated research. Scoped checks, not a full disk/software inventory.',
              git=dict(branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),
                       head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
                       status=subprocess.check_output(['git','status','--short'],cwd=ROOT,text=True)),
              configured_versions=config['versions'],verified_ghidra_version=properties['application.version'],
              verified_java_version=release['JAVA_RUNTIME_VERSION'].strip('"'),files=path_records,
              path_commands=command_paths,checked_directory_roots=[r.as_posix() for r in roots],matching_top_level_directories=matches,
              checked_candidate_commands=[record(p) for p in candidate_files],current_python_related_distributions=distributions,
              localhost_ports=ports,archive_metadata=archives,
              runtime_limit='No backend, Max host or vendor binary launched. Historical successful analysis is documented separately; presence is not a fresh runtime pass.',
              not_found_limit='No other eight tool installations identified in checked locations/PATH. This does not prove absence from every disk, environment or application profile.')
    (HERE/'LOCAL_INVENTORY.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(dict(versions=[data['verified_ghidra_version'],data['verified_java_version']],paths=len(path_records),missing=[r['path'] for r in path_records if not r['exists']],commands_found={k:v for k,v in command_paths.items() if v},ports=ports,python_distributions=distributions),indent=2))

if __name__=='__main__':main()
