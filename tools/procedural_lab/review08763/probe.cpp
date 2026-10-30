#define main originalInteractionsMain
#include "F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/tests/interactions_tests.cpp"
#undef main
#include "placement_store.h"
#include <cstdlib>
#include <new>
static std::atomic_bool countAllocations{false};
static std::atomic<std::size_t> allocationCalls{0},allocationBytes{0};
void* operator new(std::size_t n){if(auto* p=std::malloc(n?n:1)){if(countAllocations){++allocationCalls;allocationBytes+=n;}return p;}throw std::bad_alloc();}
void operator delete(void* p) noexcept {std::free(p);}
void operator delete(void* p,std::size_t) noexcept {std::free(p);}
void* operator new[](std::size_t n){return ::operator new(n);}
void operator delete[](void* p) noexcept {::operator delete(p);}
void operator delete[](void* p,std::size_t) noexcept {::operator delete(p);}

std::shared_ptr<Layout> onePlant(std::shared_ptr<const Source> source,int response,Shape obstacle,double margin,bool under){
 auto d=std::make_shared<Definition>();d->rig=source;d->geometryBounds=source->bounds;
 auto l=std::make_shared<Layout>();l->layers.resize(1);auto& c=l->layers[0];c.react=true;c.response=response;c.strength=0;c.pruneAmount=0;c.coverRoots=true;c.hideMargin=margin;c.hideUnder=under;c.gap=0;
 l->sources={{d}};Instance p;p.identity="plant";p.hostTransform={1,0,0,0,1,0,0,0,1,0,0,0};l->instances={p};l->sceneObstacles={{"obstacle",obstacle.geometry,obstacle.transform}};return l;
}
void hiding(){
 auto s=prepareSource(bladeSource());
 for(int scenario=0;scenario<2;++scenario){Shape o{1,cube(.005),{}};o.transform.rows[3]=scenario?Vec{.25,0,0}:Vec{-.03,1,0};double margin=scenario?.3:0;bool under=scenario==0;
  for(int response=0;response<4;++response){auto l=onePlant(s,response,o,margin,under);Engine e(l);auto state=e.evaluate({});auto direct=response?adaptSource(*s,{o},0,0,response,0,0,1,0,0,.25,true,margin,under):fitSource(*s,{o},0,.5,true,1,{0,1,0},margin,under);
   std::cout<<"HIDING "<<(under?"under-overhead":"inside-margin")<<" response="<<response<<" direct_hidden="<<direct.coveredRoots<<" engine_hidden="<<state->statistics.hiddenRoots<<" affected="<<state->statistics.affected<<'\n';
   require(direct.coveredRoots>0,"Hiding fixture must cover at least one root");
  }
 }
}
void roles(bool colliderOnly){
 auto a=std::make_shared<Definition>();a->rig=prepareSource(bladeSource());a->geometryBounds=a->rig->bounds;
 auto raw=bladeSource();for(auto& p:raw.positions)p[0]*=1.1f;auto b=std::make_shared<Definition>();b->rig=prepareSource(raw);b->geometryBounds=b->rig->bounds;
 auto make=[&](bool active,bool neighbor){auto l=std::make_shared<Layout>();l->layers.resize(2);l->layers[0].react=active;l->layers[0].neighbors=neighbor;l->layers[0].response=2;l->layers[1].react=true;l->layers[1].neighbors=true;l->layers[1].response=2;l->sources={{a},{b}};
  Instance x;x.layer=0;x.identity="edited-a";x.hostTransform={1,0,0,0,1,0,0,0,1,1000,0,0};Instance y=x;y.layer=1;y.identity="peer-b";y.hostTransform[9]=0;l->instances={x,y};return l;};
 auto on=make(true,true);auto moved=on->transform(0);moved.rows[3]={0,0,0};Engine live(on);auto before=live.evaluate({},{{0,moved}});std::cout<<"ROLE both reacting control poses="<<before->poses.size()<<'\n';
 if(colliderOnly){auto l=make(false,true);auto d=std::make_shared<Definition>();d->collider=cube(.01);d->geometryBounds=d->collider->bounds();l->sources[0][0]=d;l->layers[0].obstacle=true;std::cout<<"ROLE collider-only retained neighbors entering evaluate"<<std::endl;Engine e(l);e.evaluate({},{{0,moved}});return;}
 try{Engine off(make(false,true));off.evaluate({},{{0,moved}});std::cout<<"ROLE off retained neighbors succeeded\n";}catch(const std::exception& e){std::cout<<"ROLE off retained neighbors error="<<e.what()<<'\n';}
 Engine off(make(false,false));std::cout<<"ROLE off cleared neighbors control poses="<<off.evaluate({},{{0,moved}})->poses.size()<<'\n';
}
void settingsMatrix(){
 auto s=prepareSource(bladeSource());auto packed=deformationSource(s);Shape o{1,cube(.012),{}};o.transform.rows[3]={-.03,.04,0};std::size_t cases=0,faces=0;double error=0;
 for(int response:{1,2,3})for(double strength:{0.,.5,1.})for(double trim:{0.,.5,1.})for(double fixed:{0.,.5,1.})for(double trunk:{0.,1.})for(bool cover:{false,true})for(bool under:{false,true}){
  auto p=adaptSource(*s,{o},.001,strength,response,trim,.001,913,trunk,fixed,.25,cover,.002,under);auto words=deformationPose(*packed,p);
  auto repeat=adaptSource(*s,{o},.001,strength,response,trim,.001,913,trunk,fixed,.25,cover,.002,under);require(deformationPose(*packed,repeat)==words,"Repeat settings produce different compact poses");
  for(unsigned f=0;f<packed->faces.size();++f){require(visibleFace(*s,p,packed->faces[f])==deformationVisible(*packed,words,f),"CPU/GPU visibility diverged");++faces;if(!deformationVisible(*packed,words,f))continue;
   for(unsigned k=0;k<3;++k){auto a=posePoint(*s,p,s->rig->triangles[packed->faces[f]][k]),b=deformationPoint(*packed,words,f,k);error=std::max(error,length(sub(a,b)));}}
  require(!adaptSource(*s,{},.001,strength,response,trim,.001,913,trunk,fixed,.25,cover,.002,under).changed,"Move-away did not restore rest");++cases;
 }
 require(error<2e-6,"CPU and compact posed points disagree");std::cout<<"MATRIX cases="<<cases<<" faces="<<faces<<" max_cpu_compact_error_m="<<error<<" deterministic/restoration=pass\n";
}
void previewAdmission(){
 prep::Snapshot raw;const auto blade=bladeSource();for(unsigned n=0;n<80;++n){auto offset=unsigned(raw.positions.size());for(auto p:blade.positions){p[0]+=n*.2f;raw.positions.push_back(p);}for(auto t:blade.faces){for(auto& v:t)v+=offset;raw.faces.push_back(t);raw.materials.push_back(0);}}
 auto s=prepareSource(raw);auto data=deformationSource(s);const auto posed=(std::size_t(1)<<24)/data->rest.size()+1,shown=std::size_t(1);
 const auto currentWords=(posed+1)*data->rest.size(),neededWords=(shown+1)*data->rest.size();
 std::cout<<"PREVIEW admission arithmetic real_prepared_guides="<<s->rig->guides.size()<<" rest_words="<<data->rest.size()<<" posed="<<posed<<" sampled_visible="<<shown<<" current_words="<<currentWords<<" needed_words="<<neededWords<<" current_bytes="<<currentWords*sizeof(DeformationWord)<<" needed_bytes="<<neededWords*sizeof(DeformationWord)<<" rejects_before_sampling="<<(currentWords>=(1u<<24))<<'\n';
}
void mapCopies(){
 for(unsigned n:{256u,1024u}){std::map<std::size_t,Transform> before,after;for(unsigned i=0;i<n;++i){before[i]={};after[i]={};}allocationCalls=0;allocationBytes=0;volatile double sink=0;auto start=std::chrono::steady_clock::now();countAllocations=true;
  for(unsigned changed=0;changed<n;++changed)for(const auto& map:{before,after})sink=sink+map.begin()->second.rows[0].x;
  countAllocations=false;auto elapsed=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count();
  std::cout<<"MAP copied initializer n="<<n<<" allocations="<<allocationCalls<<" allocated_bytes="<<allocationBytes<<" elapsed_ms="<<elapsed<<" sink="<<sink<<'\n';
  allocationCalls=0;allocationBytes=0;start=std::chrono::steady_clock::now();countAllocations=true;
  for(unsigned changed=0;changed<n;++changed)for(const auto* map:{&before,&after})sink=sink+map->begin()->second.rows[0].x;
  countAllocations=false;std::cout<<"MAP borrowed control n="<<n<<" allocations="<<allocationCalls<<" allocated_bytes="<<allocationBytes<<" elapsed_ms="<<std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count()<<'\n';
 }
}
void placementCopy(){
 namespace p=cyrus::placements;
 for(unsigned n:{100000u,1000000u}){p::Builder build(p::newOwner(),p::Stage::Edited,1,n);p::Record row;row.transform={1,0,0,0,1,0,0,0,1,0,0,0};for(unsigned i=0;i<n;++i){row.identity=i;build.appendGenerated(row);}auto view=build.freeze();auto before=p::metrics();auto start=std::chrono::steady_clock::now();
  auto changed=view.at(0);changed.transform[9]=1;auto result=view.withTransforms({{0,changed.transform}});auto after=p::metrics();
  std::cout<<"PLACEMENT one-record change rows="<<n<<" newly_allocated_row_bytes="<<after.totalBytes-before.totalBytes<<" copy_ms="<<std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count()<<" original_x="<<view.at(0).transform[9]<<" successor_x="<<result.at(0).transform[9]<<'\n';
 }
}
void neighborBatchWork(){
 auto source=prepareSource(bladeSource());auto def=std::make_shared<Definition>();def->rig=source;def->geometryBounds=source->bounds;
 for(unsigned n:{64u,256u,1024u}){auto layout=std::make_shared<Layout>();layout->layers.resize(1);auto& cfg=layout->layers[0];cfg.react=true;cfg.neighbors=true;cfg.response=2;cfg.coverRoots=false;layout->sources={{def}};
  for(unsigned i=0;i<n;++i){Instance p;p.identity="plant:"+std::to_string(i);p.hostTransform={1,0,0,0,1,0,0,0,1,float(i)*100,0,0};layout->instances.push_back(p);}
  Engine engine(layout);std::map<std::size_t,Transform> old,next;std::vector<std::size_t> changed;for(unsigned i=0;i<n;++i){auto tm=layout->transform(i);tm.rows[3].x+=.002;old[i]=tm;tm.rows[3].x+=.002;next[i]=tm;changed.push_back(i);}
  auto before=engine.evaluate({},old);allocationCalls=0;allocationBytes=0;countAllocations=true;auto result=engine.evaluate(before,next,changed);countAllocations=false;
  std::cout<<"NEIGHBOR batch actual_engine n="<<n<<" allocations="<<allocationCalls<<" allocated_bytes="<<allocationBytes<<" affected="<<result->statistics.affected<<" contact_queries="<<result->statistics.queries<<" query_ms="<<result->statistics.queryMs<<" fit_ms="<<result->statistics.fitMs<<" total_ms="<<result->statistics.totalMs<<'\n';
 }
}
void fixedDecoration(){
 prep::Snapshot raw;
 for(unsigned leaf=0;leaf<8;++leaf){const double angle=leaf*6.283185307179586/8;unsigned offset=unsigned(raw.positions.size());
  for(unsigned row=0;row<18;++row)for(unsigned side=0;side<2;++side){double t=row/17.,radius=.02+.48*t,w=(side?1:-1)*(.004+.016*std::sin(t*3.141592653589793));raw.positions.push_back({float(radius*std::cos(angle)-w*std::sin(angle)),float(radius*std::sin(angle)+w*std::cos(angle)),float(.15+.22*std::sin(t*3.141592653589793)-(leaf%2?.11:0)*t)});}
  for(unsigned row=1;row<18;++row){unsigned a=offset+(row-1)*2,b=a+2;raw.faces.push_back({a,a+1,b});raw.faces.push_back({a+1,b+1,b});}}
 const unsigned offset=unsigned(raw.positions.size());for(unsigned k=0;k<8;++k)raw.positions.push_back({float(k&1?.035:-.035),float(k&2?.035:-.035),float(k&4?.09:0)});
 for(auto f:std::vector<Tri>{{0,2,1},{1,2,3},{4,5,6},{5,7,6},{0,1,4},{1,5,4},{2,6,3},{3,6,7},{0,4,2},{2,4,6},{1,3,5},{3,7,5}}){for(auto& v:f)v+=offset;raw.faces.push_back(f);}
 raw.materials.assign(raw.faces.size(),0);auto source=prepareSource(raw,{.005,1.});Shape obstacle{1,cube(.035),{}};obstacle.transform.rows[3]={0,.15,0};auto pose=fitSource(*source,{obstacle},0,.5,true,1);
 unsigned bad=0;for(auto vertex:source->fixedVertices){const auto& part=source->rig->parts[source->labels[vertex]];if(!visibleVertex(*source,pose,vertex))++bad;}
 unsigned visible=0;for(auto face:source->fixedFaces)visible+=visibleFace(*source,pose,face);
 std::cout<<"FIXED decoration covered_roots="<<pose.coveredRoots<<" fixed_vertices="<<source->fixedVertices.size()<<" wrongly_skipped_point_samples="<<bad<<" visible_fixed_triangles="<<visible<<'\n';
 for(unsigned i=offset;i<raw.positions.size();++i)raw.positions[i][0]+=5;
 auto far=prepareSource(raw,{.005,1.});auto farPose=fitSource(*far,{obstacle},0,.5,true,1);unsigned outside=0;
 for(auto v:far->fixedVertices){const auto p=posePoint(*far,farPose,v);const auto bound=poseEnvelope(*far);outside+=p.x<bound.lo.x||p.x>bound.hi.x||p.y<bound.lo.y||p.y>bound.hi.y||p.z<bound.lo.z||p.z>bound.hi.z;}
 std::cout<<"RENDER bounds source_reach_m="<<far->reach<<" actual_fixed_hi_x_m="<<far->fixedBounds.hi.x<<" fixed_vertices_outside_render_packet_bound="<<outside<<" all_hidden="<<farPose.allHidden<<'\n';
}
int main(int argc,char**){try{if(argc>1){roles(true);return 0;}reviewRegressions();hiding();roles(false);settingsMatrix();fixedDecoration();previewAdmission();mapCopies();placementCopy();neighborBatchWork();return 0;}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
