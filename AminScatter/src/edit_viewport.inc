// Host-thread transient mesh transforms. Gesture state borrows the admitted
// source geometry/instance arrays once; each sample stores selected patches.
struct CyrusEditViewportGesture {
    struct Address {std::size_t group=0,raw=0;std::uint32_t row=0;};
    struct Layer {std::shared_ptr<const cyrus::MeshSnapshot> mesh;std::vector<Address> addresses;};
    std::uint64_t controller=0,display=0;
    std::vector<Layer> layers;
    std::shared_ptr<cyrus::PreviewMemory> memory;
};
static cyrus::PointDisplay* editViewportDisplay(std::uint64_t controller){
    const auto found=cyrus::pickDisplays.find(controller);if(found==cyrus::pickDisplays.end())return nullptr;
    auto* value=Animatable::GetAnimByHandle(found->second);
    return value&&value->ClassID()==cyrus::displayID?static_cast<cyrus::PointDisplay*>(value):nullptr;
}
std::shared_ptr<CyrusEditViewportGesture> cyrusBeginEditViewport(std::uint64_t controller,const std::vector<CyrusEditViewportPatch>& patches){
    if(patches.empty()||patches.size()>4096)return {};
    auto* display=editViewportDisplay(controller);if(!display)return {};const auto visible=display->visibleGeneration();if(!visible)return {};
    auto result=std::make_shared<CyrusEditViewportGesture>();result->controller=controller;result->display=display->displayHandle();
    std::map<std::uint64_t,std::unordered_set<std::uint32_t>> wanted;
    for(const auto& patch:patches)wanted[patch.layer].insert(patch.placement.row);
    for(const auto& layer:visible->layers){const auto& mesh=layer.mesh;if(!mesh||!mesh->pickView)continue;
        const auto selected=wanted.find(mesh->pickView->token().owner);if(selected==wanted.end())continue;
        CyrusEditViewportGesture::Layer entry;entry.mesh=mesh;
        for(std::size_t group=0;group<mesh->groups.size();++group){const auto& source=mesh->groups[group];if(!source.pickRows||source.deformation)continue;
            for(std::size_t raw=0;raw<source.pickRows->size();++raw)if(selected->second.count(source.pickRows->at(raw)))entry.addresses.push_back({group,raw,source.pickRows->at(raw)});
        }
        if(!entry.addresses.empty())result->layers.push_back(std::move(entry));
    }
    if(result->layers.empty())return {};
    std::size_t bytes=sizeof(*result)+result->layers.capacity()*sizeof(CyrusEditViewportGesture::Layer);
    for(const auto& layer:result->layers)bytes+=layer.addresses.capacity()*sizeof(CyrusEditViewportGesture::Address);
    result->memory=cyrus::reserveMeshMemory({bytes,0});result->memory->commit();return result;
}
bool cyrusUpdateEditViewport(const std::shared_ptr<CyrusEditViewportGesture>& gesture,std::uint64_t modifier,const std::vector<CyrusEditViewportPatch>& patches){
    if(!gesture)return false;if(patches.size()>4096)throw std::length_error("Edit viewport gesture exceeds 4096 selected instances");
    auto* display=editViewportDisplay(gesture->controller);if(!display||display->displayHandle()!=gesture->display)return false;
    auto* node=static_cast<INode*>(display->controller.GetRef());if(!node)return false;
    const auto current=display->candidate&&!display->candidate->generation->failed.load()?display->candidate->generation:display->visibleGeneration();if(!current)return false;
    auto layers=current->layers;std::vector<cyrus::placements::View> feedback;
    for(const auto& base:gesture->layers){const auto owner=base.mesh->pickView->token().owner;
        auto target=std::find_if(layers.begin(),layers.end(),[&](const auto& layer){return layer.mesh&&layer.mesh->pickView&&layer.mesh->pickView->token().owner==owner;});
        if(target==layers.end()||target->mesh->pickView->token().generation!=base.mesh->pickView->token().generation)throw std::runtime_error("Edit viewport generation changed during the gesture");
        std::map<std::uint32_t,Matrix3> matrices;std::vector<cyrus::placements::TransformPatch> changes;
        for(const auto& patch:patches)if(patch.layer==owner){changes.push_back(patch.placement);Matrix3 matrix(1);for(int r=0;r<4;++r)matrix.SetRow(r,Point3(patch.placement.transform[r*3],patch.placement.transform[r*3+1],patch.placement.transform[r*3+2]));matrices.emplace(patch.placement.row,matrix);}
        if(changes.empty())continue;
        std::vector<cyrus::PreviewGeometry> groups;groups.reserve(base.mesh->groups.size());
        for(std::size_t i=0;i<base.mesh->groups.size();++i){const auto& source=base.mesh->groups[i];cyrus::PreviewGeometry group;
            group.sharedFaces=std::shared_ptr<const decltype(source.faces)>(base.mesh,&source.faceData());group.sharedBounds=base.mesh->localBounds[i];group.sharedFingerprint=base.mesh->faceFingerprints[i];
            group.sharedInstances=std::shared_ptr<const decltype(source.instances)>(base.mesh,&source.instanceData());group.sharedBands=std::shared_ptr<const decltype(source.bandSlots)>(base.mesh,&source.bandData());
            group.sharedWorldBounds=base.mesh->groupBounds[i];group.sharedInstanceFingerprint=base.mesh->instanceFingerprints[i];group.pickRows=source.pickRows;group.color=source.color;group.placeholder=source.placeholder;group.reducedBox=source.reducedBox;group.deformation=source.deformation;group.edits=source.edits;group.editsMemory=source.editsMemory;
            std::shared_ptr<cyrus::SparseInstances<Matrix3>> edits;
            for(const auto& address:base.addresses)if(address.group==i){const auto matrix=matrices.find(address.row);if(matrix==matrices.end())continue;
                if(!edits)edits=source.edits?std::make_shared<cyrus::SparseInstances<Matrix3>>(*source.edits):std::make_shared<cyrus::SparseInstances<Matrix3>>();edits->transforms[address.raw]=matrix->second;}
            if(edits){edits->seal(group.instanceData().size());group.edits=std::move(edits);group.editsMemory=cyrus::reserveMeshMemory({group.edits->bytes(),0});group.editsMemory->commit();}
            groups.push_back(std::move(group));
        }
        auto mesh=std::make_shared<cyrus::MeshSnapshot>(std::move(groups));auto view=base.mesh->pickView->withTransforms(changes);mesh->pickView=std::make_shared<const cyrus::placements::View>(view);target->mesh=std::move(mesh);feedback.push_back(std::move(view));
    }
    if(feedback.empty())return false;
    auto captured=cyrusCaptureEditFeedback(node,feedback,modifier);return display->publish(node,std::move(layers),std::move(captured));
}
