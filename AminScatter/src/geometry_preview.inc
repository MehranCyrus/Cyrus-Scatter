// Source meshes are copied once per cache rebuild, never as scene nodes.
def_visible_primitive(cyrusBuildGeometryPreview,"cyrusBuildGeometryPreview");
Value* cyrusBuildGeometryPreview_cf(Value** args,int count){
 check_arg_count(cyrusBuildGeometryPreview,6,count);
 for(int i=0;i<3;++i)type_check(args[i],Array,_T("geometry preview"));
 auto* rows=static_cast<Array*>(args[0]);auto* sources=static_cast<Array*>(args[1]);auto* colors=static_cast<Array*>(args[2]);
 int mode=args[3]->to_int(),limit=args[4]->to_int(),budget=args[5]->to_int();
 if(mode<1||mode>4||limit<1||limit>100000||budget<12||budget>20000000||sources->size!=colors->size)throw RuntimeError(_T("Invalid geometry display settings"));
 std::vector<AminPointCache::Geometry> geometry(sources->size);std::vector<AminPointCache::Group> markers(sources->size);
 const auto time=GetCOREInterface()->GetTime();
 for(int i=0;i<sources->size;++i){auto& dst=geometry[i];dst.color=colors->data[i]->to_point3()/255.f;markers[i].color=dst.color;
  if(sources->data[i]->is_kind_of(class_tag(Integer))){dst.placeholder=true;continue;}
  INode* node=sources->data[i]->to_node();if(!node)continue;
  auto* object=node->EvalWorldState(time).obj;if(!object||!object->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))continue;
  auto* tri=static_cast<TriObject*>(object->ConvertToType(time,Class_ID(TRIOBJ_CLASS_ID,0)));if(!tri)continue;
  auto cleanup=[object](TriObject* p){if(p!=object)p->DeleteThis();};std::unique_ptr<TriObject,decltype(cleanup)> owned(tri,cleanup);
  const auto tm=node->GetObjectTM(time)*Inverse(node->GetNodeTM(time));auto& mesh=tri->GetMesh();
  if(mesh.getNumVerts()==0)continue;
  if(mode==4){if(mesh.getNumFaces()>budget)continue;dst.faces.reserve(mesh.getNumFaces());for(int f=0;f<mesh.getNumFaces();++f){auto& face=mesh.faces[f];dst.faces.push_back({mesh.verts[face.v[0]]*tm,mesh.verts[face.v[1]]*tm,mesh.verts[face.v[2]]*tm});}continue;}
  Box3 bounds;bounds.Init();for(int v=0;v<mesh.getNumVerts();++v)bounds+=mesh.verts[v]*tm;
  auto lo=bounds.Min(),hi=bounds.Max(),center=(lo+hi)*.5f,half=(hi-lo)*.5f;
  auto add=[&](Point3 a,Point3 b,Point3 c){dst.faces.push_back({a,b,c});};
  if(mode==1){Point3 v[8];for(int k=0;k<8;++k)v[k]=Point3(k&1?hi.x:lo.x,k&2?hi.y:lo.y,k&4?hi.z:lo.z);
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
 int shown=0,faces=0;const int wanted=std::min(limit,int(rows->size));
 for(int k=0;k<wanted;++k){int i=static_cast<int>(static_cast<std::int64_t>(k)*rows->size/wanted);type_check(rows->data[i],Array,_T("placement"));auto* row=static_cast<Array*>(rows->data[i]);if(row->size!=2)throw RuntimeError(_T("Invalid placement"));int src=row->data[1]->to_int()-1;if(src<0||src>=sources->size)throw RuntimeError(_T("Invalid preview source"));auto tm=row->data[0]->to_matrix3();auto& group=geometry[src];
  if(group.faces.empty()){if(group.placeholder){markers[src].points.push_back(tm.GetTrans());++shown;}continue;}
  if(group.faces.size()>static_cast<std::size_t>(budget-faces))continue;
  group.instances.push_back(tm);faces+=static_cast<int>(group.faces.size());++shown;
 }
 auto out=std::make_unique<AminPointCache>();
 if(mode==4) {
  out->meshSnapshot=std::make_shared<cyrus::MeshSnapshot>(std::move(geometry));
  out->pointSnapshot=std::make_shared<cyrus::PointSnapshot>(std::move(markers));
 } else { out->geometry=std::move(geometry);out->groups=std::move(markers); }
 out->size=shown;out->faceCount=faces;out->geometryMode=mode;out->prepareProxyBatches();return out.release();
}
def_visible_primitive(cyrusPreviewFaces,"cyrusPreviewFaces");
Value* cyrusPreviewFaces_cf(Value** args,int count){check_arg_count(cyrusPreviewFaces,1,count);type_check(args[0],AminPointCache,_T("cache"));return Integer::intern(static_cast<AminPointCache*>(args[0])->faceCount);}

