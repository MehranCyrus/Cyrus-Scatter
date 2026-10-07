// Review-only CPU fixtures. Independent all-pairs oracle; no host or viewport.
#include "scatter.h"
#include "group_spacing.h"
#include "brush.h"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <random>
#include <stdexcept>
#include <string>

using Clock = std::chrono::steady_clock;
using namespace cyrus::groups;
using amin::Vec3;
double elapsed(Clock::time_point t) {
    return std::chrono::duration<double, std::milli>(Clock::now()-t).count();
}
void require(bool ok, const char* message) { if (!ok) throw std::runtime_error(message); }
bool overlaps(Vec3 a, Vec3 b, double distance, bool planar) {
    const double x=a.x-b.x,y=a.y-b.y,z=planar?0:a.z-b.z;
    return x*x+y*y+z*z < distance*distance;
}
// Deliberately uses all pairs and an explicit accepted list, with no grid/cells.
DetailedResult oracle(const std::vector<Vec3>& p,const std::vector<double>& radii,
    const DistanceRule& self,const std::vector<ScopedRule>& rules,
    const std::vector<bool>& pins,std::size_t target) {
    DetailedResult r;r.reasons.assign(p.size(),Reason::NotConsumed);
    std::vector<std::size_t> selected;
    for(std::size_t i=0;i<p.size();++i)if(pins[i])selected.push_back(i);
    auto violation=[&](std::size_t i) {
        for(const auto& rule:rules) {
            const auto& v=rule.values;
            for(std::size_t j=0;j<v.blockers.size();++j)
                if(overlaps(p[i],v.blockers[j],rule.multiplier*(v.ownRadii[i]+v.blockerRadii[j])+v.gap,v.planar))return rule.reason;
        }
        if(self.enabled)for(auto j:selected)if(i!=j&&overlaps(p[i],p[j],self.multiplier*(radii[i]+radii[j])+self.gap,self.planar))return Reason::SelfSpacing;
        return Reason::Accepted;
    };
    for(auto i:selected) {if(violation(i)!=Reason::Accepted)r.conflicts.push_back(i);r.reasons[i]=Reason::Protected;}
    for(std::size_t i=0;i<p.size();++i)if(!pins[i]&&selected.size()<target) {
        r.reasons[i]=violation(i);if(r.reasons[i]==Reason::Accepted)selected.push_back(i);
    }
    std::sort(selected.begin(),selected.end());r.kept=std::move(selected);return r;
}
std::size_t spacingOracle() {
    constexpr std::size_t cases=500;
    for(std::size_t c=0;c<cases;++c) {
        std::mt19937 rng(static_cast<unsigned>(0x721000+c));
        auto coordinate=[&](){return static_cast<double>(static_cast<int>(rng()%101)-50)*.2;};
        auto radius=[&](){return static_cast<double>(rng()%11)*.1;};
        std::vector<Vec3> p(80);std::vector<double> radii(80);std::vector<bool> pins(80);
        for(std::size_t i=0;i<p.size();++i) {p[i]={coordinate(),coordinate(),coordinate()};radii[i]=radius();pins[i]=rng()%17==0;}
        DistanceRule self{c%5!=0,c%7==0?0:.5+static_cast<double>(c%3),static_cast<double>(c%4)*.1,c%2==0};
        std::vector<ScopedRule> rules;
        for(unsigned k=0;k<2;++k) {
            ScopedRule r;r.reason=k==0?Reason::LayerSpacing:Reason::SetSpacing;
            r.multiplier=c%11==0?0:1;r.values.gap=static_cast<double>(c%3)*.15;r.values.planar=(c+k)%2==0;
            r.values.ownRadii=radii;
            for(unsigned j=0;j<23;++j) {r.values.blockers.push_back({coordinate(),coordinate(),coordinate()});r.values.blockerRadii.push_back(radius());}
            rules.push_back(std::move(r));
        }
        const auto target=c%4==0?0:(c%4==1?12:(c%4==2?35:80));
        const auto actual=resolveVariable(p,radii,self,rules,pins,target,50000000);
        const auto expected=oracle(p,radii,self,rules,pins,target);
        require(actual.kept==expected.kept,"All-pairs oracle: accepted rows differ");
        require(actual.conflicts==expected.conflicts,"All-pairs oracle: pin conflicts differ");
        require(actual.reasons==expected.reasons,"All-pairs oracle: rejection scopes differ");
    }
    const DistanceRule self{true,1,0,false};
    for(double x:{1.999999999,2.,2.000000001}) {
        const auto result=resolveVariable({{0,0,0},{x,0,0}},{1,1},self,{}, {false,false},2);
        require(result.kept.size()==(x<2?1u:2u),"Strict contact boundary changed");
    }
    return cases+3;
}
void radiusCases() {
    std::cout<<"\"radius_cases\":[";bool first=true;
    for(std::size_t count:{1000u,3000u,10000u,12000u})for(bool outlier:{false,true}) {
        std::vector<Vec3> p(count);std::vector<double> radii(count,.5);
        for(std::size_t i=0;i<count;++i)p[i]={static_cast<double>(i)*10,0,0};
        if(outlier){p.back()={1e12,0,0};radii.back()=1e9;}
        if(!first)std::cout<<',';first=false;
        auto t=Clock::now();
        std::cout<<"{\"count\":"<<count<<",\"far_outlier\":"<<(outlier?"true":"false");
        try {
            const auto r=resolveVariable(p,radii,{true,1,0,true},{},std::vector<bool>(count,false),count,50000000);
            require(r.kept.size()==count,"Non-overlapping radius fixture lost rows");
            std::cout<<",\"kept\":"<<r.kept.size()<<",\"neighbor_visits\":"<<r.neighborVisits<<",\"budget_failure\":false";
        } catch(const std::invalid_argument& e) {
            require(count==12000&&outlier,"Unexpected spacing failure");
            require(std::string(e.what()).find("work limit exceeded")!=std::string::npos,"Unexpected failure message");
            std::cout<<",\"budget_failure\":true,\"error\":\"Procedural spacing work limit exceeded\"";
        }
        std::cout<<",\"ms\":"<<elapsed(t)<<'}';
    }std::cout<<']';
}
std::vector<amin::Triangle> grid(unsigned side) {
    std::vector<amin::Triangle> result;
    for(unsigned y=0;y<side;++y)for(unsigned x=0;x<side;++x) {
        const double a=100.*x/side,b=100.*y/side,s=100./side;
        const Vec3 p{a,b,0},q{a+s,b,0},r{a+s,b+s,0},t{a,b+s,0};
        result.push_back({p,q,r});result.push_back({p,r,t});
    }return result;
}
void projectionCases() {
    std::cout<<"\"projection_cases\":[";bool first=true;
    for(unsigned side:{1u,10u,30u,60u,100u})for(bool project:{false,true}) {
        const auto surface=grid(side);amin::Settings s;s.stableCandidates=true;s.count=1000;
        s.uniformScale={1,1};s.movement={{{.25,.25},{0,0},{1,1}}};s.projectMovement=project;
        std::vector<double> ms;std::size_t kept=0;
        for(unsigned repeat=0;repeat<3;++repeat) {
            const auto t=Clock::now();const auto rows=amin::scatter(surface,s);ms.push_back(elapsed(t));kept=rows.size();
            require(kept==s.count,"Projection fixture lost candidates");
            for(std::size_t i=0;i<rows.size();++i) {
                // The raw numeric core assigns ordinals; the host attaches the
                // keyed anchor flag in placement_identity.inc after generation.
                require(rows[i].candidateKey==i,"Projection changed candidate ordinal");
                require(std::isfinite(rows[i].position.x)&&std::isfinite(rows[i].position.y),"Non-finite projection output");
                require(std::abs(rows[i].position.z-(project?0.:1.))<1e-10,"Projection did not reach receiving plane");
            }
        }
        std::sort(ms.begin(),ms.end());
        if(!first)std::cout<<',';first=false;
        std::cout<<"{\"triangles\":"<<surface.size()<<",\"candidates\":"<<s.count<<",\"project\":"<<(project?"true":"false")
                 <<",\"kept\":"<<kept<<",\"median_ms\":"<<ms[1]<<",\"samples_ms\":["<<ms[0]<<','<<ms[1]<<','<<ms[2]<<"]}";
    }std::cout<<']';
}
cyrus::brush::Mesh brushGrid(unsigned side) {
    cyrus::brush::Mesh m;
    for(unsigned y=0;y<=side;++y)for(unsigned x=0;x<=side;++x)m.vertices.push_back({100.*x/side,100.*y/side,0});
    for(unsigned y=0;y<side;++y)for(unsigned x=0;x<side;++x) {
        const auto a=y*(side+1)+x,b=a+1,d=(y+1)*(side+1)+x,c=d+1;
        m.faces.push_back({a,b,c});m.faces.push_back({a,c,d});
    }return m;
}
void brushCases() {
    using namespace cyrus::brush;
    std::cout<<"\"brush_cases\":[";bool first=true;
    for(unsigned side:{16u,32u,64u})for(unsigned dabs:{64u,256u})for(bool wide:{false,true}) {
        Surface surface(brushGrid(side));Document doc{surface.fingerprint(),{}};Stroke stroke;stroke.id=1;
        stroke.radius=wide?200:2;stroke.strength=.1;
        for(unsigned i=0;i<dabs;++i) {
            const double x=1.+98.*(i%16)/15.,y=1.+98.*((i/16)%16)/15.;
            Hit hit;require(surface.hit({{x,y,100},{0,0,-1}},hit),"Brush setup ray missed");
            Sample sample;sample.anchor=hit.anchor;sample.view={{50,50,100},{0,0,-1},false};stroke.samples.push_back(sample);
        }
        doc.strokes.push_back(stroke);
        const auto t=Clock::now();Field field(surface,doc);const auto buildMs=elapsed(t);
        auto q=Clock::now();double maxError=0;
        for(unsigned i=0;i<25;++i) {
            Hit hit;require(surface.hit({{2.+24.*(i%5),2.+24.*(i/5),100},{0,0,-1}},hit),"Brush query ray missed");
            maxError=std::max(maxError,std::abs(field.evaluate(hit.anchor)-field.evaluateReference(hit.anchor)));
        }
        require(maxError<1e-10,"Indexed Brush replay differs from reference");
        if(!first)std::cout<<',';first=false;
        std::cout<<"{\"faces\":"<<surface.mesh().faces.size()<<",\"dabs\":"<<dabs<<",\"whole_surface_radius\":"<<(wide?"true":"false")
                 <<",\"field_build_ms\":"<<buildMs<<",\"paired_query_ms\":"<<elapsed(q)<<",\"oracle_queries\":25,\"max_error\":"<<maxError
                 <<",\"wide_patch_link_payload_lower_bound_bytes\":"<<(wide?static_cast<std::uint64_t>(surface.mesh().faces.size())*dabs*12:0)<<'}';
    }std::cout<<']';
}
int main() {
    try {
        std::cout<<std::setprecision(10)<<"{\"kind\":\"CPU-only review probe; not FPS\",\"oracle_cases\":"<<spacingOracle()<<',';
        radiusCases();std::cout<<',';projectionCases();std::cout<<',';brushCases();std::cout<<"}\n";
    }catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}
}
