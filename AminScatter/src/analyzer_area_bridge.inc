// Area uses world XY, matching existing Include/Exclude spline masks.
def_visible_primitive(cyrusAnalyzerArea,"cyrusAnalyzerArea");
Value* cyrusAnalyzerArea_cf(Value** args,int count){
 check_arg_count(cyrusAnalyzerArea,6,count);
 auto arr=[](Value* v){type_check(v,Array,_T("Analyzer Area data"));return static_cast<Array*>(v);};
 auto* rows=arr(args[0]);auto* paths=arr(args[1]);auto* points=arr(args[2]);
 const double w=args[3]->to_float(),radius=args[4]->to_float();const int caps=args[5]->to_int();
 if(!std::isfinite(w)||!std::isfinite(radius)||w<0||radius<0||(caps!=1&&caps!=2))throw RuntimeError(_T("Invalid Analyzer Area settings"));
 struct Segment{Point3 a,b;bool first,last;};std::vector<Segment> segments;std::vector<Point3> centers;
 for(int i=0;i<paths->size;++i){auto* path=arr(paths->data[i]);if(path->size<2)continue;
  auto first=path->data[0]->to_point3(),last=path->data[path->size-1]->to_point3();bool closed=LengthSquared(first-last)<1e-8f;
  for(int j=1;j<path->size;++j){auto a=path->data[j-1]->to_point3(),b=path->data[j]->to_point3();if((b.x-a.x)*(b.x-a.x)+(b.y-a.y)*(b.y-a.y)>1e-12)segments.push_back({a,b,!closed&&j==1,!closed&&j==path->size-1});}
 }
 for(int i=0;i<points->size;++i)centers.push_back(points->data[i]->to_point3());
 one_typed_value_local(Array* result);vl.result=new Array(rows->size);
 for(int i=0;i<rows->size;++i){auto* row=arr(rows->data[i]);if(row->size!=2)throw RuntimeError(_T("Invalid Analyzer Area row"));auto p=row->data[0]->to_matrix3().GetTrans();bool keep=false;
  for(const auto& s:segments){
   if(p.x<std::min(s.a.x,s.b.x)-w||p.x>std::max(s.a.x,s.b.x)+w||p.y<std::min(s.a.y,s.b.y)-w||p.y>std::max(s.a.y,s.b.y)+w)continue;
   double dx=s.b.x-s.a.x,dy=s.b.y-s.a.y,t=((p.x-s.a.x)*dx+(p.y-s.a.y)*dy)/(dx*dx+dy*dy);
   if(caps==1&&((s.first&&t<0)||(s.last&&t>1)))continue;
   t=std::clamp(t,0.0,1.0);double x=p.x-s.a.x-t*dx,y=p.y-s.a.y-t*dy;
   if(x*x+y*y<=w*w){keep=true;break;}
  }
  if(!keep)for(const auto& c:centers){double x=p.x-c.x,y=p.y-c.y;if(x*x+y*y<=radius*radius){keep=true;break;}}
  if(keep)vl.result->append(row);
 }return_value(vl.result);
}
