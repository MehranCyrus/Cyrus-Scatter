// Regression cases from the 0.87.6.2 system review. Actual engine transitions
// and presentation policies supplement the local deformation parameter tests.
void reviewRoleTransitions(){
    auto a=std::make_shared<Definition>();a->rig=prepareSource(bladeSource());a->geometryBounds=a->rig->bounds;
    auto raw=bladeSource();for(auto& p:raw.positions)p[0]*=1.1f;
    auto b=std::make_shared<Definition>();b->rig=prepareSource(raw);b->geometryBounds=b->rig->bounds;
    auto make=[&](int role){
        auto l=std::make_shared<Layout>();l->layers.resize(2);l->sources={{a},{b}};
        for(auto& cfg:l->layers){cfg.react=true;cfg.neighbors=true;cfg.response=2;cfg.coverRoots=false;}
        l->layers[0].react=role==2;l->layers[0].obstacle=role==1;
        if(role==1){auto d=std::make_shared<Definition>();d->collider=cube(.01);d->geometryBounds=d->collider->bounds();l->sources[0][0]=d;}
        Instance x;x.layer=0;x.identity="edited-a";x.hostTransform={1,0,0,0,1,0,0,0,1,1000,0,0};
        Instance y=x;y.layer=1;y.identity="peer-b";y.hostTransform[9]=0;l->instances={x,y};return l;
    };
    auto active=make(2);auto moved=active->transform(0);moved.rows[3]={0,0,0};
    Engine on(active);const auto before=on.evaluate({},{{0,moved}});require(!before->poses.empty(),"Neighbor role control must actually prune a peer");
    for(int role:{0,1,2,0,2}){
        auto layout=make(role);Engine engine(layout);auto state=engine.evaluate({},{{0,moved}});
        if(role==0)require(state->poses.empty(),"Off role cannot contribute a retained neighbor preference");
        auto away=moved;away.rows[3].x=20;
        auto next=engine.evaluate(state,{{0,away}},{0});require(next->poses.empty(),"Move-away restores peers after every role transition");
        auto restored=engine.evaluate(next,{{0,moved}},{0});
        require(restored->poses.size()==state->poses.size(),"Returning edited actor preserves role participation");
        auto disabled=engine.evaluate(restored,{{0,moved}},{0},{0});require(disabled->poses.empty(),"Disabled edited neighbor/collider does not affect peer");
        auto enabled=engine.evaluate(disabled,{{0,moved}},{0},{});require(enabled->poses.size()==state->poses.size(),"Undo disable restores the same role response");
        require(engine.evaluate(enabled,{{0,moved}})==enabled,"Unchanged role result reuses immutable publication");
    }
    require(before->poses.size()==1,"Other role successors do not mutate retained active result");
}
void reviewHidingCandidates(){
    auto source=prepareSource(bladeSource());auto def=std::make_shared<Definition>();def->rig=source;def->geometryBounds=source->bounds;
    for(int response=0;response<4;++response)for(bool under:{false,true})for(bool scene:{false,true}){
        auto l=std::make_shared<Layout>();l->layers.resize(2);auto& c=l->layers[0];
        c.react=true;c.response=response;c.strength=0;c.pruneAmount=0;c.coverRoots=true;c.hideMargin=under?0:.3;c.hideUnder=under;c.gap=0;
        auto stone=std::make_shared<Definition>();stone->collider=cube(.005);stone->geometryBounds=stone->collider->bounds();l->sources={{def},{stone}};
        Instance plant;plant.identity="plant";plant.hostTransform={1,0,0,0,1,0,0,0,1,0,0,0};l->instances={plant};
        Transform tm;tm.rows[3]=under?Vec{-.03,1,0}:Vec{.25,0,0};
        if(scene)l->sceneObstacles={{"cover",stone->collider,tm}};
        else {Instance item=plant;item.layer=1;item.identity="collider";item.hostTransform[9]=float(tm.rows[3].x/l->metresPerUnit);item.hostTransform[11]=float(tm.rows[3].y/l->metresPerUnit);l->instances.push_back(item);l->layers[1].obstacle=true;}
        Engine engine(l);auto a=engine.evaluate({});
        require(a->statistics.hiddenRoots==(under?1u:2u),"All response modes admit overhead/margin root coverage");
        tm.rows[3].x=10;
        auto b=scene?engine.evaluate(a,{}, {},{}, {tm}):engine.evaluate(a,{{1,tm}},{1});
        require(b->poses.empty(),"Move-away restores coverage in every response and collider kind");
        auto off=std::make_shared<Layout>(*l);off->layers[0].coverRoots=false;Engine disabled(off);
        require(disabled.evaluate({})->statistics.hiddenRoots==0,"Disabled hiding does not use its retained margin");
    }
}
void reviewFixedGeometry(){
    prep::Snapshot raw;
    for(unsigned leaf=0;leaf<8;++leaf){const double angle=leaf*6.283185307179586/8;unsigned offset=unsigned(raw.positions.size());
        for(unsigned row=0;row<18;++row)for(unsigned side=0;side<2;++side){double t=row/17.,radius=.02+.48*t,w=(side?1:-1)*(.004+.016*std::sin(t*3.141592653589793));raw.positions.push_back({float(radius*std::cos(angle)-w*std::sin(angle)),float(radius*std::sin(angle)+w*std::cos(angle)),float(.15+.22*std::sin(t*3.141592653589793)-(leaf%2?.11:0)*t)});}
        for(unsigned row=1;row<18;++row){unsigned a=offset+(row-1)*2,b=a+2;raw.faces.push_back({a,a+1,b});raw.faces.push_back({a+1,b+1,b});}}
    const unsigned offset=unsigned(raw.positions.size());
    for(unsigned k=0;k<8;++k)raw.positions.push_back({float(k&1?.035:-.035),float(k&2?.035:-.035),float(k&4?.09:0)});
    for(auto f:std::vector<Tri>{{0,2,1},{1,2,3},{4,5,6},{5,7,6},{0,1,4},{1,5,4},{2,6,3},{3,6,7},{0,4,2},{2,4,6},{1,3,5},{3,7,5}}){for(auto& v:f)v+=offset;raw.faces.push_back(f);}
    raw.materials.assign(raw.faces.size(),0);
    for(double x:{0.,5.}){
        auto fixture=raw;for(unsigned i=offset;i<fixture.positions.size();++i)fixture.positions[i][0]+=float(x);
        auto source=prepareSource(fixture,{.005,1.});Shape obstacle{1,cube(.035),{}};obstacle.transform.rows[3]={0,.15,0};
        auto pose=fitSource(*source,{obstacle},0,.5,true,1);require(pose.coveredRoots>0&&!source->fixedVertices.empty(),"Fixed fixture must contain hidden roots and visible fixed geometry");
        for(auto vertex:source->fixedVertices)require(visibleVertex(*source,pose,vertex),"Root hiding preserves fixed point samples");
        for(auto face:source->fixedFaces)require(visibleFace(*source,pose,face),"Root hiding preserves fixed mesh faces");
        const auto bounds=poseEnvelope(*source);
        for(unsigned vertex=0;vertex<source->rig->positions.size();++vertex)if(visibleVertex(*source,pose,vertex)){
            const auto p=posePoint(*source,pose,vertex);
            require(p.x>=bounds.lo.x&&p.x<=bounds.hi.x&&p.y>=bounds.lo.y&&p.y<=bounds.hi.y&&p.z>=bounds.lo.z&&p.z<=bounds.hi.z,"Render envelope contains every emitted fixed/deformed vertex");
        }
    }
}
void reviewRegressions(){reviewRoleTransitions();reviewHidingCandidates();reviewFixedGeometry();}
