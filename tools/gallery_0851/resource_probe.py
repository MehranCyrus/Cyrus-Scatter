"""Post-soak diagnostic: .NET finalizers only, never MAXScript GC or Undo clearing."""
from pathlib import Path
import ctypes as c,json,uuid
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-gallery0851-')
def sample():
 k=c.WinDLL('kernel32');k.GetCurrentProcess.restype=c.c_void_p;handle=k.GetCurrentProcess()
 u=c.WinDLL('user32');u.GetGuiResources.argtypes=[c.c_void_p,c.c_uint];u.GetGuiResources.restype=c.c_uint
 return {'gdi':u.GetGuiResources(handle,0),'user':u.GetGuiResources(handle,1),
  'private_bytes':int(r.dotNetClass('System.Diagnostics.Process').GetCurrentProcess().PrivateMemorySize64)}
undo=list(r.theHold.GetUndoNames());redo=list(r.theHold.GetRedoNames())
before=sample();gc=r.dotNetClass('System.GC');gc.Collect();gc.WaitForPendingFinalizers();gc.Collect()
after=sample();assert undo==list(r.theHold.GetUndoNames()) and redo==list(r.theHold.GetRedoNames())
(OUT/('resource-probe-'+uuid.uuid4().hex+'.json')).write_text(json.dumps({'before':before,'after_dotnet_finalizers':after,'undo_preserved':True,
 'scope':'Post-soak diagnostic only; no product GC behavior change and no MAXScript full collection.'},indent=2),encoding='utf-8')
