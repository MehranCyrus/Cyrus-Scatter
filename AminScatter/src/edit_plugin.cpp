#include <max.h>
static_assert(MAX_PRODUCT_YEAR_NUMBER == CYRUS_MAX_YEAR, "SDK year must match the configured host year");
extern "C" __declspec(dllimport) ClassDesc* CyrusEditDesc();
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Cyrus Scatter Edit");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 1;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int i){return i==0?CyrusEditDesc():nullptr;}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
