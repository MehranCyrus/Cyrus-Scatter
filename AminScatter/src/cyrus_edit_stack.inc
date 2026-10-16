struct EditInput { Matrix3 tm;int source;std::wstring id;bool protectedEdit=false;int face=0;Point3 bary{1,0,0};std::uint64_t owner=0; };
static bool hasEditTransform(const Matrix3& m){
    const Matrix3 identity(1);
    for(int i=0;i<4;++i)if(m.GetRow(i)!=identity.GetRow(i))return true;
    return false;
}
static std::vector<EditInput> applyStable(CSEdit* m,int key,const std::vector<EditInput>& input,
    const std::wstring& signature) {
    auto& l=m->layers[key];l.active=true;
    if(l.signature.empty())l.signature=signature;
    if(l.signature!=signature){
        // Only the receiver-aware format permits membership changes. Keep the
        // union of receipts so missing/re-added receivers retain their guards.
        try{l.signature=receiverWide(cyrus::receivers::mergeBinding(receiverUTF8(l.signature),receiverUTF8(signature)));}
        catch(const std::exception&){l.invalid=true;}
    }
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
    for(auto& r:l.rows)if(!r.deleted&&r.source<input.size()){
        auto next=input[r.source];next.tm=next.tm*r.delta;next.id=r.outputId;next.protectedEdit=next.protectedEdit||r.inputId!=r.outputId||hasEditTransform(r.delta);output.push_back(std::move(next));
    }
    m->status();return output;
}
// Candidate IDs and a base-population signature are independent of coverage.
def_visible_primitive(cyrusEditStack,"cyrusEditStack");
Value* cyrusEditStack_cf(Value** a,int count) {
    check_arg_count(cyrusEditStack,4,count);
    type_check(a[0],Array,_T("modifiers"));type_check(a[1],Array,_T("rows"));
    auto* mods=static_cast<Array*>(a[0]);auto* rows=static_cast<Array*>(a[1]);
    const int key=a[2]->to_int();const std::wstring signature=a[3]->to_string();
    std::vector<EditInput> input;input.reserve(rows->size);
    for(int i=0;i<rows->size;++i) {
        type_check(rows->data[i],Array,_T("instance row"));auto* row=static_cast<Array*>(rows->data[i]);
        cyrus::rows::raw(row);
        const auto id=L"c:"+std::to_wstring(row->data[2]->to_int64());
        EditInput entry{row->data[0]->to_matrix3(),row->data[1]->to_int(),id};
        entry.face=row->data[3]->to_int();entry.bary=row->data[4]->to_point3();entry.owner=cyrus::rows::owner(row);
        input.push_back(std::move(entry));
    }
    for(int i=mods->size-1;i>=0;--i) {
        auto* m=edit(mods->data[i]);
        input=applyStable(m,key,input,signature);
        if(m->layers[key].invalid)throw RuntimeError(_T("CS Edit base changed. Restore the generation settings or explicitly Reset Edits before updating this planting setup."));
    }
    two_typed_value_locals(Array* result,Array* row);
    vl.result=new Array(0);
    for(auto& r:input){
        vl.row=new Array(8);vl.result->append(vl.row);vl.row->append(new Matrix3Value(r.tm));vl.row->append(Integer::intern(r.source));
        vl.row->append(new String(r.id.c_str()));
        vl.row->append(Integer::intern(r.face));vl.row->append(new Point3Value(r.bary));vl.row->append(Integer64::intern(r.owner));
        vl.row->append(r.protectedEdit?&true_value:&false_value);vl.row->append(Integer::intern(2));
    }
    return_value(vl.result);
}

// Transient selection/display publication, separate from immutable Edit binding.
def_visible_primitive(cyrusEditPublish,"cyrusEditPublish");
Value* cyrusEditPublish_cf(Value** a,int count){
    check_arg_count(cyrusEditPublish,3,count);type_check(a[0],Array,_T("modifiers"));type_check(a[2],Array,_T("final rows"));
    auto* mods=static_cast<Array*>(a[0]);auto* rows=static_cast<Array*>(a[2]);const int key=a[1]->to_int();
    std::unordered_set<std::wstring> ids;
    for(int i=0;i<rows->size;++i){type_check(rows->data[i],Array,_T("final row"));auto* row=static_cast<Array*>(rows->data[i]);cyrus::rows::edited(row);ids.insert(row->data[2]->to_string());}
    for(int i=0;i<mods->size;++i){auto* m=edit(mods->data[i]);auto found=m->layers.find(key);if(found==m->layers.end())continue;auto& l=found->second;l.published=true;l.publishedIDs=ids;m->status();}
    return &ok;
}
def_visible_primitive(cyrusEditVisibleCount,"cyrusEditVisibleCount");
Value* cyrusEditVisibleCount_cf(Value** a,int count){check_arg_count(cyrusEditVisibleCount,1,count);return Integer64::intern(edit(a[0])->visible().size());}

def_visible_primitive(cyrusEditGroupVisibility,"cyrusEditGroupVisibility");
Value* cyrusEditGroupVisibility_cf(Value** a,int count){check_arg_count(cyrusEditGroupVisibility,3,count);auto* m=edit(a[0]);const auto found=m->layers.find(a[1]->to_int());if(found!=m->layers.end()){found->second.viewportVisible=a[2]->to_bool()!=FALSE;m->status();}return &ok;}

// A synchronous host transaction includes derived input bindings and published
// selection state. It never lives on a worker or across a yielded host event.
namespace {
struct ProceduralEditTransaction {std::vector<std::pair<CSEdit*,std::map<int,EditLayer>>> before;};
std::unique_ptr<ProceduralEditTransaction> proceduralEditTransaction;
}
def_visible_primitive(cyrusEditTransaction,"cyrusEditTransaction");
Value* cyrusEditTransaction_cf(Value** a,int count){
    check_arg_count(cyrusEditTransaction,2,count);type_check(a[0],Array,_T("Edit modifiers"));auto* mods=static_cast<Array*>(a[0]);const int command=a[1]->to_int();
    if(command==0){
        if(proceduralEditTransaction)throw RuntimeError(_T("Nested procedural Edit transaction"));
        auto next=std::make_unique<ProceduralEditTransaction>();
        for(int i=0;i<mods->size;++i){auto* m=edit(mods->data[i]);next->before.emplace_back(m,m->layers);}
        proceduralEditTransaction=std::move(next);
    }else if(command==1||command==2){
        if(!proceduralEditTransaction)throw RuntimeError(_T("No procedural Edit transaction"));
        auto finished=std::move(proceduralEditTransaction);
        // Restore every owner before updating any allocating UI status text.
        // A display failure must neither strand the transaction nor leave a
        // mixture of restored and successor maps across Edit modifiers.
        if(command==2){
            for(auto& entry:finished->before)entry.first->layers.swap(entry.second);
            for(auto& entry:finished->before)try{entry.first->status();}catch(...){/* Data is restored; the next UI refresh can retry. */}
        }
    }else throw RuntimeError(_T("Unknown procedural Edit transaction command"));
    return &ok;
}
def_visible_primitive(cyrusEditRequiredCandidates,"cyrusEditRequiredCandidates");
def_visible_primitive(cyrusEditLocalRevision,"cyrusEditLocalRevision");
Value* cyrusEditLocalRevision_cf(Value** a,int count){check_arg_count(cyrusEditLocalRevision,1,count);return Integer64::intern(edit(a[0])->localRevision);}
Value* cyrusEditRequiredCandidates_cf(Value** a,int count){
    check_arg_count(cyrusEditRequiredCandidates,2,count);type_check(a[0],Array,_T("Edit modifiers"));auto* mods=static_cast<Array*>(a[0]);const int key=a[1]->to_int();std::uint64_t required=0;
    for(int i=0;i<mods->size;++i){auto* m=edit(mods->data[i]);const auto found=m->layers.find(key);if(found==m->layers.end())continue;
        for(const auto& row:found->second.rows)if(!row.deleted&&(row.inputId!=row.outputId||hasEditTransform(row.delta))&&row.inputId.rfind(L"c:",0)==0){
            try{std::size_t used=0;const auto ordinal=std::stoull(row.inputId.substr(2),&used);if(used!=row.inputId.size()-2||ordinal>=cyrus::receivers::limit)throw std::invalid_argument("ordinal");required=std::max(required,ordinal+1);}catch(...){throw RuntimeError(_T("Saved Edit candidate exceeds the procedural pool limit"));}
        }
    }
    return Integer::intern(int(required));
}

def_visible_primitive(cyrusEditReceiverRequirements,"cyrusEditReceiverRequirements");
Value* cyrusEditReceiverRequirements_cf(Value** a,int count){
    check_arg_count(cyrusEditReceiverRequirements,2,count);type_check(a[0],Array,_T("Edit modifiers"));auto* mods=static_cast<Array*>(a[0]);const int key=a[1]->to_int();
    std::array<unsigned,cyrus::receivers::slots> required{};
    for(int i=0;i<mods->size;++i){auto* m=edit(mods->data[i]);const auto found=m->layers.find(key);if(found==m->layers.end())continue;
        for(const auto& row:found->second.rows)if(!row.deleted&&(row.inputId!=row.outputId||hasEditTransform(row.delta))&&row.inputId.rfind(L"c:",0)==0){
            try{std::size_t used=0;const auto id=std::stoull(row.inputId.substr(2),&used);unsigned slot=0;std::uint64_t ordinal=0;
                if(used!=row.inputId.size()-2||!cyrus::receivers::decodeCandidate(id,slot,ordinal))throw std::invalid_argument("Old identity");
                // A grid already admits its complete cell schedule; there is no
                // random prefix to extend. Binding validation still guards edits.
                if(ordinal<cyrus::receivers::limit)required[slot]=std::max(required[slot],unsigned(ordinal+1));}
            catch(...){throw RuntimeError(_T("Old combined-surface Edit identities require an explicit Reset Edits before using receiver-local sampling. Saved edits are preserved."));}}
    }
    one_typed_value_local(Array* result);vl.result=new Array(int(required.size()));for(auto value:required)vl.result->append(Integer::intern(int(value)));return_value(vl.result);
}
def_visible_primitive(cyrusEditSelectedIDs,"cyrusEditSelectedIDs");
Value* cyrusEditSelectedIDs_cf(Value** a,int count){
    check_arg_count(cyrusEditSelectedIDs,2,count);type_check(a[0],Array,_T("Edit modifiers"));auto* mods=static_cast<Array*>(a[0]);const int key=a[1]->to_int();std::unordered_set<std::wstring> seen;
    one_typed_value_local(Array* result);vl.result=new Array(0);
    for(int i=0;i<mods->size;++i){auto* m=edit(mods->data[i]);const auto found=m->layers.find(key);if(found==m->layers.end()||found->second.invalid)continue;
        for(const auto& row:found->second.rows)if(row.selected&&found->second.shown(row)&&seen.insert(row.outputId).second)vl.result->append(new String(row.outputId.c_str()));
    }
    return_value(vl.result);
}
