// Host-thread appearance preparation. Geometry and accepted transforms remain
// shared; edits replace only these bounded UV/texture snapshots.
namespace {
constexpr int materialTileSize=256,materialSlotLimit=64;
struct MaterialParameter {
    IParamBlock2* block=nullptr;ParamID id=0;
    explicit operator bool() const {return block!=nullptr;}
};
MaterialParameter materialParameter(Animatable* value,const MCHAR* name) {
    if(value)for(int b=0;b<value->NumParamBlocks();++b)if(auto* block=value->GetParamBlock(b))
        for(int p=0;p<block->NumParams();++p) {
            const auto id=block->IndextoID(p);const auto& def=block->GetParamDef(id);
            if(def.int_name&&_wcsicmp(def.int_name,name)==0)return {block,id};
        }
    return {};
}
float materialNumber(Animatable* value,const MCHAR* name,TimeValue t,float fallback) {
    const auto p=materialParameter(value,name);return p?p.block->GetFloat(p.id,t):fallback;
}
float materialAmount(Animatable* value,const MCHAR* name,TimeValue t) {
    const auto p=materialParameter(value,name);if(!p)return 1.f;
    const float amount=p.block->GetFloat(p.id,t);
    // Percentage parameters expose 100 in MAXScript but store 1 in the SDK.
    if(auto* dimension=p.block->GetParamDef(p.id).dim)return dimension->Convert(amount)/100.f;
    return p.block->GetParameterType(p.id)==TYPE_PCNT_FRAC?amount:amount/100.f;
}
bool materialEnabled(Animatable* value,const MCHAR* name,TimeValue t) {
    const auto p=materialParameter(value,name);return !p||p.block->GetInt(p.id,t)!=0;
}
Color materialColor(Mtl* value,const MCHAR* name,TimeValue t,Color fallback) {
    const auto p=materialParameter(value,name);return p?p.block->GetColor(p.id,t):fallback;
}
Texmap* materialMap(Animatable* value,const MCHAR* name,TimeValue t) {
    const auto p=materialParameter(value,name);return p?p.block->GetTexmap(p.id,t):nullptr;
}
struct MaterialInputs {
    Color color{.5f,.5f,.5f},opacity{1,1,1};
    float level=1,opacityLevel=1,colorAmount=1,opacityAmount=1;
    Texmap* colorMap=nullptr;Texmap* opacityMap=nullptr;
    int colorChannel=1,opacityChannel=1;
    bool supported=true;
};
Texmap* previewMap(Texmap* map,TimeValue t,std::wstring& status) {
    // Forest's per-instance randomization has no Scatter instance context. Its
    // explicit base texture is still useful without changing the scene material.
    for(int depth=0;map&&depth<16;++depth) {
        if(map->ClassID()!=Class_ID(1613723927,104154128))return map;
        status=L"Forest Color: base texture; instance color variation unavailable";
        auto* base=materialMap(map,_T("mapbase"),t);
        if(!base||base==map)return nullptr;
        map=base;
    }
    return map;
}
MaterialInputs materialInputs(Mtl* material,TimeValue t) {
    MaterialInputs out;if(!material)return out;
    Interval valid=FOREVER;material->Update(t,valid);
    out.color=material->GetDiffuse();out.opacityLevel=1-material->GetXParency();
    const auto id=material->ClassID();
    if(id==Class_ID(DMTL_CLASS_ID,0)) {
        auto* standard=static_cast<StdMat*>(material);
        out.color=standard->GetDiffuse(t);out.opacityLevel=standard->GetOpacity(t);
        if(standard->MapEnabled(ID_DI)){out.colorMap=material->GetSubTexmap(ID_DI);out.colorAmount=standard->GetTexmapAmt(ID_DI,t);}
        if(standard->MapEnabled(ID_OP)){out.opacityMap=material->GetSubTexmap(ID_OP);out.opacityAmount=standard->GetTexmapAmt(ID_OP,t);}
    } else if(id==Class_ID(1762831241u,2266306336u)||id==Class_ID(1891525894u,1149841885u)) {
        const bool physical=id==Class_ID(1762831241u,2266306336u);
        out.color=materialColor(material,physical?_T("baseColor"):_T("colorDiffuse"),t,out.color);
        out.opacity=materialColor(material,physical?_T("opacityColor"):_T("colorOpacity"),t,Color(1,1,1));
        out.level=materialNumber(material,physical?_T("baseLevel"):_T("levelDiffuse"),t,1);
        out.opacityLevel=materialNumber(material,physical?_T("opacityLevel"):_T("levelOpacity"),t,1);
        out.colorAmount=materialAmount(material,physical?_T("baseMapAmount"):_T("mapamountDiffuse"),t);
        out.opacityAmount=materialAmount(material,physical?_T("opacityMapAmount"):_T("mapamountOpacity"),t);
        if(materialEnabled(material,physical?_T("baseTexmapOn"):_T("texmapOnDiffuse"),t))
            out.colorMap=materialMap(material,physical?_T("baseTexmap"):_T("texmapDiffuse"),t);
        if(materialEnabled(material,physical?_T("opacityTexmapOn"):_T("texmapOnOpacity"),t))
            out.opacityMap=materialMap(material,physical?_T("opacityTexmap"):_T("texmapOpacity"),t);
    } else out.supported=false;
    return out;
}
// A 2D material preview supports a common explicit UV channel within each map
// branch. Receiver/world/vertex-dependent branches need an explicit fallback.
int materialMapChannel(Texmap* root,TimeValue t,std::wstring& status) {
    if(!root)return 1;
    std::vector<Texmap*> queue{root},seen;int channel=-1;
    for(std::size_t i=0;i<queue.size();++i) {
        auto* map=queue[i];if(!map||std::find(seen.begin(),seen.end(),map)!=seen.end())continue;
        if(seen.size()>=128)throw RuntimeError(_T("Viewport map graph exceeds 128 nodes"));
        seen.push_back(map);
        const auto id=map->ClassID();
        if(id==Class_ID(1613723927,104154128)) {
            // RenderBitmap evaluates this wrapper without a Forest instance.
            // Keep surrounding corrections intact; inspect its explicit base.
            status=L"Forest Color: preview without instance color variation";
            if(auto* base=materialMap(map,_T("mapbase"),t))queue.push_back(base);
            continue;
        }
        if(id==Class_ID(9652305,0)||id==Class_ID(1568227357,1783892597))
            return -1; // Vertex Color / Forest maps require receiver/instance context.
        bool child=false;
        for(int n=0;n<map->NumSubTexmaps();++n)if(map->SubTexmapOn(n))if(auto* sub=map->GetSubTexmap(n)){queue.push_back(sub);child=true;}
        if(!child) {
            if(map->GetUVWSource()!=UVWSRC_EXPLICIT||map->GetTheXYZGen()!=nullptr)return -1;
            int current=map->GetMapChannel();
            if(auto p=materialParameter(map,_T("uvwChannel")))current=p.block->GetInt(p.id,t);
            if(auto p=materialParameter(map,_T("mapChannel")))current=p.block->GetInt(p.id,t);
            if(current<1||current>99||(channel!=-1&&channel!=current))return -1;
            channel=current;
        }
    }
    return channel==-1?1:channel;
}
using MaterialBitmap=std::unique_ptr<Bitmap,void(*)(Bitmap*)>;
MaterialBitmap materialBitmap(Texmap* map,TimeValue t) {
    MaterialBitmap result(nullptr,[](Bitmap* b){if(b)b->DeleteThis();});
    if(!map)return result;
    Interval validity=FOREVER;map->Update(t,validity);
    if(!map->LoadMapFiles(t))throw RuntimeError(_T("A viewport material texture could not be loaded"));
    BitmapInfo info;info.SetWidth(materialTileSize);info.SetHeight(materialTileSize);info.SetType(BMM_FLOAT_RGBA_32);info.SetGamma(1.f);
    result.reset(TheManager->Create(&info));
    if(!result)throw RuntimeError(_T("Viewport texture staging allocation failed"));
    map->RenderBitmap(t,result.get(),1.f,TRUE);
    return result;
}
struct AppearanceWatch;
std::size_t appearanceDependencyCount=0;
struct AppearanceDependency : MaxSDK::SingleWeakRefMaker {
    AppearanceWatch* owner;
    std::shared_ptr<cyrus::PreviewMemory> memory;
    AppearanceDependency(ReferenceTarget* target,AppearanceWatch* parent);
    ~AppearanceDependency() override {--appearanceDependencyCount;}
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID&,RefMessage,BOOL) override;
};
struct AppearanceWatch : MaxSDK::SingleWeakRefMaker {
    std::uint64_t revision=1,use=0;
    bool dependenciesDirty=true;
    Mtl* material=nullptr;
    std::vector<std::unique_ptr<AppearanceDependency>> dependencies;
    std::weak_ptr<const cyrus::SourceAppearance> cached;
    const cyrus::MeshSnapshot* geometry=nullptr;
    std::wstring cacheKey;
    explicit AppearanceWatch(INode* n):SingleWeakRefMaker(n){}
    RefResult NotifyRefChanged(const Interval& interval,RefTargetHandle target,PartID& part,RefMessage message,BOOL propagate) override {
        if(message==REFMSG_TARGET_DELETED||message==REFMSG_SUBANIM_STRUCTURE_CHANGED||
           (message==REFMSG_CHANGE&&(part&(PART_MTL|PART_TEXMAP|PART_VERTCOLOR|PART_GEOM|PART_TOPO)))){++revision;dependenciesDirty=true;}
        return SingleWeakRefMaker::NotifyRefChanged(interval,target,part,message,propagate);
    }
};
AppearanceDependency::AppearanceDependency(ReferenceTarget* target,AppearanceWatch* parent)
    :SingleWeakRefMaker(target),owner(parent),memory(cyrus::reservePreviewMemory(cyrus::meshPreviewBudget,2048)) {++appearanceDependencyCount;}
RefResult AppearanceDependency::NotifyRefChanged(const Interval& interval,RefTargetHandle target,PartID& part,RefMessage message,BOOL propagate) {
    if(message==REFMSG_CHANGE||message==REFMSG_TARGET_DELETED||message==REFMSG_SUBANIM_STRUCTURE_CHANGED){
        ++owner->revision;owner->dependenciesDirty=true;
    }
    return SingleWeakRefMaker::NotifyRefChanged(interval,target,part,message,propagate);
}
void syncAppearanceDependencies(AppearanceWatch& watch,Mtl* material) {
    if(watch.material!=material){watch.material=material;watch.dependenciesDirty=true;++watch.revision;}
    if(!watch.dependenciesDirty)return;
    // UV generators and nested maps do not consistently propagate their edits
    // through a node's weak reference (especially beneath Multi/Sub materials).
    // Observe the bounded authored reference graph directly, on the host thread.
    std::vector<ReferenceTarget*> graph;
    if(material)graph.push_back(material);
    for(std::size_t i=0;i<graph.size();++i) {
        auto* target=graph[i];
        for(int r=0;r<target->NumRefs();++r)if(auto* child=target->GetReference(r))
            if(std::find(graph.begin(),graph.end(),child)==graph.end()){
                if(graph.size()>=1024)throw RuntimeError(_T("Viewport material dependency graph exceeds 1,024 references"));
                graph.push_back(child);
            }
    }
    if(appearanceDependencyCount-watch.dependencies.size()+graph.size()>16384)
        throw RuntimeError(_T("Viewport material dependency allowance exceeded"));
    std::vector<std::unique_ptr<AppearanceDependency>> next;next.reserve(graph.size());
    for(auto* target:graph)next.push_back(std::make_unique<AppearanceDependency>(target,&watch));
    watch.dependencies.swap(next);watch.dependenciesDirty=false;
}
std::vector<std::unique_ptr<AppearanceWatch>> appearanceWatches;
std::uint64_t appearanceUse=0;
struct AppearanceColorWatch {
    std::uint64_t revision=1;
    static void changed(void* context,NotifyInfo*){++static_cast<AppearanceColorWatch*>(context)->revision;}
    AppearanceColorWatch(){RegisterNotification(changed,this,NOTIFY_COLOR_MANAGEMENT_POST_CHANGE);}
    ~AppearanceColorWatch(){UnRegisterNotification(changed,this,NOTIFY_COLOR_MANAGEMENT_POST_CHANGE);}
};
AppearanceWatch& appearanceWatch(INode* node) {
    appearanceWatches.erase(std::remove_if(appearanceWatches.begin(),appearanceWatches.end(),[](const auto& w){return !w->GetRef();}),appearanceWatches.end());
    for(auto& w:appearanceWatches)if(w->GetRef()==node){w->use=++appearanceUse;return *w;}
    if(appearanceWatches.size()>=512) {
        auto oldest=std::min_element(appearanceWatches.begin(),appearanceWatches.end(),[](const auto& a,const auto& b){return a->use<b->use;});
        appearanceWatches.erase(oldest);
    }
    appearanceWatches.push_back(std::make_unique<AppearanceWatch>(node));
    appearanceWatches.back()->use=++appearanceUse;return *appearanceWatches.back();
}
std::wstring appearanceSourceKey(INode* node,TimeValue t) {
    static AppearanceColorWatch colors;
    auto& watch=appearanceWatch(node);auto* material=node->GetMtl();
    Interval validity=FOREVER;if(material)material->Update(t,validity);
    syncAppearanceDependencies(watch,material);
    const auto space=MaxSDK::ColorManagement::IColorPipelineMgr::GetInstance()->Settings()->GetCurrentRenderingColorSpace();
    return std::to_wstring(node->GetHandle())+L":"+std::to_wstring(watch.revision)+L":"+
        std::to_wstring(reinterpret_cast<std::uintptr_t>(material))+L":"+std::to_wstring(validity.Start())+L":"+
        std::to_wstring(validity.End())+L":"+space.data()+L":"+std::to_wstring(colors.revision);
}
std::wstring appearanceKey(Array* sources) {
    if(sources->size>512)throw RuntimeError(_T("Viewport materials support at most 512 sources"));
    std::wstring key;
    for(int i=0;i<sources->size;++i) {
        if(cyrus::rows::integer(sources->data[i])){key+=L"0|";continue;}
        auto* node=sources->data[i]->to_node();if(!node)throw RuntimeError(_T("A viewport material source is missing"));
        key+=appearanceSourceKey(node,GetCOREInterface()->GetTime())+L"|";
    }
    return key;
}
std::shared_ptr<const cyrus::SourceAppearance> prepareSourceAppearance(INode* node,const cyrus::MeshSnapshot& snapshot,std::size_t source) {
    const auto& group=snapshot.groups[source];
    if(group.placeholder||group.reducedBox||group.faces.empty()||group.instances.empty())return {};
    const auto t=GetCOREInterface()->GetTime();auto key=appearanceSourceKey(node,t);auto& watch=appearanceWatch(node);
    if(watch.geometry==&snapshot&&watch.cacheKey==key)if(auto cached=watch.cached.lock())return cached;
    auto* object=node->EvalWorldState(t).obj;
    auto* tri=object?static_cast<TriObject*>(object->ConvertToType(t,Class_ID(TRIOBJ_CLASS_ID,0))):nullptr;
    if(!tri)throw RuntimeError(_T("Viewport material source has no triangle mesh"));
    auto cleanup=[object](TriObject* p){if(p!=object)p->DeleteThis();};std::unique_ptr<TriObject,decltype(cleanup)> owned(tri,cleanup);
    auto& mesh=tri->GetMesh();
    if(std::size_t(mesh.getNumFaces())!=group.faces.size())throw RuntimeError(_T("Source geometry is pending. Use Update before refreshing materials."));
    const auto transform=node->GetObjectTM(t)*Inverse(node->GetNodeTM(t));
    auto staging=cyrus::reservePreviewMemory(cyrus::meshPreviewBudget,2*materialTileSize*materialTileSize*sizeof(BMM_Color_fl)+group.faces.size()*sizeof(int));
    std::vector<Mtl*> materials;std::vector<int> slots;slots.reserve(group.faces.size());
    auto* root=node->GetMtl();
    for(int f=0;f<mesh.getNumFaces();++f) {
        // Never pair pending topology/positions with frozen Manual placements.
        for(int c=0;c<3;++c)if(mesh.verts[mesh.faces[f].v[c]]*transform!=group.faces[f][c])
            throw RuntimeError(_T("Source geometry is pending. Use Update before refreshing materials."));
        Mtl* material=root;
        if(root&&root->ClassID()==Class_ID(MULTI_CLASS_ID,0))material=root->GetSubMtl(mesh.faces[f].getMatID());
        auto found=std::find(materials.begin(),materials.end(),material);
        if(found==materials.end()){if(materials.size()>=materialSlotLimit)throw RuntimeError(_T("Viewport materials exceed 64 submaterials per source"));materials.push_back(material);slots.push_back(int(materials.size()-1));}
        else slots.push_back(int(found-materials.begin()));
    }
    auto result=std::make_shared<cyrus::SourceAppearance>();
    result->tiles=int(std::ceil(std::sqrt(double(materials.size()))));result->width=result->tiles*materialTileSize;
    const auto pixels=std::size_t(result->width)*result->width;
    result->cpuBytes=sizeof(*result)+pixels*4+group.faces.size()*3*sizeof(cyrus::MaterialUV);
    // Reservation includes temporary bitmap/row data and peak immutable overlap.
    result->memory=cyrus::reservePreviewMemory(cyrus::meshPreviewBudget,result->cpuBytes);
    result->pixels.resize(pixels,0xffffffff);result->uv.resize(group.faces.size()*3);
    std::vector<MaterialInputs> inputs;inputs.reserve(materials.size());
    auto pipeline=MaxSDK::ColorManagement::IColorPipelineMgr::GetInstance()->GetDefaultViewingPipeline(MaxSDK::ColorManagement::DisplayViewTarget::kVIEWPORT);
    if(!pipeline)throw RuntimeError(_T("Viewport color conversion is unavailable"));
    auto converter=pipeline->GetColorConverter<Color,BMM_Color_32>();
    for(std::size_t slot=0;slot<materials.size();++slot) {
        auto input=materialInputs(materials[slot],t);
        input.colorMap=previewMap(input.colorMap,t,result->status);input.opacityMap=previewMap(input.opacityMap,t,result->status);
        input.colorChannel=materialMapChannel(input.colorMap,t,result->status);input.opacityChannel=materialMapChannel(input.opacityMap,t,result->status);
        if(!input.supported){result->status=L"Unsupported material: base color fallback";input.colorMap=nullptr;input.opacityMap=nullptr;}
        if(input.colorChannel<0){result->status=L"Unsupported color map: base color fallback";input.colorMap=nullptr;input.colorChannel=1;}
        if(input.opacityChannel<0){result->status=L"Unsupported opacity map: material opacity fallback";input.opacityMap=nullptr;input.opacityChannel=1;}
        auto color=materialBitmap(input.colorMap,t),opacity=materialBitmap(input.opacityMap,t);
        std::array<BMM_Color_fl,materialTileSize> colors{},alphas{};
        for(int y=0;y<materialTileSize;++y) {
            if(color&&!color->GetLinearPixels(0,y,materialTileSize,colors.data()))throw RuntimeError(_T("Viewport color texture read failed"));
            if(opacity&&!opacity->GetLinearPixels(0,y,materialTileSize,alphas.data()))throw RuntimeError(_T("Viewport opacity texture read failed"));
            for(int x=0;x<materialTileSize;++x) {
                Color c=input.color,o=input.opacity;
                if(color)c=c*(1-input.colorAmount)+Color(colors[x].r,colors[x].g,colors[x].b)*input.colorAmount;
                if(opacity)o=o*(1-input.opacityAmount)+Color(alphas[x].r,alphas[x].g,alphas[x].b)*input.opacityAmount;
                auto pixel=converter->ConvertColor(c*input.level);
                const auto alpha=std::uint32_t(255*std::clamp((o.r+o.g+o.b)/3*input.opacityLevel,0.f,1.f));
                const auto index=(slot/result->tiles*materialTileSize+y)*result->width+slot%result->tiles*materialTileSize+x;
                result->pixels[index]=std::uint32_t(pixel.b)|(std::uint32_t(pixel.g)<<8)|(std::uint32_t(pixel.r)<<16)|(alpha<<24);
            }
        }
        inputs.push_back(input);
    }
    auto uv=[&](int channel,int f,int c,bool needed) {
        if(!needed)return Point3(0,0,0);
        if(!mesh.mapSupport(channel)||mesh.getNumMapVerts(channel)<1||!mesh.mapFaces(channel))
            throw RuntimeError(_T("Viewport material needs a missing source UV channel"));
        const auto index=mesh.mapFaces(channel)[f].t[c];if(index>=unsigned(mesh.getNumMapVerts(channel)))throw RuntimeError(_T("Viewport material UV face is incomplete"));
        auto p=mesh.mapVerts(channel)[index];
        if(!std::isfinite(p.x)||!std::isfinite(p.y))throw RuntimeError(_T("Viewport material UV is non-finite"));
        p.z=float(slots[f]);return p;
    };
    for(int f=0;f<mesh.getNumFaces();++f)for(int c=0;c<3;++c) {
        auto& input=inputs[slots[f]];auto& target=result->uv[f*3+c];
        target.color=uv(input.colorChannel,f,c,input.colorMap!=nullptr);target.color.z=float(slots[f]);
        target.opacity=uv(input.opacityChannel,f,c,input.opacityMap!=nullptr);target.opacity.z=float(slots[f]);
    }
    watch.geometry=&snapshot;watch.cacheKey=appearanceSourceKey(node,t);watch.cached=result;return result;
}
}
def_visible_primitive(cyrusMaterialPreviewKey,"cyrusMaterialPreviewKey");
Value* cyrusMaterialPreviewKey_cf(Value** args,int count) {
    check_arg_count(cyrusMaterialPreviewKey,1,count);type_check(args[0],Array,_T("material sources"));
    return new String(appearanceKey(static_cast<Array*>(args[0])).c_str());
}
def_visible_primitive(cyrusTexturePreview,"cyrusTexturePreview");
Value* cyrusTexturePreview_cf(Value** args,int count) {
    check_arg_count(cyrusTexturePreview,2,count);type_check(args[0],AminPointCache,_T("material preview"));type_check(args[1],Array,_T("material sources"));
    auto* cache=static_cast<AminPointCache*>(args[0]);auto* sources=static_cast<Array*>(args[1]);
    if(!cache->meshSnapshot||cache->geometryMode!=4||cache->palette->mode!=4)return args[0];
    const auto key=appearanceKey(sources);
    if(cache->appearance&&cache->appearance->key==key)return args[0];
    if(std::size_t(sources->size)!=cache->meshSnapshot->groups.size())throw RuntimeError(_T("Material source correspondence differs"));
    auto appearance=std::make_shared<cyrus::MeshAppearance>();appearance->key=key;appearance->sources.resize(sources->size);
    for(int i=0;i<sources->size;++i)if(!cyrus::rows::integer(sources->data[i])) {
        auto data=prepareSourceAppearance(sources->data[i]->to_node(),*cache->meshSnapshot,i);appearance->sources[i]=data;
        if(data){appearance->cpuBytes+=data->cpuBytes;appearance->gpuBytes+=data->pixels.size()*4+data->uv.size()*sizeof(cyrus::MaterialUV);if(!data->status.empty())appearance->status=data->status;}
        if(appearance->cpuBytes+2*appearance->gpuBytes>cyrus::meshPreviewOwnerLimit/2)throw RuntimeError(_T("Viewport material resources exceed the appearance allowance"));
    }
    appearance->key=appearanceKey(sources);
    auto result=std::make_unique<AminPointCache>();
    result->pointSnapshot=cache->pointSnapshot;result->meshSnapshot=cache->meshSnapshot;result->palette=cache->palette;
    result->size=cache->size;result->faceCount=cache->faceCount;result->geometryMode=cache->geometryMode;result->appearance=appearance;
    return result.release();
}
def_visible_primitive(cyrusMaterialPreviewStatus,"cyrusMaterialPreviewStatus");
Value* cyrusMaterialPreviewStatus_cf(Value** args,int count) {
    check_arg_count(cyrusMaterialPreviewStatus,1,count);type_check(args[0],AminPointCache,_T("material preview"));
    const auto* cache=static_cast<AminPointCache*>(args[0]);
    return new String(cache->appearance?cache->appearance->status.c_str():_T(""));
}
