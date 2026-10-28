#include "analysis.hpp"
#include "connectivity.hpp"
#include "preparation_spatial.hpp"
#include "preparation_authoring.hpp"
#include <chrono>
#include <map>
#include <queue>
#include <unordered_map>
namespace prep {
namespace {
using namespace spatial;using Json=stem::Json;
V point(const Snapshot& s,unsigned i){auto p=s.positions[i];return {p[0],p[1],p[2]};}
struct Part {std::vector<unsigned> vertices,faces;std::vector<std::vector<unsigned>> boundary;unsigned material=0;bool mixed=false,nonmanifold=false;};
struct Guide {unsigned component;bool tube=false;std::vector<V> nodes;std::vector<unsigned> base,tip;double radius=.001;Connection link;bool crown=false;Near attachment;unsigned attachmentVertex=0;};
std::vector<V> resample(const std::vector<V>& input,unsigned count){
    std::vector<double> arc(input.size());for(unsigned i=1;i<input.size();++i)arc[i]=arc[i-1]+length(sub(input[i],input[i-1]));
    if(arc.back()<1e-8)return {};std::vector<V> result;
    for(unsigned i=0;i<count;++i){double target=arc.back()*i/(count-1);auto hi=std::min<std::size_t>(input.size()-1,std::max<std::size_t>(1,std::upper_bound(arc.begin(),arc.end(),target)-arc.begin()));double d=arc[hi]-arc[hi-1];result.push_back(add(input[hi-1],mul(sub(input[hi],input[hi-1]),d>0?(target-arc[hi-1])/d:0)));}return result;
}
double arcLength(const std::vector<V>& p){double arc=0;for(unsigned k=1;k<p.size();++k)arc+=length(sub(p[k],p[k-1]));return arc;}
double toCurve(V p,const std::vector<V>& curve){double distance=1e100;for(unsigned k=1;k<curve.size();++k){auto d=sub(curve[k],curve[k-1]);double u=std::clamp(dot(sub(p,curve[k-1]),d)/std::max(1e-20,dot(d,d)),0.,1.);distance=std::min(distance,length(sub(p,add(curve[k-1],mul(d,u)))));}return distance;}
std::vector<Segment> segments(const std::vector<Guide>& guides){std::vector<Segment> s;for(unsigned g=0;g<guides.size();++g)for(unsigned k=1;k<guides[g].nodes.size();++k)s.push_back({guides[g].nodes[k-1],guides[g].nodes[k],g,k-1});return s;}
}
Analysis analyzeTopology(const Snapshot& s,Settings settings,const std::atomic_bool& cancel,std::atomic_int& progress,const Json& authoring){
    const auto started=std::chrono::steady_clock::now();validate(s,settings);Work work{0,std::uint64_t(settings.limits.workMillions)*1000000,cancel};
    if(cancel.load())throw std::runtime_error("Analysis cancelled; previous preparation retained.");
    std::vector<unsigned> parents(s.positions.size());std::iota(parents.begin(),parents.end(),0u);
    auto root=[&](unsigned i){while(parents[i]!=i){parents[i]=parents[parents[i]];i=parents[i];}return i;};
    std::vector<std::vector<unsigned>> adjacency(s.positions.size());
    double ground=1e100,top=-1e100;
    for(auto p:s.positions){for(float v:p)if(!std::isfinite(v)||std::abs(v)>10000)throw std::runtime_error("Nonfinite or distant source: move its geometry near its local origin.");ground=std::min(ground,double(p[2]));top=std::max(top,double(p[2]));}
    std::vector<std::uint64_t> edges;edges.reserve(s.faces.size()*3);
    for(auto f:s.faces){work.charge(3);for(unsigned v:f)if(v>=parents.size())throw std::runtime_error("Triangle index outside source.");for(unsigned k=0;k<3;++k){auto a=f[k],b=f[(k+1)%3];if(a==b)throw std::runtime_error("Collapsed source triangle; repair the source mesh.");auto ra=root(a),rb=root(b);if(ra!=rb)parents[std::max(ra,rb)]=std::min(ra,rb);if(a>b)std::swap(a,b);edges.push_back((std::uint64_t(a)<<32)|b);}}
    Analysis out;out.fingerprint=fingerprint(s);out.labels.resize(parents.size());std::unordered_map<unsigned,unsigned> ids;std::vector<Part> parts;
    for(unsigned i=0;i<parents.size();++i){auto [it,newPart]=ids.emplace(root(i),unsigned(parts.size()));if(newPart)parts.emplace_back();out.labels[i]=it->second;parts[it->second].vertices.push_back(i);}
    if(parts.size()>settings.limits.parts)throw std::runtime_error("Connected pieces: "+std::to_string(parts.size())+"; increase Parts in Preparation limits.");
    const auto edits=authoringRows(authoring);
    auto role=[&](unsigned id){auto it=edits.find(id);return it==edits.end()?0:it->second.value("role",0);};
    auto eligible=[&](unsigned id){return role(id)!=2&&role(id)!=3;};
    if(!edits.empty()&&std::none_of(out.labels.begin(),out.labels.end(),eligible))throw std::runtime_error("No bending stems remain. Restore a Bend/Automatic piece.");
    for(unsigned fi=0;fi<s.faces.size();++fi){auto& p=parts[out.labels[s.faces[fi][0]]];if(p.faces.empty())p.material=s.materials[fi];else p.mixed|=p.material!=s.materials[fi];p.faces.push_back(fi);}
    std::sort(edges.begin(),edges.end());std::vector<std::vector<unsigned>> boundaryAdj(s.positions.size());
    for(std::size_t first=0;first<edges.size();){std::size_t end=first+1;while(end<edges.size()&&edges[end]==edges[first])++end;unsigned a=unsigned(edges[first]>>32),b=unsigned(edges[first]);adjacency[a].push_back(b);adjacency[b].push_back(a);if(end-first==1){boundaryAdj[a].push_back(b);boundaryAdj[b].push_back(a);}if(end-first>2)parts[out.labels[a]].nonmanifold=true;work.charge(end-first);first=end;}
    std::vector<bool> visited(s.positions.size());
    for(auto& part:parts)for(auto vertex:part.vertices)if(!visited[vertex]&&!boundaryAdj[vertex].empty()){
        std::vector<unsigned> stack{vertex},loop;bool closed=true;
        while(!stack.empty()){auto a=stack.back();stack.pop_back();if(visited[a])continue;visited[a]=true;loop.push_back(a);closed&=boundaryAdj[a].size()==2;for(auto b:boundaryAdj[a])if(!visited[b])stack.push_back(b);work.charge();}
        if(!closed)part.nonmanifold=true;part.boundary.push_back(std::move(loop));
    }
    progress=25;std::vector<Guide> guides;std::vector<int> partGuide(parts.size(),-1);std::vector<int> distance(s.positions.size(),-1);
    auto addGuide=[&](Guide g){if(guides.size()>=settings.limits.guides)throw std::runtime_error("Guide count reached "+std::to_string(settings.limits.guides)+"; increase Guides in Preparation limits.");partGuide[g.component]=int(guides.size());guides.push_back(std::move(g));};
    // Boundary-to-boundary graph rings are invariant to the imported vertex order.
    for(unsigned ci=0;ci<parts.size();++ci){const auto& p=parts[ci];if(!eligible(ci)||p.nonmanifold||(p.mixed&&role(ci)!=1)||p.boundary.size()!=2||p.boundary[0].size()<3||p.boundary[1].size()<3||p.boundary[0].size()>64||p.boundary[1].size()>64)continue;
        auto centre=[&](const std::vector<unsigned>& v){V c{};for(auto i:v)c=add(c,point(s,i));return mul(c,1./v.size());};
        unsigned base=centre(p.boundary[1])[2]<centre(p.boundary[0])[2]?1:0;std::queue<unsigned> queue;
        for(unsigned v:p.boundary[base]){distance[v]=0;queue.push(v);}int max=0;
        while(!queue.empty()){auto a=queue.front();queue.pop();work.charge();for(auto b:adjacency[a])if(distance[b]<0){distance[b]=distance[a]+1;max=std::max(max,distance[b]);queue.push(b);}}
        std::vector<V> rings(max+1);std::vector<unsigned> counts(max+1);for(auto v:p.vertices){rings[distance[v]]=add(rings[distance[v]],point(s,v));++counts[distance[v]];distance[v]=-1;}
        if(max<2)continue;for(unsigned k=0;k<rings.size();++k)rings[k]=mul(rings[k],1./counts[k]);double arc=arcLength(rings);if(arc<settings.minimumLength)continue;
        double radius=0;for(auto v:p.boundary[base])radius=std::max(radius,length(sub(point(s,v),rings.front())));
        if(radius<1e-7||radius>.15||arc<4*radius)continue;
        auto nodes=resample(rings,std::clamp(unsigned(std::ceil(arc/.04))+1,3u,16u));if(nodes.empty())continue;
        addGuide({ci,true,std::move(nodes),p.boundary[base],p.boundary[1-base],std::min(.03,radius),{}});
    }
    unsigned tubes=unsigned(guides.size());Forest forest;
    Index stems(segments(guides),work);
    const double basalBand=std::clamp((top-ground)*.03,.003,.03);
    std::vector<double> distA(s.positions.size()),distB(s.positions.size());
    auto geodesic=[&](const Part& p,unsigned seed,std::vector<double>& distances){for(auto v:p.vertices)distances[v]=1e100;using Item=std::pair<double,unsigned>;std::priority_queue<Item,std::vector<Item>,std::greater<Item>> queue;distances[seed]=0;queue.emplace(0,seed);unsigned far=seed;
        while(!queue.empty()){auto [d,a]=queue.top();queue.pop();work.charge();if(d!=distances[a])continue;if(d>distances[far]||(d==distances[far]&&point(s,a)<point(s,far)))far=a;for(auto b:adjacency[a]){double next=d+length(sub(point(s,a),point(s,b)));if(next<distances[b]){distances[b]=next;queue.emplace(next,b);}}}return far;};
    std::vector<Guide> ribbons;
    // A geodesic chart reconstructs ordinary two-rail and irregular triangulated ribbons.
    for(unsigned ci=0;ci<parts.size();++ci){const auto& p=parts[ci];if(!eligible(ci)||partGuide[ci]>=0||p.nonmanifold||(p.mixed&&role(ci)!=1)||p.boundary.size()!=1||p.vertices.size()<6)continue;
        unsigned seed=p.vertices.front();for(auto v:p.vertices)if(point(s,v)<point(s,seed))seed=v;
        Near attachment;unsigned attachmentVertex=seed;
        if(tubes)for(auto v:p.vertices){auto hit=stems.nearest(point(s,v));if(hit.distance<attachment.distance){attachment=hit;attachmentVertex=v;}}
        unsigned a,b;if(tubes&&attachment.distance<.15){a=attachmentVertex;b=geodesic(p,a,distA);geodesic(p,b,distB);}else{b=geodesic(p,seed,distA);a=geodesic(p,b,distB);geodesic(p,a,distA);}double diameter=distA[b];if(diameter<settings.minimumLength)continue;
        unsigned stations=std::clamp(unsigned(std::ceil(diameter/.02))+1,3u,16u);std::vector<V> chart(stations);std::vector<unsigned> count(stations),base,tip;
        for(auto v:p.vertices){double t=std::clamp((distA[v]-distB[v]+diameter)/(2*diameter),0.,1.);unsigned bin=std::min(stations-1,unsigned(std::round(t*(stations-1))));chart[bin]=add(chart[bin],point(s,v));++count[bin];if(bin==0)base.push_back(v);if(bin+1==stations)tip.push_back(v);}
        std::vector<V> path;for(unsigned k=0;k<stations;++k)if(count[k])path.push_back(mul(chart[k],1./count[k]));if(path.size()<2||base.empty()||tip.empty())continue;
        auto nodes=resample(path,stations);if(nodes.empty())continue;double arc=arcLength(nodes),width=0;for(auto v:p.vertices)width=std::max(width,toCurve(point(s,v),nodes));
        if(arc<(role(ci)==1?settings.minimumLength:std::max(settings.minimumLength,(top-ground)*.08))||arc<3*width)continue;
        const bool structural=p.vertices.size()>32;
        ribbons.push_back({ci,false,std::move(nodes),std::move(base),std::move(tip),structural?std::min(.03,std::max(.001,width)):.0003,{}});
        ribbons.back().attachment=attachment;ribbons.back().attachmentVertex=attachmentVertex;
    }
    // Repeated long leaves can start at a crown above the source minimum.
    // Both ends vote geometrically; a low drooping tip must not become a root.
    double longest=0;for(const auto& g:ribbons)longest=std::max(longest,arcLength(g.nodes));
    std::vector<Segment> endpoints;
    for(unsigned k=0;k<ribbons.size();++k)if(arcLength(ribbons[k].nodes)>=std::max((top-ground)*.20,longest*.5))
        for(unsigned end=0;end<2;++end){auto p=end?ribbons[k].nodes.back():ribbons[k].nodes.front();endpoints.push_back({p,p,k,end});}
    Index crowns(std::move(endpoints),work);unsigned crownRoots=0;
    for(unsigned k=0;k<ribbons.size();++k){auto& g=ribbons[k];const double arc=arcLength(g.nodes);if(tubes||(role(g.component)!=1&&arc<std::max((top-ground)*.20,longest*.5)))continue;
        unsigned votes[2]{};
        for(unsigned end=0;end<2;++end){const auto p=end?g.nodes.back():g.nodes.front();double radius=std::clamp(arc*.20,.003,.15);
            crowns.query(p,radius,[&](const Segment& s,double,double){if(s.guide!=k)++votes[end];});}
        const unsigned base=votes[1]>votes[0]?1:0;
        if(votes[base]<3||votes[base]<2*(votes[1-base]+1))continue;
        g.crown=true;++crownRoots;if(base){std::reverse(g.nodes.begin(),g.nodes.end());std::swap(g.base,g.tip);}
    }
    for(auto& g:ribbons){const auto& p=parts[g.component];auto& nodes=g.nodes;auto& base=g.base;auto& tip=g.tip;
        if(role(g.component)==1)g.crown=true;
        const auto attachment=g.attachment;const auto attachmentVertex=g.attachmentVertex;
        auto n0=stems.nearest(nodes.front()),n1=stems.nearest(nodes.back());bool reverse=!g.crown&&(tubes?(attachment.distance<.15?false:n1.distance<n0.distance):nodes.back()[2]<nodes.front()[2]);
        if(reverse){std::reverse(nodes.begin(),nodes.end());std::swap(base,tip);std::swap(n0,n1);}
        if(tubes&&attachment.distance<.15){nodes.front()=point(s,attachmentVertex);base={attachmentVertex};}
        // Keep the full basal cross-section at its authored elevation.
        if(!g.crown&&(!tubes||nodes.front()[2]<=ground+basalBand)){double low=1e100;for(auto v:base)low=std::min(low,double(s.positions[v][2]));std::vector<unsigned> anchors;V c{};for(auto v:base)if(s.positions[v][2]<=low+.0005){anchors.push_back(v);c=add(c,point(s,v));}if(!anchors.empty()){base=std::move(anchors);nodes.front()=mul(c,1./base.size());}}
        if(!tubes&&!g.crown&&nodes.front()[2]>ground+basalBand)continue;
        addGuide(std::move(g));
    }
    if(guides.empty())throw std::runtime_error("No reliable tube or ribbon guides were found. Use authored guides, or repair disconnected/nonmanifold source geometry.");
    // Artist direction and control points are applied before the parent forest.
    for(auto& g:guides)if(auto it=edits.find(g.component);it!=edits.end()){
        const auto& edit=it->second;bool reverse=edit.value("flip",false);
        if(edit.contains("root_vertex")){const auto seed=point(s,edit["root_vertex"].get<unsigned>());reverse^=length(sub(seed,g.nodes.back()))<length(sub(seed,g.nodes.front()));}
        if(reverse){std::reverse(g.nodes.begin(),g.nodes.end());std::swap(g.base,g.tip);}
        if(edit.contains("nodes")){g.nodes.clear();for(const auto& p:edit["nodes"])g.nodes.push_back({p[0].get<double>(),p[1].get<double>(),p[2].get<double>()});}
        // A supported ring/endpoint remains the actual fixed base; editing a
        // guide does not move the source mesh or invent a new source vertex.
        if(g.base.empty())throw std::runtime_error("Selected guide has no stable root patch");
        g.crown=true;
    }
    for(const auto& [id,edit]:edits)if(role(id)==1&&partGuide[id]<0)throw std::runtime_error("Piece "+std::to_string(id+1)+" cannot form a single guide with Minimum stem "+std::to_string(settings.minimumLength*1000)+" mm. Use Automatic or Keep fixed for small/detail pieces; complex connected pieces need separate guides.");
    double guideGround=1e100;for(const auto& g:guides)if(arcLength(g.nodes)>=(top-ground)*.20)guideGround=std::min({guideGround,g.nodes.front()[2],g.nodes.back()[2]});if(guideGround==1e100)guideGround=ground;
    std::vector<Tube> raw;for(const auto& g:guides){bool parent=g.tube||parts[g.component].vertices.size()>32;auto radii=std::vector<double>(g.nodes.size(),g.radius);if(!g.tube){radii.front()=std::min(.001,g.radius);radii.back()=std::min(.001,g.radius);}raw.push_back({g.nodes,std::move(radii),tubes==0,parent,g.crown});}
    forest=connect(raw,cancel,settings.limits,settings.connectionReach,.03,guideGround,basalBand);
    for(unsigned k=0;k<guides.size();++k){guides[k].link=forest.links[k];if(forest.links[k].reversed){std::reverse(guides[k].nodes.begin(),guides[k].nodes.end());std::swap(guides[k].base,guides[k].tip);}}
    if(!edits.empty()){
        for(unsigned k=0;k<guides.size();++k)if(auto it=edits.find(guides[k].component);it!=edits.end()&&it->second.contains("parent")){
            int part=it->second["parent"].get<int>();auto& g=guides[k];
            if(part<0)g.link={-1,0,0,0,false,true,true};
            else {int parent=partGuide[part];if(parent<0)throw std::runtime_error("Selected parent piece has no bending guide");double best=1e100,u=0;unsigned span=0;const auto& p=guides[parent].nodes;
                for(unsigned s0=0;s0+1<p.size();++s0){auto d=sub(p[s0+1],p[s0]);double t=std::clamp(dot(sub(g.nodes.front(),p[s0]),d)/std::max(1e-20,dot(d,d)),0.,1.);double gap=length(sub(g.nodes.front(),add(p[s0],mul(d,t))));if(gap<best){best=gap;u=t;span=s0;}}
                if(best>settings.connectionReach)throw std::runtime_error("Parent connection exceeds Branch connection distance");g.link={parent,span,u,best,false,false,true};
            }
        }
        forest.order.clear();std::vector<unsigned char> state(guides.size());
        auto visit=[&](auto&& self,unsigned k)->void{if(state[k]==1)throw std::runtime_error("Cyclic guide parents; choose another stem");if(state[k]==2)return;state[k]=1;if(guides[k].link.parent>=0)self(self,unsigned(guides[k].link.parent));state[k]=2;forest.order.push_back(k);};
        for(unsigned k=0;k<guides.size();++k)visit(visit,k);
    }
    // Disconnected short petioles/leaf patches are rigid attachments, not planted roots.
    // Keep all their original faces; require the attachment-distance check below.
    unsigned rigidTwigs=0;std::vector<unsigned> remap(guides.size(),~0u);std::vector<Guide> kept;
    for(unsigned k=0;k<guides.size();++k){auto& g=guides[k];if(role(g.component)!=1&&!g.link.resolved&&arcLength(g.nodes)<(top-ground)*.20){partGuide[g.component]=-1;++rigidTwigs;continue;}remap[k]=unsigned(kept.size());partGuide[g.component]=int(kept.size());kept.push_back(g);}
    std::vector<unsigned> keptOrder;for(unsigned k:forest.order)if(remap[k]!=~0u)keptOrder.push_back(remap[k]);for(auto& g:kept)if(g.link.parent>=0){if(remap[g.link.parent]==~0u)throw std::runtime_error("Structural parent cannot be replaced by a rigid attachment.");g.link.parent=int(remap[g.link.parent]);}guides=std::move(kept);forest.order=std::move(keptOrder);
    tubes=unsigned(std::count_if(guides.begin(),guides.end(),[](const Guide& g){return g.tube;}));
    Index all(segments(guides),work);Json j={{"schema",2},{"preparation_version",4},{"asset","Connectivity-derived tubes and geodesic ribbons"},{"vertices",s.positions.size()},{"triangles",s.faces.size()},{"guides",Json::array()},{"parts",Json::array()},{"guide_order",Json::array()},{"preview_triangles",Json::array()},{"preview_materials",Json::array()},{"connectivity_version",3}};
    unsigned roots=0,unresolved=0,unattached=0,nonmanifold=0,fixedParts=0;double maxParent=0,maxAttachment=0;
    std::vector<unsigned> order=forest.order;
    for(unsigned k:order){auto& g=guides[k];j["guide_order"].push_back(k);if(g.link.basal)++roots;if(!g.link.resolved)++unresolved;maxParent=std::max(maxParent,g.link.distance);Json nodes=Json::array();for(auto v:g.nodes)nodes.push_back({v[0],v[2],-v[1]});
        j["guides"].push_back(nullptr); // Populated below in stable guide-ID order.
    }
    j["guides"]=Json::array();for(const auto& g:guides){Json nodes=Json::array();for(auto v:g.nodes)nodes.push_back({v[0],v[2],-v[1]});j["guides"].push_back({{"component",g.component},{"nodes",nodes},{"parent",g.link.parent},{"parent_span",g.link.parentSpan},{"parent_u",g.link.parentU},{"parent_distance_m",g.link.distance},{"length_m",arcLength(g.nodes)},{"unresolved",!g.link.resolved},{"root_kind",g.link.basal?"basal":g.link.resolved?"branch":"unresolved"},{"root_ring_vertices",g.link.basal?g.base:std::vector<unsigned>{}}});}
    for(unsigned ci=0;ci<parts.size();++ci){work.charge();const auto& p=parts[ci];nonmanifold+=p.nonmanifold;int guide=partGuide[ci];Near hit;bool flexible=guide>=0;
        // A compact non-ribbon core in a supported rosette is fixed decoration.
        // It must not rotate with whichever nearby leaf won a nearest query.
        V lo{1e100,1e100,1e100},hi{-1e100,-1e100,-1e100};for(auto v:p.vertices)for(unsigned d=0;d<3;++d){lo[d]=std::min(lo[d],double(s.positions[v][d]));hi[d]=std::max(hi[d],double(s.positions[v][d]));}
        const bool fixed=role(ci)==3||(!flexible&&role(ci)!=2&&crownRoots>=3&&p.boundary.size()!=1&&length(sub(hi,lo))<longest*.6);
        if(fixed)++fixedParts;
        if(flexible)hit.guide=unsigned(guide);else {
            for(unsigned k=0;k<std::min<std::size_t>(32,p.vertices.size());++k){auto candidate=all.nearest(point(s,p.vertices[std::size_t(k)*p.vertices.size()/std::min<std::size_t>(32,p.vertices.size())]));if(candidate.distance<hit.distance)hit=candidate;}
            if(role(ci)==2){const auto& e=edits.at(ci);if(!e.contains("parent")||e["parent"].get<int>()<0)throw std::runtime_error("Piece "+std::to_string(ci+1)+" needs a stem. Choose Pick stem.");int pg=partGuide[e["parent"].get<unsigned>()];if(pg<0)throw std::runtime_error("Follow parent has no bending guide");hit={};for(unsigned v:p.vertices){const auto& curve=guides[pg].nodes;for(unsigned k=0;k+1<curve.size();++k){auto d=sub(curve[k+1],curve[k]);double u=std::clamp(dot(sub(point(s,v),curve[k]),d)/std::max(1e-20,dot(d,d)),0.,1.);double gap=length(sub(point(s,v),add(curve[k],mul(d,u))));if(gap<hit.distance){hit.guide=pg;hit.span=k;hit.u=u;hit.distance=gap;}}work.charge(curve.size());}}
            if(fixed&&hit.guide==~0u){hit.guide=0;hit.span=0;hit.u=0;}
            if(!fixed){maxAttachment=std::max(maxAttachment,hit.distance);if(hit.guide==~0u||hit.distance>(role(ci)==2?settings.connectionReach:.15))++unattached;}
        }
        j["parts"].push_back({{"guide",hit.guide},{"stem",flexible},{"fixed",fixed},{"span",hit.span},{"u",hit.u},{"material",p.material}});
        // Preserve all source faces and material/corner identities; sample whole components only.
        const unsigned hash=(ci+2402u)*2654435761u;bool selected=double(hash%100000)/100000<std::clamp(settings.foliageFraction,.01,1.);
        if(selected)for(auto fi:p.faces){if(j["preview_triangles"].size()>=settings.limits.previewTriangles)throw std::runtime_error("Preview triangle limit reached; reduce Preview leaves or increase Preview triangles in Preparation limits.");j["preview_triangles"].push_back(s.faces[fi]);j["preview_materials"].push_back(s.materials[fi]);}
    }
    if(j["preview_triangles"].empty()&&!s.faces.empty()){j["preview_triangles"].push_back(s.faces.front());j["preview_materials"].push_back(s.materials.front());}
    j["source_geometry_sha256"]=geometryHash(s,out.labels,unsigned(parts.size()));
    out.report={{"profile","Connectivity-derived tubes and geodesic ribbons"},{"guides",guides.size()},{"tube_guides",tubes},{"ribbon_guides",guides.size()-tubes},{"crown_root_guides",crownRoots},{"fixed_parts",fixedParts},{"parts",parts.size()},{"ground_roots",roots},{"unresolved_guides",unresolved},{"unattached_parts",unattached},{"complex_foliage_parts",nonmanifold},{"max_parent_distance_m",maxParent},{"max_attachment_distance_m",maxAttachment},{"basal_band_m",forest.basalBand},{"ground_level_m",forest.ground},{"preview_triangles",j["preview_triangles"].size()},{"work_units",work.used},{"can_prepare",roots>0&&unresolved==0&&unattached==0},{"review_required",true},{"warning","Review inferred roots, tube direction, leaf guides and attachments before accepting. Geometry inference does not guarantee botanical correctness."},{"seconds",std::chrono::duration<double>(std::chrono::steady_clock::now()-started).count()}};
    out.metadata=std::move(j);progress=100;return out;
}
}
