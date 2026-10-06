"""Start an ordinary Cyrus build in a fully redirected, disposable Max profile."""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/source_container_preview'))
from launch import DIRECTORIES
sys.path.insert(0,str(ROOT/'tools'))
from build_max import reject_development_binary


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def launch(folder,script,native,extra='',transport=False,visible=False,extra_modules=()):
    folder=Path(folder).resolve();script=Path(script).resolve();native=Path(native).resolve()
    if not folder.is_relative_to(ROOT/'build'):
        raise ValueError('An ignored private build directory is required')
    folder.mkdir(parents=True,exist_ok=False)
    for rel in ['bin',*DIRECTORIES.values()]:(folder/rel).mkdir(parents=True,exist_ok=True)
    profile=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
    ini=profile.read_text(encoding='utf-16')
    for key,rel in DIRECTORIES.items():
        ini,count=re.subn(r'(?m)^'+re.escape(key)+'=.*$',lambda _:key+'='+str(folder/rel),ini)
        if count!=1:raise RuntimeError('Private profile key missing or ambiguous: '+key)
    (folder/'max.ini').write_text(ini,encoding='utf-16')
    modules={}
    for name in ['AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm',*extra_modules]:
        if Path(name).name!=name:
            raise ValueError('Extra module must be a filename in the staged native directory')
        reject_development_binary(name,(native/name).read_bytes())
        destination=folder/'bin'/name;shutil.copy2(native/name,destination)
        modules[name]=digest(destination)
    copied=folder/'scripts/CyrusScatter.ms';shutil.copy2(script,copied)
    (folder/'plugins.ini').write_text('[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns\nCyrusPrivate='+str(folder/'bin')+'\n[Help]\n')
    expected=','.join('#(@"'+name+'",@"'+str(folder/'bin'/name)+'")' for name in modules)
    bootstrap='global AminScatterObject,CyrusPerfHeadless=true,MCPFixtureDir=@"'+folder.as_posix()+'/"\n'
    if transport:
        bootstrap+='fileIn @"'+(ROOT/'tools/mcp/development_transport.ms').as_posix()+'"\n'
    bootstrap+='''try (
        local expected=#(__EXPECTED__),p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
        local log=createFile (MCPFixtureDir+"loaded.tsv")
        for spec in expected do (
            local found=false
            for i=0 to p.Modules.Count-1 do (
                local module=p.Modules.Item[i]
                if toLower module.ModuleName==toLower spec[1] do (
                    if toLower module.FileName!=toLower spec[2] do throw ("Mixed native module: "+module.FileName)
                    found=true;format "%\\t%\\n" module.ModuleName module.FileName to:log
                )
            )
            if not found do throw ("Missing module: "+spec[1])
        )
        close log
        fileIn @"__SCRIPT__"
        __EXTRA__
        (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"ready.json") "{}"
    )catch((dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"startup-error.txt") (getCurrentException()+"\\n"+getCurrentExceptionStackTrace()))
'''.replace('__EXPECTED__',expected).replace('__SCRIPT__',copied.as_posix()).replace('__EXTRA__',extra)
    start=folder/'start.ms';start.write_text(bootstrap,encoding='utf-8-sig')
    command=['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe','-q','-i',str(folder/'max.ini'),'-p',str(folder/'plugins.ini'),'-U','MAXScript',str(start),'-listenerlog',str(folder/'listener.log')]
    startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=1 if visible else 0
    process=subprocess.Popen(command,cwd=folder,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=startup)
    metadata={'pid':process.pid,'output':str(folder),'command':command,'binaries':modules,
              'script_sha256':digest(copied),'normal_profile_modified':False,'development_transport':transport}
    (folder/'launch.json').write_text(json.dumps(metadata,indent=2)+'\n')
    return process,metadata
