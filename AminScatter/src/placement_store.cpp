#include "placement_store.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <limits>
#include <stdexcept>
#include <unordered_map>
#include <utility>

namespace cyrus::placements {
namespace {
std::atomic<std::uint64_t> serial{0},live{0},peak{0},total{0},allocations{0},blocks{0},stores{0},selections{0},readbacks{0};
std::uint64_t next() {
    auto n=serial.load(std::memory_order_relaxed);
    for(;;) {
        if(n==std::uint64_t(std::numeric_limits<std::int64_t>::max()))throw std::overflow_error("Placement session identity exhausted");
        if(serial.compare_exchange_weak(n,n+1,std::memory_order_relaxed))return n+1;
    }
}
void allocated(std::size_t n) noexcept {
    const auto now=live.fetch_add(n,std::memory_order_relaxed)+n;
    auto high=peak.load(std::memory_order_relaxed);
    while(now>high&&!peak.compare_exchange_weak(high,now,std::memory_order_relaxed)){}
    total.fetch_add(n,std::memory_order_relaxed);allocations.fetch_add(1,std::memory_order_relaxed);blocks.fetch_add(1,std::memory_order_relaxed);
}
// Narrow instrumentation of placement-owned standard vectors. Allocation and
// deallocation still use std::allocator; this is not a replacement heap/budget.
// Hooks count capacity and real reallocation overlap once per allocation.
template<class T> struct Allocator {
    using value_type=T;
    Allocator()=default;template<class U> Allocator(const Allocator<U>&) noexcept {}
    T* allocate(std::size_t n) {
        if(n>std::numeric_limits<std::size_t>::max()/sizeof(T))throw std::bad_array_new_length();
        auto* p=std::allocator<T>{}.allocate(n);allocated(n*sizeof(T));return p;
    }
    void deallocate(T* p,std::size_t n) noexcept {
        live.fetch_sub(n*sizeof(T),std::memory_order_relaxed);blocks.fetch_sub(1,std::memory_order_relaxed);
        std::allocator<T>{}.deallocate(p,n);
    }
    template<class U> bool operator==(const Allocator<U>&) const noexcept {return true;}
    template<class U> bool operator!=(const Allocator<U>&) const noexcept {return false;}
};
template<class T> using Buffer=std::vector<T,Allocator<T>>;
struct Text {std::uint32_t offset=0,length=0;};
void check(bool value,const char* message) {if(!value)throw std::invalid_argument(message);}
template<class T> void reserve(Buffer<T>& buffer,std::size_t required,std::size_t bound) {
    check(required<=bound,"Native placement buffer exceeds bounds");
    if(required>buffer.capacity())buffer.reserve(std::max(required,std::min(bound,buffer.capacity()*2+8)));
}
void validate(const Record& r,Stage stage,std::uint32_t sources,std::size_t identities) {
    check(r.reserved==0&&(r.flags&~std::uint32_t(Authored|Protected))==0,"Unsupported native placement flags");
    check(r.source>0&&r.source<=sources,"Native placement source is outside its frozen table");
    check(r.face>0&&r.face<=std::uint32_t(std::numeric_limits<int>::max()),"Invalid native placement face");
    check(r.receiver<128,"Invalid native receiver slot");
    check(r.band<=std::uint64_t(std::numeric_limits<std::int64_t>::max()),"Invalid native Band owner");
    for(auto v:r.transform)check(std::isfinite(v),"Nonfinite native placement transform");
    for(auto v:r.bary)check(std::isfinite(v),"Nonfinite native placement anchor");
    if(r.flags&Authored)check(r.identity<identities,"Missing authored placement identity");
    else check(r.identity<=std::uint64_t(std::numeric_limits<std::int64_t>::max()),"Invalid generated placement identity");
    check(stage==Stage::Edited||r.flags==0,"Raw native candidates cannot contain authored Edit state");
}
}

struct View::Data {
    const std::uint64_t owner,generation;
    const Stage stage;
    const std::uint32_t sources;
    const std::shared_ptr<const SourceCohort> sourceCohort;
    const std::shared_ptr<const ReceiverCohort> receiverCohort;
    Buffer<Record> rows;
    Buffer<Text> identities;
    Buffer<char> text;
    Data(std::uint64_t o,Stage s,std::uint32_t n,std::shared_ptr<const SourceCohort> cohort,std::shared_ptr<const ReceiverCohort> receivers):owner(o),generation(next()),stage(s),sources(n),sourceCohort(std::move(cohort)),receiverCohort(std::move(receivers)){++stores;}
    ~Data(){--stores;}
};
struct View::Selection {
    const std::uint64_t id=next();
    Buffer<std::uint32_t> indices;
    Selection(){++selections;}
    ~Selection(){--selections;}
};
struct Builder::Impl {
    std::shared_ptr<View::Data> data;
    std::shared_ptr<const PreparationReceipt> preparation;
    // Construction-only interning scratch. It is released before publication.
    std::unordered_map<std::string,std::uint32_t> intern;
    explicit Impl(std::shared_ptr<View::Data> p):data(std::move(p)){}
};

Metrics metrics() noexcept {return {live.load(),peak.load(),total.load(),allocations.load(),blocks.load(),stores.load(),selections.load(),readbacks.load()};}
void noteReadback(std::size_t count) noexcept {readbacks.fetch_add(count,std::memory_order_relaxed);}
std::uint64_t newOwner(){return next();}
View::View(std::shared_ptr<const Data> d,std::shared_ptr<const Selection> s):data_(std::move(d)),selection_(std::move(s)),stage_(data_->stage),view_(selection_?selection_->id:data_->generation){}
void View::valid() const {if(!data_)throw std::logic_error("Moved-from native placement view");}
std::size_t View::size() const {valid();return selection_?selection_->indices.size():data_->rows.size();}
Stage View::stage() const {valid();return stage_;}
std::uint32_t View::sources() const {valid();return data_->sources;}
const std::shared_ptr<const SourceCohort>& View::sourceCohort() const {valid();return data_->sourceCohort;}
const std::shared_ptr<const ReceiverCohort>& View::receiverCohort() const {valid();return data_->receiverCohort;}
Token View::token() const {valid();return {data_->owner,data_->generation,view_};}
void View::require(Token t) const {check(token()==t,"Stale or foreign native placement token");}
std::size_t View::physical(std::size_t i) const {if(i>=size())throw std::out_of_range("Native placement index");return selection_?selection_->indices[i]:i;}
const Record& View::at(std::size_t i) const {const auto index=physical(i);return data_->rows[index];}
std::string_view View::authored(std::size_t i) const {
    const auto& r=at(i);check((r.flags&Authored)!=0&&r.identity<data_->identities.size(),"Native record has no authored identity in this generation");
    const auto t=data_->identities[std::size_t(r.identity)];return {data_->text.data()+t.offset,t.length};
}
std::string View::textIdentity(std::size_t i) const {
    check(stage()==Stage::Edited,"Raw candidate identity is numeric");const auto& r=at(i);
    return (r.flags&Authored)?std::string(authored(i)):"c:"+std::to_string(r.identity);
}
std::size_t View::baseBytes() const {valid();return data_->rows.capacity()*sizeof(Record)+data_->identities.capacity()*sizeof(Text)+data_->text.capacity();}
std::size_t View::selectionBytes() const {valid();return selection_?selection_->indices.capacity()*sizeof(std::uint32_t):0;}
std::vector<std::uint32_t> View::sourceUsage() const {
    std::vector<std::uint32_t> result(sources(),0);
    for(std::size_t i=0;i<size();++i)++result[at(i).source-1];return result;
}
std::vector<Record> View::page(std::size_t offset,std::size_t count,Token t) const {
    require(t);check(count<=maxPage,"Native placement page exceeds 500 records");
    check(offset<=size()&&count<=size()-offset,"Native placement page is outside its generation");
    std::vector<Record> result;result.reserve(count);
    for(std::size_t i=0;i<count;++i)result.push_back(at(offset+i));
    noteReadback(count);return result;
}
View View::select(const std::vector<std::uint32_t>& indices) const {
    valid();check(indices.size()<=size(),"Native selection exceeds its base");
    if(indices.empty()){auto result=Builder(data_->owner,stage(),sources(),0,sourceCohort(),receiverCohort()).freeze();result.preparation_=preparation_;return result;}
    auto selected=std::make_shared<Selection>();selected->indices.reserve(indices.size());
    // Scratch is bounded by the selected view's logical population, not by IDs.
    std::vector<bool> used(size(),false);
    for(auto i:indices){check(i<size()&&!used[i],"Duplicate or invalid native selection index");used[i]=true;selected->indices.push_back(static_cast<std::uint32_t>(physical(i)));}
    View result(data_,std::move(selected));result.stage_=stage_;result.preparation_=preparation_;return result;
}
View View::edited() const {
    valid();if(stage_==Stage::Edited)return *this;
    View result=*this;result.stage_=Stage::Edited;result.view_=next();return result;
}
View View::prepared(const std::string& key,const std::string& binding) const {
    valid();check(stage()==Stage::Edited&&sourceCohort(),"Preparation receipt requires edited rows with frozen source correspondence");
    check(!key.empty()&&key.size()<=8u*1024*1024&&!binding.empty()&&binding.size()<=8u*1024*1024,"Invalid preparation key/binding");
    if(preparation_){check(preparation_->key==key&&preparation_->binding==binding,"Cannot relabel an existing prepared generation");return *this;}
    View result=*this;result.preparation_=std::make_shared<const PreparationReceipt>(key,binding);result.view_=next();return result;
}
View View::compact() const {return Builder(*this).freeze();}

Builder::Builder(std::uint64_t owner,Stage s,std::uint32_t sources,std::size_t reserve,std::shared_ptr<const SourceCohort> cohort,std::shared_ptr<const ReceiverCohort> receivers) {
    check(owner>0&&owner<=std::uint64_t(std::numeric_limits<std::int64_t>::max()),"Native placement owner is missing or invalid");check(s==Stage::Candidates||s==Stage::Edited,"Invalid native placement stage");
    check(sources<=maxSources&&reserve<=maxRecords,"Native placement request exceeds existing bounds");
    check(!cohort||(cohort->owner()==owner&&cohort->sources().size()==sources),"Placement source correspondence owner/count mismatch");
    check(!receivers||receivers->owner()==owner,"Placement receiver provenance owner differs");
    impl_=std::make_unique<Impl>(std::make_shared<View::Data>(owner,s,sources,std::move(cohort),std::move(receivers)));impl_->data->rows.reserve(reserve);
}
Builder::Builder(const View& view):Builder(view.token().owner,view.stage(),view.sources(),view.size(),view.sourceCohort(),view.receiverCohort()) {
    for(std::size_t i=0;i<view.size();++i){auto r=view.at(i);if(r.flags&Authored)appendAuthored(r,view.authored(i));else appendGenerated(r);}
    impl_->preparation=view.preparation();
}
Builder::~Builder()=default;
Builder::Builder(Builder&&) noexcept=default;Builder& Builder::operator=(Builder&&) noexcept=default;
void Builder::active() const {if(!impl_)throw std::logic_error("Frozen or moved-from native placement builder");}
std::size_t Builder::size() const {active();return impl_->data->rows.size();}
Record Builder::get(std::size_t i) const {active();return impl_->data->rows.at(i);}
void Builder::appendGenerated(Record r) {
    active();impl_->preparation.reset();auto& d=*impl_->data;check(d.rows.size()<maxRecords,"Native placement candidate limit exceeded");
    check((r.flags&Authored)==0,"Generated append cannot reference an authored identity");validate(r,d.stage,d.sources,d.identities.size());reserve(d.rows,d.rows.size()+1,maxRecords);d.rows.push_back(r);
}
void Builder::appendAuthored(Record r,std::string_view id) {
    active();impl_->preparation.reset();
    active();auto& d=*impl_->data;check(d.stage==Stage::Edited&&d.rows.size()<maxRecords,"Authored native placement requires a bounded edited generation");
    check(!id.empty()&&id.size()<=maxIdentity,"Authored placement identity must contain 1..256 ASCII bytes");
    for(unsigned char c:id)check(c>0&&c<=127,"Authored placement identity must be an exact ASCII key");
    // Validate before any table mutation, including when adding a new identity.
    r.flags|=Authored;r.identity=0;validate(r,d.stage,d.sources,1);
    const auto found=impl_->intern.find(std::string(id));
    if(found!=impl_->intern.end()){r.identity=found->second;d.rows.push_back(r);return;}
    const auto index=static_cast<std::uint32_t>(d.identities.size());
    const auto offset=d.text.size();
    check(offset<=std::numeric_limits<std::uint32_t>::max()-id.size()-1,"Authored placement text overflow");
    // Reserves/lookup may throw, but never modify a frozen predecessor. Seal
    // membership only after all vector capacity needed for this append exists.
    reserve(d.text,offset+id.size()+1,maxRecords*(maxIdentity+1));reserve(d.identities,std::size_t(index)+1,maxRecords);reserve(d.rows,d.rows.size()+1,maxRecords);
    const auto inserted=impl_->intern.emplace(std::string(id),index);
    if(!inserted.second)throw std::logic_error("Authored placement interning changed during append");
    d.text.insert(d.text.end(),id.begin(),id.end());d.text.push_back('\0');
    d.identities.push_back({static_cast<std::uint32_t>(offset),static_cast<std::uint32_t>(id.size())});
    r.identity=index;d.rows.push_back(r);
}
void Builder::replace(std::size_t i,Record r) {
    active();impl_->preparation.reset();auto& d=*impl_->data;if(i>=d.rows.size())throw std::out_of_range("Native placement replacement index");
    validate(r,d.stage,d.sources,d.identities.size());d.rows[i]=r;
}
View Builder::freeze() {
    active();std::shared_ptr<const View::Data> frozen=impl_->data;auto preparation=impl_->preparation;impl_.reset();View result(std::move(frozen));result.preparation_=std::move(preparation);return result;
}
}
