#include "lab_core.hpp"
#include <cmath>
#include <iostream>
#include <stdexcept>
void require(bool b,const char* message){if(!b)throw std::runtime_error(message);}
template<class F>void rejects(F f,const char* message){bool caught=false;try{f();}catch(const std::exception&){caught=true;}require(caught,message);}
int main(){try{
    for(double unit:{1.,.0254,.01,.001}) {
        auto rest=cvl::makeRest(7,unit);require(rest->meshes.size()==7,"rest patch count");
        const auto original=cvl::encode(*rest);auto fit=cvl::fit(*rest,{{0,.2,0},.25},.005,false);
        require(fit->meshes.size()==7&&fit->fitted,"seven blade fit");require(fit->metrics.root<=1e-7&&fit->metrics.penetration<=1e-5,"independent float-mesh validation");
        require(cvl::encode(*rest)==original,"fit mutated prior result");
        auto loaded=cvl::decode(cvl::encode(*fit));require(cvl::encode(*loaded)==cvl::encode(*fit),"save/load geometry round trip");
        for(std::size_t i=0;i<fit->meshes.size();++i){require(fit->meshes[i].positions.size()==18&&fit->meshes[i].triangles.size()==16,"topology");require(fit->meshes[i].uvs.size()==18,"UV count");}
        rejects([&]{cvl::fit(*fit,{{-.2,0,0},.25},.005,false);},"blocked roots accepted");
        rejects([&]{cvl::fit(*fit,{{0,.2,0},.25},.005,true);},"blocked clamp accepted");
        require(cvl::encode(*fit)==cvl::encode(*loaded),"failed fit changed result");
        auto reset=cvl::makeRest(7,unit,fit->revision+1,fit->prepared);require(reset->prepared==rest->prepared&&!reset->fitted,"reset source/root identity");
    }
    auto max=cvl::makeRest(21,1);auto fit=cvl::fit(*max,{{0,.2,0},.25},.005,false);require(fit->metrics.queries<=20000,"aggregate query budget");
    auto clamp=cvl::fit(*cvl::makeRest(1,1),{{0,.35,0},.22},.005,true);require(clamp->clamp&&clamp->metrics.root<=1e-7,"positive clamp fit");
    auto j=cvl::Json::parse(cvl::encode(*fit));j["core"]="other";rejects([&]{cvl::decode(j.dump());},"wrong core admitted");
    j=cvl::Json::parse(cvl::encode(*fit));j["poses"][0]["nodes"][0][0]=3;rejects([&]{cvl::decode(j.dump());},"tampered root admitted");
    rejects([]{cvl::makeRest(22,1);},"blade cap");rejects([]{cvl::makeRest(1,0);},"unit cap");
    rejects([&]{cvl::decode(std::string(cvl::maxSerializedBytes+1,' '));},"save payload cap");
    auto p=cvl::hostToCore(cvl::coreToHost({1,2,3},.01),.01);require(p.x==1&&p.y==2&&p.z==3,"coordinate rotation round trip");
    std::cout<<"PASS lab integration: units, 7/21 blades, independently validated float meshes, root/clamp failure retention, save/load, reset, bounds\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
