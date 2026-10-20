// Mesh cooking uses an absolute near-zero triangle area in Jolt. Metre-space
// tessellation can fall below it even when the surface is perfectly valid.
// Cook in a larger local frame, then restore the exact physical scale/offset.
struct CookedCollider {JPH::ShapeRefC shape;Vec offset;Json info;};
CookedCollider cookedCollider(const Mesh& mesh){
 if(mesh.vertices.empty()||mesh.faces.empty())throw std::runtime_error("Collider has no triangles");
 if(mesh.vertices.size()>200000||mesh.faces.size()>200000)throw std::runtime_error("Collider mesh admission exceeded");
 Vec lo=mesh.vertices.front(),hi=lo;
 for(auto p:mesh.vertices){if(!std::isfinite(p.x)||!std::isfinite(p.y)||!std::isfinite(p.z))throw std::runtime_error("Collider has a non-finite vertex");lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}
 for(auto f:mesh.faces)for(auto i:f)if(i>=mesh.vertices.size())throw std::runtime_error("Collider triangle index exceeds its vertices");
 Vec half,center;
 if(exactBox(mesh,half,center)||flatRectangle(mesh,half,center))return {
  new JPH::BoxShape(jv(half),float(std::min({.0001,half.x*.1,half.y*.1,half.z*.1}))),center,
  {{"kind","box"},{"input_triangles",mesh.faces.size()},{"cook_scale",1}}};
 JPH::IndexedTriangleList triangles;triangles.reserve(mesh.faces.size());
 std::set<std::array<unsigned,3>> unique;double minArea=std::numeric_limits<double>::max();unsigned degenerate=0,duplicates=0;
 for(auto f:mesh.faces){auto a=mesh.vertices[f[1]]-mesh.vertices[f[0]],b=mesh.vertices[f[2]]-mesh.vertices[f[0]];
  double area=length(cross(a,b)),edge=std::max({dot(a,a),dot(b,b),dot(a-b,a-b)});
  // Relative collinearity, independent of scene units. Never discard a valid
  // triangle merely because its absolute area is small.
  if(area<=edge*1.e-12){++degenerate;continue;}
  auto key=f;while(key[0]>key[1]||key[0]>key[2])std::rotate(key.begin(),key.begin()+1,key.end());
  if(!unique.insert(key).second){++duplicates;continue;}
  minArea=std::min(minArea,area);triangles.emplace_back(f[0],f[1],f[2]);
 }
 if(triangles.empty())throw std::runtime_error("Collider has no non-degenerate triangles");
 // Jolt tests |cross(edge1,edge2)|^2 <= 1e-12. Give that test a 10x
 // area margin; powers of two keep scale conversion exact in binary floats.
 double gain=1;while(minArea*gain*gain<1.e-5&&gain<524288)gain*=2;
 if(minArea*gain*gain<1.e-5||length(hi-lo)*gain>60000)throw std::runtime_error("Collider detail exceeds the safe mesh cooking range; split this collider into smaller meshes");
 Vec offset=gain==1?Vec{}:(lo+hi)*.5;
 JPH::VertexList vertices;vertices.reserve(mesh.vertices.size());for(auto p:mesh.vertices)vertices.emplace_back(float((p.x-offset.x)*gain),float((p.y-offset.y)*gain),float((p.z-offset.z)*gain));
 const auto expected=triangles.size();JPH::MeshShapeSettings settings(std::move(vertices),std::move(triangles));
 if(settings.mIndexedTriangles.size()!=expected)throw std::runtime_error("Collider loses triangle detail at Jolt mesh precision; split this collider into smaller meshes (retained "+std::to_string(settings.mIndexedTriangles.size())+" of "+std::to_string(expected)+")");
 auto result=settings.Create();if(result.HasError())throw std::runtime_error(std::string("Jolt mesh cook: ")+result.GetError().c_str());
 JPH::ShapeRefC shape=result.Get();
 if(gain!=1){JPH::ScaledShapeSettings scaled(shape,JPH::Vec3::sReplicate(float(1/gain)));auto restored=scaled.Create();if(restored.HasError())throw std::runtime_error(std::string("Jolt mesh scale: ")+restored.GetError().c_str());shape=restored.Get();}
 return {shape,offset,{{"kind","mesh"},{"input_triangles",mesh.faces.size()},{"cooked_triangles",expected},{"degenerate_triangles",degenerate},{"duplicate_triangles",duplicates},{"cook_scale",gain},{"minimum_twice_area_m2",minArea},{"offset_m",{offset.x,offset.y,offset.z}}}};
}
