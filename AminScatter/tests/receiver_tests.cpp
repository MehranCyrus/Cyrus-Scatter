#include "receiver_plan.h"
#include "scatter.h"
#include <algorithm>
#include <iostream>
#include <map>
#include <set>
#include <stdexcept>
#include <cmath>
using namespace cyrus::receivers;
static unsigned checks=0;
static void check(bool b){++checks;if(!b)throw std::runtime_error("receiver assertion "+std::to_string(checks));}
template<class F>void rejected(F f){bool failed=false;try{f();}catch(const std::invalid_argument&){failed=true;}check(failed);}
static std::vector<amin::Triangle> mesh(unsigned slot){const double x=slot*3.0;return {{{x,0,0},{x+1,0,0},{x,1,0}},{{x+1,0,0},{x+1,1,0},{x,1,0}}};}
static std::map<std::uint64_t,amin::Instance> generate(const Plan& p){
    std::map<std::uint64_t,amin::Instance> result;
    for(const auto& r:p.receivers)if(r.pool){amin::Settings s;s.receiverSalt=salt("receiver-"+std::to_string(r.slot));s.count=r.pool;s.sourceCount=3;
        s.rotationDegrees[0]={-15,15};s.axisScale[0]={.8,1.4};s.movement[0]={-.02,.02};
        for(const auto& row:amin::scatter(mesh(r.slot),s))result.emplace(identity(r.slot,unsigned(row.candidateKey)),row);}
    return result;
}
static bool same(const amin::Instance& a,const amin::Instance& b){
    const auto eq=[](amin::Vec3 x,amin::Vec3 y){return x.x==y.x&&x.y==y.y&&x.z==y.z;};
    return eq(a.position,b.position)&&eq(a.xAxis,b.xAxis)&&eq(a.yAxis,b.yAxis)&&eq(a.zAxis,b.zAxis)&&a.scale==b.scale&&a.source==b.source&&a.triangle==b.triangle;
}
int main(){try{
    std::vector<Input> input;for(unsigned i=0;i<20;++i)input.push_back({i,"receiver-"+std::to_string(i),1,0});
    const auto a=plan(input,10000,500,1);check(a.budget==10000);const auto before=generate(a);
    input.push_back({20,"receiver-20",1,0});const auto b=plan(input,10000,500,1);check(b.budget==10500);const auto after=generate(b);
    for(const auto& item:before)check(same(item.second,after.at(item.first)));
    std::reverse(input.begin(),input.end());const auto reordered=plan(input,10000,500,1);check(reordered.order==b.order);
    const auto fixed=plan(input,10000,-1,1);check(fixed.budget==10000);const auto survivors=generate(fixed);unsigned retained=0;
    for(const auto& item:survivors)if(before.count(item.first)){check(same(item.second,before.at(item.first)));++retained;}check(retained==9524);
    input.erase(std::remove_if(input.begin(),input.end(),[](const auto& r){return r.slot==7;}),input.end());const auto removed=generate(plan(input,10000,500,1));
    for(const auto& item:removed)check(same(item.second,after.at(item.first)));
    auto protectedPlan=plan({{0,"a",1,700},{1,"b",1,10}},0,-1,1);check(protectedPlan.order.size()==710&&protectedPlan.budget==0&&protectedPlan.attempts==0);
    auto capped=plan({{0,"a",1,0},{1,"b",1,0}},0,800000,32);check(capped.capped&&capped.budget==limit&&capped.order.size()==limit);
    auto shareCap=plan({{0,"a",1,0}},0,80000,1,25000);check(shareCap.capped&&shareCap.budget==25000);
    auto retry=plan({{0,"a",1,0},{1,"b",3,0}},100,-1,4);check(retry.order.size()==400&&retry.receivers[0].budget==25&&retry.receivers[1].budget==75);
    for(unsigned i=0;i<100;++i){unsigned slot=0,ordinal=0;check(decode(retry.order[i],slot,ordinal));check(ordinal<(slot==0?25u:75u));}
    for(unsigned slot=0;slot<128;++slot)for(unsigned ordinal:{0u,99999u,100000u,131071u,131072u,262144u,999999u}){
        unsigned s=999,o=999;check(decode(identity(slot,ordinal),s,o)&&s==slot&&o==ordinal);
        if(ordinal<100000)check(identity(slot,ordinal)==marker+std::uint64_t(slot)*stride+ordinal);
    }
    unsigned slot=0,ordinal=0;check(!decode(0,slot,ordinal));
    check(!decode(identity(127,limit-1)+1,slot,ordinal));check(!decode(UINT64_MAX,slot,ordinal));
    rejected([]{identity(128,0);});rejected([]{identity(0,limit);});
    rejected([]{plan({{0,"a",1,600000},{1,"b",1,600000}},0,-1,1);});
    rejected([]{plan({{0,"a",1,0}},limit+1,-1,1);});
    const auto expanded=plan({{0,"a",1,0},{1,"b",1,0}},300000,-1,1);
    check(expanded.budget==300000&&expanded.order.size()==300000);
    std::set<std::uint64_t> unique(expanded.order.begin(),expanded.order.end());check(unique.size()==300000);
    // Exact sampler prefix stability across the old identity page boundary.
    const auto small=generate(plan({{0,"a",1,0}},100000,-1,1));
    const auto large=generate(plan({{0,"a",1,0}},150000,-1,1));
    for(const auto& item:small)check(same(item.second,large.at(item.first)));
    rejected([]{plan({{0,"a",0,0}},100,-1,1);});
    rejected([]{plan({{0,"a",1,0},{0,"b",1,0}},100,-1,1);});rejected([]{plan({{0,"a",INFINITY,0}},100,-1,1);});
    const std::string key="settings\nCyrusReceivers2\na=mesh1\n",extra="settings\nCyrusReceivers2\nb=mesh2\na=mesh1\n";
    const auto merged=mergeBinding(key,extra);check(merged=="settings\nCyrusReceivers2\na=mesh1\nb=mesh2\n");check(mergeBinding(merged,key)==merged);
    rejected([&]{mergeBinding(merged,"settings\nCyrusReceivers2\na=changed\n");});rejected([&]{mergeBinding("old sampler",key);});
    rejected([&]{mergeBinding(key,"new settings\nCyrusReceivers2\na=mesh1\n");});
    amin::Settings s;s.count=100;s.receiverSalt=salt("sphere");const auto original=amin::scatter(mesh(0),s);
    s.uniformScale={2,2};const auto scale=amin::scatter(mesh(0),s);for(std::size_t i=0;i<original.size();++i)check(amin::length(original[i].position-scale[i].position)==0);
    std::cout<<checks<<" receiver assertions passed\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<"\n";return 1;}}
