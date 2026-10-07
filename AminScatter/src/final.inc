// Final cleanup followed by count-preserving, constrained boundary smoothing.
std::vector<Instance> finalize(const std::vector<Triangle>& surface,const Settings& s,
 std::vector<Instance> points,const std::vector<Instance>& blockers,const std::vector<double>& radii,
 const std::vector<double>& blockerRadii,const FinalSettings& f,FinalWorkBudget* work) {
 if(!(f.radius>0)||!std::isfinite(f.radius)||f.strength<0||f.strength>1||f.maxMove<0||!std::isfinite(f.maxMove)||f.iterations>100) throw std::invalid_argument("Invalid final cleanup settings");
 if(radii.size()!=points.size()||blockerRadii.size()!=blockers.size())throw std::invalid_argument("Final radius count mismatch");
 const auto flat=[&](Vec3 p){if(f.planar)p.z=0;return p;};
 std::vector<double> own=radii;
 if(f.cleanup&&!points.empty()) {
  if(work)work->rowVisits.assign(points.size(),0);
  PointGrid grid(f.radius);for(std::size_t i=0;i<points.size();++i)grid.add(flat(points[i].position),i);
  std::vector<std::size_t> parent(points.size()),counts(points.size()),neighbors(points.size());std::iota(parent.begin(),parent.end(),0);
  auto root=[&](std::size_t i){while(parent[i]!=i){parent[i]=parent[parent[i]];i=parent[i];}return i;};
  for(std::size_t i=0;i<points.size();++i)grid.visit(flat(points[i].position),[&](std::size_t j){
   if(work){
    if(work->visits>=work->limit)throw std::invalid_argument("Procedural cleanup work limit exceeded; reduce population, cleanup radius or retry rounds");
    ++work->visits;++work->rowVisits[i];
   }
   if(j>i&&length(flat(points[i].position-points[j].position))<=f.radius){++neighbors[i];++neighbors[j];auto a=root(i),b=root(j);if(a!=b)parent[b]=a;}return true;
  });
  for(std::size_t i=0;i<points.size();++i)++counts[root(i)];
  std::vector<Instance> kept;std::vector<double> keptR;
  for(std::size_t i=0;i<points.size();++i)if(neighbors[i]>=f.minNeighbors&&counts[root(i)]>=f.minIsland){kept.push_back(points[i]);keptR.push_back(own[i]);}
  points=std::move(kept);own=std::move(keptR);
 }
 if(!f.relax||points.empty()||f.maxMove==0||f.strength==0)return points;
 SurfaceTree tree(surface);
 std::vector<AreaMask> masks;bool hasInclude=false;for(const auto& a:s.areas){masks.emplace_back(a);hasInclude|=a.include;}
 const auto bandAt=[&](Vec3 p){for(std::size_t j=0;j<s.lineBands.size();++j){const auto& b=s.lineBands[j];
  if(b.kind==5){for(const auto& path:b.boundary.loops)for(auto q:path)if(length(p-q)<1e-4)return int(j);}
  else if(b.kind==0?AreaMask(b.boundary).strokeBand(p,b.width,b.inside):analyzerBand(p,b))return int(j);
 }return -1;};
 std::vector<Vec3> origins,offsets;std::vector<int> originalBands;
 for(auto& p:points){auto [q,t]=tree.project(p.position,0);p.triangle=t;origins.push_back(p.position);offsets.push_back(p.position-q);originalBands.push_back(s.linePattern?bandAt(q):-1);}
 double maxOwn=0,maxOther=0;for(auto r:own)maxOwn=std::max(maxOwn,r);for(auto r:blockerRadii)maxOther=std::max(maxOther,r);
 const double reach=maxOwn+maxOther+f.gap;
 PointGrid obstacles(std::max(reach,1e-6));for(std::size_t j=0;j<blockers.size();++j)obstacles.add(flat(blockers[j].position),j);
 const auto valid=[&](std::size_t i,Vec3 q,std::uint32_t tri){
  bool include=!hasInclude;for(const auto& m:masks)if(m.contains(q)){if(!m.area.include)return false;include=true;}if(!include)return false;
  if(s.linePattern&&(originalBands[i]<0||s.lineBands[originalBands[i]].kind==5||bandAt(q)!=originalBands[i]))return false;
  if(s.distribution==2){const auto& t=surface[tri];auto ab=t.b-t.a,ac=t.c-t.a,ap=q-t.a;double aa=dot(ab,ab),bb=dot(ac,ac),cc=dot(ab,ac),d=aa*bb-cc*cc;
   if(d<=0)return false;double u=(bb*dot(ap,ab)-cc*dot(ap,ac))/d,v=(aa*dot(ap,ac)-cc*dot(ap,ab))/d;auto uv=t.uvA*(1-u-v)+t.uvB*u+t.uvC*v;
   auto x=std::uint32_t(std::clamp(uv.x,0.0,1.0)*(s.densityWidth-1)),y=std::uint32_t((1-std::clamp(uv.y,0.0,1.0))*(s.densityHeight-1));if(s.density[y*s.densityWidth+x]<=0)return false;
  }
  bool hit=false;if(reach>0)obstacles.visit(flat(q+offsets[i]),[&](std::size_t j){if(length(flat(q+offsets[i]-blockers[j].position))<own[i]+blockerRadii[j]+f.gap)hit=true;return !hit;});return !hit;
 };
 for(unsigned iteration=0;iteration<f.iterations;++iteration){
  PointGrid grid(f.radius+2*f.maxMove);for(std::size_t i=0;i<points.size();++i)grid.add(flat(points[i].position),i);
  PointGrid collisionGrid(std::max(1e-6,2*s.collisionRadius+2*f.maxMove));
  if(s.collisionEnabled)for(std::size_t i=0;i<points.size();++i)collisionGrid.add(points[i].position,i);
  double moved=0;
  // Sequential acceptance keeps the already accepted moves collision-safe.
  for(std::size_t i=0;i<points.size();++i){Vec3 mean{},direction{};std::size_t n=0;
   // Bound visits, including coincident and out-of-radius neighbours. Counting
   // only accepted neighbours leaves degenerate dense cells quadratic.
   std::size_t visited=0;
   grid.visit(flat(points[i].position),[&](std::size_t j){++visited;auto d=points[j].position-points[i].position;double len=length(flat(d));if(j!=i&&len>1e-9&&len<=f.radius){mean=mean+d;direction=direction+flat(d)*(1/len);++n;}return visited<128;});
   if(n<2||length(direction)*(1.0/n)<.2)continue; // interior points stay unchanged
   Vec3 delta=mean*(f.strength/n);double dl=length(delta);if(dl>f.maxMove)delta=delta*(f.maxMove/dl);
   auto [q,tri]=tree.project(points[i].position-offsets[i]+delta,points[i].triangle);
   if(length(q+offsets[i]-origins[i])>f.maxMove||!valid(i,q,tri))continue;
   // Check the path as well as the endpoint to avoid crossing exclusions/gaps.
   bool ok=true;auto start=points[i].position-offsets[i];
   for(int k=1;k<=8&&ok;++k){auto p=start+(q-start)*(k/8.0);auto [on,t]=tree.project(p,points[i].triangle);if(length(on-p)>1e-4||!valid(i,on,t))ok=false;}
   if(!ok)continue;
   if(s.collisionEnabled)collisionGrid.visit(q+offsets[i],[&](std::size_t j){if(i!=j&&length(q+offsets[i]-points[j].position)<s.collisionRadius*2)ok=false;return ok;});
   if(!ok)continue;moved=std::max(moved,length(q+offsets[i]-points[i].position));points[i].position=q+offsets[i];points[i].triangle=tri;
  }
  if(moved<1e-8)break;
 }
 return points;
}
