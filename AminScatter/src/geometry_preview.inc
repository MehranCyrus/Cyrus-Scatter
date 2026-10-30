// Source meshes are copied once per cache rebuild, never as scene nodes.
def_visible_primitive(cyrusBuildGeometryPreview,"cyrusBuildGeometryPreview");
Value* cyrusBuildGeometryPreview_cf(Value** args,int count){
 return previewGuard([&]() -> Value* {
    amin::diagnostics::StageTimer measurement(amin::diagnostics::Stage::Preview);
 check_arg_count(cyrusBuildGeometryPreview,6,count);
 for(int i=1;i<3;++i)type_check(args[i],Array,_T("geometry preview"));
 PreviewRows rows(args[0]);auto* sources=static_cast<Array*>(args[1]);
 const auto palette=previewPalette(args[2],sources->size);
 int mode=args[3]->to_int(),limit=args[4]->to_int(),budget=args[5]->to_int();
 if(mode<1||mode>4||limit<0||budget<0)throw RuntimeError(_T("Invalid geometry display settings"));
 if(rows.size()>1000000||sources->size>512)throw RuntimeError(_T("Mesh preview input exceeds 1,000,000 placements or 512 sources"));
 const int wanted=limit?std::min(limit,int(rows.size())):int(rows.size());
 const auto groupBytes=std::size_t(sources->size)*(sizeof(cyrus::PreviewGeometry)+2*sizeof(Box3));
 auto storage=cyrus::reserveMeshMemory({sizeof(cyrus::MeshSnapshot)+groupBytes+std::size_t(wanted)*(sizeof(Matrix3)+1+sizeof(std::uint32_t)),0});
 auto staging=cyrus::reserveMeshMemory({rows.size()+std::size_t(sources->size)*sizeof(std::size_t)+4096,0});
 auto markerStaging=cyrus::reservePreviewMemory(cyrus::pointPreviewBudget,std::size_t(wanted)*2*(sizeof(Point3)+1)+sources->size*256+4096);
 std::size_t inspectedFaces=0;
 const auto inspectionLimit=cyrus::viewportMemoryPolicy().metadataFaces;
 rows.validate(sources->size,*palette);
 std::vector<std::uint8_t> bandSlots;bandSlots.reserve(rows.size());
 for(std::size_t i=0;i<rows.size();++i)bandSlots.push_back(rows.band(i,*palette));
 std::vector<AminPointCache::Geometry> geometry(sources->size);std::vector<AminPointCache::Group> markers(sources->size);
 std::vector<std::shared_ptr<std::vector<std::uint32_t>>> pickRows(sources->size);
 std::vector<std::size_t> sourceCounts(sources->size,0);
 for(int k=0;k<wanted;++k){const auto i=std::size_t(k)*rows.size()/wanted;++sourceCounts[rows.source(i)-1];}
 for(int i=0;i<sources->size;++i){pickRows[i]=std::make_shared<std::vector<std::uint32_t>>();pickRows[i]->reserve(sourceCounts[i]);geometry[i].pickRows=pickRows[i];geometry[i].instances.reserve(sourceCounts[i]);geometry[i].bandSlots.reserve(sourceCounts[i]);}
 storage->commit(storage->cost().cpu-sizeof(cyrus::MeshSnapshot)-std::size_t(sources->size)*2*sizeof(Box3));staging->commit();
 const auto time=GetCOREInterface()->GetTime();
 for(int i=0;i<sources->size;++i){auto& dst=geometry[i];dst.color=palette->sourceColors[i];markers[i].color=dst.color;
  if(!sourceCounts[i])continue;
  if(sources->data[i]->is_kind_of(class_tag(Integer))){dst.placeholder=true;continue;}
  INode* node=sources->data[i]->to_node();if(!node)continue;
  auto* object=node->EvalWorldState(time).obj;if(!object||!object->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))continue;
  auto conversion=sourceConversionMemory(object);
  auto* tri=static_cast<TriObject*>(object->ConvertToType(time,Class_ID(TRIOBJ_CLASS_ID,0)));if(!tri)continue;
  if(conversion)conversion->commit();
  auto cleanup=[object](TriObject* p){if(p!=object)p->DeleteThis();};std::unique_ptr<TriObject,decltype(cleanup)> owned(tri,cleanup);
  const auto tm=node->GetObjectTM(time)*Inverse(node->GetNodeTM(time));auto& mesh=tri->GetMesh();
  validateSourceMesh(mesh);if(mesh.getNumVerts()==0||mesh.getNumFaces()==0)continue;
  admitSourceFaces(std::size_t(mesh.getNumFaces()),inspectedFaces,inspectionLimit);
  const bool fullSource=mode==4 && (!budget||mesh.getNumFaces()<=budget);
  dst.reducedBox=mode==4&&!fullSource;
  const auto nextFaces=fullSource?mesh.getNumFaces():(mode==1||mode==4)?12:mode==2?168:6;
  cyrus::viewport_memory::validateDrawCounts(std::size_t(nextFaces),sourceCounts[i]);
  const auto faceBytes=cyrus::viewport_memory::multiply(std::size_t(nextFaces),sizeof(std::array<Point3,3>));
  cyrus::growMeshMemory(storage,faceBytes);
  dst.faces.reserve(nextFaces);
  storage->commit(faceBytes);
  Box3 bounds;bounds.Init();
  for(int f=0;f<mesh.getNumFaces();++f) {
   std::array<Point3,3> points;
   for(int corner=0;corner<3;++corner) {
    const auto vertex=mesh.faces[f].v[corner];
    if(vertex>=unsigned(mesh.getNumVerts()))throw RuntimeError(_T("Preview source has an invalid face vertex"));
    points[corner]=mesh.verts[vertex]*tm;
    for(int axis=0;axis<3;++axis)if(!std::isfinite(points[corner][axis]))throw RuntimeError(_T("Preview source has non-finite geometry"));
    bounds+=points[corner];
   }
   if(fullSource)dst.faces.push_back(points);
  }
  if(fullSource)continue;
  auto lo=bounds.Min(),hi=bounds.Max(),center=(lo+hi)*.5f,half=(hi-lo)*.5f;
  auto add=[&](Point3 a,Point3 b,Point3 c){dst.faces.push_back({a,b,c});};
  if(mode==1||mode==4){Point3 v[8];for(int k=0;k<8;++k)v[k]=Point3(k&1?hi.x:lo.x,k&2?hi.y:lo.y,k&4?hi.z:lo.z);
   const int quads[6][4]={{0,2,3,1},{4,5,7,6},{0,1,5,4},{2,6,7,3},{0,4,6,2},{1,3,7,5}};
   for(auto& q:quads){add(v[q[0]],v[q[1]],v[q[2]]);add(v[q[0]],v[q[2]],v[q[3]]);}
  }else if(mode==2){const int sectors=12,rings=8;
   auto p=[&](int x,int y){double a=x*6.283185307179586/sectors,b=y*3.141592653589793/rings;return center+Point3(float(half.x*std::sin(b)*std::cos(a)),float(half.y*std::sin(b)*std::sin(a)),float(half.z*std::cos(b)));};
   for(int y=0;y<rings;++y)for(int x=0;x<sectors;++x){if(y>0)add(p(x,y),p(x+1,y),p(x+1,y+1));if(y<rings-1)add(p(x,y),p(x+1,y+1),p(x,y+1));}
  }else{
   // Square-base pyramid: four sides and two base triangles (six total).
   Point3 top(center.x,center.y,hi.z);
   Point3 v[4]={Point3(lo.x,lo.y,lo.z),Point3(hi.x,lo.y,lo.z),Point3(hi.x,hi.y,lo.z),Point3(lo.x,hi.y,lo.z)};
   for(int k=0;k<4;++k)add(v[k],v[(k+1)%4],top);
   add(v[0],v[2],v[1]);add(v[0],v[3],v[2]);
  }
 }
 int shown=0;std::size_t faces=0;
 for(int k=0;k<wanted;++k){const auto i=std::size_t(k)*rows.size()/wanted;const auto src=rows.source(i)-1;const auto tm=rows.matrix(i);auto& group=geometry[src];
  if(group.faces.empty()){if(group.placeholder){markers[src].points.push_back(tm.GetTrans());markers[src].bandSlots.push_back(bandSlots[i]);++shown;}continue;}
  // Retain the bounded instance stream. Controller-wide draw admission chooses
  // full meshes or boxes without erasing an entire source from the preview.
  pickRows[src]->push_back(std::uint32_t(i));group.instances.push_back(tm);group.bandSlots.push_back(bandSlots[i]);faces+=group.faces.size();++shown;
 }
 auto out=std::make_unique<AminPointCache>();
 // Proxy shapes use the same immutable source geometry and instance transforms
 // as Mesh. Expanding every proxy face on the CPU defeats retained instancing.
 // GraphicsWindow fallback can still read these snapshots through the accessors.
 auto snapshot=std::make_shared<cyrus::MeshSnapshot>(std::move(geometry),std::move(storage));snapshot->pickView=rows.pickView();out->meshSnapshot=std::move(snapshot);
 out->pointSnapshot=std::make_shared<cyrus::PointSnapshot>(std::move(markers));
 out->palette=palette;out->size=shown;out->faceCount=faces;out->geometryMode=mode;return out.release();
 });
}
def_visible_primitive(cyrusPreviewFaces,"cyrusPreviewFaces");
Value* cyrusPreviewFaces_cf(Value** args,int count){check_arg_count(cyrusPreviewFaces,1,count);type_check(args[0],AminPointCache,_T("cache"));return Integer64::intern(static_cast<AminPointCache*>(args[0])->faceCount);}

