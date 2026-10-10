#include "fixtures.h"
#include <chrono>
#include <iostream>
#include <random>
using namespace paintlab;
using Clock=std::chrono::steady_clock;
int main(){std::cout<<"method,scenario,gestures,edit_ms,query_100k_ms,state_bytes,history_logical_bytes,items,accepted\n";
 for(int method=1;method<=4;++method)for(auto scenario:{"overlap","growing"})for(int n:{1,10,100,1000}){
  try{Session s(method,plane(),5);auto start=Clock::now();for(int i=0;i<n;++i){double x=0,y=0;if(std::string(scenario)=="growing"){x=-400+(i%32)*25;y=-400+((i/32)%32)*25;}stroke(s,x,y,20);}double edit=std::chrono::duration<double,std::milli>(Clock::now()-start).count();std::mt19937 gen(42);std::uniform_real_distribution<double>d(-450,450);std::vector<Hit> samples;for(int i=0;i<100000;++i)samples.push_back(hit(d(gen),d(gen),1));start=Clock::now();unsigned accepted=0;for(auto p:samples)if(s.view().query(p.anchor,p.p)>.5)++accepted;double query=std::chrono::duration<double,std::milli>(Clock::now()-start).count();auto st=s.view().stats();std::cout<<method<<','<<scenario<<','<<n<<','<<edit<<','<<query<<','<<st.bytes<<','<<s.historyBytes()<<','<<st.items<<','<<accepted<<'\n'<<std::flush;
  }catch(const std::exception& e){std::cerr<<method<<' '<<scenario<<' '<<n<<": "<<e.what()<<'\n';}}
}
