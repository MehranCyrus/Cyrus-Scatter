// GC-owned immutable copied receiver data. No node pointer, callbacks or workers.
namespace {
std::uint64_t gridBuilds=0,gridCells=0,gridVisits=0,gridBytes=0,gridSnapshots=0;
}
visible_class_debug_ok(CyrusGridSnapshot)
class CyrusGridSnapshot : public Value {
public:
    const std::vector<amin::Triangle> mesh;
    const cyrus::grid::Result projection;
    const ULONG receiverHandle;
    const int uvChannel;
    const bool uv;
    const std::uint32_t seed;
    const std::uint64_t salt,bytes;
    CyrusGridSnapshot(std::vector<amin::Triangle> m,cyrus::grid::Result p,ULONG receiver,int channel,bool textured,std::uint32_t randomSeed,std::uint64_t domain)
        :mesh(std::move(m)),projection(std::move(p)),receiverHandle(receiver),uvChannel(channel),uv(textured),seed(randomSeed),salt(domain),
         bytes(mesh.capacity()*sizeof(amin::Triangle)+projection.anchors.capacity()*sizeof(amin::CandidateAnchor)){
        tag=class_tag(CyrusGridSnapshot);gridBytes+=bytes;++gridSnapshots;++gridBuilds;gridCells+=projection.enumeratedCells;gridVisits+=projection.projectionVisits;
    }
    ~CyrusGridSnapshot(){gridBytes-=bytes;--gridSnapshots;}
    classof_methods(CyrusGridSnapshot,Value);
    void collect() override {delete this;}
    void sprin1(CharStream* stream) override {stream->printf(_T("<CyrusGridSnapshot>"));}
    Value* deep_copy(HashTable*) override {return this;}
};
visible_class_instance(CyrusGridSnapshot,"CyrusGridSnapshot");
