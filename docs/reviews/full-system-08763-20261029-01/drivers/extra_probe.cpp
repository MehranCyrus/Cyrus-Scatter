#include "repair_probe.cpp"
#include <random>
#include <fstream>

void overlayProperties(){
 namespace p=cyrus::placements;
 const auto owner=p::newOwner();auto sources=p::SourceCohort::create(owner,"review",{{"model",42,p::RenderSource}});
 p::Builder b(owner,p::Stage::Edited,1,100,sources);p::Record r;r.transform={1,0,0,0,1,0,0,0,1,0,0,0};
 for(unsigned i=0;i<100;++i){r.identity=i;r.transform[9]=float(i);b.appendGenerated(r);}auto base=b.freeze().prepared("key","binding");auto current=base;
 std::vector<float> expected(100);std::iota(expected.begin(),expected.end(),0.f);std::mt19937 gen(913);
 for(unsigned step=0;step<500;++step){unsigned row=gen()%100;auto tm=current.at(row).transform;tm[9]=float(int(gen()%200)-100);expected[row]=tm[9];current=current.withTransforms({{row,tm}});
  for(unsigned i=0;i<100;++i){require(current.at(i).transform[9]==expected[i],"Overlay cumulative value");require(base.at(i).transform[9]==float(i),"Overlay mutated predecessor");}
  if(step%17==0){auto selected=current.select({99,7,0,50}).select({2,0});require(selected.at(0).identity==0&&selected.at(1).identity==99,"Overlay selection identity");require(selected.compact().at(1).transform==current.at(99).transform,"Overlay compaction changed pose");auto edit=selected.at(1).transform;edit[9]=987;auto changed=selected.withTransforms({{1,edit}});require(changed.at(1).identity==99&&changed.at(1).transform[9]==987&&current.at(99).transform[9]==expected[99],"Selected logical patch correspondence");}
 }
 require(!current.preparation(),"Changed overlay retained preparation receipt");
 auto unchanged=current.withTransforms({{0,current.at(0).transform}});require(unchanged.token()==current.token(),"No-op overlay changed token");
 bool rejected=false;try{current.withTransforms({{100,r.transform}});}catch(...){rejected=true;}require(rejected,"Out of bounds patch accepted");
 rejected=false;try{current.withTransforms({{0,r.transform},{0,r.transform}});}catch(...){rejected=true;}require(rejected,"Duplicate patch accepted");
 std::cout<<"OVERLAY 500 cumulative edits, selection/compaction/receipt/no-op/invalid pass\n";
}
std::shared_ptr<Layout> population(unsigned n,int response=2,bool neighbors=false){
 auto d=std::make_shared<Definition>();d->rig=prepareSource(bladeSource());d->geometryBounds=d->rig->bounds;
 auto l=std::make_shared<Layout>();l->metresPerUnit=1.;l->layers.resize(1);auto& cfg=l->layers[0];cfg.react=true;cfg.response=response;cfg.neighbors=neighbors;cfg.coverRoots=false;l->sources={{d}};
 for(unsigned i=0;i<n;++i){Instance x;x.identity="row:"+std::to_string(i);x.hostTransform={1,0,0,0,1,0,0,0,1,float(i)*.2f,0,0};l->instances.push_back(x);}
 Transform t;t.rows[3]={-.03,.04,0};l->sceneObstacles={{"scene",cube(.012),t}};return l;
}
void sameResult(const std::shared_ptr<const Snapshot>& a,const std::shared_ptr<const Snapshot>& b){
 require(a->poses.size()==b->poses.size(),"Incremental pose membership differs from full evaluation");
 for(auto& [id,pose]:a->poses){auto found=b->poses.find(id);require(found!=b->poses.end(),"Incremental stale pose");auto src=a->layout->sources[0][0]->rig;auto packed=deformationSource(src);require(deformationPose(*packed,*pose)==deformationPose(*packed,*found->second),"Incremental pose differs from full evaluation");}
 require(a->statistics.hiddenRoots==b->statistics.hiddenRoots,"Incremental root count differs");
}
void incrementalMatrix(){
 unsigned checks=0;std::mt19937 rng(718);
 for(int response:{1,2,3})for(bool neighbors:{false,true})for(bool under:{false,true}){
  auto l=population(80,response,neighbors);l->layers[0].coverRoots=true;l->layers[0].hideUnder=under;l->layers[0].hideMargin=.003;
  Engine e(l);auto state=e.evaluate({});std::map<std::size_t,Transform> overrides;std::set<std::size_t> disabled;
  for(unsigned step=0;step<24;++step){unsigned row=rng()%80;auto tm=l->transform(row);tm.rows[3].x+=.02*(int(step%3)-1);overrides[row]=tm;
   if(step%2)disabled.erase(row);else disabled.insert(row);auto scene=l->sceneObstacles[0].transform;scene.rows[3].x=float(rng()%80)*.2-.03;if(under&&step%2)scene.rows[3].y=1.;
   auto next=e.evaluate(state,overrides,{row},disabled,{scene});auto rebuilt=e.evaluate({},overrides,{},disabled,{scene});sameResult(next,rebuilt);state=next;++checks;
  }
 }
 std::cout<<"INCREMENTAL checks="<<checks<<" moved/disabled/neighbor/hiding full-equivalence pass\n";
}
void benchmark(){
 std::ofstream csv("benchmark.csv");csv<<"case,rows,threads,iteration,total_ms,query_ms,fit_ms,affected,queries,participants,allocations,allocated_bytes\n";
 std::map<unsigned,std::shared_ptr<const Snapshot>> crossThread;
 for(unsigned n:{128u,512u})for(unsigned threads:{1u,2u,4u,8u}){
  auto l=population(n);for(auto& x:l->instances)x.hostTransform[9]=0;Engine e(l);amin::setComputeThreads(threads);
  std::shared_ptr<const Snapshot> reference;
  for(unsigned k=0;k<10;++k){allocationCalls=0;allocationBytes=0;countAllocations=k==9;auto s=e.evaluate({});countAllocations=false;
   if(!reference)reference=s;else sameResult(reference,s);
   if(!crossThread.contains(n))crossThread[n]=s;else sameResult(crossThread[n],s);
   if(k)csv<<"parallel,"<<n<<','<<threads<<','<<k<<','<<s->statistics.totalMs<<','<<s->statistics.queryMs<<','<<s->statistics.fitMs<<','<<s->statistics.affected<<','<<s->statistics.queries<<','<<s->statistics.participants<<','<<(k==9?allocationCalls.load():0)<<','<<(k==9?allocationBytes.load():0)<<'\n';
  }
 }
 amin::setComputeThreads(1);
 for(unsigned n:{1000u,10000u,100000u}){
  auto l=population(n);l->layers[0].coverRoots=true;l->layers[0].hideUnder=true;Engine e(l);auto previous=e.evaluate({});
  for(unsigned k=0;k<10;++k){auto t=l->sceneObstacles[0].transform;t.rows[3].x+=k%2?.001:0.;auto s=e.evaluate(previous,{}, {}, {}, {t});
   if(k)csv<<"local-distant,"<<n<<",1,"<<k<<','<<s->statistics.totalMs<<','<<s->statistics.queryMs<<','<<s->statistics.fitMs<<','<<s->statistics.affected<<','<<s->statistics.queries<<','<<s->statistics.participants<<",0,0\n";previous=s;
  }
 }
 for(unsigned n:{128u,1024u,8192u}){
  auto l=population(n);l->sceneObstacles.clear();l->layers.resize(2);l->layers[1].obstacle=true;
  auto d=std::make_shared<Definition>();d->collider=cube(.012);d->geometryBounds=d->collider->bounds();l->sources.push_back({d});
  for(unsigned i=0;i<n;++i){Instance x;x.identity="stone:"+std::to_string(i);x.layer=1;x.hostTransform={1,0,0,0,1,0,0,0,1,float(i)*.2f-.03f,0,.04f};l->instances.push_back(x);}
  Engine e(l);auto previous=e.evaluate({});require(previous->poses.size()==n,"Persistent pose fixture must bend every plant");
  for(unsigned k=0;k<10;++k){auto t=l->transform(n);t.rows[3].x+=k%2?.001:0.;allocationCalls=0;allocationBytes=0;countAllocations=k==9;
   auto s=e.evaluate(previous,{{n,t}},{n});countAllocations=false;require(s->statistics.affected==1,"Local edit expanded unexpectedly");
   if(k)csv<<"local-posed,"<<n<<",1,"<<k<<','<<s->statistics.totalMs<<','<<s->statistics.queryMs<<','<<s->statistics.fitMs<<','<<s->statistics.affected<<','<<s->statistics.queries<<','<<s->statistics.participants<<','<<(k==9?allocationCalls.load():0)<<','<<(k==9?allocationBytes.load():0)<<'\n';previous=s;
  }
 }
 amin::setComputeThreads(0);std::cout<<"BENCHMARK raw benchmark.csv written; cross-thread pose equivalence passed; counted allocations only iteration 9\n";
}
int main(int argc,char** argv){try{if(argc>1&&std::string(argv[1])=="--benchmark"){benchmark();return 0;}reviewRegressions();hiding();roles(false);roles(true);settingsMatrix();fixedDecoration();placementCopy();neighborBatchWork();overlayProperties();incrementalMatrix();return 0;}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
