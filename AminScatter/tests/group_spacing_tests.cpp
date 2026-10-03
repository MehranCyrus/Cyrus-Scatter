#include "group_spacing.h"
#include <cmath>
#include <iostream>
#include <limits>
#include <random>
#include <stdexcept>
using namespace cyrus::groups;
using amin::Vec3;
void check(bool p,const char* m){if(!p)throw std::runtime_error(m);}
Result oracle(const std::vector<Vec3>& points,double distance,const std::vector<Rule>& rules,const std::vector<bool>& protect){
    auto accepted=protect;std::vector<bool> conflicts(points.size(),false);
    const auto close=[](Vec3 a,Vec3 b,double d,bool flat){auto v=a-b;if(flat)v.z=0;return amin::dot(v,v)<d*d;};
    for(std::size_t pass=0;pass<2;++pass)for(std::size_t i=0;i<points.size();++i)if(protect[i]==(pass==0)){
        bool hit=false;
        for(const auto& r:rules)for(std::size_t j=0;j<r.blockers.size();++j)hit|=close(points[i],r.blockers[j],r.gap+r.ownRadii[i]+r.blockerRadii[j],r.planar);
        for(std::size_t j=0;j<points.size();++j)if(i!=j&&accepted[j])hit|=close(points[i],points[j],distance,false);
        if(protect[i])conflicts[i]=hit;else accepted[i]=!hit;
    }
    Result out;for(std::size_t i=0;i<points.size();++i){if(accepted[i])out.kept.push_back(i);if(conflicts[i])out.conflicts.push_back(i);}return out;
}
int main(){try{
    std::mt19937 random(731);std::uniform_real_distribution<double> coordinate(-20,20),radius(0,3);
    for(int trial=0;trial<180;++trial){
        std::vector<Vec3> p;std::vector<bool> protect;
        for(int i=0;i<80;++i){p.push_back({coordinate(random),coordinate(random),coordinate(random)});protect.push_back(i%13==trial%13);}
        std::vector<Rule> rules(3);
        for(auto& rule:rules){rule.gap=radius(random);rule.planar=trial%2==0;for(std::size_t i=0;i<p.size();++i)rule.ownRadii.push_back(radius(random));for(int j=0;j<60;++j){rule.blockers.push_back({coordinate(random),coordinate(random),coordinate(random)});rule.blockerRadii.push_back(radius(random));}}
        const double distance=trial%7==0?0:radius(random);const auto actual=resolve(p,distance,rules,protect),expected=oracle(p,distance,rules,protect);
        check(actual.kept==expected.kept&&actual.conflicts==expected.conflicts,"Spatial grid disagrees with exhaustive group oracle");
    }
    const std::vector<Vec3> p={{0,0,0},{1,0,0},{4,0,0}};
    check(resolve(p,1,{},std::vector<bool>(3,false)).kept.size()==3,"Exact gap boundary rejected");
    check(resolve(p,2,{},std::vector<bool>{false,true,false}).kept==std::vector<std::size_t>({1,2}),"Manual override did not reserve position first");
    const auto conflict=resolve(p,2,{},std::vector<bool>{true,true,false});
    check(conflict.kept.size()==3&&conflict.conflicts==std::vector<std::size_t>({0,1}),"Conflicting overrides lost or unreported");
    Rule blocking;blocking.blockers={{0,0,0}};blocking.ownRadii={0,0,0};blocking.blockerRadii={0};blocking.gap=1.5;
    check(resolve(p,4,{blocking},std::vector<bool>(3,false)).kept==std::vector<std::size_t>({2}),"Rejected external candidate reserved internal spacing");
    blocking.blockers={{0,0,100}};blocking.planar=true;
    check(resolve(p,0,{blocking},std::vector<bool>(3,false)).kept.size()==1,"Planar gap ignored");
    blocking.planar=false;check(resolve(p,0,{blocking},std::vector<bool>(3,false)).kept.size()==3,"Spatial gap ignored height");
    check(resolve({},0,{},{}).kept.empty(),"Empty input failed");
    bool rejected=false;try{resolve({{std::numeric_limits<double>::infinity(),0,0}},1,{}, {false});}catch(const std::invalid_argument&){rejected=true;}check(rejected,"Non-finite coordinates accepted");
    rejected=false;try{resolve(p,-1,{},std::vector<bool>(3,false));}catch(const std::invalid_argument&){rejected=true;}check(rejected,"Negative distance accepted");
    rejected=false;blocking.ownRadii.clear();try{resolve(p,1,{blocking},std::vector<bool>(3,false));}catch(const std::invalid_argument&){rejected=true;}check(rejected,"Mismatched radii accepted");
    std::vector<Vec3> dense(100000,{0,0,0});auto bounded=resolve(dense,1,{},std::vector<bool>(dense.size(),false));check(bounded.kept.size()==1,"Dense population failed");
    std::cout<<"PASS 180 exhaustive comparisons, priorities, protected edits, gaps, planes, invalid input and 100k coincident candidates\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
