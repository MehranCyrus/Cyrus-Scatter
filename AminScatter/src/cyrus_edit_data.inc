namespace ce=cyrus::edit;
namespace ep=cyrus::placements;
using EditText=std::basic_string<wchar_t,std::char_traits<wchar_t>,ce::Allocator<wchar_t>>;
struct EditKey {
    std::uint64_t candidate=0;
    std::shared_ptr<const EditText> authored;
    EditKey()=default;
    explicit EditKey(std::uint64_t id):candidate(id){}
    explicit EditKey(const std::wstring& text){
        bool generated=text.size()>=3&&text[0]==L'c'&&text[1]==L':'&&(text.size()==3||text[2]!=L'0');
        std::uint64_t id=0;
        if(generated)for(std::size_t i=2;i<text.size();++i){
            const auto c=text[i];if(c<L'0'||c>L'9'||id>(std::uint64_t(INT64_MAX)-unsigned(c-L'0'))/10){generated=false;break;}
            id=id*10+unsigned(c-L'0');
        }
        if(generated)candidate=id;else authored=ce::make<EditText>(text.begin(),text.end());
    }
    std::wstring text()const{return authored?std::wstring(authored->begin(),authored->end()):L"c:"+std::to_wstring(candidate);}
    bool operator==(const EditKey& b)const noexcept{return bool(authored)==bool(b.authored)&&(authored?*authored==*b.authored:candidate==b.candidate);}
    bool operator!=(const EditKey& b)const noexcept{return !(*this==b);}
};
struct EditKeyHash{std::size_t operator()(const EditKey& k)const noexcept{return k.authored?std::hash<std::wstring_view>{}({k.authored->data(),k.authored->size()}):std::hash<std::uint64_t>{}(k.candidate);}};
using EditKeySet=std::unordered_set<EditKey,EditKeyHash,std::equal_to<EditKey>,ce::Allocator<EditKey>>;
using EditIncoming=std::unordered_map<EditKey,unsigned,EditKeyHash,std::equal_to<EditKey>,ce::Allocator<std::pair<const EditKey,unsigned>>>;
// savedSource remains a legacy candidate-row index, never a model identity.
// Variants of one base ID share order, but have independent saved source lineage.
struct EditRow {EditKey inputId,outputId;unsigned savedSource=0,lineage=0;std::uint64_t order=0;Matrix3 delta{1};bool deleted=false,recipeLocal=false;};
static bool authoredEdit(const EditRow& r){return r.deleted||r.inputId!=r.outputId||hasEditTransform(r.delta);}
struct EditVariant {EditKey id;unsigned lineage=0;bool operator==(const EditVariant& b)const noexcept{return id==b.id&&lineage==b.lineage;}};
struct EditVariantHash{std::size_t operator()(const EditVariant& v)const noexcept{return EditKeyHash{}(v.id)^(std::size_t(v.lineage)*0x9e3779b9u);}};
struct EditOriginals {
    std::unordered_set<EditVariant,EditVariantHash,std::equal_to<EditVariant>,ce::Allocator<EditVariant>> variants;
    std::unordered_map<EditKey,std::uint64_t,EditKeyHash,std::equal_to<EditKey>,ce::Allocator<std::pair<const EditKey,std::uint64_t>>> order;
    std::size_t attributedBytes()const{return sizeof(*this)+(variants.bucket_count()+order.bucket_count())*sizeof(void*)+variants.size()*(sizeof(EditVariant)+3*sizeof(void*))+order.size()*(sizeof(EditKey)+sizeof(std::uint64_t)+3*sizeof(void*));}
};
struct EditLineages {
    ce::Vector<EditText> ids;
    unsigned find(std::wstring_view id)const{for(unsigned i=0;i<ids.size();++i)if(std::wstring_view(ids[i].data(),ids[i].size())==id)return i+1;return 0;}
    std::size_t attributedBytes()const{std::size_t n=sizeof(*this)+ids.capacity()*sizeof(EditText);for(const auto& id:ids)n+=id.capacity()*sizeof(wchar_t);return n;}
};
static EditKey editKey(const ep::View& view,std::size_t i){const auto& r=view.at(i);if(!(r.flags&ep::Authored))return EditKey(r.identity);const auto key=view.authored(i);return EditKey(std::wstring(key.begin(),key.end()));}
static Matrix3 editMatrix(const ep::View& view,std::size_t i){Matrix3 tm(1);const auto& a=view.at(i).transform;for(int k=0;k<4;++k)tm.SetRow(k,Point3(a[k*3],a[k*3+1],a[k*3+2]));return tm;}
struct EditDerived {
    std::optional<ep::View> native;
    ce::Vector<Matrix3> matrices;
    ce::Vector<EditKey> order; // comparison route only; native IDs stay in its View
    EditIncoming incoming;
    ce::Vector<unsigned> sourceLineages; // bounded SourceCohort ordinal -> lineage
    ce::Vector<EditText> sourceIDs;
    std::size_t size()const{return native?native->size():matrices.size();}
    Matrix3 matrix(std::size_t i)const{return native?editMatrix(*native,i):matrices.at(i);}
    unsigned lineage(std::size_t i)const{if(!native||sourceLineages.empty())return 0;const auto source=native->at(i).source;return source&&source<=sourceLineages.size()?sourceLineages[source-1]:0;}
    std::size_t attributedBytes()const{
        // Conservative per-restore attribution; the allocator ledger reports
        // unique tracked Edit bytes separately. Native stores have their own ledger.
        std::size_t texts=sourceIDs.capacity()*sizeof(EditText);for(const auto& id:sourceIDs)texts+=id.capacity()*sizeof(wchar_t);
        return sizeof(*this)+texts+matrices.capacity()*sizeof(Matrix3)+order.capacity()*sizeof(EditKey)+incoming.bucket_count()*sizeof(void*)+
            incoming.size()*(sizeof(EditIncoming::value_type)+3*sizeof(void*))+
            sourceLineages.capacity()*sizeof(unsigned)+(native?native->baseBytes()+native->selectionBytes():0);
    }
};
// Same version-1 palette and resolver semantics as preview_palette.inc. Its
// small storage uses the Edit allocator; no renderer resources are owned here.
struct EditPalette {
    int mode=1;bool requireBand=false;
    ce::Vector<Point3> sourceColors;ce::Vector<std::uint64_t> bandIDs;
    std::array<Point3,65> bandColors{};
    EditPalette(){bandColors.fill(Point3(0,0,0));}
    Point3 color(unsigned source,std::uint64_t band)const{
        if(mode==3){const auto found=std::lower_bound(bandIDs.begin(),bandIDs.end(),band);const auto slot=found!=bandIDs.end()&&*found==band?1+std::size_t(found-bandIDs.begin()):0;return bandColors[slot];}
        return source&&source<=sourceColors.size()?sourceColors[source-1]:Point3(1.f,.55f,0.f);
    }
    std::size_t attributedBytes()const{return sizeof(*this)+sourceColors.capacity()*sizeof(Point3)+bandIDs.capacity()*sizeof(std::uint64_t);}
};
struct EditPresentation {
    std::shared_ptr<const EditDerived> final;
    std::shared_ptr<const EditPalette> palette;
    std::size_t attributedBytes()const{return sizeof(*this)+(final?final->attributedBytes():0)+(palette?palette->attributedBytes():0);}
};
// The committed local input and COW authored blocks prove the downstream
// transform used by a gesture. Sharing blocks adds no second matrix array.
// These references are derived publication state, never an Undo payload.
struct EditPublishedLocal {
    std::shared_ptr<const EditDerived> input;
    ce::Blocks<EditRow> rows;
    std::size_t attributedBytes()const{return sizeof(*this)+rows.attributedBytes()+(input?input->attributedBytes():0);}
};
struct EditLayer {
    std::wstring signature;
    std::wstring legacyProof;
    bool invalid=false,active=true,published=false,viewportVisible=true;
    bool sourceAware=false,recipeUnbound=false;
    std::uint64_t nextOrder=0;
    std::uint64_t allocateOrder(){if(nextOrder>=std::uint64_t(INT64_MAX))throw std::length_error("Edit instance ordering limit exceeded");return nextOrder++;}
    void observeOrder(std::uint64_t order){if(order>=std::uint64_t(INT64_MAX))throw std::invalid_argument("Invalid saved Edit order");nextOrder=std::max(nextOrder,order+1);}
    ce::Blocks<EditRow> rows;
    ce::Selection selection;
    std::shared_ptr<const EditDerived> input;
    std::shared_ptr<const EditOriginals> originals;
    std::shared_ptr<const EditLineages> lineages;
    std::shared_ptr<const EditPresentation> presentation;
    std::shared_ptr<const EditPublishedLocal> publishedLocal;
    bool rendererManaged=false;
    std::shared_ptr<const EditPresentation> displayedPresentation;
    std::shared_ptr<const EditPublishedLocal> displayedLocal;
    const std::shared_ptr<const EditPresentation>& feedback()const{return rendererManaged?displayedPresentation:presentation;}
    const std::shared_ptr<const EditPublishedLocal>& feedbackLocal()const{return rendererManaged?displayedLocal:publishedLocal;}
    bool feedbackPending()const{
        if(!rendererManaged)return false;
        const auto& shown=feedback();
        if(!presentation||!presentation->final)return false;
        if(!shown||!shown->final)return true;
        if(presentation->final==shown->final)return false;
        return !presentation->final->native||!shown->final->native||!(presentation->final->native->token()==shown->final->native->token());
    }
    std::size_t textBytes=0;
    static std::size_t keyBytes(const EditRow& row){std::size_t bytes=0;for(const auto* id:{&row.inputId,&row.outputId})if(id->authored)bytes+=sizeof(EditText)+id->authored->capacity()*sizeof(wchar_t);return bytes;}
    void append(const EditRow& row){if(rows.size()>=10000000)throw std::length_error("Saved Edit record limit exceeded");rows.append(row);textBytes+=keyBytes(row);}
    unsigned sourceIn(const EditRow& r,const std::shared_ptr<const EditDerived>& data)const{
        if(!data)return UINT_MAX;const auto found=data->incoming.find(r.inputId);if(found==data->incoming.end())return UINT_MAX;
        if(sourceAware){if(!r.lineage||!lineages||r.lineage>lineages->ids.size()||!data->native)return UINT_MAX;
            const auto source=data->native->at(found->second).source;
            if(!source||source>data->sourceIDs.size()||data->sourceIDs[source-1]!=lineages->ids[r.lineage-1])return UINT_MAX;}
        return found->second;
    }
    unsigned source(const EditRow& r)const{return sourceIn(r,input);}
    unsigned presented(const EditRow& r)const{
        const auto& displayed=feedback();if(!displayed||!displayed->final)return UINT_MAX;const auto& final=*displayed->final;const auto found=final.incoming.find(r.outputId);if(found==final.incoming.end())return UINT_MAX;
        if(sourceAware){if(!r.lineage||!lineages||r.lineage>lineages->ids.size()||!final.native)return UINT_MAX;
            const auto& record=final.native->at(found->second);
            if(!record.source||record.source>final.sourceIDs.size()||final.sourceIDs[record.source-1]!=lineages->ids[r.lineage-1])return UINT_MAX;}
        return found->second;
    }
    bool shown(const EditRow& r)const{return viewportVisible&&(published?presented(r)!=UINT_MAX:!r.deleted&&input&&source(r)<input->size());}
    Matrix3 matrix(const EditRow& r)const{return input->matrix(source(r))*r.delta;}
    Matrix3 displayMatrix(const EditRow& r)const{const auto at=presented(r);return published&&at!=UINT_MAX?feedback()->final->matrix(at):matrix(r);}
    Point3 color(const EditRow& r)const{const auto at=presented(r);const auto& displayed=feedback();if(at!=UINT_MAX&&displayed->palette&&displayed->final->native){const auto& p=displayed->final->native->at(at);return displayed->palette->color(p.source,p.band);}return Point3(1.f,.55f,0.f);}
    bool hasAuthored()const{for(std::size_t i=0;i<rows.size();++i)if(authoredEdit(rows.get(i)))return true;return false;}
};
static std::size_t editAttributedBytes(const std::map<int,EditLayer>& layers){
    std::size_t total=sizeof(layers);
    for(const auto& [key,l]:layers){(void)key;total+=sizeof(l)+(l.signature.capacity()+l.legacyProof.capacity())*sizeof(wchar_t)+l.rows.attributedBytes()+l.selection.attributedBytes();
        if(l.input)total+=l.input->attributedBytes();
        if(l.originals)total+=l.originals->attributedBytes();
        if(l.lineages)total+=l.lineages->attributedBytes();
        if(l.presentation)total+=l.presentation->attributedBytes();
        if(l.publishedLocal)total+=l.publishedLocal->attributedBytes();
        if(l.displayedPresentation&&l.displayedPresentation!=l.presentation)total+=l.displayedPresentation->attributedBytes();
        if(l.displayedLocal&&l.displayedLocal!=l.publishedLocal)total+=l.displayedLocal->attributedBytes();
        total+=l.textBytes;
    }return total;
}
// Artist history owns authored values only. The current evaluated input and
// publication belong to the controller/transaction and must not be duplicated
// or kept alive merely because a sparse Edit command is in Undo.
static std::map<int,EditLayer> editAuthoredState(const std::map<int,EditLayer>& layers){
    auto result=layers;
    for(auto& [key,l]:result){(void)key;l.input.reset();l.originals.reset();l.presentation.reset();l.publishedLocal.reset();l.displayedPresentation.reset();l.displayedLocal.reset();l.rendererManaged=false;}
    return result;
}
static std::map<int,EditLayer> editRestoreState(const std::map<int,EditLayer>& authored,const std::map<int,EditLayer>& current){
    auto result=authored;
    for(auto& [key,l]:result){const auto found=current.find(key);if(found!=current.end()){
        l.input=found->second.input;l.presentation=found->second.presentation;l.publishedLocal=found->second.publishedLocal;
        l.displayedPresentation=found->second.displayedPresentation;l.displayedLocal=found->second.displayedLocal;l.rendererManaged=found->second.rendererManaged;
        l.published=found->second.published;l.viewportVisible=found->second.viewportVisible;l.active=found->second.active;
    }}return result;
}
static std::size_t editHistoryBytes(const std::map<int,EditLayer>& a,const std::map<int,EditLayer>& b){
    std::size_t bytes=sizeof(a)+sizeof(b);
    for(const auto& [key,l]:a){const auto found=b.find(key);const EditLayer empty;const auto& other=found==b.end()?empty:found->second;
        bytes+=2*sizeof(EditLayer)+(l.signature.capacity()+other.signature.capacity()+l.legacyProof.capacity()+other.legacyProof.capacity())*sizeof(wchar_t);
        if(l.lineages!=other.lineages)bytes+=(l.lineages?l.lineages->attributedBytes():0)+(other.lineages?other.lineages->attributedBytes():0);
        bytes+=std::max(l.rows.changedBytes(other.rows),other.rows.changedBytes(l.rows));
        bytes+=std::max(l.selection.changedBytes(other.selection),other.selection.changedBytes(l.selection));
        // Shared authored key text is a small extra conservative attribution.
        bytes+=std::max(l.textBytes,other.textBytes);
    }
    for(const auto& [key,l]:b)if(!a.count(key))bytes+=sizeof(l)+(l.signature.capacity()+l.legacyProof.capacity())*sizeof(wchar_t)+l.rows.attributedBytes()+l.selection.attributedBytes()+l.textBytes+(l.lineages?l.lineages->attributedBytes():0);
    return bytes;
}
