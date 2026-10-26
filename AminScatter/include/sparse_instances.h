#pragma once
#include <algorithm>
#include <cstddef>
#include <map>
#include <stdexcept>
#include <vector>

namespace cyrus {
// Immutable edits address the original source stream. Rank/select maps a
// visible ordinal to that stream without copying every unaffected matrix.
template<class Matrix> struct SparseInstances {
    std::vector<std::size_t> hidden, ranks;
    std::map<std::size_t,Matrix> transforms;
    void seal(std::size_t count) {
        std::sort(hidden.begin(),hidden.end());hidden.erase(std::unique(hidden.begin(),hidden.end()),hidden.end());
        if(!hidden.empty()&&hidden.back()>=count)throw std::out_of_range("Hidden instance exceeds source stream");
        for(const auto& item:transforms)if(item.first>=count)throw std::out_of_range("Edited instance exceeds source stream");
        ranks.resize(hidden.size());for(std::size_t i=0;i<hidden.size();++i)ranks[i]=hidden[i]-i;
    }
    std::size_t sourceIndex(std::size_t visible)const {
        return visible+std::size_t(std::upper_bound(ranks.begin(),ranks.end(),visible)-ranks.begin());
    }
    std::size_t bytes()const{return sizeof(*this)+(hidden.capacity()+ranks.capacity())*sizeof(std::size_t)+transforms.size()*(sizeof(std::pair<const std::size_t,Matrix>)+4*sizeof(void*));}
    bool operator==(const SparseInstances& other)const{return hidden==other.hidden&&transforms==other.transforms;}
};
}
