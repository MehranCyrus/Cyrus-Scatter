// Host-thread, bounded inspection. No full mesh is retained merely to support a
// future display-mode switch. The signature includes only pivot-local geometry,
// so palette/material edits do not create a different geometric publication.
namespace {
constexpr std::size_t sourceInspectionFaceLimit=2000000;
constexpr int sourceInspectionCountLimit=512;
struct SourceGeometryInfo {
    int status=0; // 0 placeholder, 1 supported mesh, 2 unavailable/empty geometry
    ULONG handle=0;
    std::uint64_t fingerprint=1469598103934665603ULL;
    Box3 bounds;
    bool autoSupported=false;
    std::size_t faces=0;
    const MCHAR* reason=_T("");
    Interval validity=FOREVER;
    SourceGeometryInfo() { bounds.Init(); }
};
// Explicit initial capability: native mesh/poly and built-in mesh primitives.
// A third-party object being convertible does not qualify its render geometry.
bool sourceSupportsAuto(INode* node) {
    auto* object=node?node->GetObjectRef():nullptr;
    auto* base=object?object->FindBaseObject():nullptr;if(!base)return false;
    const auto id=base->ClassID();
    for(const auto allowed:{Class_ID(TRIOBJ_CLASS_ID,0),Class_ID(EDITTRIOBJ_CLASS_ID,0),
        Class_ID(POLYOBJ_CLASS_ID,0),EPOLYOBJ_CLASS_ID,Class_ID(BOXOBJ_CLASS_ID,0),
        Class_ID(SPHERE_CLASS_ID,0),Class_ID(CYLINDER_CLASS_ID,0),PLANE_CLASS_ID,
        GSPHERE_CLASS_ID,Class_ID(CONE_CLASS_ID,0),CAPSULE_CLASS_ID})if(id==allowed)return true;
    return false;
}
SourceGeometryInfo extractSourceGeometry(INode* node,TimeValue time,std::size_t allowance) {
    SourceGeometryInfo result;
    result.handle=node->GetHandle();result.status=2;
    result.autoSupported=sourceSupportsAuto(node);
    result.reason=_T("No face-referenced mesh is available");
    const auto state=node->EvalWorldState(time);auto* object=state.obj;result.validity&=state.Validity(time);
    const auto nodeTM=node->GetNodeTM(time,&result.validity),objectTM=node->GetObjectTM(time,&result.validity);
    const auto a=nodeTM.GetRow(0),b=nodeTM.GetRow(1),c=nodeTM.GetRow(2);
    const double det=double(a.x)*(double(b.y)*c.z-double(b.z)*c.y)-double(a.y)*(double(b.x)*c.z-double(b.z)*c.x)+double(a.z)*(double(b.x)*c.y-double(b.y)*c.x);
    if(!std::isfinite(det)||det==0){result.reason=_T("Source node transform is singular or non-finite");return result;}
    if(!object||!object->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))return result;
    auto* tri=static_cast<TriObject*>(object->ConvertToType(time,Class_ID(TRIOBJ_CLASS_ID,0)));
    if(!tri)return result;
    auto cleanup=[object](TriObject* p){if(p!=object)p->DeleteThis();};
    std::unique_ptr<TriObject,decltype(cleanup)> owned(tri,cleanup);
    auto& mesh=tri->GetMesh();const auto count=mesh.getNumFaces();
    if(count<=0)return result;
    if(std::size_t(count)>allowance)
        throw RuntimeError(_T("Source geometry inspection exceeds 2,000,000 faces across this population. Simplify the sources."));
    result.faces=count;result.status=1;
    result.reason=result.autoSupported?_T(""):_T("Auto is not qualified for this source type; use Manual radius");
    const auto transform=objectTM*Inverse(nodeTM);
    const auto hash=[&](const void* value,std::size_t size) {
        const auto* bytes=static_cast<const unsigned char*>(value);
        for(std::size_t i=0;i<size;++i){result.fingerprint^=bytes[i];result.fingerprint*=1099511628211ULL;}
    };
    hash(&count,sizeof(count));
    for(int f=0;f<count;++f)for(int corner=0;corner<3;++corner) {
        const auto vertex=mesh.faces[f].v[corner];
        if(vertex>=unsigned(mesh.getNumVerts()))throw RuntimeError(_T("Source geometry contains an invalid face vertex"));
        auto point=mesh.verts[vertex]*transform;
        for(int axis=0;axis<3;++axis) {
            if(!std::isfinite(point[axis]))throw RuntimeError(_T("Source geometry contains non-finite pivot-local coordinates"));
            if(point[axis]==0)point[axis]=0; // canonicalize negative zero
        }
        result.bounds+=point;hash(&point,sizeof(point));
    }
    return result;
}
// Small, process-bounded metadata cache. Weak SDK references invalidate
// synchronously on geometry/topology/transform changes and do not own scenes.
// The host validity interval handles animation even without a change message.
struct SourceGeometryWatch : MaxSDK::SingleWeakRefMaker {
    SourceGeometryInfo info;
    bool valid=false;
    std::uint64_t revision=0,lastUse=0;
    explicit SourceGeometryWatch(INode* node):SingleWeakRefMaker(node){}
    RefResult NotifyRefChanged(const Interval& interval,RefTargetHandle target,PartID& part,RefMessage message,BOOL propagate) override {
        if(message==REFMSG_TARGET_DELETED||(message==REFMSG_CHANGE&&(part&(PART_GEOM|PART_TOPO|PART_TM|PART_TM_CHAN|PART_OBJECT_TYPE)))){valid=false;++revision;}
        return SingleWeakRefMaker::NotifyRefChanged(interval,target,part,message,propagate);
    }
};
std::vector<std::unique_ptr<SourceGeometryWatch>> sourceGeometryCache;
std::uint64_t sourceGeometryQueries=0,sourceGeometryExtractions=0,sourceGeometryHits=0;
SourceGeometryInfo inspectSourceGeometry(Value* value,TimeValue time,std::size_t& faces) {
    if(cyrus::rows::integer(value))return {};
    auto* node=value->to_node();if(!node)throw RuntimeError(_T("A published source is missing. Use Update to publish the current source list."));
    ++sourceGeometryQueries;
    sourceGeometryCache.erase(std::remove_if(sourceGeometryCache.begin(),sourceGeometryCache.end(),[](const auto& p){return !p->GetRef();}),sourceGeometryCache.end());
    SourceGeometryWatch* watch=nullptr;
    for(auto& entry:sourceGeometryCache)if(entry->GetRef()==node){watch=entry.get();break;}
    if(!watch){
        if(sourceGeometryCache.size()==sourceInspectionCountLimit){
            const auto oldest=std::min_element(sourceGeometryCache.begin(),sourceGeometryCache.end(),[](const auto& a,const auto& b){return a->lastUse<b->lastUse;});sourceGeometryCache.erase(oldest);
        }
        sourceGeometryCache.push_back(std::make_unique<SourceGeometryWatch>(node));watch=sourceGeometryCache.back().get();
    }
    watch->lastUse=sourceGeometryQueries;
    if(watch->valid&&watch->info.validity.InInterval(time))++sourceGeometryHits;
    else {
        const auto revision=watch->revision;++sourceGeometryExtractions;
        const auto next=extractSourceGeometry(node,time,sourceInspectionFaceLimit-faces);
        watch->info=next;watch->valid=revision==watch->revision;
    }
    if(watch->info.faces>sourceInspectionFaceLimit-faces)throw RuntimeError(_T("Source geometry inspection exceeds 2,000,000 faces across this population. Simplify the sources."));
    faces+=watch->info.faces;return watch->info;
}
}

// Each entry: status, node handle, signature, minimum, maximum, Auto capability,
// explanation. Placeholders explicitly indicate uninspected/unneeded geometry.
// Face-referenced bounds exclude orphan vertices. This is a content check, not
// a promise that every renderer proxy exposes its final render geometry.
def_visible_primitive(cyrusSourceGeometryInfo,"cyrusSourceGeometryInfo");
Value* cyrusSourceGeometryInfo_cf(Value** args,int count) {
    check_arg_count(cyrusSourceGeometryInfo,1,count);
    type_check(args[0],Array,_T("source geometry inputs"));auto* sources=static_cast<Array*>(args[0]);
    if(sources->size>sourceInspectionCountLimit)throw RuntimeError(_T("Source inspection supports at most 512 entries per population"));
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(sources->size);
    std::size_t faces=0;const auto time=GetCOREInterface()->GetTime();
    for(int i=0;i<sources->size;++i) {
        const auto info=inspectSourceGeometry(sources->data[i],time,faces);
        vl.row=new Array(7);vl.result->append(vl.row);
        vl.row->append(Integer::intern(info.status));vl.row->append(Integer64::intern(info.handle));
        vl.row->append(new String(std::to_wstring(info.fingerprint).c_str()));
        vl.row->append(new Point3Value(info.status==1?info.bounds.Min():Point3(0,0,0)));
        vl.row->append(new Point3Value(info.status==1?info.bounds.Max():Point3(0,0,0)));
        vl.row->append(info.autoSupported?&true_value:&false_value);
        vl.row->append(new String(info.reason));
    }
    return_value(vl.result);
}

def_visible_primitive(cyrusSourceSupportsAuto,"cyrusSourceSupportsAuto");
Value* cyrusSourceSupportsAuto_cf(Value** args,int count){
    check_arg_count(cyrusSourceSupportsAuto,1,count);
    return sourceSupportsAuto(args[0]->to_node())?&true_value:&false_value;
}
def_visible_primitive(cyrusSourceGeometryStats,"cyrusSourceGeometryStats");
Value* cyrusSourceGeometryStats_cf(Value**,int count){
    check_arg_count(cyrusSourceGeometryStats,0,count);one_typed_value_local(Array* result);vl.result=new Array(4);
    for(auto value:{sourceGeometryQueries,sourceGeometryExtractions,sourceGeometryHits,std::uint64_t(sourceGeometryCache.size())})vl.result->append(Integer64::intern(value));
    return_value(vl.result);
}
