namespace {
struct GridOptions {bool enabled=false;cyrus::grid::Settings settings;};
GridOptions gridSettings(Value* value){
    auto* a=groupArray(value);if(a->size!=7||!cyrus::rows::integer(a->data[0]))throw RuntimeError(_T("Grid requires mode, spacing, origin, heading and jitter"));
    const int mode=a->data[0]->to_int();if(mode<1||mode>4)throw RuntimeError(_T("Unknown placement generator"));
    GridOptions out;if(mode==1)return out;out.enabled=true;auto& s=out.settings;
    s.mode=cyrus::grid::Mode(mode-1);s.columnSpacing=a->data[1]->to_double();s.rowSpacing=a->data[2]->to_double();
    s.originX=a->data[3]->to_double();s.originY=a->data[4]->to_double();s.headingDegrees=a->data[5]->to_double();s.jitter=a->data[6]->to_double()/100.;
    cyrus::grid::validate(s);return out;
}
}
def_visible_primitive(cyrusGridVersion,"cyrusGridVersion");
Value* cyrusGridVersion_cf(Value**,int n){check_arg_count(cyrusGridVersion,0,n);return Integer::intern(1);}
def_visible_primitive(cyrusGridKey,"cyrusGridKey");
Value* cyrusGridKey_cf(Value** a,int n){
    check_arg_count(cyrusGridKey,1,n);
    try{const auto option=gridSettings(a[0]);if(!option.enabled)return new String(L"SurfaceRandom1");
        const auto& s=option.settings;std::wostringstream key;key.imbue(std::locale::classic());key<<L"Grid1:"<<unsigned(s.mode)<<std::hexfloat;
        for(double v:{s.columnSpacing,s.mode==cyrus::grid::Mode::Hexagonal?0.:s.rowSpacing,s.originX,s.originY,s.headingDegrees,s.jitter})key<<L':'<<(v==0?0.:v);
        return new String(key.str().c_str());
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
def_visible_primitive(cyrusGridPrepare,"cyrusGridPrepare");
Value* cyrusGridPrepare_cf(Value** a,int n){
    check_arg_count(cyrusGridPrepare,7,n);
    try{auto option=gridSettings(a[1]);if(!option.enabled)throw RuntimeError(_T("Surface random needs no grid snapshot"));
        auto* node=a[0]->to_node();if(!node)throw RuntimeError(_T("Grid receiver is missing"));
        if(!cyrus::rows::integer(a[2])||!cyrus::rows::integer(a[5])||!cyrus::rows::integer(a[6])||(a[4]!=&true_value&&a[4]!=&false_value))throw RuntimeError(_T("Invalid grid preparation options"));
        const int seed=a[2]->to_int(),channel=a[5]->to_int(),remaining=a[6]->to_int();
        if(seed<0||channel<1||channel>=MAX_MESHMAPS||remaining<0||remaining>1000000)throw RuntimeError(_T("Grid preparation bounds exceeded"));
        auto& s=option.settings;s.seed=unsigned(seed);s.receiverSalt=cyrus::receivers::salt(proceduralID(a[3]));const bool uv=a[4]==&true_value;
        cyrus::grid::Limits limits;limits.cells=unsigned(remaining);
        auto mesh=meshOf(node,true,uv,limits.triangles,channel);
        const auto bytes=mesh.capacity()*sizeof(amin::Triangle);if(bytes>=limits.bytes)throw RuntimeError(_T("Grid receiver memory limit exceeded"));limits.bytes-=bytes;
        amin::diagnostics::StageTimer measurement(amin::diagnostics::Stage::Candidates);
        auto projection=cyrus::grid::generate(mesh,s,limits);
        return new CyrusGridSnapshot(std::move(mesh),std::move(projection),node->GetHandle(),channel,uv,s.seed,s.receiverSalt);
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
def_visible_primitive(cyrusGridPlan,"cyrusGridPlan");
Value* cyrusGridPlan_cf(Value** a,int n){
    check_arg_count(cyrusGridPlan,1,n);auto* entries=groupArray(a[0]);if(entries->size>128)throw RuntimeError(_T("Grid receiver limit exceeded"));
    std::map<unsigned,const CyrusGridSnapshot*> snapshots;std::uint64_t cells=0,hits=0;
    for(int i=0;i<entries->size;++i){auto* entry=groupArray(entries->data[i]);if(entry->size!=2||!cyrus::rows::integer(entry->data[0]))throw RuntimeError(_T("Invalid grid receiver plan"));
        const int slot=entry->data[0]->to_int();type_check(entry->data[1],CyrusGridSnapshot,_T("grid receiver snapshot"));const auto* snapshot=static_cast<CyrusGridSnapshot*>(entry->data[1]);
        if(slot<1||slot>128||!snapshots.emplace(unsigned(slot-1),snapshot).second)throw RuntimeError(_T("Duplicate or invalid grid receiver slot"));
        cells+=snapshot->projection.enumeratedCells;hits+=snapshot->projection.anchors.size();if(cells>1000000)throw RuntimeError(_T("Grid exceeds the shared candidate limit"));
    }
    four_typed_value_locals(Array* result,Array* rows,Array* row,Array* order);vl.result=new Array(6);vl.rows=new Array(entries->size);vl.result->append(vl.rows);
    vl.order=new Array(int(hits));vl.result->append(vl.order);
    for(const auto& entry:snapshots){const auto& anchors=entry.second->projection.anchors;vl.row=new Array(4);vl.rows->append(vl.row);vl.row->append(Integer::intern(entry.first+1));
        for(int i=0;i<3;++i)vl.row->append(Integer::intern(int(anchors.size())));
        for(const auto& anchor:anchors)vl.order->append(Integer64::intern(cyrus::receivers::candidateIdentity(entry.first,anchor.key)));
    }
    vl.result->append(Integer::intern(int(hits)));vl.result->append(Integer::intern(int(hits)));vl.result->append(&false_value);vl.result->append(Integer::intern(int(cells)));return_value(vl.result);
}
def_visible_primitive(cyrusGridSnapshotInfo,"cyrusGridSnapshotInfo");
Value* cyrusGridSnapshotInfo_cf(Value** a,int n){check_arg_count(cyrusGridSnapshotInfo,1,n);type_check(a[0],CyrusGridSnapshot,_T("grid receiver snapshot"));const auto* snapshot=static_cast<CyrusGridSnapshot*>(a[0]);
    one_typed_value_local(Array* result);vl.result=new Array(4);for(auto value:{snapshot->projection.enumeratedCells,std::uint64_t(snapshot->projection.anchors.size()),std::uint64_t(snapshot->mesh.size()),snapshot->projection.projectionVisits})vl.result->append(Integer64::intern(value));return_value(vl.result);
}
def_visible_primitive(cyrusGridStats,"cyrusGridStats");
Value* cyrusGridStats_cf(Value**,int n){check_arg_count(cyrusGridStats,0,n);one_typed_value_local(Array* result);vl.result=new Array(5);for(auto v:{gridBuilds,gridCells,gridVisits,gridBytes,gridSnapshots})vl.result->append(Integer64::intern(v));return_value(vl.result);}
