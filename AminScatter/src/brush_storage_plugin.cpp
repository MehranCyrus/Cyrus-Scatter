// Scene class registration companion to the MAXScript extension.
// Keep both binaries together; this module owns no duplicated Brush state.
#include <max.h>
extern "C" __declspec(dllimport) ClassDesc* CyrusBrushDocumentDesc();
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Cyrus Scatter 1.0 Brush document registration");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 1;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int i){return i==0?CyrusBrushDocumentDesc():nullptr;}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
BOOL WINAPI DllMain(HINSTANCE,DWORD,LPVOID){return TRUE;}
