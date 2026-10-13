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
