#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/macros/define_instantiation_functions.h>

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
