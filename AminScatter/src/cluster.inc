// Included in scatter.cpp's private namespace after valueNoise/weightedIndex.
// Query arithmetic and site visitation order match the original implementation.
struct ClusterField { std::size_t first{}, second{}; double edgeChance{}; };
// Both paths share the same field arithmetic. Select the immutable weighting
// mode once rather than checking it at every site. Serial returns its final
// group directly, avoiding a temporary field between two calls per placement.
template<bool fieldOnly,bool uniformGroups>
auto clusterQuery(Vec3 p,const Settings& s,std::size_t groups,
                  const std::vector<double>& groupCDF,Random* rng) {
    p=p*(1.0/(s.distribution==1?s.clusterRadius:s.clusterSize));
    if(!finite(p)||std::abs(p.x)>1e8||std::abs(p.y)>1e8||std::abs(p.z)>1e8)
        throw std::invalid_argument("Cluster size too small for world coordinates");
    const Vec3 q=p*2;
    p=p+Vec3{valueNoise(q,s.clusterSeed)-0.5,valueNoise(q,s.clusterSeed+1)-0.5,valueNoise(q,s.clusterSeed+2)-0.5}*(s.clusterRoughness*1.5);
    const int x=static_cast<int>(std::floor(p.x)),y=static_cast<int>(std::floor(p.y)),z=static_cast<int>(std::floor(p.z));
    double first=std::numeric_limits<double>::infinity(),second=first;
    std::size_t a=0,b=0;
    for(int dz=-1;dz<=1;++dz) for(int dy=-1;dy<=1;++dy) for(int dx=-1;dx<=1;++dx) {
        const auto h=cellHash(x+dx,y+dy,z+dz,s.clusterSeed);
        const Vec3 site{x+dx+0.25+0.5*hashUnit(h),y+dy+0.25+0.5*hashUnit(h+1),z+dz+0.25+0.5*hashUnit(h+2)};
        const double d=length(p-site);
        std::size_t group;
        if constexpr(uniformGroups) group=mix(h+3)%groups;
        else group=weightedIndex(groupCDF,hashUnit(h+3));
        if(d<first) {second=first;b=a;first=d;a=group;}
        else if(d<second) {second=d;b=group;}
    }
    const double edgeChance=s.clusterBlur>0?0.5*std::max(0.0,1-(second-first)/s.clusterBlur):0;
    if constexpr(fieldOnly) return ClusterField{a,b,edgeChance};
    else {
        if(rng->next()<edgeChance) a=b;
        if(rng->next()<s.clusterNoise) {
            const double u=rng->next();
            if constexpr(uniformGroups) a=static_cast<std::size_t>(u*groups);
            else a=weightedIndex(groupCDF,u);
        }
        return a;
    }
}
class ClusterQueries {
    const Settings& settings;
    std::size_t groups;
    const std::vector<double>& groupCDF;
public:
    std::uint64_t queries{};
    ClusterQueries(const Settings& s,std::size_t count,const std::vector<double>& cdf)
        :settings(s),groups(count),groupCDF(cdf) {}
    ClusterField field(Vec3 p) {
        ++queries;
        return groupCDF.empty()?clusterQuery<true,true>(p,settings,groups,groupCDF,nullptr):
            clusterQuery<true,false>(p,settings,groups,groupCDF,nullptr);
    }
    std::size_t group(Vec3 p,Random& rng) {
        ++queries;
        return groupCDF.empty()?clusterQuery<false,true>(p,settings,groups,groupCDF,&rng):
            clusterQuery<false,false>(p,settings,groups,groupCDF,&rng);
    }
};
std::size_t diversityGroup(const ClusterField& field,const Settings& s,std::size_t groups,
                          Random& rng,const std::vector<double>& groupCDF) {
    auto a=field.first;
    // Both draws occur even at zero blur/noise, preserving all later assignments.
    if(rng.next()<field.edgeChance) a=field.second;
    if(rng.next()<s.clusterNoise) {const double u=rng.next();a=groupCDF.empty()?static_cast<std::size_t>(u*groups):weightedIndex(groupCDF,u);}
    return a;
}
