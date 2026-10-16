// Mesh channels are numeric field data, independent of texture UV coordinates.
// Every SDK read is synchronous on the host thread. No borrowed map pointers escape.
namespace {
std::uint64_t meshDensityReads=0,meshDensityRows=0,meshDensityPreviews=0;
cyrus::mesh_density::Settings meshDensitySettings(Value* value) {
    auto* a=groupArray(value);
    if(a->size!=7)throw RuntimeError(_T("Mesh density requires seven settings"));
    cyrus::mesh_density::Settings s;
    if((a->data[0]!=&true_value&&a->data[0]!=&false_value)||(a->data[5]!=&true_value&&a->data[5]!=&false_value))
        throw RuntimeError(_T("Invalid mesh density enable/invert flag"));
    s.enabled=a->data[0]==&true_value;s.channel=a->data[1]->to_int();s.component=a->data[2]->to_int()-1;
    s.minimum=a->data[3]->to_double();s.maximum=a->data[4]->to_double();s.invert=a->data[5]==&true_value;
    auto* curve=groupArray(a->data[6]);s.curve.clear();
    if(curve->size>257)throw RuntimeError(_T("Mesh density curve exceeds 257 samples"));
    for(int i=0;i<curve->size;++i)s.curve.push_back(curve->data[i]->to_double());
    cyrus::mesh_density::validate(s);return s;
}
struct MeshDensitySnapshot {
    std::vector<std::array<double,3>> corners;
    std::vector<amin::Vec3> previewPoints;
    std::uint64_t hash=1469598103934665603ULL;
};
MeshDensitySnapshot meshDensitySnapshot(INode* node,const cyrus::mesh_density::Settings& s,std::size_t budget=0) {
    amin::diagnostics::StageTimer measurement(amin::diagnostics::Stage::MeshChannel);
    if(!node)throw RuntimeError(_T("Mesh density receiver is missing"));
    const auto fail=[&](const wchar_t* reason){
        const std::wstring message=std::wstring(L"Mesh density: receiver '")+node->GetName()+L"', channel "+std::to_wstring(s.channel)+L": "+reason+L". Repair/select the channel or disable the mask. The previous result is retained.";
        throw RuntimeError(message.c_str());
    };
    const auto time=GetCOREInterface()->GetTime();auto* object=node->EvalWorldState(time).obj;
    if(!object||!object->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))fail(L"not mesh-convertible");
    auto* tri=static_cast<TriObject*>(object->ConvertToType(time,Class_ID(TRIOBJ_CLASS_ID,0)));
    if(!tri)fail(L"mesh evaluation failed");
    const auto cleanup=[object](TriObject* p){if(p!=object)p->DeleteThis();};
    std::unique_ptr<TriObject,decltype(cleanup)> holder(tri,cleanup);
    auto& mesh=tri->GetMesh();
    const auto faces=std::size_t(mesh.getNumFaces());
    if(faces>cyrus::mesh_density::faceLimit)fail(L"exceeds 2 million evaluated faces");
    if(!mesh.mapSupport(s.channel)||!mesh.mapVerts(s.channel)||!mesh.mapFaces(s.channel)||
       mesh.getNumMapVerts(s.channel)<1||mesh.getNumMapFaces(s.channel)!=mesh.getNumFaces())fail(L"missing or incomplete channel");
    MeshDensitySnapshot result;result.corners.reserve(faces);
    const auto* values=mesh.mapVerts(s.channel);const auto* mapping=mesh.mapFaces(s.channel);
    const auto count=std::size_t(mesh.getNumMapVerts(s.channel));
    const auto add=[&](double value){std::uint64_t bits=0;std::memcpy(&bits,&value,sizeof(bits));for(int byte=0;byte<8;++byte){result.hash^=(bits>>(byte*8))&255;result.hash*=1099511628211ULL;}};
    add(double(faces));
    for(std::size_t i=0;i<faces;++i){
        std::array<double,3> corners{};
        for(int k=0;k<3;++k){const auto index=std::size_t(mapping[i].t[k]);if(index>=count)fail(L"invalid map-face vertex index");
            corners[k]=values[index][s.component];if(!std::isfinite(corners[k]))fail(L"nonfinite selected component");add(corners[k]);}
        result.corners.push_back(corners);
    }
    if(budget&&faces){
        const auto tm=node->GetObjectTM(time);const auto samples=std::min(budget,faces);result.previewPoints.reserve(samples);
        for(std::size_t k=0;k<samples;++k){const auto face=k*faces/samples;const auto& f=mesh.faces[face];
            for(int j=0;j<3;++j)if(f.v[j]>=DWORD(mesh.getNumVerts()))fail(L"invalid geometry face");
            result.previewPoints.push_back(vec(((mesh.verts[f.v[0]]+mesh.verts[f.v[1]]+mesh.verts[f.v[2]])/3)*tm));}
    }
    ++meshDensityReads;return result;
}
}
def_visible_primitive(cyrusMeshDensityVersion,"cyrusMeshDensityVersion");
Value* cyrusMeshDensityVersion_cf(Value**,int n){check_arg_count(cyrusMeshDensityVersion,0,n);return Integer::intern(1);}
def_visible_primitive(cyrusValidateMeshDensity,"cyrusValidateMeshDensity");
Value* cyrusValidateMeshDensity_cf(Value** a,int n){check_arg_count(cyrusValidateMeshDensity,1,n);
    try{meshDensitySettings(a[0]);}catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}return &ok;}
def_visible_primitive(cyrusMeshDensityKey,"cyrusMeshDensityKey");
Value* cyrusMeshDensityKey_cf(Value** a,int n){check_arg_count(cyrusMeshDensityKey,2,n);
    try{const auto s=meshDensitySettings(a[1]);if(!s.enabled)return new String(L"off");
        const auto snapshot=meshDensitySnapshot(a[0]->to_node(),s);return new String(std::to_wstring(snapshot.hash).c_str());
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}}
def_visible_primitive(cyrusMeshDensityFilter,"cyrusMeshDensityFilter");
Value* cyrusMeshDensityFilter_cf(Value** a,int n){check_arg_count(cyrusMeshDensityFilter,5,n);
    amin::diagnostics::StageTimer measurement(amin::diagnostics::Stage::Mask);
    auto* rows=groupArray(a[0]);if(rows->size>1000000)throw RuntimeError(_T("Mesh density exceeds candidate limit"));
    one_typed_value_local(Array* result);vl.result=new Array(rows->size);
    try{const auto s=meshDensitySettings(a[2]);
        const auto snapshot=s.enabled?meshDensitySnapshot(a[1]->to_node(),s):MeshDensitySnapshot{};
        const auto seed=std::uint32_t(a[3]->to_int());const auto salt=cyrus::receivers::salt(proceduralID(a[4]));
        for(int i=0;i<rows->size;++i){auto* row=groupArray(rows->data[i]);cyrus::rows::raw(row);bool keep=true;
            if(s.enabled){const int face=row->data[3]->to_int()-1;if(face<0||std::size_t(face)>=snapshot.corners.size())throw RuntimeError(_T("Mesh density anchor is outside receiver"));
                unsigned slot=0;std::uint64_t ordinal=0;const auto id=std::uint64_t(row->data[2]->to_int64());
                if(!cyrus::receivers::decodeCandidate(id,slot,ordinal))throw RuntimeError(_T("Mesh density candidate identity is invalid"));
                const auto value=cyrus::mesh_density::sample(snapshot.corners[std::size_t(face)],vec(row->data[4]->to_point3()));
                keep=cyrus::mesh_density::accepts(cyrus::mesh_density::weight(value,s),seed,ordinal,salt);++meshDensityRows;}
            if(keep)vl.result->append(row);
        }
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}return_value(vl.result);
}
def_visible_primitive(cyrusMeshDensityPreview,"cyrusMeshDensityPreview");
Value* cyrusMeshDensityPreview_cf(Value** a,int n){check_arg_count(cyrusMeshDensityPreview,3,n);
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(0);
    try{const auto s=meshDensitySettings(a[1]);const int requested=a[2]->to_int();
        if(requested<1||requested>int(cyrus::mesh_density::previewLimit))throw RuntimeError(_T("Mesh density preview supports 1..2048 samples"));
        if(s.enabled){const auto snapshot=meshDensitySnapshot(a[0]->to_node(),s,std::size_t(requested));const auto count=snapshot.previewPoints.size();
            for(std::size_t i=0;i<count;++i){const auto face=i*snapshot.corners.size()/count;
                vl.row=new Array(2);vl.result->append(vl.row);vl.row->append(new Point3Value(point(snapshot.previewPoints[i])));
                vl.row->append(Float::intern(float(cyrus::mesh_density::weight(cyrus::mesh_density::sample(snapshot.corners[face],{1./3,1./3,1./3}),s))));}
            ++meshDensityPreviews;}
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}return_value(vl.result);
}
def_visible_primitive(cyrusMeshDensityStats,"cyrusMeshDensityStats");
Value* cyrusMeshDensityStats_cf(Value**,int n){check_arg_count(cyrusMeshDensityStats,0,n);
    one_typed_value_local(Array* result);vl.result=new Array(3);for(auto v:{meshDensityReads,meshDensityRows,meshDensityPreviews})vl.result->append(Integer64::intern(v));return_value(vl.result);}
