#pragma once
#include <cstddef>
#include <stdexcept>
#include <map>

namespace Clipper2Lib {
// Cyrus addition: explicit optional operation context. No global/TLS allocator
// changes. Cumulative storage admission is intentionally more conservative than
// peak live storage: input, derived objects, vector growth/copies and sort scratch
// are charged before their producing operation. No credits during an operation.
struct OperationBudget {
    std::map<void*,void(*)(void*)> outstanding;
    std::size_t bytes=0,work=0,byteLimit,workLimit;
    OperationBudget(std::size_t memory,std::size_t visits):byteLimit(memory),workLimit(visits){storage(2u*1024u*1024u);}
    ~OperationBudget()noexcept{
        // Linked points are retired normally by Clipper. A budget/allocation
        // exception may leave a just-produced point not linked to an OutRec;
        // those trivial points remain owned here and cannot leak on unwind.
        while(!outstanding.empty()){auto item=*outstanding.begin();outstanding.erase(outstanding.begin());item.second(item.first);}
    }
    OperationBudget(const OperationBudget&)=delete;
    OperationBudget& operator=(const OperationBudget&)=delete;
    void track(void* value,void(*destroy)(void*)){tick(64);outstanding.emplace(value,destroy);}
    void forget(void* value)noexcept{outstanding.erase(value);}
    void storage(std::size_t n){if(bytes>byteLimit||n>byteLimit-bytes)throw std::runtime_error("Spline clipping scratch allowance exceeded");bytes+=n;}
    void tick(std::size_t n=1){if(work>workLimit||n>workLimit-work)throw std::runtime_error("Spline clipping work allowance exceeded");work+=n;}
    void items(std::size_t count){
        // 1024 bytes per produced item covers the pinned engine's largest
        // record, allocator overhead, <=2x container growth and output copies.
        if(count>(byteLimit-bytes)/1024)throw std::runtime_error("Spline clipping scratch allowance exceeded");
        storage(count*1024);tick(count);
    }
};
inline void BudgetWork(OperationBudget* budget,std::size_t n=1){if(budget)budget->tick(n);}
inline void BudgetItems(OperationBudget* budget,std::size_t n=1){if(budget)budget->items(n);}
}
