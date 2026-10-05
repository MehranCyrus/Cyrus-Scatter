#include <max.h>
#include <commctrl.h>
#include <windowsx.h>
#include <new>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/macros/define_instantiation_functions.h>

namespace {
// The nested MAXScript rollup containers fit their contents and cannot scroll.
// Route only their background gestures to the outer command-panel rollup.
// Child controls keep their native input handling; no scene work runs here.
struct ScrollBinding {
    HWND root;
    bool background;
};

constexpr UINT_PTR subclassId = 0x43595343; // CYSC

HWND gestureTargetFor(HWND root) {
    auto* rollup=GetCOREInterface()->GetCommandPanelRollup();
    auto* panel=rollup ? rollup->GetPanel(root) : nullptr;
    // GetHwnd() describes the aggregate interface's first content panel, not
    // every native column. GetRollupWindowHWND() is null on Max 2027's Qt
    // panels. After checking native ownership, forward to the page's actual
    // parent so Qt propagates the gesture through its current column. Resolve
    // it on every gesture: widening can reparent the same live page.
    return panel && panel->GetHWnd()==root ? GetParent(root) : nullptr;
}

LRESULT CALLBACK scrollProc(HWND window, UINT message, WPARAM wp, LPARAM lp,
                            UINT_PTR id, DWORD_PTR data) {
    auto* binding = reinterpret_cast<ScrollBinding*>(data);
    if (message == WM_NCDESTROY) {
        RemoveWindowSubclass(window, scrollProc, id);
        delete binding;
        return DefSubclassProc(window, message, wp, lp);
    }
    const bool mouseGesture = binding->background && (message == WM_LBUTTONDOWN ||
        message == WM_MOUSEMOVE || message == WM_LBUTTONUP);
    if ((message == WM_MOUSEWHEEL || mouseGesture) && IsWindow(binding->root) && IsChild(binding->root, window)) {
        const HWND target=gestureTargetFor(binding->root);
        if (!IsWindow(target) || !IsChild(target,binding->root))
            return DefSubclassProc(window, message, wp, lp);
        if (message == WM_MOUSEWHEEL) {
            return SendMessage(target, message, wp, lp);
        }
        if (mouseGesture) {
            if (auto* rollup = GetCOREInterface()->GetCommandPanelRollup()) {
                POINT point{GET_X_LPARAM(lp), GET_Y_LPARAM(lp)};
                MapWindowPoints(window, binding->root, &point, 1);
                rollup->DlgMouseMessage(binding->root, message, wp,
                    MAKELPARAM(point.x, point.y));
                return 0;
            }
        }
    }
    return DefSubclassProc(window, message, wp, lp);
}

struct InstallContext { HWND root; int count = 0; };

BOOL CALLBACK installChild(HWND window, LPARAM parameter) {
    auto& context = *reinterpret_cast<InstallContext*>(parameter);
    wchar_t name[128]{};
    GetClassNameW(window, name, 128);
    const bool background = wcscmp(name, L"#32770") == 0;
    const bool rollup = wcscmp(name, L"RollupWindow") == 0;
    // Qt-owned rollup headers also receive wheel messages. Their click/drag
    // handling is deliberately untouched, so headers still expand/reorder.
    const bool qt = wcsncmp(name, L"Qt", 2) == 0;
    if (!background && !rollup && !qt) return TRUE;
    DWORD_PTR existing = 0;
    if (GetWindowSubclass(window, scrollProc, subclassId, &existing)) {
        auto* binding = reinterpret_cast<ScrollBinding*>(existing);
        binding->root = context.root;
        ++context.count;
        return TRUE;
    }
    auto* binding = new (std::nothrow) ScrollBinding{context.root, background};
    if (!binding) return FALSE;
    if (SetWindowSubclass(window, scrollProc, subclassId,
                          reinterpret_cast<DWORD_PTR>(binding))) ++context.count;
    else delete binding;
    return TRUE;
}

BOOL CALLBACK detachChild(HWND window, LPARAM) {
    DWORD_PTR data = 0;
    if (GetWindowSubclass(window, scrollProc, subclassId, &data)) {
        RemoveWindowSubclass(window, scrollProc, subclassId);
        delete reinterpret_cast<ScrollBinding*>(data);
    }
    return TRUE;
}
}

// Read-only ownership evidence for private host qualification. Handles must
// never be used as saved scene identities.
def_visible_primitive(cyrusRolloutScrollInfo, "cyrusRolloutScrollInfo");
Value* cyrusRolloutScrollInfo_cf(Value** args,int count) {
    check_arg_count(cyrusRolloutScrollInfo,1,count);
    const auto root=reinterpret_cast<HWND>(args[0]->to_intptr());
    if(!IsWindow(root)||GetWindowThreadProcessId(root,nullptr)!=GetCurrentThreadId())return &undefined;
    auto* rollup=GetCOREInterface()->GetCommandPanelRollup();
    auto* panel=rollup?rollup->GetPanel(root):nullptr;
    one_typed_value_local(Array* result);vl.result=new Array(12);
    for(auto h:{root,rollup?rollup->GetHwnd():nullptr,panel?panel->GetHWnd():nullptr,panel?panel->GetRollupWindowHWND():nullptr,panel?panel->GetPanelWnd():nullptr})
        vl.result->append(Integer64::intern(reinterpret_cast<INT64>(h)));
    auto h=GetParent(root);for(int i=0;h&&i<7;++i,h=GetParent(h))vl.result->append(Integer64::intern(reinterpret_cast<INT64>(h)));
    return_value(vl.result);
}

def_visible_primitive(cyrusBindRolloutScroll, "cyrusBindRolloutScroll");
Value* cyrusBindRolloutScroll_cf(Value** args, int count) {
    check_arg_count(cyrusBindRolloutScroll, 1, count);
    const auto root = reinterpret_cast<HWND>(args[0]->to_intptr());
    if (!IsWindow(root) || GetWindowThreadProcessId(root, nullptr) != GetCurrentThreadId())
        return Integer::intern(0);
    const HWND target=gestureTargetFor(root);
    if (!target || !IsChild(target, root)) return Integer::intern(0);
    InstallContext context{root};
    EnumChildWindows(root, installChild, reinterpret_cast<LPARAM>(&context));
    return Integer::intern(context.count);
}

def_visible_primitive(cyrusReleaseRolloutScroll, "cyrusReleaseRolloutScroll");
Value* cyrusReleaseRolloutScroll_cf(Value** args, int count) {
    check_arg_count(cyrusReleaseRolloutScroll, 1, count);
    const auto root = reinterpret_cast<HWND>(args[0]->to_intptr());
    if (IsWindow(root) && GetWindowThreadProcessId(root, nullptr) == GetCurrentThreadId())
        EnumChildWindows(root, detachChild, 0);
    return &ok;
}
