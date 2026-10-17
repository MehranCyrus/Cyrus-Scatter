// One internal transport: candidate identity, base anchor, Band owner and stage.
static amin::Instance placementInstance(Array* row) {
    cyrus::rows::raw(row);
    const auto tm=row->data[0]->to_matrix3();
    amin::Instance p{vec(tm.GetTrans()),vec(tm.GetRow(0)),vec(tm.GetRow(1)),vec(tm.GetRow(2)),1.0,static_cast<unsigned>(row->data[1]->to_int()-1),0};
    p.keyed=true;p.candidateKey=static_cast<std::uint64_t>(row->data[2]->to_int64());
    p.anchorFace=p.triangle=static_cast<unsigned>(row->data[3]->to_int()-1);p.anchorBary=vec(row->data[4]->to_point3());
    p.bandOwner=cyrus::rows::owner(row);
    return p;
}
static amin::Instance placementInstance(const cyrus::placements::Record& row) {
    const auto& m=row.transform;
    amin::Instance p{{m[9],m[10],m[11]},{m[0],m[1],m[2]},{m[3],m[4],m[5]},{m[6],m[7],m[8]},1.0,row.source-1,row.face-1};
    p.keyed=true;p.candidateKey=row.identity;p.anchorFace=row.face-1;p.anchorBary={row.bary[0],row.bary[1],row.bary[2]};p.bandOwner=row.band;return p;
}
static cyrus::placements::Record placementRecord(const amin::Instance& p,unsigned receiver,bool mergeScale) {
    if(!p.keyed)throw RuntimeError(_T("Placement is missing its candidate anchor"));
    const Matrix3 matrix(point(mergeScale?p.xAxis*p.scale:p.xAxis),point(mergeScale?p.yAxis*p.scale:p.yAxis),point(mergeScale?p.zAxis*p.scale:p.zAxis),point(p.position));
    const auto bary=point(p.anchorBary);cyrus::placements::Record r;
    for(int j=0;j<4;++j)for(int k=0;k<3;++k)r.transform[std::size_t(j*3+k)]=matrix.GetRow(j)[k];
    r.bary={bary.x,bary.y,bary.z};r.source=p.source+1;r.face=p.anchorFace+1;r.receiver=receiver;r.identity=p.candidateKey;r.band=p.bandOwner;return r;
}
static void appendIdentity(Array* row,const amin::Instance& p){
    if(!p.keyed)throw RuntimeError(_T("Placement is missing its candidate anchor"));
    row->append(Integer64::intern(p.candidateKey));row->append(Integer::intern(p.anchorFace+1));row->append(new Point3Value(point(p.anchorBary)));
    row->append(Integer64::intern(p.bandOwner));row->append(&false_value);row->append(Integer::intern(2));
}
static void anchorInstance(amin::Instance& p,const std::vector<amin::Triangle>& mesh){
    const auto& t=mesh.at(p.triangle);const auto x=t.b-t.a,y=t.c-t.a,z=p.position-t.a;
    const double xx=amin::dot(x,x),xy=amin::dot(x,y),yy=amin::dot(y,y),xz=amin::dot(x,z),yz=amin::dot(y,z),den=xx*yy-xy*xy;
    if(den<=0)throw RuntimeError(_T("Degenerate candidate anchor"));
    const double b=(yy*xz-xy*yz)/den,c=(xx*yz-xy*xz)/den;
    p.keyed=true;p.anchorFace=p.triangle;p.anchorBary={1-b-c,b,c};
}
