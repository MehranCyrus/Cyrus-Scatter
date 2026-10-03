// Separate random stream: adjusting uniform size does not re-seed positions or axes.
def_visible_primitive(cyrusWholeScale,"cyrusWholeScale");
Value* cyrusWholeScale_cf(Value** args,int count){
 check_arg_count(cyrusWholeScale,4,count);type_check(args[0],Array,_T("Whole Scale rows"));
 auto* rows=static_cast<Array*>(args[0]);double lo=args[1]->to_float(),hi=args[2]->to_float();
 if(!std::isfinite(lo)||!std::isfinite(hi)||lo<=0||hi<lo)throw RuntimeError(_T("Whole Scale requires 0 < Min <= Max"));
 auto hash=[](unsigned v){v^=v>>16;v*=0x7feb352du;v^=v>>15;v*=0x846ca68bu;return v^(v>>16);};
 const unsigned seed=static_cast<unsigned>(args[3]->to_int());
 two_typed_value_locals(Array* result,Array* row);vl.result=new Array(rows->size);
 for(int i=0;i<rows->size;++i){type_check(rows->data[i],Array,_T("Whole Scale row"));auto* r=static_cast<Array*>(rows->data[i]);
  if(r->size<2)throw RuntimeError(_T("Invalid Whole Scale row"));auto tm=r->data[0]->to_matrix3();
  float f=static_cast<float>(lo+(hi-lo)*(hash(seed^hash(static_cast<unsigned>(i)))/4294967296.0));
  for(int axis=0;axis<3;++axis)tm.SetRow(axis,tm.GetRow(axis)*f);
  vl.row=new Array(r->size);vl.row->append(new Matrix3Value(tm));for(int j=1;j<r->size;++j)vl.row->append(r->data[j]);vl.result->append(vl.row);
 }return_value(vl.result);
}
