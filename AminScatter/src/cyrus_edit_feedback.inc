// Bounded host-thread bridge to the renderer's actual commit. Snapshots own
// immutable CPU feedback only; their destruction has no host callbacks.
struct CyrusEditFeedback {
    struct Layer {int key=0;std::shared_ptr<const EditPresentation> presentation;std::shared_ptr<const EditPublishedLocal> local;};
    struct Target {AnimHandle modifier=0;unsigned revision=0;ce::Vector<Layer> layers;};
    AnimHandle owner=0;std::uint64_t serial=0;ce::Vector<Target> targets;
};
namespace {
std::uint64_t nextEditFeedbackSerial=0;
static CSEdit* feedbackModifier(AnimHandle handle)noexcept{
    auto* value=Animatable::GetAnimByHandle(handle);return value&&value->ClassID()==CS_EDIT_ID?static_cast<CSEdit*>(value):nullptr;
}
}
std::shared_ptr<const CyrusEditFeedback> cyrusCaptureEditFeedback(INode* node){
    if(!node)return {};
    auto result=ce::make<CyrusEditFeedback>();result->owner=Animatable::GetHandleByAnim(node);
    if(nextEditFeedbackSerial==std::uint64_t(INT64_MAX))throw std::overflow_error("Edit feedback ticket exhausted");result->serial=++nextEditFeedbackSerial;
    auto* object=node->GetObjectRef();unsigned depth=0,totalLayers=0;
    while(object&&object->SuperClassID()==GEN_DERIVOB_CLASS_ID){
        if(++depth>256)throw std::length_error("Edit feedback modifier stack exceeds its bound");
        auto* derived=static_cast<IDerivedObject*>(object);
        for(int i=0;i<derived->NumModifiers();++i){auto* modifier=derived->GetModifier(i);if(!modifier||modifier->ClassID()!=CS_EDIT_ID)continue;
            if(result->targets.size()>=256)throw std::length_error("Edit feedback modifier inventory exceeds its bound");
            auto* edit=static_cast<CSEdit*>(modifier);CyrusEditFeedback::Target target;target.modifier=Animatable::GetHandleByAnim(edit);target.revision=edit->localRevision;
            for(const auto& [key,layer]:edit->layers){if(++totalLayers>4096)throw std::length_error("Edit feedback layer inventory exceeds its bound");target.layers.push_back({key,layer.presentation,layer.publishedLocal});}
            result->targets.push_back(std::move(target));
        }
        object=derived->GetObjRef();
    }
    return result->targets.empty()?std::shared_ptr<const CyrusEditFeedback>{}:result;
}
void cyrusStageEditFeedback(const std::shared_ptr<const CyrusEditFeedback>& feedback,bool retainVisible)noexcept{
    if(!feedback||!Animatable::GetAnimByHandle(feedback->owner))return;
    for(const auto& target:feedback->targets)if(auto* modifier=feedbackModifier(target.modifier)){
        if(modifier->feedbackOwner==feedback->owner&&modifier->feedbackStage>feedback->serial)continue;
        const bool sameOwner=modifier->feedbackOwner==feedback->owner;modifier->feedbackOwner=feedback->owner;modifier->feedbackStage=feedback->serial;
        // Once this authored revision reaches full display staging, the normal
        // committed-feedback rules own handles again, including GPU failure.
        if(target.revision==modifier->localRevision&&modifier->transformPreview){modifier->transformPreview=false;modifier->refreshFeedback();}
        for(auto& [key,layer]:modifier->layers){(void)key;layer.rendererManaged=true;if(!sameOwner||!retainVisible){layer.displayedPresentation.reset();layer.displayedLocal.reset();}}
    }
}
void cyrusPresentEditFeedback(const std::shared_ptr<const CyrusEditFeedback>& feedback)noexcept{
    if(!feedback||!Animatable::GetAnimByHandle(feedback->owner))return;
    for(const auto& target:feedback->targets)if(auto* modifier=feedbackModifier(target.modifier)){
        if(modifier->feedbackOwner!=feedback->owner||modifier->feedbackStage!=feedback->serial)continue;
        bool changed=false;
        for(const auto& published:target.layers){const auto found=modifier->layers.find(published.key);if(found==modifier->layers.end())continue;
            changed|=found->second.displayedPresentation!=published.presentation||found->second.displayedLocal!=published.local;
            found->second.displayedPresentation=published.presentation;found->second.displayedLocal=published.local;found->second.rendererManaged=true;}
        // Nitrous can present an unchanged retained bundle during a gesture.
        // Only feedback captured from this authored revision ends its preview.
        if(target.revision==modifier->localRevision)modifier->transformPreview=false;
        if(changed)modifier->refreshFeedback();
    }
}
void cyrusReleaseEditFeedback(const std::shared_ptr<const CyrusEditFeedback>& feedback)noexcept{
    if(!feedback)return;
    for(const auto& target:feedback->targets)if(auto* modifier=feedbackModifier(target.modifier)){
        // A superseded snapshot cannot detach a newer staged/visible owner.
        if(modifier->feedbackOwner!=feedback->owner||modifier->feedbackStage!=feedback->serial)continue;
        modifier->feedbackOwner=0;modifier->feedbackStage=0;
        for(auto& [key,layer]:modifier->layers){(void)key;layer.rendererManaged=false;layer.displayedPresentation.reset();layer.displayedLocal.reset();}
    }
}
