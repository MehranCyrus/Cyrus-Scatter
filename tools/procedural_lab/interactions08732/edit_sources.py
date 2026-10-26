"""Apply the scoped 0.87.3.2 edits with compare-before-replace writes."""
from pathlib import Path
import os
def edit(path,changes):
    p=Path(path);before=p.read_bytes();text=before.decode('utf-8').replace('\r\n','\n').replace('\r','\n')
    for old,new in changes:
        assert old in text,(path,old[:120]);text=text.replace(old,new)
    tmp=p.with_name(p.name+'.08732.tmp');tmp.write_bytes(text.encode('utf-8'))
    assert p.read_bytes()==before,f'Concurrent edit: {p}'
    os.replace(tmp,p)

edit('tools/procedural_lab/check_generated.py', [('assert len(current)==360  # One Prepare model replaces the separate Analyze and Accept actions.','assert len(current)==361  # Interactions shares canonical + / remove source actions.')])
for path in ['AminScatter/CMakeLists.txt','AminScatter/tools/ui/templates/unified-core.ms','AminScatter/tools/ui/templates/interactions-authoring.ms']:
    changes=[('0.87.3.1','0.87.3.2')]
    if path.endswith('.ms'):changes.append(('cyrusInteractionVersion()!=6','cyrusInteractionVersion()!=7'))
    edit(path,changes)
edit('AminScatter/src/interactions_host.cpp',[('return Integer::intern(6);','return Integer::intern(7);')])
edit('CyrusVegetationLab/experiments/stem-live/connectivity.hpp', [('bool canParent=true;','bool canParent=true;bool orientedRoot=false;')])
edit('CyrusVegetationLab/experiments/stem-live/connectivity.cpp', [
    ('unsigned end=t.nodes.back()[2]<t.nodes.front()[2]?1:0,e=end?', 'unsigned end=!t.orientedRoot&&t.nodes.back()[2]<t.nodes.front()[2]?1:0,e=end?'),
    ('if(t.nodes[e][2]>out.ground+out.basalBand||t.radii[e]<t.radii[other]*.85)continue;', 'if(!t.orientedRoot&&(t.nodes[e][2]>out.ground+out.basalBand||t.radii[e]<t.radii[other]*.85))continue;')])
edit('CyrusVegetationLab/experiments/stem-live/preparation_spatial.hpp', [
    ('if(denominator<1e-18)continue;double u=std::clamp(dot(sub(p,s.a),delta)/denominator,0.,1.);', 'double u=denominator<1e-18?0.:std::clamp(dot(sub(p,s.a),delta)/denominator,0.,1.);')])
edit('CyrusVegetationLab/experiments/stem-live/topology_analysis.cpp', [
    ('double radius=.001;Connection link;','double radius=.001;Connection link;bool crown=false;'),
    ('// A geodesic chart reconstructs ordinary two-rail and irregular triangulated ribbons.', 'std::vector<Guide> ribbons;\n    // A geodesic chart reconstructs ordinary two-rail and irregular triangulated ribbons.'),
    ('        auto n0=stems.nearest(nodes.front()),n1=stems.nearest(nodes.back());bool reverse=', '        const bool structural=p.vertices.size()>32;\n        ribbons.push_back({ci,false,std::move(nodes),std::move(base),std::move(tip),structural?std::min(.03,std::max(.001,width)):.0003,{}});\n    }\n    // Repeated long leaves can start at a crown above the source minimum.\n    // Both ends vote geometrically; a low drooping tip must not become a root.\n    double longest=0;for(const auto& g:ribbons)longest=std::max(longest,arcLength(g.nodes));\n    std::vector<Segment> endpoints;\n    for(unsigned k=0;k<ribbons.size();++k)if(arcLength(ribbons[k].nodes)>=std::max((top-ground)*.20,longest*.5))\n        for(unsigned end=0;end<2;++end){auto p=end?ribbons[k].nodes.back():ribbons[k].nodes.front();endpoints.push_back({p,p,k,end});}\n    Index crowns(std::move(endpoints),work);unsigned crownRoots=0;\n    for(unsigned k=0;k<ribbons.size();++k){auto& g=ribbons[k];const double arc=arcLength(g.nodes);if(tubes||arc<std::max((top-ground)*.20,longest*.5))continue;\n        unsigned votes[2]{};\n        for(unsigned end=0;end<2;++end){const auto p=end?g.nodes.back():g.nodes.front();double radius=std::clamp(arc*.20,.003,.15);\n            crowns.query(p,radius,[&](const Segment& s,double,double){if(s.guide!=k)++votes[end];});}\n        const unsigned base=votes[1]>votes[0]?1:0;\n        if(votes[base]<3||votes[base]<2*(votes[1-base]+1))continue;\n        g.crown=true;++crownRoots;if(base){std::reverse(g.nodes.begin(),g.nodes.end());std::swap(g.base,g.tip);}\n    }\n    for(auto& g:ribbons){const auto& p=parts[g.component];auto& nodes=g.nodes;auto& base=g.base;auto& tip=g.tip;\n        auto n0=stems.nearest(nodes.front()),n1=stems.nearest(nodes.back());bool reverse=!g.crown&&'),
    ('if(!tubes||nodes.front()[2]<=ground+basalBand){', 'if(!g.crown&&(!tubes||nodes.front()[2]<=ground+basalBand)){'),
    ('if(!tubes&&nodes.front()[2]>ground+basalBand)continue;\n        const bool structural=p.vertices.size()>32;\n        addGuide({ci,false,std::move(nodes),std::move(base),std::move(tip),structural?std::min(.03,std::max(.001,width)):.0003,{}});', 'if(!tubes&&!g.crown&&nodes.front()[2]>ground+basalBand)continue;\n        addGuide(std::move(g));'),
    ('tubes==0,parent});', 'tubes==0,parent,g.crown});'),
    ('{"preparation_version",3}', '{"preparation_version",4}'),
    ('unsigned roots=0,unresolved=0,unattached=0,nonmanifold=0;', 'unsigned roots=0,unresolved=0,unattached=0,nonmanifold=0,fixedParts=0;'),
    ('int guide=partGuide[ci];Near hit;bool flexible=guide>=0;', 'int guide=partGuide[ci];Near hit;bool flexible=guide>=0;\n        // A compact non-ribbon core in a supported rosette is fixed decoration.\n        // It must not rotate with whichever nearby leaf won a nearest query.\n        V lo{1e100,1e100,1e100},hi{-1e100,-1e100,-1e100};for(auto v:p.vertices)for(unsigned d=0;d<3;++d){lo[d]=std::min(lo[d],double(s.positions[v][d]));hi[d]=std::max(hi[d],double(s.positions[v][d]));}\n        const bool fixed=!flexible&&crownRoots>=3&&p.boundary.size()!=1&&length(sub(hi,lo))<longest*.6;\n        if(fixed)++fixedParts;'),
    ('maxAttachment=std::max(maxAttachment,hit.distance);if(hit.guide==~0u||hit.distance>.15)++unattached;', 'if(!fixed){maxAttachment=std::max(maxAttachment,hit.distance);if(hit.guide==~0u||hit.distance>.15)++unattached;}'),
    ('{"stem",flexible},{"span",hit.span}', '{"stem",flexible},{"fixed",fixed},{"span",hit.span}'),
    ('{"ribbon_guides",guides.size()-tubes}', '{"ribbon_guides",guides.size()-tubes},{"crown_root_guides",crownRoots},{"fixed_parts",fixedParts}')])

edit('CyrusVegetationLab/experiments/stem-live/stem_core.hpp', [('bool stem=false;Vec restCentre;', 'bool stem=false,fixed=false;Vec restCentre;')])
edit('CyrusVegetationLab/experiments/stem-live/stem_core.cpp', [
    ('if(!b.stem&&pose.moved[b.guide])', 'if(!b.stem&&!b.fixed&&pose.moved[b.guide])'),
    ('b.stem=row.at("stem");b.span=', 'b.stem=row.at("stem");b.fixed=row.value("fixed",false);if(b.fixed&&b.stem)throw std::runtime_error("A flexible part cannot also be fixed decoration.");b.span='),
    ('r.max_bound_offset_m[b.span]=std::max(r.max_bound_offset_m[b.span],radius);r.span_radius_m[b.span]=std::max(r.span_radius_m[b.span],radius+.0003);', 'if(!part.fixed){r.max_bound_offset_m[b.span]=std::max(r.max_bound_offset_m[b.span],radius);r.span_radius_m[b.span]=std::max(r.span_radius_m[b.span],radius+.0003);}'),
    ('if(!part.stem)return apply(pose.rigid[b.part],p.positions[i]);', 'if(part.fixed)return p.positions[i];if(!part.stem)return apply(pose.rigid[b.part],p.positions[i]);')])
edit('AminScatter/include/interactions_source.h', [('std::vector<unsigned> sortedVertices;', 'std::vector<unsigned> fixedVertices,fixedFaces;\n    Bounds fixedBounds;\n    std::vector<unsigned> sortedVertices;')])
edit('AminScatter/src/interactions_source.cpp', [
    ('for(unsigned i=0;i<rig.positions.size();++i)p->guideVertices[rig.parts[p->labels[i]].guide].push_back(i);', 'for(unsigned i=0;i<rig.positions.size();++i){const auto& part=rig.parts[p->labels[i]];if(part.fixed){p->fixedVertices.push_back(i);p->fixedBounds.include(rig.positions[i]);}else p->guideVertices[part.guide].push_back(i);}'),
    ('for(unsigned i=0;i<rig.triangles.size();++i)p->guideFaces[rig.parts[p->labels[rig.triangles[i][0]]].guide].push_back(i);', 'for(unsigned i=0;i<rig.triangles.size();++i){const auto& part=rig.parts[p->labels[rig.triangles[i][0]]];if(part.fixed)p->fixedFaces.push_back(i);else p->guideFaces[part.guide].push_back(i);}'),
    ('p->bytes+=(p->sortedVertices.capacity()', 'p->bytes+=(p->fixedVertices.capacity()+p->fixedFaces.capacity())*sizeof(unsigned);\n    p->bytes+=(p->sortedVertices.capacity()'),
    ('pose.allHidden=roots>0&&roots==hidden;', 'pose.allHidden=roots>0&&roots==hidden&&source.fixedFaces.empty();'),
    ('    v::SolveOptions options;options.limits=', '''    // Fixed decorations have no deforming guide. Diagnose a real intersection
    // explicitly instead of allowing a neighboring leaf to drag them around.
    for(const auto& shape:obstacles)if(!source.fixedFaces.empty()&&source.fixedBounds.expanded(clearance+1e-5).overlaps(shape.transform.bounds(shape.geometry->bounds()))){
        const double scale=shape.transform.scale();auto charge=[&]{if(++pose.meshRefinementWork>2000000)throw std::runtime_error("Fixed decoration check reached its 2M geometry-query budget.");};
        for(auto v:source.fixedVertices){charge();if(shape.geometry->point(shape.transform.inversePoint(prepared.positions[v])).gap*scale<clearance+1e-5)throw std::runtime_error("Collider intersects fixed source decoration. Move it away from the rigid base or use a plant-only source.");}
        for(auto fi:source.fixedFaces){charge();const auto& t=prepared.triangles[fi];if(shape.geometry->triangleDistance(shape.transform.inversePoint(prepared.positions[t[0]]),shape.transform.inversePoint(prepared.positions[t[1]]),shape.transform.inversePoint(prepared.positions[t[2]]))*scale<clearance+1e-5)throw std::runtime_error("Collider intersects fixed source decoration. Move it away from the rigid base or use a plant-only source.");}
    }
    v::SolveOptions options;options.limits='''),
    ('if(!part.stem&&pose.guides[part.guide])', 'if(!part.stem&&!part.fixed&&pose.guides[part.guide])'),
    ('const auto& part=p.parts[binding.part];\n', 'const auto& part=p.parts[binding.part];\n    if(part.fixed)return p.positions.at(vertex);\n',),
])
# poseDirection returns a direction, not a position. Keep fixed normals unchanged.
edit('AminScatter/src/interactions_source.cpp', [
    ('Vec poseDirection(const Source& source,const Pose& pose,unsigned vertex,Vec direction){\n    const auto& p=*source.rig;if(source.anchors.at(vertex))return direction;const auto& binding=p.bindings.at(vertex);const auto& part=p.parts[binding.part];\n    if(part.fixed)return p.positions.at(vertex);', 'Vec poseDirection(const Source& source,const Pose& pose,unsigned vertex,Vec direction){\n    const auto& p=*source.rig;if(source.anchors.at(vertex))return direction;const auto& binding=p.bindings.at(vertex);const auto& part=p.parts[binding.part];\n    if(part.fixed)return direction;'),
    ('for(auto v:t)if(pose.hiddenRoots[source.partRoot[source.labels[v]]])return false;', 'for(auto v:t)if(!source.rig->parts[source.labels[v]].fixed&&pose.hiddenRoots[source.partRoot[source.labels[v]]])return false;'),
    ('Light preview exceeds Preview triangles in Interactions > Advanced;', 'Light preview exceeds Preview triangles in Interactions > Preparation limits;')])
print('Updated 0.87.3.2 source controls, native crown inference and fixed decoration.')
