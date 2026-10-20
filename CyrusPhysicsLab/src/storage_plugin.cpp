#include <max.h>
extern "C" __declspec(dllimport) ClassDesc* CyrusPhysicsDocumentDesc();
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Cyrus Physics Lab 0.1.9 storage");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 1;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int i){return i==0?CyrusPhysicsDocumentDesc():nullptr;}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
BOOL WINAPI DllMain(HINSTANCE,DWORD,LPVOID){return TRUE;}
