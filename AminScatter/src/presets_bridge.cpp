#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include "presets.h"
#include <stdexcept>

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
