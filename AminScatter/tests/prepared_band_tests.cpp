// Differential access to the private original predicate and prepared predicate.
// This TU supplies scatter definitions; the static library supplies execution.
#include "../src/scatter.cpp"
#include <iostream>
int main() {
    try {
        std::mt19937 random(917);
        const auto number=[&] {return static_cast<double>(random())/4294967296.0;};
        for(int variant=0;variant<8;++variant) for(int kind:{1,2}) for(bool straight:{false,true}) {
            amin::LineBand band;band.kind=kind;band.start=3;band.width=30;band.straightEnds=straight;
            band.boundary.loops={{{-100,-80,0},{140,-80,0},{140,120,0},{-100,120,0}},
                                 {{-20,-10,0},{-20,40,0},{40,40,0},{40,-10,0}}};
            if(variant==1) band.boundary.loops.push_back({{-100,-80,10},{140,-80,10},{140,120,10},{-100,120,10}});
            if(variant==2) for(auto& path:band.boundary.loops) for(auto& p:path) p.z=p.y*.3;
            if(variant==3) band.boundary.loops.push_back({{0,0,0},{1,0,0},{2,0,0}});
            if(variant==4) {band.boundaryMask={true,false,true};}
            if(variant==5) {band.boundary.loops[0].insert(band.boundary.loops[0].begin()+1,band.boundary.loops[0][0]);}
            if(variant==6) {band.boundary.loops.insert(band.boundary.loops.begin(),std::vector<amin::Vec3>{});}
            if(variant==7) {band.start=0;band.width=1e-8;}
            amin::PreparedAnalyzerBand prepared(band);
            for(int sample=0;sample<5000;++sample) {
                amin::Vec3 p{-150+350*number(),-120+300*number(),0};
                if(variant==2) p.z=p.y*.3;
                if(variant==1 && sample%2) p.z=10;
                if(sample%13==0) p.z+=.0001000000001;
                const double tolerance=sample%7==0?1e-5:0;
                if(amin::analyzerBand(p,band,tolerance)!=prepared.contains(p,tolerance))
                    throw std::runtime_error("Prepared band changed a boundary query");
            }
            for(const auto& path:band.boundary.loops) for(auto p:path)
                if(amin::analyzerBand(p,band)!=prepared.contains(p)) throw std::runtime_error("Prepared band changed vertex threshold");
        }
        std::cout<<"PASS 160000 differential boundary queries, masks, holes, tilted/stacked paths, duplicate vertices and thresholds\n";
    } catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;}
}
