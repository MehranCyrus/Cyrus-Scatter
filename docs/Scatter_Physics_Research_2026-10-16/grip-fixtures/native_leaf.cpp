// Extended geometry witness linked against the qualified delivery's unchanged core.
#define main cpl_matrix_main
#include "../../../CyrusPhysicsLab/tests/grip_tests.cpp"
#undef main
int main(int argc,char** argv){Json report=Json::array();try{
 Mesh leaf;leaf.vertices={{-.05,0,0},{-.035,-.07,.001},{0,-.1,0},{.035,-.07,.001},{.05,0,0},{.025,.07,-.001},{0,.1,0},{-.025,.07,-.001},{0,0,.003}};
 for(unsigned i=0;i<8;++i)leaf.faces.push_back({8,i,(i+1)%8});
 for(auto kind:{"hills","ridge","valley","rough","terraces","hole"})for(double grip:{.25,.8,1.}){
  auto mesh=terrain(kind);auto in=input(mesh,.6,grip);in.sources={proxySource(leaf,leaf,.002,true)};in.settings.scaleMin=.7;in.settings.scaleMax=1.15;
  Surface surface(mesh);ContinuousCore core(in,mesh);unsigned expected=0;
  for(unsigned i=0;i<12;++i){Hit h;if(!surface.hit({-1.4+(i%4)*.85,-1.+(i/4)*.9,20},{0,0,-1},h))continue;++expected;core.beginGesture();core.sample(h.point,h.normal,true);core.endGesture();core.advance(20);}
  for(unsigned i=0;i<5;++i)core.advance(120);
  auto state=core.view();double penetration=0,largestGap=0;
  for(auto& b:state.bodies){double nearest=1e100;for(auto p:leaf.vertices){auto v=rotate(b.row.rotation,p*b.row.scale)+b.row.position;Hit h;if(surface.hit({v.x,v.y,100},{0,0,-1},h)){penetration=std::max(penetration,h.point.z-v.z);nearest=std::min(nearest,v.z-h.point.z);}}largestGap=std::max(largestGap,nearest);}
  auto archive=core.archive();ContinuousCore restored(in,mesh);restored.recover(archive);same(state.bodies,restored.view().bodies);
  core.undoGesture();core.redoGesture();same(state.bodies,core.view().bodies);core.freeze();check(core.isDone(),"Leaf Freeze failed");
  report.push_back({{"terrain",kind},{"grip",grip},{"bodies",state.bodies.size()},{"lost",state.lost},{"penetration_vertical_m",penetration},{"largest_nearest_vertex_gap_m",largestGap}});
  check(penetration<.001,"Curved leaf penetrated terrain beyond 1 mm");check(state.lost==0&&state.bodies.size()==expected,"Supported leaf was lost");check(largestGap<.02,"Curved leaf did not reach its support");
 }
 std::ofstream(argv[1])<<Json({{"pass",true},{"checks",checks},{"cases",report}}).dump(2);std::cout<<"PASS "<<checks<<" curved-leaf terrain checks\n";return 0;
 }catch(const std::exception& e){if(argc>1)std::ofstream(argv[1])<<Json({{"pass",false},{"error",e.what()},{"checks",checks},{"cases",report}}).dump(2);std::cerr<<e.what()<<'\n';return 1;}}
