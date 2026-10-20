// Node-owned viewport preference. No ordinary Hide/render flags or geometry edits.
// A native filter avoids a scripted callback for every scene node.
namespace {
constexpr DWORD surfaceVisibilityChunk=0x43535631;
bool surfaceHidden(INode* node) {
    auto* data=node?node->GetAppDataChunk(documentID,REF_TARGET_CLASS_ID,surfaceVisibilityChunk):nullptr;
    return data&&data->length==1&&*static_cast<unsigned char*>(data->data)==1;
}
class SurfaceDisplayFilter:public DisplayFilterCallback {
public:
    const MCHAR* GetName()override{return _T("Cyrus hidden receiving surfaces");}
    BOOL IsHidden(SClass_ID,Class_ID,INode* node)override{return surfaceHidden(node);}
} surfaceFilter;
bool surfaceFilterRegistered=false;
bool surfaceNotificationsRegistered=false;
bool surfaceStartupRegistered=false;
int renderDepth=0;
bool restoreFilter=false;
int surfaceFilterIndex() {
    auto* ip=GetCOREInterface();
    for(int i=0;i<ip->GetNumberDisplayFilters();++i)
        if(MSTR(ip->GetDisplayFilterName(i))==surfaceFilter.GetName())return i;
    return -1;
}
void surfaceRenderEvent(void*,NotifyInfo* info) {
    auto* ip=GetCOREInterface();const int index=surfaceFilterIndex();if(index<0)return;
    if(info->intcode==NOTIFY_PRE_RENDER) {
        if(renderDepth++==0){restoreFilter=ip->GetDisplayFilter(index)!=FALSE;ip->SetDisplayFilter(index,FALSE);}
    }else if(renderDepth>0&&--renderDepth==0) {
        ip->SetDisplayFilter(index,restoreFilter?TRUE:FALSE);ip->ForceCompleteRedraw();
    }
}
bool brushTargetHidden(INode* node) {
    if(!surfaceHidden(node))return node->IsHidden()!=0;
    if(node->IsObjectHidden())return true;
    auto* props=static_cast<INodeLayerProperties*>(node->GetInterface(NODELAYERPROPERTIES_INTERFACE));
    auto* layer=props?props->getLayer():nullptr;
    for(int depth=0;layer&&depth<256;++depth,layer=layer->getParentLayerProperties())if(!layer->getOn())return true;
    if(layer)return true;
    auto* object=node->GetObjectRef();auto* ip=GetCOREInterface();
    if(!object)return true;
    for(int i=0;i<ip->GetNumberDisplayFilters();++i)
        if(ip->GetDisplayFilter(i)&&MSTR(ip->GetDisplayFilterName(i))!=surfaceFilter.GetName()&&
            ip->DisplayFilterIsNodeHidden(i,object->SuperClassID(),object->ClassID(),node))return true;
    return false;
}
void enableSurfaceFilter() {
    auto* ip=GetCOREInterface();
    if(!surfaceFilterRegistered){surfaceFilter.on=TRUE;ip->RegisterDisplayFilterCallback(&surfaceFilter);surfaceFilterRegistered=true;}
    if(!surfaceNotificationsRegistered){
        RegisterNotification(surfaceRenderEvent,nullptr,NOTIFY_PRE_RENDER);
        RegisterNotification(surfaceRenderEvent,nullptr,NOTIFY_POST_RENDER);
        surfaceNotificationsRegistered=true;
    }
    int index=surfaceFilterIndex();if(index>=0&&renderDepth==0)ip->SetDisplayFilter(index,TRUE);
}
void surfaceStartupEvent(void*,NotifyInfo*){enableSurfaceFilter();}
void initializeSurfaceVisibility() {
    // DLX initialization precedes viewport/MAXScript UI initialization. Defer
    // display-filter API calls until Max is ready; ordinary commands also ensure
    // initialization for a module loaded later in the session.
    if(!surfaceStartupRegistered){
        RegisterNotification(surfaceStartupEvent,nullptr,NOTIFY_SYSTEM_STARTUP);
        surfaceStartupRegistered=true;
    }
}
void setSurfaceHidden(INode* node,bool hidden) {
    if(!node)return;
    if(hidden) {
        auto* data=static_cast<unsigned char*>(MAX_malloc(1));
        if(!data)throw std::bad_alloc();
        *data=1;
        node->RemoveAppDataChunk(documentID,REF_TARGET_CLASS_ID,surfaceVisibilityChunk);
        node->AddAppDataChunk(documentID,REF_TARGET_CLASS_ID,surfaceVisibilityChunk,1,data);
    }else node->RemoveAppDataChunk(documentID,REF_TARGET_CLASS_ID,surfaceVisibilityChunk);
    enableSurfaceFilter();GetCOREInterface()->ForceCompleteRedraw();
}
class SurfaceVisibilityRestore:public RestoreObj {
    SingleRefMaker lifetime;
    bool before,after;
    INode* node(){return static_cast<INode*>(lifetime.GetRef());}
public:
    SurfaceVisibilityRestore(INode* target,bool value):before(surfaceHidden(target)),after(value){lifetime.SetRef(target);}
    void Restore(int)override{setSurfaceHidden(node(),before);}
    void Redo()override{setSurfaceHidden(node(),after);}
    int Size()override{return sizeof(*this);}
    MSTR Description()override{return _T("Cyrus surface visibility");}
};
}
// MAXScript extensions use LibInit, unlike the ordinary plug-in LibInitialize.
// Initialize on load so saved node preferences work before the first UI action.
extern "C" __declspec(dllexport) void LibInit(){initializeSurfaceVisibility();}
extern "C" __declspec(dllexport) int LibInitialize(){initializeSurfaceVisibility();return TRUE;}
extern "C" __declspec(dllexport) int LibShutdown(){
    UnRegisterNotification(surfaceRenderEvent,nullptr);
    UnRegisterNotification(surfaceStartupEvent,nullptr);
    surfaceStartupRegistered=false;
    surfaceNotificationsRegistered=false;
    if(surfaceFilterRegistered){GetCOREInterface()->UnRegisterDisplayFilterCallback(&surfaceFilter);surfaceFilterRegistered=false;}
    return TRUE;
}
def_visible_primitive(cyrusSurfaceHidden,"cyrusSurfaceHidden");
Value* cyrusSurfaceHidden_cf(Value** a,int n){check_arg_count(cyrusSurfaceHidden,1,n);return surfaceHidden(a[0]->to_node())?&true_value:&false_value;}
def_visible_primitive(cyrusSetSurfaceHidden,"cyrusSetSurfaceHidden");
Value* cyrusSetSurfaceHidden_cf(Value** a,int n){
    check_arg_count(cyrusSetSurfaceHidden,2,n);
    return api([&]()->Value*{
        auto* node=a[0]->to_node();if(!node)throw std::runtime_error("Choose a receiving surface.");
        const bool value=a[1]->to_bool()!=FALSE;
        if(surfaceHidden(node)!=value){if(theHold.Holding())theHold.Put(new SurfaceVisibilityRestore(node,value));setSurfaceHidden(node,value);}
        return &ok;
    });
}
