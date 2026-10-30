#include "interactions_source.h"
#include <fstream>
#include <iostream>
using namespace cyrus::interactions;
std::shared_ptr<const MeshGeometry> cube(double h){
 return std::make_shared<MeshGeometry>(std::vector<Vec>{{-h,-h,-h},{h,-h,-h},{h,h,-h},{-h,h,-h},{-h,-h,h},{h,-h,h},{h,h,h},{-h,h,h}},std::vector<Tri>{{0,2,1},{0,3,2},{4,5,6},{4,6,7},{0,1,5},{0,5,4},{1,2,6},{1,6,5},{2,3,7},{2,7,6},{3,0,4},{3,4,7}});
}
int main(int argc,char** argv){Json report;try{
 if(argc!=4)throw std::runtime_error("snapshot intent output required");
 std::ifstream input(argv[1],std::ios::binary);unsigned h[4]{};input.read(reinterpret_cast<char*>(h),16);
 if(h[0]!=0x53544c32u||h[1]>2000000||h[2]>4000000)throw std::runtime_error("bad snapshot");
 prep::Snapshot mesh;mesh.positions.resize(h[1]);mesh.faces.resize(h[2]);mesh.materials.resize(h[2]);input.read(reinterpret_cast<char*>(mesh.positions.data()),h[1]*12);input.read(reinterpret_cast<char*>(mesh.faces.data()),h[2]*12);input.read(reinterpret_cast<char*>(mesh.materials.data()),h[2]*4);if(!input)throw std::runtime_error("short snapshot");
 Json intent;std::ifstream in(argv[2]);in>>intent;auto source=prepareSource(mesh,{},nullptr,&intent);auto saved=saveSource(*source);
 report["contacts"]=Json::array();unsigned generation=1;
 for(auto location:std::vector<Vec>{{-.012,.067,-.070},{.075,.04,-.020}}){
  Shape obstacle{generation,cube(.004),{}};obstacle.coverRoots=false;obstacle.transform.rows[3]=location;
  auto pose=fitSource(*source,{obstacle},.00001,.5,true,generation++);
  auto audit=auditSource(*source,pose,{obstacle});
  if(!pose.changed||!pose.activeGuides)throw std::runtime_error("No actual guide response at selected source contact");
  double maxRigidError=0;
  for(unsigned part=77;part<197;++part){std::vector<unsigned> ids;for(unsigned i=0;i<source->labels.size();++i)if(source->labels[i]==part)ids.push_back(i);
   if(ids.size()<2)throw std::runtime_error("Flower piece lost source correspondence");
   for(unsigned j=1;j<ids.size();++j){auto a=ids[0],b=ids[j];maxRigidError=std::max(maxRigidError,std::abs(length(sub(posePoint(*source,pose,a),posePoint(*source,pose,b)))-length(sub(source->rig->positions[a],source->rig->positions[b]))));}
  }
  if(maxRigidError>1e-8)throw std::runtime_error("Flower-head rigidity changed");
  if(saveSource(*source)!=saved)throw std::runtime_error("Pose mutated reusable source");
  auto rest=fitSource(*source,{},0,.5,false,generation++);double restError=0;for(unsigned i=0;i<mesh.positions.size();++i)restError=std::max(restError,length(sub(posePoint(*source,rest,i),source->rig->positions[i])));
  if(restError>1e-8)throw std::runtime_error("Move-away failed to restore the source");
  report["contacts"].push_back({{"location",{location.x,location.y,location.z}},{"active_guides",pose.activeGuides},{"flower_rigid_error_m",maxRigidError},{"rest_error_m",restError},{"source_unchanged",true},{"audit",audit}});
 }
 report["status"]="pass";
}catch(const std::exception& e){report["status"]="failed";report["error"]=e.what();}
 if(argc==4){std::ofstream out(argv[3]);out<<report.dump(2);}std::cout<<report.dump(2)<<'\n';return report["status"]=="pass"?0:1;
}
