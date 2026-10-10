namespace {
std::string proceduralID(Value* value){
    const std::wstring text=value->to_string();std::string out;
    if(text.size()>256)throw RuntimeError(_T("Procedural identity is too long"));
    for(auto c:text){if(c>127)throw RuntimeError(_T("Procedural identities must be ASCII keys, not display names"));out.push_back(static_cast<char>(c));}
    return out;
}
cyrus::procedural::DistanceRule proceduralRule(Value* value){
    auto* r=groupArray(value);if(r->size!=4)throw RuntimeError(_T("Rule needs enabled, radius multiplier, gap and XY metric"));
    return {r->data[0]->to_bool()!=FALSE,r->data[1]->to_float(),r->data[2]->to_float(),r->data[3]->to_bool()!=FALSE};
}
std::string proceduralRowID(Array* row){
    if(row->size<3)throw RuntimeError(_T("Procedural row needs an immutable identity"));
    if(row->data[2]->is_kind_of(class_tag(String)))return proceduralID(row->data[2]);
    const auto n=row->data[2]->to_int64();if(n<0)throw RuntimeError(_T("Negative candidate identity"));
    return "c:"+std::to_string(n);
}
}
// Transport keeps original MAXScript row references; no identity/transform is
// reconstructed from a compacted output position.
def_visible_primitive(cyrusEvaluateProcedural,"cyrusEvaluateProcedural");
Value* cyrusEvaluateProcedural_cf(Value** a,int n){
    check_arg_count(cyrusEvaluateProcedural,3,n);
    auto* layers=groupArray(a[0]);auto* pairs=groupArray(a[1]);
    const int cap=a[2]->to_int();if(cap<1||cap>1000000)throw RuntimeError(_T("Candidate admission cap must be 1..1000000"));
    cyrus::procedural::Plan plan;plan.maxSamples=static_cast<std::size_t>(cap);
    std::vector<std::vector<Array*>> originals;
    for(int l=0;l<layers->size;++l){auto* input=groupArray(layers->data[l]);
        if(input->size!=7)throw RuntimeError(_T("Invalid procedural layer payload"));
        cyrus::procedural::Layer layer;layer.id=proceduralID(input->data[0]);
        layer.acceptedTarget=input->data[1]->to_bool()!=FALSE;layer.repair=input->data[2]->to_bool()!=FALSE;
        const int rounds=input->data[3]->to_int();if(rounds<1||rounds>16)throw RuntimeError(_T("Repair rounds must be 1..16"));layer.rounds=unsigned(rounds);
        layer.siblings=proceduralRule(input->data[4]);auto* cleanup=groupArray(input->data[5]);
        if(cleanup->size!=5)throw RuntimeError(_T("Invalid procedural cleanup payload"));
        layer.cleanup.cleanup=cleanup->data[0]->to_bool()!=FALSE;layer.cleanup.radius=cleanup->data[1]->to_float();
        const int neighbors=cleanup->data[2]->to_int(),island=cleanup->data[3]->to_int();
        if(neighbors<0||island<0)throw RuntimeError(_T("Invalid cleanup thresholds"));
        layer.cleanup.minNeighbors=unsigned(neighbors);layer.cleanup.minIsland=unsigned(island);layer.cleanup.planar=cleanup->data[4]->to_bool()!=FALSE;
        auto* populations=groupArray(input->data[6]);originals.emplace_back();
        for(int s=0;s<populations->size;++s){auto* set=groupArray(populations->data[s]);
            if(set->size!=6&&set->size!=7)throw RuntimeError(_T("Invalid procedural population payload"));
            std::unordered_map<std::string,std::uint64_t> schedule;
            if(set->size==7){auto* order=groupArray(set->data[6]);if(order->size>100000)throw RuntimeError(_T("Receiver schedule exceeds limit"));
                for(int k=0;k<order->size;++k){const auto id=order->data[k]->to_int64();unsigned slot=0,local=0;
                    if(id<0||!cyrus::receivers::decode(std::uint64_t(id),slot,local)||!schedule.emplace("c:"+std::to_string(id),std::uint64_t(k)).second)throw RuntimeError(_T("Invalid receiver candidate schedule"));}}
            cyrus::procedural::Population p;p.id=proceduralID(set->data[0]);auto* rows=groupArray(set->data[1]);
            originals.back().push_back(rows);const auto radii=groupRadii(set->data[2]);
            if(radii.size()!=std::size_t(rows->size))throw RuntimeError(_T("One radius per procedural instance required"));
            p.self=proceduralRule(set->data[3]);const int budget=set->data[4]->to_int(),attempts=set->data[5]->to_int();
            if(budget<0||attempts<0)throw RuntimeError(_T("Negative procedural budget"));p.budget=unsigned(budget);p.attemptLimit=unsigned(attempts);
            for(int i=0;i<rows->size;++i){auto* row=groupArray(rows->data[i]);const auto id=proceduralRowID(row);const auto position=row->data[0]->to_matrix3().GetTrans();
                const bool pin=groupProtected(row);std::uint64_t ordinal=0;
                if(set->size==7&&id.rfind("c:",0)==0){const auto found=schedule.find(id);if(found==schedule.end())throw RuntimeError(_T("Candidate missing from receiver schedule"));ordinal=found->second;}
                else if(id.rfind("c:",0)==0){try{std::size_t used=0;ordinal=std::stoull(id.substr(2),&used);if(used!=id.size()-2)throw std::invalid_argument("ordinal");}catch(...){throw RuntimeError(_T("Invalid candidate ordinal"));}}
                else if(!pin)throw RuntimeError(_T("Nonprocedural identity is not protected"));
                p.samples.push_back({{position.x,position.y,position.z},radii[std::size_t(i)],ordinal,id,pin});
            }
            layer.sets.push_back(std::move(p));
        }
        plan.layers.push_back(std::move(layer));
    }
    for(int i=0;i<pairs->size;++i){auto* p=groupArray(pairs->data[i]);if(p->size!=4)throw RuntimeError(_T("Invalid procedural pair payload"));
        const int scope=p->data[0]->to_int();if(scope!=1&&scope!=2)throw RuntimeError(_T("Unknown procedural scope"));
        plan.rules.push_back({scope==1?cyrus::procedural::Scope::Sets:cyrus::procedural::Scope::Layers,proceduralID(p->data[1]),proceduralID(p->data[2]),proceduralRule(p->data[3])});
    }
    cyrus::procedural::Result resolved;
    try{resolved=cyrus::procedural::evaluate(plan);}catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
    five_typed_value_locals(Array* result,Array* kept,Array* stats,Array* rounds,Array* radii);
    vl.result=new Array(4);vl.kept=new Array(layers->size);vl.result->append(vl.kept);
    vl.stats=new Array(layers->size);vl.result->append(vl.stats);vl.rounds=new Array(layers->size);vl.result->append(vl.rounds);
    vl.radii=new Array(layers->size);vl.result->append(vl.radii);
    for(std::size_t l=0;l<resolved.layers.size();++l){
        auto* keptLayer=new Array(int(resolved.layers[l].sets.size()));vl.kept->append(keptLayer);
        auto* statsLayer=new Array(int(resolved.layers[l].sets.size()));vl.stats->append(statsLayer);
        auto* radiusLayer=new Array(int(resolved.layers[l].sets.size()));vl.radii->append(radiusLayer);
        auto* round=new Array(2);vl.rounds->append(round);round->append(Integer::intern(int(resolved.layers[l].rounds)));round->append(resolved.layers[l].limitReached?&true_value:&false_value);
        for(std::size_t s=0;s<resolved.layers[l].sets.size();++s){const auto& r=resolved.layers[l].sets[s];
            auto* kept=new Array(int(r.kept.size()));keptLayer->append(kept);for(auto i:r.kept)kept->append(originals[l][s]->data[i]);
            // Freeze the actual collision radii alongside the selected original
            // rows. Inspection must not recalculate them from pending settings.
            auto* keptRadii=new Array(int(r.kept.size()));radiusLayer->append(keptRadii);
            for(auto i:r.kept)keptRadii->append(Float::intern(static_cast<float>(plan.layers[l].sets[s].samples[i].radius)));
            std::array<std::size_t,7> reasons{};for(auto reason:r.reasons)++reasons[std::size_t(reason)];
            auto* stats=new Array(12);statsLayer->append(stats);
            for(auto value:{std::uint64_t(r.reasons.size()),std::uint64_t(r.kept.size()),std::uint64_t(reasons[2]),std::uint64_t(r.conflicts.size()),std::uint64_t(reasons[3]),std::uint64_t(reasons[4]),std::uint64_t(reasons[5]),std::uint64_t(reasons[6]),std::uint64_t(reasons[0]),r.attempts,std::uint64_t(r.shortfall),r.neighborVisits})stats->append(Integer64::intern(static_cast<INT64>(value)));
        }
    }
    return_value(vl.result);
}

def_visible_primitive(cyrusProceduralPublicationVersion,"cyrusProceduralPublicationVersion");
Value* cyrusProceduralPublicationVersion_cf(Value**,int n){
    check_arg_count(cyrusProceduralPublicationVersion,0,n);
    return Integer::intern(1);
}

def_visible_primitive(cyrusProceduralRadii,"cyrusProceduralRadii");
Value* cyrusProceduralRadii_cf(Value** a,int n){
    check_arg_count(cyrusProceduralRadii,6,n);auto* rows=groupArray(a[0]);const auto radii=groupRadii(a[1]);auto* follow=groupArray(a[2]);
    auto* ids=groupArray(a[3]);auto* modes=groupArray(a[4]);const auto values=groupRadii(a[5]);
    if(radii.size()!=std::size_t(follow->size)||ids->size!=modes->size||values.size()!=std::size_t(ids->size))throw RuntimeError(_T("Radius metadata length mismatch"));
    std::unordered_map<std::string,std::pair<int,double>> overrides;
    for(int i=0;i<ids->size;++i){const int mode=modes->data[i]->to_int();if((mode!=1&&mode!=2)||!std::isfinite(values[i])||values[i]<0)throw RuntimeError(_T("Invalid instance radius override"));
        if(!overrides.emplace(proceduralID(ids->data[i]),std::make_pair(mode,values[i])).second)throw RuntimeError(_T("Duplicate radius override"));
    }
    one_typed_value_local(Array* result);vl.result=new Array(rows->size);
    for(int i=0;i<rows->size;++i){auto* row=groupArray(rows->data[i]);if(row->size<3)throw RuntimeError(_T("Radius requires keyed rows"));
        const int source=row->data[1]->to_int()-1;if(source<0||std::size_t(source)>=radii.size())throw RuntimeError(_T("Missing radius source"));
        double r=radii[std::size_t(source)];if(!std::isfinite(r)||r<0)throw RuntimeError(_T("Invalid source radius"));
        if(follow->data[source]->to_bool()){
            const auto tm=row->data[0]->to_matrix3();std::array<amin::Vec3,3> basis;
            for(int j=0;j<3;++j){const auto v=tm.GetRow(j);basis[std::size_t(j)]={v.x,v.y,v.z};}
            try{r*=cyrus::procedural::transformScaleBound(basis);}catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
        }
        const auto found=overrides.find(proceduralRowID(row));if(found!=overrides.end())r=found->second.first==1?found->second.second:r*found->second.second;
        if(!std::isfinite(r)||r>std::numeric_limits<float>::max())throw RuntimeError(_T("Effective radius overflow"));
        vl.result->append(Float::intern(static_cast<float>(r)));
    }
    return_value(vl.result);
}
