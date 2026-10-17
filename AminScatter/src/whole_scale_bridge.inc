// Separate random stream: adjusting uniform size does not re-seed positions or axes.
def_visible_primitive(cyrusWholeScale,"cyrusWholeScale");
Value* cyrusWholeScale_cf(Value** args,int count){
 check_arg_count(cyrusWholeScale,4,count);
 double lo=args[1]->to_float(),hi=args[2]->to_float();
 if(!std::isfinite(lo)||!std::isfinite(hi)||lo<=0||hi<lo)throw RuntimeError(_T("Whole Scale requires 0 < Min <= Max"));
 const unsigned seed=static_cast<unsigned>(args[3]->to_int());
 if(cyrusIsPlacementValue(args[0]))try{
  const auto& view=cyrusPlacementView(args[0]);
  if(view.stage()!=cyrus::placements::Stage::Candidates)throw RuntimeError(_T("Whole Scale requires raw native candidates"));
  cyrus::placements::Builder builder(view.token().owner,view.stage(),view.sources(),view.size(),view.sourceCohort(),view.receiverCohort());
  for(std::size_t i=0;i<view.size();++i){auto record=view.at(i);
   const double unit=amin::stableUnit(seed,record.identity,8);
   const float f=static_cast<float>(lo+(hi-lo)*unit);
   // Keep the SDK Point3 Float32 multiplication used by the script adapter.
   for(int axis=0;axis<3;++axis){const auto k=std::size_t(axis*3);
    const auto p=Point3(record.transform[k],record.transform[k+1],record.transform[k+2])*f;
    record.transform[k]=p.x;record.transform[k+1]=p.y;record.transform[k+2]=p.z;
   }
   builder.appendGenerated(record);
  }
  return cyrusPlacementValue(builder.freeze());
 }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
 type_check(args[0],Array,_T("Whole Scale rows"));auto* rows=static_cast<Array*>(args[0]);
 cyrus::placements::MaterializationScope materializations(cyrus::placements::TransportStage::Source);
 two_typed_value_locals(Array* result,Array* row);vl.result=new Array(rows->size);
 materializations.populationArray();
 for(int i=0;i<rows->size;++i){type_check(rows->data[i],Array,_T("Whole Scale row"));auto* r=static_cast<Array*>(rows->data[i]);
  cyrus::rows::raw(r);auto tm=r->data[0]->to_matrix3();
  const double unit=amin::stableUnit(seed,std::uint64_t(r->data[2]->to_int64()),8);
  float f=static_cast<float>(lo+(hi-lo)*unit);
  for(int axis=0;axis<3;++axis)tm.SetRow(axis,tm.GetRow(axis)*f);
  vl.row=new Array(r->size);materializations.row();vl.row->append(new Matrix3Value(tm));materializations.matrix();for(int j=1;j<r->size;++j)vl.row->append(r->data[j]);vl.result->append(vl.row);
 }return_value(vl.result);
}
