#include "preview_service.h"
#include "arrange_document.h"
#include <GraphicsWindow.h>
#include <notify.h>
#include <units.h>
#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <memory>
#include <set>
#include <stdexcept>
#include <utility>

namespace cyrus::arrange::host {
namespace {
constexpr std::size_t max_previews=8,max_boxes=80000,max_boxes_per_preview=10000,max_selected_regions=4096;
constexpr std::size_t max_registry_cells=2000000;
constexpr double pi=3.14159265358979323846;
enum class Stale { None,State,Dependency,Time,Units,Owner,Host };
const char* reason(Stale stale)noexcept {
    switch(stale) {
    case Stale::None:return "";
    case Stale::State:return "Setup settings or published state changed; Preview again.";
    case Stale::Dependency:return "A relevant scene dependency changed; Preview again.";
    case Stale::Time:return "Scene time changed; Preview again.";
    case Stale::Units:return "Scene units changed; Preview again.";
    case Stale::Owner:return "The preview's setup owner was removed or replaced.";
    default:return "Preview freshness could not be validated; Preview again.";
    }
}
struct Entry {
    SingleRefMaker lifetime;
    const DocumentState* expected_state{}; // Identity only, never dereferenced.
    std::uint64_t revision{},input_epoch{};
    cache::Ticket dependency_stamp;
    TimeValue time{};
    double mm_per_system_unit{};
    Stale stale{Stale::None};
    std::vector<OrientedBox> boxes;
    std::vector<std::uint32_t> selected;
    std::shared_ptr<const RegionRegistry> registry;
    std::size_t registry_cells{};
    ArrangementStats stats;
    Document* document()const noexcept {
        return static_cast<Document*>(const_cast<SingleRefMaker&>(lifetime).GetRef());
    }
};
std::vector<std::unique_ptr<Entry>> entries;
std::unique_ptr<Entry> fit_highlight;
std::uint64_t fit_asset_id{},fit_draws{};
bool fit_suggestion{};
DWORD service_thread{};
bool registered{},drawing{};
void main_thread() {
    auto* ip=GetCOREInterface();const auto hwnd=ip?ip->GetMAXHWnd():nullptr;
    if(!hwnd||GetWindowThreadProcessId(hwnd,nullptr)!=GetCurrentThreadId())
        throw std::runtime_error("Arrange preview requires Max's main thread.");
}
double unit_scale() {
    const double unit=GetSystemUnitScale(UNITS_MILLIMETERS);
    if(!std::isfinite(unit)||unit<=0)throw std::runtime_error("Invalid preview system units.");
    return unit;
}
bool current(Entry& entry,TimeValue time,double unit)noexcept {
    if(entry.stale!=Stale::None)return false;
    try {
        auto* doc=entry.document();auto* owner=doc?doc->owner():nullptr;
        if(!owner||get_document(owner,false)!=doc)entry.stale=Stale::Owner;
        else if(doc->state().get()!=entry.expected_state||doc->state()->revision!=entry.revision)entry.stale=Stale::State;
        else if(doc->lifecycle().input_epoch!=entry.input_epoch||!entry.dependency_stamp.valid()||doc->geometry_ticket()!=entry.dependency_stamp)entry.stale=Stale::Dependency;
        else if(time!=entry.time)entry.stale=Stale::Time;
        else if(unit!=entry.mm_per_system_unit)entry.stale=Stale::Units;
    }catch(...){entry.stale=Stale::Host;}
    return entry.stale==Stale::None;
}
auto find_entry(Document& doc) {
    return std::find_if(entries.begin(),entries.end(),[&](const auto& entry){return entry->document()==&doc;});
}

// SDK primary references: maxsdk/include/maxapi.h ViewportDisplayCallback and
// Interface::RegisterViewportDisplayCallback/NotifyViewportDisplayCallbackChanged;
// samples/utilities/shapechk.cpp demonstrates the native post-scene callback.
// GraphicsWindow.h documents identity world transforms and start/segment/end.
class PreviewDisplay final : public ViewportDisplayCallback {
public:
    BOOL Foreground()override{return TRUE;}
    void GetViewportRect(TimeValue,ViewExp* viewport,Rect* rect)override {
        if(!rect)return;rect->SetEmpty();
        if(GetCurrentThreadId()!=service_thread||!viewport||!viewport->IsAlive())return;
        if(auto* gw=viewport->getGW()) {
            rect->left=0;rect->top=0;rect->right=gw->getWinSizeX();rect->bottom=gw->getWinSizeY();
        }
    }
    void Display(TimeValue time,ViewExp* viewport,int)override {
        if(drawing||GetCurrentThreadId()!=service_thread||!viewport||!viewport->IsAlive())return;
        drawing=true;
        try {
            auto* gw=viewport->getGW();if(!gw){drawing=false;return;}
            const double unit=unit_scale();
            struct GraphicsRestore {
                GraphicsWindow* gw;Matrix3 transform;DWORD limits;bool segments{};
                explicit GraphicsRestore(GraphicsWindow* value):gw(value),transform(value->getTransform()),limits(value->getRndLimits()){}
                ~GraphicsRestore(){try{if(segments)gw->endSegments();gw->setRndLimits(limits);gw->setTransform(transform);}catch(...){}}
            } restore(gw);
            gw->setTransform(Matrix3(TRUE));
            gw->setRndLimits((restore.limits|GW_WIREFRAME|GW_Z_BUFFER)&~(GW_ILLUM|GW_TEXTURE|GW_PICK));
            gw->setColor(LINE_COLOR,0.20f,0.80f,0.95f);
            gw->startSegments();restore.segments=true;
            constexpr std::array<std::array<int,2>,12> edges{{{0,1},{1,2},{2,3},{3,0},{4,5},{5,6},{6,7},{7,4},{0,4},{1,5},{2,6},{3,7}}};
            const auto draw=[&](Entry& entry,bool fit) {
                if(!current(entry,time,unit))return;
                for(std::size_t index=0;index<entry.boxes.size();++index) {
                    const auto& box=entry.boxes[index];
                    if(fit){if(index+1==entry.boxes.size()&&fit_suggestion)gw->setColor(LINE_COLOR,.20f,.95f,.35f);else gw->setColor(LINE_COLOR,1.0f,.48f,.12f);}else gw->setColor(LINE_COLOR,.20f,.80f,.95f);
                    const double angle=std::remainder(box.yaw_degrees,360.0)*pi/180,c=std::cos(angle),s=std::sin(angle);
                    std::array<Point3,8> points;
                    for(int i=0;i<8;++i) {
                        const double x=(i==0||i==3||i==4||i==7)?-box.half_extents.x:box.half_extents.x;
                        const double y=(i==0||i==1||i==4||i==5)?-box.half_extents.y:box.half_extents.y;
                        const double z=i<4?-box.half_extents.z:box.half_extents.z;
                        points[i]=Point3(static_cast<float>((box.center.x+c*x-s*y)/unit),
                                         static_cast<float>((box.center.y+s*x+c*y)/unit),static_cast<float>((box.center.z+z)/unit));
                    }
                    for(const auto& edge:edges){Point3 line[2]{points[edge[0]],points[edge[1]]};gw->segment(line,1);}
                }
                if(fit&&fit_draws<std::numeric_limits<std::uint64_t>::max())++fit_draws;
            };
            for(auto& entry:entries)draw(*entry,false);
            if(fit_highlight)draw(*fit_highlight,true);
        }catch(...){} // Never throw, solve, capture or mutate scene nodes in drawing.
        drawing=false;
    }
} display;
void changed(bool redraw)noexcept {
    if(!registered||drawing)return;
    try {
        auto* ip=GetCOREInterface();if(!ip)return;
        ip->NotifyViewportDisplayCallbackChanged(FALSE,&display);
        if(redraw)ip->RedrawViews(ip->GetTime());
    }catch(...){}
}
class PreviewTime final : public TimeChangeCallback {
public:
    void TimeChanged(TimeValue time)override {
        if(GetCurrentThreadId()!=service_thread)return;
        bool invalidated=false;
        for(auto& entry:entries)if(entry->stale==Stale::None&&entry->time!=time){entry->stale=Stale::Time;invalidated=true;}
        if(fit_highlight&&fit_highlight->stale==Stale::None&&fit_highlight->time!=time){fit_highlight->stale=Stale::Time;invalidated=true;}
        if(invalidated)changed(false);
    }
} time_callback;
void scene_event(void*,NotifyInfo* info) {
    if(!info||GetCurrentThreadId()!=service_thread)return;
    try {
        if(info->intcode==NOTIFY_SYSTEM_SHUTDOWN){shutdown_preview();return;}
        entries.clear();fit_highlight.reset();changed(false);
    }catch(...){} // Notifications only discard transient native data.
}
void ensure_registered() {
    if(registered)return;
    service_thread=GetCurrentThreadId();auto* ip=GetCOREInterface();
    ip->RegisterViewportDisplayCallback(FALSE,&display);
    ip->RegisterTimeChangeCallback(&time_callback);
    for(auto code:{NOTIFY_SYSTEM_PRE_RESET,NOTIFY_SYSTEM_PRE_NEW,NOTIFY_FILE_PRE_OPEN,NOTIFY_FILE_PRE_SAVE,
                  NOTIFY_SCENE_PRE_UNDO,NOTIFY_SCENE_PRE_REDO,NOTIFY_UNITS_CHANGE,NOTIFY_SYSTEM_SHUTDOWN})
        RegisterNotification(scene_event,nullptr,code);
    registered=true;
}
void validate_box(const OrientedBox& box,double unit) {
    const auto& p=box.center;const auto& h=box.half_extents;
    for(double value:{p.x,p.y,p.z,h.x,h.y,h.z,box.yaw_degrees})
        if(!std::isfinite(value))throw std::runtime_error("Preview bounds must be finite.");
    if(h.x<0||h.y<0||h.z<0)throw std::runtime_error("Preview half extents must be nonnegative.");
    // Conservative XY bound admits every yaw and prevents float overflow during
    // drawing without constructing/storing a duplicate vertex array.
    const double radius=h.x+h.y;
    if((std::abs(p.x)+radius)/unit>1e9||(std::abs(p.y)+radius)/unit>1e9||(std::abs(p.z)+h.z)/unit>1e9)
        throw std::runtime_error("Preview bounds exceed Max coordinate admission.");
}
std::size_t registry_cell_count(const RegionRegistry& registry) {
    validate_region_registry(registry);
    std::size_t total=0;
    for(const auto& record:registry.records) {
        if(!record.shape||record.shape->cells.size()>max_registry_cells-total)
            throw std::runtime_error("Preview registry exceeds 2,000,000 canonical cells.");
        total+=record.shape->cells.size();
    }
    return total;
}
}

void stage_preview(Document& doc,std::shared_ptr<const DocumentState> expected_state,
                   const CommandDependencyTicket& expected_dependencies,std::int32_t expected_time,double expected_unit,
                   std::span<const OrientedBox> bounds,std::span<const std::uint32_t> selected,const ArrangementStats& stats,
                   std::shared_ptr<const RegionRegistry> registry) {
    main_thread();
    if(bounds.size()>max_boxes_per_preview||selected.size()>max_selected_regions)
        throw std::runtime_error("Preview exceeds 10,000 boxes or 4,096 selected regions.");
    auto* owner=doc.owner();if(!owner||get_document(owner,false)!=&doc)throw std::runtime_error("Preview requires a scene-owned setup.");
    const auto time=GetCOREInterface()->GetTime();const double unit=unit_scale();
    const auto validate_expected=[&] {
        flush_dependency_events();
        // Host calls may invoke callbacks. Check the immutable state and command
        // observer last, and never stamp a successor with newly changed inputs.
        const bool owned=doc.owner()==owner&&get_document(owner,false)==&doc;
        const bool context=GetCOREInterface()->GetTime()==expected_time&&unit_scale()==expected_unit;
        if(!owned||!context||!expected_state||doc.state()!=expected_state||!doc.dependencies_unchanged(expected_dependencies))
            throw std::runtime_error("Preview inputs changed during staging; Preview again.");
    };
    validate_expected();
    for(const auto& box:bounds)validate_box(box,unit);
    std::set<std::uint32_t> unique;
    for(const auto id:selected)if(!id||!unique.insert(id).second)throw std::runtime_error("Preview region IDs must be unique and nonzero.");
    if(stats.accepted!=bounds.size())throw std::runtime_error("Preview bounds and accepted placement count disagree.");
    const auto cells=registry?registry_cell_count(*registry):0;
    auto next=std::make_unique<Entry>();next->boxes.assign(bounds.begin(),bounds.end());next->selected.assign(selected.begin(),selected.end());next->stats=stats;
    next->lifetime.SetRef(&doc);next->expected_state=expected_state.get();next->revision=expected_state->revision;
    next->input_epoch=doc.lifecycle().input_epoch;next->dependency_stamp=doc.geometry_ticket();next->time=time;next->mm_per_system_unit=unit;
    // A failed successor never removes its predecessor. Once all allocation and
    // validation succeeds, stale entries for OTHER setups may be pruned for space.
    std::size_t total=bounds.size(),active=1,total_cells=cells;
    for(const auto& entry:entries)if(entry->document()!=&doc&&current(*entry,time,unit)) {
        ++active;total+=entry->boxes.size();
        if(entry->registry_cells>max_registry_cells-total_cells)
            throw std::runtime_error("Preview cache exceeds 2,000,000 canonical region cells; clear a preview.");
        total_cells+=entry->registry_cells;
    }
    if(active>max_previews||total>max_boxes)throw std::runtime_error("Preview cache exceeds 8 active setups or 80,000 boxes; clear a preview.");
    next->registry=std::move(registry);next->registry_cells=cells;
    entries.reserve(max_previews);ensure_registered();
    for(auto it=entries.begin();it!=entries.end();) {
        if((*it)->document()!=&doc&&!current(**it,time,unit))it=entries.erase(it);else ++it;
    }
    validate_expected(); // No host callbacks or allocating work before the swap.
    auto existing=find_entry(doc);
    if(existing!=entries.end())existing->swap(next);else entries.push_back(std::move(next));
    doc.disarm_live(); // Diagnostic staging never lets the Live timer publish it.
    changed(true);
}
PreviewInfo preview_info(Document& doc) {
    main_thread();PreviewInfo info;auto entry=find_entry(doc);if(entry==entries.end())return info;
    info.present=true;info.valid=current(**entry,GetCOREInterface()->GetTime(),unit_scale());
    info.box_count=(*entry)->boxes.size();info.stats=(*entry)->stats;info.selected_region_ids=(*entry)->selected;
    info.revision=(*entry)->revision;info.input_epoch=(*entry)->input_epoch;info.time=(*entry)->time;info.reason=reason((*entry)->stale);
    return info;
}
std::vector<std::uint32_t> preview_selection(Document& doc) {
    const auto info=preview_info(doc);
    if(!info.present)throw std::runtime_error("No diagnostic preview exists for this setup; Preview first.");
    if(!info.valid)throw std::runtime_error(info.reason);
    return info.selected_region_ids;
}
std::shared_ptr<const RegionRegistry> preview_regions(Document& doc) {
    main_thread();auto entry=find_entry(doc);
    if(entry==entries.end())throw std::runtime_error("No diagnostic preview exists for this setup; Preview first.");
    if(!current(**entry,GetCOREInterface()->GetTime(),unit_scale()))throw std::runtime_error(reason((*entry)->stale));
    return (*entry)->registry;
}
std::vector<OrientedBox> preview_bounds(Document& doc) {
    main_thread();auto entry=find_entry(doc);
    if(entry==entries.end())throw std::runtime_error("No diagnostic preview exists for this setup; Preview first.");
    if(!current(**entry,GetCOREInterface()->GetTime(),unit_scale()))throw std::runtime_error(reason((*entry)->stale));
    return (*entry)->boxes;
}
bool clear_preview(Document& doc) {
    main_thread();auto entry=find_entry(doc);if(entry==entries.end())return false;
    entries.erase(entry);changed(true);return true;
}
void show_fit_highlight(Document& doc,std::uint64_t asset,std::span<const OrientedBox> boxes,bool suggestion) {
    main_thread();
    const auto feedback=doc.fit_feedback();const auto state=doc.state();
    if(!feedback||!asset||boxes.empty()||boxes.size()>2)throw std::runtime_error("Generate this prop's fit feedback before highlighting.");
    const auto time=GetCOREInterface()->GetTime();const double unit=unit_scale();
    auto next=std::make_unique<Entry>();next->boxes.assign(boxes.begin(),boxes.end());
    for(const auto& box:next->boxes)validate_box(box,unit);
    next->lifetime.SetRef(&doc);next->expected_state=state.get();next->revision=state->revision;
    next->input_epoch=doc.lifecycle().input_epoch;next->dependency_stamp=doc.geometry_ticket();next->time=time;next->mm_per_system_unit=unit;
    ensure_registered();
    if(doc.fit_feedback()!=feedback||doc.state()!=state||GetCOREInterface()->GetTime()!=time||unit_scale()!=unit||!current(*next,time,unit))
        throw std::runtime_error("Fit feedback changed. Generate again before highlighting.");
    fit_highlight.swap(next);fit_asset_id=asset;fit_suggestion=suggestion;fit_draws=0;
    changed(true);
}
bool hide_fit_highlight(Document& doc) {
    main_thread();if(!fit_highlight||fit_highlight->document()!=&doc)return false;
    fit_highlight.reset();fit_asset_id=0;fit_suggestion=false;changed(true);return true;
}
FitHighlightInfo fit_highlight_info(Document& doc) {
    main_thread();FitHighlightInfo info;
    if(!fit_highlight||fit_highlight->document()!=&doc)return info;
    info.present=true;info.valid=current(*fit_highlight,GetCOREInterface()->GetTime(),unit_scale());info.asset_id=fit_asset_id;
    info.draws=fit_draws;info.suggestion=fit_suggestion;info.boxes=fit_highlight->boxes;return info;
}
void shutdown_preview()noexcept {
    try {
        if(registered) {
            auto* ip=GetCOREInterface();if(ip){ip->UnRegisterViewportDisplayCallback(FALSE,&display);ip->UnRegisterTimeChangeCallback(&time_callback);}
            UnRegisterNotification(scene_event,nullptr);registered=false;
        }
        entries.clear();fit_highlight.reset();service_thread=0;
    }catch(...){} // Native module shutdown must not throw across the host boundary.
}
}
