// Owned-host SDK callback test only. No OS input, no product packaging.
#include <max.h>
#include <mouseman.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include <algorithm>
#include <string>
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("PRIVATE Cyrus creation callback test");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 0;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int){return nullptr;}
BOOL WINAPI DllMain(HINSTANCE,DWORD,LPVOID){return TRUE;}
def_visible_primitive(cyrusPrivateCreateEvent,"cyrusPrivateCreateEvent");
Value* cyrusPrivateCreateEvent_cf(Value** args,int count){
    check_arg_count(cyrusPrivateCreateEvent,4,count);
    std::wstring command=GetCommandLineW();std::replace(command.begin(),command.end(),L'\\',L'/');
    if(command.find(L"/build/mcp-qualification/refine0795-create-")==std::wstring::npos)
        throw RuntimeError(_T("Owned creation host required"));
    auto* ip=GetCOREInterface();auto* mode=ip->GetCommandMode();
    if(!mode || mode->Class()!=CREATE_COMMAND)throw RuntimeError(_T("Start object creation first"));
    int points=0;auto* callback=mode->MouseProc(&points);
    if(!callback)throw RuntimeError(_T("No active creation callback"));
    const int message=args[0]->to_int(),point=args[1]->to_int();
    if(message!=MOUSE_POINT && message!=MOUSE_MOVE && message!=MOUSE_ABORT)throw RuntimeError(_T("Unsupported test event"));
    auto& view=ip->GetActiveViewExp();if(!view.IsAlive())throw RuntimeError(_T("No active viewport"));
    return Integer::intern(callback->proc(view.GetHWnd(),message,point,0,IPoint2(args[2]->to_int(),args[3]->to_int())));
}
