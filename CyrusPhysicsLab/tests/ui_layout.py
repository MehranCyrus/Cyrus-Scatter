"""Read owned rollout rectangles and font metrics; no pixels or OS input."""
from pathlib import Path
import ctypes as c
from ctypes import wintypes as w
import json
from pymxs import runtime as r

folder = Path(str(r.CPLTestDir)).resolve()
assert folder.parent.name == "build" and folder.name.startswith("physics-lab")
user = c.WinDLL("user32", use_last_error=True)
gdi = c.WinDLL("gdi32", use_last_error=True)
user.GetWindowRect.argtypes = [w.HWND, c.POINTER(w.RECT)]
user.GetClientRect.argtypes = [w.HWND, c.POINTER(w.RECT)]
user.IsWindowVisible.argtypes = [w.HWND]
user.SendMessageW.argtypes = [w.HWND, w.UINT, w.WPARAM, w.LPARAM]
user.SendMessageW.restype = w.LPARAM
user.GetDC.argtypes = [w.HWND]
user.GetDC.restype = w.HDC
user.ReleaseDC.argtypes = [w.HWND, w.HDC]
gdi.SelectObject.argtypes = [w.HDC, w.HANDLE]
gdi.SelectObject.restype = w.HANDLE
gdi.GetTextExtentPoint32W.argtypes = [w.HDC, w.LPCWSTR, c.c_int, c.POINTER(w.SIZE)]
results = []
names = ("brushHeader", "objectsUI", "brushUI", "collisionUI", "areaUI", "viewportUI", "resultUI")
for name in names:
    for other in names:
        getattr(r.CPLUILab, other).open = other == name
    page = getattr(r.CPLUILab, name)
    page.open = True
    r.execute("CPLUILab.refreshBindings()")
    r.windows.processPostedMessages()
    hwnd = int(page.hwnd)
    parent = w.RECT()
    assert user.GetWindowRect(hwnd, c.byref(parent))
    row = {"name": name, "width": int(page.width), "height": int(page.height), "scale": float(r.GetUIScaleFactor()), "controls": [], "items": []}
    for item in page.controls:
        try:
            handles = list(item.hwnd)
        except Exception as exc:
            row["items"].append({"item":str(item), "error":str(exc)})
            continue
        row["items"].append({"item":str(item), "visible":bool(item.visible), "handles":[int(h) for h in handles]})
        for handle in handles:
            handle = int(handle)
            if not handle or not item.visible:
                continue
            rect, client = w.RECT(), w.RECT()
            assert user.GetWindowRect(handle, c.byref(rect))
            assert user.GetClientRect(handle, c.byref(client))
            data = r.windows.getHWNDData(handle)
            klass, text = str(data[3]), str(data[4])
            if rect.right <= rect.left or rect.bottom <= rect.top or (klass == "Static" and not text):
                continue
            inside = rect.left >= parent.left - 1 and rect.top >= parent.top - 1 and rect.right <= parent.right + 1 and rect.bottom <= parent.bottom + 1
            glyphs_fit = True
            if text and klass.lower() in ("static", "button", "custbutton"):
                dc = user.GetDC(handle)
                font = user.SendMessageW(handle, 0x31, 0, 0)
                previous = gdi.SelectObject(dc, font) if font else None
                try:
                    widths = []
                    heights = []
                    for line in text.splitlines():
                        size = w.SIZE()
                        assert gdi.GetTextExtentPoint32W(dc, line, len(line), c.byref(size))
                        widths.append(size.cx)
                        heights.append(size.cy)
                    glyphs_fit = max(widths, default=0) <= client.right - 4 and sum(heights) <= client.bottom + 1
                finally:
                    if previous:
                        gdi.SelectObject(dc, previous)
                    user.ReleaseDC(handle, dc)
            row["controls"].append({"name": str(item.name), "class": klass, "text": text,
                                    "rect": [rect.left-parent.left, rect.top-parent.top, rect.right-parent.left, rect.bottom-parent.top],
                                    "inside": inside, "glyphs_fit": glyphs_fit})
    row["overlaps"] = []
    for i, first in enumerate(row["controls"]):
        for second in row["controls"][i+1:]:
            if first["name"] == second["name"]:
                continue
            a, b = first["rect"], second["rect"]
            if min(a[2], b[2])-max(a[0], b[0]) > 3 and min(a[3], b[3])-max(a[1], b[1]) > 3:
                row["overlaps"].append([first["name"], second["name"]])
    results.append(row)
(folder / "ui-layout.json").write_text(json.dumps(results, indent=2))
failures = [(row["name"], item) for row in results for item in row["controls"] if not item["inside"] or not item["glyphs_fit"]]
assert all(row["controls"] for row in results), results
assert not any(row["overlaps"] for row in results), [(row["name"], row["overlaps"]) for row in results]
assert not failures, failures
for name in names:
    getattr(r.CPLUILab, name).open = name in ("brushHeader", "objectsUI", "brushUI")
r.execute("CPLUILab.refreshBindings()")
