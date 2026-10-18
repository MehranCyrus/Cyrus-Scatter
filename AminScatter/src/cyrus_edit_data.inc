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
struct EditRow {EditKey inputId,outputId;unsigned savedSource=0;Matrix3 delta{1};bool deleted=false;};
static EditKey editKey(const ep::View& view,std::size_t i){const auto& r=view.at(i);if(!(r.flags&ep::Authored))return EditKey(r.identity);const auto key=view.authored(i);return EditKey(std::wstring(key.begin(),key.end()));}
static Matrix3 editMatrix(const ep::View& view,std::size_t i){Matrix3 tm(1);const auto& a=view.at(i).transform;for(int k=0;k<4;++k)tm.SetRow(k,Point3(a[k*3],a[k*3+1],a[k*3+2]));return tm;}
struct EditDerived {
    std::optional<ep::View> native;
    ce::Vector<Matrix3> matrices;
    ce::Vector<EditKey> order; // comparison route only; native IDs stay in its View
    EditIncoming incoming;
    std::size_t size()const{return native?native->size():matrices.size();}
    Matrix3 matrix(std::size_t i)const{return native?editMatrix(*native,i):matrices.at(i);}
    std::size_t attributedBytes()const{
        // Conservative per-restore attribution; the allocator ledger reports
        // unique tracked Edit bytes separately. Native stores have their own ledger.
        return sizeof(*this)+matrices.capacity()*sizeof(Matrix3)+order.capacity()*sizeof(EditKey)+incoming.bucket_count()*sizeof(void*)+
            incoming.size()*(sizeof(EditIncoming::value_type)+3*sizeof(void*))+
            (native?native->baseBytes()+native->selectionBytes():0);
    }
};
struct EditLayer {
    std::wstring signature;
    bool invalid=false,active=true,published=false,viewportVisible=true;
    ce::Blocks<EditRow> rows;
    ce::Selection selection;
    std::shared_ptr<const EditDerived> input;
    std::shared_ptr<const EditKeySet> originals,publishedIDs;
    std::size_t textBytes=0;
    static std::size_t keyBytes(const EditRow& row){std::size_t bytes=0;for(const auto* id:{&row.inputId,&row.outputId})if(id->authored)bytes+=sizeof(EditText)+id->authored->capacity()*sizeof(wchar_t);return bytes;}
    void append(const EditRow& row){if(rows.size()>=10000000)throw std::length_error("Saved Edit record limit exceeded");rows.append(row);textBytes+=keyBytes(row);}
    unsigned source(const EditRow& r)const{if(!input)return std::numeric_limits<unsigned>::max();auto found=input->incoming.find(r.inputId);return found==input->incoming.end()?std::numeric_limits<unsigned>::max():found->second;}
    bool shown(const EditRow& r)const{return viewportVisible&&!r.deleted&&input&&source(r)<input->size()&&(!published||(publishedIDs&&publishedIDs->count(r.outputId)>0));}
    Matrix3 matrix(const EditRow& r)const{return input->matrix(source(r))*r.delta;}
};
static std::size_t editAttributedBytes(const std::map<int,EditLayer>& layers){
    std::size_t total=sizeof(layers);
    for(const auto& [key,l]:layers){(void)key;total+=sizeof(l)+l.signature.capacity()*sizeof(wchar_t)+l.rows.attributedBytes()+l.selection.attributedBytes();
        if(l.input)total+=l.input->attributedBytes();
        for(const auto* set:{l.originals.get(),l.publishedIDs.get()})if(set)total+=sizeof(*set)+set->bucket_count()*sizeof(void*)+set->size()*(sizeof(EditKey)+3*sizeof(void*));
        total+=l.textBytes;
    }return total;
}
// Artist history owns authored values only. The current evaluated input and
// publication belong to the controller/transaction and must not be duplicated
// or kept alive merely because a sparse Edit command is in Undo.
static std::map<int,EditLayer> editAuthoredState(const std::map<int,EditLayer>& layers){
    auto result=layers;
    for(auto& [key,l]:result){(void)key;l.input.reset();l.originals.reset();l.publishedIDs.reset();}
    return result;
}
static std::map<int,EditLayer> editRestoreState(const std::map<int,EditLayer>& authored,const std::map<int,EditLayer>& current){
    auto result=authored;
    for(auto& [key,l]:result){const auto found=current.find(key);if(found!=current.end()){
        l.input=found->second.input;l.publishedIDs=found->second.publishedIDs;
        l.published=found->second.published;l.viewportVisible=found->second.viewportVisible;l.active=found->second.active;
    }}return result;
}
static std::size_t editHistoryBytes(const std::map<int,EditLayer>& a,const std::map<int,EditLayer>& b){
    std::size_t bytes=sizeof(a)+sizeof(b);
    for(const auto& [key,l]:a){const auto found=b.find(key);const EditLayer empty;const auto& other=found==b.end()?empty:found->second;
        bytes+=2*sizeof(EditLayer)+l.signature.capacity()*sizeof(wchar_t)+other.signature.capacity()*sizeof(wchar_t);
        bytes+=std::max(l.rows.changedBytes(other.rows),other.rows.changedBytes(l.rows));
        bytes+=std::max(l.selection.changedBytes(other.selection),other.selection.changedBytes(l.selection));
        // Shared authored key text is a small extra conservative attribution.
        bytes+=std::max(l.textBytes,other.textBytes);
    }
    for(const auto& [key,l]:b)if(!a.count(key))bytes+=sizeof(l)+l.signature.capacity()*sizeof(wchar_t)+l.rows.attributedBytes()+l.selection.attributedBytes()+l.textBytes;
    return bytes;
}
