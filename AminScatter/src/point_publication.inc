// Included inside PointDisplay and the SDK-free publication regression fixture.
// All potentially allocating render-item preparation precedes publication.
bool publish(INode* node,std::vector<PointLayer> layers) {
    if(generation && !generation->failed.load() && sameLayers(generation->layers,layers)) {
        controller.SetRef(node);controller.update();return true;
    }
    // Keep the old reservation alive during admission. A replacement can be
    // rejected at peak coexistence; rejection must retain the previous result.
    auto next=std::make_shared<Generation>(std::move(layers));
    if(next->failed.load()) return false;
    std::vector<RefPtr<ICustomRenderItem>> nextItems;
    std::vector<Box3> nextBounds;
    nextItems.reserve(next->groups);nextBounds.reserve(next->groups);
    for(std::size_t l=0;l<next->layers.size();++l) {
        const auto& layer=next->layers[l];
        for(std::size_t g=0;g<layer.snapshot->groups.size();++g)
            if(!layer.snapshot->groups[g].points.empty()) {
                const PointItem* previous=nullptr;
                for(const auto& item:items) {
                    const auto* candidate=dynamic_cast<const PointItem*>(item.GetPointer());
                    if(candidate && candidate->reusable(layer,g)) { previous=candidate;break; }
                }
                nextItems.emplace_back(new PointItem(next,l,g,previous));
                nextBounds.push_back(layer.snapshot->groupBounds[g]);
            }
        if(layer.mesh) for(std::size_t g=0;g<layer.mesh->groups.size();++g)
            if(!layer.mesh->groups[g].faces.empty() && !layer.mesh->groups[g].instances.empty()) {
                const MeshItem* previous=nullptr;
                for(const auto& item:items) {
                    const auto* candidate=dynamic_cast<const MeshItem*>(item.GetPointer());
                    if(candidate && candidate->reusable(layer,g)) { previous=candidate;break; }
                }
                nextItems.emplace_back(new MeshItem(next,l,g,previous));
                nextBounds.push_back(layer.mesh->groupBounds[g]);
            }
    }
    controller.SetRef(node);
    if(generation) generation->enabled=false;
    generation.swap(next);items.swap(nextItems);itemBounds.swap(nextBounds);
    controller.generation=generation;controller.update();++revision;
    NotifyDependents(FOREVER,PART_GEOM|PART_DISPLAY,REFMSG_CHANGE);
    return true;
}
