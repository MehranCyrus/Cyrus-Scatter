// Post-Edit eligibility: original row references and protected artist changes
// survive untouched. This synchronous adapter owns its evaluated geometry.
namespace {
cyrus::surface_filter::Settings surfaceFilterSettings(Value* value) {
    auto* a=groupArray(value);
    if(a->size!=10)throw RuntimeError(_T("Surface filter requires ten settings"));
    cyrus::surface_filter::Settings result;
    for(int i=0;i<2;++i){
        auto& r=i==0?result.slope:result.altitude;const int k=i*5;
        if(a->data[k]!=&true_value&&a->data[k]!=&false_value)throw RuntimeError(_T("Invalid surface filter enable flag"));
        r={a->data[k]==&true_value,a->data[k+1]->to_double(),a->data[k+2]->to_double(),a->data[k+3]->to_double(),a->data[k+4]->to_double()};
    }
    cyrus::surface_filter::validate(result);return result;
}
}
def_visible_primitive(cyrusSurfaceFilterVersion,"cyrusSurfaceFilterVersion");
Value* cyrusSurfaceFilterVersion_cf(Value**,int n){check_arg_count(cyrusSurfaceFilterVersion,0,n);return Integer::intern(1);}
def_visible_primitive(cyrusValidateSurfaceFilter,"cyrusValidateSurfaceFilter");
Value* cyrusValidateSurfaceFilter_cf(Value** a,int n){
    check_arg_count(cyrusValidateSurfaceFilter,1,n);
    try{surfaceFilterSettings(a[0]);}catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
    return &ok;
}
def_visible_primitive(cyrusSurfaceFilter,"cyrusSurfaceFilter");
Value* cyrusSurfaceFilter_cf(Value** a,int n){
    amin::diagnostics::StageTimer measurement(amin::diagnostics::Stage::SurfaceFilter);
    check_arg_count(cyrusSurfaceFilter,5,n);
    auto* rows=groupArray(a[0]);auto* targets=groupArray(a[1]);auto* keys=groupArray(a[2]);
    if(rows->size>1000000||targets->size>128||targets->size!=keys->size)
        throw RuntimeError(_T("Surface filter input exceeds candidate/receiver limits"));
    three_typed_value_locals(Array* result,Array* kept,Array* stats);
    vl.result=new Array(2);vl.kept=new Array(rows->size);vl.result->append(vl.kept);
    vl.stats=new Array(3);vl.result->append(vl.stats);
    int rejected=0,protectedCount=0;
    try{
        const auto settings=surfaceFilterSettings(a[4]);const auto seed=std::uint32_t(a[3]->to_int());
        struct Receiver {unsigned slot;std::uint64_t salt;std::size_t begin;std::vector<amin::Triangle> mesh;std::vector<double> slopes;};
        std::vector<Receiver> receivers;std::size_t faceCount=0;std::set<unsigned> slots;
        if(settings.slope.enabled||settings.altitude.enabled){
            for(int i=0;i<targets->size;++i){
                auto* key=groupArray(keys->data[i]);if(key->size!=2)throw RuntimeError(_T("Invalid surface filter receiver identity"));
                const int slot=key->data[0]->to_int();if(slot<1||slot>128||!slots.insert(unsigned(slot-1)).second)throw RuntimeError(_T("Invalid surface filter receiver slot"));
                Receiver r{unsigned(slot-1),cyrus::receivers::salt(proceduralID(key->data[1])),faceCount,meshOf(targets->data[i]->to_node(),true,false,10000000-faceCount),{}};
                faceCount+=r.mesh.size();if(faceCount>10000000)throw RuntimeError(_T("Surface filter exceeds 10 million evaluated faces"));
                if(settings.slope.enabled)r.slopes.assign(r.mesh.size(),-1);
                receivers.push_back(std::move(r));
            }
        }
        for(int i=0;i<rows->size;++i){
            auto* row=groupArray(rows->data[i]);cyrus::rows::edited(row);
            bool keep=true;
            if(cyrus::rows::protectedEdit(row))++protectedCount;
            else if(settings.slope.enabled||settings.altitude.enabled){
                const auto id=proceduralID(row->data[2]);
                if(id.rfind("c:",0)!=0)throw RuntimeError(_T("Unprotected surface filter row has no candidate identity"));
                std::size_t used=0;const auto encoded=std::stoull(id.substr(2),&used);
                unsigned slot=0;std::uint64_t ordinal=0;
                if(used!=id.size()-2||!cyrus::receivers::decodeCandidate(encoded,slot,ordinal))throw RuntimeError(_T("Invalid surface filter candidate identity"));
                auto found=std::find_if(receivers.begin(),receivers.end(),[&](const Receiver& r){return r.slot==slot;});
                if(found==receivers.end())throw RuntimeError(_T("Surface filter candidate receiver is missing"));
                const auto face=std::size_t(row->data[3]->to_int()-1);
                if(face<found->begin||face-found->begin>=found->mesh.size())throw RuntimeError(_T("Surface filter anchor belongs to another receiver"));
                const auto local=face-found->begin;const auto& t=found->mesh[local];const auto b=vec(row->data[4]->to_point3());
                const double altitude=cyrus::surface_filter::anchorAltitude(t,b);
                double slope=0;
                if(settings.slope.enabled){auto& cached=found->slopes[local];if(cached<0)cached=cyrus::surface_filter::slopeDegrees(t);slope=cached;}
                keep=cyrus::surface_filter::accepts(settings,slope,altitude,seed,ordinal,found->salt);
            }
            if(keep)vl.kept->append(row);else ++rejected;
        }
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
    for(int count:{rows->size,rejected,protectedCount})vl.stats->append(Integer::intern(count));
    return_value(vl.result);
}
