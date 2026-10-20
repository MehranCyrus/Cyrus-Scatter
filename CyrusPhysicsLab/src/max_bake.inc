// Document members. Scene publication and conversion run only on Max's host thread.
bool bakeOnFinish=false;
void installBaked(const std::shared_ptr<State>& solved,const MCHAR* label){
 if(theHold.Holding())throw std::runtime_error("Finish the current Max Undo operation before baking Physics");
 if(solved->rows.empty()){bakeOnFinish=false;return;}
 auto* owner=GetCOREInterface()->GetINodeByHandle(ownerHandle);
 if(!owner)throw std::runtime_error("Physics owner was deleted; pending result retained");
 const unsigned slot=freeCollider(),count=std::max(colliderCount,slot+1);
 // Preflight the input for the NEXT session before creating any scene object.
 cpl::Mesh collider;std::size_t vertices=0,faces=0;
 for(auto row:solved->rows){const auto& model=solved->input.sources.at(row.source).render;vertices+=model.vertices.size();faces+=model.faces.size();}
 if(vertices>200000||faces>200000)throw std::runtime_error("Bake collider exceeds 200,000 vertices or triangles. Reduce the batch density or source mesh detail; pending preview retained.");
 collider.vertices.reserve(vertices);collider.faces.reserve(faces);
 for(auto row:solved->rows){const auto& model=solved->input.sources.at(row.source).render;const unsigned base=unsigned(collider.vertices.size());for(auto p:model.vertices)collider.vertices.push_back(cpl::rotate(row.rotation,p*row.scale)+row.position);for(auto f:model.faces)collider.faces.push_back({base+f[0],base+f[1],base+f[2]});}
 auto empty=std::make_shared<State>(*solved);empty->rows.clear();empty->recipe.clear();empty->input.frozen.clear();empty->input.colliders.push_back(collider);++empty->revision;
 try{cpl::validate(empty->input);}catch(const std::exception& e){throw std::runtime_error(std::string("Bake collider budget: ")+e.what()+". Pending preview retained.");}
 trace("bake.prepare",{{"bodies",solved->rows.size()},{"vertices",vertices},{"triangles",faces},{"collider_slot",slot}});
 // Staging owns every object until it is handed to Max. Mesh conversion is bounded.
 struct DeleteObject{void operator()(Object* object)const{if(object)object->DeleteThis();}};
 std::unique_ptr<TriObject,DeleteObject> tri(CreateNewTriObject());
 if(!tri)throw std::runtime_error("Cannot allocate baked mesh; pending preview retained");
 auto assembled=mesh(false,0,0,solved.get());tri->GetMesh()=*assembled;assembled.reset();
 auto* converted=tri->ConvertToType(GetCOREInterface()->GetTime(),polyObjectClassID);
 std::unique_ptr<Object,DeleteObject> convertedPoly(converted==tri.get()?nullptr:converted);
 if(!converted||converted==tri.get()||converted->ClassID()!=polyObjectClassID)throw std::runtime_error("Editable Poly conversion failed; pending preview retained");
 tri.reset();
 // polyObjectClassID is the SDK's bare PolyMeshObject, not the artist-editable
 // Editable Poly plug-in. Publish the real Editable Poly class with that mesh.
 std::unique_ptr<Object,DeleteObject> poly(static_cast<Object*>(GetCOREInterface()->CreateInstance(GEOMOBJECT_CLASS_ID,EPOLYOBJ_CLASS_ID)));
 if(!poly||poly->ClassID()!=EPOLYOBJ_CLASS_ID)throw std::runtime_error("Editable Poly class is unavailable; pending preview retained");
 static_cast<PolyObject*>(poly.get())->GetMesh()=static_cast<PolyObject*>(convertedPoly.get())->GetMesh();
 static_cast<PolyObject*>(poly.get())->GetMesh().InvalidateGeomCache();convertedPoly.reset();
 // Poly conversion may change triangulation. Validate its real float vertices
 // in the same metre frame that the next Start will capture, before accepting.
 ::Mesh polyTriangles;static_cast<PolyObject*>(poly.get())->GetMesh().OutToTri(polyTriangles);
 cpl::Mesh recaptured;recaptured.vertices.reserve(polyTriangles.numVerts);recaptured.faces.reserve(polyTriangles.numFaces);
 const Vec storedOrigin=vec(point(solved->origin));
 for(int i=0;i<polyTriangles.numVerts;++i)recaptured.vertices.push_back((vec(polyTriangles.verts[i])+storedOrigin-solved->origin)*solved->metersPerUnit);
 for(int i=0;i<polyTriangles.numFaces;++i){const auto& f=polyTriangles.faces[i];recaptured.faces.push_back({f.v[0],f.v[1],f.v[2]});}
 auto cookInfo=cpl::joltColliderInfo(recaptured);trace("bake.collider.ready",cookInfo);
 empty->input.colliders.back()=std::move(recaptured);cpl::validate(empty->input);
 auto before=state;const unsigned beforeCount=colliderCount;INode* node=nullptr;bool held=false;
 publishing=true;
 try{
#ifdef CPL_TEST_FAULTS
  if(fault==1){fault=0;throw std::runtime_error("Injected failure before bake publication");}
#endif
  theHold.Begin();held=true;
  node=GetCOREInterface()->CreateObjectNode(poly.get());if(!node)throw std::runtime_error("Cannot create baked scene node");poly.release();
  MSTR name(_T("Physics_Baked_"));GetCOREInterface()->MakeNameUnique(name);node->SetName(name);
  Matrix3 transform(1);transform.SetTrans(point(solved->origin));node->SetNodeTM(GetCOREInterface()->GetTime(),transform);
  node->SetMtl(owner->GetMtl());node->SetWireColor(owner->GetWireColor());
  node->SetUserPropInt(_T("CyrusPhysicsLabBodies"),int(solved->rows.size()));
  node->SetUserPropString(_T("CyrusPhysicsLabVersion"),_T("0.2.1"));
  theHold.Put(new ColliderRestore(this,slot,node,count));
  theHold.Put(new ResultRestore(this,before,empty));
  ReplaceReference(128+slot,node);colliderCount=count;state=empty;
#ifdef CPL_TEST_FAULTS
  if(fault==2){fault=0;throw std::runtime_error("Injected failure after bake assignment");}
#endif
  // Use the baked triangles immediately for inspection; Start recaptures editable geometry.
  prepareCollisionDisplay(*state);changed();
  theHold.Accept(label);held=false;publishing=false;++commits;
 }catch(...){
  state=before;if(held)theHold.Cancel();colliderCount=beforeCount;publishing=false;
  prepareCollisionDisplay(*solved);changed();trace("bake.rollback");throw;
 }
 // Diagnostic allocation failure must never roll back state after Max accepted
 // the transaction. Publication above is complete and independently Undoable.
 try{trace("bake.commit",{{"node",node->GetHandle()},{"bodies",solved->rows.size()},{"triangles",faces}});}catch(...){}
 diagnosticSnapshot("baked");
}
