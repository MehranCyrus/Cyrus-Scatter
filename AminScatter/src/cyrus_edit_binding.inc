// Source reconciliation shared with the SDK-free production-body tests.
static std::shared_ptr<EditDerived> nativeEditInput(const ep::View& input){
    auto result=ce::make<EditDerived>();result->native=input;result->incoming.reserve(input.size());
    for(unsigned i=0;i<input.size();++i)if(!result->incoming.emplace(editKey(input,i),i).second)throw std::invalid_argument("Duplicate Edit input identity");
    if(input.sourceCohort())for(const auto& source:input.sourceCohort()->sources()){const auto id=receiverWide(source.id);result->sourceIDs.emplace_back(id.begin(),id.end());}
    return result;
}
static Matrix3 recipeEditInverse(const Matrix3& a){
    const auto x=a.GetRow(0),y=a.GetRow(1),z=a.GetRow(2);const double d=double(x.x)*(double(y.y)*z.z-double(y.z)*z.y)-double(x.y)*(double(y.x)*z.z-double(y.z)*z.x)+double(x.z)*(double(y.x)*z.y-double(y.y)*z.x);
    if(!std::isfinite(d)||std::abs(d)<1e-30)throw std::invalid_argument("Recipe instance frame is singular");Matrix3 m(1);
    m.SetRow(0,Point3(float((double(y.y)*z.z-double(y.z)*z.y)/d),float((double(x.z)*z.y-double(x.y)*z.z)/d),float((double(x.y)*y.z-double(x.z)*y.y)/d)));
    m.SetRow(1,Point3(float((double(y.z)*z.x-double(y.x)*z.z)/d),float((double(x.x)*z.z-double(x.z)*z.x)/d),float((double(x.z)*y.x-double(x.x)*y.z)/d)));
    m.SetRow(2,Point3(float((double(y.x)*z.y-double(y.y)*z.x)/d),float((double(x.y)*z.x-double(x.x)*z.y)/d),float((double(x.x)*y.y-double(x.y)*y.x)/d)));
    Point3 t;for(int k=0;k<3;++k)t[k]=float(-double(a.GetRow(3).x)*m.GetRow(0)[k]-double(a.GetRow(3).y)*m.GetRow(1)[k]-double(a.GetRow(3).z)*m.GetRow(2)[k]);m.SetRow(3,t);return m;
}
static void bindStable(EditLayer&,const std::wstring&,std::shared_ptr<EditDerived>);
static void bindRecipeLayer(EditLayer& layer,const std::wstring& signature,std::shared_ptr<EditDerived> input){
    EditLayer next;bindStable(next,signature,input);const auto old=cyrus::editbinding::parse(receiverUTF8(layer.signature));auto descriptor=cyrus::editbinding::parse(receiverUTF8(next.signature));auto ids=ce::make<EditLineages>(*next.lineages);
    for(const auto& [id,revision]:old.sources)if(!descriptor.sources.count(id))descriptor.sources.emplace(id,revision);
    std::unordered_map<EditVariant,std::size_t,EditVariantHash,std::equal_to<EditVariant>,ce::Allocator<std::pair<const EditVariant,std::size_t>>> originals;
    for(std::size_t i=0;i<next.rows.size();++i)originals.emplace(EditVariant{next.rows.get(i).outputId,next.rows.get(i).lineage},i);
    std::map<std::uint64_t,EditKey> reserved;std::uint64_t last=next.nextOrder;
    for(std::size_t i=0;i<layer.rows.size();++i){const auto& r=layer.rows.get(i);auto p=reserved.emplace(r.order,r.outputId);if(!p.second&&p.first->second!=r.outputId)throw std::invalid_argument("Conflicting recipe Edit order");last=std::max(last,r.order+1);}
    for(std::size_t i=0;i<next.rows.size();++i){auto row=next.rows.get(i);auto used=reserved.find(row.order);if(used!=reserved.end()&&used->second!=row.outputId){row.order=last++;next.rows.write(i)=row;}}
    for(std::size_t i=0;i<layer.rows.size();++i){auto row=layer.rows.get(i);const auto& source=layer.lineages->ids.at(row.lineage-1);std::wstring id(source.begin(),source.end());auto lineage=ids->find(id);if(!lineage){if(ids->ids.size()>=cyrus::editbinding::maxSources)throw std::length_error("Recipe source history is full");ids->ids.emplace_back(id.begin(),id.end());lineage=unsigned(ids->ids.size());}row.lineage=lineage;
        auto found=originals.find({row.outputId,lineage});if(found==originals.end())next.append(row);else{next.textBytes-=EditLayer::keyBytes(next.rows.get(found->second));next.textBytes+=EditLayer::keyBytes(row);next.rows.write(found->second)=row;}}
    next.lineages=std::move(ids);next.nextOrder=last;next.signature=receiverWide(cyrus::editbinding::encode(descriptor));next.originals.reset();next.recipeUnbound=false;bindStable(next,signature,std::move(input));layer=std::move(next);
}
static void bindStable(EditLayer& layer,const std::wstring& signature,std::shared_ptr<EditDerived> input){
    if(layer.recipeUnbound){bindRecipeLayer(layer,signature,std::move(input));return;}
    // Reconciliation is a complete successor. The outer publication transaction
    // additionally retains all modifiers if another owner later fails.
    auto l=layer;l.active=true;const auto text=receiverUTF8(signature);
    const bool sourceAware=cyrus::editbinding::isSourceAware(text);
    if(sourceAware){
        if(!input->native||!input->native->sourceCohort())throw std::invalid_argument("Source-aware Edit requires the native source correspondence");
        const auto current=cyrus::editbinding::parse(text);const bool authored=l.hasAuthored();
        cyrus::editbinding::Descriptor merged;
        if(l.signature.empty()||!authored)merged=current;
        else merged=cyrus::editbinding::merge(receiverUTF8(l.signature),text).descriptor;
        bool hydrate=l.signature.empty();
        if(!l.sourceAware&&!l.signature.empty()){
            // A moved/deleted legacy row can only acquire source lineage from
            // an exactly compatible old generation. A missing row stays saved.
            if(authored)cyrus::receivers::mergeBinding(receiverUTF8(l.signature),current.legacy);
            l.legacyProof=l.signature;hydrate=authored;
        }
        if(!l.legacyProof.empty())try{cyrus::receivers::mergeBinding(receiverUTF8(l.legacyProof),current.legacy);hydrate=true;}catch(const std::invalid_argument&){hydrate=false;}
        auto lineage=l.lineages?ce::make<EditLineages>(*l.lineages):ce::make<EditLineages>();
        const auto& cohort=input->native->sourceCohort()->sources();input->sourceLineages.clear();input->sourceLineages.reserve(cohort.size());
        for(const auto& source:cohort){
            if(!cyrus::editbinding::sourceRevision(current,source.id)){
                if(input->size())throw std::invalid_argument("Edit source is absent from its compatibility descriptor");
                input->sourceLineages.push_back(0);continue; // empty context sentinel
            }
            const auto id=receiverWide(source.id);auto index=lineage->find(id);
            if(!index){if(lineage->ids.size()>=cyrus::editbinding::maxSources)throw std::length_error("Edit source history is full");lineage->ids.emplace_back(id.begin(),id.end());index=unsigned(lineage->ids.size());}
            input->sourceLineages.push_back(index);
        }
        bool unresolved=false,changed=false;
        bool needsHydration=false;for(std::size_t i=0;i<l.rows.size();++i)if(!l.rows.get(i).lineage){needsHydration=true;break;}
        std::unordered_map<EditVariant,unsigned,EditVariantHash,std::equal_to<EditVariant>,ce::Allocator<std::pair<const EditVariant,unsigned>>> known;
        if(needsHydration)for(unsigned i=0;i<l.rows.size();++i){const auto& row=l.rows.get(i);if(row.lineage&&row.inputId==row.outputId)known.emplace(EditVariant{row.inputId,row.lineage},i);}
        ce::Selection discard;bool discarding=false;
        for(std::size_t i=0;i<l.rows.size();++i)if(!l.rows.get(i).lineage){
            const auto& row=l.rows.get(i);const auto found=input->incoming.find(row.inputId);
            if(found!=input->incoming.end()&&(hydrate||!authoredEdit(row))){
                const auto id=input->lineage(found->second);const auto duplicate=known.find({row.inputId,id});
                if(row.inputId==row.outputId&&duplicate!=known.end()){
                    const auto other=duplicate->second;
                    if(authoredEdit(row)&&authoredEdit(l.rows.get(other)))throw std::invalid_argument("Legacy Edit recovery has two authored histories for one source; restore the original matching scene before upgrading");
                    const auto removed=authoredEdit(row)?other:unsigned(i),kept=authoredEdit(row)?unsigned(i):other;
                    l.selection.set(kept,l.selection.get(kept)||l.selection.get(removed));discard.set(removed,true);discarding=true;
                }
                l.rows.write(i).lineage=id;changed=true;
            }
            else if(authoredEdit(row))unresolved=true;
        }
        if(discarding){ce::Blocks<EditRow> rows;ce::Selection selected;std::size_t textBytes=0;
            for(std::size_t i=0;i<l.rows.size();++i)if(!discard.get(i)){selected.set(rows.size(),l.selection.get(i));rows.append(l.rows.get(i));textBytes+=EditLayer::keyBytes(l.rows.get(i));}
            l.rows=std::move(rows);l.selection=std::move(selected);l.textBytes=textBytes;
        }
        if(changed)l.originals.reset();
        if(!unresolved)l.legacyProof.clear();
        l.lineages=std::move(lineage);l.signature=receiverWide(cyrus::editbinding::encode(merged));l.sourceAware=true;
    }else{
        if(l.sourceAware)throw std::invalid_argument("Source-aware Edit requires Cyrus Scatter 0.86.9 or later");
        if(l.signature.empty())l.signature=signature;
        else if(l.signature!=signature)l.signature=receiverWide(cyrus::receivers::mergeBinding(receiverUTF8(l.signature),text));
    }
    l.invalid=false;l.input=std::move(input);
    for(std::size_t i=0;i<l.rows.size();++i)if(l.rows.get(i).recipeLocal){auto row=l.rows.get(i);const auto source=l.source(row);if(source==UINT_MAX)continue;const auto base=l.input->matrix(source);row.delta=recipeEditInverse(base)*row.delta*base;row.recipeLocal=false;if(!finiteEditMatrix(row.delta))throw std::invalid_argument("Invalid rebound recipe transform");l.rows.write(i)=row;}
    auto originals=l.originals;std::shared_ptr<EditOriginals> writable;
    if(!originals){writable=ce::make<EditOriginals>();originals=writable;}
    if(!l.originals)for(std::size_t i=0;i<l.rows.size();++i){const auto& r=l.rows.get(i);l.observeOrder(r.order);if(r.inputId==r.outputId){
        if(!writable->variants.insert({r.inputId,r.lineage}).second)throw std::invalid_argument("Duplicate saved Edit source variant");
        const auto old=writable->order.find(r.inputId);if(old==writable->order.end())writable->order.emplace(r.inputId,r.order);else if(old->second!=r.order)throw std::invalid_argument("Inconsistent saved Edit ordering");}}
    for(unsigned i=0;i<l.input->size();++i){
        const auto id=l.input->native?editKey(*l.input->native,i):l.input->order[i];const auto lineage=l.input->lineage(i);
        if(originals->variants.count({id,lineage}))continue;
        if(!writable){writable=ce::make<EditOriginals>(*originals);originals=writable;}writable->variants.insert({id,lineage});
        EditRow row;row.savedSource=i;row.inputId=row.outputId=id;row.lineage=lineage;
        const auto order=originals->order.find(id);if(order!=originals->order.end())row.order=order->second;
        else{row.order=l.allocateOrder();writable->order.emplace(id,row.order);}l.append(row);
    }
    l.originals=std::move(originals);layer=std::move(l);
}
static ce::Vector<unsigned> activeEditOrder(const EditLayer& l){
    ce::Vector<unsigned> result;result.reserve(l.input?l.input->size():0);
    for(unsigned i=0;i<l.rows.size();++i)if(!l.rows.get(i).deleted&&l.source(l.rows.get(i))<l.input->size())result.push_back(i);
    const auto less=[&](unsigned a,unsigned b){return l.rows.get(a).order<l.rows.get(b).order;};if(!std::is_sorted(result.begin(),result.end(),less))std::sort(result.begin(),result.end(),less);
    EditKeySet seen;seen.reserve(result.size());for(auto i:result)if(!seen.insert(l.rows.get(i).outputId).second)throw std::invalid_argument("Duplicate active Edit output identity");return result;
}
