// Snapshot authored spline geometry, including knot edits before host callbacks
// arrive. Hash the same bounded curve samples consumed by Area/Pattern inputs.
def_visible_primitive(cyrusReceiverShapeKey,"cyrusReceiverShapeKey");
Value* cyrusReceiverShapeKey_cf(Value** a,int n){
    check_arg_count(cyrusReceiverShapeKey,1,n);auto* nodes=groupArray(a[0]);std::uint64_t hash=1469598103934665603ULL;
    const auto add=[&](double value){std::uint64_t bits=0;std::memcpy(&bits,&value,sizeof(bits));for(int byte=0;byte<8;++byte){hash^=(bits>>(byte*8))&255;hash*=1099511628211ULL;}};
    const auto t=GetCOREInterface()->GetTime();
    for(int i=0;i<nodes->size;++i){auto* node=nodes->data[i]->to_node();if(!node)throw RuntimeError(_T("Missing receiver mask spline"));
        auto* object=node->EvalWorldState(t).obj;if(!object||object->SuperClassID()!=SHAPE_CLASS_ID)throw RuntimeError(_T("Receiver mask must be a spline"));
        auto* shape=static_cast<ShapeObject*>(object);const auto tm=node->GetObjectTM(t);add(shape->NumberOfCurves(t));
        for(int curve=0;curve<shape->NumberOfCurves(t);++curve){add(shape->CurveClosed(t,curve));const int steps=std::max(3,shape->NumberOfPieces(t,curve)*16);
            if(steps>65536)throw RuntimeError(_T("Receiver mask spline exceeds work limit"));add(steps);
            for(int k=0;k<steps;++k){const auto p=shape->InterpCurve3D(t,curve,float(k)/steps,PARAM_SIMPLE)*tm;add(p.x);add(p.y);add(p.z);}}}
    return new String(std::to_wstring(hash).c_str());
}
def_visible_primitive(cyrusReceiverPlan,"cyrusReceiverPlan");
Value* cyrusReceiverPlan_cf(Value** a,int n){
    check_arg_count(cyrusReceiverPlan,5,n);auto* input=groupArray(a[0]);std::vector<cyrus::receivers::Input> entries;
    for(int i=0;i<input->size;++i){auto* r=groupArray(input->data[i]);if(r->size!=4)throw RuntimeError(_T("Invalid receiver allocation input"));
        const int slot=r->data[0]->to_int(),required=r->data[3]->to_int();if(slot<1||required<0)throw RuntimeError(_T("Invalid receiver slot/requirement"));
        entries.push_back({unsigned(slot-1),proceduralID(r->data[1]),r->data[2]->to_double(),unsigned(required)});}
    cyrus::receivers::Plan plan;
    try{plan=cyrus::receivers::plan(entries,unsigned(a[1]->to_int()),a[2]->to_double(),unsigned(a[3]->to_int()),unsigned(a[4]->to_int()));}
    catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
    four_typed_value_locals(Array* result,Array* rows,Array* row,Array* order);
    vl.result=new Array(5);vl.rows=new Array(int(plan.receivers.size()));vl.result->append(vl.rows);
    for(const auto& r:plan.receivers){vl.row=new Array(4);vl.rows->append(vl.row);for(auto x:{r.slot+1,r.budget,r.attempts,r.pool})vl.row->append(Integer::intern(int(x)));}
    vl.order=new Array(int(plan.order.size()));vl.result->append(vl.order);for(auto id:plan.order)vl.order->append(Integer64::intern(id));
    vl.result->append(Integer::intern(int(plan.budget)));vl.result->append(Integer::intern(int(plan.attempts)));vl.result->append(plan.capped?&true_value:&false_value);
    return_value(vl.result);
}
def_visible_primitive(cyrusReceiverOffsetRows,"cyrusReceiverOffsetRows");
Value* cyrusReceiverOffsetRows_cf(Value** a,int n){
    check_arg_count(cyrusReceiverOffsetRows,2,n);auto* rows=groupArray(a[0]);const int offset=a[1]->to_int();if(offset<0)throw RuntimeError(_T("Invalid receiver face offset"));
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(rows->size);
    for(int i=0;i<rows->size;++i){auto* r=groupArray(rows->data[i]);if(r->size!=5)throw RuntimeError(_T("Receiver rows require local anchors"));
        const auto face=std::int64_t(r->data[3]->to_int())+offset;if(face<1||face>INT_MAX)throw RuntimeError(_T("Receiver face offset overflow"));
        vl.row=new Array(5);vl.result->append(vl.row);for(int k=0;k<5;++k)vl.row->append(k==3?Integer::intern(int(face)):r->data[k]);}
    return_value(vl.result);
}
def_visible_primitive(cyrusReceiverMergeBinding,"cyrusReceiverMergeBinding");
Value* cyrusReceiverMergeBinding_cf(Value** a,int n){
    check_arg_count(cyrusReceiverMergeBinding,2,n);
    try{const auto result=receiverWide(cyrus::receivers::mergeBinding(receiverUTF8(a[0]->to_string()),receiverUTF8(a[1]->to_string())));return new String(result.c_str());}
    catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
