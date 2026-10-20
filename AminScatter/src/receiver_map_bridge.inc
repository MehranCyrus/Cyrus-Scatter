// Host-thread-only texture evaluation. Each operation borrows one map graph and
// owns its evaluated TriObject for the synchronous call; no SDK pointer is cached.
namespace {
std::uint64_t receiverMapPreparations=0,receiverMapSamples=0;
struct ReceiverMapMeshDelete {
    Object* original=nullptr;
    void operator()(TriObject* value) const {if(value&&value!=original)value->DeleteThis();}
};
class ReceiverMapContext final : public ShadeContext {
    INode* node_;
    Texmap* map_;
    TimeValue time_;
    std::unique_ptr<TriObject,ReceiverMapMeshDelete> object_;
    Matrix3 toWorld_,toLocal_;
    Box3 bounds_;
    BitArray channels_{MAX_MESHMAPS};
    int face_=0;
    Point3 bary_{1,0,0},normal_{0,0,1},position_{0,0,0};
    std::uint64_t hash_=1469598103934665603ULL;
    std::size_t nodes_=0,meshBytes_=0;
    void add(double value) {
        std::uint64_t bits=0;std::memcpy(&bits,&value,sizeof(bits));
        for(int i=0;i<8;++i){hash_^=(bits>>(i*8))&255;hash_*=1099511628211ULL;}
    }
    [[noreturn]] void fail(const std::wstring& reason) const {
        const auto text=std::wstring(L"Density map on '")+node_->GetName()+L"': "+reason;
        throw RuntimeError(text.c_str());
    }
    void graph(Texmap* map,std::set<Texmap*>& visited,std::set<Texmap*>& active,int depth) {
        if(!map)return;
        if(active.count(map))fail(L"the texture graph contains a cycle.");
        if(visited.count(map))return;
        if(depth>32||visited.size()>=64)fail(L"the texture graph exceeds 64 maps or 32 nested levels.");
        const auto id=map->ClassID();
        const bool supported=id==Class_ID(CHECKER_CLASS_ID,0)||id==Class_ID(VCOL_CLASS_ID,0)||
            id==Class_ID(OUTPUT_CLASS_ID,0)||id==Class_ID(COLORCORRECTION_CLASS_ID,0)||
            id==Class_ID(BMTEX_CLASS_ID,0)||id==Class_ID(MIX_CLASS_ID,0)||
            id==Class_ID(NOISE_CLASS_ID,0)||id==Class_ID(RGBMULT_CLASS_ID,0)||id==Class_ID(GRADIENT_CLASS_ID,0);
        if(!supported)fail(std::wstring(L"map '")+map->GetName().data()+L"' is not supported with receiver coordinates. Use a supported map or an explicitly projected image.");
        visited.insert(map);active.insert(map);
        const int count=map->NumSubTexmaps();
        if(count<0||count>128)fail(L"the texture has too many input slots.");
        // Update/Requirements may visit disabled slots too. Validate the whole
        // referenced graph before invoking either SDK traversal.
        for(int i=0;i<count;++i)graph(map->GetSubTexmap(i),visited,active,depth+1);
        active.erase(map);
    }
    const Mesh& mesh() const {return object_->GetMesh();}
    void validateChannel(int channel) {
        const auto& m=mesh();
        const auto label=L"channel "+std::to_wstring(channel);
        if(channel<0||channel>99||!m.mapSupport(channel)||!m.mapVerts(channel)||!m.mapFaces(channel)||
            m.getNumMapVerts(channel)<1||m.getNumMapFaces(channel)!=m.getNumFaces())
            fail(label+L" is missing or incomplete. Select an existing channel in the map or add it to this receiver.");
        add(channel);const auto* values=m.mapVerts(channel);const auto* faces=m.mapFaces(channel);
        const auto count=std::size_t(m.getNumMapVerts(channel));
        for(int f=0;f<m.getNumFaces();++f)for(int k=0;k<3;++k){
            const auto index=std::size_t(faces[f].t[k]);if(index>=count)fail(label+L" has an invalid face index.");
            for(int axis=0;axis<3;++axis){const double value=values[index][axis];if(!std::isfinite(value))fail(label+L" contains nonfinite values.");add(value);}
        }
    }
public:
    ReceiverMapContext(INode* node,Texmap* map,std::size_t samples,std::size_t remainingBytes=256ULL*1024*1024):node_(node),map_(map),time_(GetCOREInterface()->GetTime()) {
        if(!node_||!map_)throw RuntimeError(_T("Density evaluation requires a receiver and a texture map."));
        std::set<Texmap*> visited,active;graph(map_,visited,active,0);nodes_=visited.size();
        if(samples>1000000||nodes_*samples>32000000)fail(L"evaluation exceeds its work limit. Reduce the amount or simplify the map graph.");
        Interval valid=FOREVER;map_->Update(time_,valid);
        const auto requirements=map_->Requirements(-1);
        if(requirements&(MTLREQ_VIEW_DEP|MTLREQ_BGCOL|MTLREQ_AUTOREFLECT|MTLREQ_AUTOMIRROR|MTLREQ_PREPRO|MTLREQ_OXYZ|MTLREQ_FACEMAP))
            fail(L"the graph requires a camera, renderer, face mapping or undeformed coordinates that this density mode does not supply.");
        auto* original=node_->EvalWorldState(time_).obj;
        if(!original||!original->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))fail(L"the receiver is not mesh-convertible.");
        auto* evaluated=static_cast<TriObject*>(original->ConvertToType(time_,Class_ID(TRIOBJ_CLASS_ID,0)));
        if(!evaluated)fail(L"the receiver could not be evaluated.");
        object_=decltype(object_)(evaluated,ReceiverMapMeshDelete{original});
        const auto& m=mesh();
        if(m.getNumFaces()<1||m.getNumVerts()<1||m.getNumFaces()>2000000||m.getNumVerts()>2000000)fail(L"the receiver must contain 1..2 million faces and vertices.");
        // Account even unused channels/vertices: a converted object retains all
        // of them until the synchronous call ends. Overlay receivers share one
        // aggregate allowance. Host-owned texture caches are not included.
        const auto account=[&](std::size_t count,std::size_t stride){
            if(count>(remainingBytes-meshBytes_)/stride)fail(L"retained receiver mesh arrays exceed the 256 MiB evaluation budget. Simplify the mesh or remove unused channels.");
            meshBytes_+=count*stride;
        };
        account(std::size_t(m.getNumVerts()),sizeof(Point3));account(std::size_t(m.getNumFaces()),sizeof(Face));
        if(m.getNumMaps()>MAX_MESHMAPS)fail(L"the receiver exceeds the supported channel count.");
        for(int channel=-2;channel<m.getNumMaps();++channel)if(m.mapSupport(channel)){
            if(m.getNumMapVerts(channel)<0||m.getNumMapFaces(channel)<0)fail(L"the receiver has invalid channel storage.");
            account(std::size_t(m.getNumMapVerts(channel)),sizeof(UVVert));account(std::size_t(m.getNumMapFaces(channel)),sizeof(TVFace));
        }
        toWorld_=node_->GetObjectTM(time_);
        double matrix[3][3],lengthProduct=1.;
        for(int i=0;i<4;++i){const auto row=toWorld_.GetRow(i);double squared=0.;for(int j=0;j<3;++j){
            if(!std::isfinite(row[j]))fail(L"the receiver transform is nonfinite.");
            if(i<3){matrix[i][j]=row[j];squared+=matrix[i][j]*matrix[i][j];}
        }if(i<3)lengthProduct*=std::sqrt(squared);}
        const auto determinant=matrix[0][0]*(matrix[1][1]*matrix[2][2]-matrix[1][2]*matrix[2][1])-matrix[0][1]*(matrix[1][0]*matrix[2][2]-matrix[1][2]*matrix[2][0])+matrix[0][2]*(matrix[1][0]*matrix[2][1]-matrix[1][1]*matrix[2][0]);
        if(lengthProduct==0.||std::abs(determinant)<=lengthProduct*1e-8)fail(L"the receiver transform is singular or too close to singular.");
        toLocal_=Inverse(toWorld_);bounds_.Init();
        for(int i=0;i<m.getNumVerts();++i){
            const auto& p=m.verts[i];for(int axis=0;axis<3;++axis)if(!std::isfinite(p[axis]))fail(L"the receiver has nonfinite geometry.");bounds_+=p;
        }
        for(int f=0;f<m.getNumFaces();++f)for(int k=0;k<3;++k)if(m.faces[f].v[k]>=DWORD(m.getNumVerts()))fail(L"the receiver has an invalid geometry face.");
        channels_.ClearAll();BitArray bump(MAX_MESHMAPS);bump.ClearAll();map_->MappingsRequired(-1,channels_,bump);
        std::size_t required=0;for(int i=0;i<channels_.GetSize();++i)if(channels_[i])++required;
        if(required*std::size_t(m.getNumFaces())>16000000)fail(L"required channel data exceeds its work limit. Simplify the receiver or map graph.");
        for(int i=0;i<channels_.GetSize();++i)if(channels_[i])validateChannel(i);
        doMaps=TRUE;filterMaps=FALSE;backFace=FALSE;mtlNum=0;ambientLight=Color(0,0,0);xshadeID=0;
        ++receiverMapPreparations;
    }
    std::uint64_t channelKey() const {return hash_;}
    std::size_t meshBytes() const {return meshBytes_;}
    double sample(int face,Point3 bary,bool invert,const std::vector<double>& response) {
        if(face<0||face>=mesh().getNumFaces())fail(L"a placement refers to a missing receiver face.");
        for(int i=0;i<3;++i)if(!std::isfinite(bary[i])||bary[i]<-.0001f||bary[i]>1.0001f)fail(L"a placement has invalid barycentric coordinates.");
        if(std::abs(bary.x+bary.y+bary.z-1)>0.0001f)fail(L"a placement has invalid barycentric coordinates.");
        face_=face;bary_=bary;const auto& f=mesh().faces[face_];
        position_=mesh().verts[f.v[0]]*bary.x+mesh().verts[f.v[1]]*bary.y+mesh().verts[f.v[2]]*bary.z;
        const auto a=mesh().verts[f.v[0]]*toWorld_,b=mesh().verts[f.v[1]]*toWorld_,c=mesh().verts[f.v[2]]*toWorld_;
        normal_=Normalize(CrossProd(b-a,c-a));mtlNum=object_->GetMesh().faces[face_].getMatID();
        // Each call supplies a new point; ShadeContext's default cache is disabled.
        const AColor color=map_->EvalColor(*this);++receiverMapSamples;
        double value=color.r*.2126+color.g*.7152+color.b*.0722;
        if(!std::isfinite(value))fail(L"the texture returned a nonfinite density value.");
        value=std::clamp(value,0.0,1.0);if(invert)value=1-value;
        const double position=value*double(response.size()-1);const auto i=std::min(std::size_t(position),response.size()-2);
        return std::clamp(response[i]+(response[i+1]-response[i])*(position-double(i)),0.0,1.0);
    }
    BOOL InMtlEditor() override {return FALSE;}
    LightDesc* Light(int) override {return nullptr;}
    TimeValue CurTime() override {return time_;}
    INode* Node() override {return node_;}
    Object* GetEvalObject() override {return object_.get();}
    int FaceNumber() override {return face_;}
    Point3 BarycentricCoords() override {return bary_;}
    Point3 Normal() override {return normal_;}
    void SetNormal(Point3 value) override {normal_=value;}
    Point3 GNormal() override {return normal_;}
    Point3 V() override {fail(L"the map requested a camera direction.");}
    void SetView(Point3) override {fail(L"the map requested a camera direction.");}
    Point3 ReflectVector() override {fail(L"reflection maps require a renderer.");}
    Point3 RefractVector(float) override {fail(L"refraction maps require a renderer.");}
    Point3 CamPos() override {fail(L"the map requested a camera position.");}
    Point3 P() override {return position_*toWorld_;}
    Point3 DP() override {return Point3(0,0,0);}
    Point3 PObj() override {return position_;}
    Point3 DPObj() override {return Point3(0,0,0);}
    Box3 ObjectBox() override {return bounds_;}
    Point3 PObjRelBox() override {
        const auto size=bounds_.Width();Point3 result(0,0,0);
        for(int i=0;i<3;++i)if(size[i]>0)result[i]=2*(position_[i]-bounds_.pmin[i])/size[i]-1;
        return result;
    }
    Point3 DPObjRelBox() override {return Point3(0,0,0);}
    void ScreenUV(Point2&,Point2&) override {fail(L"screen-space maps require a renderer.");}
    IPoint2 ScreenCoord() override {fail(L"screen-space maps require a renderer.");}
    Point3 UVW(int channel=0) override {
        if(channel<0||channel>=channels_.GetSize()||!channels_[channel])fail(L"the map requested an undeclared channel. This map is not supported with receiver coordinates.");
        const auto* values=mesh().mapVerts(channel);const auto& f=mesh().mapFaces(channel)[face_];
        return values[f.t[0]]*bary_.x+values[f.t[1]]*bary_.y+values[f.t[2]]*bary_.z;
    }
    Point3 DUVW(int) override {return Point3(0,0,0);}
    void DPdUVW(Point3[3],int) override {fail(L"bump-vector evaluation is not supported for density.");}
    void GetBGColor(Color&,Color&,BOOL) override {fail(L"background maps require a renderer.");}
    Matrix3 MatrixTo(RefFrame target) override {return target==REF_OBJECT?toLocal_:Matrix3(1);}
    Matrix3 MatrixFrom(RefFrame source) override {return source==REF_OBJECT?toWorld_:Matrix3(1);}
    Point3 PointTo(const Point3& p,RefFrame target) override {return p*MatrixTo(target);}
    Point3 PointFrom(const Point3& p,RefFrame source) override {return p*MatrixFrom(source);}
    Point3 VectorTo(const Point3& p,RefFrame target) override {return VectorTransform(MatrixTo(target),p);}
    Point3 VectorFrom(const Point3& p,RefFrame source) override {return VectorTransform(MatrixFrom(source),p);}
};
}

def_visible_primitive(cyrusReceiverMapKey,"cyrusReceiverMapKey");
Value* cyrusReceiverMapKey_cf(Value** a,int n){check_arg_count(cyrusReceiverMapKey,2,n);
    try{ReceiverMapContext context(a[0]->to_node(),a[1]->to_texmap(),0);
        return new String(std::to_wstring(context.channelKey()).c_str());
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}

def_visible_primitive(cyrusReceiverMapFilter,"cyrusReceiverMapFilter");
Value* cyrusReceiverMapFilter_cf(Value** a,int n){check_arg_count(cyrusReceiverMapFilter,7,n);
    try{
        const auto& view=cyrusPlacementView(a[0]);
        if(view.stage()!=cyrus::placements::Stage::Candidates)throw RuntimeError(_T("Map density requires raw native candidates."));
        const auto mapping=densityMapping(a[3]);ReceiverMapContext context(a[1]->to_node(),a[2]->to_texmap(),view.size());
        const auto seed=std::uint32_t(a[5]->to_int());const auto salt=cyrus::receivers::salt(proceduralID(a[6]))^0x7c2d1b93u;
        std::vector<std::uint32_t> selected;selected.reserve(view.size());
        for(std::size_t i=0;i<view.size();++i){const auto& row=view.at(i);unsigned slot=0;std::uint64_t ordinal=0;
            if(!cyrus::receivers::decodeCandidate(row.identity,slot,ordinal))throw RuntimeError(_T("Map density candidate identity is invalid."));
            const double weight=context.sample(int(row.face)-1,Point3(float(row.bary[0]),float(row.bary[1]),float(row.bary[2])),a[4]->to_bool()!=FALSE,mapping.curve);
            if(cyrus::mesh_density::accepts(weight,seed,ordinal,salt))selected.push_back(static_cast<std::uint32_t>(i));
        }
        if(selected.size()==view.size())return a[0];return cyrusPlacementValue(view.select(selected));
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}

def_visible_primitive(cyrusReceiverMapSample,"cyrusReceiverMapSample");
Value* cyrusReceiverMapSample_cf(Value** a,int n){check_arg_count(cyrusReceiverMapSample,4,n);
    try{ReceiverMapContext context(a[0]->to_node(),a[1]->to_texmap(),1);
        return Double::intern(context.sample(a[2]->to_int()-1,a[3]->to_point3(),false,{0,1}));
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}

def_visible_primitive(cyrusReceiverMapStats,"cyrusReceiverMapStats");
Value* cyrusReceiverMapStats_cf(Value**,int n){check_arg_count(cyrusReceiverMapStats,0,n);one_typed_value_local(Array* result);vl.result=new Array(2);
    vl.result->append(Integer64::intern(receiverMapPreparations));vl.result->append(Integer64::intern(receiverMapSamples));return_value(vl.result);
}
