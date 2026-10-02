// Compile/link only. Never loaded or executed. Not a display implementation.
#include <max.h>
#include <Graphics/IObjectDisplay2.h>
#include <Graphics/InstanceDisplayGeometry.h>
#include <type_traits>
using namespace MaxSDK::Graphics;
using namespace MaxSDK::Graphics::ViewportInstancing;
class InterfaceProbe final : public IObjectDisplay2 {
public:
    bool PrepareDisplay(const UpdateDisplayContext&) override {return true;}
    bool UpdatePerNodeItems(const UpdateDisplayContext&,UpdateNodeContext&,IRenderItemContainer&) override {return false;}
};
static_assert(!std::is_abstract_v<InterfaceProbe>);
extern "C" __declspec(dllexport) IObjectDisplay2* probeInterface() {return new InterfaceProbe;}
extern "C" __declspec(dllexport) InstanceDisplayGeometry* probeGeometry() {return new InstanceDisplayGeometry;}
extern "C" __declspec(dllexport) bool probeMethods(InstanceDisplayGeometry* g,Matrix3* matrices,size_t count,
    const UpdateDisplayContext& context,UpdateNodeContext& node,IRenderItemContainer& items) {
    InstanceData data;data.numInstances=count;data.pMatrices=matrices;data.bTransformationsAreInWorldSpace=true;
    if(!g->CreateInstanceData(data)) return false;
    g->UpdateInstanceData(data);
    return g->GenerateInstances(false,context,node,items);
}
