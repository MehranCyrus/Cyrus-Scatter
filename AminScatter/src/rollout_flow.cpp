#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/macros/define_instantiation_functions.h>

// Measure using the actual native control font. MAXScript rollout heights are
// physical pixels, while control positions/sizes use logical UI units. Callers
// convert at that boundary and cache text/width results for unchanged views.
def_visible_primitive(cyrusMeasureWrappedText, "cyrusMeasureWrappedText");
Value* cyrusMeasureWrappedText_cf(Value** args, int count) {
    check_arg_count(cyrusMeasureWrappedText, 3, count);
    const auto window = reinterpret_cast<HWND>(args[0]->to_intptr());
    if (!IsWindow(window) || GetWindowThreadProcessId(window, nullptr) != GetCurrentThreadId())
        return Integer::intern(0);
    const int width = args[2]->to_int();
    if (width <= 0) return Integer::intern(0);
    const auto text = args[1]->to_string();
    HDC dc = GetDC(window);
    if (!dc) return Integer::intern(0);
    const auto font = reinterpret_cast<HFONT>(SendMessage(window, WM_GETFONT, 0, 0));
    const auto previous = font ? SelectObject(dc, font) : nullptr;
    RECT bounds{0, 0, width, 0};
    DrawText(dc, text, -1, &bounds, DT_CALCRECT | DT_WORDBREAK | DT_NOPREFIX);
    if (previous) SelectObject(dc, previous);
    ReleaseDC(window, dc);
    return Integer::intern(bounds.bottom - bounds.top);
}

// MAXScript cannot hide a command-panel rollout (its .visible property only
// applies to dialogs). Keep the declared layer slots in the native command
// panel and hide unused slots through the documented SDK. Max owns layout,
// columns, page lifetime and scrolling. No reparenting and no scene work.
def_visible_primitive(cyrusSetRolloutVisible, "cyrusSetRolloutVisible");
Value* cyrusSetRolloutVisible_cf(Value** args, int count) {
    check_arg_count(cyrusSetRolloutVisible, 3, count);
    const auto page = reinterpret_cast<HWND>(args[0]->to_intptr());
    if (!IsWindow(page) || GetWindowThreadProcessId(page, nullptr) != GetCurrentThreadId())
        return &false_value;
    // Use Max's command-panel interface, which owns all native columns.
    // Modern Qt hosts need not have a Win32 "RollupWindow" ancestor.
    auto* rollup=GetCOREInterface()->GetCommandPanelRollup();
    if (!rollup) return &false_value;
    const int index=rollup->GetPanelIndex(page);
    auto* panel=rollup->GetPanel(page);
    if (index<0 || rollup->GetPanelDlg(index)!=page || !panel)
        return &false_value;
    // Creation categories provide defaults. Max restores the artist's dragged
    // order from its category registry; visibility must not reset it.
    // Keep the third argument for the existing matched-script API.
    (void)args[2];
    if (args[1]->to_bool()) rollup->Show(index);
    else rollup->Hide(index);
    rollup->UpdateLayout();
    return &true_value;
}

// Qt command-panel reflow can erase the transparent captions of hosted Win32
// check/radio buttons without invalidating those children. Queue their own
// paint after layout settles; no scene work, owner rebinding or synchronous
// nested painting. The script coalesces resize/rollup requests into one tick.
def_visible_primitive(cyrusRepaintRolloutButtons, "cyrusRepaintRolloutButtons");
Value* cyrusRepaintRolloutButtons_cf(Value** args, int count) {
    check_arg_count(cyrusRepaintRolloutButtons, 1, count);
    const auto page = reinterpret_cast<HWND>(args[0]->to_intptr());
    if (!IsWindow(page) || GetWindowThreadProcessId(page, nullptr) != GetCurrentThreadId())
        return Integer::intern(0);
    unsigned painted=0;
    EnumChildWindows(page, [](HWND child, LPARAM context)->BOOL {
        auto& count=*reinterpret_cast<unsigned*>(context);
        if(count>=2048)return FALSE;
        wchar_t name[32]{};
        if(IsWindowVisible(child) && GetClassNameW(child,name,32) && wcscmp(name,L"Button")==0) {
            RedrawWindow(child,nullptr,nullptr,RDW_INVALIDATE|RDW_ERASE);
            ++count;
        }
        return TRUE;
    }, reinterpret_cast<LPARAM>(&painted));
    return Integer::intern(int(painted));
}
