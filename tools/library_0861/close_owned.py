"""Gracefully close only the explicitly recorded disposable qualification hosts."""
from pathlib import Path
import ctypes,json,sys
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import send
kernel=ctypes.WinDLL('kernel32',use_last_error=True);kernel.OpenProcess.restype=ctypes.c_void_p;kernel.OpenProcess.argtypes=[ctypes.c_uint,ctypes.c_int,ctypes.c_uint]
kernel.QueryFullProcessImageNameW.argtypes=[ctypes.c_void_p,ctypes.c_uint,ctypes.c_wchar_p,ctypes.POINTER(ctypes.c_uint)];kernel.WaitForSingleObject.argtypes=[ctypes.c_void_p,ctypes.c_uint];kernel.CloseHandle.argtypes=[ctypes.c_void_p]
for host in sorted((ROOT/'build/mcp-qualification').glob('library-surface0861-*')):
 record=host/'launch.json'
 if not record.is_file():continue
 launch=json.loads(record.read_text());assert Path(launch['output']).resolve()==host.resolve()
 handle=kernel.OpenProcess(0x1000|0x100000,False,launch['pid'])
 if not handle:continue
 try:
  if kernel.WaitForSingleObject(handle,0)==0:continue
  buffer=ctypes.create_unicode_buffer(32768);size=ctypes.c_uint(len(buffer));assert kernel.QueryFullProcessImageNameW(handle,0,buffer,ctypes.byref(size))
  assert Path(buffer.value).resolve()==Path(f'C:/Program Files/Autodesk/3ds Max {launch["max_year"]}/3dsmax.exe').resolve()
  script=host/'close-owned.ms';script.write_text('''(
if MCPFixtureDir!=@"'''+host.as_posix()+'''/" do throw "Not the recorded owned profile"
for dialog in #(CyrusRecipeBrowser,CyrusReadyPresetEditor,CyrusRecipeSaveEditor,CyrusPresetSaveEditor) where dialog!=undefined do try(destroyDialog dialog)catch()
resetMaxFile #noPrompt
MCPFixtureTimer.Stop()
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"dev-result.txt") ("SUCCESS "+MCPFixtureLast)
(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"shutdown.txt") "Owned host closed after qualification; artist profiles untouched"
quitMax #noPrompt
)''',encoding='utf-8-sig')
  send(host,script,'Close owned PID '+str(launch['pid']))
  assert kernel.WaitForSingleObject(handle,30000)==0,'Observe owned process exit before retrying'
 finally:kernel.CloseHandle(handle)
