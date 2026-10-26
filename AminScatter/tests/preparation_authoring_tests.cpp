#include "interactions_source.h"
#include "preparation_authoring.hpp"
#include <iostream>
using namespace cyrus::interactions;
void require(bool x,const char* s){if(!x)throw std::runtime_error(s);}
template<class F>void rejects(F f){bool error=false;try{f();}catch(const std::exception&){error=true;}require(error,"Expected invalid authoring rejection");}
prep::Snapshot leaves(){prep::Snapshot s;for(float x:{-.02f,.02f,.04f}){unsigned b=unsigned(s.positions.size());for(unsigned k=0;k<5;++k){s.positions.push_back({x-.002f,0,k*.025f});s.positions.push_back({x+.002f,0,k*.025f});}for(unsigned k=0;k<4;++k){unsigned a=b+k*2;s.faces.push_back({a,a+1,a+2});s.faces.push_back({a+1,a+3,a+2});}}s.materials.assign(s.faces.size(),0);return s;}
int main(){try{auto s=leaves();prep::Settings cfg;cfg.foliageFraction=1;std::atomic_bool cancel=false;auto pieces=prep::inspectPieces(s,cfg,cancel);require(pieces.parts.size()==3,"Stable complete component inspection");
    Json intent={{"version",1},{"fingerprint",prep::fingerprint(s)},{"parts",Json::array({{{"part",0},{"role",1}},{{"part",1},{"role",3}},{{"part",2},{"role",1}}})}};
    auto source=prepareSource(s,cfg,nullptr,&intent);require(source->rig->guides.size()==2,"Fixed piece must not generate a guide");require(source->rig->parts[1].fixed,"Fixed role applied");require(source->rig->triangles.size()==s.faces.size(),"Every source face retained");Pose rest;rest.guides.resize(2);rest.hiddenRoots.resize(2);for(unsigned i=0;i<s.positions.size();++i){auto p=posePoint(*source,rest,i);require(length(sub(p,{s.positions[i][0],s.positions[i][2],-s.positions[i][1]}))<1e-8,"Exact rest reproduction");}
    auto saved=saveSource(*source);require(saved["format"]==2,"Authored format guard");auto loaded=prepareSource(s,cfg,&saved);require(loaded->authoring==source->authoring,"Authored intent roundtrip");auto stale=s;stale.positions[0][0]+=.001f;rejects([&]{prepareSource(stale,cfg,nullptr,&intent);});
    auto follow=intent;follow["parts"][1]={{"part",1},{"role",2},{"parent",0}};auto attached=prepareSource(s,cfg,nullptr,&follow);require(!attached->rig->parts[1].stem&&!attached->rig->parts[1].fixed,"Follow role is rigid attachment");require(attached->rig->parts[1].guide==attached->rig->parts[0].guide,"Follow exact parent");
    auto cyclic=intent;cyclic["parts"][0]["parent"]=2;cyclic["parts"][2]["parent"]=0;rejects([&]{prepareSource(s,cfg,nullptr,&cyclic);});
    auto duplicate=intent;duplicate["parts"].push_back(duplicate["parts"][0]);rejects([&]{prepareSource(s,cfg,nullptr,&duplicate);});
    auto invalidRoot=intent;invalidRoot["parts"][0]["root_vertex"]=15;rejects([&]{prepareSource(s,cfg,nullptr,&invalidRoot);});
    auto allFixed=intent;for(auto& r:allFixed["parts"])r["role"]=3;rejects([&]{prepareSource(s,cfg,nullptr,&allFixed);});
    auto moved=intent;moved["parts"][0]["nodes"]=Json::array({Json::array({-.02,0,0}),Json::array({-.01,0,.05}),Json::array({-.02,0,.1})});auto custom=prepareSource(s,cfg,nullptr,&moved);require(custom->rig->guides[0].rest.nodes.size()==3,"Manual guide nodes");
    cancel=true;rejects([&]{prep::inspectPieces(s,cfg,cancel);});std::cout<<"PASS source roles, complete geometry, exact rest, authored persistence, parents, cycles, roots and cancellation\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
