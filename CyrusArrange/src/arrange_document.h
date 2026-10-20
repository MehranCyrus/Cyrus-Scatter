#pragma once
#include "cyrus_arrange/document_state.h" // Include before MAXScript macros.
#include "cyrus_arrange/geometry_cache.h"
#include <max.h>
#include <IRefTargContainer.h>
#include <array>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <utility>
#include <vector>

namespace cyrus::arrange::host {
class Document;
class CommandDependencyWatch;
class DependencyCommandScope;
enum class DependencyOrigin : std::uint8_t { Other,Reference,CommandWatch,Hierarchy,Time,Scene,Restore,Owner,Output };
struct DependencyEventDetail {
    DependencyOrigin origin{DependencyOrigin::Other};
    std::uint32_t message{},role_mask{};
    std::uint64_t part{},sender{},actual_sender{};
    std::int32_t changed_index{-1};
    bool constructing{};
};
struct CommandDependencyTicket {
    std::uint64_t document_instance{},scene{},dependency{},command_serial{};
    const DependencyCommandScope* scope{}; // Borrowed, valid only inside this command.
};
// Mandatory current-input observation, independent of optional numeric reuse.
// Caller keeps Document/owner alive, cancels/accepts its hold and restores
// updating before destruction. Never retain a ticket beyond this scope.
class DependencyCommandScope {
    Document* document_{};
    std::uint64_t serial_{};
    bool invalidated_{};
    struct FirstInvalidation {
        DependencyEventDetail event;
        cache::Reason reason{};
        std::uint64_t geometry_before{},geometry_after{},dependency_before{},dependency_after{};
        bool updating{},restoring{},initializing{},installing{};
    } first_;
    friend class Document;
public:
    explicit DependencyCommandScope(Document&);
    DependencyCommandScope(const DependencyCommandScope&)=delete;
    DependencyCommandScope& operator=(const DependencyCommandScope&)=delete;
    ~DependencyCommandScope() noexcept;
};
struct Bindings {
    std::vector<INode*> furniture;
    std::vector<INode*> assets; // Same order as DocumentState.assets.
    std::vector<INode*> outputs; // Same order as DocumentState.placements.
    std::vector<INode*> obstacles; // Independent collision roots, never support sources.
    std::vector<INode*> paths; // One real path slot when DocumentState.path is present.
};
enum Dirty : std::uint32_t {
    DirtyNone=0, DirtyAuthored=1, DirtyGeometry=2, DirtyTransform=4,
    DirtyMissingBinding=8, DirtyOutput=16, DirtyTime=32, DirtyUnits=64,
    DirtyLoaded=128, DirtyCloned=256
};
struct Lifecycle {
    std::uint32_t dirty{DirtyAuthored};
    std::uint64_t input_epoch{1}, attempted_epoch{};
    bool updating{}, live_armed{};
    std::string error;
    std::optional<CompositionStats> composition_stats; // Transient last successful generation only.
};

class Document final : public ReferenceTarget, public TimeChangeCallback {
public:
    explicit Document(bool loading=false);
    ~Document() override;
    void DeleteThis() override;
    Class_ID ClassID() override;
    SClass_ID SuperClassID() override;
    void GetClassName(MSTR&,bool localized=true) const override;
    int NumRefs() override;
    RefTargetHandle GetReference(int) override;
    void SetReference(int,RefTargetHandle) override;
    RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID&,RefMessage,BOOL) override;
    RefTargetHandle Clone(RemapDir&) override;
    IOResult Save(ISave*) override;
    IOResult Load(ILoad*) override;
    void TimeChanged(TimeValue) override;

    std::shared_ptr<const DocumentState> state() const noexcept { return state_; }
    const Lifecycle& lifecycle() const noexcept { return lifecycle_; }
    Bindings bindings() const;
    INode* owner() const;
    // UI/root supplies a complete staged successor and positional real references.
    // One Undo transaction includes state and the native containers. Source/output
    // materialization/deletion by root must use that same outer transaction.
    void commit(std::shared_ptr<const DocumentState>,const Bindings&,const MCHAR* undo_label,bool published=false);
    // IDs are monotonic even across Undo/cancel; high-water is saved separately.
    std::uint64_t reserve_ids(std::size_t count);
    void mark_dirty(std::uint32_t reason,const char* message=nullptr) noexcept;
    void mark_clean(TimeValue,const Interval& input_validity=FOREVER) noexcept;
    void set_error(const std::string&);
    void set_updating(bool value) noexcept;
    void disarm_live() noexcept { lifecycle_.live_armed=false; }
    void record_composition_stats(const CompositionStats& stats) noexcept { lifecycle_.composition_stats=stats; }
    void record_fit_feedback(std::shared_ptr<const FitFeedback> value) noexcept {
        feedback_state_=state_.get();feedback_epoch_=lifecycle_.input_epoch;feedback_ticket_=geometry_ticket();feedback_=std::move(value);
    }
    std::shared_ptr<const FitFeedback> fit_feedback() const noexcept {
        return feedback_&&feedback_state_==state_.get()&&feedback_epoch_==lifecycle_.input_epoch&&feedback_ticket_.valid()&&feedback_ticket_==geometry_ticket()?feedback_:std::shared_ptr<const FitFeedback>{};
    }
    void bind_owner(INode*);
    void finish_load(); // Called only by a late post-load callback.
    void finish_clone(std::shared_ptr<const DocumentState>,const Bindings&,INode* mapped_owner);
    cache::Ticket geometry_ticket() const noexcept;
    CommandDependencyTicket dependency_ticket() const noexcept;
    bool dependencies_unchanged(const CommandDependencyTicket&) const noexcept;
    // Failure-only internal diagnostic; never called by reference callbacks.
    std::string dependency_failure_detail(const CommandDependencyTicket&) const;
    void record_cache_command(const cache::CommandMetrics& value) noexcept { last_cache_command_=value; }
    std::optional<cache::CommandMetrics> last_cache_command() const noexcept { return last_cache_command_; }
    // Internal callback observer: no capture/solve, allocation or payload release.
    // Dirty scheduling is separate from conservative cache invalidation.
    void observe_input_change(cache::Reason,std::uint32_t dirty=DirtyNone,DependencyEventDetail={}) noexcept;
    // Callback-only membership filter for the older serialized descendant
    // container. Unknown senders must still be handled conservatively.
    bool observes_current_input(RefTargetHandle) const noexcept;

private:
    // Keep existing slots stable: 0 owner, 1 furniture, 2 assets, 3 outputs,
    // 4 derived descendants, 5 independent obstacles, 6 path node (schema6).
    std::array<RefTargetHandle,7> refs_{};
    std::shared_ptr<const DocumentState> state_;
    Lifecycle lifecycle_;
    std::uint64_t id_high_water_{1};
    Interval input_validity_{NEVER};
    TimeValue valid_capture_time_{};
    bool restoring_{}, initializing_{true};
    std::uint64_t geometry_instance_{},next_command_serial_{};
    cache::Epoch geometry_epoch_,dependency_epoch_;
    DependencyCommandScope* active_command_{};
    // Current expanded input observation is transient host ownership, separate
    // from numeric cache data and the seven serialized/Undo references. A staged
    // replacement never destroys its predecessor before it is complete.
    std::unique_ptr<CommandDependencyWatch> input_watch_;
    bool input_watch_retired_{},input_owner_detached_{};
    std::uint32_t deferred_input_dirty_{},installing_bindings_{};
    bool committing_{};
    TimeValue dependency_time_{};
    std::optional<cache::CommandMetrics> last_cache_command_;
    // Not serialized or included in Lifecycle/Undo. Callbacks invalidate stamps
    // only; a normal generation/destruction boundary releases old numeric rows.
    std::shared_ptr<const FitFeedback> feedback_;
    const DocumentState* feedback_state_{};
    std::uint64_t feedback_epoch_{};
    cache::Ticket feedback_ticket_;
    IRefTargContainer* container(int group) const;
    void initialize_references();
    void install_bindings(const Bindings&);
    void restore_state(std::shared_ptr<const DocumentState>,const Lifecycle&) noexcept;
    void drain_deferred_dirty() noexcept;
    void drain_input_watch() noexcept; // Ordinary main-thread boundary only.
    void record_dependency_failure(cache::Reason,DependencyEventDetail,std::uint64_t geometry_before,std::uint64_t dependency_before) noexcept;
    friend class StateRestore;
    friend class DependencyCommandScope;
    friend class CommandDependencyWatch;
    friend class BindingInstallScope;
    friend void remove_document(INode*);
    friend std::size_t process_live_updates(std::size_t);
};

// All factories/getters and service calls require Max's main thread.
INode* create_setup(const MCHAR* name=_T("CyrusArrange_Setup"));
// Explicit creation/binding command only. Passive panel discovery never calls it.
Document* initialize_setup(INode*);
Document* get_document(INode* setup,bool required=true);
struct SceneSetupRow {
    INode* owner{};
    bool matched{};
    std::vector<INode*> furniture;
};
// Passive bounded discovery of actually attached current-scene documents.
// Matches selected owners, real outputs and furniture group hierarchies only;
// never repairs owner monitors, evaluates geometry or trusts user properties.
std::vector<SceneSetupRow> scene_setups(std::span<INode* const> selected);
void remove_document(INode* setup); // Native attributes only; ordinary outputs survive.
Class_ID document_class_id();
Class_ID owner_attribute_class_id();
void set_document_module(HINSTANCE);

using UpdateCallback=void(*)(INode*,Document&);
void set_live_update_callback(UpdateCallback);
// Native service timer runs on Max's main thread, never inside reference callbacks.
// Root may also call process_live_updates from its bounded caTick command.
std::size_t process_live_updates(std::size_t maximum_documents=4);
void flush_dependency_events();
void stop_document_service() noexcept;
// Nullable access does not create the optional cache. Creation/release happen
// only at ordinary main-thread boundaries, never reference callbacks/drawing.
cache::GeometryCache* geometry_cache() noexcept;
cache::GeometryCache* ensure_geometry_cache() noexcept;
void defer_geometry_cache_document(std::uint64_t,cache::Reason) noexcept;
void defer_geometry_cache_all(cache::Reason) noexcept;
void drain_geometry_cache() noexcept;
void shutdown_geometry_cache() noexcept;
}

extern "C" __declspec(dllexport) ClassDesc* CyrusArrangeDocumentDesc();
extern "C" __declspec(dllexport) ClassDesc* CyrusArrangeOwnerDesc();
