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
    cyrus::rows::edited(row);return proceduralID(row->data[2]);
}
bool proceduralCandidate(std::string_view id,std::uint64_t& key){
    if(id.size()<3||id.substr(0,2)!="c:"||(id.size()>3&&id[2]=='0'))return false;
    const auto parsed=std::from_chars(id.data()+2,id.data()+id.size(),key);
    return parsed.ec==std::errc{}&&parsed.ptr==id.data()+id.size()&&key<=std::uint64_t(INT64_MAX);
}
// Borrowed only during the host call; the argument roots the immutable value.
// No implicit page/readback and no per-candidate textual key on the native path.
struct ProceduralRows {
    Value* value;Array* rows=nullptr;const cyrus::placements::View* native=nullptr;
    explicit ProceduralRows(Value* v):value(v){
        if(cyrusIsPlacementValue(v)){
            native=&cyrusPlacementView(v);
            if(native->stage()!=cyrus::placements::Stage::Edited)throw RuntimeError(_T("Acceptance requires edited native placements"));
        }else rows=groupArray(v);
        if(size()>1000000)throw RuntimeError(_T("Procedural input exceeds one million placements"));
    }
    std::size_t size() const{return native?native->size():std::size_t(rows->size);}
    Value* selected(const std::vector<std::size_t>& indices) const{
        if(native){
            bool same=indices.size()==size();for(std::size_t i=0;same&&i<indices.size();++i)same=indices[i]==i;
            if(same)return value;
            std::vector<std::uint32_t> selected;selected.reserve(indices.size());for(auto i:indices)selected.push_back(static_cast<std::uint32_t>(i));
            return cyrusPlacementValue(native->select(selected).compactIfSparse());
        }
        cyrus::placements::MaterializationScope materializations(cyrus::placements::TransportStage::Acceptance);
        one_typed_value_local(Array* result);vl.result=new Array(int(indices.size()));materializations.populationArray();for(auto i:indices)vl.result->append(rows->data[i]);return_value(vl.result);
    }
};
cyrus::procedural::Radii proceduralRadiusPair(Value* value){
    auto* pair=groupArray(value);
    if(pair->size!=2)throw RuntimeError(_T("A procedural radius needs XY and 3D values"));
    cyrus::procedural::Radii r{pair->data[0]->to_float(),pair->data[1]->to_float()};
    if(!std::isfinite(r.xy)||!std::isfinite(r.spatial)||r.xy<0||r.spatial<0)
        throw RuntimeError(_T("Invalid procedural radius pair"));
    return r;
}
void appendProceduralRadii(Array* result,cyrus::procedural::Radii r){
    if(!std::isfinite(r.xy)||!std::isfinite(r.spatial)||r.xy<0||r.spatial<0||
       r.xy>std::numeric_limits<float>::max()||r.spatial>std::numeric_limits<float>::max())
        throw RuntimeError(_T("Effective radius overflow"));
    auto* pair=new Array(2);result->append(pair);
    pair->append(Float::intern(static_cast<float>(r.xy)));pair->append(Float::intern(static_cast<float>(r.spatial)));
}
}
// Transport keeps original MAXScript row references; no identity/transform is
// reconstructed from a compacted output position.
def_visible_primitive(cyrusEvaluateProcedural,"cyrusEvaluateProcedural");
Value* cyrusEvaluateProcedural_cf(Value** a,int n){
    amin::diagnostics::StageTimer measurement(amin::diagnostics::Stage::Spacing);
    check_arg_count(cyrusEvaluateProcedural,3,n);
    try{
    cyrus::owned::fault(6);
    auto* layers=groupArray(a[0]);auto* pairs=groupArray(a[1]);
    const int cap=a[2]->to_int();if(cap<1||cap>1000000)throw RuntimeError(_T("Candidate admission cap must be 1..1000000"));
    cyrus::procedural::Plan plan;plan.maxSamples=static_cast<std::size_t>(cap);
    if(layers->size>10)throw RuntimeError(_T("Procedural policy supports ten layers"));
    std::size_t populationCount=0,sampleCount=0;
    std::vector<std::vector<ProceduralRows>> originals;
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
        populationCount+=populations->size;if(populationCount>10)throw RuntimeError(_T("Procedural policy supports ten total populations"));
        for(int s=0;s<populations->size;++s){auto* set=groupArray(populations->data[s]);
            if(set->size!=7&&set->size!=8)throw RuntimeError(_T("Procedural population requires its receiver schedule and source policies"));
            ProceduralRows rows(set->data[1]);sampleCount+=rows.size();if(sampleCount>std::size_t(cap))throw RuntimeError(_T("Procedural candidate memory admission limit exceeded"));
            std::unordered_map<std::string,std::uint64_t> schedule;
            std::unordered_map<std::uint64_t,std::uint64_t> numericSchedule;
            {const auto& order=cyrusScheduleValues(set->data[6]);if(order.size()>cyrus::receivers::limit)throw RuntimeError(_T("Receiver schedule exceeds 1,000,000 candidates"));
                if(rows.native)numericSchedule.reserve(order.size());else schedule.reserve(order.size());
                for(std::size_t k=0;k<order.size();++k){const auto id=order[k];unsigned slot=0;std::uint64_t local=0;
                    if(id>std::uint64_t(INT64_MAX)||!cyrus::receivers::decodeCandidate(id,slot,local)||
                       !(rows.native?numericSchedule.emplace(id,std::uint64_t(k)).second:schedule.emplace("c:"+std::to_string(id),std::uint64_t(k)).second))throw RuntimeError(_T("Invalid receiver candidate schedule"));}}
            cyrus::procedural::Population p;p.id=proceduralID(set->data[0]);
            if(set->size==8){
                auto* policies=groupArray(set->data[7]);
                if(policies->size>512)throw RuntimeError(_T("Clearance supports 512 active source rows"));
                if(!rows.native||!rows.native->sourceCohort()||rows.native->sourceCohort()->population()!=p.id||
                   rows.native->sourceCohort()->sources().size()!=std::size_t(policies->size))
                    throw RuntimeError(_T("Clearance source cohort does not match the prepared population"));
                for(int k=0;k<policies->size;++k){
                    auto* spec=groupArray(policies->data[k]);if(spec->size!=8)throw RuntimeError(_T("Invalid clearance source record"));
                    cyrus::procedural::SourcePolicy policy;policy.id=proceduralID(spec->data[0]);
                    if(proceduralID(spec->data[1])!=rows.native->sourceCohort()->sources()[std::size_t(k)].id)
                        throw RuntimeError(_T("Clearance source correspondence changed; previous result retained"));
                    const int copies=spec->data[2]->to_int(),others=spec->data[3]->to_int(),external=spec->data[4]->to_int();
                    if(copies<0||copies>2||others<0||others>2||external<0||external>3)throw RuntimeError(_T("Unknown clearance inheritance setting"));
                    policy.copies=unsigned(copies);policy.others=unsigned(others);policy.external=unsigned(external);
                    auto* targets=groupArray(spec->data[5]);if(targets->size>10)throw RuntimeError(_T("Too many clearance target layers"));
                    for(int t=0;t<targets->size;++t)policy.targets.push_back(proceduralID(targets->data[t]));
                    policy.preferred=spec->data[6]->to_bool()!=FALSE;policy.distance=proceduralRule(spec->data[7]);
                    p.sources.push_back(std::move(policy));
                }
            }
            originals.back().push_back(rows);auto* radii=set->data[2];
            if(cyrusRadiusCount(radii)!=rows.size())throw RuntimeError(_T("One radius pair per procedural instance required"));
            p.self=proceduralRule(set->data[3]);const int budget=set->data[4]->to_int(),attempts=set->data[5]->to_int();
            if(budget<0||attempts<0)throw RuntimeError(_T("Negative procedural budget"));p.budget=unsigned(budget);p.attemptLimit=unsigned(attempts);
            p.samples.reserve(rows.size());
            if(rows.native)for(std::size_t i=0;i<rows.size();++i){
                const auto& r=rows.native->at(i);const bool pin=(r.flags&cyrus::placements::Protected)!=0;
                std::uint64_t key=r.identity,ordinal=0;std::string authored;
                if(r.flags&cyrus::placements::Authored){
                    const auto text=rows.native->authored(i);
                    if(text.substr(0,2)=="c:"){
                        if(!proceduralCandidate(text,key))throw RuntimeError(_T("Candidate missing from receiver schedule"));
                    }else{key=0;authored.assign(text);if(!pin)throw RuntimeError(_T("Nonprocedural identity is not protected"));}
                }
                if(key){
                    unsigned receiver=0;std::uint64_t local=0;
                    const auto found=numericSchedule.find(key);
                    if(found==numericSchedule.end()||!cyrus::receivers::decodeCandidate(key,receiver,local)||receiver!=r.receiver)throw RuntimeError(_T("Candidate missing from its receiver schedule"));
                    ordinal=found->second;
                }else if(authored.empty())throw RuntimeError(_T("Invalid native candidate identity"));
                const auto radius=cyrusRadiusAt(radii,i);
                p.samples.push_back({{r.transform[9],r.transform[10],r.transform[11]},{float(radius[0]),float(radius[1])},ordinal,std::move(authored),pin,key,set->size==8?r.source-1:0});
            }
            else for(std::size_t i=0;i<rows.size();++i){auto* row=groupArray(rows.rows->data[i]);const auto id=proceduralRowID(row);const auto position=row->data[0]->to_matrix3().GetTrans();
                const bool pin=groupProtected(row);std::uint64_t ordinal=0;
                if(id.rfind("c:",0)==0){const auto found=schedule.find(id);if(found==schedule.end())throw RuntimeError(_T("Candidate missing from receiver schedule"));ordinal=found->second;}
                else if(!pin)throw RuntimeError(_T("Nonprocedural identity is not protected"));
                const auto radius=cyrusRadiusAt(radii,i);
                p.samples.push_back({{position.x,position.y,position.z},{float(radius[0]),float(radius[1])},ordinal,id,pin});
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
            keptLayer->append(originals[l][s].selected(r.kept));
            // Freeze the actual collision radii alongside the selected original
            // rows. Inspection must not recalculate them from pending settings.
            std::vector<CyrusRadiusPair> keptRadii;keptRadii.reserve(r.kept.size());
            for(auto i:r.kept){const auto pair=plan.layers[l].sets[s].samples[i].radii;keptRadii.push_back({float(pair.xy),float(pair.spatial)});}
            radiusLayer->append(cyrusNativeRadii(std::move(keptRadii)));
            std::array<std::size_t,7> reasons{};for(auto reason:r.reasons)++reasons[std::size_t(reason)];
            auto* stats=new Array(12);statsLayer->append(stats);
            for(auto value:{std::uint64_t(r.reasons.size()),std::uint64_t(r.kept.size()),std::uint64_t(reasons[2]),std::uint64_t(r.conflicts.size()),std::uint64_t(reasons[3]),std::uint64_t(reasons[4]),std::uint64_t(reasons[5]),std::uint64_t(reasons[6]),std::uint64_t(reasons[0]),r.attempts,std::uint64_t(r.shortfall),r.neighborVisits})stats->append(Integer64::intern(static_cast<INT64>(value)));
        }
    }
    return_value(vl.result);
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}

def_visible_primitive(cyrusProceduralPublicationVersion,"cyrusProceduralPublicationVersion");
Value* cyrusProceduralPublicationVersion_cf(Value**,int n){
    check_arg_count(cyrusProceduralPublicationVersion,0,n);
    return Integer::intern(4);
}

def_visible_primitive(cyrusProceduralRadii,"cyrusProceduralRadii");
Value* cyrusProceduralRadii_cf(Value** a,int n){
    amin::diagnostics::StageTimer measurement(amin::diagnostics::Stage::Attributes);
    check_arg_count(cyrusProceduralRadii,5,n);try{ProceduralRows rows(a[0]);auto* input=groupArray(a[1]);
    auto* ids=groupArray(a[2]);auto* modes=groupArray(a[3]);const auto values=groupRadii(a[4]);
    if(rows.size()>1000000||input->size>512)throw RuntimeError(_T("Radius input exceeds 1,000,000 placements or 512 sources"));
    if(ids->size!=modes->size||values.size()!=std::size_t(ids->size))throw RuntimeError(_T("Radius metadata length mismatch"));
    struct Source {int mode;double manual;bool follow;amin::Vec3 minimum,maximum;};
    std::vector<Source> sources;
    const std::array<amin::Vec3,3> identity={amin::Vec3{1,0,0},{0,1,0},{0,0,1}};
    for(int i=0;i<input->size;++i){auto* spec=groupArray(input->data[i]);
        if(spec->size!=5)throw RuntimeError(_T("Radius source needs mode, Manual radius, Follow Scale and two bounds"));
        const auto lo=spec->data[3]->to_point3(),hi=spec->data[4]->to_point3();
        Source s{spec->data[0]->to_int(),spec->data[1]->to_float(),spec->data[2]->to_bool()!=FALSE,{lo.x,lo.y,lo.z},{hi.x,hi.y,hi.z}};
        if((s.mode!=1&&s.mode!=2)||!std::isfinite(s.manual)||s.manual<0)throw RuntimeError(_T("Invalid radius source mode or Manual radius"));
        // Validate every admitted Auto source even when no sampled row uses it.
        if(s.mode==2)try{cyrus::procedural::transformedBounds(s.minimum,s.maximum,identity);}catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
        sources.push_back(s);
    }
    std::unordered_map<std::string,std::pair<int,double>> overrides;
    std::unordered_map<std::uint64_t,std::pair<int,double>> numericOverrides;
    for(int i=0;i<ids->size;++i){const int mode=modes->data[i]->to_int();if((mode!=1&&mode!=2)||!std::isfinite(values[i])||values[i]<0)throw RuntimeError(_T("Invalid instance radius override"));
        const auto id=proceduralID(ids->data[i]);std::uint64_t key=0;
        if(rows.native&&proceduralCandidate(id,key)){
            if(!numericOverrides.emplace(key,std::make_pair(mode,values[i])).second)throw RuntimeError(_T("Duplicate radius override"));
        }else if(!overrides.emplace(id,std::make_pair(mode,values[i])).second)throw RuntimeError(_T("Duplicate radius override"));
    }
    std::vector<CyrusRadiusPair> result;result.reserve(rows.size());
    for(std::size_t i=0;i<rows.size();++i){auto* row=rows.native?nullptr:groupArray(rows.rows->data[i]);if(row)cyrus::rows::edited(row);
        const int source=rows.native?int(rows.native->at(i).source)-1:row->data[1]->to_int()-1;if(source<0||std::size_t(source)>=sources.size())throw RuntimeError(_T("Missing radius source"));
        const auto& spec=sources[std::size_t(source)];cyrus::procedural::Radii r{spec.manual,spec.manual};
        if(spec.mode==2||spec.follow){
            std::array<amin::Vec3,3> basis;
            if(rows.native){const auto& m=rows.native->at(i).transform;for(int j=0;j<3;++j)basis[std::size_t(j)]={m[std::size_t(j*3)],m[std::size_t(j*3+1)],m[std::size_t(j*3+2)]};}
            else{const auto tm=row->data[0]->to_matrix3();for(int j=0;j<3;++j){const auto v=tm.GetRow(j);basis[std::size_t(j)]={v.x,v.y,v.z};}}
            try{
                if(spec.mode==2)r=cyrus::procedural::transformedBounds(spec.minimum,spec.maximum,basis);
                else r.xy=r.spatial=spec.manual*cyrus::procedural::transformScaleBound(basis);
            }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
        }
        const std::pair<int,double>* override=nullptr;
        if(rows.native){const auto& record=rows.native->at(i);
            if(record.flags&cyrus::placements::Authored){
                const auto text=rows.native->authored(i);std::uint64_t key=0;
                if(proceduralCandidate(text,key)){const auto found=numericOverrides.find(key);if(found!=numericOverrides.end())override=&found->second;}
                else{const auto found=overrides.find(std::string(text));if(found!=overrides.end())override=&found->second;}
            }else{const auto found=numericOverrides.find(record.identity);if(found!=numericOverrides.end())override=&found->second;}
        }else{const auto found=overrides.find(proceduralRowID(row));if(found!=overrides.end())override=&found->second;}
        if(override){
            if(override->first==1)r.xy=r.spatial=override->second;
            else {r.xy*=override->second;r.spatial*=override->second;}
        }
        if(!std::isfinite(r.xy)||!std::isfinite(r.spatial)||r.xy<0||r.spatial<0||r.xy>std::numeric_limits<float>::max()||r.spatial>std::numeric_limits<float>::max())throw RuntimeError(_T("Effective radius overflow"));
        result.push_back({float(r.xy),float(r.spatial)});
    }
    return cyrusNativeRadii(std::move(result));
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
