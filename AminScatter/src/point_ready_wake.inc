// Included after pure resource realization, including by the SDK-free fixture.
// At most one wake per generation; no scene API or publication on this worker.
if((generation->complete()||generation->failed.load(std::memory_order_acquire))&&
   !generation->editWakePosted.exchange(true,std::memory_order_acq_rel))
    cyrusWakeEditFrameReady(generation->editFeedback,generation->displayOwner);
