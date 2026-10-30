// Private Max 2027 SDK exercise. Excluded from product/package.
#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)
extern "C" __declspec(dllexport) void LibInit(){}
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return L"Cyrus selection qualification only";}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 0;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int){return nullptr;}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) ULONG CanAutoDefer(){return 0;}
def_visible_primitive(selectionProbeNode,"selectionProbeNode");
Value* selectionProbeNode_cf(Value** a,int count){check_arg_count(selectionProbeNode,2,count);auto* ip=GetCOREInterface();auto& v=ip->GetActiveViewExp();auto* n=ip->PickNode(v.GetHWnd(),IPoint2(a[0]->to_int(),a[1]->to_int()));return n?static_cast<Value*>(MAXNode::intern(n)):&undefined;}
def_visible_primitive(selectionProbeSub,"selectionProbeSub");
Value* selectionProbeSub_cf(Value** a,int count){
 check_arg_count(selectionProbeSub,3,count);auto* ip=GetCOREInterface();auto& v=ip->GetActiveViewExp();IPoint2 p(a[0]->to_int(),a[1]->to_int());v.ClearSubObjHitList();
 ip->SubObHitTest(ip->GetTime(),HITTYPE_POINT,0,0,&p,&v);
 auto* record=v.GetSubObjHitList().First();
 if(!record)return &undefined;
 if(a[2]->to_bool()){auto* edit=dynamic_cast<Modifier*>(ip->GetCurEditObject());if(edit){edit->ClearSelection(1);edit->SelectSubComponent(record,TRUE,FALSE,FALSE);}}
 return Integer::intern(int(record->hitInfo));
}

#include <windowsx.h>
def_visible_primitive(selectionProbeHover,"selectionProbeHover");
Value* selectionProbeHover_cf(Value** a,int count){check_arg_count(selectionProbeHover,2,count);auto* ip=GetCOREInterface();auto& v=ip->GetActiveViewExp();auto hwnd=v.GetHWnd();POINT pixel{a[0]->to_int(),a[1]->to_int()};POINT screen=pixel;ClientToScreen(hwnd,&screen);SetForegroundWindow(ip->GetMAXHWnd());SetCursorPos(screen.x,screen.y);SendMessageW(hwnd,WM_MOUSEMOVE,0,MAKELPARAM(pixel.x,pixel.y));return &ok;}
def_visible_primitive(selectionProbeClick,"selectionProbeClick");
Value* selectionProbeClick_cf(Value** a,int count){check_arg_count(selectionProbeClick,2,count);auto* ip=GetCOREInterface();auto& v=ip->GetActiveViewExp();auto hwnd=v.GetHWnd();auto p=MAKELPARAM(a[0]->to_int(),a[1]->to_int());SendMessageW(hwnd,WM_LBUTTONDOWN,MK_LBUTTON,p);SendMessageW(hwnd,WM_LBUTTONUP,0,p);return &ok;}
def_visible_primitive(selectionProbeOwnHighlight,"selectionProbeOwnHighlight");
Value* selectionProbeOwnHighlight_cf(Value** a,int count){check_arg_count(selectionProbeOwnHighlight,1,count);auto* n=a[0]->to_node();return Integer::intern(n->GetObjectRef()->DoOwnSelectHilite());}
