#include "analysis.hpp"
#include "connectivity.hpp"
#include <algorithm>
#include <numeric>
#include <cmath>
#include <chrono>
#include <map>
#include <unordered_map>
#include <windows.h>
#include <bcrypt.h>
namespace prep {
namespace {
using V=std::array<double,3>;using Json=stem::Json;
V add(V a,V b){return {a[0]+b[0],a[1]+b[1],a[2]+b[2]};}
V sub(V a,V b){return {a[0]-b[0],a[1]-b[1],a[2]-b[2]};}
V mul(V a,double b){return {a[0]*b,a[1]*b,a[2]*b};}
double dot(V a,V b){return a[0]*b[0]+a[1]*b[1]+a[2]*b[2];}
double norm(V a){return std::sqrt(dot(a,a));}
V pos(const Snapshot& s,unsigned i){auto p=s.positions.at(i);return {p[0],p[1],p[2]};}
void check(const std::atomic_bool& c){if(c.load())throw std::runtime_error("Analysis cancelled; previous preparation retained.");}
class Hash {
    BCRYPT_ALG_HANDLE alg=nullptr;BCRYPT_HASH_HANDLE h=nullptr;std::vector<unsigned char> memory;
public:
    Hash(){if(BCryptOpenAlgorithmProvider(&alg,BCRYPT_SHA256_ALGORITHM,nullptr,0)<0)throw std::runtime_error("Hash provider.");DWORD n=0,done=0;BCryptGetProperty(alg,BCRYPT_OBJECT_LENGTH,reinterpret_cast<PUCHAR>(&n),sizeof(n),&done,0);memory.resize(n);if(BCryptCreateHash(alg,&h,memory.data(),n,nullptr,0,0)<0)throw std::runtime_error("Hash state.");}
    ~Hash(){if(h)BCryptDestroyHash(h);if(alg)BCryptCloseAlgorithmProvider(alg,0);}
    void add(const void* p,std::size_t n){if(n>UINT_MAX||BCryptHashData(h,reinterpret_cast<PUCHAR>(const_cast<void*>(p)),ULONG(n),0)<0)throw std::runtime_error("Hash input.");}
    std::string finish(){unsigned char d[32];if(BCryptFinishHash(h,d,32,0)<0)throw std::runtime_error("Hash finish.");std::string r;for(auto b:d){r+="0123456789abcdef"[b>>4];r+="0123456789abcdef"[b&15];}return r;}
};
struct Component {std::vector<unsigned> vertices,faces;unsigned material=0;bool mixed=false;};
struct Guide {unsigned component,sides;double length;std::vector<V> nodes;std::vector<std::vector<unsigned>> rings;std::vector<double> radii;bool blade=false;};
struct Segment {unsigned guide,span;V a,d;double denominator;};
struct Near {int guide=-1;unsigned span=0;double u=0,distance=0;};
using Cell=std::array<int,3>;
struct CellHash {std::size_t operator()(const Cell& c)const{return std::size_t(c[0])*73856093u^std::size_t(c[1])*19349663u^std::size_t(c[2])*83492791u;}};
Cell cell(V p){return {int(std::floor(p[0]/.025)),int(std::floor(p[1]/.025)),int(std::floor(p[2]/.025))};}
std::vector<V> resample(const std::vector<V>& p,unsigned count){std::vector<double> arc(p.size());for(unsigned i=1;i<p.size();++i)arc[i]=arc[i-1]+norm(sub(p[i],p[i-1]));std::vector<V> out;for(unsigned i=0;i<count;++i){double t=arc.back()*i/(count-1);auto j=std::min<std::size_t>(p.size()-1,std::max<std::size_t>(1,std::upper_bound(arc.begin(),arc.end(),t)-arc.begin()));double d=arc[j]-arc[j-1];out.push_back(add(p[j-1],mul(sub(p[j],p[j-1]),d>0?(t-arc[j-1])/d:0)));}return out;}
}
std::string fingerprint(const Snapshot& s){Hash h;unsigned header[]{unsigned(s.positions.size()),unsigned(s.faces.size())};h.add(header,sizeof(header));h.add(s.positions.data(),s.positions.size()*sizeof(s.positions[0]));h.add(s.faces.data(),s.faces.size()*sizeof(s.faces[0]));h.add(s.materials.data(),s.materials.size()*4);return h.finish();}
std::string geometryHash(const Snapshot& s,const std::vector<unsigned>& labels,unsigned components){Hash h;unsigned header[]{0x53544c32u,unsigned(s.positions.size()),unsigned(s.faces.size()),components};h.add(header,sizeof(header));h.add(s.positions.data(),s.positions.size()*sizeof(s.positions[0]));h.add(s.faces.data(),s.faces.size()*sizeof(s.faces[0]));h.add(s.materials.data(),s.materials.size()*4);h.add(labels.data(),labels.size()*4);return h.finish();}
Analysis analyze(const Snapshot& s,Settings settings,const std::atomic_bool& cancel,std::atomic_int& progress){
    const auto started=std::chrono::steady_clock::now();check(cancel);progress=1;
    if(s.positions.size()<3||s.positions.size()>1000000||s.faces.empty()||s.faces.size()>2000000||s.materials.size()!=s.faces.size())throw std::runtime_error("Source admission: at most 1M vertices / 2M triangles.");
    if(!std::isfinite(settings.minimumLength)||settings.minimumLength<.001-1e-10||settings.minimumLength>.1+2e-8||!std::isfinite(settings.foliageFraction)||settings.foliageFraction<.01||settings.foliageFraction>.25)throw std::runtime_error("Preparation minimum must be 1..100 mm and preview foliage 1..25%; received "+std::to_string(settings.minimumLength*1000)+" mm / "+std::to_string(settings.foliageFraction*100)+"%.");
    for(auto p:s.positions)for(auto x:p)if(!std::isfinite(x)||std::abs(x)>10000)throw std::runtime_error("Nonfinite or distant source: move near origin.");
    std::vector<unsigned> parent(s.positions.size());std::iota(parent.begin(),parent.end(),0);auto root=[&](unsigned i){while(parent[i]!=i){parent[i]=parent[parent[i]];i=parent[i];}return i;};
    for(unsigned i=0;i<s.faces.size();++i){if(!(i%4096))check(cancel);auto f=s.faces[i];for(auto v:f)if(v>=parent.size())throw std::runtime_error("Triangle index outside source.");for(int k=1;k<3;++k){auto a=root(f[0]),b=root(f[k]);if(a!=b)parent[std::max(a,b)]=std::min(a,b);}}
    Analysis result;result.fingerprint=fingerprint(s);result.labels.resize(parent.size());std::unordered_map<unsigned,unsigned> ids;std::vector<Component> components;
    for(unsigned i=0;i<parent.size();++i){unsigned r=root(i);auto [it,inserted]=ids.emplace(r,unsigned(components.size()));if(inserted)components.emplace_back();result.labels[i]=it->second;components[it->second].vertices.push_back(i);}
    if(components.size()>40000)throw std::runtime_error("Connected part budget: 40,000.");
    for(unsigned i=0;i<s.faces.size();++i){auto& c=components[result.labels[s.faces[i][0]]];if(c.faces.empty())c.material=s.materials[i];else if(c.material!=s.materials[i])c.mixed=true;c.faces.push_back(i);}
    progress=15;std::vector<Guide> guides;std::vector<int> componentGuide(components.size(),-1);unsigned unsupported=0,mixed=0;double maxRadius=0;
    for(unsigned ci=0;ci<components.size();++ci){if(!(ci%128))check(cancel);auto& c=components[ci];mixed+=c.mixed;const auto nv=c.vertices.size(),nf=c.faces.size();if(nv*2<nf)continue;auto side2=nv*2-nf;if(side2%2)continue;unsigned sides=unsigned(side2/2);if(sides<3||sides>16||nv%sides||nv/sides<3||c.mixed)continue;
        Guide g{ci,sides,0,{},{}};std::vector<V> centres;std::vector<double> ringRadii;bool round=true;double radius=0;
        for(unsigned r=0;r<nv/sides;++r){V centre{};std::vector<unsigned> ring;for(unsigned j=0;j<sides;++j){unsigned i=c.vertices[r*sides+j];ring.push_back(i);centre=add(centre,pos(s,i));}centre=mul(centre,1./sides);centres.push_back(centre);g.rings.push_back(std::move(ring));double lo=1e10,hi=0;for(auto i:g.rings.back()){double d=norm(sub(pos(s,i),centre));lo=std::min(lo,d);hi=std::max(hi,d);}ringRadii.push_back((lo+hi)*.5);radius=std::max(radius,hi);if(lo<1e-7||hi>1.35*lo)round=false;}
        for(unsigned j=1;j<centres.size();++j)g.length+=norm(sub(centres[j],centres[j-1]));
        // Consecutive authored vertex rings must actually be joined by source faces.
        std::unordered_map<unsigned,unsigned> rank;for(unsigned i=0;i<c.vertices.size();++i)rank.emplace(c.vertices[i],i/sides);
        for(auto fi:c.faces){auto f=s.faces[fi];unsigned lo=UINT_MAX,hi=0;for(auto v:f){lo=std::min(lo,rank[v]);hi=std::max(hi,rank[v]);}if(hi!=lo+1)round=false;}
        if(!round||g.length<settings.minimumLength||radius>.03||g.length<4*radius){++unsupported;continue;}
        maxRadius=std::max(maxRadius,radius);g.nodes=resample(centres,g.length>.3?9:g.length>.15?7:g.length>.08?5:3);std::vector<double> arc(centres.size());for(unsigned k=1;k<centres.size();++k)arc[k]=arc[k-1]+norm(sub(centres[k],centres[k-1]));for(unsigned k=0;k<g.nodes.size();++k){double target=g.length*k/(g.nodes.size()-1);auto hi=std::min<std::size_t>(centres.size()-1,std::max<std::size_t>(1,std::upper_bound(arc.begin(),arc.end(),target)-arc.begin()));double u=(target-arc[hi-1])/(arc[hi]-arc[hi-1]);g.radii.push_back(ringRadii[hi-1]*(1-u)+ringRadii[hi]*u);}componentGuide[ci]=int(guides.size());guides.push_back(std::move(g));if(guides.size()>2048)throw std::runtime_error("Stem budget: 2,048 guides.");
    }
    // Dense authored folded leaves retain ordered cross-sections, just like
    // three-column grass, but must bend as independent basal guides rather than
    // being attached as giant rigid foliage to the nearest flower stem.
    double sourceGround=1e100,sourceTop=-1e100;for(auto p:s.positions){sourceGround=std::min(sourceGround,double(p[2]));sourceTop=std::max(sourceTop,double(p[2]));}
    unsigned bladeCount=0;
    for(unsigned ci=0;ci<components.size();++ci){
        const auto& c=components[ci];if(componentGuide[ci]>=0||c.mixed||c.vertices.size()<20)continue;
        for(unsigned width:{3u,5u,7u,9u}){
            const unsigned count=unsigned(c.vertices.size()),rings=count/width,tip=count%width;
            if(rings<3||rings>512||tip>1||c.faces.size()!=(rings-1)*2*(width-1)+(tip?width-1:0))continue;
            std::unordered_map<unsigned,unsigned> rank;for(unsigned k=0;k<count;++k)rank.emplace(c.vertices[k],k/width);
            bool ordered=true;for(auto fi:c.faces){unsigned lo=UINT_MAX,hi=0;for(auto v:s.faces[fi]){lo=std::min(lo,rank.at(v));hi=std::max(hi,rank.at(v));}if(hi!=lo+1){ordered=false;break;}}
            if(!ordered)continue;
            Guide g{ci,width,0,{},{},{},true};std::vector<V> centres;
            for(unsigned row=0;row<rings;++row){V centre{};std::vector<unsigned> ring;for(unsigned side=0;side<width;++side){auto index=c.vertices[row*width+side];ring.push_back(index);centre=add(centre,pos(s,index));}centres.push_back(mul(centre,1./width));g.rings.push_back(std::move(ring));}
            if(tip)centres.push_back(pos(s,c.vertices.back()));
            for(unsigned k=1;k<centres.size();++k)g.length+=norm(sub(centres[k],centres[k-1]));
            if(g.length<settings.minimumLength)continue;
            // The authored blade base must be basal; never promote an airborne
            // petal strip to a root just to make the preparation pass.
            const double band=std::clamp((sourceTop-sourceGround)*.03,.003,.03);
            if(std::min(centres.front()[2],centres.back()[2])>sourceGround+band)continue;
            g.nodes=resample(centres,std::min(16u,std::max(3u,unsigned(std::ceil(g.length/.07))+1)));
            g.radii.assign(g.nodes.size(),.001);componentGuide[ci]=int(guides.size());guides.push_back(std::move(g));++bladeCount;
            if(guides.size()>2048)throw std::runtime_error("Stem budget: 2,048 guides.");break;
        }
    }
    if(guides.empty())throw std::runtime_error("No supported ordered tube stems found. This model needs authored guides or a different preparation profile.");
    progress=30;std::vector<Tube> tubes;for(const auto& g:guides)tubes.push_back({g.nodes,g.radii,g.blade});auto forest=connect(tubes,cancel);for(unsigned i=0;i<guides.size();++i)if(forest.links[i].reversed)std::reverse(guides[i].nodes.begin(),guides[i].nodes.end());
    progress=35;std::vector<Segment> segments;std::unordered_map<Cell,std::vector<unsigned>,CellHash> grid;
    for(unsigned gi=0;gi<guides.size();++gi)for(unsigned si=0;si+1<guides[gi].nodes.size();++si){auto a=guides[gi].nodes[si],d=sub(guides[gi].nodes[si+1],a);double denominator=dot(d,d);if(denominator<1e-14)throw std::runtime_error("Collapsed guide span.");unsigned id=unsigned(segments.size());segments.push_back({gi,si,a,d,denominator});unsigned samples=std::max(2u,unsigned(std::sqrt(denominator)/.01)+1);if(samples>10000)throw std::runtime_error("Guide sampling budget.");for(unsigned k=0;k<samples;++k)grid[cell(add(a,mul(d,double(k)/(samples-1))))].push_back(id);}
    auto nearest=[&](V point,int before)->Near{Near best;double bestSq=1e100;auto test=[&](unsigned id){const auto& s=segments[id];if(before>=0&&int(s.guide)>=before)return;double u=std::clamp(dot(sub(point,s.a),s.d)/s.denominator,0.,1.);auto delta=sub(sub(point,s.a),mul(s.d,u));double d=dot(delta,delta);if(d<bestSq){bestSq=d;best={int(s.guide),s.span,u,std::sqrt(d)};}};Cell key=cell(point);for(int r=1;r<=4;++r){check(cancel);std::vector<unsigned> candidates;for(int x=-r;x<=r;++x)for(int y=-r;y<=r;++y)for(int z=-r;z<=r;++z){auto found=grid.find({key[0]+x,key[1]+y,key[2]+z});if(found!=grid.end())candidates.insert(candidates.end(),found->second.begin(),found->second.end());}std::sort(candidates.begin(),candidates.end());candidates.erase(std::unique(candidates.begin(),candidates.end()),candidates.end());for(auto id:candidates)test(id);if(bestSq<std::pow((r-.5)*.025,2))return best;}for(unsigned i=0;i<segments.size();++i)test(i);return best;};
    Json j={{"schema",2},{"asset","Native ordered tube profile"},{"vertices",s.positions.size()},{"triangles",s.faces.size()},{"guides",Json::array()},{"parts",Json::array()},{"guide_order",Json::array()},{"preview_triangles",Json::array()},{"preview_materials",Json::array()}};
    double maxParent=0,maxAttachment=0;unsigned roots=forest.roots,largeRigid=0;Json rootComponents=Json::array(),unresolvedComponents=Json::array();
    j["connectivity_version"]=2;j["guide_order"]=forest.order;
    for(unsigned gi=0;gi<guides.size();++gi){check(cancel);auto& g=guides[gi];const auto& link=forest.links[gi];if(link.resolved)maxParent=std::max(maxParent,link.distance);if(link.basal)rootComponents.push_back(g.component);if(!link.resolved)unresolvedComponents.push_back(g.component);Json nodes=Json::array();for(auto v:g.nodes)nodes.push_back({v[0],v[2],-v[1]});j["guides"].push_back({{"component",g.component},{"nodes",nodes},{"parent",link.parent},{"parent_span",link.parentSpan},{"parent_u",link.parentU},{"parent_distance_m",link.distance},{"length_m",g.length},{"unresolved",!link.resolved},{"root_kind",link.basal?"basal":link.resolved?"branch":"unresolved"},{"root_ring_vertices",link.basal?(link.reversed?g.rings.back():g.rings.front()):std::vector<unsigned>{}}});}
    progress=50;std::vector<bool> selected(components.size(),false);
    auto addFace=[&](std::array<unsigned,3> f,unsigned m){if(j["preview_triangles"].size()>=160000)throw std::runtime_error("Preview budget: reduce foliage percentage.");j["preview_triangles"].push_back(f);j["preview_materials"].push_back(m);};
    for(unsigned ci=0;ci<components.size();++ci){if(!(ci%64)){check(cancel);progress=50+int(45.*ci/components.size());}const auto& c=components[ci];int gi=componentGuide[ci];Near p;bool isStem=gi>=0;
        if(isStem)p.guide=gi;else{unsigned pivot=c.vertices[0];for(auto i:c.vertices)if(s.positions[i][2]<s.positions[pivot][2])pivot=i;p=nearest(pos(s,pivot),-1);maxAttachment=std::max(maxAttachment,p.distance);if(c.vertices.size()>512)++largeRigid;}
        j["parts"].push_back({{"guide",p.guide},{"stem",isStem},{"span",p.span},{"u",p.u},{"material",c.material}});
        if(isStem&&guides[gi].blade){for(auto fi:c.faces)addFace(s.faces[fi],s.materials[fi]);}
        else if(isStem){const auto& g=guides[gi];unsigned count=std::min<unsigned>(unsigned(g.rings.size()),g.length>.15?5:3);for(unsigned k=1;k<count;++k){auto& a=g.rings[(k-1)*(g.rings.size()-1)/(count-1)];auto& b=g.rings[k*(g.rings.size()-1)/(count-1)];for(unsigned side=0;side<g.sides;++side){auto next=(side+1)%g.sides;addFace({a[side],a[next],b[side]},c.material);addFace({a[next],b[next],b[side]},c.material);}}}
        else {unsigned hash=(ci+2402u)*2654435761u;selected[ci]=c.vertices.size()<=12||double(hash%100000)/100000<settings.foliageFraction;if(selected[ci])for(auto fi:c.faces)addFace(s.faces[fi],s.materials[fi]);}
    }
    j["source_geometry_sha256"]=geometryHash(s,result.labels,unsigned(components.size()));check(cancel);
    const bool supported=largeRigid==0&&mixed==0&&forest.unresolved==0&&forest.roots>0&&maxParent<=.025&&maxAttachment<.15;
    result.report={{"profile",bladeCount?"Round stems and ordered basal folded leaves":"Round tube stems; basal roots and spatial/taper branch forest"},{"folded_leaf_guides",bladeCount},{"guides",guides.size()},{"parts",components.size()},{"ground_roots",roots},{"root_components",rootComponents},{"unresolved_guides",forest.unresolved},{"unresolved_components",unresolvedComponents},{"ground_level_m",forest.ground},{"basal_band_m",forest.basalBand},{"connection_candidates",forest.candidates},{"unsupported_tube_candidates",unsupported},{"large_unresolved_parts",largeRigid},{"mixed_material_parts",mixed},{"max_parent_distance_m",maxParent},{"max_attachment_distance_m",maxAttachment},{"preview_triangles",j["preview_triangles"].size()},{"can_prepare",supported},{"review_required",true},{"warning","Inspect roots, branch direction and foliage attachments. This is geometric inference; botanical correctness is not guaranteed."},{"seconds",std::chrono::duration<double>(std::chrono::steady_clock::now()-started).count()}};
    result.metadata=std::move(j);if(result.metadata.dump().size()>16*1024*1024)throw std::runtime_error("Prepared metadata exceeds 16 MiB.");progress=100;return result;
}
}
