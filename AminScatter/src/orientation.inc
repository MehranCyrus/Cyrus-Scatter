namespace {
struct FacingLoop {std::vector<Vec3> points,out;Vec3 normal,up;std::size_t maskStart=0;};
bool loopInside(Vec3 p,const std::vector<Vec3>& loop,Vec3 n) {
    if(loop.size()<3||std::abs(dot(p-loop[0],n))>1e-5)return false;
    Vec3 x=unit(loop[1]-loop[0]),y=cross(n,x);bool inside=false;
    for(std::size_t i=0,j=loop.size()-1;i<loop.size();j=i++) {
        double ax=dot(loop[j]-p,x),ay=dot(loop[j]-p,y),bx=dot(loop[i]-p,x),by=dot(loop[i]-p,y);
        if((ay>0)!=(by>0)&&0<ax-ay*(bx-ax)/(by-ay))inside=!inside;
    }
    return inside;
}
Vec3 pathNormal(const std::vector<Vec3>& path) {
    Vec3 n{};if(path.size()<3)return n;
    for(std::size_t i=0;i<path.size();++i)n=n+cross(path[i]-path[0],path[(i+1)%path.size()]-path[0]);
    return length(n)>1e-12?unit(n):Vec3{};
}
double segmentDistance(Vec3 p,Vec3 a,Vec3 b) {
    Vec3 v=b-a;double den=dot(v,v);
    return length(p-(a+v*(den>1e-20?std::clamp(dot(p-a,v)/den,0.0,1.0):0)));
}
std::vector<FacingLoop> facingLoops(const LineBand& band) {
    std::vector<FacingLoop> loops;std::size_t start=0;
    for(const auto& path:band.boundary.loops) {
        auto n=pathNormal(path);if(length(n)<.5){start+=path.size();continue;}
        unsigned depth=0;
        for(const auto& other:band.boundary.loops)if(&path!=&other){auto on=pathNormal(other);if(length(on)>.5&&std::abs(dot(on,n))>.999999&&loopInside(path[0],other,on))++depth;}
        Vec3 up=n;
        const double sign=std::abs(up.z)>1e-6?up.z:(std::abs(up.y)>1e-6?up.y:up.x);
        if(sign<0)up=up*(-1);
        FacingLoop item{path,{},n,up,start};
        for(std::size_t i=0;i<path.size();++i){auto tangent=path[(i+1)%path.size()]-path[i];item.out.push_back(length(tangent)>1e-12?unit(cross(tangent,n))*(depth%2?-1:1):Vec3{});}
        loops.push_back(std::move(item));start+=path.size();
    }
    return loops;
}
bool outwardAt(Vec3 p,const LineBand& band,const std::vector<FacingLoop>& loops,Vec3& direction,Vec3& up) {
    const FacingLoop* nearest=nullptr;std::size_t edge=0;double best=INFINITY;Vec3 projected{};
    for(const auto& loop:loops) {
        Vec3 q=p-loop.normal*dot(p-loop.points[0],loop.normal);
        for(std::size_t i=0;i<loop.points.size();++i) {
            auto k=loop.maskStart+i;
            if(!band.boundaryMask.empty()&&(k>=band.boundaryMask.size()||!band.boundaryMask[k]))continue;
            if(length(loop.out[i])<.5)continue;
            if(band.straightEnds){auto v=loop.points[(i+1)%loop.points.size()]-loop.points[i];double t=dot(q-loop.points[i],v)/dot(v,v);if(t<0||t>1)continue;}
            double d=segmentDistance(q,loop.points[i],loop.points[(i+1)%loop.points.size()]);
            // Prefer the physically closest plane for disconnected stacked elements.
            double score=std::hypot(d,dot(p-loop.points[0],loop.normal));
            if(score<best){best=score;nearest=&loop;edge=i;projected=q;}
        }
    }
    if(!nearest)return false;
    const auto& v=nearest->points;const auto n=v.size();
    const double distance=segmentDistance(projected,v[edge],v[(edge+1)%n]);
    // MAXScript matrices use floats; points snapped to a boundary may round just
    // outside it during transport. Permit only the scale-relative float error.
    double tolerance=1e-6*std::max({1.0,std::abs(p.x),std::abs(p.y),std::abs(p.z)});
    auto testBand=band;if(testBand.kind==6)testBand.kind=2;
    if(!analyzerBand(projected,testBand,tolerance)&&!(band.start==0&&distance<=tolerance))return false;
    direction=nearest->out[edge];up=nearest->up;
    std::size_t corner=length(projected-v[edge])<=length(projected-v[(edge+1)%n])?edge:(edge+1)%n;
    double r=length(projected-v[corner]);
    if(r<=band.cornerRadius||r<1e-8) {
        const auto prev=(corner+n-1)%n;
        Vec3 a=nearest->out[prev],b=nearest->out[corner];
        if(length(a)>.5&&length(b)>.5) {
            double da=segmentDistance(projected,v[prev],v[corner]),db=segmentDistance(projected,v[corner],v[(corner+1)%n]);
            // A shrinking soft nearest-edge blend joins both normals at the vertex.
            double falloff=band.cornerRadius>0?std::max(0.0,1-r/band.cornerRadius):0;
            double softness=band.cornerRadius*falloff*falloff;
            double weight=std::abs(da-db)<1e-10?.5:(softness>1e-12?1/(1+std::exp(std::clamp((da-db)/softness,-60.0,60.0))):(da<db?1.0:0.0));
            Vec3 blend=a*weight+b*(1-weight);
            if(band.kind==6){
                // Blend both endpoints so overlapping radii do not switch abruptly
                // at the midpoint of a short edge. Exact vertices keep their bisector.
                blend=direction;
                for(auto endpoint:{edge,(edge+1)%n}){
                    Vec3 bisector=nearest->out[(endpoint+n-1)%n]+nearest->out[endpoint];
                    double d=length(projected-v[endpoint]);
                    if(length(bisector)<1e-10)continue;
                    if(d<1e-8){blend=unit(bisector);break;}
                    if(band.cornerRadius<=0||d>=band.cornerRadius)continue;
                    double t=d/band.cornerRadius;
                    double influence=(1-t*t*(3-2*t))/t;
                    blend=blend+unit(bisector)*influence;
                }
            }
            if(length(blend)>1e-10)direction=unit(blend);
        }
    }
    return true;
}
}
void orientBoundary(std::vector<Instance>& rows,const std::vector<LineBand>& bands,const std::vector<int>& axes,const std::vector<double>& offsets) {
    std::vector<std::vector<FacingLoop>> prepared;
    for(const auto& band:bands){if(!std::isfinite(band.cornerRadius)||band.cornerRadius<0)throw std::invalid_argument("Invalid corner radius");prepared.push_back(band.kind==1||band.kind==2||band.kind==6?facingLoops(band):std::vector<FacingLoop>{});}
    for(auto& row:rows) {
        if(row.source>=axes.size()||axes[row.source]<1||axes[row.source]>4)throw std::invalid_argument("Invalid source forward axis");
        Vec3 p=row.position;if(row.source<offsets.size())p.z-=offsets[row.source];
        for(std::size_t i=0;i<bands.size();++i) {
            const auto& band=bands[i];Vec3 out{},up{};
            bool matched=band.kind==1||band.kind==2||band.kind==6?outwardAt(p,band,prepared[i],out,up):analyzerBand(p,band);
            if(band.kind==5)for(const auto& path:band.boundary.loops)for(auto anchor:path)if(length(p-anchor)<1e-7)matched=true;
            if(!matched)continue;
            if(band.faceOutward&&(band.kind==1||band.kind==2||band.kind==6)) {
                double sx=length(row.xAxis),sy=length(row.yAxis),sz=length(row.zAxis);Vec3 x{},y{};
                switch(axes[row.source]) {
                    case 1:y=out;x=cross(y,up);break;
                    case 2:y=out*(-1);x=cross(y,up);break;
                    case 3:x=out;y=cross(up,x);break;
                    case 4:x=out*(-1);y=cross(up,x);break;
                }
                row.xAxis=x*sx;row.yAxis=y*sy;row.zAxis=up*sz;
            }
            if(band.kind==6 && length(band.edgeRotation)>0) {
                if(!finite(band.edgeRotation))throw std::invalid_argument("Invalid local rotation");
                double sx=length(row.xAxis),sy=length(row.yAxis),sz=length(row.zAxis);
                if(sx>1e-12&&sy>1e-12&&sz>1e-12){
                    Vec3 x=row.xAxis*(1/sx),y=row.yAxis*(1/sy),z=row.zAxis*(1/sz);
                    auto turn=[&](Vec3 v){auto q=rotate(v,band.edgeRotation*(3.14159265358979323846/180));return x*q.x+y*q.y+z*q.z;};
                    row.xAxis=turn({1,0,0})*sx;row.yAxis=turn({0,1,0})*sy;row.zAxis=turn({0,0,1})*sz;
                }
            }
            if(band.kind==6 && band.edgeOffset!=0) {
                // Offset along the chosen local forward axis after all placement filters.
                Vec3 forward=axes[row.source]<=2?row.yAxis:row.xAxis;
                if(axes[row.source]==2||axes[row.source]==4)forward=forward*(-1);
                if(length(forward)>1e-12)row.position=row.position-unit(forward)*band.edgeOffset;
            }
            break;
        }
    }
}
