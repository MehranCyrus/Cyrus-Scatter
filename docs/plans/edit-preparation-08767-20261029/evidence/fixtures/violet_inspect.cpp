#include "interactions_source.h"
#include "preparation_authoring.hpp"
#include <fstream>
#include <iostream>
using namespace cyrus::interactions;
int main(int argc,char** argv){try{
 if(argc<3)return 2;std::ifstream input(argv[1],std::ios::binary);unsigned h[4]{};input.read(reinterpret_cast<char*>(h),16);if(h[0]!=0x53544c32u||h[1]>2000000||h[2]>4000000)throw std::runtime_error("bad snapshot");
 prep::Snapshot mesh;mesh.positions.resize(h[1]);mesh.faces.resize(h[2]);mesh.materials.resize(h[2]);input.read(reinterpret_cast<char*>(mesh.positions.data()),h[1]*12);input.read(reinterpret_cast<char*>(mesh.faces.data()),h[2]*12);input.read(reinterpret_cast<char*>(mesh.materials.data()),h[2]*4);if(!input)throw std::runtime_error("short snapshot");
 prep::Settings cfg;std::atomic_bool cancel=false;auto pieces=prep::inspectPieces(mesh,cfg,cancel);Json result={{"fingerprint",prep::fingerprint(mesh)},{"parts",Json::array()}};
 for(unsigned i=0;i<pieces.parts.size();++i){const auto& p=pieces.parts[i];std::array<double,3> lo{1e99,1e99,1e99},hi{-1e99,-1e99,-1e99};for(auto v:p.vertices)for(int a=0;a<3;++a){lo[a]=std::min(lo[a],double(mesh.positions[v][a]));hi[a]=std::max(hi[a],double(mesh.positions[v][a]));}result["parts"].push_back({{"part",i},{"vertices",p.vertices.size()},{"faces",p.faces.size()},{"material",p.material},{"mixed",p.mixed},{"lo",lo},{"hi",hi}});}
 Json intent;const Json* authored=nullptr;if(argc>=4){std::ifstream f(argv[3]);f>>intent;authored=&intent;}
 try{auto prepared=prepareSource(mesh,cfg,nullptr,authored);result["definition"]=saveSource(*prepared);result["bytes"]=prepared->bytes;result["report"]=prepared->report;
  if(prepared->rig->triangles!=mesh.faces)throw std::runtime_error("Source triangle/corner identity changed");
  auto pose=fitSource(*prepared,{},0,.5,false,1);double restError=0;for(unsigned i=0;i<mesh.positions.size();++i){const auto p=mesh.positions[i];restError=std::max(restError,length(sub(posePoint(*prepared,pose,i),{p[0],p[2],-p[1]})));}if(restError>1e-8)throw std::runtime_error("Source rest geometry changed");
  auto loaded=prepareSource(mesh,cfg,&result["definition"]);if((authored&&loaded->authoring!=prepared->authoring)||loaded->rig->guides.size()!=prepared->rig->guides.size())throw std::runtime_error("Serialized preparation changed");
  result["rest_max_error_m"]=restError;result["triangles_preserved"]=true;result["roundtrip"]=true;result["status"]="pass";
 }
 catch(const PreparationFailure& failure){result["report"]=failure.analysis->report;result["metadata"]=failure.analysis->metadata;result["status"]="needs_review";}
 catch(const std::exception& e){result["error"]=e.what();result["status"]="failed";}
 std::ofstream output(argv[2]);output<<result.dump(2);std::cout<<result["status"]<<'\n';if(result.contains("error"))std::cout<<result["error"]<<'\n';return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
