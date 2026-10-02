#include <max.h>
extern "C" __declspec(dllimport) ClassDesc* CyrusPointProbeDesc();
extern "C" __declspec(dllexport) const MCHAR* LibDescription() { return _T("Cyrus retained point probe owner"); }
extern "C" __declspec(dllexport) ULONG LibVersion() { return VERSION_3DSMAX; }
extern "C" __declspec(dllexport) int LibNumberClasses() { return 1; }
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int index) { return index == 0 ? CyrusPointProbeDesc() : nullptr; }
extern "C" __declspec(dllexport) ULONG CanAutoDefer() { return 0; }
