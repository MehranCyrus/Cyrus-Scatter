// Closed Analyzer bands only. Preserve edge order, mask offsets, planar tests,
// square roots and all per-query arithmetic from analyzerBand; reuse constants.
class PreparedAnalyzerBand {
    struct Edge { Vec3 a,b,v; double denominator; std::size_t maskIndex; };
    struct Path { Vec3 origin,normal,x,y; bool valid; std::vector<Edge> edges; };
    const LineBand& band;
    std::vector<Path> paths;
public:
    explicit PreparedAnalyzerBand(const LineBand& input):band(input) {
        std::size_t edgeIndex=0;
        for(const auto& points:band.boundary.loops) {
            if(points.empty()) continue;
            Path path{};path.origin=points[0];
            Vec3 normal{};
            for(std::size_t i=0;i<points.size();++i)
                normal=normal+cross(points[i]-points[0],points[(i+1)%points.size()]-points[0]);
            // Match the original less-than test, including NaN behavior. Normal
            // validation remains at its existing caller, not in this helper.
            path.valid=!(length(normal)<1e-12);
            if(path.valid) {
                path.normal=unit(normal);path.x=unit(points[1]-points[0]);path.y=cross(path.normal,path.x);
                path.edges.reserve(points.size());
                for(std::size_t i=0;i<points.size();++i) {
                    auto a=points[i],b=points[(i+1)%points.size()],v=b-a;
                    path.edges.push_back({a,b,v,dot(v,v),edgeIndex+i});
                }
            }
            edgeIndex+=points.size();paths.push_back(std::move(path));
        }
    }
    bool contains(Vec3 p,double tolerance=0) const {
        double nearest=INFINITY;bool inside=false;
        for(const auto& path:paths) {
            if(!path.valid || std::abs(dot(p-path.origin,path.normal))>1e-4) continue;
            for(const auto& edge:path.edges) {
                const auto den=edge.denominator;
                const double projection=den>0?dot(p-edge.a,edge.v)/den:0,t=std::clamp(projection,0.0,1.0);
                if((!band.straightEnds || (den>0 && projection>=0 && projection<=1)) &&
                   (band.boundaryMask.empty() || (edge.maskIndex<band.boundaryMask.size() && band.boundaryMask[edge.maskIndex])))
                    nearest=std::min(nearest,length(p-(edge.a+edge.v*t)));
                const double ax=dot(edge.a-p,path.x),ay=dot(edge.a-p,path.y),bx=dot(edge.b-p,path.x),by=dot(edge.b-p,path.y);
                if((ay>0)!=(by>0) && 0<ax-ay*(bx-ax)/(by-ay)) inside=!inside;
            }
        }
        return nearest>=std::max(0.0,band.start-tolerance) && nearest<=band.width+tolerance && inside==(band.kind==2);
    }
};
