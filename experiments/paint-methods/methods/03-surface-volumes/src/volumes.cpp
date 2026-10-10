#include "../../../src/lab.h"
#include <algorithm>
#include <numeric>
namespace paintlab {
struct Box {V lo{1e300,1e300,1e300},hi{-1e300,-1e300,-1e300};void add(V p,double r=0){lo={std::min(lo.x,p.x-r),std::min(lo.y,p.y-r),std::min(lo.z,p.z-r)};hi={std::max(hi.x,p.x+r),std::max(hi.y,p.y+r),std::max(hi.z,p.z+r)};}bool contains(V p)const{return p.x>=lo.x&&p.x<=hi.x&&p.y>=lo.y&&p.y<=hi.y&&p.z>=lo.z&&p.z<=hi.z;}};
class Volumes final:public Kernel {
 struct Node {Box bounds;int left=-1,right=-1;std::vector<unsigned> leaves;};
 std::vector<Segment> segments;std::vector<Node> nodes;Settings settings;Hit last;bool connected=false;unsigned gesture=0;std::size_t indexed=0;mutable Stats counters;
 int build(std::vector<unsigned> indices){int index=int(nodes.size());nodes.emplace_back();Box box;for(auto i:indices){box.add(segments[i].a.p,segments[i].a.radius);box.add(segments[i].b.p,segments[i].b.radius);}nodes[index].bounds=box;if(indices.size()<=8){nodes[index].leaves=std::move(indices);return index;}V size=box.hi-box.lo;int axis=size.x>size.y?(size.x>size.z?0:2):(size.y>size.z?1:2);auto value=[&](unsigned i){V p=segments[i].a.p+segments[i].b.p;return axis==0?p.x:axis==1?p.y:p.z;};std::sort(indices.begin(),indices.end(),[&](auto a,auto b){return value(a)<value(b);});auto mid=indices.begin()+indices.size()/2;std::vector<unsigned> a(indices.begin(),mid),b(mid,indices.end());int left=build(std::move(a)),right=build(std::move(b));nodes[index].left=left;nodes[index].right=right;return index;}
 void index(){nodes.clear();if(!segments.empty()){std::vector<unsigned> order(segments.size());std::iota(order.begin(),order.end(),0);build(std::move(order));}indexed=segments.size();}
 void search(int i,V p,std::vector<unsigned>& out)const{if(i<0||!nodes[i].bounds.contains(p))return;for(auto j:nodes[i].leaves)out.push_back(j);search(nodes[i].left,p,out);search(nodes[i].right,p,out);}
public:
 Volumes(const Mesh&,double){}
 std::unique_ptr<Kernel> clone()const override{return std::make_unique<Volumes>(*this);}
 void begin(Settings s)override{settings=s;connected=false;++gesture;}
 void append(Hit h)override{if(segments.size()>=1000000)throw std::runtime_error("Segment capacity");segments.push_back({connected&&h.connected?last:h,h,settings,gesture});last=h;connected=true;++counters.edits;}
 void end()override{connected=false;index();}
 double query(Anchor,V p)const override{++counters.queries;std::vector<unsigned> candidates;if(!nodes.empty())search(0,p,candidates);for(std::size_t i=indexed;i<segments.size();++i)candidates.push_back(unsigned(i));std::sort(candidates.begin(),candidates.end());double result=0,maxInfluence=0;unsigned current=0;Settings previous;
  for(auto i:candidates){auto& s=segments[i];++counters.tests;if(s.gesture!=current){if(current)result=previous.erase?result*(1-maxInfluence):result+(1-result)*maxInfluence;current=s.gesture;maxInfluence=0;previous=s.settings;}maxInfluence=std::max(maxInfluence,influence(p,s));}if(current)result=previous.erase?result*(1-maxInfluence):result+(1-result)*maxInfluence;return result;}
 std::string save()const override{std::ostringstream o;o.precision(17);o<<gesture<<' '<<segments.size()<<'\n';for(auto& s:segments){o<<s.gesture<<' '<<s.settings.erase<<' '<<s.settings.strength<<' '<<s.settings.softness<<' ';for(auto h:{s.a,s.b})o<<h.anchor.face<<' '<<h.anchor.bary.x<<' '<<h.anchor.bary.y<<' '<<h.anchor.bary.z<<' '<<h.p.x<<' '<<h.p.y<<' '<<h.p.z<<' '<<h.radius<<' ';o<<'\n';}return o.str();}
 void load(const std::string& bytes)override{std::istringstream in(bytes);std::size_t n;if(!(in>>gesture>>n)||n>1000000)throw std::runtime_error("Invalid volume count");segments.clear();for(std::size_t i=0;i<n;++i){Segment s;if(!(in>>s.gesture>>s.settings.erase>>s.settings.strength>>s.settings.softness)||!std::isfinite(s.settings.strength)||s.settings.strength<0||s.settings.strength>1||!std::isfinite(s.settings.softness)||s.settings.softness<0||s.settings.softness>1)throw std::runtime_error("Invalid volume settings");for(auto h:{&s.a,&s.b})if(!(in>>h->anchor.face>>h->anchor.bary.x>>h->anchor.bary.y>>h->anchor.bary.z>>h->p.x>>h->p.y>>h->p.z>>h->radius)||!std::isfinite(h->p.x)||!std::isfinite(h->p.y)||!std::isfinite(h->p.z)||!std::isfinite(h->radius)||h->radius<=0)throw std::runtime_error("Invalid volume");segments.push_back(s);}index();}
 Stats stats()const override{auto s=counters;s.items=segments.size();s.bytes=segments.capacity()*sizeof(Segment)+nodes.capacity()*sizeof(Node);for(auto& n:nodes)s.bytes+=n.leaves.capacity()*sizeof(unsigned);return s;}
};
std::unique_ptr<Kernel> makeVolumes(const Mesh& m,double r){return std::make_unique<Volumes>(m,r);}
}
