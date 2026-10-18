#include <max.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include "placement_publication.h"
#include "native_fault_qualification.h"
#include "placement_value.h"
#include "placement_transport.h"
#include "placement_host_text.h"
#include "placement_materialization.h"
#include <limits>
#include <maxscript/macros/define_instantiation_functions.h>
#undef ScripterExport
#define ScripterExport __declspec(dllexport)

namespace p=cyrus::placements;
namespace {
template<class F>Value* api(F action){try{return action();}catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}}
Array* array(Value* value,int size=-1){type_check(value,Array,_T("native publication metadata"));auto* result=static_cast<Array*>(value);if(size>=0&&result->size!=size)throw RuntimeError(_T("Publication metadata field count differs"));return result;}
std::uint64_t number(Value* value,std::uint64_t maximum=std::uint64_t(INT64_MAX)){
    // Max's getHandleByAnim uses IntegerPtr. Preserve its numeric handle while
    // still rejecting Float/Double instead of truncating arbitrary numbers.
    if(!Number::is_integer_number(value)||value->to_int64()<0||std::uint64_t(value->to_int64())>maximum)throw RuntimeError(_T("Invalid publication nonnegative integer"));return std::uint64_t(value->to_int64());
}
bool pubBool(Value* value){if(value!=&true_value&&value!=&false_value)throw RuntimeError(_T("Publication flag must be Boolean"));return value==&true_value;}
std::string key(Value* value){return p::host::text(value,p::maxIdentity,p::maxIdentity);}
Value* integer(std::uint64_t value){return Integer64::intern(static_cast<INT64>(value));}
Value* pubBool(bool value){return value?&true_value:&false_value;}
}
visible_class_debug_ok(CyrusPlacementPublication)
class CyrusPlacementPublication : public Value {
public:
    const std::shared_ptr<const p::Publication> value;
    explicit CyrusPlacementPublication(std::shared_ptr<const p::Publication> snapshot):value(std::move(snapshot)){tag=class_tag(CyrusPlacementPublication);}
    classof_methods(CyrusPlacementPublication,Value);
    void collect() override{delete this;}
    void sprin1(CharStream* stream) override{stream->printf(_T("<CyrusPlacementPublication:%llu>"),static_cast<unsigned long long>(value->size()));}
    Value* deep_copy(HashTable*) override{return this;}
    Value* get_property(Value** args,int count) override{
        if(count==1){if(args[0]==Name::intern(_T("count")))return integer(value->size());if(args[0]==Name::intern(_T("epoch")))return integer(value->header().epoch);}
        return Value::get_property(args,count);
    }
};
visible_class_instance(CyrusPlacementPublication,"CyrusPlacementPublication");
namespace {
const std::shared_ptr<const p::Publication>& publication(Value* value){type_check(value,CyrusPlacementPublication,_T("immutable native root publication"));return static_cast<CyrusPlacementPublication*>(value)->value;}
Value* populationInfo(const p::PublishedPopulation& population){
    three_typed_value_locals(Array* result,Array* sources,Array* source);vl.result=new Array(10);
    vl.result->append(p::host::string(population.id));vl.result->append(p::host::string(population.parent));
    for(auto value:{std::uint64_t(population.layerOrder),std::uint64_t(population.setOrder),std::uint64_t(population.rows.size()),std::uint64_t(population.budget),std::uint64_t(population.attempts),std::uint64_t(population.pool),population.salt})vl.result->append(integer(value));
    vl.sources=new Array(int(population.expectedSources->sources().size()));vl.result->append(vl.sources);
    for(const auto& binding:population.expectedSources->sources()){
        vl.source=new Array(5);vl.sources->append(vl.source);vl.source->append(p::host::string(binding.id));vl.source->append(integer(binding.handle));
        for(unsigned k=0;k<3;++k)vl.source->append(pubBool((binding.flags&(1u<<k))!=0));
    }
    return_value(vl.result);
}
}
def_visible_primitive(cyrusPlacementPublicationVersion,"cyrusPlacementPublicationVersion");
Value* cyrusPlacementPublicationVersion_cf(Value**,int count){check_arg_count(cyrusPlacementPublicationVersion,0,count);return Integer::intern(1);}

// Existing eight-field manifest + input signature; population payloads are
// #(nativeRows,nativeRadii,expectedContext,receiverBindings,binding,stats,rounds,surfaceStats,preparationKey).
def_visible_primitive(cyrusPlacementPublicationCreate,"cyrusPlacementPublicationCreate");
Value* cyrusPlacementPublicationCreate_cf(Value** args,int count){check_arg_count(cyrusPlacementPublicationCreate,5,count);return api([&]()->Value*{
    cyrus::owned::fault(7);
    p::PublicationHeader header;header.owner=number(args[0]);auto previous=args[1]==&undefined?std::shared_ptr<const p::Publication>{}:publication(args[1]);
    auto* info=array(args[2],8);header.id=key(info->data[0]);header.epoch=number(info->data[1]);
    if(!cyrus::rows::integer(info->data[2]))throw RuntimeError(_T("Publication time must be integer ticks"));header.time=info->data[2]->to_int64();header.meters=info->data[3]->to_double();
    const auto expectedCount=number(info->data[4],p::maxRecords);auto* sets=array(info->data[5]);auto* rules=array(info->data[6]);header.script=p::host::text(info->data[7],1024,1024);
    header.inputKey=p::host::text(args[3],2097152,8u*1024*1024);auto* inputs=array(args[4]);
    if(sets->size!=inputs->size||inputs->size>10||rules->size>90)throw RuntimeError(_T("Publication population/rule count mismatch"));
    for(int i=0;i<rules->size;++i){auto* row=array(rules->data[i],7);header.rules.push_back({unsigned(number(row->data[0],2)),key(row->data[1]),key(row->data[2]),pubBool(row->data[3]),pubBool(row->data[6]),row->data[4]->to_double(),row->data[5]->to_double()});}
    std::vector<p::PublishedPopulation> populations;populations.reserve(inputs->size);
    for(int i=0;i<inputs->size;++i){auto* input=array(inputs->data[i],9);auto* set=array(sets->data[i],10);
        p::PublishedPopulation pop(cyrusPlacementView(input->data[0]),cyrusRadiusData(input->data[1]),cyrusPlacementContext(input->data[2]));
        pop.id=key(set->data[0]);pop.parent=key(set->data[1]);pop.layerOrder=unsigned(number(set->data[2],10));pop.setOrder=unsigned(number(set->data[3],10));
        if(number(set->data[4],p::maxRecords)!=pop.rows.size())throw RuntimeError(_T("Manifest count differs from its native population"));
        pop.budget=unsigned(number(set->data[5],p::maxRecords));pop.attempts=unsigned(number(set->data[6],p::maxRecords));pop.pool=unsigned(number(set->data[7],p::maxRecords));pop.salt=number(set->data[8]);
        auto* assets=array(set->data[9]);const auto& sources=pop.expectedSources->sources();
        if(std::size_t(assets->size)!=sources.size())throw RuntimeError(_T("Manifest sources differ from the frozen generation"));
        for(int s=0;s<assets->size;++s){auto* asset=array(assets->data[s],5);p::SourceBinding binding;binding.id=key(asset->data[0]);binding.handle=number(asset->data[1]);
            for(unsigned k=0;k<3;++k)if(pubBool(asset->data[k+2]))binding.flags|=1u<<k;
            if(!(binding==sources[s]))throw RuntimeError(_T("Manifest source identities, order or scene bindings changed"));}
        auto* receivers=array(input->data[3]);if(receivers->size>128)throw RuntimeError(_T("Publication exceeds 128 receiver bindings"));
        for(int r=0;r<receivers->size;++r){auto* receiver=array(receivers->data[r],6);const auto slot=number(receiver->data[0],128);
            if(slot==0)throw RuntimeError(_T("Publication receiver slot must be 1..128"));
            pop.receivers.push_back({std::uint32_t(slot-1),std::uint32_t(number(receiver->data[2],10000000)),std::uint32_t(number(receiver->data[3],10000000)),key(receiver->data[1]),key(receiver->data[4]),number(receiver->data[5])});}
        pop.binding=p::host::text(input->data[4],2097152,8u*1024*1024);auto* stats=array(input->data[5],12);for(int k=0;k<12;++k)pop.statistics[std::size_t(k)]=number(stats->data[k],50000000);
        pop.preparationKey=p::host::text(input->data[8],2097152,8u*1024*1024);
        auto* rounds=array(input->data[6],2);pop.rounds=unsigned(number(rounds->data[0],16));pop.roundLimit=pubBool(rounds->data[1]);auto* surface=array(input->data[7],3);
        for(int k=0;k<3;++k){if(!cyrus::rows::integer(surface->data[k]))throw RuntimeError(_T("Surface statistics must be integer"));pop.surfaceStatistics[std::size_t(k)]=surface->data[k]->to_int64();}
        populations.push_back(std::move(pop));
    }
    auto result=p::Publication::create(header,populations,previous);if(result->size()!=expectedCount)throw RuntimeError(_T("Publication total differs from its manifest"));
    return new CyrusPlacementPublication(std::move(result));
});}

def_visible_primitive(cyrusPlacementPublicationInfo,"cyrusPlacementPublicationInfo");
Value* cyrusPlacementPublicationInfo_cf(Value** args,int count){check_arg_count(cyrusPlacementPublicationInfo,1,count);return api([&]()->Value*{
    const auto& value=*publication(args[0]);const auto& header=value.header();three_typed_value_locals(Array* result,Array* sets,Array* rules);
    vl.result=new Array(9);vl.result->append(p::host::string(header.id));vl.result->append(integer(header.epoch));vl.result->append(Integer64::intern(header.time));vl.result->append(Double::intern(header.meters));vl.result->append(integer(value.size()));
    vl.sets=new Array(int(value.populations().size()));vl.result->append(vl.sets);for(const auto& pop:value.populations())vl.sets->append(populationInfo(pop));
    vl.rules=new Array(int(header.rules.size()));vl.result->append(vl.rules);
    for(const auto& rule:header.rules){auto* row=new Array(7);vl.rules->append(row);row->append(integer(rule.scope));row->append(p::host::string(rule.a));row->append(p::host::string(rule.b));row->append(pubBool(rule.enabled));row->append(Double::intern(rule.multiplier));row->append(Double::intern(rule.gap));row->append(pubBool(rule.planar));}
    vl.result->append(p::host::string(header.script));vl.result->append(p::host::string(header.inputKey));return_value(vl.result);
});}

def_visible_primitive(cyrusPlacementPublicationRows,"cyrusPlacementPublicationRows");
Value* cyrusPlacementPublicationRows_cf(Value** args,int count){check_arg_count(cyrusPlacementPublicationRows,2,count);return api([&]()->Value*{
    const auto& value=*publication(args[0]);const auto slot=number(args[1],10);if(slot<1||slot>value.populations().size())throw RuntimeError(_T("Publication population is out of range"));return cyrusPlacementValue(value.populations()[std::size_t(slot-1)].rows);
});}
def_visible_primitive(cyrusPlacementPublicationRadii,"cyrusPlacementPublicationRadii");
Value* cyrusPlacementPublicationRadii_cf(Value** args,int count){check_arg_count(cyrusPlacementPublicationRadii,2,count);return api([&]()->Value*{
    const auto& value=*publication(args[0]);const auto slot=number(args[1],10);if(slot<1||slot>value.populations().size())throw RuntimeError(_T("Publication population is out of range"));return cyrusRadiusValue(value.populations()[std::size_t(slot-1)].radii);
});}

// Matches the existing public page shape. It reads only this cached frame,
// creates at most 500 detached rows and never resolves nodes or calculates.
def_visible_primitive(cyrusPlacementPublicationPage,"cyrusPlacementPublicationPage");
Value* cyrusPlacementPublicationPage_cf(Value** args,int count){check_arg_count(cyrusPlacementPublicationPage,4,count);return api([&]()->Value*{
    const auto& value=*publication(args[0]);const auto id=key(args[1]);const auto offset=number(args[2],p::maxRecords),limit=number(args[3],p::maxPage);
    if(id!=value.header().id||limit==0||offset>value.size())throw RuntimeError(_T("Stale publication or invalid page bounds"));
    const auto end=std::min<std::size_t>(value.size(),std::size_t(offset+limit));
    p::MaterializationScope materialization(p::TransportStage::Readback);
    p::noteReadback(end-offset);
    four_typed_value_locals(Array* result,Array* rows,Array* row,Array* radius);vl.result=new Array(4);vl.rows=new Array(int(end-offset));materialization.populationArray();
    vl.result->append(p::host::string(value.header().id));vl.result->append(integer(value.size()));vl.result->append(integer(end));vl.result->append(vl.rows);
    std::size_t base=0;
    for(std::size_t populationIndex=0;populationIndex<value.populations().size();++populationIndex){const auto& population=value.populations()[populationIndex];const auto size=population.rows.size();
        const auto first=offset>base?std::min<std::size_t>(size,offset-base):0,last=end>base?std::min<std::size_t>(size,end-base):0;
        for(std::size_t i=first;i<last;++i){const auto& source=population.rows.at(i);Matrix3 matrix(1);for(int r=0;r<4;++r)matrix.SetRow(r,Point3(source.transform[std::size_t(r*3)],source.transform[std::size_t(r*3+1)],source.transform[std::size_t(r*3+2)]));
            vl.row=new Array(7);materialization.row();vl.rows->append(vl.row);vl.row->append(integer(populationIndex+1));vl.row->append(new Matrix3Value(matrix));materialization.matrix();vl.row->append(integer(source.source));vl.row->append(p::host::string(population.rows.textIdentity(i)));materialization.string();vl.row->append(pubBool((source.flags&p::Protected)!=0));
            vl.radius=new Array(2);vl.row->append(vl.radius);for(auto radius:(*population.radii)[i])vl.radius->append(Float::intern(radius));vl.row->append(pubBool((population.expectedSources->sources()[source.source-1].flags&p::RenderSource)!=0));
        }
        base+=size;
    }
    return_value(vl.result);
});}

def_visible_primitive(cyrusPlacementPublicationStatistics,"cyrusPlacementPublicationStatistics");
Value* cyrusPlacementPublicationStatistics_cf(Value** args,int count){check_arg_count(cyrusPlacementPublicationStatistics,2,count);return api([&]()->Value*{
    const auto& value=*publication(args[0]);const auto slot=number(args[1],10);if(slot<1||slot>value.populations().size())throw RuntimeError(_T("Publication population is out of range"));
    const auto& pop=value.populations()[std::size_t(slot-1)];three_typed_value_locals(Array* result,Array* values,Array* rounds);
    vl.result=new Array(4);vl.values=new Array(12);vl.result->append(vl.values);for(auto count:pop.statistics)vl.values->append(integer(count));
    vl.rounds=new Array(2);vl.result->append(vl.rounds);vl.rounds->append(integer(pop.rounds));vl.rounds->append(pubBool(pop.roundLimit));
    vl.values=new Array(3);vl.result->append(vl.values);for(auto count:pop.surfaceStatistics)vl.values->append(Integer64::intern(count));
    vl.values=new Array(int(pop.sourceCounts.size()));vl.result->append(vl.values);for(auto count:pop.sourceCounts)vl.values->append(integer(count));return_value(vl.result);
});}
