// Included inside namespace amin; all work uses copied geometry, never Max APIs.
namespace {
struct Cell {
    std::int64_t x,y,z;
    bool operator==(const Cell& b) const {return x==b.x&&y==b.y&&z==b.z;}
};
struct CellHash {
    std::size_t operator()(const Cell& c) const {
        return std::hash<std::int64_t>{}(c.x) ^ (std::hash<std::int64_t>{}(c.y)*0x9e3779b9u) ^ (std::hash<std::int64_t>{}(c.z)*0x85ebca6bu);
    }
};
struct PointGrid {
    double width;
    std::unordered_map<Cell,std::vector<std::size_t>,CellHash> cells;
    explicit PointGrid(double w):width(w) {}
    Cell cell(Vec3 p) const {
        const auto coord=[&](double a) {
            const auto v=std::floor(a/width);
            if(!std::isfinite(v)||std::abs(v)>9e15) throw std::invalid_argument("Spacing too small for scene coordinates");
            return static_cast<std::int64_t>(v);
        };
        return {coord(p.x),coord(p.y),coord(p.z)};
    }
    void add(Vec3 p,std::size_t i) {cells[cell(p)].push_back(i);}
    template<class F> void visit(Vec3 p,F fn) const {
        const auto c=cell(p);
        for(int z=-1;z<=1;++z) for(int y=-1;y<=1;++y) for(int x=-1;x<=1;++x) {
            const auto it=cells.find({c.x+x,c.y+y,c.z+z});
            if(it!=cells.end()) for(auto i:it->second) if(!fn(i)) return;
        }
    }
};
// Triangle BVH avoids scanning the whole surface for every solver step.
class SurfaceTree {
    struct Node {Vec3 lo{INFINITY,INFINITY,INFINITY},hi{-INFINITY,-INFINITY,-INFINITY};std::size_t begin{},end{};int left{-1},right{-1};};
    const std::vector<Triangle>& mesh;
    std::vector<std::uint32_t> ids;
    std::vector<Node> nodes;
    static double axis(Vec3 p,int a) {return a==0?p.x:(a==1?p.y:p.z);}
    int build(std::size_t begin,std::size_t end) {
        Node n;n.begin=begin;n.end=end;
        for(auto i=begin;i<end;++i) for(auto p:{mesh[ids[i]].a,mesh[ids[i]].b,mesh[ids[i]].c}) {
            n.lo={std::min(n.lo.x,p.x),std::min(n.lo.y,p.y),std::min(n.lo.z,p.z)};
            n.hi={std::max(n.hi.x,p.x),std::max(n.hi.y,p.y),std::max(n.hi.z,p.z)};
        }
        const int index=static_cast<int>(nodes.size());nodes.push_back(n);
        if(end-begin>8) {
            const auto span=n.hi-n.lo;const int a=span.x>span.y?(span.x>span.z?0:2):(span.y>span.z?1:2);
            const auto middle=begin+(end-begin)/2;
            std::nth_element(ids.begin()+begin,ids.begin()+middle,ids.begin()+end,[&](auto i,auto j){
                const auto& t=mesh[i];const auto& u=mesh[j];return axis(t.a+t.b+t.c,a)<axis(u.a+u.b+u.c,a);
            });
            const int l=build(begin,middle),r=build(middle,end);nodes[index].left=l;nodes[index].right=r;
        }
        return index;
    }
    double bound(Vec3 p,int i) const {
        const auto& n=nodes[i];const Vec3 q{std::clamp(p.x,n.lo.x,n.hi.x),std::clamp(p.y,n.lo.y,n.hi.y),std::clamp(p.z,n.lo.z,n.hi.z)};
        return dot(p-q,p-q);
    }
    void search(Vec3 p,int i,double& best,Vec3& q,std::uint32_t& tri) const {
        if(bound(p,i)>best) return;
        const auto& n=nodes[i];
        if(n.left<0) for(auto k=n.begin;k<n.end;++k) {
            const auto candidate=closest(p,mesh[ids[k]]);const double d=dot(candidate-p,candidate-p);
            if(d<best) {best=d;q=candidate;tri=ids[k];}
        } else {
            int a=n.left,b=n.right;if(bound(p,a)>bound(p,b)) std::swap(a,b);
            search(p,a,best,q,tri);search(p,b,best,q,tri);
        }
    }
public:
    explicit SurfaceTree(const std::vector<Triangle>& m):mesh(m) {
        for(std::size_t i=0;i<m.size();++i) if(length(cross(m[i].b-m[i].a,m[i].c-m[i].a))>0) ids.push_back(static_cast<std::uint32_t>(i));
        build(0,ids.size());
    }
    std::pair<Vec3,std::uint32_t> project(Vec3 p,std::uint32_t hint) const {
        auto q=closest(p,mesh[hint]);double best=dot(q-p,q-p);auto tri=hint;
        search(p,0,best,q,tri);return {q,tri};
    }
};
void spacePoints(std::vector<Instance>& points,const std::vector<Triangle>& surface,const Settings& s,
                 const std::function<bool(std::size_t,Vec3,std::uint32_t)>& allowed) {
    if(s.relaxEnabled&&s.relaxIterations&&s.relaxStrength>0&&!points.empty()) {
        SurfaceTree tree(surface);
        auto next=points;
        for(std::uint32_t iteration=0;iteration<s.relaxIterations;++iteration) {
            PointGrid grid(s.relaxSpacing);grid.cells.reserve(points.size());
            for(std::size_t i=0;i<points.size();++i) grid.add(points[i].position,i);
            double maximumMove=0;
            for(std::size_t i=0;i<points.size();++i) {
                const auto& p=points[i];Vec3 force{};int neighbors=0,visited=0;
                // Bounded neighbor work even for pathological coincident populations.
                grid.visit(p.position,[&](std::size_t j){
                    if(j==i) return true;
                    auto delta=p.position-points[j].position;double d=length(delta);
                    if(d<s.relaxSpacing) {
                        if(d<1e-12) {
                            const auto h=mix(static_cast<std::uint32_t>(std::min(i,j))^mix(static_cast<std::uint32_t>(std::max(i,j)))^s.seed);
                            const double angle=hashUnit(h)*6.283185307179586;
                            const auto& t=surface[p.triangle];const auto normal=unit(cross(t.b-t.a,t.c-t.a));
                            const auto x=unit(t.b-t.a),y=cross(normal,x);
                            delta=(x*std::cos(angle)+y*std::sin(angle))*(i<j?1.0:-1.0);d=1;
                            force=force+delta*s.relaxSpacing;
                        } else force=force+delta*((s.relaxSpacing-d)/d);
                        ++neighbors;
                    }
                    return ++visited<128;
                });
                next[i]=p;
                if(!neighbors) continue;
                auto step=force*(s.relaxStrength/neighbors);const double size=length(step),cap=s.relaxSpacing*.25;
                if(size>cap) step=step*(cap/size);
                const auto [q,tri]=tree.project(p.position+step,p.triangle);
                if(!allowed(i,q,tri)) continue;
                next[i].position=q;next[i].triangle=tri;
                if(s.alignToNormal&&tri!=p.triangle) {
                    const auto frame=[&](std::uint32_t t){
                        const auto& v=surface[t];const auto z=unit(cross(v.b-v.a,v.c-v.a));
                        const auto x=unit(cross(std::abs(z.z)<.999?Vec3{0,0,1}:Vec3{0,1,0},z));return std::array<Vec3,3>{x,cross(z,x),z};
                    };
                    const auto a=frame(p.triangle),b=frame(tri);
                    const auto turn=[&](Vec3 v){return b[0]*dot(v,a[0])+b[1]*dot(v,a[1])+b[2]*dot(v,a[2]);};
                    next[i].xAxis=turn(p.xAxis);next[i].yAxis=turn(p.yAxis);next[i].zAxis=turn(p.zAxis);
                }
                maximumMove=std::max(maximumMove,length(q-p.position));
            }
            points.swap(next);
            if(maximumMove<s.relaxSpacing*1e-5) break;
        }
    }
    if(s.collisionEnabled) {
        const double separation=2*s.collisionRadius;
        PointGrid grid(separation);grid.cells.reserve(points.size());
        std::vector<Instance> kept;kept.reserve(points.size());
        for(const auto& p:points) {
            bool collision=false;
            grid.visit(p.position,[&](std::size_t j){collision=length(p.position-kept[j].position)<separation;return !collision;});
            if(!collision) {grid.add(p.position,kept.size());kept.push_back(p);}
        }
        points.swap(kept);
    }
}
}
