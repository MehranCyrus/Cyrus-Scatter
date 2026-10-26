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
// Bands consume bounded Bezier controls rather than the legacy Area sampler.
// Hash exactly those authored controls so dense linear Paths do not acquire a
// second 16-samples-per-piece admission limit just to build a cache key.
def_visible_primitive(cyrusBandShapeKey,"cyrusBandShapeKey");
Value* cyrusBandShapeKey_cf(Value** arguments,int count){
    check_arg_count(cyrusBandShapeKey,1,count);
    auto* nodes=groupArray(arguments[0]);
    if(nodes->size>32)throw RuntimeError(_T("Spline fields support at most 32 Paths."));
    std::uint64_t hash=1469598103934665603ULL;
    const auto add=[&](double value){std::uint64_t bits=0;std::memcpy(&bits,&value,sizeof(bits));for(int byte=0;byte<8;++byte){hash^=(bits>>(byte*8))&255;hash*=1099511628211ULL;}};
    const auto time=GetCOREInterface()->GetTime();std::size_t total=0;
    add(nodes->size);
    for(int index=0;index<nodes->size;++index){
        auto* node=nodes->data[index]->to_node();auto* object=node?node->EvalWorldState(time).obj:nullptr;
        if(!object||object->SuperClassID()!=SHAPE_CLASS_ID)throw RuntimeError(_T("Band Paths require closed spline shapes."));
        auto* shape=static_cast<ShapeObject*>(object);const int curves=shape->NumberOfCurves(time);
        if(curves<1||curves>2730)throw RuntimeError(_T("Path has no bounded closed curves."));
        std::size_t pieces=0;
        for(int curve=0;curve<curves;++curve){const int size=shape->NumberOfPieces(time,curve);
            if(size<1||std::size_t(size)>8192-total-pieces)throw RuntimeError(_T("Band Paths exceed 8,192 total knots."));pieces+=size;}
        if(!shape->CanMakeBezier())throw RuntimeError(_T("This Path cannot provide bounded Bezier geometry."));
        BezierShape bezier;shape->MakeBezier(time,bezier);
        if(bezier.SplineCount()!=curves)throw RuntimeError(_T("Path Bezier conversion changed its curve topology."));
        const auto tm=node->GetObjectTM(time);const auto x=tm.GetRow(0),y=tm.GetRow(1),z=tm.GetRow(2),offset=tm.GetTrans();
        const auto point=[&](Point3 p){add(double(p.x)*x.x+double(p.y)*y.x+double(p.z)*z.x+offset.x);add(double(p.x)*x.y+double(p.y)*y.y+double(p.z)*z.y+offset.y);add(double(p.x)*x.z+double(p.y)*y.z+double(p.z)*z.z+offset.z);};
        add(curves);
        for(int curve=0;curve<curves;++curve){
            auto* spline=bezier.GetSpline(curve);const int knots=spline?spline->KnotCount():0;
            if(!spline||!spline->Closed()||knots<1||std::size_t(knots)>8192-total)throw RuntimeError(_T("Invalid or oversized closed Bezier Path."));
            total+=knots;add(knots);
            for(int knot=0;knot<knots;++knot){const int next=(knot+1)%knots;const bool linear=spline->GetLineType(knot)==LTYPE_LINE;
                const auto first=spline->GetKnotPoint(knot),last=spline->GetKnotPoint(next);
                point(first);point(linear?first:spline->GetOutVec(knot));point(linear?last:spline->GetInVec(next));point(last);}
        }
    }
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
    three_typed_value_locals(Array* result,Array* rows,Array* row);
    vl.result=new Array(5);vl.rows=new Array(int(plan.receivers.size()));vl.result->append(vl.rows);
    for(const auto& r:plan.receivers){vl.row=new Array(4);vl.rows->append(vl.row);for(auto x:{r.slot+1,r.budget,r.attempts,r.pool})vl.row->append(Integer::intern(int(x)));}
    vl.result->append(cyrusNativeSchedule(std::move(plan.order)));
    vl.result->append(Integer::intern(int(plan.budget)));vl.result->append(Integer::intern(int(plan.attempts)));vl.result->append(plan.capped?&true_value:&false_value);
    return_value(vl.result);
}

def_visible_primitive(cyrusReceiverPlanSummaryVersion,"cyrusReceiverPlanSummaryVersion");
Value* cyrusReceiverPlanSummaryVersion_cf(Value**,int n){check_arg_count(cyrusReceiverPlanSummaryVersion,0,n);return Integer::intern(1);}
def_visible_primitive(cyrusReceiverPlanSummary,"cyrusReceiverPlanSummary");
Value* cyrusReceiverPlanSummary_cf(Value** a,int n){
    check_arg_count(cyrusReceiverPlanSummary,5,n);auto* input=groupArray(a[0]);
    if(input->size>128)throw RuntimeError(_T("Receiver allocation summary exceeds its input bound"));
    std::vector<cyrus::receivers::Input> entries;entries.reserve(input->size);
    for(int i=0;i<input->size;++i){auto* r=groupArray(input->data[i]);if(r->size!=4)throw RuntimeError(_T("Invalid receiver allocation input"));
        const int slot=r->data[0]->to_int(),required=r->data[3]->to_int();if(slot<1||required<0)throw RuntimeError(_T("Invalid receiver slot/requirement"));
        entries.push_back({unsigned(slot-1),proceduralID(r->data[1]),r->data[2]->to_double(),unsigned(required)});}
    cyrus::receivers::Plan summary;
    try{summary=cyrus::receivers::allocation(std::move(entries),unsigned(a[1]->to_int()),a[2]->to_double(),unsigned(a[3]->to_int()),unsigned(a[4]->to_int()));}
    catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
    unsigned pool=0;for(const auto& r:summary.receivers)pool+=r.pool;
    one_typed_value_local(Array* result);vl.result=new Array(4);
    for(auto value:{summary.budget,summary.attempts,pool})vl.result->append(Integer::intern(int(value)));
    vl.result->append(summary.capped?&true_value:&false_value);return_value(vl.result);
}
def_visible_primitive(cyrusReceiverOffsetRows,"cyrusReceiverOffsetRows");
Value* cyrusReceiverOffsetRows_cf(Value** a,int n){
    check_arg_count(cyrusReceiverOffsetRows,2,n);const int offset=a[1]->to_int();if(offset<0)throw RuntimeError(_T("Invalid receiver face offset"));
    if(cyrusIsPlacementValue(a[0]))try{
        const auto& view=cyrusPlacementView(a[0]);
        if(view.stage()!=cyrus::placements::Stage::Candidates)throw RuntimeError(_T("Receiver offsets require raw native candidates"));
        if(offset==0)return a[0];
        auto receivers=view.receiverCohort()?view.receiverCohort()->offset(static_cast<std::uint32_t>(offset)):std::shared_ptr<const cyrus::placements::ReceiverCohort>{};
        cyrus::placements::Builder builder(view.token().owner,view.stage(),view.sources(),view.size(),view.sourceCohort(),std::move(receivers));
        for(std::size_t i=0;i<view.size();++i){auto r=view.at(i);const auto face=std::uint64_t(r.face)+offset;if(face>INT_MAX)throw RuntimeError(_T("Receiver face offset overflow"));r.face=static_cast<std::uint32_t>(face);builder.appendGenerated(r);}
        return cyrusPlacementValue(builder.freeze());
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
    auto* rows=groupArray(a[0]);
    // A single receiver needs no face-index rewriting. Validate every row even
    // on this shared immutable fast path; downstream orientation owns matrices.
    if(offset==0){for(int i=0;i<rows->size;++i)cyrus::rows::raw(groupArray(rows->data[i]));return a[0];}
    cyrus::placements::MaterializationScope materializations(cyrus::placements::TransportStage::Receiver);
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(rows->size);materializations.populationArray();
    for(int i=0;i<rows->size;++i){auto* r=groupArray(rows->data[i]);cyrus::rows::raw(r);
        const auto face=std::int64_t(r->data[3]->to_int())+offset;if(face<1||face>INT_MAX)throw RuntimeError(_T("Receiver face offset overflow"));
        vl.row=new Array(r->size);materializations.row();vl.result->append(vl.row);for(int k=0;k<r->size;++k)vl.row->append(k==3?Integer::intern(int(face)):r->data[k]);}
    return_value(vl.result);
}
def_visible_primitive(cyrusReceiverMergeBinding,"cyrusReceiverMergeBinding");
Value* cyrusReceiverMergeBinding_cf(Value** a,int n){
    check_arg_count(cyrusReceiverMergeBinding,2,n);
    try{const auto result=receiverWide(cyrus::receivers::mergeBinding(receiverUTF8(a[0]->to_string()),receiverUTF8(a[1]->to_string())));return new String(result.c_str());}
    catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
