def_visible_primitive(cyrusOrientRows, "cyrusOrientRows");
Value* cyrusOrientRows_cf(Value** args,int count) {
    check_arg_count(cyrusOrientRows,4,count);
    auto array=[](Value* v){type_check(v,Array,_T("orientation data"));return static_cast<Array*>(v);};
    auto* input=array(args[0]);auto* pattern=array(args[1]);auto* axes=array(args[2]);auto* offsets=array(args[3]);
    if(pattern->size!=3)throw RuntimeError(_T("Invalid orientation pattern"));
    if(!pattern->data[0]->to_bool())return args[0];
    std::vector<amin::Instance> rows;std::vector<amin::LineBand> bands;std::vector<int> forward;std::vector<double> heights;
    for(int i=0;i<input->size;++i){auto* row=array(input->data[i]);if(row->size!=2)throw RuntimeError(_T("Invalid orientation row"));
        auto tm=row->data[0]->to_matrix3();int source=row->data[1]->to_int();if(source<1)throw RuntimeError(_T("Invalid source"));
        rows.push_back({vec(tm.GetTrans()),vec(tm.GetRow(0)),vec(tm.GetRow(1)),vec(tm.GetRow(2)),1.0,static_cast<unsigned>(source-1),0});}
    for(int i=0;i<axes->size;++i)forward.push_back(axes->data[i]->to_int());
    for(int i=0;i<offsets->size;++i)heights.push_back(offsets->data[i]->to_float());
    auto* wire=array(pattern->data[2]);
    for(int i=0;i<wire->size;++i){auto* row=array(wire->data[i]);if(row->size<9||row->size>13)throw RuntimeError(_T("Expected analyzer stroke"));
        amin::LineBand band;band.width=row->data[1]->to_float();band.kind=row->data[7]->to_int();band.start=row->data[8]->to_float();
        auto* paths=array(row->data[0]);for(int k=0;k<paths->size;++k){auto* path=array(paths->data[k]);std::vector<amin::Vec3> points;for(int j=0;j<path->size;++j)points.push_back(vec(path->data[j]->to_point3()));band.boundary.loops.push_back(std::move(points));}
        if(row->size>=10){auto* mask=array(row->data[9]);for(int j=0;j<mask->size;++j)band.boundaryMask.push_back(mask->data[j]->to_bool()!=FALSE);}
        if(row->size>=11)band.straightEnds=row->data[10]->to_bool()!=FALSE;
        if(row->size>=12){auto* settings=array(row->data[11]);if(settings->size!=2)throw RuntimeError(_T("Invalid facing settings"));band.faceOutward=settings->data[0]->to_bool()!=FALSE;band.cornerRadius=settings->data[1]->to_float();}
        if(row->size>=13&&band.kind==6){auto* e=array(row->data[12]);if(e->size!=3&&e->size!=6&&e->size!=9)throw RuntimeError(_T("Invalid edge row"));if(e->size==9)band.edgeRotation={e->data[6]->to_float(),e->data[7]->to_float(),e->data[8]->to_float()};band.edgeOffset=e->data[0]->to_float();band.start=0;band.width=e->data[2]->to_float()+.001;}
        bands.push_back(std::move(band));
    }
    try{amin::orientBoundary(rows,bands,forward,heights);}catch(const std::exception&){throw RuntimeError(_T("Invalid boundary orientation data"));}
    two_typed_value_locals(Array* result,Array* row);vl.result=new Array(static_cast<int>(rows.size()));
    for(const auto& row:rows){Matrix3 tm(TRUE);tm.SetRow(0,point(row.xAxis));tm.SetRow(1,point(row.yAxis));tm.SetRow(2,point(row.zAxis));tm.SetTrans(point(row.position));
        vl.row=new Array(2);vl.row->append(new Matrix3Value(tm));vl.row->append(Integer::intern(row.source+1));vl.result->append(vl.row);}
    return_value(vl.result);
}
