struct EditInput { Matrix3 tm;int source;std::wstring id; };
static std::wstring legacyTopology(const EditLayer& l) {
    std::uint64_t h=1469598103934665603ULL;
    for(unsigned i=0;i<l.rows.size();++i)if(!l.rows[i].deleted){h=(h^i)*1099511628211ULL;h=(h^l.rows[i].source)*1099511628211ULL;}
    return std::to_wstring(h);
}
static std::vector<EditInput> applyStable(CSEdit* m,int key,const std::vector<EditInput>& input,
    const std::wstring& signature,const std::wstring& legacySignature,unsigned baseCount) {
    auto& l=m->layers[key];l.active=true;l.pending=false;
    if(l.legacy) {
        // Recover old invalid flags only when the original index mapping is provable.
        // A modifier originally bound directly to the base has unambiguous base IDs,
        // even if a lower modifier is now enabled and supplies additional copies.
        const bool baseBinding=l.signature==signature;
        const bool sameBinding=l.signature==legacySignature;
        if(!baseBinding&&!sameBinding) {
            l.pending=true;l.invalid=true;l.input.clear();m->status();return input;
        }
        std::unordered_set<unsigned> seen;
        for(auto& r:l.rows) {
            if(r.source>=(baseBinding?baseCount:unsigned(input.size()))) {
                l.pending=true;l.invalid=true;l.input.clear();m->status();return input;
            }
        }
        for(auto& r:l.rows) {
            r.inputId=baseBinding?L"b:"+std::to_wstring(r.source):input[r.source].id;
            r.outputId=seen.insert(r.source).second?r.inputId:pointId();
        }
        l.signature=signature;l.legacy=false;l.invalid=false;
    }
    if(l.signature.empty())l.signature=signature;
    if(l.signature!=signature)l.invalid=true; // Real base generation changes still require Reset.
    l.input.clear();l.sources.clear();
    std::unordered_map<std::wstring,unsigned> incoming;
    for(unsigned i=0;i<input.size();++i){incoming.emplace(input[i].id,i);l.input.push_back(input[i].tm);l.sources.push_back(input[i].source);}
    if(l.invalid){m->status();return input;}
    std::unordered_set<std::wstring> originals;
    for(auto& r:l.rows) {
        if(r.inputId==r.outputId)originals.insert(r.inputId);
        auto it=incoming.find(r.inputId);
        r.source=it==incoming.end()?std::numeric_limits<unsigned>::max():it->second;
    }
    for(unsigned i=0;i<input.size();++i)if(originals.insert(input[i].id).second) {
        EditRow r;r.source=i;r.inputId=r.outputId=input[i].id;l.rows.push_back(std::move(r));
    }
    std::vector<EditInput> output;output.reserve(l.rows.size());
    for(auto& r:l.rows)if(!r.deleted&&r.source<input.size())output.push_back({input[r.source].tm*r.delta,input[r.source].source,r.outputId});
    m->status();return output;
}
// Legacy rows retain index binding. Keyed rows use immutable candidate IDs and
// a full base-population signature, independent of current Brush membership.
def_visible_primitive(cyrusEditStack,"cyrusEditStack");
Value* cyrusEditStack_cf(Value** a,int count) {
    if(count!=4&&count!=5)throw RuntimeError(_T("Expected 4 or 5 CS Edit stack arguments"));
    const bool keyed=count==5&&a[4]->to_bool()!=FALSE;
    type_check(a[0],Array,_T("modifiers"));type_check(a[1],Array,_T("rows"));
    auto* mods=static_cast<Array*>(a[0]);auto* rows=static_cast<Array*>(a[1]);
    const int key=a[2]->to_int();const std::wstring signature=a[3]->to_string();
    std::vector<EditInput> input;input.reserve(rows->size);
    for(int i=0;i<rows->size;++i) {
        type_check(rows->data[i],Array,_T("instance row"));auto* row=static_cast<Array*>(rows->data[i]);
        if(row->size<2||(keyed&&row->size<3))throw RuntimeError(_T("Expected transform, source and candidate identity"));
        const auto id=keyed?L"c:"+std::to_wstring(row->data[2]->to_int64()):L"b:"+std::to_wstring(i);
        input.push_back({row->data[0]->to_matrix3(),row->data[1]->to_int(),id});
    }
    std::wstring legacy=signature;
    for(int i=mods->size-1;i>=0;--i) {
        auto* m=edit(mods->data[i]);
        // Capture the old topology before conversion remaps transient input indices.
        auto it=m->layers.find(key);
        std::wstring topology=it==m->layers.end()?L"pass":legacyTopology(it->second);
        input=applyStable(m,key,input,signature,legacy,unsigned(rows->size));
        legacy+=L"|"+std::to_wstring(mods->size-i)+L":"+topology;
    }
    two_typed_value_locals(Array* result,Array* row);
    vl.result=new Array(0);
    for(auto& r:input){vl.row=new Array(2);vl.row->append(new Matrix3Value(r.tm));vl.row->append(Integer::intern(r.source));if(keyed)vl.row->append(new String(r.id.c_str()));vl.result->append(vl.row);}
    return_value(vl.result);
}
