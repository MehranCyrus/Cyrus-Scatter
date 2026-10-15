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
    panel->SetCategory(args[2]->to_int());
    if (args[1]->to_bool()) rollup->Show(index);
    else rollup->Hide(index);
    rollup->UpdateLayout();
    return &true_value;
}
