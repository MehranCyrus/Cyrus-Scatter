"""Exercise the actual native dropdown inside the owned Max test process."""
from pathlib import Path
import ctypes
from pymxs import runtime as r

out = Path(str(r.MCPFixtureDir)).resolve()
assert out.name.startswith('foundation-roadmap-p04-')


def p04_choose_resolution(index):
    root = r.modPanel.getCurrentObject()
    control = root.populationUI.distributionUI_resolutionList
    user = ctypes.WinDLL('user32', use_last_error=True)
    user.GetClassNameW.argtypes = [ctypes.c_void_p, ctypes.c_wchar_p, ctypes.c_int]
    user.GetParent.argtypes = [ctypes.c_void_p]; user.GetParent.restype = ctypes.c_void_p
    user.GetDlgCtrlID.argtypes = [ctypes.c_void_p]; user.GetDlgCtrlID.restype = ctypes.c_int
    user.SendMessageW.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_size_t, ctypes.c_ssize_t]
    user.SendMessageW.restype = ctypes.c_ssize_t
    combos = []
    for value in control.hwnd:
        handle = int(value); name = ctypes.create_unicode_buffer(256)
        user.GetClassNameW(handle, name, 256)
        if name.value.lower() == 'combobox':
            combos.append(handle)
    assert len(combos) == 1, 'Expected the control-owned native ComboBox: ' + str(list(control.hwnd))
    handle = combos[0]
    assert user.SendMessageW(handle, 0x146, 0, 0) == 4  # CB_GETCOUNT
    assert user.SendMessageW(handle, 0x14E, index - 1, 0) == index - 1  # CB_SETCURSEL
    # CBN_SELENDOK, dispatched to this control's actual parent, in this host thread.
    user.SendMessageW(user.GetParent(handle), 0x111, user.GetDlgCtrlID(handle) | (9 << 16), handle)
