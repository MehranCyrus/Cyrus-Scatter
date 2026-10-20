// PRIVATE, not packaged. Exercises Max's own object picking with numeric points.
#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include <algorithm>
#include <string>
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("PRIVATE Physics icon hit-test probe");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 0;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int){return nullptr;}
BOOL WINAPI DllMain(HINSTANCE,DWORD,LPVOID){return TRUE;}
def_visible_primitive(cplPrivateIconHit,"cplPrivateIconHit");
Value* cplPrivateIconHit_cf(Value** a,int n){check_arg_count(cplPrivateIconHit,2,n);std::wstring cmd=GetCommandLineW();std::replace(cmd.begin(),cmd.end(),L'\\',L'/');if(cmd.find(L"/build/physics-lab")==std::wstring::npos)throw RuntimeError(_T("Owned profile required"));auto* node=a[0]->to_node();auto& view=GetCOREInterface()->GetActiveViewExp();if(!view.IsAlive())throw RuntimeError(_T("Viewport required"));auto* gw=view.getGW();Point3 p=a[1]->to_point3();IPoint3 screen;gw->setTransform(Matrix3(1));gw->wTransPoint(&p,&screen);IPoint2 point(screen.x,screen.y);auto* object=node->EvalWorldState(GetCOREInterface()->GetTime()).obj;return bool_result(object&&object->HitTest(GetCOREInterface()->GetTime(),node,HITTYPE_POINT,0,HIT_ABORTONHIT,&point,&view));}
