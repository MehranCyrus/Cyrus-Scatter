// Host-thread preparation, immutable numeric snapshots, copied row application.
namespace {
cyrus::orientation::Settings orientationSettings(Value* value){
    auto* a=groupArray(value);if(a->size!=5)throw RuntimeError(_T("Orientation requires five settings"));
    if(!cyrus::rows::integer(a->data[0])||(a->data[1]!=&true_value&&a->data[1]!=&false_value))throw RuntimeError(_T("Invalid orientation mode/alignment"));
    cyrus::orientation::Settings s;s.mode=static_cast<cyrus::orientation::Mode>(a->data[0]->to_int()-1);
    s.align=a->data[1]==&true_value;s.normalBlend=a->data[2]->to_double();s.direction=vec(a->data[3]->to_point3());s.target=vec(a->data[4]->to_point3());
    cyrus::orientation::validate(s);return s;
}
}
def_visible_primitive(cyrusOrientationVersion,"cyrusOrientationVersion");
Value* cyrusOrientationVersion_cf(Value**,int n){check_arg_count(cyrusOrientationVersion,0,n);return Integer::intern(1);}
def_visible_primitive(cyrusOrientationKey,"cyrusOrientationKey");
Value* cyrusOrientationKey_cf(Value** a,int n){
    check_arg_count(cyrusOrientationKey,2,n);
    try{
        const auto s=orientationSettings(a[0]);auto* axes=groupArray(a[1]);
        if(axes->size>65536)throw RuntimeError(_T("Orientation source bounds exceeded"));
        std::wostringstream key;key.imbue(std::locale::classic());key<<L"Orientation1:"<<static_cast<int>(s.mode)<<L':'<<s.align<<std::hexfloat;
        for(double value:{s.normalBlend,s.direction.x,s.direction.y,s.direction.z,s.target.x,s.target.y,s.target.z})key<<L':'<<(value==0?0.:value);
        for(int i=0;i<axes->size;++i){if(!cyrus::rows::integer(axes->data[i]))throw RuntimeError(_T("Invalid orientation source axis"));const int axis=axes->data[i]->to_int();if(axis<1||axis>4)throw RuntimeError(_T("Invalid orientation source axis"));key<<L':'<<axis;}
        return new String(key.str().c_str());
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
def_visible_primitive(cyrusValidateOrientation,"cyrusValidateOrientation");
Value* cyrusValidateOrientation_cf(Value** a,int n){
    check_arg_count(cyrusValidateOrientation,1,n);
    try{orientationSettings(a[0]);return &ok;}catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
def_visible_primitive(cyrusOrientSurfaceRows,"cyrusOrientSurfaceRows");
Value* cyrusOrientSurfaceRows_cf(Value** a,int n){
    check_arg_count(cyrusOrientSurfaceRows,4,n);auto* rows=groupArray(a[0]);auto* forward=groupArray(a[3]);
    if(rows->size>1000000||forward->size>65536)throw RuntimeError(_T("Orientation row/source bounds exceeded"));
    auto* receivers=groupArray(a[1]);if(receivers->size>128)throw RuntimeError(_T("Orientation receiver limit exceeded"));
    struct Snapshot {const std::vector<amin::Vec3>* normals=nullptr;std::size_t begin=0;};
    std::array<Snapshot,128> snapshots{};std::size_t faceOffset=0;
    for(int i=0;i<receivers->size;++i){
        auto* entry=groupArray(receivers->data[i]);if(entry->size!=3||!cyrus::rows::integer(entry->data[0])||!cyrus::rows::integer(entry->data[1]))throw RuntimeError(_T("Orientation receiver needs slot, face offset and snapshot"));
        const int slot=entry->data[0]->to_int(),offset=entry->data[1]->to_int();
        if(slot<1||slot>128||offset<0||snapshots[slot-1].normals)throw RuntimeError(_T("Invalid orientation receiver slot or face offset"));
        type_check(entry->data[2],CyrusOrientationNormals,_T("orientation normal snapshot"));
        const auto& values=static_cast<CyrusOrientationNormals*>(entry->data[2])->values;
        faceOffset+=values.size();if(faceOffset>cyrus::orientation::maxFaces)throw RuntimeError(_T("Orientation surface exceeds ten million faces"));
        snapshots[slot-1]={&values,static_cast<std::size_t>(offset)};
    }
    std::vector<amin::Instance> output;
    try{
        auto settings=orientationSettings(a[2]);std::vector<int> axes;axes.reserve(forward->size);
        for(int i=0;i<forward->size;++i){if(!cyrus::rows::integer(forward->data[i]))throw RuntimeError(_T("Invalid orientation source axis"));axes.push_back(forward->data[i]->to_int());}
        for(int axis:axes)if(axis<1||axis>4)throw RuntimeError(_T("Invalid orientation source axis"));
        output.reserve(rows->size);
        for(int i=0;i<rows->size;++i){
            auto row=placementInstance(groupArray(rows->data[i]));unsigned slot=0;std::uint64_t localKey=0;
            if(!cyrus::receivers::decodeCandidate(row.candidateKey,slot,localKey)||slot>=snapshots.size())throw RuntimeError(_T("Orientation candidate has no valid receiver"));
            const auto& snapshot=snapshots[slot];
            if(!snapshot.normals||row.triangle<snapshot.begin||row.triangle-snapshot.begin>=snapshot.normals->size())throw RuntimeError(_T("Orientation face belongs to another receiver"));
            if(row.source>=axes.size())throw RuntimeError(_T("Orientation source axis is missing"));
            output.push_back(cyrus::orientation::orient(row,(*snapshot.normals)[row.triangle-snapshot.begin],settings,axes[row.source]));
        }
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(static_cast<int>(output.size()));
    for(const auto& p:output){
        vl.row=new Array(8);vl.result->append(vl.row);
        vl.row->append(new Matrix3Value(Matrix3(point(p.xAxis),point(p.yAxis),point(p.zAxis),point(p.position))));
        vl.row->append(Integer::intern(p.source+1));appendIdentity(vl.row,p);
    }
    ++orientationApplications;orientationAppliedRows+=output.size();return_value(vl.result);
}
def_visible_primitive(cyrusOrientationStats,"cyrusOrientationStats");
Value* cyrusOrientationStats_cf(Value**,int n){
    check_arg_count(cyrusOrientationStats,0,n);one_typed_value_local(Array* result);vl.result=new Array(5);
    vl.result->append(Integer64::intern(orientationSnapshotBuilds));vl.result->append(Integer64::intern(orientationApplications));vl.result->append(Integer64::intern(orientationAppliedRows));
    vl.result->append(Integer64::intern(orientationSnapshotBytes));vl.result->append(Integer64::intern(orientationSnapshotCount));return_value(vl.result);
}
