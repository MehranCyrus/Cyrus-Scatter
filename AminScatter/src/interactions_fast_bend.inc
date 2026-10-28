// Artistic response, not a collision-free simulation. Each guide is queried
// once at up to four coarse spans, then bent once. No angle search, convergence
// loop, mesh reconstruction or full-surface validation runs during a drag.
Pose adaptSource(const Source& source,const std::vector<Shape>& shapes,double clearance,double strength,int response,double amount,double threshold,std::uint64_t seed,double trunkBend,double fixedBase,double transition,bool cover,double hideMargin,bool hideUnder,Vec worldUp){
    auto fraction=[](double x){return std::isfinite(x)&&x>=0&&x<=1;};
    if(response<1||response>3||!std::isfinite(clearance)||clearance<0||!fraction(strength)||!fraction(amount)||!std::isfinite(threshold)||threshold<0||!fraction(trunkBend)||!fraction(fixedBase)||!fraction(transition))throw std::runtime_error("Invalid bend settings");
    workCounters().plantFits.fetch_add(1,std::memory_order_relaxed);
    const auto& rig=*source.rig;Pose pose;const auto count=rig.guides.size();
    pose.guides.resize(count);pose.hiddenRoots.assign(count,false);pose.hiddenGuides.assign(count,false);pose.smoothedRoots.assign(count,false);
    std::vector<PreparedShape> cached;cached.reserve(shapes.size());for(const auto& shape:shapes)cached.emplace_back(shape,std::max(clearance,hideMargin));
    const double height=std::max(1e-6,source.bounds.hi.y-source.rootCentre.y);
    const double fixedHeight=source.rootCentre.y+fixedBase*height;
    auto weight=[&](double y){const double t=std::clamp((y-fixedHeight)/std::max(1e-6,transition*height),0.,1.);return t*t*(3-2*t);};
    if(cover){
        for(unsigned i:rig.order){const auto& guide=rig.guides[i];if(guide.parent>=0)continue;
            const auto root=guide.rest.nodes.front();
            for(const auto& shape:cached){if(!shape.shape->coverRoots)continue;
                const auto local=shape.inverse.point(root);bool hidden=false;
                if(hideUnder){++pose.coverageQueries;hidden=shape.shape->geometry->projectedNear(local,unit(shape.shape->transform.inverseVector(worldUp)),(hideMargin+1e-5)/shape.scale);}
                else if(Bounds{root,root}.overlaps(shape.rootBounds)){++pose.coverageQueries;hidden=shape.shape->geometry->occupied(local,shape.scale,hideMargin+1e-5);}
                if(hidden){pose.hiddenRoots[i]=true;++pose.coveredRoots;pose.changed=true;break;}
            }
        }
    }
    for(unsigned index:rig.order){const auto& guide=rig.guides[index];
        if(pose.hiddenRoots[source.guideRoot[index]]||(guide.parent>=0&&pose.hiddenGuides[guide.parent])){pose.hiddenGuides[index]=true;continue;}
        const bool trunk=source.structuralGuides[index];
        // An immovable trunk does not need collision queries. Branches still
        // receive their own independent response from their fixed attachment.
        if(trunk&&trunkBend==0)continue;
        const bool parentMoved=guide.parent>=0&&bool(pose.guides[guide.parent]);
        if(!parentMoved&&std::none_of(cached.begin(),cached.end(),[&](const auto& shape){return source.guideBounds[index].expanded(clearance).overlaps(shape.bounds);}))continue;
        auto rest=guide.rest;bool changed=false;
        if(guide.parent>=0&&pose.guides[guide.parent]){
            const auto delta=skinTransform(rig.guides[guide.parent],*pose.guides[guide.parent],guide.parentSpan,guide.parentU,pose.smoothedRoots[guide.parent]);
            for(auto& p:rest.nodes)p=stem::apply(delta,p);
            for(auto& q:rest.material_frames)q=f::qnormal(f::product(delta.q,q));changed=true;
        }
        Bounds envelope;const double radius=source.guideRadius[index];for(auto p:rest.nodes)envelope.include(p);
        envelope=envelope.expanded(radius+clearance);
        double depth=0,contactNode=0;Vec away{};const unsigned spans=unsigned(rest.nodes.size()-1),samples=std::min(4u,spans);
        for(const auto& shape:cached){if(!envelope.overlaps(shape.bounds))continue;
            for(unsigned sample=0;sample<samples;++sample){const auto a=sample*spans/samples,b=(sample+1)*spans/samples;
                const double band=radius+clearance+1e-6;Bounds spanBox;spanBox.include(rest.nodes[a]);spanBox.include(rest.nodes[b]);
                if(!spanBox.expanded(band).overlaps(shape.bounds))continue;
                ++pose.queries;
                const auto hit=shape.shape->geometry->contactSegment(shape.inverse.point(rest.nodes[a]),shape.inverse.point(rest.nodes[b]),band/shape.scale);
                if(hit){const double penetration=band-hit->gap*shape.scale;if(penetration>0){if(penetration>depth){depth=penetration;contactNode=a+(b-a)*hit->u;}away=add(away,mul(unit(shape.shape->transform.vector(hit->normal)),penetration));}}
            }
        }
        bool bent=false;double remainingDepth=depth;
        if(depth>0&&response!=2&&strength>0){
            Vec tangent,axis;
            if(f::unit(sub(rest.nodes.back(),rest.nodes.front()),tangent)){
                // Symmetric contact must still choose a stable direction.
                if(!f::unit(cross(tangent,away),axis))axis=f::rotate(rest.material_frames.front(),{1,0,0});
                const double reach=std::max(1e-6,length(sub(rest.nodes.back(),rest.nodes.front())));
                const double angle=std::min(1.35,2*std::atan2(depth,reach))*strength*(trunk?trunkBend:1.);
                const auto original=rest.nodes;
                for(unsigned k=0;k<spans;++k){
                    const double w=weight((guide.rest.nodes[k].y+guide.rest.nodes[k+1].y)*.5);
                    const double half=angle*w*.5;const v::Quat q{axis.x*std::sin(half),axis.y*std::sin(half),axis.z*std::sin(half),std::cos(half)};
                    rest.nodes[k+1]=add(rest.nodes[k],f::rotate(q,sub(original[k+1],original[k])));bent|=half>1e-8;
                }
                if(bent){
                    const auto contactSpan=std::min(unsigned(contactNode),spans-1);const double t=std::clamp(contactNode-contactSpan,0.,1.);
                    const auto displacement=sub(f::lerp(rest.nodes[contactSpan],rest.nodes[contactSpan+1],t),f::lerp(original[contactSpan],original[contactSpan+1],t));
                    remainingDepth=std::max(0.,depth-std::max(0.,dot(displacement,unit(away))));
                    for(unsigned k=0;k<rest.nodes.size();++k){Vec a,b;v::Quat q;
                        if(f::tangent(original,k,a)&&f::tangent(rest.nodes,k,b)&&f::swing(a,b,q))rest.material_frames[k]=f::qnormal(f::product(q,rest.material_frames[k]));}
                    // Authored planted vertices stay fixed in every delivery.
                    if(guide.parent<0){rest.material_frames.front()=guide.rest.material_frames.front();pose.smoothedRoots[index]=true;}
                    changed=true;++pose.hinges;
                }
            }
        }
        // Trim is explicit and reversible. Bend-and-trim uses depth as an art
        // threshold, not an expensive second solve or a failed-solver fallback.
        if(remainingDepth>threshold&&response!=1&&!trunk){
            std::uint64_t hash=seed^(std::uint64_t(index+1)*0x9e3779b97f4a7c15ull);hash^=hash>>30;hash*=0xbf58476d1ce4e5b9ull;hash^=hash>>27;hash*=0x94d049bb133111ebull;hash^=hash>>31;
            if(amount>=1||double(hash>>11)*(1./9007199254740992.)<amount){pose.hiddenGuides[index]=true;pose.changed=true;++pose.prunedGuides;continue;}
        }
        if(depth>0&&!bent)++pose.blockedGuides;
        if(changed){pose.guides[index]=std::make_shared<v::GuidePose>(v::GuidePose{rest.guide_id,std::move(rest.nodes),std::move(rest.material_frames)});pose.changed=true;++pose.activeGuides;}
    }
    for(unsigned i=0;i<rig.parts.size();++i){const auto& part=rig.parts[i];if(!part.stem&&!part.fixed&&!pose.hiddenGuides[part.guide]&&pose.guides[part.guide])pose.rigid.emplace(i,skinTransform(rig.guides[part.guide],*pose.guides[part.guide],part.span,part.u,pose.smoothedRoots[part.guide]));}
    pose.allHidden=!pose.hiddenGuides.empty()&&std::all_of(pose.hiddenGuides.begin(),pose.hiddenGuides.end(),[](bool hidden){return hidden;})&&source.fixedFaces.empty();
    pose.bytes=sizeof(Pose)+pose.guides.capacity()*sizeof(pose.guides[0])+(pose.hiddenRoots.capacity()+pose.hiddenGuides.capacity()+pose.smoothedRoots.capacity()+21)/8+pose.rigid.size()*(sizeof(unsigned)+sizeof(stem::Rigid)+4*sizeof(void*))+pose.rigid.bucket_count()*sizeof(void*);
    for(const auto& guide:pose.guides)if(guide)pose.bytes+=sizeof(v::GuidePose)+guide->nodes.capacity()*sizeof(Vec)+guide->material_frames.capacity()*sizeof(v::Quat);
    return pose;
}
