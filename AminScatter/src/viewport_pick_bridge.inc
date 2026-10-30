// Public native bridge; MAXScript only schedules hover and binds UI selection.
namespace {
struct OutlineLine {std::array<Point3,3> points;unsigned count=3;};
struct ViewportHover {
    std::uint64_t owner=0,ticket=0;std::size_t layer=0,group=0,instance=0;
    std::size_t entry=0;
    std::vector<OutlineLine> lines;
    std::shared_ptr<cyrus::PreviewMemory> memory;
} viewportHover;
struct ViewportSelected {
    std::uint64_t owner=0,ticket=0,editor=0,revision=0;
    std::vector<OutlineLine> lines;
    std::vector<std::size_t> entries;
    std::shared_ptr<cyrus::PreviewMemory> memory;
} viewportSelected;
static std::uint64_t hoverOutlineBuilds=0,selectedOutlineBuilds=0;
static constexpr std::size_t outlineFaceLimit=1024,selectedLineLimit=4096;
static cyrus::PointDisplay* pickOwner(INode* node) {
    if(!node)return nullptr;
    const auto it=cyrus::pickDisplays.find(Animatable::GetHandleByAnim(node));
    if(it==cyrus::pickDisplays.end())return nullptr;
    auto* value=Animatable::GetAnimByHandle(it->second);
    return value&&value->ClassID()==cyrus::displayID?static_cast<cyrus::PointDisplay*>(value):nullptr;
}
static void appendOutline(std::vector<OutlineLine>& lines,const cyrus::Generation& gen,const cyrus::PickEntry& e,std::size_t budget) {
    const auto& mesh=*gen.layers[e.layer].mesh;const auto& group=mesh.groups[e.group];
    if(e.box){
        // Only a displayed box proxy gets a box outline, in instance space.
        const auto& b=mesh.localBounds[e.group];Point3 corners[8];
        for(unsigned i=0;i<8;++i)corners[i]=Point3(i&1?b.Max().x:b.Min().x,i&2?b.Max().y:b.Min().y,i&4?b.Max().z:b.Min().z)*e.tm;
        for(unsigned i=0;i<8;++i)for(unsigned a=0;a<3;++a)if(!(i&(1u<<a)))lines.push_back({{corners[i],corners[i|(1u<<a)],Point3(0,0,0)},2});
        return;
    }
    const auto faces=group.faceData().size(),count=std::min({faces,budget,outlineFaceLimit});
    // Sampling bounds skinning and drawing on dense assets. It changes only
    // the cue, never the visible mesh or exact surface picking.
    for(std::size_t n=0;n<count;++n){const auto face=unsigned(n*faces/count);
        if(!cyrus::pickVisible(group,e,face))continue;
        auto triangle=cyrus::pickFace(group,e,face);for(auto& p:triangle)p=p*e.tm;
        lines.push_back({triangle,3});
    }
}
static void drawOutline(ViewExp* view,const std::vector<OutlineLine>& lines) {
    if(!view||lines.empty())return;auto* gw=view->getGW();const auto limits=gw->getRndLimits();
    gw->setRndLimits(limits&~GW_ILLUM);gw->setTransform(Matrix3(1));gw->setColor(LINE_COLOR,1.f,1.f,0.f);
    for(const auto& line:lines){
        // Max's clipper requires count+1 writable points. Do not mutate the
        // cache or let clipping write past the final segment's allocation.
        Point3 points[4]={line.points[0],line.points[1],line.points[2],Point3(0,0,0)};
        gw->polyline(int(line.count),points,nullptr,nullptr,line.count==3,nullptr);
    }
    gw->setRndLimits(limits);
}
static void setViewportHover(cyrus::PointDisplay& display,const CyrusViewportHit& hit) {
    const auto gen=display.visibleGeneration();if(!gen)return;
    if(viewportHover.owner==hit.owner&&viewportHover.ticket==gen->ticket&&viewportHover.layer==hit.displayLayer&&viewportHover.group==hit.group&&viewportHover.instance==hit.instance)return;
    ViewportHover next;next.owner=hit.owner;next.ticket=gen->ticket;next.layer=hit.displayLayer;next.group=hit.group;next.instance=hit.instance;
    const auto cache=display.pickState;if(!cache||cache->ticket!=gen->ticket||hit.entry>=cache->entries.size())return;
    const auto& entry=cache->entries[hit.entry];next.entry=hit.entry;
    const auto count=entry.box?12:std::min(outlineFaceLimit,gen->layers[entry.layer].mesh->groups[entry.group].faceData().size());
    next.memory=cyrus::reserveMeshMemory({count*sizeof(OutlineLine),0});next.lines.reserve(count);
    appendOutline(next.lines,*gen,entry,count);
    next.memory->commit();viewportHover=std::move(next);++hoverOutlineBuilds;
}
}
bool cyrusViewportPick(INode* node,ViewExp* view,IPoint2 pixel,CyrusViewportHit& hit,bool hover)noexcept {
    try{auto* display=pickOwner(node);if(!display||!cyrus::pickQuery(*display,view,pixel,hit))return false;
        if(hover)setViewportHover(*display,hit);return true;}catch(...){return false;}
}
void cyrusViewportClearHover(INode* node)noexcept{if(!node||viewportHover.owner==Animatable::GetHandleByAnim(node))viewportHover={};}
void cyrusViewportClearSelected()noexcept{viewportSelected={};}
void cyrusViewportDrawSelected(INode* node,ViewExp* view,std::uint64_t editor,std::uint64_t revision,
    const std::function<std::vector<CyrusViewportSelectedInstance>()>& selection)noexcept {
    try{
        auto* display=pickOwner(node);const auto gen=display?display->visibleGeneration():nullptr;
        if(!gen||!gen->visible()||!gen->submitted.load())return;
        const auto owner=Animatable::GetHandleByAnim(node);
        if(viewportSelected.owner!=owner||viewportSelected.ticket!=gen->ticket||viewportSelected.editor!=editor||viewportSelected.revision!=revision){
            ViewportSelected next;next.owner=owner;next.ticket=gen->ticket;next.editor=editor;next.revision=revision;
            // Enumeration happens on a changed selection/display, not camera redraw.
            next.memory=cyrus::reserveMeshMemory({selectedLineLimit*sizeof(OutlineLine)+cyrusViewportOutlineInstances*sizeof(std::size_t)+65536,0});
            const auto selected=selection();if(selected.size()>cyrusViewportOutlineInstances)return;
            if(!selected.empty()){
                next.lines.reserve(selectedLineLimit);next.entries.reserve(selected.size());
                std::map<std::pair<std::uint64_t,std::wstring>,bool> wanted;for(const auto& item:selected)wanted.emplace(std::make_pair(item.layer,item.identity),true);
                const auto cache=cyrus::pickPrepare(*display,gen);
                for(std::size_t i=0;i<cache->entries.size()&&!wanted.empty();++i){const auto& e=cache->entries[i];const auto& mesh=*gen->layers[e.layer].mesh;const auto& group=mesh.groups[e.group];
                    const auto raw=group.sourceIndex(e.instance);if(!mesh.pickView||!group.pickRows||raw>=group.pickRows->size())continue;
                    const auto id=mesh.pickView->textIdentity(group.pickRows->at(raw));
                    const auto found=wanted.find({mesh.pickView->token().owner,std::wstring(id.begin(),id.end())});if(found==wanted.end())continue;
                    appendOutline(next.lines,*gen,e,(selectedLineLimit-next.lines.size())/wanted.size());next.entries.push_back(i);wanted.erase(found);
                }
                next.memory->commit();
            }else next.memory.reset();
            viewportSelected=std::move(next);++selectedOutlineBuilds;
        }
        drawOutline(view,viewportSelected.lines);
    }catch(...){viewportSelected={};} // Optional cue failure leaves selection and display intact.
}
Box3 cyrusViewportPickBounds(INode* node)noexcept{Box3 bounds;bounds.Init();try{auto* display=pickOwner(node);const auto gen=display?display->visibleGeneration():nullptr;if(gen&&gen->visible())bounds=gen->bounds;}catch(...){}return bounds;}
void cyrusViewportDrawHover(INode*,ViewExp* view)noexcept {
    try{if(cyrusViewportEditDragging())return;auto* node=Animatable::GetAnimByHandle(viewportHover.owner);if(!node||node->SuperClassID()!=BASENODE_CLASS_ID||!view)return;
        auto* display=pickOwner(static_cast<INode*>(node));const auto gen=display?display->visibleGeneration():nullptr;if(!gen||!gen->visible()||gen->ticket!=viewportHover.ticket)return;
        // The persistent selected cue already covers this same instance.
        if(viewportSelected.owner==viewportHover.owner&&viewportSelected.ticket==gen->ticket&&
            std::find(viewportSelected.entries.begin(),viewportSelected.entries.end(),viewportHover.entry)!=viewportSelected.entries.end())return;
        drawOutline(view,viewportHover.lines);
    }catch(...){}
}
def_visible_primitive(cyrusViewportOutlineStats,"cyrusViewportOutlineStats");
Value* cyrusViewportOutlineStats_cf(Value**,int count){check_arg_count(cyrusViewportOutlineStats,0,count);
    one_typed_value_local(Array* result);vl.result=new Array(6);
    for(auto n:{hoverOutlineBuilds,selectedOutlineBuilds,std::uint64_t(viewportHover.lines.size()),std::uint64_t(viewportSelected.lines.size()),std::uint64_t(viewportSelected.entries.size())})vl.result->append(Integer64::intern(n));
    vl.result->append(cyrusViewportEditDragging()?&true_value:&false_value);return_value(vl.result);
}
INode* cyrusViewportController(INode* helper)noexcept {
    try{auto* obj=helper?helper->GetObjectRef():nullptr;if(!obj||obj->ClassID()!=cyrus::displayID)return nullptr;
        auto* display=static_cast<cyrus::PointDisplay*>(obj);if(display->pickTarget)display=display->pickDisplayTarget();
        return display?static_cast<INode*>(display->controller.GetRef()):nullptr;}catch(...){return nullptr;}
}
def_visible_primitive(cyrusViewportCreatePicker,"cyrusViewportCreatePicker");
Value* cyrusViewportCreatePicker_cf(Value** args,int count){
    check_arg_count(cyrusViewportCreatePicker,2,count);auto* target=cyrus::owner(args[0]->to_node());auto* controller=args[1]->to_node();
    if(target->pickTarget)throw RuntimeError(_T("Expected a render helper"));
    auto* object=new cyrus::PointDisplay;object->pickTarget=target->displayHandle();auto* node=GetCOREInterface()->CreateObjectNode(object);
    if(!node){object->DeleteThis();return &undefined;}node->SetName(controller->GetName());node->SetRenderable(FALSE);node->IgnoreExtents(TRUE);node->SetNodeTM(GetCOREInterface()->GetTime(),Matrix3(1));return MAXNode::intern(node);
}
def_visible_primitive(cyrusViewportSyncPicker,"cyrusViewportSyncPicker");
Value* cyrusViewportSyncPicker_cf(Value** args,int count){
    check_arg_count(cyrusViewportSyncPicker,1,count);auto* node=args[0]->to_node();auto* picker=cyrus::owner(node);auto* target=picker->pickDisplayTarget();if(!target)return &undefined;
    const auto ticket=target->presentation->visibleTicket();
    if(picker->pickBoundsTicket!=ticket){picker->pickBoundsTicket=ticket;node->InvalidateWS();picker->NotifyDependents(FOREVER,PART_GEOM,REFMSG_CHANGE);}
    auto* owner=static_cast<INode*>(target->controller.GetRef());if(owner&&_tcscmp(node->GetName(),owner->GetName())!=0)node->SetName(owner->GetName());return &ok;
}
extern INode* cyrusViewportEditOwner()noexcept;
def_visible_primitive(cyrusViewportSelectionVersion,"cyrusViewportSelectionVersion");
Value* cyrusViewportSelectionVersion_cf(Value**,int count){check_arg_count(cyrusViewportSelectionVersion,0,count);return Integer::intern(2);}
// Only a recent viewport hit can enter instance mode. Scene Explorer, icon
// selection, scripts and Ctrl multi-selection keep ordinary setup selection.
def_visible_primitive(cyrusViewportSelectionHit,"cyrusViewportSelectionHit");
Value* cyrusViewportSelectionHit_cf(Value** args,int count){
    check_arg_count(cyrusViewportSelectionHit,1,count);auto* owner=cyrusViewportController(args[0]->to_node());auto* display=pickOwner(owner);
    if(!display||!display->pickState)return &undefined;const auto cache=display->pickState;const auto gen=display->visibleGeneration();
    if(!gen||!gen->visible()||cache->ticket!=gen->ticket||!cache->hitFound||cache->lastHit.identity.empty()||GetTickCount64()-cache->selectedAt>750)return &undefined;
    if((GetAsyncKeyState(VK_CONTROL)|GetAsyncKeyState(VK_MENU)|GetAsyncKeyState(VK_SHIFT))&0x8000)return &undefined;
    POINT cursor{};GetCursorPos(&cursor);const auto window=WindowFromPoint(cursor);if(window!=cache->selectedView&&!IsChild(cache->selectedView,window))return &undefined;
    ScreenToClient(cache->selectedView,&cursor);if(std::abs(cursor.x-cache->selectedPixel.x)>2||std::abs(cursor.y-cache->selectedPixel.y)>2)return &undefined;
    cache->selectedAt=0;
    one_typed_value_local(Array* result);vl.result=new Array(4);vl.result->append(MAXNode::intern(owner));vl.result->append(Integer64::intern(cache->lastHit.layer));vl.result->append(new String(cache->lastHit.identity.c_str()));vl.result->append(Integer64::intern(gen->ticket));return_value(vl.result);
}
def_visible_primitive(cyrusViewportSelectionValid,"cyrusViewportSelectionValid");
Value* cyrusViewportSelectionValid_cf(Value** args,int count){check_arg_count(cyrusViewportSelectionValid,2,count);auto* display=pickOwner(args[0]->to_node());const auto gen=display?display->visibleGeneration():nullptr;return gen&&gen->visible()&&gen->ticket==std::uint64_t(args[1]->to_int64())?&true_value:&false_value;}
def_visible_primitive(cyrusViewportPointerIdle,"cyrusViewportPointerIdle");
Value* cyrusViewportPointerIdle_cf(Value**,int count){check_arg_count(cyrusViewportPointerIdle,0,count);return (GetAsyncKeyState(VK_LBUTTON)|GetAsyncKeyState(VK_MBUTTON)|GetAsyncKeyState(VK_RBUTTON))&0x8000?&false_value:&true_value;}
def_visible_primitive(cyrusViewportSelectionOwner,"cyrusViewportSelectionOwner");
Value* cyrusViewportSelectionOwner_cf(Value** args,int count){check_arg_count(cyrusViewportSelectionOwner,1,count);auto* node=cyrusViewportController(args[0]->to_node());return node?static_cast<Value*>(MAXNode::intern(node)):&undefined;}
def_visible_primitive(cyrusViewportPickAt,"cyrusViewportPickAt");
Value* cyrusViewportPickAt_cf(Value** args,int count){
    check_arg_count(cyrusViewportPickAt,3,count);auto& view=GetCOREInterface()->GetActiveViewExp();CyrusViewportHit hit;
    if(!cyrusViewportPick(args[0]->to_node(),&view,IPoint2(args[1]->to_int(),args[2]->to_int()),hit))return &undefined;
    one_typed_value_local(Array* result);vl.result=new Array(5);vl.result->append(Integer64::intern(hit.layer));vl.result->append(new String(hit.identity.c_str()));vl.result->append(Integer::intern(hit.source));vl.result->append(new Point3Value(hit.position));vl.result->append(Float::intern(hit.distance));return_value(vl.result);
}
def_visible_primitive(cyrusViewportHoverDraw,"cyrusViewportHoverDraw");
Value* cyrusViewportHoverDraw_cf(Value**,int count){check_arg_count(cyrusViewportHoverDraw,0,count);auto& view=GetCOREInterface()->GetActiveViewExp();cyrusViewportDrawHover(nullptr,&view);return &ok;}
def_visible_primitive(cyrusViewportHoverTick,"cyrusViewportHoverTick");
Value* cyrusViewportHoverTick_cf(Value**,int count){
    check_arg_count(cyrusViewportHoverTick,0,count);static POINT previous{-99999,-99999};static HWND previousView=nullptr;static std::uint64_t previousTicket=0,previousEdit=0;static Ray previousRay;
    auto& view=GetCOREInterface()->GetActiveViewExp();POINT cursor{};GetCursorPos(&cursor);RECT rect{};const auto hwnd=view.GetHWnd();GetClientRect(hwnd,&rect);POINT pixel=cursor;ScreenToClient(hwnd,&pixel);
    const bool idle=!(GetAsyncKeyState(VK_LBUTTON)&0x8000)&&!(GetAsyncKeyState(VK_MBUTTON)&0x8000)&&!(GetAsyncKeyState(VK_RBUTTON)&0x8000);
    const bool inside=idle&&PtInRect(&rect,pixel)&&IsChild(GetCOREInterface()->GetMAXHWnd(),WindowFromPoint(cursor));
    if(!inside){previous.x=-99999;if(viewportHover.owner){viewportHover={};return &true_value;}return &false_value;}
    auto* edited=cyrusViewportEditOwner();std::uint64_t ticket=0;for(const auto& [owner,handle]:cyrus::pickDisplays){(void)owner;auto* object=Animatable::GetAnimByHandle(handle);if(object&&object->ClassID()==cyrus::displayID)ticket+=static_cast<cyrus::PointDisplay*>(object)->presentation->visibleTicket();}
    Ray ray;view.MapScreenToWorldRay(float(pixel.x),float(pixel.y),ray);const auto editHandle=edited?Animatable::GetHandleByAnim(edited):0;
    if(cursor.x==previous.x&&cursor.y==previous.y&&previousView==hwnd&&previousTicket==ticket&&previousEdit==editHandle&&ray.p==previousRay.p&&ray.dir==previousRay.dir)return &false_value;
    previous=cursor;previousView=hwnd;previousTicket=ticket;previousEdit=editHandle;previousRay=ray;
    // Ask Max for the frontmost selectable node so ordinary foreground geometry
    // occludes Scatter hover too. Its HitTest and the next query share one ray.
    auto* picked=GetCOREInterface()->PickNode(hwnd,IPoint2(pixel.x,pixel.y));
    auto* controller=cyrusViewportController(picked);CyrusViewportHit best;
    const bool found=controller&&!controller->IsHidden()&&!controller->IsFrozen()&&(!edited||edited==controller)&&cyrusViewportPick(controller,&view,IPoint2(pixel.x,pixel.y),best,false);
    const auto old=std::make_tuple(viewportHover.owner,viewportHover.ticket,viewportHover.layer,viewportHover.group,viewportHover.instance);
    try{if(found){auto* node=static_cast<INode*>(Animatable::GetAnimByHandle(best.owner));setViewportHover(*pickOwner(node),best);}else viewportHover={};}catch(...){viewportHover={};}
    return old!=std::make_tuple(viewportHover.owner,viewportHover.ticket,viewportHover.layer,viewportHover.group,viewportHover.instance)?&true_value:&false_value;
}
