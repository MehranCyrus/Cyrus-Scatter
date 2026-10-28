#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include "edit_binding.h"
#include "source_radius.h"
#include "placement_value.h"
#include "placement_host_text.h"
#include <stdexcept>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)

namespace {
namespace eb=cyrus::editbinding;namespace sr=cyrus::sourceradius;namespace host=cyrus::placements::host;
template<class F> Value* bindingAPI(F f){try{return f();}catch(const std::exception& error){throw RuntimeError(MSTR::FromACP(error.what()));}}
Array* bindingArray(Value* value,std::size_t maximum){type_check(value,Array,_T("bounded source/radius metadata"));auto* array=static_cast<Array*>(value);
    if(array->size<0||std::size_t(array->size)>maximum)throw RuntimeError(_T("Source/radius metadata exceeds its allowance"));return array;}
std::string bindingText(Value* value,std::size_t maximum){return host::text(value,maximum,maximum);}
std::vector<std::string> radiusIDs(Value* value){auto* array=bindingArray(value,sr::maxOverrides);std::vector<std::string> result;result.reserve(array->size);std::size_t bytes=0;
    for(int i=0;i<array->size;++i){auto id=bindingText(array->data[i],cyrus::placements::maxIdentity);if(id.size()>sr::maxBindingBytes-bytes)throw RuntimeError(_T("Radius identity metadata exceeds 64 MiB"));bytes+=id.size();result.push_back(std::move(id));}return result;}
}
def_visible_primitive(cyrusSourceEditBinding,"cyrusSourceEditBinding");
Value* cyrusSourceEditBinding_cf(Value** a,int n){check_arg_count(cyrusSourceEditBinding,3,n);return bindingAPI([&]()->Value*{
    const auto legacy=bindingText(a[0],eb::maxSignatureBytes),basis=bindingText(a[1],eb::maxSignatureBytes);auto* input=bindingArray(a[2],eb::maxActiveSources);
    std::vector<eb::SourceSpec> sources;sources.reserve(input->size);std::size_t bytes=legacy.size()+basis.size();
    for(int i=0;i<input->size;++i){auto* row=bindingArray(input->data[i],3);if(row->size!=2&&row->size!=3)throw RuntimeError(_T("Source binding needs stable native ID, settings and optional editable scale"));
        eb::SourceSpec source{bindingText(row->data[0],eb::maxIdentityBytes),bindingText(row->data[1],eb::maxSettingsBytes)};
        if(row->size==3)source.settings=eb::editableScaleSettings(source.settings,row->data[2]->to_double());
        if(source.id.size()+source.settings.size()>eb::maxDescriptorBytes-bytes)throw RuntimeError(_T("Source binding exceeds 8 MiB"));bytes+=source.id.size()+source.settings.size();sources.push_back(std::move(source));}
    return host::string(eb::make(legacy,basis,sources));
});}
def_visible_primitive(cyrusSourceRadiusBind,"cyrusSourceRadiusBind");
Value* cyrusSourceRadiusBind_cf(Value** a,int n){check_arg_count(cyrusSourceRadiusBind,4,n);return bindingAPI([&]()->Value*{
    const auto& view=cyrusPlacementView(a[0]);const auto current=bindingText(a[1],eb::maxDescriptorBytes),previous=bindingText(a[2],sr::maxBindingBytes);const auto ids=radiusIDs(a[3]);
    const auto result=sr::bind(view,current,previous,ids);return host::string(ids.empty()?std::string{}:sr::encode(result));
});}
def_visible_primitive(cyrusSourceRadiusEdit,"cyrusSourceRadiusEdit");
Value* cyrusSourceRadiusEdit_cf(Value** a,int n){check_arg_count(cyrusSourceRadiusEdit,11,n);return bindingAPI([&]()->Value*{
    const auto& view=cyrusPlacementView(a[0]);const auto current=bindingText(a[1],eb::maxDescriptorBytes),previous=bindingText(a[2],sr::maxBindingBytes);const auto ids=radiusIDs(a[3]);
    auto* modes=bindingArray(a[4],sr::maxOverrides);auto* values=bindingArray(a[5],sr::maxOverrides);auto* distances=bindingArray(a[6],sr::maxOverrides);
    if(std::size_t(modes->size)!=ids.size()||std::size_t(values->size)!=ids.size()||std::size_t(distances->size)!=ids.size())throw RuntimeError(_T("Radius metadata length mismatch"));
    std::vector<int> modeData;std::vector<double> valueData,distanceData;modeData.reserve(ids.size());valueData.reserve(ids.size());distanceData.reserve(ids.size());
    for(int i=0;i<modes->size;++i){modeData.push_back(modes->data[i]->to_int());valueData.push_back(values->data[i]->to_float());distanceData.push_back(distances->data[i]->to_float());}
    if(a[10]!=&true_value&&a[10]!=&false_value)throw RuntimeError(_T("Radius reset flag must be Boolean"));
    const auto result=sr::author(view,current,previous,ids,modeData,valueData,distanceData,radiusIDs(a[7]),a[8]->to_int(),a[9]->to_float(),a[10]==&true_value);
    five_typed_value_locals(Array* output,Array* outputIDs,Array* outputModes,Array* outputValues,Array* outputDistances);
    vl.output=new Array(5);vl.outputIDs=new Array(int(result.ids.size()));vl.output->append(vl.outputIDs);
    vl.outputModes=new Array(int(result.ids.size()));vl.output->append(vl.outputModes);vl.outputValues=new Array(int(result.ids.size()));vl.output->append(vl.outputValues);
    vl.outputDistances=new Array(int(result.ids.size()));vl.output->append(vl.outputDistances);
    for(std::size_t i=0;i<result.ids.size();++i){vl.outputIDs->append(host::string(result.ids[i]));vl.outputModes->append(Integer::intern(result.modes[i]));
        vl.outputValues->append(Float::intern(float(result.values[i])));vl.outputDistances->append(Float::intern(float(result.distances[i])));}
    vl.output->append(host::string(result.binding));return_value(vl.output);
});}
