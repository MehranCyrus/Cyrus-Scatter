#include <max.h>
static_assert(MAX_PRODUCT_YEAR_NUMBER==2027);
extern "C" __declspec(dllimport) ClassDesc* CyrusStemDescriptor();
extern "C" __declspec(dllimport) ClassDesc* CyrusPreparationDescriptor();
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Cyrus Vegetation Stem Lab 0.3.1 geometry - Max 2027");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 2;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int i){return i==0?CyrusStemDescriptor():i==1?CyrusPreparationDescriptor():nullptr;}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
BOOL WINAPI DllMain(HINSTANCE,DWORD,LPVOID){return TRUE;}
