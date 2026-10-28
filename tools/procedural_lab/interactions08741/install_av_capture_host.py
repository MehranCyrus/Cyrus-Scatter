"""Install a scoped, non-handling access-violation recorder in an owned Max host."""
from pathlib import Path
import builtins, ctypes, json, traceback
from pymxs import runtime as r

host=Path(str(r.GardenRun)); result={'status':'running'}
try:
    root=Path(__file__).resolve().parents[3]
    dll=root/'build/interactions08741-20261027-01/measurement-tools/capture_av.dll'
    capture=ctypes.WinDLL(str(dll))
    capture.install_capture.argtypes=[ctypes.c_wchar_p];capture.install_capture.restype=ctypes.c_int
    assert capture.install_capture(str(host))==1
    builtins._cyrus_08741_av_capture=capture
    result.update(status='installed',scope='Private Max process only; recorder continues normal exception handling')
except Exception:
    result.update(status='failed',error=traceback.format_exc())
(host/'av-capture-install.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
