#include "source_radius.h"
#include <cstring>
#include <iostream>
#include <stdexcept>

namespace p=cyrus::placements;namespace eb=cyrus::editbinding;namespace sr=cyrus::sourceradius;
namespace {
unsigned checks=0;
void check(bool value,const char* label){++checks;if(!value)throw std::runtime_error(label);}
template<class F>void rejects(F f,const char* label){bool caught=false;try{f();}catch(const std::exception&){caught=true;}check(caught,label);}
const std::string geometry="\nCyrusReceivers2\nreceiver=geometry\n";
std::string legacy(const std::string& members="A|B"){return "CyrusBinding2:17|"+members+"|scale:1|"+geometry;}
std::string descriptor(const std::vector<std::string>& sources,const std::string& members="A|B",unsigned seed=17){
    std::vector<eb::SourceSpec> specs;for(const auto& source:sources)specs.push_back({source,"model;scale:1;z:0"});
    return eb::make(legacy(members),"CyrusBinding2:"+std::to_string(seed)+"|Owner:layer|globalScale:1|"+geometry,specs);
}
struct Row {std::string id;unsigned source;};
p::View view(const std::vector<std::string>& sources,const std::vector<Row>& rows,const std::string& binding,bool prepare=true){
    const auto owner=p::newOwner();std::vector<p::SourceBinding> sourceSpecs;for(std::size_t i=0;i<sources.size();++i)sourceSpecs.push_back({sources[i],i+1,p::RenderSource});
    auto cohort=p::SourceCohort::create(owner,"layer",sourceSpecs);p::Builder builder(owner,p::Stage::Edited,unsigned(sources.size()),rows.size(),cohort);
    for(std::size_t i=0;i<rows.size();++i){p::Record record;record.transform={1,0,0,0,1,0,0,0,1,float(i),2,3};record.source=rows[i].source;
        if(rows[i].id.starts_with("c:")){record.identity=std::stoull(rows[i].id.substr(2));builder.appendGenerated(record);}else builder.appendAuthored(record,rows[i].id);}
    auto result=builder.freeze();return prepare?result.prepared("prepared-key",binding):result;
}
void history(){
    const auto ab=descriptor({"A","B"});const auto initial=view({"A","B"},{{"c:100",1},{"c:101",2},{"clone-guid",1}},ab);
    const auto original=initial.at(0);
    auto a=sr::author(initial,ab,"",{},{},{},{},{"c:100","clone-guid"},1,7,false);
    check(a.ids==std::vector<std::string>({"c:100","clone-guid"})&&a.distances==std::vector<double>({7,7}),"Authored overrides capture candidate and clone source lineage");
    check(std::memcmp(&original,&initial.at(0),sizeof(original))==0,"Radius authoring leaves placement transform/identity bytes unchanged");
    const auto saved=sr::parse(a.binding);check(saved.entries[0].source=="A"&&saved.entries[1].source=="A","Source identity comes from native cohort, not row index");
    const auto bOnly=descriptor({"B"},"B");const auto b=view({"B"},{{"c:100",1},{"c:101",1}},bOnly);
    sr::Replay removed(b,bOnly,a.binding,a.ids);
    check(!removed.find(b,0)&&!removed.find(b,1),"A-to-B reassignment cannot replay A's world radius");
    auto both=sr::author(b,bOnly,a.binding,a.ids,a.modes,a.values,a.distances,{"c:100"},2,3,false);
    check(both.ids==std::vector<std::string>({"c:100","clone-guid","c:100"}),"Different source history can retain duplicate textual candidate IDs");
    sr::Replay replayB(b,bOnly,both.binding,both.ids);check(replayB.find(b,0)==2,"Replay selects only the matching B override");
    sr::Replay replayA(initial,ab,both.binding,both.ids);check(replayA.find(initial,0)==0&&replayA.find(initial,2)==1,"Original source restores its own candidate and clone overrides");
    auto resetB=sr::author(b,bOnly,both.binding,both.ids,both.modes,both.values,both.distances,{"c:100"},1,0,true);
    check(resetB.ids==a.ids&&resetB.distances==a.distances,"Reset selected radius removes only current source history");
    const auto emptyBinding=descriptor({},"");const auto empty=view({}, {},emptyBinding);
    const auto retained=sr::encode(sr::bind(empty,emptyBinding,both.binding,both.ids));
    check(sr::parse(retained).entries.size()==3,"Last-source removal saves inactive override histories");
    sr::Replay reopened(initial,ab,retained,both.ids);check(reopened.find(initial,0)==0&&reopened.find(initial,2)==1,"Serialized empty-source history reactivates exact source IDs");
    const auto renamed=descriptor({"different-same-name"},"different-same-name");const auto different=view({"different-same-name"},{{"c:100",1}},renamed);
    sr::Replay newRole(different,renamed,both.binding,both.ids);check(!newRole.find(different,0),"A different same-name source inherits no radius override");
    const auto reverse=descriptor({"B","A"},"B|A");const auto reordered=view({"B","A"},{{"c:101",1},{"c:100",2},{"clone-guid",2}},reverse);
    sr::Replay ordinal(reordered,reverse,both.binding,both.ids);check(ordinal.find(reordered,1)==0&&ordinal.find(reordered,2)==1,"Source ordinal compaction/reorder does not change ownership");
    rejects([&]{replayA.find(reordered,0);},"Replay cannot be borrowed by another native view");
    check(sr::encode(sr::parse(both.binding))==both.binding,"Radius descriptor canonical save/reopen roundtrip");
}
void legacyAndGuards(){
    const auto ab=descriptor({"A","B"});const auto rows=view({"A","B"},{{"c:100",1},{"c:101",2},{"clone-guid",2}},ab);
    const std::vector<std::string> ids={"c:100","clone-guid"};
    const auto hydrated=sr::encode(sr::bind(rows,ab,legacy(),ids));check(sr::parse(hydrated).entries[1].source=="B","Legacy clone hydration resolves exact input source");
    sr::Replay legacyReplay(rows,ab,legacy(),ids);check(legacyReplay.find(rows,0)==0&&legacyReplay.find(rows,2)==1,"Unchanged legacy path remains usable before explicit hydration");
    rejects([&]{sr::bind(rows,ab,legacy("B"),ids);},"Old incompatible membership is not guessed");
    rejects([&]{sr::bind(rows,ab,legacy(),{"c:999"});},"Unresolved old ID retains recovery requirement");
    rejects([&]{sr::bind(rows,ab,"",ids);},"Missing old generation receipt cannot authorize capture");
    rejects([&]{sr::bind(rows,ab,ab,ids);},"Source descriptor without radius lineage is not an ownership proof");
    const auto unprepared=view({"A","B"},{{"c:100",1}},ab,false);
    rejects([&]{sr::bind(unprepared,ab,legacy(),{"c:100"});},"Raw native rows cannot claim a matching prepared signature");
    const auto seedChanged=descriptor({"A","B"},"A|B",18);const auto changed=view({"A","B"},{{"c:100",1}},seedChanged);
    rejects([&]{sr::bind(changed,seedChanged,hydrated,ids);},"Source-aware radius replay still rejects changed seed");
    auto changedGeometry=ab;const auto at=changedGeometry.rfind("geometry");changedGeometry.replace(at,8,"changed!");
    rejects([&]{sr::bind(rows,changedGeometry,hydrated,ids);},"Mismatched receipt/receiver data cannot replay");
    rejects([&]{sr::bind(rows,ab,hydrated,{"clone-guid","c:100"});},"Persisted parallel-array order must match binding");
    rejects([&]{sr::author(rows,ab,hydrated,ids,{1},{1},{1},{"c:100"},1,2,false);},"Mismatched authored arrays rejected atomically");
    check(sr::parse(hydrated).entries.size()==2,"Failed successors leave original binding usable");
    const auto small=rows.select({1});sr::Replay absent(small,ab,hydrated,ids);check(!absent.find(small,0),"Reduced Count/filter does not prune absent overrides");
    rejects([&]{sr::bind(rows,ab,legacy(),{"c:100","c:100"});},"Legacy duplicate IDs cannot establish two ownerships");
}
void malformed(){
    const auto ab=descriptor({"A","B"});const auto rows=view({"A","B"},{{"c:100",1}},ab);auto bound=sr::bind(rows,ab,legacy(),{"c:100"});const auto encoded=sr::encode(bound);
    rejects([&]{sr::parse(encoded+"x");},"Trailing radius descriptor data rejected");
    rejects([&]{sr::parse(encoded.substr(0,encoded.size()-1));},"Truncated radius descriptor rejected");
    rejects([&]{sr::parse("CyrusSourceRadius2\n");},"Unknown future radius version rejected");
    rejects([&]{sr::parse("CyrusSourceRadius1\n99999999999999999999\n");},"Length overflow rejected before allocation");
    auto duplicate=bound;duplicate.entries.push_back(duplicate.entries.front());rejects([&]{sr::encode(duplicate);},"Duplicate candidate/source lineage rejected");
    auto unknown=bound;unknown.entries.front().source="unknown";rejects([&]{sr::encode(unknown);},"Unknown source references rejected");
}
}
int main(){try{const auto before=p::metrics();history();legacyAndGuards();malformed();check(p::metrics().liveBytes==before.liveBytes,"Tests release all immutable placement storage");std::cout<<checks<<" source radius assertions passed\n";return 0;}catch(const std::exception& e){std::cerr<<e.what()<<"\n";return 1;}}
