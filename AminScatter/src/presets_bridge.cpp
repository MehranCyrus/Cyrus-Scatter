#include <max.h>
#include <icurvctl.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include "presets.h"
#include <stdexcept>
#include <algorithm>
#include <memory>
#include <unordered_set>

namespace {
namespace p=cyrus::presets;
std::string utf8(Value* value){
    type_check(value,String,_T("preset text"));const auto* text=value->to_string();
    if(wcslen(text)>p::maxBytes)throw RuntimeError(_T("Preset text exceeds the input limit"));
    const int n=WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,text,-1,nullptr,0,nullptr,nullptr);
    if(n<=0)throw RuntimeError(_T("Invalid preset Unicode text"));
    std::string result(static_cast<std::size_t>(n),'\0');
    WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,text,-1,result.data(),n,nullptr,nullptr);result.pop_back();return result;
}
Value* stringValue(const std::string& text){
    const int n=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,text.c_str(),-1,nullptr,0);
    if(n<=0)throw RuntimeError(_T("Invalid preset UTF-8"));
    std::wstring result(static_cast<std::size_t>(n),L'\0');
    MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,text.c_str(),-1,result.data(),n);return new String(result.c_str());
}
Array* array(Value* v){type_check(v,Array,_T("preset values"));return static_cast<Array*>(v);}
bool presetBoolean(Value* v){if(v!=&true_value&&v!=&false_value)throw RuntimeError(_T("Expected a Boolean preset value"));return v==&true_value;}
[[noreturn]] void fail(const std::exception& e){throw RuntimeError(_T("Preset: "),stringValue(e.what()));}

// MAXCurve wrappers retain ICurve, but their UI control pointer is raw. The
// MAXScript SDK drops the control owner when its rollout closes. Native curve
// history must keep that control alive through later Undo/Redo notifications.
// Host-thread only: this set contains active holds, never retired history.
std::unordered_set<ICurveCtl*> heldCurveControls;
std::size_t curveUndoRecords=0;
class CurveControlLifetime final : public RestoreObj {
    SingleRefMaker reference_;
    ICurveCtl* control_;
    bool held_=true;
    void releaseHold(){if(held_){heldCurveControls.erase(control_);held_=false;}}
public:
    explicit CurveControlLifetime(ICurveCtl* control):reference_(control),control_(control){
        heldCurveControls.insert(control);++curveUndoRecords;
    }
    ~CurveControlLifetime() override {releaseHold();--curveUndoRecords;}
    void EndHold() override {releaseHold();}
    void Restore(int) override {}
    void Redo() override {}
    int Size() override {return static_cast<int>(sizeof(*this));}
    MSTR Description() override {return _T("Cyrus curve control lifetime");}
};

ICurveCtl* curveControl(Value* value){
    auto* curve=value->to_reftarg();
    if(!curve)throw std::invalid_argument("Expected a live native curve");
    ICurveCtl* found=nullptr;DependentIterator iterator(curve);std::size_t visited=0;
    while(auto* dependent=iterator.Next()){
        if(++visited>1024)throw std::invalid_argument("Curve dependency inspection exceeds its bound");
        if(dependent->SuperClassID()!=REF_MAKER_CLASS_ID||dependent->ClassID()!=CURVE_CONTROL_CLASS_ID)continue;
        auto* candidate=static_cast<ICurveCtl*>(dependent);
        if(candidate->GetNumCurves()!=1||candidate->GetControlCurve(0)!=curve)continue;
        if(found&&found!=candidate)throw std::invalid_argument("Curve belongs to multiple controls");
        found=candidate;
    }
    if(!found)throw std::invalid_argument("Expected one native single-curve editor");
    return found;
}

p::Document prepareCurve(const p::Document& source,bool targetMultiplier){
    if(!p::curve(source.category))throw std::invalid_argument("Curve preparation requires a curve preset");
    if((source.category=="density_curve"&&targetMultiplier)||(source.multiplier&&!targetMultiplier))
        throw std::invalid_argument("Curve domain is incompatible with its target");
    // These SDK objects are transient, main-thread data. No dialog, owner,
    // scene node, persistent reference or native placement buffer is involved.
    // Restore every suspended state after releasing the private reference graph.
    SuspendAll passive(true,true,true,true,false,true,false,false);
    auto* control=static_cast<ICurveCtl*>(CreateInstance(REF_MAKER_CLASS_ID,CURVE_CONTROL_CLASS_ID));
    if(!control)throw std::runtime_error("Native curve evaluator is unavailable");
    SingleRefMaker reference(control);
    control->SetCCFlags(CC_NONE);control->SetNumCurves(1,FALSE);control->SetXRange(0.f,1.f);
    const auto largest=*std::max_element(source.samples.begin(),source.samples.end());
    control->SetYRange(0.f,static_cast<float>(targetMultiplier?std::max(200.,largest*100.):100.));
    auto* curve=control->GetControlCurve(0);
    if(!curve)throw std::runtime_error("Native curve evaluator did not create its curve");
    curve->SetCanBeAnimated(FALSE);
    const auto count=source.graph.empty()?source.samples.size():source.graph.size();
    curve->SetNumPts(static_cast<int>(count));
    for(std::size_t i=0;i<count;++i){
        CurvePoint point;
        if(source.graph.empty()){
            point.p=Point2(static_cast<float>(static_cast<double>(i)/(count-1)),static_cast<float>(source.samples[i]*100.));
            point.in=point.out=Point2(0.f,0.f);point.flags=CURVEP_CORNER;
        }else{
            const auto& v=source.graph[i];point.p=Point2(static_cast<float>(v[0]),static_cast<float>(v[1]));
            point.in=Point2(static_cast<float>(v[2]),static_cast<float>(v[3]));
            point.out=Point2(static_cast<float>(v[4]),static_cast<float>(v[5]));
            point.flags=(v[6]!=0?CURVEP_BEZIER:0)|(v[7]!=0?CURVEP_CORNER:0);
        }
        if(i==0||i+1==count)point.flags|=CURVEP_LOCKED_X|CURVEP_ENDPOINT;
        // The complete graph was validated before construction. New SDK points
        // initially share X=0; incremental neighbor constraints would collapse
        // valid later points before their neighbors have been restored.
        curve->SetPoint(0,static_cast<int>(i),&point,FALSE,FALSE);
    }
    std::vector<double> samples;samples.reserve(257);
    std::vector<std::array<double,8>> graph;graph.reserve(count);
    for(std::size_t i=0;i<count;++i){
        const auto point=curve->GetPoint(0,static_cast<int>(i));
        graph.push_back({point.p.x,point.p.y,point.in.x,point.in.y,point.out.x,point.out.y,
            (point.flags&CURVEP_BEZIER)?1.:0.,(point.flags&CURVEP_CORNER)?1.:0.});
    }
    for(int i=0;i<=256;++i){
        // Match curveTrace's Float percentage arithmetic, with the same native
        // evaluator and no approximate lookup table.
        const float value=curve->GetValue(0,static_cast<float>(i)/256.f,FALSE)/100.f;
        samples.push_back(value);
    }
    return p::preparedCurve(source,targetMultiplier,samples,graph);
}
}

def_visible_primitive(cyrusPresetTrackCurveUndo,"cyrusPresetTrackCurveUndo");
Value* cyrusPresetTrackCurveUndo_cf(Value** args,int count){
    check_arg_count(cyrusPresetTrackCurveUndo,1,count);
    if(!theHold.Holding()||theHold.RestoreOrRedoing())return &false_value;
    try{
        auto* control=curveControl(args[0]);
        if(heldCurveControls.count(control))return &true_value;
        if(heldCurveControls.size()>=16)throw std::invalid_argument("Too many curve controls in one authored hold");
        auto restore=std::make_unique<CurveControlLifetime>(control);
        if(!theHold.Put(restore.get()))throw std::runtime_error("Curve lifetime could not join its authored hold");
        restore.release();return &true_value;
    }catch(const std::exception& e){fail(e);}
}
def_visible_primitive(cyrusPresetCurveUndoInfo,"cyrusPresetCurveUndoInfo");
Value* cyrusPresetCurveUndoInfo_cf(Value**,int count){
    check_arg_count(cyrusPresetCurveUndoInfo,0,count);
    one_typed_value_local(Array* result);vl.result=new Array(2);
    vl.result->append(Integer::intern(static_cast<int>(curveUndoRecords)));
    vl.result->append(Integer::intern(static_cast<int>(heldCurveControls.size())));
    return_value(vl.result);
}

def_visible_primitive(cyrusPresetCurveVersion,"cyrusPresetCurveVersion");
Value* cyrusPresetCurveVersion_cf(Value**,int count){check_arg_count(cyrusPresetCurveVersion,0,count);return Integer::intern(1);}
def_visible_primitive(cyrusPresetPrepareCurve,"cyrusPresetPrepareCurve");
Value* cyrusPresetPrepareCurve_cf(Value** args,int count){
    check_arg_count(cyrusPresetPrepareCurve,2,count);
    try{return stringValue(p::serialize(prepareCurve(p::parse(utf8(args[0])),presetBoolean(args[1]))));}
    catch(const std::exception& e){fail(e);}
}

def_visible_primitive(cyrusPresetVersion,"cyrusPresetVersion");
Value* cyrusPresetVersion_cf(Value**,int count){check_arg_count(cyrusPresetVersion,0,count);return Integer::intern(3);}
def_visible_primitive(cyrusPresetSchema,"cyrusPresetSchema");
Value* cyrusPresetSchema_cf(Value** args,int count){
    check_arg_count(cyrusPresetSchema,1,count);
    try{const auto& fields=p::fields(utf8(args[0]));
        two_typed_value_locals(Array* result,Array* row);vl.result=new Array(static_cast<int>(fields.size()));
        for(const auto& f:fields){vl.row=new Array(3);vl.row->append(stringValue(f.name));vl.row->append(Integer::intern(static_cast<int>(f.kind)+1));vl.row->append(f.distance?&true_value:&false_value);vl.result->append(vl.row);}
        return_value(vl.result);
    }catch(const std::exception& e){fail(e);}
}
def_visible_primitive(cyrusPresetEncode,"cyrusPresetEncode");
Value* cyrusPresetEncode_cf(Value** args,int count){
    check_arg_count(cyrusPresetEncode,3,count);
    try{p::Document d;d.category=utf8(args[0]);d.name=utf8(args[1]);auto* values=array(args[2]);
        if(p::curve(d.category)){
            if(values->size!=3)throw RuntimeError(_T("Expected samples, graph and curve domain"));
            auto* samples=array(values->data[0]);auto* graph=array(values->data[1]);
            if(samples->size>257||graph->size>257*8||graph->size%8)throw RuntimeError(_T("Preset curve exceeds bounded dimensions"));
            for(int i=0;i<samples->size;++i)d.samples.push_back(samples->data[i]->to_double());
            for(int i=0;i<graph->size;i+=8){std::array<double,8> row{};for(int k=0;k<8;++k)row[k]=graph->data[i+k]->to_double();d.graph.push_back(row);}
            d.multiplier=presetBoolean(values->data[2]);
        }else{const auto& spec=p::fields(d.category);
            if(values->size!=static_cast<int>(spec.size()))throw RuntimeError(_T("Preset category value count mismatch"));
            for(int i=0;i<values->size;++i)d.values.push_back(spec[i].kind==p::Kind::boolean?(presetBoolean(values->data[i])?1.:0.):values->data[i]->to_double());
        }
        return stringValue(p::serialize(d));
    }catch(const std::exception& e){fail(e);}
}
def_visible_primitive(cyrusPresetDecode,"cyrusPresetDecode");
Value* cyrusPresetDecode_cf(Value** args,int count){
    check_arg_count(cyrusPresetDecode,1,count);
    try{const auto d=p::parse(utf8(args[0]));
        four_typed_value_locals(Array* result,Array* values,Array* samples,Array* graph);
        vl.result=new Array(3);vl.result->append(stringValue(d.category));vl.result->append(stringValue(d.name));vl.values=new Array(32);vl.result->append(vl.values);
        if(p::curve(d.category)){
            vl.samples=new Array(static_cast<int>(d.samples.size()));vl.graph=new Array(static_cast<int>(d.graph.size()*8));
            vl.values->append(vl.samples);vl.values->append(vl.graph);vl.values->append(d.multiplier?&true_value:&false_value);
            for(double v:d.samples)vl.samples->append(Double::intern(v));
            for(const auto& row:d.graph)for(double v:row)vl.graph->append(Double::intern(v));
        }else{const auto& fields=p::fields(d.category);for(std::size_t i=0;i<fields.size();++i){
            if(fields[i].kind==p::Kind::boolean)vl.values->append(d.values[i]!=0?&true_value:&false_value);
            else if(fields[i].kind==p::Kind::integer)vl.values->append(Integer::intern(static_cast<int>(d.values[i])));
            else vl.values->append(Double::intern(d.values[i]));
        }}
        return_value(vl.result);
    }catch(const std::exception& e){fail(e);}
}
