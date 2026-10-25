#include "interactions_geometry.h"
#include <algorithm>
#include <cmath>
#include <limits>
#include <map>
#include <numeric>
#include <stdexcept>
#include <tuple>

namespace cyrus::interactions {
namespace {
double coord(Vec p,int i){return i==0?p.x:i==1?p.y:p.z;}
bool finite(Vec p){return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z);}
Bounds pointBox(Vec p){Bounds b;b.include(p);return b;}
Vec closestTriangle(Vec p,Vec a,Vec b,Vec c){
    auto ab=sub(b,a),ac=sub(c,a),ap=sub(p,a);double d1=dot(ab,ap),d2=dot(ac,ap);
    if(d1<=0&&d2<=0)return a;
    auto bp=sub(p,b);double d3=dot(ab,bp),d4=dot(ac,bp);if(d3>=0&&d4<=d3)return b;
    double vc=d1*d4-d3*d2;if(vc<=0&&d1>=0&&d3<=0)return add(a,mul(ab,d1/(d1-d3)));
    auto cp=sub(p,c);double d5=dot(ab,cp),d6=dot(ac,cp);if(d6>=0&&d5<=d6)return c;
    double vb=d5*d2-d1*d6;if(vb<=0&&d2>=0&&d6<=0)return add(a,mul(ac,d2/(d2-d6)));
    double va=d3*d6-d5*d4;if(va<=0&&(d4-d3)>=0&&(d5-d6)>=0)return add(b,mul(sub(c,b),(d4-d3)/((d4-d3)+(d5-d6))));
    double denominator=va+vb+vc;if(std::abs(denominator)<1e-30)throw std::runtime_error("Degenerate admitted collision triangle");
    return add(a,add(mul(ab,vb/denominator),mul(ac,vc/denominator)));
}
bool rayTriangle(Vec o,Vec d,Vec a,Vec b,Vec c,double& t){
    auto e1=sub(b,a),e2=sub(c,a),h=cross(d,e2);double det=dot(e1,h);
    if(std::abs(det)<1e-14*std::max(1e-12,length(e1)*length(e2)))return false;
    auto s=sub(o,a);double u=dot(s,h)/det;if(u< -1e-10||u>1+1e-10)return false;
    auto q=cross(s,e1);double w=dot(d,q)/det;if(w< -1e-10||u+w>1+1e-10)return false;
    t=dot(e2,q)/det;return t>=0;
}
bool rayBounds(Vec o,Vec d,const Bounds& b){
    double lo=0,hi=1e100;
    for(int k=0;k<3;++k){double x=coord(o,k),v=coord(d,k),a=coord(b.lo,k),z=coord(b.hi,k);
        if(std::abs(v)<1e-20){if(x<a||x>z)return false;continue;}
        double p=(a-x)/v,q=(z-x)/v;if(p>q)std::swap(p,q);lo=std::max(lo,p);hi=std::min(hi,q);if(lo>hi)return false;}
    return true;
}
std::pair<double,double> segmentParameters(Vec a,Vec b,Vec c,Vec d){
    auto u=sub(b,a),w=sub(d,c),r=sub(a,c);double aa=dot(u,u),ee=dot(w,w),ff=dot(w,r),s=0,t=0;
    if(aa<1e-24&&ee<1e-24)return {0,0};
    if(aa<1e-24)t=std::clamp(ff/ee,0.,1.);
    else {double cc=dot(u,r);if(ee<1e-24)s=std::clamp(-cc/aa,0.,1.);
        else {double bb=dot(u,w),den=aa*ee-bb*bb;if(den>1e-24*aa*ee)s=std::clamp((bb*ff-cc*ee)/den,0.,1.);
            t=(bb*s+ff)/ee;if(t<0){t=0;s=std::clamp(-cc/aa,0.,1.);}else if(t>1){t=1;s=std::clamp((bb-cc)/aa,0.,1.);}}}
    return {s,t};
}
}
Vec add(Vec a,Vec b){return {a.x+b.x,a.y+b.y,a.z+b.z};}
Vec sub(Vec a,Vec b){return {a.x-b.x,a.y-b.y,a.z-b.z};}
Vec mul(Vec a,double s){return {a.x*s,a.y*s,a.z*s};}
double dot(Vec a,Vec b){return a.x*b.x+a.y*b.y+a.z*b.z;}
double length(Vec a){return std::sqrt(dot(a,a));}
Vec cross(Vec a,Vec b){return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
Vec unit(Vec a){double n=length(a);if(n<1e-20)throw std::runtime_error("Undefined collision normal");return mul(a,1/n);}
void Bounds::include(Vec p){lo={std::min(lo.x,p.x),std::min(lo.y,p.y),std::min(lo.z,p.z)};hi={std::max(hi.x,p.x),std::max(hi.y,p.y),std::max(hi.z,p.z)};}
void Bounds::include(const Bounds& b){include(b.lo);include(b.hi);}
Bounds Bounds::expanded(double p)const{return {sub(lo,{p,p,p}),add(hi,{p,p,p})};}
bool Bounds::overlaps(const Bounds& b)const{return lo.x<=b.hi.x&&hi.x>=b.lo.x&&lo.y<=b.hi.y&&hi.y>=b.lo.y&&lo.z<=b.hi.z&&hi.z>=b.lo.z;}
double Bounds::distanceSq(const Bounds& b)const{double d=0;for(int k=0;k<3;++k){double x=std::max({coord(lo,k)-coord(b.hi,k),coord(b.lo,k)-coord(hi,k),0.});d+=x*x;}return d;}
double Transform::scale()const{
    for(auto p:rows)if(!finite(p))throw std::runtime_error("Nonfinite interaction transform");
    double s=length(rows[0]);if(s<1e-8)throw std::runtime_error("Singular interaction transform");
    for(int k=0;k<3;++k){if(std::abs(length(rows[k])-s)>s*1e-5)throw std::runtime_error("Interactions currently require positive uniform instance scale");
        for(int j=k+1;j<3;++j)if(std::abs(dot(rows[k],rows[j]))>s*s*1e-5)throw std::runtime_error("Sheared interaction transform is unsupported");}
    if(dot(cross(rows[0],rows[1]),rows[2])<=0)throw std::runtime_error("Mirrored interaction transform is unsupported");return s;
}
Vec Transform::vector(Vec p)const{return add(add(mul(rows[0],p.x),mul(rows[1],p.y)),mul(rows[2],p.z));}
Vec Transform::point(Vec p)const{return add(vector(p),rows[3]);}
Vec Transform::inverseVector(Vec p)const{const auto x=cross(rows[1],rows[2]),y=cross(rows[2],rows[0]),z=cross(rows[0],rows[1]);const double determinant=dot(rows[0],x);if(std::abs(determinant)<1e-24)throw std::runtime_error("Singular interaction inverse");return {dot(p,x)/determinant,dot(p,y)/determinant,dot(p,z)/determinant};}
Vec Transform::inversePoint(Vec p)const{return inverseVector(sub(p,rows[3]));}
Bounds Transform::bounds(const Bounds& b)const{Bounds r;for(int i=0;i<8;++i)r.include(point({i&1?b.hi.x:b.lo.x,i&2?b.hi.y:b.lo.y,i&4?b.hi.z:b.lo.z}));return r;}

struct MeshGeometry::Impl {
    struct Node {Bounds box;unsigned begin=0,count=0,left=0,right=0;};
    std::vector<Vec> vertices;std::vector<Tri> triangles;std::vector<unsigned> order;std::vector<Node> nodes;Bounds box;bool closed=true;
    Bounds triangleBounds(unsigned id)const{Bounds b;for(auto i:triangles[id])b.include(vertices[i]);return b;}
    unsigned build(unsigned begin,unsigned end){
        unsigned id=unsigned(nodes.size());nodes.emplace_back();Bounds b,centres;
        for(unsigned i=begin;i<end;++i){auto a=triangleBounds(order[i]);b.include(a);centres.include(mul(add(a.lo,a.hi),.5));}
        nodes[id].box=b;if(end-begin<=8){nodes[id].begin=begin;nodes[id].count=end-begin;return id;}
        Vec size=sub(centres.hi,centres.lo);int axis=size.x>size.y?(size.x>size.z?0:2):(size.y>size.z?1:2);unsigned mid=(begin+end)/2;
        std::nth_element(order.begin()+begin,order.begin()+mid,order.begin()+end,[&](unsigned a,unsigned c){auto x=triangleBounds(a),y=triangleBounds(c);double p=coord(add(x.lo,x.hi),axis),q=coord(add(y.lo,y.hi),axis);return p==q?a<c:p<q;});
        auto left=build(begin,mid),right=build(mid,end);nodes[id].left=left;nodes[id].right=right;return id;
    }
    bool inside(Vec p)const{
        if(!closed)return false;Vec direction=unit({1,.3713906763541037,.6947465906068658});std::vector<double> hits;std::vector<unsigned> stack{0};
        while(!stack.empty()){auto id=stack.back();stack.pop_back();const auto& n=nodes[id];if(!rayBounds(p,direction,n.box))continue;
            if(n.count)for(unsigned j=n.begin;j<n.begin+n.count;++j){const auto& t=triangles[order[j]];double distance=0;if(rayTriangle(p,direction,vertices[t[0]],vertices[t[1]],vertices[t[2]],distance)&&distance>1e-9)hits.push_back(distance);}
            else{stack.push_back(n.left);stack.push_back(n.right);}}
        std::sort(hits.begin(),hits.end());unsigned distinct=0;double last=-1;
        for(double t:hits)if(last<0||t-last>1e-8*std::max(1.,t)){++distinct;last=t;}return distinct%2!=0;
    }
    Witness point(Vec p)const{
        double best=1e100;Vec surface{};unsigned face=0;std::vector<unsigned> stack{0};Bounds pb=pointBox(p);
        while(!stack.empty()){auto id=stack.back();stack.pop_back();const auto& n=nodes[id];if(n.box.distanceSq(pb)>best)continue;
            if(n.count)for(unsigned j=n.begin;j<n.begin+n.count;++j){unsigned fi=order[j];auto t=triangles[fi];auto q=closestTriangle(p,vertices[t[0]],vertices[t[1]],vertices[t[2]]);auto d=sub(p,q);double sq=dot(d,d);if(sq<best){best=sq;surface=q;face=fi;}}
            else{double a=nodes[n.left].box.distanceSq(pb),b=nodes[n.right].box.distanceSq(pb);if(a<b){stack.push_back(n.right);stack.push_back(n.left);}else{stack.push_back(n.left);stack.push_back(n.right);}}}
        bool negative=closed&&inside(p);double distance=std::sqrt(best);Vec normal;
        if(distance>1e-10)normal=mul(sub(p,surface),(negative?-1:1)/distance);
        else {auto t=triangles[face];normal=unit(cross(sub(vertices[t[1]],vertices[t[0]]),sub(vertices[t[2]],vertices[t[0]])));if(closed&&inside(add(surface,mul(normal,1e-7))))normal=mul(normal,-1);}
        return {p,surface,normal,0,negative?-distance:distance};
    }
    std::optional<Witness> segment(Vec a,Vec b,double maximum=1e50)const{
        Bounds segmentBox;segmentBox.include(a);segmentBox.include(b);double best=maximum*maximum,bestU=0;bool found=false;std::vector<unsigned> stack{0};Vec axis{},surface{};
        auto consider=[&](Vec p,Vec q,double u){double d=dot(sub(p,q),sub(p,q));if(d<=best){found=true;best=d;axis=p;surface=q;bestU=u;}};
        while(!stack.empty()){auto id=stack.back();stack.pop_back();const auto& n=nodes[id];if(n.box.distanceSq(segmentBox)>best)continue;
            if(n.count)for(unsigned j=n.begin;j<n.begin+n.count;++j){auto t=triangles[order[j]];Vec x=vertices[t[0]],y=vertices[t[1]],z=vertices[t[2]];double hit=0;
                if(rayTriangle(a,sub(b,a),x,y,z,hit)&&hit<=1){auto p=add(a,mul(sub(b,a),hit));consider(p,p,hit);}
                consider(a,closestTriangle(a,x,y,z),0);consider(b,closestTriangle(b,x,y,z),1);
                for(unsigned k=0;k<3;++k){auto c=vertices[t[k]],d=vertices[t[(k+1)%3]];auto [u,v]=segmentParameters(a,b,c,d);consider(add(a,mul(sub(b,a),u)),add(c,mul(sub(d,c),v)),u);}}
            else{stack.push_back(n.left);stack.push_back(n.right);}}
        // When every surface is farther than the capsule envelope, a single
        // parity test distinguishes exterior separation from deep containment.
        // Exterior misses never require an unbounded nearest-surface search.
        if(!found){if(!closed||!inside(a))return {};return segment(a,b);}
        // The nearest surface witness catches crossings exactly. Signed samples
        // additionally supply a useful deep-containment direction for the fit.
        // A positive segment/triangle minimum and an exterior witness prove
        // this connected segment never enters the closed volume. Reuse that
        // exact closest pair instead of running six more nearest-point BVHs.
        if(best>1e-18&&(!closed||!inside(axis))){const auto distance=std::sqrt(best);return Witness{axis,surface,mul(sub(axis,surface),1/distance),bestU,distance};}
        Witness out=point(axis);out.u=bestU;
        for(double u:{0.,.25,.5,.75,1.}){auto q=point(add(a,mul(sub(b,a),u)));q.u=u;if(q.gap<out.gap)out=q;}
        return out;
    }
};
MeshGeometry::MeshGeometry(std::vector<Vec> vertices,std::vector<Tri> triangles,bool requireSolid){
    if(vertices.size()<3||vertices.size()>2000000||triangles.empty()||triangles.size()>4000000)throw std::runtime_error("Interaction collider exceeds geometry admission");
    auto p=std::make_shared<Impl>();p->vertices=std::move(vertices);
    std::map<std::tuple<long long,long long,long long>,unsigned> welded;std::vector<unsigned> ids;ids.reserve(p->vertices.size());
    for(auto q:p->vertices){if(!finite(q)||length(q)>10000)throw std::runtime_error("Invalid collider source coordinates");p->box.include(q);auto key=std::make_tuple(std::llround(q.x/1e-7),std::llround(q.y/1e-7),std::llround(q.z/1e-7));auto [it,inserted]=welded.emplace(key,unsigned(welded.size()));(void)inserted;ids.push_back(it->second);}
    std::map<std::pair<unsigned,unsigned>,unsigned> edges;
    for(auto t:triangles){for(auto i:t)if(i>=p->vertices.size())throw std::runtime_error("Collider triangle index outside source");
        if(length(cross(sub(p->vertices[t[1]],p->vertices[t[0]]),sub(p->vertices[t[2]],p->vertices[t[0]])))<1e-14)continue;
        p->triangles.push_back(t);for(unsigned k=0;k<3;++k){unsigned a=ids[t[k]],b=ids[t[(k+1)%3]];if(a>b)std::swap(a,b);++edges[{a,b}];}}
    if(p->triangles.empty())throw std::runtime_error("Collider has no admitted triangles");
    p->closed=std::all_of(edges.begin(),edges.end(),[](const auto& e){return e.second==2;});
    if(requireSolid&&!p->closed)throw std::runtime_error("Mesh collider is open/nonmanifold after seam welding; choose an explicit proxy");
    p->order.resize(p->triangles.size());std::iota(p->order.begin(),p->order.end(),0);p->nodes.reserve(2*p->triangles.size());p->build(0,unsigned(p->triangles.size()));impl_=std::move(p);
}
const Bounds& MeshGeometry::bounds()const{return impl_->box;}
bool MeshGeometry::solid()const{return impl_->closed;}
std::size_t MeshGeometry::bytes()const{return sizeof(*impl_)+impl_->vertices.capacity()*sizeof(Vec)+impl_->triangles.capacity()*sizeof(Tri)+impl_->order.capacity()*sizeof(unsigned)+impl_->nodes.capacity()*sizeof(Impl::Node);}
Witness MeshGeometry::point(Vec p)const{return impl_->point(p);}
Witness MeshGeometry::segment(Vec a,Vec b)const{return impl_->segment(a,b).value();}
std::optional<Witness> MeshGeometry::contactSegment(Vec a,Vec b,double radius)const{return impl_->segment(a,b,radius);}
bool MeshGeometry::rayHit(Vec origin,Vec direction,double maximumDistance)const{
    direction=unit(direction);std::vector<unsigned> stack{0};Bounds query;query.include(origin);query.include(add(origin,mul(direction,maximumDistance)));
    while(!stack.empty()){const auto id=stack.back();stack.pop_back();const auto& node=impl_->nodes[id];if(!node.box.overlaps(query)||!rayBounds(origin,direction,node.box))continue;
        if(node.count)for(unsigned i=node.begin;i<node.begin+node.count;++i){auto t=impl_->triangles[impl_->order[i]];double distance=0;if(rayTriangle(origin,direction,impl_->vertices[t[0]],impl_->vertices[t[1]],impl_->vertices[t[2]],distance)&&distance<=maximumDistance)return true;}
        else {stack.push_back(node.left);stack.push_back(node.right);}}
    return false;
}
bool MeshGeometry::projectedNear(Vec origin,Vec direction,double radius)const{
    direction=unit(direction);const auto u=unit(cross(direction,std::abs(direction.x)<.8?Vec{1,0,0}:Vec{0,1,0})),v=cross(direction,u);const double px=dot(origin,u),py=dot(origin,v),limit=radius*radius;
    auto edgeDistance=[&](double ax,double ay,double bx,double by){const double x=bx-ax,y=by-ay,den=x*x+y*y;const double t=den>1e-30?std::clamp(((px-ax)*x+(py-ay)*y)/den,0.,1.):0.;const double dx=px-ax-t*x,dy=py-ay-t*y;return dx*dx+dy*dy;};
    std::vector<unsigned> stack{0};while(!stack.empty()){auto id=stack.back();stack.pop_back();const auto& node=impl_->nodes[id];const auto c=mul(add(node.box.lo,node.box.hi),.5),e=mul(sub(node.box.hi,node.box.lo),.5);
        const double ex=std::abs(u.x)*e.x+std::abs(u.y)*e.y+std::abs(u.z)*e.z,ey=std::abs(v.x)*e.x+std::abs(v.y)*e.y+std::abs(v.z)*e.z;
        const double dx=std::max(0.,std::abs(px-dot(c,u))-ex),dy=std::max(0.,std::abs(py-dot(c,v))-ey);if(dx*dx+dy*dy>limit)continue;
        if(node.count)for(unsigned i=node.begin;i<node.begin+node.count;++i){auto triangle=impl_->triangles[impl_->order[i]];double x[3],y[3],side[3];for(unsigned k=0;k<3;++k){x[k]=dot(impl_->vertices[triangle[k]],u);y[k]=dot(impl_->vertices[triangle[k]],v);}
            for(unsigned k=0;k<3;++k){unsigned j=(k+1)%3;side[k]=(x[j]-x[k])*(py-y[k])-(y[j]-y[k])*(px-x[k]);if(edgeDistance(x[k],y[k],x[j],y[j])<=limit)return true;}
            const double area=(x[1]-x[0])*(y[2]-y[0])-(y[1]-y[0])*(x[2]-x[0]);if(std::abs(area)>1e-20&&((side[0]>=0&&side[1]>=0&&side[2]>=0)||(side[0]<=0&&side[1]<=0&&side[2]<=0)))return true;
        }else{stack.push_back(node.left);stack.push_back(node.right);}}
    return false;
}
bool MeshGeometry::overlapsSolid(const Bounds& box)const{
    if(!box.overlaps(impl_->box))return false;const auto centre=mul(add(box.lo,box.hi),.5),extent=mul(sub(box.hi,box.lo),.5);
    auto triangle=[&](Tri face){Vec p[3];for(unsigned k=0;k<3;++k)p[k]=sub(impl_->vertices[face[k]],centre);
        auto separated=[&](Vec axis){if(dot(axis,axis)<1e-28)return false;const double radius=std::abs(axis.x)*extent.x+std::abs(axis.y)*extent.y+std::abs(axis.z)*extent.z,epsilon=1e-12*(1+radius);double lo=dot(p[0],axis),hi=lo;for(unsigned k=1;k<3;++k){auto d=dot(p[k],axis);lo=std::min(lo,d);hi=std::max(hi,d);}return lo>radius+epsilon||hi< -radius-epsilon;};
        const Vec axes[3]{{1,0,0},{0,1,0},{0,0,1}};for(auto axis:axes)if(separated(axis))return false;
        if(separated(cross(sub(p[1],p[0]),sub(p[2],p[0]))))return false;
        for(unsigned k=0;k<3;++k)for(auto axis:axes)if(separated(cross(sub(p[(k+1)%3],p[k]),axis)))return false;return true;};
    std::vector<unsigned> stack{0};while(!stack.empty()){auto id=stack.back();stack.pop_back();const auto& node=impl_->nodes[id];if(!box.overlaps(node.box))continue;
        if(node.count){for(unsigned i=node.begin;i<node.begin+node.count;++i)if(triangle(impl_->triangles[impl_->order[i]]))return true;}
        else{stack.push_back(node.left);stack.push_back(node.right);}}
    return impl_->inside(centre);
}
double MeshGeometry::triangleDistance(Vec a,Vec b,Vec c)const{
    const Vec query[3]{a,b,c};Bounds box;for(auto p:query)box.include(p);double best=1e100;std::vector<unsigned> stack{0};
    auto distance=[&](Vec p,Vec q){const auto d=sub(p,q);best=std::min(best,dot(d,d));};
    while(!stack.empty()){auto id=stack.back();stack.pop_back();const auto& node=impl_->nodes[id];if(node.box.distanceSq(box)>best)continue;
        if(node.count)for(unsigned i=node.begin;i<node.begin+node.count;++i){auto tri=impl_->triangles[impl_->order[i]];Vec target[3]{impl_->vertices[tri[0]],impl_->vertices[tri[1]],impl_->vertices[tri[2]]};
            for(unsigned k=0;k<3;++k){double u=0;if(rayTriangle(query[k],sub(query[(k+1)%3],query[k]),target[0],target[1],target[2],u)&&u<=1)return 0;
                if(rayTriangle(target[k],sub(target[(k+1)%3],target[k]),a,b,c,u)&&u<=1)return 0;
                distance(query[k],closestTriangle(query[k],target[0],target[1],target[2]));distance(target[k],closestTriangle(target[k],a,b,c));
                for(unsigned j=0;j<3;++j){auto [s,t]=segmentParameters(query[k],query[(k+1)%3],target[j],target[(j+1)%3]);distance(add(query[k],mul(sub(query[(k+1)%3],query[k]),s)),add(target[j],mul(sub(target[(j+1)%3],target[j]),t)));}}
        }else{stack.push_back(node.left);stack.push_back(node.right);}}
    return std::sqrt(best);
}
MeshWorld::MeshWorld(std::uint64_t generation,std::vector<Shape> shapes,std::size_t calls,std::size_t contacts):generation_(generation),shapes_(std::move(shapes)),maxCalls_(calls),maxContacts_(contacts){
    if(!generation||!calls||!contacts||shapes_.size()>4096)throw std::runtime_error("Invalid mesh world admission");
    std::vector<std::uint64_t> ids;for(const auto& s:shapes_){if(!s.id||!s.geometry||!s.geometry->solid())throw std::runtime_error("Invalid solid collider binding");s.transform.scale();ids.push_back(s.id);}
    std::sort(ids.begin(),ids.end());if(std::adjacent_find(ids.begin(),ids.end())!=ids.end())throw std::runtime_error("Duplicate collider identity");
}
bool MeshWorld::admit(v::Cancellation c)const{return !c.requested()&&++calls_<=maxCalls_;}
v::BackendIdentity MeshWorld::backend()const{return {"Cyrus mesh contact adapter","0.87.0","CPU double; welded closed triangle meshes","SI; positive uniform similarities"};}
v::PointResult MeshWorld::classify_point(Vec p,double radius,v::Cancellation cancel)const{
    v::PointResult out;out.generation=generation_;if(!admit(cancel)){out.outcome=cancel.requested()?v::Outcome::Cancelled:v::Outcome::ResourceLimit;return out;}
    if(!finite(p)||!std::isfinite(radius)||radius<0){out.outcome=v::Outcome::InvalidInput;return out;}
    for(const auto& s:shapes_){auto w=s.geometry->point(s.transform.inversePoint(p));double gap=w.gap*s.transform.scale()-radius;
        out.hits.push_back({s.id,gap< -1e-7?v::Location::Inside:gap>1e-7?v::Location::Outside:v::Location::Boundary,gap});}
    out.outcome=v::Outcome::Ok;out.complete=true;return out;
}
v::ContactResult MeshWorld::query_capsule(const v::CapsuleQuery& q,v::Cancellation cancel)const{
    v::ContactResult out;out.generation=generation_;if(!admit(cancel)){out.outcome=cancel.requested()?v::Outcome::Cancelled:v::Outcome::ResourceLimit;return out;}
    if(!q.guide_id||!q.span_id||!finite(q.a)||!finite(q.b)||length(sub(q.b,q.a))<1e-12||!std::isfinite(q.geometric_radius_m)||q.geometric_radius_m<0||!std::isfinite(q.clearance_m)||q.clearance_m<0){out.outcome=v::Outcome::InvalidInput;return out;}
    Bounds query;query.include(q.a);query.include(q.b);query=query.expanded(q.geometric_radius_m+q.clearance_m+1e-6);
    for(const auto& s:shapes_){if(!query.overlaps(s.transform.bounds(s.geometry->bounds())))continue;
        auto candidate=s.geometry->contactSegment(s.transform.inversePoint(q.a),s.transform.inversePoint(q.b),(q.geometric_radius_m+q.clearance_m+1e-6)/s.transform.scale());if(!candidate)continue;auto w=*candidate;
        // Max's float similarities carry small orthogonality errors. Rebuild
        // the axis from the caller's material fraction and use the exact
        // inverse-transpose normal; the qualified witness equation must hold
        // in the caller's coordinates, not approximately in source space.
        const auto axis=add(q.a,mul(sub(q.b,q.a),w.u)),surface=s.transform.point(w.surface);
        const auto& r=s.transform.rows;const auto normal=unit(add(add(mul(cross(r[1],r[2]),w.normal.x),mul(cross(r[2],r[0]),w.normal.y)),mul(cross(r[0],r[1]),w.normal.z)));
        double gap=dot(normal,sub(axis,surface))-q.geometric_radius_m-q.clearance_m;if(gap>1e-7)continue;
        if(out.contacts.size()>=maxContacts_){out.outcome=v::Outcome::ResourceLimit;return out;}
        out.contacts.push_back({s.id,q.guide_id,q.span_id,w.u,true,axis,surface,normal,gap});}
    out.outcome=v::Outcome::Ok;out.complete=true;return out;
}
}
