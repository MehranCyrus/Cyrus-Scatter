#pragma once
#include <array>
#include <atomic>
#include <cstdint>
#include <limits>
#include <memory>
#include <stdexcept>
#include <vector>
#include "native_fault_qualification.h"

// CS Edit's host-thread copy-on-write storage. Snapshots share the table and
// unchanged blocks. Read access never detaches; mutation is explicit.
namespace cyrus::edit {
struct Memory {std::uint64_t live=0,peak=0,total=0,allocations=0;};
inline std::atomic<std::uint64_t> liveBytes{0},peakBytes{0},totalBytes{0},allocations{0};
inline Memory memory() noexcept{return {liveBytes.load(),peakBytes.load(),totalBytes.load(),allocations.load()};}
template<class T> struct Allocator {
    using value_type=T;
    Allocator() noexcept=default;
    template<class U> Allocator(const Allocator<U>&) noexcept{}
    T* allocate(std::size_t n){
        cyrus::owned::fault(5);
        if(n>std::numeric_limits<std::size_t>::max()/sizeof(T))throw std::bad_array_new_length();
        auto* p=std::allocator<T>{}.allocate(n);const auto bytes=n*sizeof(T);
        const auto live=liveBytes.fetch_add(bytes)+bytes;totalBytes.fetch_add(bytes);allocations.fetch_add(1);
        auto peak=peakBytes.load();while(peak<live&&!peakBytes.compare_exchange_weak(peak,live)){}
        return p;
    }
    void deallocate(T* p,std::size_t n)noexcept{liveBytes.fetch_sub(n*sizeof(T));std::allocator<T>{}.deallocate(p,n);}
    template<class U> bool operator==(const Allocator<U>&)const noexcept{return true;}
    template<class U> bool operator!=(const Allocator<U>&)const noexcept{return false;}
};
template<class T,class... A> std::shared_ptr<T> make(A&&... a){return std::allocate_shared<T>(Allocator<T>{},std::forward<A>(a)...);}
template<class T> using Vector=std::vector<T,Allocator<T>>;

template<class T,std::size_t Width=128> class Blocks {
    static_assert(Width>0);
    struct Block{std::array<T,Width> values{};};
    struct Table{Vector<std::shared_ptr<Block>> blocks;std::size_t count=0;};
    std::shared_ptr<Table> table_;
    void writable(){if(!table_)table_=make<Table>();else if(table_.use_count()!=1)table_=make<Table>(*table_);}
public:
    std::size_t size()const noexcept{return table_?table_->count:0;}
    const T& get(std::size_t i)const{if(i>=size())throw std::out_of_range("Edit block index");return table_->blocks[i/Width]->values[i%Width];}
    T& write(std::size_t i){
        if(i>=size())throw std::out_of_range("Edit block index");writable();auto& block=table_->blocks[i/Width];
        if(block.use_count()!=1)block=make<Block>(*block);return block->values[i%Width];
    }
    void append(const T& value){
        writable();const auto i=table_->count;
        if(i%Width==0){auto block=make<Block>();block->values[0]=value;table_->blocks.push_back(std::move(block));}
        else {auto& block=table_->blocks[i/Width];if(block.use_count()!=1)block=make<Block>(*block);block->values[i%Width]=value;}
        ++table_->count;
    }
    // Conservative snapshot attribution, distinct from the unique allocator
    // ledger. Shared blocks may be attributed to multiple restore records.
    std::size_t attributedBytes()const noexcept{return table_?sizeof(Table)+table_->blocks.capacity()*sizeof(std::shared_ptr<Block>)+table_->blocks.size()*sizeof(Block):0;}
    // Incremental retention relative to another authored state. Blocks shared
    // with that state are not Undo-only memory and are counted by its owner.
    std::size_t changedBytes(const Blocks& other)const noexcept{
        if(table_==other.table_||!table_)return 0;
        std::size_t bytes=sizeof(Table)+table_->blocks.capacity()*sizeof(std::shared_ptr<Block>);
        for(std::size_t i=0;i<table_->blocks.size();++i)
            if(!other.table_||i>=other.table_->blocks.size()||table_->blocks[i]!=other.table_->blocks[i])bytes+=sizeof(Block);
        return bytes;
    }
};
class Selection {
    Blocks<std::uint64_t,64> words_;
public:
    bool get(std::size_t i)const{return i/64<words_.size()&&(words_.get(i/64)&(std::uint64_t(1)<<(i%64)))!=0;}
    void set(std::size_t i,bool value){
        if(get(i)==value)return;
        while(words_.size()<=i/64)words_.append(0);
        auto& word=words_.write(i/64);const auto mask=std::uint64_t(1)<<(i%64);if(value)word|=mask;else word&=~mask;
    }
    void clear()noexcept{words_=Blocks<std::uint64_t,64>{};}
    std::size_t attributedBytes()const noexcept{return words_.attributedBytes();}
    std::size_t changedBytes(const Selection& other)const noexcept{return words_.changedBytes(other.words_);}
};
}
