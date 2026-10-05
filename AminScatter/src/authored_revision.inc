// Isolated amount/seed native ownership experiment. Native members and SDK
// persistence own the admitted recipe; evaluation accepts no replacement
// settings and no "saved" flag. This is not full product recipe migration or
// cryptographic provenance for hostile modifications of .max file chunks.
#ifdef CYRUS_NATIVE_LICENSE_EXPERIMENT
#include <iparamb2.h>
#include <ref.h>
namespace {
const Class_ID ownedRevisionID(0x65785423, 0x19230ade);
struct OwnedState { std::uint32_t version=1, amount=0, seed=0, revision=0; };
class OwnedRevision;
class OwnedRestore : public RestoreObj {
    OwnedRevision* owner;
    SingleRefMaker lifetime;
    OwnedState before, after;
public:
    explicit OwnedRestore(OwnedRevision*);
    void Restore(int) override;
    void Redo() override;
    MSTR Description() override { return _T("Cyrus admitted revision"); }
};
class OwnedRevision : public ReferenceTarget {
    friend class OwnedRestore;
    OwnedState state_;
    INode* surface_=nullptr;
public:
    void DeleteThis() override { delete this; }
    Class_ID ClassID() override { return ownedRevisionID; }
    SClass_ID SuperClassID() override { return REF_TARGET_CLASS_ID; }
    void GetClassName(MSTR& text,bool) const override { text=_T("Cyrus owned revision LAB"); }
    int NumRefs() override { return 1; }
    RefTargetHandle GetReference(int i) override { return i==0?surface_:nullptr; }
    void SetReference(int i,RefTargetHandle value) override { if(i==0)surface_=static_cast<INode*>(value); }
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle target,PartID&,RefMessage message,BOOL) override {
        if(message==REFMSG_TARGET_DELETED&&target==surface_)surface_=nullptr;
        return REF_SUCCEED;
    }
    RefTargetHandle Clone(RemapDir& remap) override {
        auto* result=new OwnedRevision;
        result->state_=state_;
        // Scene clone remapping, with external references retained by Max's
        // normal clone protocol. Authoring a different recipe remains gated.
        result->ReplaceReference(0,remap.CloneRef(surface_));
        BaseClone(this,result,remap);
        return result;
    }
    const OwnedState& state() const { return state_; }
    void initialize(INode* surface) { ReplaceReference(0,surface); }
    std::vector<amin::Instance> evaluate(const OwnedState& state) const {
        if(!state.amount||!surface_)throw RuntimeError(_T("No admitted Cyrus recipe or receiver"));
        amin::Settings settings;
        settings.count=state.amount;settings.seed=state.seed;
        settings.uniformScale={1,1};settings.stableCandidates=true;
        return amin::scatter(meshOf(surface_,true),settings);
    }
    std::vector<amin::Instance> evaluate() const { return evaluate(state_); }
    void author(int amount,int seed) {
        auto permit=cyrusBoundaryBegin(this);
        if(!permit)throw RuntimeError(_T("Cyrus authoring denied; existing revision retained"));
        if(amount<1||amount>100000||seed<0)throw RuntimeError(_T("Amount 1..100000 and nonnegative seed required"));
        OwnedState next=state_;next.amount=amount;next.seed=seed;++next.revision;
        // Validate the calculation before changing either authored state or
        // any downstream output. A failed prepare leaves the old revision.
        evaluate(next);
        if(!cyrusBoundaryCommit(permit,this))throw RuntimeError(_T("Cyrus authority ended before commit"));
        theHold.Begin();theHold.Put(new OwnedRestore(this));
        state_=next;NotifyDependents(FOREVER,PART_ALL,REFMSG_CHANGE);
        theHold.Accept(_T("Cyrus admitted recipe"));
    }
    IOResult Save(ISave* save) override {
        save->BeginChunk(0x7201);ULONG bytes=0;
        const std::uint32_t values[]={state_.version,state_.amount,state_.seed,state_.revision};
        auto result=save->Write(values,sizeof(values),&bytes);save->EndChunk();
        return result==IO_OK&&bytes==sizeof(values)?IO_OK:IO_ERROR;
    }
    IOResult Load(ILoad* load) override {
        IOResult result;bool found=false;
        while((result=load->OpenChunk())==IO_OK) {
            if(load->CurChunkID()==0x7201) {
                std::uint32_t values[4]{};ULONG bytes=0;
                if(found||load->CurChunkLength()!=sizeof(values)||load->Read(values,sizeof(values),&bytes)!=IO_OK||bytes!=sizeof(values)) {
                    load->CloseChunk();return IO_ERROR;
                }
                OwnedState next{values[0],values[1],values[2],values[3]};
                if(next.version!=1||next.amount>100000||next.seed>INT_MAX||(next.amount&&!next.revision)) { load->CloseChunk();return IO_ERROR; }
                state_=next;found=true;
            }
            load->CloseChunk();
        }
        return result==IO_END?IO_OK:result;
    }
};
OwnedRestore::OwnedRestore(OwnedRevision* value):owner(value),before(value->state_) { lifetime.SetRef(value); }
void OwnedRestore::Restore(int undo) { if(undo)after=owner->state_;owner->state_=before;owner->NotifyDependents(FOREVER,PART_ALL,REFMSG_CHANGE); }
void OwnedRestore::Redo() { owner->state_=after;owner->NotifyDependents(FOREVER,PART_ALL,REFMSG_CHANGE); }
class OwnedDesc : public ClassDesc2 {
public:
    int IsPublic() override { return FALSE; }
    void* Create(BOOL) override { return new OwnedRevision; }
    const MCHAR* ClassName() override { return _T("Cyrus owned revision LAB"); }
    const MCHAR* NonLocalizedClassName() override { return ClassName(); }
    const MCHAR* InternalName() override { return _T("CyrusOwnedRevisionLab"); }
    SClass_ID SuperClassID() override { return REF_TARGET_CLASS_ID; }
    Class_ID ClassID() override { return ownedRevisionID; }
    const MCHAR* Category() override { return _T("Cyrus LAB"); }
    HINSTANCE HInstance() override { return CyrusEditInstance; }
};
OwnedRevision* owned(Value* value) {
    auto* target=value->to_reftarg();
    if(!target||target->ClassID()!=ownedRevisionID)throw RuntimeError(_T("Expected native owned Cyrus recipe"));
    return static_cast<OwnedRevision*>(target);
}
}
extern "C" __declspec(dllexport) ClassDesc* CyrusOwnedRevisionDesc() { static OwnedDesc desc;return &desc; }
def_visible_primitive(cyrusOwnedCreate,"cyrusOwnedCreate");
Value* cyrusOwnedCreate_cf(Value** a,int n) {
    check_arg_count(cyrusOwnedCreate,3,n);
    std::unique_ptr<OwnedRevision> value(static_cast<OwnedRevision*>(GetCOREInterface()->CreateInstance(REF_TARGET_CLASS_ID,ownedRevisionID)));
    if(!value)throw RuntimeError(_T("Missing matching owned-revision storage class"));
    if(!cyrusBoundaryAllows(value.get()))throw RuntimeError(_T("Cyrus authoring denied"));
    value->initialize(a[0]->to_node());value->author(a[1]->to_int(),a[2]->to_int());
    return MAXRefTarg::intern(value.release());
}
def_visible_primitive(cyrusOwnedAuthor,"cyrusOwnedAuthor");
Value* cyrusOwnedAuthor_cf(Value** a,int n) {
    check_arg_count(cyrusOwnedAuthor,3,n);owned(a[0])->author(a[1]->to_int(),a[2]->to_int());return &ok;
}
def_visible_primitive(cyrusOwnedState,"cyrusOwnedState");
Value* cyrusOwnedState_cf(Value** a,int n) {
    check_arg_count(cyrusOwnedState,1,n);const auto& state=owned(a[0])->state();
    one_typed_value_local(Array* result);vl.result=new Array(3);
    for(auto v:{state.amount,state.seed,state.revision})vl.result->append(Integer64::intern(v));
    return_value(vl.result);
}
def_visible_primitive(cyrusOwnedEvaluate,"cyrusOwnedEvaluate");
Value* cyrusOwnedEvaluate_cf(Value** a,int n) {
    check_arg_count(cyrusOwnedEvaluate,1,n);
    std::vector<amin::Instance> rows;
    try { rows=owned(a[0])->evaluate(); }
    catch(const std::exception&) { throw RuntimeError(_T("Owned evaluation failed; retained recipe unchanged")); }
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(static_cast<int>(rows.size()));
    for(const auto& p:rows) {
        vl.row=new Array(3);vl.row->append(new Matrix3Value(Matrix3(point(p.xAxis*p.scale),point(p.yAxis*p.scale),point(p.zAxis*p.scale),point(p.position))));
        vl.row->append(Integer::intern(1));vl.row->append(Integer64::intern(p.candidateKey));vl.result->append(vl.row);
    }
    return_value(vl.result);
}
#endif
