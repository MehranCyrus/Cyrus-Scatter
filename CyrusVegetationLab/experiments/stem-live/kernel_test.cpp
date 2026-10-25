#include "stem_core.hpp"
#include <fstream>
#include <iostream>
int main(int count,char** args){try{
    if(count!=3)throw std::runtime_error("Usage: stem_kernel_test exported.bin prepared.json");
    std::ifstream stream(args[1],std::ios::binary);unsigned header[4]{};stream.read(reinterpret_cast<char*>(header),sizeof(header));if(header[0]!=0x53544c32u)throw std::runtime_error("Export header.");
    std::vector<std::array<float,3>> xyz(header[1]);std::vector<std::array<unsigned,3>> faces(header[2]);std::vector<unsigned> materials(header[2]),labels(header[1]);stream.read(reinterpret_cast<char*>(xyz.data()),xyz.size()*sizeof(xyz[0]));stream.read(reinterpret_cast<char*>(faces.data()),faces.size()*sizeof(faces[0]));stream.read(reinterpret_cast<char*>(materials.data()),materials.size()*4);stream.read(reinterpret_cast<char*>(labels.data()),labels.size()*4);if(!stream)throw std::runtime_error("Export payload.");
    std::ifstream metadata(args[2]);stem::Json j;metadata>>j;std::vector<stem::Vec> points;for(auto p:xyz)points.push_back({p[0],p[2],-p[1]});auto prepared=stem::prepare(j,points,faces,labels);
    std::cout<<"guides "<<prepared->guides.size()<<" preview faces "<<prepared->previewTriangles.size()<<'\n';
    auto rest=stem::restPose(*prepared);double error=0;for(unsigned i=0;i<points.size();++i){auto q=stem::point(*prepared,rest,i);double d=std::hypot(q.x-points[i].x,q.y-points[i].y,q.z-points[i].z);error=std::max(error,d);}std::cout<<"rest reconstruction "<<error<<'\n';if(error>1e-7)throw std::runtime_error("Rest reconstruction failed.");
    for(unsigned i=0;i<9;++i){double x=1.1-.085*i;stem::Vec centre{x,.78,-.096};auto result=stem::solve(*prepared,centre,.167,.001,.5,i+2);std::cout<<"x "<<x<<" ok "<<result.ok<<" "<<result.metrics.dump()<<" "<<result.error<<'\n';if(!result.ok)throw std::runtime_error("Sweep solve rejected.");if(i==8){auto saved=stem::savePose(result.pose);auto restored=stem::loadPose(*prepared,saved);if(stem::savePose(restored)!=saved)throw std::runtime_error("Pose round trip.");auto check=stem::audit(*prepared,result.pose,centre,.167,.01);std::cout<<"AUDIT "<<check.dump()<<'\n';if(check.at("min_gap_m").get<double>()<.001||check.at("rigid_part_edges_over_10pct").get<unsigned>()||check.at("root_ring_error_m").get<double>()>1e-6)throw std::runtime_error("Delivered geometry acceptance.");}}
    return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
