struct EditInput {Matrix3 tm;int source;EditKey id;bool protectedEdit=false;int face=0;Point3 bary{1,0,0};std::uint64_t owner=0;};
static bool hasEditTransform(const Matrix3& m){const Matrix3 identity(1);for(int i=0;i<4;++i)if(m.GetRow(i)!=identity.GetRow(i))return true;return false;}
static void bindStable(EditLayer& l,const std::wstring& signature,std::shared_ptr<const EditDerived> input){
    l.active=true;
    if(l.signature.empty())l.signature=signature;
    if(l.signature!=signature){try{l.signature=receiverWide(cyrus::receivers::mergeBinding(receiverUTF8(l.signature),receiverUTF8(signature)));}catch(const std::exception&){l.invalid=true;}}
    l.input=std::move(input);
    if(l.invalid)return;
    if(!l.originals){auto originals=ce::make<EditKeySet>();originals->reserve(l.rows.size());for(std::size_t i=0;i<l.rows.size();++i){const auto& r=l.rows.get(i);if(r.inputId==r.outputId)originals->insert(r.inputId);}l.originals=std::move(originals);}
    std::shared_ptr<EditKeySet> successor;
    for(unsigned i=0;i<l.input->size();++i){
        const auto id=l.input->native?editKey(*l.input->native,i):l.input->order[i];
        if((successor?successor.get():l.originals.get())->count(id))continue;
        if(!successor)successor=ce::make<EditKeySet>(*l.originals);
        successor->insert(id);EditRow row;row.savedSource=i;row.inputId=row.outputId=id;l.append(row);
    }
    if(successor)l.originals=std::move(successor);
}
static std::vector<EditInput> applyStable(CSEdit* m,int key,const std::vector<EditInput>& input,const std::wstring& signature){
    auto derived=ce::make<EditDerived>();derived->matrices.reserve(input.size());derived->order.reserve(input.size());derived->incoming.reserve(input.size());
    for(unsigned i=0;i<input.size();++i){derived->incoming.emplace(input[i].id,i);derived->matrices.push_back(input[i].tm);derived->order.push_back(input[i].id);}
    auto& l=m->layers[key];bindStable(l,signature,std::move(derived));if(l.invalid){m->status();return input;}
    std::vector<EditInput> output;output.reserve(l.rows.size());
    for(std::size_t i=0;i<l.rows.size();++i){const auto& r=l.rows.get(i);const auto source=l.source(r);if(!r.deleted&&source<input.size()){
        auto next=input[source];next.tm=next.tm*r.delta;next.id=r.outputId;next.protectedEdit=next.protectedEdit||r.inputId!=r.outputId||hasEditTransform(r.delta);output.push_back(std::move(next));}}
    m->status();return output;
}
static ep::View applyStableNative(CSEdit* m,int key,const ep::View& input,const std::wstring& signature){
    auto derived=ce::make<EditDerived>();derived->native=input;derived->incoming.reserve(input.size());
    for(unsigned i=0;i<input.size();++i)derived->incoming.emplace(editKey(input,i),i);
    auto& l=m->layers[key];bindStable(l,signature,std::move(derived));
    if(l.invalid)throw RuntimeError(_T("CS Edit base changed. Restore the generation settings or explicitly Reset Edits before updating this planting setup."));
    ep::Builder output(input.token().owner,ep::Stage::Edited,input.sources(),std::min(l.rows.size(),ep::maxRecords),input.sourceCohort(),input.receiverCohort());
    for(std::size_t i=0;i<l.rows.size();++i){const auto& row=l.rows.get(i);const auto source=l.source(row);if(row.deleted||source>=input.size())continue;
        auto record=input.at(source);const auto tm=editMatrix(input,source)*row.delta;
        for(int j=0;j<4;++j)for(int k=0;k<3;++k)record.transform[j*3+k]=tm.GetRow(j)[k];
        record.flags&=~ep::Authored;
        if(row.inputId!=row.outputId||hasEditTransform(row.delta))record.flags|=ep::Protected;
        if(row.outputId.authored){const auto& text=*row.outputId.authored;output.appendAuthored(record,receiverUTF8(std::wstring(text.begin(),text.end())));}
        else {record.identity=row.outputId.candidate;output.appendGenerated(record);}
    }
    m->status();return output.freeze();
}
// Candidate IDs and a base-population signature are independent of coverage.
def_visible_primitive(cyrusEditStack,"cyrusEditStack");
Value* cyrusEditStack_cf(Value** a,int count) {
    check_arg_count(cyrusEditStack,4,count);
    type_check(a[0],Array,_T("modifiers"));
    auto* mods=static_cast<Array*>(a[0]);
    const int key=a[2]->to_int();const std::wstring signature=a[3]->to_string();
    if(cyrusIsPlacementValue(a[1])) {
        const auto& view=cyrusPlacementView(a[1]);
        if(view.stage()!=cyrus::placements::Stage::Candidates)throw RuntimeError(_T("CS Edit requires raw native candidates"));
        try{auto result=view.edited();for(int i=mods->size-1;i>=0;--i)result=applyStableNative(edit(mods->data[i]),key,result,signature);return cyrusPlacementValue(std::move(result));}
        catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
    }
    type_check(a[1],Array,_T("rows"));auto* rows=static_cast<Array*>(a[1]);
    if(mods->size==0){
        // Normalization changes only identity type. The prepared generation is
        // immutable, so keep its already-rounded matrix/anchor values shared.
        for(int i=0;i<rows->size;++i){type_check(rows->data[i],Array,_T("instance row"));cyrus::rows::raw(static_cast<Array*>(rows->data[i]));}
        cyrus::placements::MaterializationScope materializations(cyrus::placements::TransportStage::Edit);
        two_typed_value_locals(Array* result,Array* row);vl.result=new Array(rows->size);materializations.populationArray();
        for(int i=0;i<rows->size;++i){auto* input=static_cast<Array*>(rows->data[i]);vl.row=new Array(8);materializations.row();vl.result->append(vl.row);
            for(int j=0;j<8;++j)if(j==2){auto* id=new String((L"c:"+std::to_wstring(input->data[2]->to_int64())).c_str());materializations.string();vl.row->append(id);}else vl.row->append(input->data[j]);}
        return_value(vl.result);
    }
    std::vector<EditInput> input;input.reserve(rows->size);
    for(int i=0;i<rows->size;++i) {
        type_check(rows->data[i],Array,_T("instance row"));auto* row=static_cast<Array*>(rows->data[i]);
        cyrus::rows::raw(row);
        const auto id=L"c:"+std::to_wstring(row->data[2]->to_int64());
        EditInput entry{row->data[0]->to_matrix3(),row->data[1]->to_int(),EditKey(id)};
        entry.face=row->data[3]->to_int();entry.bary=row->data[4]->to_point3();entry.owner=cyrus::rows::owner(row);
        input.push_back(std::move(entry));
    }
    for(int i=mods->size-1;i>=0;--i) {
        auto* m=edit(mods->data[i]);
        input=applyStable(m,key,input,signature);
        if(m->layers[key].invalid)throw RuntimeError(_T("CS Edit base changed. Restore the generation settings or explicitly Reset Edits before updating this planting setup."));
    }
    cyrus::placements::MaterializationScope materializations(cyrus::placements::TransportStage::Edit);
    two_typed_value_locals(Array* result,Array* row);
    vl.result=new Array(0);materializations.populationArray();
    for(auto& r:input){
        vl.row=new Array(8);materializations.row();vl.result->append(vl.row);auto* matrix=new Matrix3Value(r.tm);materializations.matrix();vl.row->append(matrix);vl.row->append(Integer::intern(r.source));
        auto* id=new String(r.id.text().c_str());materializations.string();vl.row->append(id);
        vl.row->append(Integer::intern(r.face));vl.row->append(new Point3Value(r.bary));vl.row->append(Integer64::intern(r.owner));
        vl.row->append(r.protectedEdit?&true_value:&false_value);vl.row->append(Integer::intern(2));
    }
    return_value(vl.result);
}

// Transient selection/display publication, separate from immutable Edit binding.
def_visible_primitive(cyrusEditPublish,"cyrusEditPublish");
Value* cyrusEditPublish_cf(Value** a,int count){
    check_arg_count(cyrusEditPublish,3,count);type_check(a[0],Array,_T("modifiers"));
    auto* mods=static_cast<Array*>(a[0]);if(mods->size==0)return &ok;const int key=a[1]->to_int();
    auto ids=ce::make<EditKeySet>();
    if(cyrusIsPlacementValue(a[2])){const auto& view=cyrusPlacementView(a[2]);if(view.stage()!=ep::Stage::Edited)throw RuntimeError(_T("Edit publication requires edited rows"));ids->reserve(view.size());for(std::size_t i=0;i<view.size();++i)ids->insert(editKey(view,i));}
    else {type_check(a[2],Array,_T("final rows"));auto* rows=static_cast<Array*>(a[2]);ids->reserve(rows->size);
        for(int i=0;i<rows->size;++i){type_check(rows->data[i],Array,_T("final row"));auto* row=static_cast<Array*>(rows->data[i]);cyrus::rows::edited(row);ids->insert(EditKey(row->data[2]->to_string()));}}
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
        if(command==1)try{cyrus::owned::fault(9);}catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
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
        for(std::size_t i=0;i<found->second.rows.size();++i){const auto& row=found->second.rows.get(i);if(!row.deleted&&(row.inputId!=row.outputId||hasEditTransform(row.delta))&&!row.inputId.authored){
            try{const auto ordinal=row.inputId.candidate;if(ordinal>=cyrus::receivers::limit)throw std::invalid_argument("ordinal");required=std::max(required,ordinal+1);}catch(...){throw RuntimeError(_T("Saved Edit candidate exceeds the procedural pool limit"));}
        }}
    }
    return Integer::intern(int(required));
}

def_visible_primitive(cyrusEditReceiverRequirements,"cyrusEditReceiverRequirements");
Value* cyrusEditReceiverRequirements_cf(Value** a,int count){
    check_arg_count(cyrusEditReceiverRequirements,2,count);type_check(a[0],Array,_T("Edit modifiers"));auto* mods=static_cast<Array*>(a[0]);const int key=a[1]->to_int();
    std::array<unsigned,cyrus::receivers::slots> required{};
    for(int i=0;i<mods->size;++i){auto* m=edit(mods->data[i]);const auto found=m->layers.find(key);if(found==m->layers.end())continue;
        for(std::size_t i=0;i<found->second.rows.size();++i){const auto& row=found->second.rows.get(i);if(!row.deleted&&(row.inputId!=row.outputId||hasEditTransform(row.delta))&&!row.inputId.authored){
            try{const auto id=row.inputId.candidate;unsigned slot=0;std::uint64_t ordinal=0;
                if(!cyrus::receivers::decodeCandidate(id,slot,ordinal))throw std::invalid_argument("Old identity");
                // A grid already admits its complete cell schedule; there is no
                // random prefix to extend. Binding validation still guards edits.
                if(ordinal<cyrus::receivers::limit)required[slot]=std::max(required[slot],unsigned(ordinal+1));}
            catch(...){throw RuntimeError(_T("Old combined-surface Edit identities require an explicit Reset Edits before using receiver-local sampling. Saved edits are preserved."));}}}
    }
    one_typed_value_local(Array* result);vl.result=new Array(int(required.size()));for(auto value:required)vl.result->append(Integer::intern(int(value)));return_value(vl.result);
}
def_visible_primitive(cyrusEditSelectedIDs,"cyrusEditSelectedIDs");
Value* cyrusEditSelectedIDs_cf(Value** a,int count){
    check_arg_count(cyrusEditSelectedIDs,2,count);type_check(a[0],Array,_T("Edit modifiers"));auto* mods=static_cast<Array*>(a[0]);const int key=a[1]->to_int();EditKeySet seen;
    one_typed_value_local(Array* result);vl.result=new Array(0);
    for(int i=0;i<mods->size;++i){auto* m=edit(mods->data[i]);const auto found=m->layers.find(key);if(found==m->layers.end()||found->second.invalid)continue;
        for(std::size_t i=0;i<found->second.rows.size();++i){const auto& row=found->second.rows.get(i);if(found->second.selection.get(i)&&found->second.shown(row)&&seen.insert(row.outputId).second)vl.result->append(new String(row.outputId.text().c_str()));}
    }
    return_value(vl.result);
}
