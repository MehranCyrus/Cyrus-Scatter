// Included inside PointDisplay and the SDK-free production-body fixture.
std::shared_ptr<RenderBundle> visibleBundle() const {
    const auto ticket=presentation->visibleTicket();
    if(candidate&&candidate->generation->ticket==ticket&&candidate->generation->complete())return candidate;
    if(retained&&retained->generation->ticket==ticket&&retained->generation->complete())return retained;
    return {};
}
std::shared_ptr<Generation> visibleGeneration() const {
    const auto bundle=visibleBundle();return bundle?bundle->generation:nullptr;
}
// Called only on the host thread. A worker's readiness/failure requests one
// container update; the SDK display-update boundary performs the actual swap.
void requestPresentationUpdate() {
    if(!candidate||presentationRefreshRequested)return;
    const auto& next=candidate->generation;
    if((next->complete()&&presentation->visibleTicket()!=next->ticket)||
       (next->failed.load()&&!candidate->items.empty())) {
        presentationRefreshRequested=true;
        NotifyDependents(FOREVER,PART_GEOM|PART_DISPLAY,REFMSG_CHANGE);
    }
}
void settlePresentation() {
    if(!candidate)return;
    const auto& next=candidate->generation;
    if(next->complete()) {
        if(presentation->commit(next->ticket)) {
            if(retained)retained->generation->enabled=false;
            retained.reset();
        }
    } else if(next->failed.load()) {
        // Stop owning failed SDK resources once the host can rebuild its
        // container. SDK pins and an in-flight Realize retain their own leases.
        std::lock_guard<std::mutex> lock(candidate->realizeMutex);
        candidate->items.clear();candidate->itemBounds.clear();
    }
    presentationRefreshRequested=false;
}
