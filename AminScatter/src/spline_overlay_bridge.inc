// Bounded host-thread extraction -> numeric overlay -> immutable line snapshot.
// This primitive changes no scene recipe, placement or display publication.
namespace {
std::uint64_t fieldDependencySerial=0,fieldDependencyQueries=0;
struct FieldDependencyWatch final:MaxSDK::SingleWeakRefMaker {
    std::uint64_t serial=++fieldDependencySerial,lastUse=0;
    Interval validity=NEVER;
    explicit FieldDependencyWatch(INode* node):SingleWeakRefMaker(node){}
    RefResult NotifyRefChanged(const Interval& interval,RefTargetHandle target,PartID& part,RefMessage message,BOOL propagate) override {
        if(message==REFMSG_TARGET_DELETED||(message==REFMSG_CHANGE&&(part&(PART_GEOM|PART_TOPO|PART_TM|PART_TM_CHAN|PART_OBJECT_TYPE)))){
            serial=++fieldDependencySerial;validity=NEVER;
        }
        return SingleWeakRefMaker::NotifyRefChanged(interval,target,part,message,propagate);
    }
};
// Metadata only. Weak references do not retain scenes or converted geometry.
// A key is a conservative dependency revision, not a content hash or proof
// that two independently prepared shapes are semantically different.
std::vector<std::unique_ptr<FieldDependencyWatch>> fieldDependencyWatches;
}
def_visible_primitive(cyrusFieldDependencyKey,"cyrusFieldDependencyKey");
Value* cyrusFieldDependencyKey_cf(Value** args,int count){
    check_arg_count(cyrusFieldDependencyKey,1,count);type_check(args[0],Array,_T("field dependencies"));
    auto* nodes=static_cast<Array*>(args[0]);if(nodes->size>544)throw RuntimeError(_T("Field dependencies exceed 512 receivers and 32 Paths"));
    fieldDependencyWatches.erase(std::remove_if(fieldDependencyWatches.begin(),fieldDependencyWatches.end(),[](const auto& p){return !p->GetRef();}),fieldDependencyWatches.end());
    std::wstring key;const auto time=GetCOREInterface()->GetTime();
    for(int i=0;i<nodes->size;++i){auto* node=nodes->data[i]->to_node();if(!node)throw RuntimeError(_T("Missing field dependency"));
        FieldDependencyWatch* watch=nullptr;
        for(auto& entry:fieldDependencyWatches)if(entry->GetRef()==node){watch=entry.get();break;}
        if(!watch){
            if(fieldDependencyWatches.size()==1024){const auto oldest=std::min_element(fieldDependencyWatches.begin(),fieldDependencyWatches.end(),[](const auto& a,const auto& b){return a->lastUse<b->lastUse;});fieldDependencyWatches.erase(oldest);}
            fieldDependencyWatches.push_back(std::make_unique<FieldDependencyWatch>(node));watch=fieldDependencyWatches.back().get();
        }
        watch->lastUse=++fieldDependencyQueries;
        if(!watch->validity.InInterval(time)){
            const auto revision=watch->serial;const auto state=node->EvalWorldState(time);Interval validity=state.Validity(time);
            node->GetObjectTM(time,&validity);const bool stable=watch->serial==revision;
            watch->serial=++fieldDependencySerial;watch->validity=stable?validity:NEVER;
        }
        key+=std::to_wstring(node->GetHandle())+L":"+std::to_wstring(watch->serial)+L";";
    }
    return new String(key.c_str());
}
def_visible_primitive(cyrusBuildFieldPreview,"cyrusBuildFieldPreview");
Value* cyrusBuildFieldPreview_cf(Value** args,int count){
    check_arg_count(cyrusBuildFieldPreview,3,count);
    const auto& field=cyrusPreparedSplineField(args[0]);
    type_check(args[1],Array,_T("field receivers"));type_check(args[2],Array,_T("field display settings"));
    auto* nodes=static_cast<Array*>(args[1]);auto* settings=static_cast<Array*>(args[2]);
    if(nodes->size>512||settings->size!=5)throw RuntimeError(_T("Field preview expects at most 512 receivers and five display settings"));
    if(!cyrus::rows::integer(settings->data[0])||settings->data[0]->to_int64()<0)
        throw RuntimeError(_T("Field selection must be a nonnegative Band identity; zero means combined"));
    for(int i:{1,2})if(settings->data[i]!=&true_value&&settings->data[i]!=&false_value)
        throw RuntimeError(_T("Field display toggles must be Boolean"));
    if(!cyrus::rows::integer(settings->data[3])||settings->data[3]->to_int64()<1||settings->data[3]->to_int64()>20000)
        throw RuntimeError(_T("Field sample limit must be an integer in 1..20,000"));
    const double displayOffset=settings->data[4]->to_float();
    if(!std::isfinite(displayOffset)||displayOffset<0)throw RuntimeError(_T("Field display offset must be finite and nonnegative"));
    cyrus::bands::OverlayOptions options;options.band=settings->data[0]->to_int64();
    options.falloff=settings->data[1]==&true_value;options.boundaries=settings->data[2]==&true_value;options.samples=settings->data[3]->to_int();
    try {
        const cyrus::bands::OverlayLimits limits;
        // Admission precedes copied input allocation. Reserve the maximum
        // admitted face count so no conversion is repeated just to count faces.
        // Host/vendor conversion allocations are outside owned payload bounds.
        const auto bytes=cyrus::bands::overlayPreparationBytes(limits.faces,options,limits);
        auto staging=cyrus::reservePreviewMemory(cyrus::pointPreviewBudget,bytes);
        std::vector<cyrus::bands::ReceiverTriangle> triangles;triangles.reserve(limits.faces);
        std::vector<INode*> seen;seen.reserve(nodes->size);const auto time=GetCOREInterface()->GetTime();
        for(int i=0;i<nodes->size;++i){auto* node=nodes->data[i]->to_node();
            if(!node||std::find(seen.begin(),seen.end(),node)!=seen.end())throw RuntimeError(_T("Field receivers must be unique valid nodes"));
            seen.push_back(node);auto* object=node->EvalWorldState(time).obj;
            if(!object||!object->CanConvertToType(Class_ID(TRIOBJ_CLASS_ID,0)))throw RuntimeError(_T("Field receiver cannot provide a triangle mesh"));
            auto* tri=static_cast<TriObject*>(object->ConvertToType(time,Class_ID(TRIOBJ_CLASS_ID,0)));
            if(!tri)throw RuntimeError(_T("Field receiver mesh conversion failed"));
            auto cleanup=[object](TriObject* p){if(p!=object)p->DeleteThis();};std::unique_ptr<TriObject,decltype(cleanup)> owned(tri,cleanup);
            auto& mesh=tri->GetMesh();const auto faces=mesh.getNumFaces();
            if(faces<0||std::size_t(faces)>limits.faces-triangles.size())throw RuntimeError(_T("Field preview exceeds 200,000 receiver faces; simplify receivers"));
            const auto tm=node->GetObjectTM(time);const auto x=tm.GetRow(0),y=tm.GetRow(1),z=tm.GetRow(2),translation=tm.GetTrans();
            const auto world=[&](Point3 p)->amin::Vec3{return {double(p.x)*x.x+double(p.y)*y.x+double(p.z)*z.x+translation.x,
                double(p.x)*x.y+double(p.y)*y.y+double(p.z)*z.y+translation.y,double(p.x)*x.z+double(p.y)*y.z+double(p.z)*z.z+translation.z};};
            for(int f=0;f<faces;++f){std::array<amin::Vec3,3> points;
                for(int k=0;k<3;++k){const auto v=mesh.faces[f].v[k];if(v>=unsigned(mesh.getNumVerts()))throw RuntimeError(_T("Field receiver contains an invalid face vertex"));points[k]=world(mesh.verts[v]);}
                triangles.push_back({points[0],points[1],points[2],node->GetHandle(),std::uint32_t(f)});
            }
        }
        const auto overlay=cyrus::bands::buildOverlay(field,triangles,options,limits);
        const auto point=[&](amin::Vec3 p){Point3 result(float(p.x),float(p.y),float(p.z));
            if(!std::isfinite(result.x)||!std::isfinite(result.y)||!std::isfinite(result.z))throw RuntimeError(_T("Field display position exceeds viewport precision"));return result;};
        std::array<std::size_t,34> sizes{};for(const auto& line:overlay.lines)sizes[line.color]+=2;
        std::vector<cyrus::PointGroup> groups;groups.reserve(sizes.size());
        auto conversion=cyrus::reservePreviewMemory(cyrus::pointPreviewBudget,overlay.lines.size()*2*(sizeof(Point3)+1)+sizes.size()*256+4096);
        for(std::size_t i=0;i<sizes.size();++i){groups.push_back({point(cyrus::bands::overlayColor(std::uint8_t(i))),{}});
            groups.back().points.reserve(sizes[i]);groups.back().bandSlots.reserve(sizes[i]);}
        for(const auto& line:overlay.lines){auto& group=groups[line.color];const auto shift=line.normal*displayOffset;
            group.points.push_back(point(line.a+shift));group.points.push_back(point(line.b+shift));group.bandSlots.push_back(0);group.bandSlots.push_back(0);}
        auto details=std::make_shared<FieldPreviewDetails>();details->stats=overlay.stats;details->sampleCount=overlay.samples.size();details->lineCount=overlay.lines.size();details->reservedBytes=bytes;
        const auto witnesses=std::min<std::size_t>(1000,overlay.samples.size());
        details->memory=cyrus::reservePreviewMemory(cyrus::pointPreviewBudget,sizeof(FieldPreviewDetails)+witnesses*sizeof(cyrus::bands::OverlaySample));
        details->samples.reserve(witnesses);
        for(std::size_t i=0;i<witnesses;++i)details->samples.push_back(overlay.samples[i*overlay.samples.size()/witnesses]);
        auto snapshot=std::make_shared<cyrus::PointSnapshot>(std::move(groups),true);
        auto result=std::make_unique<AminPointCache>();result->pointSnapshot=std::move(snapshot);result->fieldDetails=std::move(details);
        // This count is explicitly display samples, never accepted plants.
        result->size=int(overlay.samples.size());return result.release();
    }catch(const std::exception& error){const std::string message=error.what();throw RuntimeError(MSTR(std::wstring(message.begin(),message.end()).c_str()));}
}

// Version 1: samples, lines, boundary lines, faces, degenerate faces, receivers,
// sampled receivers/faces, work, peak admitted preparation, numeric output bytes,
// contour error/segments, then up to 1,000 diagnostic witnesses. No mesh query.
def_visible_primitive(cyrusFieldPreviewInfo,"cyrusFieldPreviewInfo");
Value* cyrusFieldPreviewInfo_cf(Value** args,int count){
    check_arg_count(cyrusFieldPreviewInfo,2,count);type_check(args[0],AminPointCache,_T("field preview cache"));
    const auto& details=static_cast<AminPointCache*>(args[0])->fieldDetails;
    const int limit=args[1]->to_int();if(!details||limit<0||limit>1000)throw RuntimeError(_T("Expected a field preview and diagnostic limit 0..1,000"));
    const auto& s=details->stats;
    three_typed_value_locals(Array* result,Array* samples,Array* row);
    vl.result=new Array(15);vl.result->append(Integer::intern(1));
    for(auto value:{details->sampleCount,details->lineCount,s.boundaryLines,s.faces,s.degenerate,s.receivers,s.sampledReceivers,s.sampledFaces,s.work,details->reservedBytes,s.retainedBytes})
        vl.result->append(Integer64::intern(value));
    vl.result->append(Float::intern(float(s.outlines.error)));vl.result->append(Integer64::intern(s.outlines.segments));
    vl.samples=new Array(std::min(std::size_t(limit),details->samples.size()));vl.result->append(vl.samples);
    for(std::size_t i=0;i<std::min(std::size_t(limit),details->samples.size());++i){const auto& sample=details->samples[i];
        vl.row=new Array(6);vl.samples->append(vl.row);
        for(auto p:{sample.position,sample.bary})vl.row->append(new Point3Value(Point3(float(p.x),float(p.y),float(p.z))));
        vl.row->append(Integer64::intern(sample.receiver));vl.row->append(Integer::intern(sample.face+1));
        vl.row->append(Float::intern(float(sample.value)));vl.row->append(Float::intern(float(sample.error)));
    }
    return_value(vl.result);
}
