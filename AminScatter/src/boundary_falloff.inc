// Boundary distance falloff; immutable rows, deterministic thinning, no refill.
namespace {
struct FallSegment { Vec3 a,b; };
struct FallTree {
 struct Node { Vec3 lo,hi;int left=-1,right=-1;std::size_t begin=0,end=0; };
 std::vector<FallSegment> edges;std::vector<Node> nodes;
 static double coord(Vec3 p,int i){return i==0?p.x:i==1?p.y:p.z;}
 int build(std::size_t begin,std::size_t end){
  Node n;n.begin=begin;n.end=end;n.lo={INFINITY,INFINITY,INFINITY};n.hi={-INFINITY,-INFINITY,-INFINITY};
  for(auto i=begin;i<end;++i)for(auto p:{edges[i].a,edges[i].b}){n.lo={std::min(n.lo.x,p.x),std::min(n.lo.y,p.y),std::min(n.lo.z,p.z)};n.hi={std::max(n.hi.x,p.x),std::max(n.hi.y,p.y),std::max(n.hi.z,p.z)};}
  int idx=static_cast<int>(nodes.size());nodes.push_back(n);
  if(end-begin>8){auto d=n.hi-n.lo;int axis=d.x>d.y?(d.x>d.z?0:2):(d.y>d.z?1:2);auto mid=(begin+end)/2;
   std::nth_element(edges.begin()+begin,edges.begin()+mid,edges.begin()+end,[axis](const auto& a,const auto& b){return coord(a.a+a.b,axis)<coord(b.a+b.b,axis);});
   int left=build(begin,mid),right=build(mid,end);nodes[idx].left=left;nodes[idx].right=right;
  }return idx;
 }
 double box(Vec3 p,const Node& n)const {double r=0;for(int a=0;a<3;++a){double d=std::max({coord(n.lo,a)-coord(p,a),0.0,coord(p,a)-coord(n.hi,a)});r+=d*d;}return std::sqrt(r);}
 void nearest(int i,Vec3 p,double& best)const {const auto& n=nodes[i];if(box(p,n)>best)return;if(n.left<0){for(auto j=n.begin;j<n.end;++j)best=std::min(best,segmentDistance(p,edges[j].a,edges[j].b));}else{int a=n.left,b=n.right;if(box(p,nodes[a])>box(p,nodes[b]))std::swap(a,b);nearest(a,p,best);nearest(b,p,best);}}
};
double fallCurve(const std::vector<double>& values,double t){double v=std::clamp(t,0.0,1.0)*(values.size()-1);auto i=std::min(values.size()-2,static_cast<std::size_t>(v));return values[i]+(values[i+1]-values[i])*(v-i);}
}
std::vector<Instance> boundaryFalloff(const std::vector<Instance>& rows,const std::vector<std::vector<Vec3>>& loops,const BoundaryFalloff& f,std::uint32_t seed){
 if(!f.remove&&!f.scale&&!f.density)return rows;
 for(double v:{f.removeWidth,f.scaleWidth,f.densityWidth})if(!std::isfinite(v)||v<0)throw std::invalid_argument("Invalid falloff width");
 for(const auto* curve:{&f.scaleCurve,&f.densityCurve}){if(curve->size()<2||curve->size()>257)throw std::invalid_argument("Invalid falloff curve");for(double v:*curve)if(!std::isfinite(v)||v<0)throw std::invalid_argument("Invalid curve value");}
 FallTree tree;for(const auto& path:loops)if(path.size()>2)for(std::size_t i=0;i<path.size();++i){if(!finite(path[i]))throw std::invalid_argument("Invalid boundary vertex");if(length(path[(i+1)%path.size()]-path[i])>1e-10)tree.edges.push_back({path[i],path[(i+1)%path.size()]});}
 if(tree.edges.empty())throw std::invalid_argument("Analyzer has no boundary data; run Analyze first");
 if(f.areaSide)for(auto& e:tree.edges){e.a.z=0;e.b.z=0;}
 tree.build(0,tree.edges.size());
 std::vector<Instance> out;out.reserve(rows.size());
 for(std::size_t i=0;i<rows.size();++i){auto row=rows[i];auto query=row.position;if(f.areaSide)query.z=0;
  double distance=INFINITY;tree.nearest(0,query,distance);
  if(f.areaSide&&distance>1e-8){bool inside=false;for(const auto& path:loops)for(std::size_t a=0,b=path.size()-1;a<path.size();b=a++) {auto p=path[a],q=path[b];if((p.y>query.y)!=(q.y>query.y)&&query.x<(q.x-p.x)*(query.y-p.y)/(q.y-p.y)+p.x)inside=!inside;}
   if(inside!=(f.areaSide==1)){out.push_back(row);continue;}}
  double start=f.remove?f.removeWidth:0;if(f.remove&&distance<start)continue;double d=std::max(0.0,distance-start);
  if(f.density){double rate=std::clamp(fallCurve(f.densityCurve,f.densityWidth>0?d/f.densityWidth:1),0.0,1.0);double random=static_cast<double>(mix(seed^mix(static_cast<std::uint32_t>(i))))/4294967296.0;if(random>=rate)continue;}
  if(f.scale){double factor=fallCurve(f.scaleCurve,f.scaleWidth>0?d/f.scaleWidth:1);row.xAxis=row.xAxis*factor;row.yAxis=row.yAxis*factor;row.zAxis=row.zAxis*factor;}
  out.push_back(row);
 }return out;
}
