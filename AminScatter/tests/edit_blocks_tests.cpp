#include "edit_blocks.h"
#ifdef NDEBUG
#undef NDEBUG
#endif
#include <cassert>
#include <iostream>
struct Row {std::uint64_t id=0;std::array<float,12> matrix{};};
int main(){
 using namespace cyrus::edit;
 const auto initial=memory().live;
 {
  Blocks<Row> a;for(unsigned i=0;i<200000;++i){Row row;row.id=i;a.append(row);}
  const auto before=memory();auto b=a;assert(memory().total==before.total);
  b.write(12345).matrix[9]=15;
  assert(a.get(12345).matrix[9]==0&&b.get(12345).matrix[9]==15);
  assert(memory().live-before.live<100000); // table + one block, not 200k matrices
  const auto unchanged=memory();for(unsigned i=0;i<200000;++i)assert(a.get(i).id==i);
  assert(memory().total==unchanged.total);
  auto c=b;b.append(Row{200000});assert(c.size()==200000&&b.size()==200001);
  Selection s;s.set(199999,true);auto old=s;auto selected=memory();s.set(10,true);
  assert(!old.get(10)&&old.get(199999)&&s.get(10));assert(memory().live-selected.live<4096);
  std::vector<std::size_t> indices;s.each(200000,[&](auto i){indices.push_back(i);});assert((indices==std::vector<std::size_t>{10,199999}));
  indices.clear();old.each(199999,[&](auto i){indices.push_back(i);});assert(indices.empty());
  s.clear();assert(!s.get(199999)&&old.get(199999));
  bool failed=false;try{a.write(200000);}catch(const std::out_of_range&){failed=true;}assert(failed&&a.size()==200000);
  // Repeated history Restore(false), Redo and abandoned future are reference
  // assignments: they cannot mutate either saved generation.
  for(int i=0;i<100;++i){b=a;b=c;assert(b.get(12345).matrix[9]==15);}
 }
 assert(memory().live==initial);std::cout<<"Edit blocks isolation, sparse allocation, selection and release passed\n";
}
