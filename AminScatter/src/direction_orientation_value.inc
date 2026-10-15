// Host-thread constructed, immutable, GC-owned normals. No retained host nodes.
namespace {
std::uint64_t orientationSnapshotBuilds=0,orientationApplications=0,orientationAppliedRows=0;
std::uint64_t orientationSnapshotBytes=0,orientationSnapshotCount=0;
}
visible_class_debug_ok(CyrusOrientationNormals)
class CyrusOrientationNormals : public Value {
public:
    std::vector<amin::Vec3> values;
    explicit CyrusOrientationNormals(std::vector<amin::Vec3> v):values(std::move(v)){tag=class_tag(CyrusOrientationNormals);orientationSnapshotBytes+=values.capacity()*sizeof(amin::Vec3);++orientationSnapshotCount;}
    ~CyrusOrientationNormals(){orientationSnapshotBytes-=values.capacity()*sizeof(amin::Vec3);--orientationSnapshotCount;}
    classof_methods(CyrusOrientationNormals,Value);
    void collect() override {delete this;}
    void sprin1(CharStream* stream) override {stream->printf(_T("<CyrusOrientationNormals>"));}
    Value* deep_copy(HashTable*) override {return this;}
};
visible_class_instance(CyrusOrientationNormals,"CyrusOrientationNormals");
