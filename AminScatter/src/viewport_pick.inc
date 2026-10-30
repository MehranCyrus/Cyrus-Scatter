// Included in point_display.cpp. Main-thread only; derived data is disposable.
struct PickEntry {Box3 bounds;Matrix3 tm;unsigned layer=0,group=0,instance=0,pose=0;bool box=false;};
struct PickFaceBlocks {std::vector<Box3> bounds;std::shared_ptr<PreviewMemory> memory;};
struct PickState {
    std::uint64_t ticket=0;
    std::vector<PickEntry> entries;
    std::shared_ptr<PreviewMemory> memory;
    bool rayReady=false,hitFound=false,wire=false;
    Ray ray;
    CyrusViewportHit lastHit;
    IPoint2 selectedPixel{};
    HWND selectedView=nullptr;
    ULONGLONG selectedAt=0;
    std::unordered_map<std::uint64_t,PickFaceBlocks> faceBlocks;
};
static bool pickBox(const Ray& ray,const Box3& box,float limit) {
    if(box.IsEmpty())return false;
    float entryDistance=0,exitDistance=limit;
    for(int a=0;a<3;++a){
        if(std::abs(ray.dir[a])<1e-20f){if(ray.p[a]<box.Min()[a]||ray.p[a]>box.Max()[a])return false;}
        else{float x=(box.Min()[a]-ray.p[a])/ray.dir[a],y=(box.Max()[a]-ray.p[a])/ray.dir[a];if(x>y)std::swap(x,y);entryDistance=std::max(entryDistance,x);exitDistance=std::min(exitDistance,y);if(entryDistance>exitDistance)return false;}
    }return true;
}
static bool pickTriangle(const Ray& ray,const std::array<Point3,3>& t,float& distance,float& u,float& v) {
    const auto e=t[1]-t[0],f=t[2]-t[0],p=CrossProd(ray.dir,f);
    const double d=DotProd(e,p);if(std::abs(d)<1e-18)return false;
    const auto s=ray.p-t[0];u=float(DotProd(s,p)/d);if(u<0||u>1)return false;
    const auto q=CrossProd(s,e);v=float(DotProd(ray.dir,q)/d);if(v<0||u+v>1)return false;
    const float at=float(DotProd(f,q)/d);if(at<0||at>=distance)return false;distance=at;return true;
}
static Point3 pickHost(interactions::Vec p,double units){return {float(p.x/units),float(-p.z/units),float(p.y/units)};}
static std::array<Point3,3> pickFace(const PreviewGeometry& group,const PickEntry& e,unsigned face) {
    if(!group.deformation||e.box)return group.faceData()[face];
    const auto& pose=*group.deformation;std::array<Point3,3> tri;
    for(unsigned k=0;k<3;++k)tri[k]=pickHost(interactions::deformationPoint(*pose.source->data,pose.nodes,face,k,e.pose),pose.metresPerUnit);
    return tri;
}
static bool pickVisible(const PreviewGeometry& group,const PickEntry& e,unsigned face){return !group.deformation||e.box||interactions::deformationVisible(*group.deformation->source->data,group.deformation->nodes,face,e.pose);}
static bool pickOpaque(const PointLayer& layer,unsigned group,unsigned face,float u,float v){
    if(!layer.appearance||group>=layer.appearance->sources.size()||!layer.appearance->sources[group])return true;
    const auto& material=*layer.appearance->sources[group];if(face*3+2>=material.uv.size()||!material.width||!material.tiles)return true;
    auto uv=material.uv[face*3].opacity*(1-u-v)+material.uv[face*3+1].opacity*u+material.uv[face*3+2].opacity*v;
    const int tile=int(std::floor(uv.z+.5f));const double x=uv.x-std::floor(uv.x),yy=1-uv.y,y=yy-std::floor(yy);
    const double size=double(material.width)/material.tiles;
    const int px=std::clamp(int((tile%material.tiles)*size+x*(size-1)+.5),0,material.width-1);
    const int py=std::clamp(int((tile/material.tiles)*size+y*(size-1)+.5),0,material.width-1);
    const auto& pixels=material.texturePixels();return (pixels.at(std::size_t(py)*material.width+px)>>24)>=128;
}
static const std::vector<Box3>& pickFaceBlocks(PickState& cache,const PickEntry& e,const PreviewGeometry& group){
    const auto key=(std::uint64_t(e.layer)<<32)|e.group;
    const auto found=cache.faceBlocks.find(key);if(found!=cache.faceBlocks.end())return found->second.bounds;
    PickFaceBlocks blocks;const auto count=(group.faceData().size()+63)/64;
    blocks.memory=reserveMeshMemory({sizeof(PickFaceBlocks)+64+count*sizeof(Box3),0});blocks.bounds.resize(count);
    for(auto& box:blocks.bounds)box.Init();
    for(std::size_t f=0;f<group.faceData().size();++f)for(const auto& p:group.faceData()[f])blocks.bounds[f/64]+=p;
    blocks.memory->commit();return cache.faceBlocks.emplace(key,std::move(blocks)).first->second.bounds;
}
static std::shared_ptr<PickState> pickPrepare(PointDisplay& display,const std::shared_ptr<Generation>& gen) {
    if(display.pickState&&display.pickState->ticket==gen->ticket)return display.pickState;
    auto next=std::make_shared<PickState>();next->ticket=gen->ticket;
    std::size_t count=0;for(const auto& layer:gen->layers)if(layer.mesh)count+=layer.mesh->instances;
    if(count>1000000)throw std::length_error("Viewport pick inventory exceeds one million displayed instances");
    next->memory=reserveMeshMemory({sizeof(PickState)+count*sizeof(PickEntry),0});next->entries.reserve(count);
    for(unsigned l=0;l<gen->layers.size();++l){const auto& layer=gen->layers[l];if(!layer.mesh||layer.snapshot->lines)continue;
        const auto& mesh=*layer.mesh;
        for(unsigned g=0;g<mesh.groups.size();++g){const auto& group=mesh.groups[g];if(group.faceData().empty())continue;
            const auto& quota=gen->meshPlan[l][g].idle;const auto stride=viewportStride(group.instanceCount());
            for(unsigned k=0;k<quota.count;++k){unsigned i=unsigned(std::size_t(k)*stride%group.instanceCount());PickEntry e;e.layer=l;e.group=g;e.instance=i;e.tm=group.instanceAt(i);e.box=quota.box;
                Box3 local=mesh.localBounds[g];
                if(group.deformation){const auto& pose=*group.deformation;const int change=interactions::deformationFind(pose.changes,unsigned(group.sourceIndex(i)));
                    if(change>=0){const auto& row=pose.changes.words[change];if(row[2]<=0)continue;e.pose=unsigned(row[1]);for(unsigned r=0;r<4;++r){const auto& w=pose.changes.words[change+r+1];e.tm.SetRow(r,Point3(w[0],w[1],w[2]));}}
                    if(e.pose&&!e.box){local.Init();const auto& source=*pose.source->data;const auto& guides=source.source->rig->guides;
                        local+=mesh.localBounds[g]; // fixed pieces remain in rest space
                        for(unsigned guide=0;guide<guides.size();++guide){const float rad=float((source.offsetRadius[guide]+1e-5)/pose.metresPerUnit);
                            for(unsigned n=0;n<guides[guide].rest.nodes.size();++n){const auto& w=pose.nodes.at(e.pose+source.guideSlots[guide]+n*2);auto p=pickHost({w[0],w[1],w[2]},pose.metresPerUnit);local+=p-Point3(rad,rad,rad);local+=p+Point3(rad,rad,rad);}}}
                }e.bounds=local*e.tm;next->entries.push_back(e);
            }
        }
    }next->memory->commit();display.pickState=next;return next;
}
static bool pickQuery(PointDisplay& display,ViewExp* view,IPoint2 pixel,CyrusViewportHit& hit) {
    const auto gen=display.visibleGeneration();if(!gen||!gen->visible()||!gen->submitted.load()||!view)return false;
    Ray ray;view->MapScreenToWorldRay(float(pixel.x),float(pixel.y),ray);ray.dir=Normalize(ray.dir);
    if(!pickBox(ray,gen->bounds,FLT_MAX))return false;
    const auto cache=pickPrepare(display,gen);
    // Max preselection, our hover and the click can ask for the same ray.
    // Reuse only within the exact displayed generation and draw style.
    if(cache->rayReady&&cache->ray.p==ray.p&&cache->ray.dir==ray.dir&&cache->wire==bool(view->IsWire())){if(cache->hitFound)hit=cache->lastHit;return cache->hitFound;}
    cache->rayReady=true;cache->ray=ray;cache->wire=bool(view->IsWire());cache->hitFound=false;
    float closest=FLT_MAX;const PickEntry* winner=nullptr;
    for(const auto& e:cache->entries){if(!pickBox(ray,e.bounds,closest))continue;
        const auto& layer=gen->layers[e.layer];const auto& group=layer.mesh->groups[e.group];const auto inverse=Inverse(e.tm);
        Ray local;local.p=ray.p*inverse;local.dir=VectorTransform(inverse,ray.dir);
        // The unnormalised local direction keeps distances in world-ray units.
        if(e.box){const auto& b=layer.mesh->localBounds[e.group];Point3 v[8];for(int k=0;k<8;++k)v[k]={k&1?b.Max().x:b.Min().x,k&2?b.Max().y:b.Min().y,k&4?b.Max().z:b.Min().z};
            const int q[6][4]={{0,2,3,1},{4,5,7,6},{0,1,5,4},{2,6,7,3},{0,4,6,2},{1,3,7,5}};
            for(const auto& quad:q)for(int k=0;k<2;++k){float d=closest,u=0,vv=0;if(pickTriangle(local,{v[quad[0]],v[quad[k+1]],v[quad[k+2]]},d,u,vv)){closest=d;winner=&e;}}continue;}
        const auto* blocks=group.deformation?nullptr:&pickFaceBlocks(*cache,e,group);
        for(unsigned f=0;f<group.faceData().size();++f){
            if(blocks&&f%64==0&&!pickBox(local,blocks->at(f/64),closest)){f+=63;continue;}
            if(!pickVisible(group,e,f))continue;float distance=closest,u=0,v=0;
            if(pickTriangle(local,pickFace(group,e,f),distance,u,v)&&(view->IsWire()||pickOpaque(layer,e.group,f,u,v))){closest=distance;winner=&e;}}
    }
    if(!winner)return false;const auto& e=*winner;const auto& mesh=*gen->layers[e.layer].mesh;const auto& group=mesh.groups[e.group];
    auto* controller=display.controller.GetRef();if(!controller)return false;
    hit.owner=Animatable::GetHandleByAnim(controller);hit.source=e.group+1;hit.displayLayer=e.layer;hit.group=e.group;hit.instance=e.instance;hit.entry=std::size_t(winner-cache->entries.data());hit.position=ray.p+ray.dir*closest;hit.distance=closest;hit.bounds=e.bounds;
    const auto raw=group.sourceIndex(e.instance);
    if(mesh.pickView&&group.pickRows&&raw<group.pickRows->size()){auto row=group.pickRows->at(raw);hit.layer=mesh.pickView->token().owner;const auto id=mesh.pickView->textIdentity(row);hit.identity.assign(id.begin(),id.end());}
    cache->lastHit=hit;cache->hitFound=true;return true;
}
int pickDisplay(PointDisplay& display,TimeValue,INode*,int type,int,int,IPoint2* p,ViewExp* view){
    if(type!=HITTYPE_POINT||!p||!view)return 0;
    auto* controller=static_cast<INode*>(display.controller.GetRef());if(!controller||controller->IsHidden()||controller->IsFrozen())return 0;
    try{CyrusViewportHit hit;if(!pickQuery(display,view,*p,hit))return 0;
        display.pickState->selectedPixel=*p;display.pickState->selectedView=view->GetHWnd();display.pickState->selectedAt=GetTickCount64();
        IPoint3 screen;view->getGW()->setTransform(Matrix3(1));view->getGW()->wTransPoint(&hit.position,&screen);
        view->getGW()->setHitCode(TRUE);view->getGW()->setHitDistance(DWORD(screen.z));return 1;
    }catch(...){return 0;}
}
