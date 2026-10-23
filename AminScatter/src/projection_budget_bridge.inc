// Opaque solve-owned counters. This value holds no mesh, SDK object or result;
// the controller releases it on both successful and failed successor paths.
visible_class_debug_ok(CyrusProjectionBudget)
class CyrusProjectionBudget : public Value {
public:
    amin::ProjectionWorkBudget work;
    CyrusProjectionBudget(){tag=class_tag(CyrusProjectionBudget);}
    classof_methods(CyrusProjectionBudget,Value);
    void collect() override {delete this;}
    void sprin1(CharStream* stream) override {stream->printf(_T("<CyrusProjectionBudget>"));}
    Value* deep_copy(HashTable*) override {return this;}
};
visible_class_instance(CyrusProjectionBudget,"CyrusProjectionBudget");
def_visible_primitive(cyrusProjectionBudget,"cyrusProjectionBudget");
Value* cyrusProjectionBudget_cf(Value**,int n){check_arg_count(cyrusProjectionBudget,0,n);return new CyrusProjectionBudget;}
def_visible_primitive(cyrusProjectionBudgetStats,"cyrusProjectionBudgetStats");
Value* cyrusProjectionBudgetStats_cf(Value** a,int n){
    check_arg_count(cyrusProjectionBudgetStats,1,n);type_check(a[0],CyrusProjectionBudget,_T("solve projection budget"));
    const auto& w=static_cast<CyrusProjectionBudget*>(a[0])->work;
    one_typed_value_local(Array* result);vl.result=new Array(8);
    for(auto value:{w.builds,w.queries,w.buildUnits,w.nodeVisits,w.triangleTests,w.workUsed,w.peakScratchBytes,w.currentScratchBytes})
        vl.result->append(Integer64::intern(static_cast<INT64>(value)));
    return_value(vl.result);
}
