namespace {
Array* groupArray(Value* v){type_check(v,Array,_T("planting array"));return static_cast<Array*>(v);}
std::vector<amin::Vec3> groupPositions(Array* rows){
    std::vector<amin::Vec3> out;out.reserve(rows->size);
    for(int i=0;i<rows->size;++i){auto* r=groupArray(rows->data[i]);if(r->size<2)throw RuntimeError(_T("Invalid planting row"));auto p=r->data[0]->to_matrix3().GetTrans();out.push_back({p.x,p.y,p.z});}return out;
}
std::vector<double> groupRadii(Value* value){auto* a=groupArray(value);std::vector<double> out;out.reserve(a->size);for(int i=0;i<a->size;++i)out.push_back(a->data[i]->to_float());return out;}
bool groupProtected(Value* value){auto* row=groupArray(value);return row->size==4&&row->data[3]==&true_value;}
}
def_visible_primitive(cyrusResolveGroup,"cyrusResolveGroup");
Value* cyrusResolveGroup_cf(Value** a,int n){
    check_arg_count(cyrusResolveGroup,3,n);
    auto* rows=groupArray(a[0]);auto* rules=groupArray(a[2]);
    auto positions=groupPositions(rows);std::vector<bool> protect;protect.reserve(rows->size);
    for(int i=0;i<rows->size;++i)protect.push_back(groupProtected(rows->data[i]));
    std::vector<cyrus::groups::Rule> inputs;
    for(int i=0;i<rules->size;++i){auto* rule=groupArray(rules->data[i]);if(rule->size!=5)throw RuntimeError(_T("Expected blocker rows, gap, planar, own radii, blocker radii"));
        inputs.push_back({groupPositions(groupArray(rule->data[0])),groupRadii(rule->data[3]),groupRadii(rule->data[4]),rule->data[1]->to_float(),rule->data[2]->to_bool()!=FALSE});
    }
    cyrus::groups::Result selected;
    try{selected=cyrus::groups::resolve(positions,a[1]->to_float(),inputs,protect);}
    catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
    two_typed_value_locals(Array* result,Array* kept);
    vl.result=new Array(2);vl.kept=new Array(int(selected.kept.size()));vl.result->append(vl.kept);
    for(auto i:selected.kept)vl.kept->append(rows->data[i]);
    vl.result->append(Integer::intern(int(selected.conflicts.size())));return_value(vl.result);
}
// Removal-only cleanup returns original rows, including string Edit identities
// and protected metadata. It neither reprojects nor reconstructs transforms.
def_visible_primitive(cyrusCleanupGroup,"cyrusCleanupGroup");
Value* cyrusCleanupGroup_cf(Value** a,int n){
    check_arg_count(cyrusCleanupGroup,5,n);auto* rows=groupArray(a[0]);auto positions=groupPositions(rows);
    amin::FinalSettings f;f.cleanup=true;f.relax=false;f.radius=a[1]->to_float();f.planar=a[4]->to_bool()!=FALSE;
    const int neighbors=a[2]->to_int(),island=a[3]->to_int();if(neighbors<0||island<0)throw RuntimeError(_T("Invalid cleanup thresholds"));
    f.minNeighbors=unsigned(neighbors);f.minIsland=unsigned(island);
    std::vector<amin::Instance> input;for(std::size_t i=0;i<positions.size();++i){amin::Instance p{};p.position=positions[i];p.candidateKey=i;input.push_back(p);}
    std::vector<amin::Instance> output;
    try{output=amin::finalize({},amin::Settings{},input,{},std::vector<double>(input.size(),0),{},f);}
    catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
    std::vector<bool> keep(rows->size,false);for(const auto& p:output)keep[p.candidateKey]=true;
    one_typed_value_local(Array* result);vl.result=new Array(rows->size);
    for(int i=0;i<rows->size;++i)if(keep[i]||groupProtected(rows->data[i]))vl.result->append(rows->data[i]);
    return_value(vl.result);
}
