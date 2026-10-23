// Included inside PointDisplay and the SDK-free publication regression fixture.
// All potentially allocating render-item preparation precedes publication.
bool publish(INode* node,std::vector<PointLayer> layers) {
    if(candidate && !candidate->generation->failed.load() && sameLayers(candidate->generation->layers,layers)) {
        controller.SetRef(node);controller.update();requestPresentationUpdate();return true;
    }
    // Keep the old reservation alive during admission. A replacement can be
    // rejected at peak coexistence; rejection must retain the previous result.
    auto nextGeneration=std::make_shared<Generation>(std::move(layers));
    if(nextGeneration->failed.load()) return false;
    if(revision==std::numeric_limits<std::uint64_t>::max())throw std::overflow_error("Viewport publication ticket exhausted");
    nextGeneration->presentation=presentation;nextGeneration->ticket=revision+1;
    auto next=std::make_shared<RenderBundle>(nextGeneration);nextGeneration->realization=next;
    next->items.reserve(nextGeneration->groups);next->itemBounds.reserve(nextGeneration->groups);
    // A fully ready, not-yet-presented candidate can share its resources, but
    // only the actual visible bundle is eligible as the failure fallback.
    const auto visible=visibleBundle();
    const auto reuse=candidate&&candidate->generation->complete()?candidate:visible;
    for(std::size_t l=0;l<nextGeneration->layers.size();++l) {
        const auto& layer=nextGeneration->layers[l];
        for(std::size_t g=0;g<layer.snapshot->groups.size();++g)
            if(!layer.snapshot->groups[g].points.empty()) {
                const PointItem* previous=nullptr;
                if(reuse)for(const auto& item:reuse->items) {
                    const auto* candidate=dynamic_cast<const PointItem*>(item.GetPointer());
                    if(candidate && candidate->reusable(layer,g)) { previous=candidate;break; }
                }
                next->items.emplace_back(new PointItem(nextGeneration,l,g,previous));
                next->itemBounds.push_back(layer.snapshot->groupBounds[g]);
            }
        if(layer.mesh) for(std::size_t g=0;g<layer.mesh->groups.size();++g)
            if(!layer.mesh->groups[g].faces.empty() && !layer.mesh->groups[g].instances.empty()) {
                const MeshItem* previous=nullptr;
                // Prefer the corresponding old slot when its geometry still
                // matches. Identical source shapes in separate layers can
                // carry different immutable instance streams; a first shape
                // match alone must not hide the exact stream later in the list.
                if(reuse)for(const auto& item:reuse->items) {
                    const auto* candidate=dynamic_cast<const MeshItem*>(item.GetPointer());
                    if(candidate && candidate->sameSlot(l,g) && candidate->reusable(layer,g)) {
                        previous=candidate;break;
                    }
                }
                if(reuse&&(!previous||!previous->sameInstances(layer,g)))for(const auto& item:reuse->items) {
                    const auto* candidate=dynamic_cast<const MeshItem*>(item.GetPointer());
                    if(candidate && candidate!=previous && candidate->reusable(layer,g)) {
                        if(!previous)previous=candidate;
                        if(candidate->sameInstances(layer,g)){previous=candidate;break;}
                    }
                }
                next->items.emplace_back(new MeshItem(nextGeneration,l,g,previous));
                next->itemBounds.push_back(layer.mesh->groupBounds[g]);
            }
    }
    controller.SetRef(node);
    if(candidate&&candidate!=visible)candidate->generation->enabled=false;
    retained=visible;candidate=std::move(next);
    revision=nextGeneration->ticket;presentation->stage(revision);
    controller.generation=nextGeneration;controller.update();presentationRefreshRequested=false;
    // Empty or wholly reused successors have no pending SDK work. Other
    // successors remain invisible until a host container update sees all ready.
    if(nextGeneration->complete())settlePresentation();
    NotifyDependents(FOREVER,PART_GEOM|PART_DISPLAY,REFMSG_CHANGE);
    return true;
}
