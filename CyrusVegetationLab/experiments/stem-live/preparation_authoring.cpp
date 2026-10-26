#include "preparation_authoring.hpp"
#include <numeric>
#include <cmath>
#include <set>
namespace prep {
Pieces inspectPieces(const Snapshot& s,Settings cfg,const std::atomic_bool& cancel){
    validate(s,cfg);std::vector<unsigned> parents(s.positions.size());std::iota(parents.begin(),parents.end(),0u);
    auto root=[&](unsigned a){while(parents[a]!=a){parents[a]=parents[parents[a]];a=parents[a];}return a;};
    for(unsigned i=0;i<s.faces.size();++i){if((i&4095)==0&&cancel.load())throw std::runtime_error("Preparation cancelled");const auto& f=s.faces[i];for(auto v:f)if(v>=parents.size())throw std::runtime_error("Invalid source triangle");for(unsigned k=1;k<3;++k){auto a=root(f[0]),b=root(f[k]);if(a!=b)parents[std::max(a,b)]=std::min(a,b);}}
    Pieces out;out.labels.resize(parents.size());std::map<unsigned,unsigned> ids;
    for(unsigned i=0;i<parents.size();++i){auto [it,added]=ids.emplace(root(i),unsigned(out.parts.size()));if(added)out.parts.emplace_back();out.labels[i]=it->second;out.parts[it->second].vertices.push_back(i);}
    if(out.parts.size()>cfg.limits.parts)throw std::runtime_error("Connected pieces exceed Preparation limits");
    for(unsigned i=0;i<s.faces.size();++i){auto& p=out.parts[out.labels[s.faces[i][0]]];if(p.faces.empty())p.material=s.materials[i];else p.mixed|=p.material!=s.materials[i];p.faces.push_back(i);}return out;
}
std::map<unsigned,stem::Json> authoringRows(const stem::Json& data){std::map<unsigned,stem::Json> out;if(data.is_object()&&data.contains("parts"))for(const auto& row:data.at("parts"))out.emplace(row.at("part").get<unsigned>(),row);return out;}
stem::Json canonicalAuthoring(const Snapshot& s,const Pieces& pieces,const stem::Json& input){
    using J=stem::Json;const auto hash=fingerprint(s);J result={{"version",1},{"fingerprint",hash},{"parts",J::array()}};
    if(input.is_null()||input.empty())return result;
    if(!input.is_object()||input.value("version",0)!=1||input.value("fingerprint",std::string{})!=hash||!input.contains("parts")||!input["parts"].is_array()||input["parts"].size()>pieces.parts.size())throw std::runtime_error("Authored preparation is stale or incompatible; original edits retained");
    std::map<unsigned,J> rows;
    for(const auto& r:input["parts"]){
        unsigned id=r.at("part").get<unsigned>();int role=r.value("role",0);
        if(id>=pieces.parts.size()||role<0||role>3||rows.contains(id))throw std::runtime_error("Invalid or duplicate authored piece");
        J clean={{"part",id},{"role",role}};
        for(auto it=r.begin();it!=r.end();++it)if(it.key()!="part"&&it.key()!="role"&&it.key()!="parent"&&it.key()!="root_vertex"&&it.key()!="flip"&&it.key()!="nodes")throw std::runtime_error("Unknown authored preparation field");
        if(r.contains("parent")){int parent=r["parent"].get<int>();if(parent < -1||parent>=int(pieces.parts.size())||parent==int(id))throw std::runtime_error("Invalid parent piece");clean["parent"]=parent;}
        if(r.contains("root_vertex")){auto v=r["root_vertex"].get<unsigned>();if(v>=pieces.labels.size()||pieces.labels[v]!=id)throw std::runtime_error("Root seed belongs to another piece");clean["root_vertex"]=v;}
        if(r.value("flip",false))clean["flip"]=true;
        if(r.contains("nodes")){const auto& nodes=r["nodes"];if(!nodes.is_array()||nodes.size()<3||nodes.size()>16)throw std::runtime_error("Guide editing supports 3 to 16 points");for(const auto& p:nodes){if(!p.is_array()||p.size()!=3)throw std::runtime_error("Invalid guide point");for(const auto& x:p){double v=x.get<double>();if(!std::isfinite(v)||std::abs(v)>10000)throw std::runtime_error("Nonfinite guide point");}}clean["nodes"]=nodes;}
        if(role||clean.size()>2)rows.emplace(id,std::move(clean));
    }
    for(auto& [id,row]:rows)result["parts"].push_back(row);return result;
}
}
