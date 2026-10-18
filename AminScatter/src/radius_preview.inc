// Bounded display preparation directly from immutable placement/radius data.
// The 24 authored unit-circle samples preserve MAXScript trig rounding; no
// placement rows, eligible-index array or ring vertices cross into script.
def_visible_primitive(cyrusNativeRadiusPreview,"cyrusNativeRadiusPreview");
Value* cyrusNativeRadiusPreview_cf(Value** args,int count){
 check_arg_count(cyrusNativeRadiusPreview,5,count);
 if(!cyrusIsPlacementValue(args[0]))throw RuntimeError(_T("Native radius preview needs native placements"));
 PreviewRows rows(args[0]);const auto radii=cyrusRadiusData(args[1]);
 if(radii->size()!=rows.size())throw RuntimeError(_T("Radius preview count differs from placements"));
 for(int k=2;k<5;++k)type_check(args[k],Array,_T("radius preview settings"));
 const auto* sources=static_cast<Array*>(args[2]);const auto* cfg=static_cast<Array*>(args[3]);const auto* circle=static_cast<Array*>(args[4]);
 if(sources->size>1024||cfg->size!=3||circle->size!=24)throw RuntimeError(_T("Invalid bounded radius preview settings"));
 const int metric=cfg->data[0]->to_int(),limit=cfg->data[1]->to_int();const bool all=cfg->data[2]->to_bool()!=FALSE;
 if(metric<1||metric>2)throw RuntimeError(_T("Radius display metric must be XY or 3D"));
 std::vector<bool> show;std::vector<Point3> colors;std::array<Point3,24> unit;
 for(int i=0;i<sources->size;++i){type_check(sources->data[i],Array,_T("radius source"));const auto* s=static_cast<Array*>(sources->data[i]);if(s->size!=2)throw RuntimeError(_T("Invalid radius source"));show.push_back(s->data[0]->to_bool()!=FALSE);colors.push_back(s->data[1]->to_point3()/255.f);}
 for(int i=0;i<24;++i)unit[std::size_t(i)]=circle->data[i]->to_point3();
 std::size_t eligible=0;
 auto qualifies=[&](std::size_t i){const auto source=rows.source(i);if(!source||source>show.size())throw RuntimeError(_T("Invalid radius source correspondence"));return show[source-1]&&(*radii)[i][std::size_t(metric-1)]>0;};
 for(std::size_t i=0;i<rows.size();++i)if(qualifies(i))++eligible;
 const auto wanted=all?eligible:std::min(std::size_t(std::max(0,limit)),eligible);
 const unsigned perRadius=metric==1?1u:3u;
 if(wanted*perRadius>10000)throw RuntimeError(_T("Radius display exceeds 10,000 rings. Reduce Radii / layer (at most 3,333 in 3D)."));
 const auto vertices=wanted*perRadius*48;
 auto staging=cyrus::reservePreviewMemory(cyrus::pointPreviewBudget,vertices*2*(sizeof(Point3)+sizeof(std::uint8_t))+wanted*perRadius*256+4096);
 std::vector<AminPointCache::Group> groups;
 std::size_t ordinal=0,k=0,next=0;
 for(std::size_t i=0;i<rows.size()&&k<wanted;++i)if(qualifies(i)){
  if(ordinal++!=next)continue;
  const auto center=rows.matrix(i).GetTrans();const float radius=(*radii)[i][std::size_t(metric-1)];const auto color=colors[rows.source(i)-1];
  auto group=std::find_if(groups.begin(),groups.end(),[&](const auto& g){return g.color==color;});
  if(group==groups.end()){groups.push_back({color,{}});group=groups.end()-1;}
  for(unsigned axis=0;axis<perRadius;++axis){std::array<Point3,24> points;
   for(std::size_t j=0;j<24;++j){const float a=radius*unit[j].x,b=radius*unit[j].y;points[j]=center+(axis==0?Point3(a,b,0.f):axis==1?Point3(a,0.f,b):Point3(0.f,a,b));}
   for(std::size_t j=0;j<24;++j){group->points.push_back(points[j]);group->points.push_back(points[(j+1)%24]);group->bandSlots.push_back(0);group->bandSlots.push_back(0);}
  }
  ++k;next=std::size_t(std::floor(float(k)*float(eligible)/float(std::max(std::size_t(1),wanted))));
 }
 auto snapshot=std::make_shared<cyrus::PointSnapshot>(std::move(groups),true);
 auto* result=new AminPointCache();result->pointSnapshot=std::move(snapshot);result->size=int(wanted*perRadius);result->radiusDetails=true;return result;
}
static Value* combineRadiusPreview(Value* ringsValue,Value* fieldValue){
 auto* rings=static_cast<AminPointCache*>(ringsValue);
 if(!rings->radiusDetails||!rings->pointSnapshot||!rings->pointSnapshot->lines)throw RuntimeError(_T("Inspection needs native radius lines"));
 if(fieldValue==&undefined)return ringsValue;
 type_check(fieldValue,AminPointCache,_T("field preview"));auto* field=static_cast<AminPointCache*>(fieldValue);
 if(!field->fieldDetails||!field->pointSnapshot||!field->pointSnapshot->lines)throw RuntimeError(_T("Inspection expects a field overlay cache"));
 if(!rings->size)return fieldValue;
 constexpr std::size_t vertexLimit=cyrus::pointPreviewOwnerLimit/(2*(sizeof(Point3)+sizeof(std::uint8_t)));
 const auto vertices=rings->pointSnapshot->count+field->pointSnapshot->count;
 if(vertices>vertexLimit)throw RuntimeError(_T("Field and radius display exceed the vertex allowance"));
 auto staging=cyrus::reservePreviewMemory(cyrus::pointPreviewBudget,vertices*2*(sizeof(Point3)+sizeof(std::uint8_t))+rings->size*256+4096);
 auto groups=field->pointGroups();
 for(const auto& ring:rings->pointGroups()){
  auto group=std::find_if(groups.begin(),groups.end(),[&](const auto& g){return g.color==ring.color;});
  if(group==groups.end())groups.push_back(ring);
  else{group->points.insert(group->points.end(),ring.points.begin(),ring.points.end());group->bandSlots.insert(group->bandSlots.end(),ring.bandSlots.begin(),ring.bandSlots.end());}
 }
 auto snapshot=std::make_shared<cyrus::PointSnapshot>(std::move(groups),true);
 auto* result=new AminPointCache();result->pointSnapshot=std::move(snapshot);result->size=rings->size;result->fieldDetails=field->fieldDetails;return result;
}
