// Included in namespace amin. Uses the frozen closest-point arithmetic above.
namespace detail {
struct ProjectedMovementIndex::Impl {
    struct Node {Vec3 lo{},hi{};std::uint32_t begin=0,end=0,left=0,right=0;};
    struct Scratch {
        ProjectionWorkBudget& work;std::uint64_t bytes;
        Scratch(ProjectionWorkBudget& w,std::uint64_t n):work(w),bytes(n){work.acquire(bytes);}
        ~Scratch(){work.release(bytes);}
    };
    static constexpr std::size_t exhaustiveLimit=32,leafSize=8;
    const std::vector<Triangle>& mesh;
    const std::vector<std::uint32_t>& eligible;
    ProjectionWorkBudget& work;
    Scratch scratch;
    std::vector<std::uint32_t> order;
    std::vector<Node> nodes;

    static std::size_t capacity(std::size_t count) {
        if(count<=exhaustiveLimit)return 0;
        if(count>std::numeric_limits<std::uint32_t>::max())throw std::invalid_argument("Projected movement receiver has too many eligible faces; the previous result is retained.");
        std::size_t leaves=1;
        while(leaves<(count+leafSize-1)/leafSize) {
            if(leaves>std::numeric_limits<std::uint32_t>::max()/2)throw std::invalid_argument("Projected movement index size overflow; the previous result is retained.");
            leaves*=2;
        }
        return leaves*2-1;
    }
    static std::uint64_t bytes(std::size_t count) {
        const auto nodeCount=capacity(count);
        if(!nodeCount)return 0;
        // Sizes are bounded by uint32 above. Include a conservative fixed
        // allowance for the bounded (at most 32-level) build/query stacks.
        return std::uint64_t(count)*sizeof(std::uint32_t)+std::uint64_t(nodeCount)*sizeof(Node)+sizeof(Impl)+4096;
    }
    static double axis(Vec3 p,int a){return a==0?p.x:(a==1?p.y:p.z);}
    std::uint32_t build(std::size_t begin,std::size_t end) {
        Node node;node.begin=static_cast<std::uint32_t>(begin);node.end=static_cast<std::uint32_t>(end);
        node.lo={INFINITY,INFINITY,INFINITY};node.hi={-INFINITY,-INFINITY,-INFINITY};
        for(auto i=begin;i<end;++i) {
            work.charge(work.buildUnits,3);
            const auto& t=mesh[eligible[order[i]]];
            for(auto p:{t.a,t.b,t.c}) {
                node.lo={std::min(node.lo.x,p.x),std::min(node.lo.y,p.y),std::min(node.lo.z,p.z)};
                node.hi={std::max(node.hi.x,p.x),std::max(node.hi.y,p.y),std::max(node.hi.z,p.z)};
            }
        }
        const auto span=node.hi-node.lo;
        const int a=span.x>span.y?(span.x>span.z?0:2):(span.y>span.z?1:2);
        // Expand outward to include rounding in the unchanged leaf arithmetic.
        for(int k=0;k<3;++k) {
            double* lo=k==0?&node.lo.x:(k==1?&node.lo.y:&node.lo.z);
            double* hi=k==0?&node.hi.x:(k==1?&node.hi.y:&node.hi.z);
            const auto pad=64*std::numeric_limits<double>::epsilon()*std::max({1.,std::abs(*lo),std::abs(*hi)});
            *lo=std::nextafter(*lo-pad,-INFINITY);*hi=std::nextafter(*hi+pad,INFINITY);
        }
        const auto index=static_cast<std::uint32_t>(nodes.size());nodes.push_back(node);
        if(end-begin>leafSize) {
            const auto middle=begin+(end-begin)/2;
            std::nth_element(order.begin()+begin,order.begin()+middle,order.begin()+end,[&](auto i,auto j) {
                work.charge(work.buildUnits);
                const auto& t=mesh[eligible[i]];const auto& u=mesh[eligible[j]];
                const auto x=axis(t.a,a)/3+axis(t.b,a)/3+axis(t.c,a)/3;
                const auto y=axis(u.a,a)/3+axis(u.b,a)/3+axis(u.c,a)/3;
                return x<y||(x==y&&i<j);
            });
            const auto left=build(begin,middle),right=build(middle,end);
            nodes[index].left=left;nodes[index].right=right;
        }
        return index;
    }
    Impl(const std::vector<Triangle>& m,const std::vector<std::uint32_t>& e,ProjectionWorkBudget& w)
        :mesh(m),eligible(e),work(w),scratch(w,bytes(e.size())) {
        if(e.empty())throw std::invalid_argument("Projected movement requires eligible receiver faces; the previous result is retained.");
        for(auto face:e) {
            work.charge(work.buildUnits);
            if(face>=m.size()||!finite(m[face].a)||!finite(m[face].b)||!finite(m[face].c))
                throw std::invalid_argument("Projected movement has an invalid receiver face; repair the receiver. The previous result is retained.");
        }
        if(e.size()<=exhaustiveLimit)return;
        order.resize(e.size());std::iota(order.begin(),order.end(),0u);
        nodes.reserve(capacity(e.size()));build(0,e.size());++work.builds;
    }
    double lowerBound(Vec3 p,std::uint32_t index) const {
        work.charge(work.nodeVisits);
        const auto& n=nodes[index];double sum=0;
        for(int k=0;k<3;++k) {
            const double value=axis(p,k),lo=axis(n.lo,k),hi=axis(n.hi,k);
            const auto pad=64*std::numeric_limits<double>::epsilon()*std::max(1.,std::abs(value));
            const auto distance=value<lo?lo-value:(value>hi?value-hi:0.);
            const auto delta=std::nextafter(std::max(0.,distance-pad),0.);
            const auto square=std::nextafter(delta*delta,0.);
            sum=std::nextafter(sum+square,0.);
        }
        // Overflow cannot safely prune. Exact leaf evaluation below rejects an
        // unsupported numerical range instead of returning an arbitrary face.
        return std::isfinite(sum)?sum:0.;
    }
    void test(Vec3 p,std::uint32_t ordinal,double& best,Vec3& q,std::uint32_t& winner) const {
        work.charge(work.triangleTests);
        const auto candidate=closest(p,mesh[eligible[ordinal]]);const auto delta=candidate-p;
        const double d=dot(delta,delta);
        if(!finite(candidate)||!std::isfinite(d))throw std::invalid_argument("Projected movement exceeds the supported numerical range. Repair or rescale the receiver; the previous result is retained.");
        if(d<best||(d==best&&ordinal<winner)){best=d;q=candidate;winner=ordinal;}
    }
    void search(Vec3 p,std::uint32_t index,double lower,double& best,Vec3& q,std::uint32_t& winner) const {
        if(lower>best)return; // Keep equality: the earlier eligible face can win.
        const auto& n=nodes[index];
        if(!n.left){for(auto i=n.begin;i<n.end;++i)test(p,order[i],best,q,winner);return;}
        auto a=n.left,b=n.right;auto da=lowerBound(p,a),db=lowerBound(p,b);
        if(da>db){std::swap(a,b);std::swap(da,db);}
        search(p,a,da,best,q,winner);search(p,b,db,best,q,winner);
    }
    std::pair<Vec3,std::uint32_t> project(Vec3 p) const {
        if(!finite(p))throw std::invalid_argument("Projected movement target is nonfinite; the previous result is retained.");
        if(work.queries==std::numeric_limits<std::uint64_t>::max())throw std::invalid_argument("Projected movement query counter overflow");
        ++work.queries;
        Vec3 q{};double best=INFINITY;std::uint32_t winner=std::numeric_limits<std::uint32_t>::max();
        if(nodes.empty())for(std::size_t i=0;i<eligible.size();++i)test(p,static_cast<std::uint32_t>(i),best,q,winner);
        else search(p,0,lowerBound(p,0),best,q,winner);
        return {q,eligible[winner]};
    }
};
ProjectedMovementIndex::ProjectedMovementIndex(const std::vector<Triangle>& m,const std::vector<std::uint32_t>& e,ProjectionWorkBudget& w)
    :impl_(std::make_unique<Impl>(m,e,w)){}
ProjectedMovementIndex::~ProjectedMovementIndex()=default;
std::pair<Vec3,std::uint32_t> ProjectedMovementIndex::project(Vec3 p) const{return impl_->project(p);}
}
