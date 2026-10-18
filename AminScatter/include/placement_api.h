#pragma once
#include <stddef.h>
#include <stdint.h>

// POD boundary owned/exported only by AminScatter.dlx. Consumers never delete
// leases, exchange STL/shared_ptr, or link another copy of placement_store.cpp.
// acquire touches a MAXScript Value and is main-thread-only. Retained numeric
// info/record/text reads and retain/release need no Max API. A text pointer is
// borrowed until the matching lease's last release. No lease is serialized.
struct CyrusPlacementLease;
struct CyrusPlacementFilter;
struct CyrusPlacementRecord {
    float transform[12],bary[3];
    uint32_t source,face,receiver;
    uint64_t identity,band;
    uint32_t flags,reserved;
};
struct CyrusPlacementInfo {
    uint32_t size,version,recordBytes,stage,sources,reserved;
    uint64_t owner,generation,view,count;
};
struct CyrusPlacementReceiver { uint32_t slot,begin,faces,reserved; uint64_t handle; };
struct CyrusPlacementApi {
    uint32_t size,version,recordBytes,reserved;
    CyrusPlacementLease* (*acquire)(void* scriptValue);
    int (*retain)(CyrusPlacementLease*);
    void (*release)(CyrusPlacementLease*);
    int (*info)(const CyrusPlacementLease*,CyrusPlacementInfo*);
    int (*record)(const CyrusPlacementLease*,uint64_t,CyrusPlacementRecord*);
    const char* (*authored)(const CyrusPlacementLease*,uint64_t,uint32_t* length);
    uint64_t (*liveLeases)();
    // v2: ordered filtered successors. All allocation/ownership stays in the
    // producer DLL. append preserves every input field except the 12 floats.
    // finish is main-thread-only, returns a GC Value or null, and consumes the
    // builder contents. Always destroy the opaque builder, even after finish.
    CyrusPlacementFilter* (*beginFilter)(const CyrusPlacementLease*);
    int (*appendFilter)(CyrusPlacementFilter*,uint64_t inputIndex,const float* transform12);
    void* (*finishFilter)(CyrusPlacementFilter*);
    void (*destroyFilter)(CyrusPlacementFilter*);
    uint64_t (*liveFilters)();
    uint32_t (*receiverCount)(const CyrusPlacementLease*);
    int (*receiver)(const CyrusPlacementLease*,uint32_t,CyrusPlacementReceiver*);
    void (*notePaintTransport)(uint64_t rows,uint64_t matrices,uint64_t populationArrays);
};
typedef const CyrusPlacementApi* (*CyrusPlacementGetApiFn)(uint32_t version);
