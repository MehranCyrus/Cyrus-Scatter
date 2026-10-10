// Test-only SDK callback driver. Never linked into or packaged with Cyrus.
#include <max.h>
#include <IPainterInterface.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include <string>
#include <algorithm>
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("PRIVATE Cyrus Painter callback qualification");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 0;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int){return nullptr;}
BOOL WINAPI DllMain(HINSTANCE,DWORD,LPVOID){return TRUE;}
def_visible_primitive(cyrusPrivatePaintPath,"cyrusPrivatePaintPath");
def_visible_primitive(cyrusPrivatePaintContinue,"cyrusPrivatePaintContinue");
def_visible_primitive(cyrusPrivatePainterSample,"cyrusPrivatePainterSample");
namespace {
Value* drive(Value** args,bool finish){
    std::wstring command=GetCommandLineW();std::replace(command.begin(),command.end(),L'\\',L'/');
    if(command.find(L"/build/vector-brush-078/")==std::wstring::npos)throw RuntimeError(_T("Owned vector host required"));
    auto* document=args[0]->to_reftarg();
    if(!document||document->ClassID()!=Class_ID(0x5c743810,0x229f3ab6))throw RuntimeError(_T("Expected vector document"));
    auto* canvas=static_cast<IPainterCanvasInterface_V5*>(document->GetInterface(PAINTERCANVASINTERFACE_V5));
    auto* ref=static_cast<ReferenceTarget*>(GetCOREInterface()->CreateInstance(REF_TARGET_CLASS_ID,PAINTERINTERFACE_CLASS_ID));
    auto* painter=static_cast<IPainterInterface_V14*>(ref->GetInterface(PAINTERINTERFACE_V14));
    if(!canvas||!painter||!painter->InPaintMode())throw RuntimeError(_T("Button must start Painter before this probe"));
    type_check(args[1],Array,_T("world path"));auto* path=static_cast<Array*>(args[1]);
    if(path->size<1||path->size>1000)throw RuntimeError(_T("Path size outside diagnostic bounds"));
    auto& view=GetCOREInterface()->GetActiveViewExp();auto* gw=view.getGW();
    if(!view.IsAlive()||!gw)throw RuntimeError(_T("Live viewport required"));
    gw->setTransform(Matrix3(1));if(!canvas->StartStroke())throw RuntimeError(_T("StartStroke failed"));
    int hits=0;
    for(int i=0;i<path->size;++i){
        Point3 p=path->data[i]->to_point3();IPoint3 screen;gw->wTransPoint(&p,&screen);IPoint2 mouse(screen.x,screen.y);
        Point3 world{},normal{},local{},localNormal{},bary{},mw{},mn{},ml{},mln{};int face=-1;BOOL mirror=FALSE;
        auto* node=static_cast<INode*>(document->GetReference(0));
        const BOOL hit=painter->TestHit(mouse,world,normal,local,localNormal,bary,face,node,mirror,mw,mn,ml,mln);
        if(hit)++hits;
        if(!canvas->PaintStroke(hit,mouse,world,normal,local,localNormal,bary,face,FALSE,FALSE,FALSE,painter->GetMaxSize(),1,1,node,FALSE,{},{},{},{})){
            canvas->CancelStroke();throw RuntimeError(_T("PaintStroke failed"));
        }
    }
    if(finish){
        const bool cancel=args[2]->to_bool()!=FALSE;
        if(!(cancel?canvas->CancelStroke():canvas->EndStroke()))throw RuntimeError(_T("Stroke completion failed"));
    }
    return Integer::intern(hits);
}
}
Value* cyrusPrivatePaintPath_cf(Value** args,int count){check_arg_count(cyrusPrivatePaintPath,3,count);return drive(args,true);}
Value* cyrusPrivatePaintContinue_cf(Value** args,int count){check_arg_count(cyrusPrivatePaintContinue,2,count);return drive(args,false);}
// Measure the installed Painter's own stored radius; no OS mouse messages.
Value* cyrusPrivatePainterSample_cf(Value** args,int count){
    check_arg_count(cyrusPrivatePainterSample,2,count);
    std::wstring command=GetCommandLineW();std::replace(command.begin(),command.end(),L'\\',L'/');
    if(command.find(L"/build/vector-brush-078/")==std::wstring::npos)throw RuntimeError(_T("Owned vector host required"));
    auto* document=args[0]->to_reftarg();
    if(!document||document->ClassID()!=Class_ID(0x5c743810,0x229f3ab6))throw RuntimeError(_T("Expected vector document"));
    auto* ref=static_cast<ReferenceTarget*>(GetCOREInterface()->CreateInstance(REF_TARGET_CLASS_ID,PAINTERINTERFACE_CLASS_ID));
    auto* painter=static_cast<IPainterInterface_V14*>(ref->GetInterface(PAINTERINTERFACE_V14));
    if(!painter||!painter->InPaintMode())throw RuntimeError(_T("Active Painter required"));
    auto& view=GetCOREInterface()->GetActiveViewExp();auto* gw=view.getGW();
    if(!view.IsAlive()||!gw)throw RuntimeError(_T("Live viewport required"));
    Point3 p=args[1]->to_point3();IPoint3 screen;gw->setTransform(Matrix3(1));gw->wTransPoint(&p,&screen);
    painter->ClearStroke();
    if(!painter->AddToStroke(IPoint2(screen.x,screen.y),FALSE,FALSE)||painter->GetStrokeCount()!=1)throw RuntimeError(_T("Painter sample missed receiver"));
    one_typed_value_local(Array* result);vl.result=new Array(4);
    vl.result->append(Float::intern(painter->GetMinSize()));vl.result->append(Float::intern(painter->GetMaxSize()));
    vl.result->append(Float::intern(painter->GetStrokeRadius()[0]));vl.result->append(new Point3Value(painter->GetStrokePointWorld()[0]));
    painter->ClearStroke();return_value(vl.result);
}
