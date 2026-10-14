#include "presets.h"
#include <iostream>
#include <stdexcept>
using namespace cyrus::presets;
void check(bool ok){if(!ok)throw std::runtime_error("Preset test failed");}
template<class F>void rejected(F f){bool failed=false;try{f();}catch(const std::exception&){failed=true;}check(failed);}
int main(){try{
    Document a;a.category="population";a.name="Trees \xe2\x80\x94 12 / m2";a.values={300,2,12,57,1,8,4,1};
    const auto text=serialize(a);const auto b=parse(text);check(b.values==a.values&&b.name==a.name&&b.category==a.category);
    auto changed=text;const auto at=changed.find("\"version\": 1");check(at!=std::string::npos);changed.replace(at,12,"\"version\": 2");rejected([&]{parse(changed);});
    rejected([&]{parse(text+"{}");});rejected([&]{parse(std::string(maxBytes+1,' '));});
    changed=text;changed.insert(changed.find('{')+1,"\"version\":1,");rejected([&]{parse(changed);});
    changed=text;const auto count=changed.find("\"amount\": 300");changed.replace(count,13,"\"amount\": 3.0");rejected([&]{parse(changed);});
    changed=text;changed.insert(changed.find('{')+1,"\"nested\":[[[[[[[[[[0]]]]]]]]]],");rejected([&]{parse(changed);});
    Document c;c.category="scale_curve";c.name="Raised edge";c.samples={0,2,1};c.multiplier=true;
    c.graph={{{0,0,0,0,0,0,0,1}},{{.5,200,0,0,0,0,0,1}},{{1,100,0,0,0,0,0,1}}};
    const auto curveCopy=parse(serialize(c));check(c.samples==curveCopy.samples&&c.graph==curveCopy.graph&&curveCopy.multiplier);
    c.category="density_curve";rejected([&]{serialize(c);});c.category="scale_curve";c.multiplier=false;rejected([&]{serialize(c);});
    c.multiplier=true;c.graph[1][0]=0;rejected([&]{serialize(c);});c.graph.clear();check(parse(serialize(c)).graph.empty());
    Document transforms;transforms.category="transforms";transforms.name="Static axes";
    for(const auto& f:fields(transforms.category))transforms.values.push_back(f.minimum);
    check(parse(serialize(transforms)).values==transforms.values);transforms.values[3]=36001;rejected([&]{serialize(transforms);});
    transforms.values[3]=10;transforms.values[4]=5;rejected([&]{serialize(transforms);});
    a.name=std::string(81,'a');rejected([&]{serialize(a);});
    a.name="Trees";a.values[0]=1000001;rejected([&]{serialize(a);});
    std::cout<<"PASS: bounded typed presets, round trips, strict parsing and curve domains\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
