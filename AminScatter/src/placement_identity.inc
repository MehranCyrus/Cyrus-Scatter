// The legacy two-column transport remains byte-for-byte compatible. The v1
// keyed transport adds candidate ID and its canonical receiving-surface anchor.
static amin::Instance placementInstance(Array* row) {
    if(row->size!=2&&row->size!=5)throw RuntimeError(_T("Invalid placement transport"));
    const auto tm=row->data[0]->to_matrix3();
    amin::Instance p{vec(tm.GetTrans()),vec(tm.GetRow(0)),vec(tm.GetRow(1)),vec(tm.GetRow(2)),1.0,static_cast<unsigned>(row->data[1]->to_int()-1),0};
    if(row->size==5){
        p.keyed=true;p.candidateKey=static_cast<std::uint64_t>(row->data[2]->to_int64());
        const auto face=row->data[3]->to_int();if(face<1)throw RuntimeError(_T("Invalid candidate surface face"));
        p.anchorFace=p.triangle=static_cast<unsigned>(face-1);p.anchorBary=vec(row->data[4]->to_point3());
    }
    return p;
}
static void appendIdentity(Array* row,const amin::Instance& p){
    if(!p.keyed)return;
    row->append(Integer64::intern(p.candidateKey));row->append(Integer::intern(p.anchorFace+1));row->append(new Point3Value(point(p.anchorBary)));
}
static void anchorInstance(amin::Instance& p,const std::vector<amin::Triangle>& mesh){
    const auto& t=mesh.at(p.triangle);const auto x=t.b-t.a,y=t.c-t.a,z=p.position-t.a;
    const double xx=amin::dot(x,x),xy=amin::dot(x,y),yy=amin::dot(y,y),xz=amin::dot(x,z),yz=amin::dot(y,z),den=xx*yy-xy*xy;
    if(den<=0)throw RuntimeError(_T("Degenerate candidate anchor"));
    const double b=(yy*xz-xy*yz)/den,c=(xx*yz-xy*xz)/den;
    p.keyed=true;p.anchorFace=p.triangle;p.anchorBary={1-b-c,b,c};
}
