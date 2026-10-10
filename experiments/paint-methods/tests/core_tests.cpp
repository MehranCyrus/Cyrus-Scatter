#include "fixtures.h"
#include <iostream>
#include <random>
#include "picker.h"
using namespace paintlab;
int checks=0;
void require(bool b,const char* m){++checks;if(!b)throw std::runtime_error(m);}
int main(){try{for(int method=1;method<=4;++method){Session s(method,plane(),2);stroke(s,0,0,100);for(int y=-130;y<=130;y+=7)for(int x=-130;x<=130;x+=7){double d=length({double(x),double(y),0});if(std::abs(d-100)>5)require((s.view().query(anchor(x,y),{double(x),double(y),0})>.5)==(d<100),"Disk oracle outside error band");}
 auto saved=s.save();stroke(s,0,0,35,true);require(s.view().query(anchor(0,0),{})==0,"Erase hole");s.undo();require(s.save()==saved,"Undo exact state");s.redo();require(s.view().query(anchor(0,0),{})==0,"Redo hole");s.begin({});s.append(hit(250,250,20));s.cancel();require(s.view().query(anchor(250,250),{250,250,0})==0,"Cancel preserves state");s.load(saved);require(s.save()==saved,"Save/load exact state");
 s.begin({});s.append(hit(-300,-200,25));s.append(hit(300,-200,25,true));s.commit();for(int x=-300;x<300;x+=11)require(s.view().query(anchor(x,-200),{double(x),-200,0})>.5,"Swept coverage continuity");
 s.begin({});s.append(hit(-300,300,20));s.append(hit(300,300,20,false));s.commit();require(s.view().query(anchor(0,300),{0,300,0})==0,"Miss does not bridge");
 // Disjoint growing regions must never erase a prior region.
 for(int i=0;i<24;++i){double x=-400+(i%6)*150,y=-400+(i/6)*230;stroke(s,x,y,20);for(int j=0;j<=i;++j){double a=-400+(j%6)*150,b=-400+(j/6)*230;require(s.view().query(anchor(a,b),{a,b,0})>.5,"Growing area loses prior region");}}
 auto p=preview(s,true,true,30);require(!p.lines.empty()&&!p.points.empty(),"Resolved boundary and sample preview");auto stable=s.save();bool refused=false;try{preview(s,true,true,.001);}catch(...){refused=true;}require(refused&&s.save()==stable,"Display budget preserves state");
 bool failed=false;s.begin({});try{s.append(hit(0,0,-1));}catch(...){failed=true;s.cancel();}require(failed&&s.save()==stable,"Invalid hit preserves state");
 if(method!=1){Session t(method,plane(),2);stroke(t,50,0,80,false,.5,.5);double first=t.view().query(anchor(50,0),{50,0,0});require(first>.45&&first<.51,"Soft paint strength");stroke(t,50,0,80,false,.5,.5);require(t.view().query(anchor(50,0),{50,0,0})>.7,"Separate gestures accumulate");}
 std::cout<<"method "<<method<<" PASS\n";
 // Reversed diagonal/face frame: reproduce the seam failure seen in Max.
 auto other=plane();other.faces={{1,2,3},{1,3,0}};Session seam(method,other,2);seam.begin({});seam.append({{0,{.5,0,.5}},{0,0,0},100,false});seam.commit();for(unsigned f=0;f<2;++f){Anchor center=f==0?Anchor{0,{.5,0,.5}}:Anchor{1,{.5,.5,0}};require(seam.view().query(center,{})>.5,"Painted face edge must not become empty");}
 auto moved=plane();for(auto& p:moved.vertices)p.x+=10;Session wrong(method,moved,2);bool mismatch=false;try{wrong.load(saved);}catch(...){mismatch=true;}require(mismatch,"Geometry mismatch rejects saved paint");
 // Varying-radius sweep oracle uses dense independent disks along the path.
 Session variable(method,plane(),2);variable.begin({});variable.append(hit(-100,0,10));variable.append(hit(100,0,80,true));variable.commit();for(int y=-100;y<=100;y+=9)for(int x=-140;x<=190;x+=9){double best=1e9;for(int k=0;k<=2000;++k){double t=double(k)/2000;best=std::min(best,length(V{double(x)+100-200*t,double(y),0})-(10+70*t));}if(std::abs(best)>5)require((variable.view().query(anchor(x,y),{double(x),double(y),0})>.5)==(best<0),"Variable radius sweep oracle");}
 }auto m=plane();Picker picker(m);Anchor a;require(picker.hit({0,0,10},{0,0,-1},a)&&length(m.position(a))<1e-8,"Snapshot picker center");require(!picker.hit({1000,0,10},{0,0,-1},a),"Snapshot picker miss");std::cout<<"assertions "<<checks<<"\n";return 0;}catch(const std::exception& e){std::cerr<<"FAIL after "<<checks<<": "<<e.what()<<'\n';return 1;}}
