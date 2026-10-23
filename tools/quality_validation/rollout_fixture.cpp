// Private Max 2027 SDK fixture: not registered or packaged as a product plugin.
#include <max.h>
#include <irollupsettings.h>
#include <limits>

static IRollupWindow* ownedRollup(HWND page) {
    if (!IsWindow(page) || GetWindowThreadProcessId(page,nullptr)!=GetCurrentThreadId()) return nullptr;
    auto* rollup=GetCOREInterface()->GetCommandPanelRollup();
    return rollup && rollup->GetPanelIndex(page)>=0 && rollup->GetPanel(page) ? rollup : nullptr;
}
extern "C" __declspec(dllexport) int qRolloutCategory(HWND page) {
    auto* rollup=ownedRollup(page);
    return rollup ? rollup->GetPanel(page)->GetCategory() : std::numeric_limits<int>::min();
}
extern "C" __declspec(dllexport) int qArrangeContainer(HWND page,int category) {
    auto* rollup=ownedRollup(page);
    auto* settings=GetIRollupSettings();
    if (!rollup || !settings || !settings->GetCatReg()) return 0;
    rollup->GetPanel(page)->SetCategory(category);
    settings->GetCatReg()->UpdateCat(GEOMOBJECT_CLASS_ID,Class_ID(0x617d43a1,0x395c2e17),_T("Source containers"),category);
    settings->GetCatReg()->Save();rollup->UpdateLayout();return 1;
}
