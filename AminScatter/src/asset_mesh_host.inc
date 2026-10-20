// Included globally by recipes_bridge.cpp after its shared helpers. SDK work is
// synchronous on the host thread; no original object/normal array is changed.
namespace {
using AssetMeshProfile=cyrus::assets::MeshProfile;
struct AssetMeshSource {
    Object* object=nullptr;TriObject* tri=nullptr;INode* node=nullptr;TimeValue time=0;
    explicit AssetMeshSource(INode* value):node(value){
        if(!node)throw RuntimeError(_T("Package source was deleted"));time=GetCOREInterface()->GetTime();object=node->EvalWorldState(time).obj;
        if(!object||!object->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))throw RuntimeError(_T("Source cannot provide a static triangle mesh"));
        if(object->IsAnimated())throw RuntimeError(_T("Animated geometry needs a separate portable adapter"));
        tri=static_cast<TriObject*>(object->ConvertToType(time,Class_ID(TRIOBJ_CLASS_ID,0)));if(!tri)throw RuntimeError(_T("Source mesh conversion failed"));
    }
    ~AssetMeshSource(){if(tri&&tri!=object)tri->DeleteThis();}
    AssetMeshSource(const AssetMeshSource&)=delete;AssetMeshSource& operator=(const AssetMeshSource&)=delete;
};
std::array<cyrus::assets::Vertex,3> assetMeshLinear(const Matrix3& m){std::array<cyrus::assets::Vertex,3> a{};for(int i=0;i<3;++i)for(int j=0;j<3;++j)a[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]=m.GetRow(i)[j];return a;}
void assetMeshMatrix(const Matrix3& m){for(int i=0;i<4;++i)for(int j=0;j<3;++j)if(!std::isfinite(m.GetRow(i)[j]))throw RuntimeError(_T("Source transform is not finite"));cyrus::assets::transformStoredNormal({1,0,0},assetMeshLinear(m));}
double assetMeshDet(const Matrix3& m){const auto a=assetMeshLinear(m);return a[0][0]*(a[1][1]*a[2][2]-a[1][2]*a[2][1])-a[0][1]*(a[1][0]*a[2][2]-a[1][2]*a[2][0])+a[0][2]*(a[1][0]*a[2][1]-a[1][1]*a[2][0]);}
// CYRUS SDK NORMAL CANONICALIZATION BEGIN
// Point3 stores float components. Canonicalize at this host capture boundary,
// before encoding; the data-only codec retains its exact binary64 contract.
cyrus::assets::Vertex assetMeshSDKNormal(const cyrus::assets::Vertex& value){
    cyrus::assets::Vertex result{};double length2=0;
    for(std::size_t i=0;i<3;++i){const float component=static_cast<float>(value[i]);if(!std::isfinite(value[i])||!std::isfinite(component))throw std::invalid_argument("Normal cannot be represented by SDK Point3");result[i]=static_cast<double>(component);length2+=result[i]*result[i];}
    if(length2==0)throw std::invalid_argument("Normal underflows to zero in SDK Point3");return result;
}
// CYRUS SDK NORMAL CANONICALIZATION END
void assetMeshPoint(const cyrus::assets::Vertex& v){for(auto x:v)if(!std::isfinite(x)||std::abs(x)>1e9)throw RuntimeError(_T("Source coordinates exceed portable finite bounds"));}
struct AssetMeshInspection {
    AssetMeshProfile profile=AssetMeshProfile::Legacy;Matrix3 offset{1};
    std::size_t vertices=0,faces=0,normalCount=0,encodedBytes=0,decodedBytes=0;std::uint32_t normalFlags=0;
    std::vector<int> channels;
};
// mode0 is the preserved Legacy export, mode1 explicitly Plant, mode2 inspect.
// Inspection validates SDK data and computes requested typed capacities without
// copying vertex, face, map or normal arrays into a second mesh.
AssetMeshInspection inspectAssetMesh(AssetMeshSource& source,double metres,int mode){
    using namespace cyrus::assets;
    if(!std::isfinite(metres)||metres<=0||metres>1e12)throw RuntimeError(_T("Invalid scene units"));
    auto& mesh=source.tri->GetMesh();const auto nv=mesh.getNumVerts(),nf=mesh.getNumFaces();
    const auto maxV=mode==0?maxMeshVertices:maxPlantMeshVertices,maxF=mode==0?maxMeshFaces:maxPlantMeshFaces,maxMV=mode==0?maxMapVertices:maxPlantMapVertices;
    if(nv<1||nf<1||static_cast<std::size_t>(nv)>maxV||static_cast<std::size_t>(nf)>maxF)throw RuntimeError(_T("Source geometry exceeds its finite mesh profile"));
    AssetMeshInspection out;out.vertices=static_cast<std::size_t>(nv);out.faces=static_cast<std::size_t>(nf);
    const auto nt=source.node->GetNodeTM(source.time),ot=source.node->GetObjectTM(source.time);assetMeshMatrix(nt);assetMeshMatrix(ot);
    // Equal actual transforms cancel exactly. Multiplying a float Matrix3 by
    // its computed inverse can introduce a false object offset on each export.
    // Compare all components, not Matrix3::Equals' epsilon or authored offset
    // properties: GetObjectTM can also reflect world-space pipeline context.
    bool sameTransform=true;for(int i=0;i<4;++i)for(int j=0;j<3;++j)if(ot.GetRow(i)[j]!=nt.GetRow(i)[j])sameTransform=false;
    out.offset=sameTransform?Matrix3(1):ot*Inverse(nt);assetMeshMatrix(out.offset);
    // Reflected object offsets need a separately proven winding/corner adapter.
    // Node transforms remain separately serialized and are not baked here.
    if(mode!=0&&assetMeshDet(out.offset)<=0)throw RuntimeError(_T("Reflected object offsets need a separate plant mesh adapter"));
    const auto linear=assetMeshLinear(out.offset);
    if((nv&&!mesh.verts)||(nf&&!mesh.faces))throw RuntimeError(_T("Source topology data is unavailable"));
    for(int i=0;i<nv;++i){const auto p=mesh.verts[i]*out.offset;assetMeshPoint({p.x/metres,p.y/metres,p.z/metres});}
    for(int i=0;i<nf;++i){auto& f=mesh.faces[i];for(int c=0;c<3;++c)if(f.v[c]>=static_cast<DWORD>(nv))throw RuntimeError(_T("Source face index is invalid"));}
    out.encodedBytes=20+out.vertices*24+out.faces*24;out.decodedBytes=sizeof(cyrus::assets::Mesh)+out.vertices*sizeof(Vertex)+out.faces*sizeof(cyrus::assets::Face);
    if(mesh.getNumMaps()>100)throw RuntimeError(_T("Source mapping channels exceed portable channel IDs"));
    for(int ch=-2;ch<mesh.getNumMaps();++ch)if(mesh.mapSupport(ch)){
        const int mv=mesh.getNumMapVerts(ch),mf=mesh.getNumMapFaces(ch);if(mv==0){if(mode!=0&&mf!=0)throw RuntimeError(_T("Empty source map has face data"));continue;}
        if(mv<0||static_cast<std::size_t>(mv)>maxMV||mf!=nf||!mesh.mapVerts(ch)||!mesh.mapFaces(ch)||out.channels.size()>=maxMeshChannels)throw RuntimeError(_T("Source mapping channels exceed portable bounds"));
        out.channels.push_back(ch);out.encodedBytes+=12+static_cast<std::size_t>(mv)*24+out.faces*12;
        out.decodedBytes+=sizeof(Mapping)+static_cast<std::size_t>(mv)*sizeof(Vertex)+out.faces*sizeof(Triangle);
        for(int i=0;i<mv;++i){const auto& p=mesh.mapVerts(ch)[i];assetMeshPoint({p.x,p.y,p.z});}
        for(int i=0;i<mf;++i)for(int c=0;c<3;++c)if(mesh.mapFaces(ch)[i].t[c]>=static_cast<DWORD>(mv))throw RuntimeError(_T("Source map index is invalid"));
    }
    auto* ns=mesh.GetSpecifiedNormals();
    if(ns&&ns->GetNumNormals()>0){
        if(mode==0)throw RuntimeError(_T("Stored normals require the explicitly selected plant mesh adapter"));
        const int nn=ns->GetNumNormals();if(nn>static_cast<int>(maxPlantNormals)||ns->GetNumFaces()!=nf||!ns->GetNormalArray()||!ns->GetFaceArray())throw RuntimeError(_T("Source stored-normal counts exceed portable bounds"));
        if(ns->GetFlag(~supportedMeshNormalFlags))throw RuntimeError(_T("Source stored normals contain unsupported flags; the original is preserved"));
        for(const auto flag:{MESH_NORMAL_NORMALS_BUILT,MESH_NORMAL_NORMALS_COMPUTED,MESH_NORMAL_FACE_ANGLES,MESH_NORMAL_MODIFIER_SUPPORT})if(ns->GetFlag(flag))out.normalFlags|=flag;
        if((out.normalFlags&3u)!=3u)throw RuntimeError(_T("Unbuilt or uncomputed stored normals need a separately qualified derivative"));
        out.normalCount=static_cast<std::size_t>(nn);
        for(int i=0;i<nn;++i){const auto& p=ns->Normal(i);assetMeshSDKNormal(transformStoredNormal({p.x,p.y,p.z},linear));}
        for(int i=0;i<nf;++i)for(int c=0;c<3;++c){const auto& f=ns->Face(i);const int id=f.GetNormalID(c);if(!((id==-1&&!f.GetSpecified(c))||(id>=0&&id<nn)))throw RuntimeError(_T("Source stored-normal corner index is invalid"));}
        out.encodedBytes+=out.normalCount*28+out.faces*16;out.decodedBytes+=out.normalCount*(sizeof(Vertex)+sizeof(std::uint8_t))+out.faces*sizeof(NormalFace);
    }else if(mode!=0&&ns&&(ns->GetNumNormals()<0||ns->GetNumFaces()!=0||ns->GetFlag(0xffffffffu)))throw RuntimeError(_T("Empty stored-normal state needs a separate adapter"));
    bool legacy=out.normalCount==0&&out.vertices<=maxMeshVertices&&out.faces<=maxMeshFaces&&out.encodedBytes<=maxLegacyMeshBytes;
    for(int ch:out.channels)legacy=legacy&&mesh.getNumMapVerts(ch)<=static_cast<int>(maxMapVertices);
    out.profile=mode==1||!legacy?AssetMeshProfile::Plant:AssetMeshProfile::Legacy;if(mode==0)out.profile=AssetMeshProfile::Legacy;
    if(out.profile==AssetMeshProfile::Plant){
        // A native proxy's viewport snapshot is not full render geometry proof.
        const auto sourceClass=source.object->ClassID();
        const bool independentMesh=sourceClass==Class_ID(TRIOBJ_CLASS_ID,0)||sourceClass==Class_ID(EDITTRIOBJ_CLASS_ID,0)
            ||sourceClass==Class_ID(POLYOBJ_CLASS_ID,0)||sourceClass==EPOLYOBJ_CLASS_ID;
        if(!independentMesh)throw RuntimeError(_T("Plant geometry requires an independent editable mesh derivative; native proxies are preserved"));
        out.encodedBytes+=12;if(out.encodedBytes>maxPlantMeshBytes)throw RuntimeError(_T("Plant mesh exceeds 224 MiB encoded admission"));
    }else if(out.encodedBytes>maxLegacyMeshBytes)throw RuntimeError(_T("Legacy mesh exceeds 32 MiB encoded admission"));
    return out;
}
cyrus::assets::Mesh captureAssetMesh(AssetMeshSource& source,const AssetMeshInspection& info,double metres){
    using namespace cyrus::assets;auto& mesh=source.tri->GetMesh();cyrus::assets::Mesh out;out.profile=info.profile;out.vertices.reserve(info.vertices);out.faces.reserve(info.faces);out.maps.reserve(info.channels.size());
    for(int i=0;i<mesh.getNumVerts();++i){const auto p=mesh.verts[i]*info.offset;out.vertices.push_back({p.x/metres,p.y/metres,p.z/metres});}
    for(int i=0;i<mesh.getNumFaces();++i){auto& f=mesh.faces[i];out.faces.push_back({{f.v[0],f.v[1],f.v[2]},f.smGroup,f.getMatID(),static_cast<std::uint32_t>((f.getEdgeVis(0)?1:0)|(f.getEdgeVis(1)?2:0)|(f.getEdgeVis(2)?4:0))});}
    for(int ch:info.channels){Mapping map;map.channel=ch;map.vertices.reserve(mesh.getNumMapVerts(ch));map.faces.reserve(info.faces);for(int i=0;i<mesh.getNumMapVerts(ch);++i){const auto& v=mesh.mapVerts(ch)[i];map.vertices.push_back({v.x,v.y,v.z});}for(int i=0;i<mesh.getNumFaces();++i){const auto& f=mesh.mapFaces(ch)[i];map.faces.push_back({f.t[0],f.t[1],f.t[2]});}out.maps.push_back(std::move(map));}
    if(info.normalCount){auto* ns=mesh.GetSpecifiedNormals();out.normals.emplace();auto& dest=*out.normals;dest.flags=info.normalFlags;dest.vectors.reserve(info.normalCount);dest.explicitFlags.reserve(info.normalCount);dest.faces.reserve(info.faces);const auto linear=assetMeshLinear(info.offset);
        for(int i=0;i<ns->GetNumNormals();++i){const auto& p=ns->Normal(i);dest.vectors.push_back(assetMeshSDKNormal(transformStoredNormal({p.x,p.y,p.z},linear)));dest.explicitFlags.push_back(ns->GetNormalExplicit(i)?1:0);}
        for(int i=0;i<ns->GetNumFaces();++i){NormalFace face;for(int c=0;c<3;++c){face.ids[static_cast<std::size_t>(c)]=ns->Face(i).GetNormalID(c);face.specified[static_cast<std::size_t>(c)]=ns->Face(i).GetSpecified(c)?1:0;}dest.faces.push_back(face);}
    }
    validateMesh(out,info.profile);if(meshEncodedBytes(out,info.profile)!=info.encodedBytes||meshStorageBytes(out)!=info.decodedBytes)throw RuntimeError(_T("Mesh resource plan differs from actual typed allocations"));return out;
}
Value* createAssetMesh(const cyrus::assets::Mesh& data,double metres,const MCHAR* sourceName){
    using namespace cyrus::assets;if(!theHold.Holding())throw RuntimeError(_T("Portable mesh creation requires its owning authored transaction"));
    if(!std::isfinite(metres)||metres<=0||metres>1e12)throw RuntimeError(_T("Invalid destination units"));validateMesh(data,data.profile);
    const auto cleanup=[](TriObject* p){if(p)p->DeleteThis();};std::unique_ptr<TriObject,decltype(cleanup)> tri(CreateNewTriObject(),cleanup);if(!tri)throw RuntimeError(_T("Cannot allocate portable mesh"));auto& mesh=tri->GetMesh();
    if(!mesh.setNumVerts(static_cast<int>(data.vertices.size()))||!mesh.setNumFaces(static_cast<int>(data.faces.size())))throw RuntimeError(_T("Cannot allocate mesh topology"));
    auto point=[metres](const Vertex& v,bool distance){Point3 p;for(int i=0;i<3;++i){const auto d=v[static_cast<std::size_t>(i)]*(distance?metres:1.);if(!std::isfinite(d)||std::abs(d)>1e20)throw RuntimeError(_T("Portable geometry exceeds destination units"));p[i]=static_cast<float>(d);}return p;};
    for(std::size_t i=0;i<data.vertices.size();++i)mesh.verts[i]=point(data.vertices[i],true);
    for(std::size_t i=0;i<data.faces.size();++i){const auto& f=data.faces[i];auto& target=mesh.faces[i];target.setVerts(f.vertices[0],f.vertices[1],f.vertices[2]);target.smGroup=f.smoothing;target.setMatID(static_cast<MtlID>(f.material));target.setEdgeVisFlags((f.edges&1)!=0,(f.edges&2)!=0,(f.edges&4)!=0);}
    int mapCount=2;for(const auto& m:data.maps)mapCount=std::max(mapCount,m.channel+1);mesh.setNumMaps(mapCount);
    for(const auto& m:data.maps){mesh.setMapSupport(m.channel,TRUE);mesh.setNumMapVerts(m.channel,static_cast<int>(m.vertices.size()));mesh.setNumMapFaces(m.channel,static_cast<int>(m.faces.size()));if(mesh.getNumMapVerts(m.channel)!=static_cast<int>(m.vertices.size())||mesh.getNumMapFaces(m.channel)!=static_cast<int>(m.faces.size())||!mesh.mapVerts(m.channel)||!mesh.mapFaces(m.channel))throw RuntimeError(_T("Cannot allocate portable mapping channel"));for(std::size_t i=0;i<m.vertices.size();++i)mesh.mapVerts(m.channel)[i]=point(m.vertices[i],false);for(std::size_t i=0;i<m.faces.size();++i)for(int c=0;c<3;++c)mesh.mapFaces(m.channel)[i].t[c]=m.faces[i][static_cast<std::size_t>(c)];}
    // Build ordinary caches before attaching stored data. No build/check/clear
    // normal operation follows the stored-normal restoration below.
    mesh.InvalidateGeomCache();mesh.buildNormals();mesh.buildBoundingBox();
    if(data.normals){const auto& from=*data.normals;mesh.SpecifyNormals();auto* ns=mesh.GetSpecifiedNormals();if(!ns||!ns->SetNumNormals(static_cast<int>(from.vectors.size()))||!ns->SetNumFaces(static_cast<int>(from.faces.size())))throw RuntimeError(_T("Cannot allocate stored-normal topology"));ns->SetParent(&mesh);
        for(std::size_t i=0;i<from.vectors.size();++i){ns->Normal(static_cast<int>(i))=point(from.vectors[i],false);ns->SetNormalExplicit(static_cast<int>(i),from.explicitFlags[i]!=0);}
        for(std::size_t i=0;i<from.faces.size();++i)for(int c=0;c<3;++c){ns->Face(static_cast<int>(i)).SetNormalID(c,from.faces[i].ids[static_cast<std::size_t>(c)]);ns->Face(static_cast<int>(i)).SetSpecified(c,from.faces[i].specified[static_cast<std::size_t>(c)]!=0);}
        ns->ClearFlag(0xffffffffu);ns->SetFlag(from.flags);if(ns->GetFlag(~supportedMeshNormalFlags)||!ns->GetFlag(MESH_NORMAL_NORMALS_BUILT)||!ns->GetFlag(MESH_NORMAL_NORMALS_COMPUTED))throw RuntimeError(_T("Stored-normal state was not restored"));
    }
    auto* ip=GetCOREInterface();MSTR name(sourceName);if(name.Length()<1||name.Length()>160)throw RuntimeError(_T("Portable source name exceeds bounds"));ip->MakeNameUnique(name);auto* node=ip->CreateObjectNode(tri.get());if(!node)throw RuntimeError(_T("Cannot create portable source node"));tri.release();node->SetName(name);node->Hide(TRUE);return MAXNode::intern(node);
}
Value* exportAssetMesh(Value** a,bool plant){
    auto* node=a[0]->to_node();type_check(a[1],String,_T("mesh staging filename"));const std::filesystem::path path(a[1]->to_string());const double metres=a[2]->to_double();
    if(!path.is_absolute()||std::filesystem::exists(path))throw RuntimeError(_T("Mesh export needs a new absolute filename"));AssetMeshSource source(node);const auto info=inspectAssetMesh(source,metres,plant?1:0);const auto data=captureAssetMesh(source,info,metres);const auto bytes=cyrus::assets::encodeMesh(data,info.profile);
    std::ofstream out(path,std::ios::binary);if(!out)throw RuntimeError(_T("Cannot create owned mesh staging file"));out.write(reinterpret_cast<const char*>(bytes.data()),static_cast<std::streamsize>(bytes.size()));out.flush();if(!out)throw RuntimeError(_T("Mesh staging write failed"));out.close();return recipeValue(r::Json::array({r::digest(bytes),bytes.size(),data.vertices.size(),data.faces.size(),data.maps.size()}));
}
}
def_visible_primitive(cyrusAssetMeshExport,"cyrusAssetMeshExport");
Value* cyrusAssetMeshExport_cf(Value** a,int n){check_arg_count(cyrusAssetMeshExport,3,n);return recipeAPI([&](){return exportAssetMesh(a,false);});}
def_visible_primitive(cyrusAssetPlantMeshExport,"cyrusAssetPlantMeshExport");
Value* cyrusAssetPlantMeshExport_cf(Value** a,int n){check_arg_count(cyrusAssetPlantMeshExport,3,n);return recipeAPI([&](){return exportAssetMesh(a,true);});}
def_visible_primitive(cyrusAssetMeshProfile,"cyrusAssetMeshProfile");
Value* cyrusAssetMeshProfile_cf(Value** a,int n){check_arg_count(cyrusAssetMeshProfile,1,n);return recipeAPI([&]()->Value*{const double scale=GetSystemUnitScale(UNITS_METERS);if(!std::isfinite(scale)||scale<=0)throw RuntimeError(_T("Invalid source system units"));AssetMeshSource source(a[0]->to_node());const auto x=inspectAssetMesh(source,1./scale,2);return recipeValue(r::Json::array({x.profile==AssetMeshProfile::Plant?"plant":"legacy",x.encodedBytes,x.decodedBytes,x.vertices,x.faces,x.channels.size(),x.normalCount,x.normalFlags,x.channels}));});}
def_visible_primitive(cyrusAssetMeshCreate,"cyrusAssetMeshCreate");
Value* cyrusAssetMeshCreate_cf(Value** a,int n){check_arg_count(cyrusAssetMeshCreate,4,n);return recipeAPI([&]()->Value*{
    if(!theHold.Holding())throw RuntimeError(_T("Portable mesh creation requires its owning authored transaction"));type_check(a[0],String,_T("mesh payload"));type_check(a[3],String,_T("mesh name"));const std::filesystem::path path(a[0]->to_string());if(!path.is_absolute()||std::filesystem::is_symlink(path))throw RuntimeError(_T("Mesh payload requires an absolute regular path"));
    const auto expected=recipeUTF8(a[1],64);const double metres=a[2]->to_double();if(!std::isfinite(metres)||metres<=0||metres>1e12)throw RuntimeError(_T("Invalid destination units"));std::ifstream in(path,std::ios::binary|std::ios::ate);if(!in)throw RuntimeError(_T("Mesh payload is missing"));const auto length=in.tellg();if(length<0||static_cast<std::uint64_t>(length)>cyrus::assets::maxLegacyMeshBytes)throw RuntimeError(_T("Legacy mesh payload exceeds admission"));std::vector<unsigned char> bytes(static_cast<std::size_t>(length));in.seekg(0);if(length>0)in.read(reinterpret_cast<char*>(bytes.data()),length);if(!in||r::digest(bytes)!=expected)throw RuntimeError(_T("Mesh payload changed since review"));return createAssetMesh(cyrus::assets::decodeMesh(bytes),metres,a[3]->to_string());
});}
def_visible_primitive(cyrusAssetPreparedMeshCreate,"cyrusAssetPreparedMeshCreate");
Value* cyrusAssetPreparedMeshCreate_cf(Value** a,int n){check_arg_count(cyrusAssetPreparedMeshCreate,4,n);return recipeAPI([&]()->Value*{type_check(a[3],String,_T("mesh name"));const auto snapshot=packages().prepared(a[0]->to_int64());const auto id=recipeUTF8(a[1],80);const auto found=snapshot->meshes.find(id);if(found==snapshot->meshes.end())throw RuntimeError(_T("Mesh is absent from the prepared package"));return createAssetMesh(*found->second,a[2]->to_double(),a[3]->to_string());});}
