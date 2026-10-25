#include <max.h>
static_assert(MAX_PRODUCT_YEAR_NUMBER==2027);
extern "C" __declspec(dllimport) ClassDesc* CyrusVegetationDocumentDesc();
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Cyrus Vegetation Lab 0.1.0 storage - Max 2027");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 1;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int i){return i==0?CyrusVegetationDocumentDesc():nullptr;}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
BOOL WINAPI DllMain(HINSTANCE,DWORD,LPVOID){return TRUE;}
