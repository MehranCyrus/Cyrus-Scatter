#include <max.h>
static_assert(MAX_PRODUCT_YEAR_NUMBER == CYRUS_MAX_YEAR, "SDK year must match the configured host year");
extern "C" __declspec(dllimport) ClassDesc* CyrusEditDesc();
extern "C" __declspec(dllimport) ClassDesc* CyrusPointDisplayDesc();
#ifdef CYRUS_NATIVE_LICENSE_EXPERIMENT
extern "C" __declspec(dllimport) ClassDesc* CyrusOwnedRevisionDesc();
#endif
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Cyrus Scatter Edit");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){
#ifdef CYRUS_NATIVE_LICENSE_EXPERIMENT
return 3;
#else
return 2;
#endif
}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int i){
#ifdef CYRUS_NATIVE_LICENSE_EXPERIMENT
if(i==2)return CyrusOwnedRevisionDesc();
#endif
return i==0?CyrusEditDesc():(i==1?CyrusPointDisplayDesc():nullptr);}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
