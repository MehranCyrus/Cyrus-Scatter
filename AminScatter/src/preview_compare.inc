// Explicit diagnostic comparison of native draw content, not allocation/GPU IDs
// or field diagnostic metadata. No script population, geometry copy or solve.
namespace {
bool previewPointEqual(const Point3& a,const Point3& b){return a.x==b.x&&a.y==b.y&&a.z==b.z;}
bool previewMatrixEqual(const Matrix3& a,const Matrix3& b){
    for(int row=0;row<4;++row)if(!previewPointEqual(a.GetRow(row),b.GetRow(row)))return false;return true;
}
bool previewBoxEqual(const Box3& a,const Box3& b){
    if(a.IsEmpty()||b.IsEmpty())return a.IsEmpty()==b.IsEmpty();
    return previewPointEqual(a.Min(),b.Min())&&previewPointEqual(a.Max(),b.Max());
}
bool previewBoxesEqual(const std::vector<Box3>& a,const std::vector<Box3>& b){
    if(a.size()!=b.size())return false;for(std::size_t i=0;i<a.size();++i)if(!previewBoxEqual(a[i],b[i]))return false;return true;
}
bool previewContentEqual(const AminPointCache& a,const AminPointCache& b){
    if(a.size!=b.size||a.geometryMode!=b.geometryMode||a.faceCount!=b.faceCount||!cyrus::samePalette(a.palette,b.palette))return false;
    if(bool(a.pointSnapshot)!=bool(b.pointSnapshot)||bool(a.meshSnapshot)!=bool(b.meshSnapshot))return false;
    if(a.pointSnapshot){const auto& x=*a.pointSnapshot;const auto& y=*b.pointSnapshot;
        if(x.count!=y.count||x.lines!=y.lines||x.groups.size()!=y.groups.size()||!previewBoxEqual(x.bounds,y.bounds)||!previewBoxesEqual(x.groupBounds,y.groupBounds))return false;
        for(std::size_t s=0;s<x.groups.size();++s){const auto& left=x.groups[s];const auto& right=y.groups[s];
            if(!previewPointEqual(left.color,right.color)||left.bandSlots!=right.bandSlots||left.points.size()!=right.points.size())return false;
            for(std::size_t i=0;i<left.points.size();++i)if(!previewPointEqual(left.points[i],right.points[i]))return false;
        }
    }
    if(a.meshSnapshot){const auto& x=*a.meshSnapshot;const auto& y=*b.meshSnapshot;
        if(x.faces!=y.faces||x.instances!=y.instances||x.groups.size()!=y.groups.size()||!previewBoxEqual(x.bounds,y.bounds)||!previewBoxesEqual(x.groupBounds,y.groupBounds)||!previewBoxesEqual(x.localBounds,y.localBounds))return false;
        for(std::size_t s=0;s<x.groups.size();++s){const auto& left=x.groups[s];const auto& right=y.groups[s];
            if(!previewPointEqual(left.color,right.color)||left.placeholder!=right.placeholder||left.reducedBox!=right.reducedBox||left.bandSlots!=right.bandSlots||left.faces.size()!=right.faces.size()||left.instances.size()!=right.instances.size())return false;
            for(std::size_t i=0;i<left.faces.size();++i)for(int corner=0;corner<3;++corner)if(!previewPointEqual(left.faces[i][corner],right.faces[i][corner]))return false;
            for(std::size_t i=0;i<left.instances.size();++i)if(!previewMatrixEqual(left.instances[i],right.instances[i]))return false;
        }
    }
    return true;
}
}
def_visible_primitive(cyrusPreviewContentEqual,"cyrusPreviewContentEqual");
Value* cyrusPreviewContentEqual_cf(Value** args,int count){
    check_arg_count(cyrusPreviewContentEqual,2,count);
    for(int i=0;i<2;++i)type_check(args[i],AminPointCache,_T("preview cache"));
    return previewContentEqual(*static_cast<AminPointCache*>(args[0]),*static_cast<AminPointCache*>(args[1]))?&true_value:&false_value;
}
