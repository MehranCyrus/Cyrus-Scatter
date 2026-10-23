#include "edit_binding.h"
#include "receiver_plan.h"
#include <iostream>
#include <stdexcept>

namespace eb=cyrus::editbinding;
namespace {
unsigned checks=0;
void check(bool value,const char* label){++checks;if(!value)throw std::runtime_error(label);}
template<class F>void rejects(F f,const char* label){bool caught=false;try{f();}catch(const std::invalid_argument&){caught=true;}check(caught,label);}
const std::string receivers="\nCyrusReceivers2\nreceiver-a=geometry-a\n";
std::string old(const std::string& membership="A|B",const std::string& geometry=receivers){return "CyrusBinding2:17|"+membership+"|scale:1|"+geometry;}
std::string basis(const std::string& geometry=receivers){return "CyrusBinding2:17|Owner:layer-a|globalScale:1|"+geometry;}
std::string descriptor(const std::vector<eb::SourceSpec>& sources,const std::string& membership="A|B",const std::string& geometry=receivers){return eb::make(old(membership,geometry),basis(geometry),sources);}
void membership(){
    const auto first=descriptor({{"A","kind:model;scale:1;z:2"},{"B","kind:point;scale:3;z:0"}});
    const auto reordered=descriptor({{"B","kind:point;scale:3;z:0"},{"A","kind:model;scale:1;z:2"}});
    check(first==reordered,"Source settings are canonical by stable ID, not array order");
    const auto initial=eb::merge("",first);check(!initial.legacyHydrated&&initial.descriptor.sources.size()==2,"Initial source-aware bind");
    const auto hydrated=eb::merge(old(),first);check(hydrated.legacyHydrated&&hydrated.descriptor.legacy==old(),"Legacy proof requires old signature and preserves evidence");
    const auto removed=descriptor({{"B","kind:point;scale:3;z:0"}},"B");
    const auto history=eb::merge(eb::encode(hydrated.descriptor),removed);
    check(history.descriptor.sources.size()==2&&history.descriptor.legacy==old(),"Source removal keeps inactive settings and original legacy evidence");
    check(eb::sourceRevision(history.descriptor,"A")&&*eb::sourceRevision(history.descriptor,"A")=="kind:model;scale:1;z:2","Exact source revision lookup");
    check(eb::sourceRevision(history.descriptor,"same-name-new-ID")==nullptr,"Names cannot establish source lineage");
    const auto empty=eb::merge(eb::encode(history.descriptor),descriptor({},""));
    check(empty.descriptor.sources==history.descriptor.sources,"Last-source removal retains history");
    check(eb::merge(eb::encode(empty.descriptor),first).descriptor.sources==history.descriptor.sources,"Original roles can return after an empty population");
    const auto added=eb::merge(eb::encode(empty.descriptor),descriptor({{"different-A","kind:model;scale:9"}},"different-A"));
    check(added.descriptor.sources.size()==3,"Different source identity enrolls a separate history");
    const auto before=eb::encode(history.descriptor);
    rejects([&]{eb::merge(before,descriptor({{"A","kind:model;scale:2;z:2"}},"A"));},"Removed retained source semantics remain guarded on re-add");
    check(eb::encode(history.descriptor)==before,"Failed successor does not mutate prior descriptor");
    rejects([&]{eb::merge(old(),removed);},"Legacy source removal cannot guess hydration");
    rejects([&]{eb::merge(first,eb::make(old(),"CyrusBinding2:18|Owner:layer-a|globalScale:1|"+receivers,{{"A","kind:model;scale:1;z:2"}}));},"Seed/global generation change remains guarded");
    rejects([&]{cyrus::receivers::mergeBinding(first,old());},"Old receiver-only reader rejects new descriptor instead of dropping source lineage");
}
void geometry(){
    const auto original=descriptor({{"A","same"}},"A");
    const std::string two=receivers+"receiver-b=geometry-b\n";
    const auto expanded=eb::merge(original,descriptor({{"A","same"}},"A",two));
    check(expanded.descriptor.basis.find("receiver-b=geometry-b")!=std::string::npos,"Existing supported receiver additions retained");
    const auto absent=eb::merge(eb::encode(expanded.descriptor),original);
    rejects([&]{eb::merge(eb::encode(absent.descriptor),descriptor({{"A","same"}},"A",receivers+"receiver-b=changed\n"));},"Absent receiver geometry remains guarded");
    const auto migrated=eb::merge(old("A",two),original);
    check(migrated.legacyHydrated&&migrated.descriptor.basis.find("receiver-b=geometry-b")!=std::string::npos,"Legacy hydration carries historical receiver revisions into new basis");
    rejects([&]{eb::make(old("A"),basis(two),{{"A","same"}});},"Legacy proof and new basis must describe the same current receivers");
}
void malformed(){
    const auto valid=descriptor({{"A","settings\nwith|delimiters=and Unicode: \xc3\xa9"}},"A");
    check(eb::encode(eb::parse(valid))==valid,"Length-prefixed strings preserve delimiters and UTF-8");
    rejects([&]{eb::parse(valid+"x");},"Trailing data rejected");
    rejects([&]{eb::parse(valid.substr(0,valid.size()-1));},"Truncated descriptor rejected");
    rejects([&]{eb::parse("CyrusSourceBinding2\n0\n");},"Future feature version rejected");
    rejects([&]{eb::parse("CyrusSourceBinding1\n99999999999999999999\n");},"Overflowing length rejected before allocation");
    rejects([&]{eb::parse("CyrusSourceBinding1\n01\nx\n");},"Noncanonical length rejected");
    rejects([&]{descriptor({{"A","one"},{"A","two"}});},"Duplicate source identity rejected");
    rejects([&]{descriptor({{"A",""}});},"Missing source semantics rejected");
    rejects([&]{descriptor({{std::string("A\0B",3),"one"}});},"Embedded NUL cannot truncate identity");
    rejects([&]{descriptor({{"A",std::string(eb::maxSettingsBytes+1,'x')}});},"Per-source settings bounded");
    std::vector<eb::SourceSpec> tooMany(eb::maxActiveSources+1);rejects([&]{descriptor(tooMany);},"Active source inventory bounded before iteration");
    rejects([&]{eb::parse(std::string(eb::maxDescriptorBytes+1,'x'));},"Aggregate descriptor bounded before parsing");
}
}
int main(){try{membership();geometry();malformed();std::cout<<checks<<" source binding assertions passed\n";return 0;}catch(const std::exception& e){std::cerr<<e.what()<<"\n";return 1;}}
