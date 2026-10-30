// Independent affine-box oracle and broad-response ownership/visibility tests.
void sceneAdaptation(){
    prep::Snapshot trunk;
    for(unsigned ring=0;ring<7;++ring)for(unsigned side=0;side<6;++side){const double angle=side*6.283185307179586/6;trunk.positions.push_back({float(.05*std::cos(angle)),float(.05*std::sin(angle)),float(ring/3.)});}
    for(unsigned ring=0;ring<6;++ring)for(unsigned side=0;side<6;++side){unsigned a=ring*6+side,b=ring*6+(side+1)%6;trunk.faces.push_back({a,b,b+6});trunk.faces.push_back({a,b+6,a+6});}
    for(unsigned side=1;side<5;++side){trunk.faces.push_back({0,side+1,side});trunk.faces.push_back({36,36+side,37+side});}
    trunk.materials.assign(trunk.faces.size(),0);auto trunkSource=prepareSource(trunk);
    require(trunkSource->rig->guides.size()==1&&trunkSource->roots==1,"A capped 2m trunk with 5cm radius prepares through ordered rings without the former absolute width cap");
    auto box=cube(1);Transform affine;affine.rows[0]={2,0,0};affine.rows[1]={0,.25,0};affine.rows[2]={0,0,.5};
    auto cooked=box->bakeLinear(affine);
    for(auto p:{Vec{0,0,0},Vec{2.1,0,0},Vec{0,.4,0},Vec{0,0,.8}}){
        const double outside=length({std::max(std::abs(p.x)-2.,0.),std::max(std::abs(p.y)-.25,0.),std::max(std::abs(p.z)-.5,0.)});
        const double expected=outside>0?outside:std::max({std::abs(p.x)-2.,std::abs(p.y)-.25,std::abs(p.z)-.5});
        require(std::abs(cooked->point(p).gap-expected)<1e-9,"Scaled collider distances match independent rectangular-box oracle");
    }
    affine.rows[0].x=-2;require(box->bakeLinear(affine)->point({0,0,0}).gap<0,"Mirrored collider retains solid classification");
    affine.rows[0]={0,0,0};rejects([&]{box->bakeLinear(affine);});
    auto source=prepareSource(bladeSource());Shape obstacle{1,cube(.1),{}};
    auto pruned=adaptSource(*source,{obstacle},0,0,2,1,0,91);
    require(pruned.prunedGuides==2&&pruned.allHidden,"Prune mode masks every eligible independent branch without a root solver failure");
    require(pruned.meshRefinementWork==0&&pruned.meshRefinements==0,"Broad adaptation never enters the detailed visible-mesh refinement loop");
    auto compact=deformationSource(source);auto words=deformationPose(*compact,pruned);
    for(unsigned face=0;face<compact->faces.size();++face)require(!deformationVisible(*compact,words,face)&&!visibleFace(*source,pruned,compact->faces[face]),"CPU and compact GPU branch masks agree");
    auto retained=adaptSource(*source,{obstacle},0,0,2,0,0,91);
    require(!retained.changed&&retained.queries==0&&retained.blockedGuides==0,"Zero prune amount retains guides without probing disabled contacts");
    auto threshold=adaptSource(*source,{obstacle},0,0,2,1,1,91);
    require(!threshold.changed&&threshold.blockedGuides==2,"Penetration threshold controls pruning independently of bend clearance");
    auto restored=adaptSource(*source,{},0,.5,3,1,0,91);
    require(!restored.changed&&restored.prunedGuides==0,"Move-away response restores original rest geometry");
    auto fixed=adaptSource(*source,{obstacle},0,1,1,1,0,91,1,1,.25,false);
    require(!fixed.changed&&fixed.queries==0,"Fully fixed Bend retains rest geometry without contact queries");
    auto noBend=adaptSource(*source,{obstacle},0,0,1,1,0,91,1,0,.25,false);
    require(!noBend.changed&&noBend.queries==0,"Zero Bend strength bypasses contact queries");
    auto fixedTrim=adaptSource(*source,{obstacle},0,1,3,1,0,91,1,1,.25,false);
    require(fixedTrim.prunedGuides==2&&fixedTrim.queries>0,"Fixed Bend does not disable independent Trim");
    auto fixedCover=adaptSource(*source,{obstacle},0,0,1,1,0,91,1,1,.25,true);
    require(fixedCover.coveredRoots==2&&fixedCover.coverageQueries>0&&fixedCover.queries==0,"Disabled Bend keeps root coverage active");
    // Make a two-guide structural forest with an explicit child. The trunk
    // cannot disappear merely because its root is inside an obstacle.
    auto tree=std::make_shared<Source>(*source);auto rig=std::make_shared<stem::Prepared>(*source->rig);tree->rig=rig;
    rig->guides[1].parent=0;rig->guides[1].parentSpan=0;rig->guides[1].parentU=.5;rig->order={0,1};tree->guideRoot[1]=0;
    // Match the immutable topology cache that prepareSource builds in production.
    tree->structuralGuides={true,false};
    auto subtree=adaptSource(*tree,{obstacle},0,0,2,1,0,91);
    require(!subtree.hiddenGuides[0]&&subtree.hiddenGuides[1]&&subtree.blockedGuides==0,"Structural trunk survives without a disabled contact probe while an eligible child is pruned");
    auto carried=std::make_shared<Source>(*tree);auto carriedRig=std::make_shared<stem::Prepared>(*rig);carried->rig=carriedRig;
    auto& child=carriedRig->guides[1];child.parentSpan=1;child.parentU=.5;
    carried->guideBounds[1]={};
    for(auto& p:child.rest.nodes){p.y*=.1;carried->guideBounds[1].include(p);}
    auto following=adaptSource(*carried,{obstacle},0,1,1,0,0,91,1,.25,.25,false);
    require(following.guides[0]&&following.guides[1],"A child below the fixed height still follows its bending parent");
    require(length(sub(following.guides[1]->nodes.front(),child.rest.nodes.front()))>1e-6,"The disabled child's attachment moves with its parent");
    for(unsigned i=1;i<child.rest.nodes.size();++i)require(std::abs(length(sub(following.guides[1]->nodes[i],following.guides[1]->nodes[0]))-length(sub(child.rest.nodes[i],child.rest.nodes[0])))<1e-12,"Parent propagation preserves the disabled child's shape");
    auto definition=std::make_shared<Definition>();definition->rig=source;definition->geometryBounds=source->bounds;
    auto layout=std::make_shared<Layout>();layout->layers={LayerSettings{}};layout->layers[0].react=true;layout->layers[0].coverRoots=false;layout->layers[0].response=2;layout->sources={{definition}};
    Instance plant;plant.identity="tree:a";plant.hostTransform={1,0,0,0,1,0,0,0,1,0,0,0};layout->instances={plant};
    SceneObstacle wall{"scene:wall",cube(.1),{}};wall.transform.rows[0]={2,0,0};layout->sceneObstacles={wall};
    Engine engine(layout);auto first=engine.evaluate({});require(first->poses.at(0)->prunedGuides==2,"Ordinary scene collider participates without a scattered obstacle instance");
    auto moved=first->sceneTransforms;moved[0].rows[3]={3,0,0};auto second=engine.evaluate(first,{}, {},{},moved);
    require(second->poses.empty()&&second->statistics.restored==1,"Old and new scene-collider bounds restore leaving plants");
    require(second->worldObstacles[0].geometry==first->worldObstacles[0].geometry,"Translation reuses the immutable affine collision copy");
    require(engine.evaluate(second)==second,"Unchanged scene transforms reuse the whole publication");
    moved[0].rows[0]={0,0,0};rejects([&]{engine.evaluate(second,{}, {},{},moved);});require(second->poses.empty(),"Rejected collapsed successor leaves complete prior state intact");
    auto neighborLayout=std::make_shared<Layout>(*layout);neighborLayout->sceneObstacles.clear();neighborLayout->layers[0].neighbors=true;auto peer=plant;peer.identity="tree:b";neighborLayout->instances.push_back(peer);
    Engine neighbors(neighborLayout);auto neighborResult=neighbors.evaluate({});
    require(!neighborResult->poses.contains(0)&&neighborResult->poses.contains(1),"Stable lower identity keeps priority; only the yielding neighbor adapts");
    require(neighbors.evaluate(neighborResult)==neighborResult,"Neighbor adaptation is deterministic and has no feedback iterations");
    std::cout<<"PASS affine scene boxes, broad pruning/retention/thresholds, structural trunk, GPU/CPU masks, local restore and stable neighboring-tree priority\n";
}
