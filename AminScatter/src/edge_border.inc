std::vector<Vec3> edgeBorderPoints(const LineBand& band,std::uint32_t seed) {
    if(!std::isfinite(band.width)||band.width<=0)throw std::invalid_argument("Positive edge spacing required");
    if(!std::isfinite(band.edgeOffset))throw std::invalid_argument("Invalid edge offset");
    for(double x:{band.edgeAlongJitter,band.edgeAcrossJitter})if(!std::isfinite(x)||x<0)throw std::invalid_argument("Invalid edge row controls");
    if(!std::isfinite(band.edgeCornerAngle)||band.edgeCornerAngle<0||band.edgeCornerAngle>180||band.edgeCornerCount<1||band.edgeCornerCount>64)throw std::invalid_argument("Invalid corner settings");
    std::vector<Vec3> result;Random jitter(seed^0x591a278du);
    const auto loops=facingLoops(band);
    for(const auto& loop:loops) {
        const auto n=loop.points.size();std::vector<Vec3> shifted;std::vector<double> cumulative{0};
        // Sample the original boundary; local offset is a final transform only.
        shifted=loop.points;
        for(std::size_t i=0;i<n;++i)cumulative.push_back(cumulative.back()+length(shifted[(i+1)%n]-shifted[i]));
        double perimeter=cumulative.back();if(perimeter<1e-8)continue;
        double count=std::max(1.0,std::floor(perimeter/band.width+.5));
        if(count>500000||result.size()+count>500000)throw std::invalid_argument("Edge row exceeds 500000 points; increase spacing");
        const auto total=static_cast<std::size_t>(count);double step=perimeter/total;
        std::vector<double> pinned;
        auto allowedEdge=[&](std::size_t e){auto m=loop.maskStart+e;return band.boundaryMask.empty()||(m<band.boundaryMask.size()&&band.boundaryMask[m]);};
        if(band.edgeKeepCorners)for(std::size_t i=0;i<n;++i){
            auto prev=(i+n-1)%n;double before=cumulative[prev+1]-cumulative[prev],after=cumulative[i+1]-cumulative[i];
            if(before<1e-10||after<1e-10||(!allowedEdge(prev)&&!allowedEdge(i)))continue;
            double turn=std::acos(std::clamp(dot(unit(shifted[i]-shifted[prev]),unit(shifted[(i+1)%n]-shifted[i])),-1.0,1.0))*180/3.14159265358979323846;
            if(turn<1e-6||turn+1e-8<band.edgeCornerAngle)continue;
            pinned.push_back(cumulative[i]);
            double spacing=std::min(step*.25,std::min(before,after)/(band.edgeCornerCount+1));
            for(int j=1;j<band.edgeCornerCount;++j){bool back=(j%2==1);if(!allowedEdge(prev))back=false;if(!allowedEdge(i))back=true;
                int rank=allowedEdge(prev)&&allowedEdge(i)?(j+1)/2:j;
                pinned.push_back(std::fmod(cumulative[i]+(back?-1:1)*spacing*rank+perimeter,perimeter));
            }
        }
        std::sort(pinned.begin(),pinned.end());pinned.erase(std::unique(pinned.begin(),pinned.end(),[](double a,double b){return std::abs(a-b)<1e-8;}),pinned.end());
        if(result.size()+total+pinned.size()>500000)throw std::invalid_argument("Edge row exceeds 500000 points; increase spacing");
        auto nearPin=[&](double d){if(pinned.empty())return false;auto it=std::lower_bound(pinned.begin(),pinned.end(),d);double next=it==pinned.end()?pinned.front()+perimeter:*it;double prev=it==pinned.begin()?pinned.back()-perimeter:*(it-1);return std::min(next-d,d-prev)<step*.2;};
        for(double d:pinned){auto e=std::min(n-1,static_cast<std::size_t>(std::upper_bound(cumulative.begin(),cumulative.end(),d)-cumulative.begin()-1));double len=cumulative[e+1]-cumulative[e];result.push_back(shifted[e]+(shifted[(e+1)%n]-shifted[e])*((d-cumulative[e])/len));}
        for(std::size_t k=0;k<total;++k){double along=std::min(band.edgeAlongJitter,.45*step);
            double distance=std::fmod(k*step+jitter.range({-along,along})+perimeter,perimeter);
            if(nearPin(distance))continue;
            auto edge=std::min(n-1,static_cast<std::size_t>(std::upper_bound(cumulative.begin(),cumulative.end(),distance)-cumulative.begin()-1));
            auto mask=loop.maskStart+edge;if(!band.boundaryMask.empty()&&(mask>=band.boundaryMask.size()||!band.boundaryMask[mask]))continue;
            double len=cumulative[edge+1]-cumulative[edge];if(len<1e-10)continue;
            auto p=shifted[edge]+(shifted[(edge+1)%n]-shifted[edge])*((distance-cumulative[edge])/len);
            double lateral=jitter.range({0.0,band.edgeAcrossJitter});
            p=p-loop.out[edge]*lateral;
            // Keep base jitter on the surface; local offset is applied later.
            bool inside=false;double clearance=INFINITY;
            for(const auto& other:loops) {inside^=loopInside(p,other.points,other.normal);for(std::size_t e=0;e<other.points.size();++e)clearance=std::min(clearance,segmentDistance(p,other.points[e],other.points[(e+1)%other.points.size()]));}
            if(inside||clearance<1e-6)result.push_back(p);
        }
    }
    return result;
}
Settings prepareEdgeRows(const Settings& s){
    Settings out=s;
    for(std::size_t i=0;i<out.lineBands.size();++i){auto& b=out.lineBands[i];if(b.kind==6){auto points=edgeBorderPoints(b,s.seed^static_cast<std::uint32_t>(i*2654435761u));b.kind=5;b.boundary.loops={std::move(points)};}}
    return out;
}

