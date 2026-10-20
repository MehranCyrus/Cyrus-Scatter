#include <max.h>
static_assert(MAX_PRODUCT_YEAR_NUMBER==2027,"Arrange storage requires Max 2027");
extern "C" __declspec(dllimport) ClassDesc* CyrusArrangeDocumentDesc();
extern "C" __declspec(dllimport) ClassDesc* CyrusArrangeOwnerDesc();
extern "C" __declspec(dllimport) ClassDesc* CyrusArrangeModifierDesc();
extern "C" __declspec(dllimport) ClassDesc* CyrusArrangeIconDesc();
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Cyrus Arrange 0.3.2 native scene ownership and Modify interface");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 4;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int index){return index==0?CyrusArrangeDocumentDesc():index==1?CyrusArrangeOwnerDesc():index==2?CyrusArrangeModifierDesc():index==3?CyrusArrangeIconDesc():nullptr;}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
BOOL WINAPI DllMain(HINSTANCE,DWORD,LPVOID){return TRUE;}
