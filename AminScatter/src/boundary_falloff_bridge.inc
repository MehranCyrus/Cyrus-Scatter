def_visible_primitive(cyrusBoundaryFalloff,"cyrusBoundaryFalloff");
def_visible_primitive(cyrusAreaFalloff,"cyrusAreaFalloff");
static Value* falloffBridge(Value** args,int count,bool area){
 const int originalCount=area?5:4;
 if(count!=originalCount&&count!=originalCount+1) throw RuntimeError(_T("Invalid falloff argument count"));
 auto arr=[](Value* v){type_check(v,Array,_T("Boundary falloff data"));return static_cast<Array*>(v);};
 auto* input=arr(args[0]);auto* paths=area?nullptr:arr(args[1]);auto* cfg=arr(args[2]);if(cfg->size!=8)throw RuntimeError(_T("Invalid falloff settings"));
 amin::BoundaryFalloff f;f.remove=cfg->data[0]->to_bool()!=FALSE;f.removeWidth=cfg->data[1]->to_float();f.scale=cfg->data[2]->to_bool()!=FALSE;f.scaleWidth=cfg->data[3]->to_float();f.density=cfg->data[5]->to_bool()!=FALSE;f.densityWidth=cfg->data[6]->to_float();
 f.stableCandidates=count>originalCount&&args[originalCount]->to_bool()!=FALSE;
 auto curve=[&](Value* v){auto* a=arr(v);std::vector<double> out;for(int i=0;i<a->size;++i)out.push_back(a->data[i]->to_float());return out;};f.scaleCurve=curve(cfg->data[4]);f.densityCurve=curve(cfg->data[7]);
 std::vector<amin::Instance> rows;std::vector<std::vector<amin::Vec3>> loops;
 for(int i=0;i<input->size;++i){auto* row=arr(input->data[i]);if(f.stableCandidates&&(row->size!=5||row->data[2]->to_int64()<0))throw RuntimeError(_T("Stable falloff requires candidate identity"));rows.push_back(placementInstance(row));}
 if(!area)for(int i=0;i<paths->size;++i){auto* p=arr(paths->data[i]);std::vector<amin::Vec3> path;for(int j=0;j<p->size;++j)path.push_back(vec(p->data[j]->to_point3()));loops.push_back(std::move(path));}
 if(area){
  f.areaSide=args[4]->to_int();if(f.areaSide!=1&&f.areaSide!=2)throw RuntimeError(_T("Invalid Area mode"));
  auto* node=args[1]->to_node();if(!node)throw RuntimeError(_T("Missing Area spline"));
  auto time=GetCOREInterface()->GetTime();auto* object=node->EvalWorldState(time).obj;
  if(!object||object->SuperClassID()!=SHAPE_CLASS_ID)throw RuntimeError(_T("Area must be a closed spline"));
  auto* shape=static_cast<ShapeObject*>(object);auto tm=node->GetObjectTM(time);
  for(int c=0;c<shape->NumberOfCurves(time);++c){
   if(!shape->CurveClosed(time,c))throw RuntimeError(_T("Area spline must be closed"));
   int steps=std::max(3,shape->NumberOfPieces(time,c)*16);if(steps>65536)throw RuntimeError(_T("Area spline too complex"));
   std::vector<amin::Vec3> path;for(int k=0;k<steps;++k)path.push_back(vec(shape->InterpCurve3D(time,c,static_cast<float>(k)/steps,PARAM_SIMPLE)*tm));loops.push_back(std::move(path));
  }
 }
 try{rows=amin::boundaryFalloff(rows,loops,f,args[3]->to_int());}catch(const std::exception& e){throw RuntimeError(_T("Boundary falloff failed. Check Analyzer data and curve settings."));}
 two_typed_value_locals(Array* result,Array* row);vl.result=new Array(static_cast<int>(rows.size()));
 for(const auto& r:rows){Matrix3 tm(TRUE);tm.SetRow(0,point(r.xAxis));tm.SetRow(1,point(r.yAxis));tm.SetRow(2,point(r.zAxis));tm.SetTrans(point(r.position));vl.row=new Array(2);vl.row->append(new Matrix3Value(tm));vl.row->append(Integer::intern(r.source+1));appendIdentity(vl.row,r);vl.result->append(vl.row);}return_value(vl.result);
}

Value* cyrusBoundaryFalloff_cf(Value** args,int count){return falloffBridge(args,count,false);}
Value* cyrusAreaFalloff_cf(Value** args,int count){return falloffBridge(args,count,true);}

