#include "cyrus_arrange/placement_queries.h"
#include <bit>
#include <array>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <limits>
#include <map>
#include <sstream>
#include <stdexcept>
#include <set>

using namespace cyrus::arrange;
namespace {
Mesh box(double x,double y,double z) {
    Mesh m;m.vertices={{-x/2,-y/2,0},{x/2,-y/2,0},{x/2,y/2,0},{-x/2,y/2,0},
        {-x/2,-y/2,z},{x/2,-y/2,z},{x/2,y/2,z},{-x/2,y/2,z}};
    m.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},
        {{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};return m;
}
Asset item(std::uint64_t id,AssetCategory category,bool stack=false) {
    Asset a;a.id=id;a.name="Golden fixture";a.category=category;a.mesh=box(40,35,10);a.allowed_yaws_degrees={0,90,180,270};
    a.min_scale=.9;a.max_scale=1.1;a.stackable=stack;
    if(stack){a.stack_height_mm=10;a.allowed_on_top=all_asset_mask;a.stack_footprint={{-20,-17.5,10},{20,-17.5,10},{20,17.5,10},{-20,17.5,10}};}
    return prepare_asset(std::move(a));
}
Region surface(std::uint32_t id,double offset=0) {
    Region r;r.id=id;r.bounds={{offset-200,-150,0},{offset+200,150,0}};r.sampled_area_mm2=r.usable_area_mm2=120000;
    r.open_above=true;r.minimum_clearance_mm=std::numeric_limits<double>::infinity();
    for(int x=0;x<16;++x)for(int y=0;y<12;++y)r.cells.push_back({{offset-187.5+25*x,-137.5+25*y,0},r.minimum_clearance_mm,true});return r;
}
struct Accept final:PlacementQuery {QueryResult validate(const PlacementProbe& p)const override{return {Rejection::None,1+p.footprint_world.size()};}};
struct Reject final:PlacementQuery {QueryResult validate(const PlacementProbe&)const override{return {Rejection::Obstacle,3};}};
void write(std::ostream& out,const char* name,const ArrangementResult& r) {
    out<<name<<'\n'<<std::hex;
    const auto& s=r.stats;out<<s.requested<<' '<<s.accepted<<' '<<s.kept<<' '<<s.candidates<<' '<<s.underfilled<<' '<<s.work<<'\n';
    for(auto n:s.rejections)out<<n<<' ';out<<'\n';
    for(const auto& p:r.placements){out<<p.stable_id<<' '<<p.asset_id<<' '<<p.parent_stack_id<<' '<<p.region_id<<' ';
        for(double d:{p.position.x,p.position.y,p.position.z,p.yaw_degrees,p.scale})out<<std::bit_cast<std::uint64_t>(d)<<' ';
        out<<p.locked<<'\n';}
    for(const auto& w:r.warnings)out<<w<<'\n';out<<"END\n";
}
std::string capture() {
    std::ostringstream out;Accept yes;Reject no;std::vector<Asset> assets{item(3,AssetCategory::Plant),item(1,AssetCategory::Book,true),item(2,AssetCategory::Candle)};
    std::vector<Region> regions{surface(7,600),surface(2)};ArrangeSettings s;s.seed=0xfedcba9876543210ULL;s.density=.12;s.empty_space=.2;s.spacing_mm=10;
    s.edge_clearance_mm=5;s.cluster_strength=.45;s.category=FurnitureCategory::OpenShelf;
    const auto basic=arrange({regions,assets},s,yes);write(out,"open-shelf",basic);
    s.style=ArrangeStyle::Layered;s.cluster_strength=1;s.height_variation=1;write(out,"layered",arrange({regions,assets},s,yes));
    auto previous=basic.placements;previous.front().locked=true;std::vector<std::uint32_t> chosen{2};s.seed=71;
    write(out,"locked-selective",arrange({regions,assets,previous,{},chosen},s,yes));
    s.category=FurnitureCategory::TVConsole;s.style=ArrangeStyle::Minimal;write(out,"tv",arrange({regions,assets},s,yes));
    write(out,"refused",arrange({regions,assets},s,no));
    auto support=box(400,300,20);for(auto& v:support.vertices)v.z-=20;std::vector<FurnitureBody> bodies{{9,std::move(support)}};
    QuerySettings qs;qs.require_front_access=false;FurniturePlacementQuery geometry(bodies,qs);regions={surface(2)};
    s.seed=11;s.style=ArrangeStyle::Balanced;s.cluster_strength=0;s.density=.1;
    write(out,"real-query",arrange({regions,assets},s,geometry));return out.str();
}
struct Snapshot {
    std::string name;
    std::array<std::uint64_t,6> stats{};
    std::array<std::uint64_t,7> rejections{};
    std::map<std::uint64_t,std::string> poses;
    std::vector<std::uint64_t> pose_order;
    std::vector<std::string> warnings;
};
std::vector<Snapshot> snapshots(const std::string& text) {
    std::istringstream input(text);std::vector<Snapshot> out;std::string line;
    while(std::getline(input,line)) {
        Snapshot s;s.name=line;
        if(!std::getline(input,line))throw std::runtime_error("Missing golden stats");
        std::istringstream stats(line);stats>>std::hex;for(auto& n:s.stats)if(!(stats>>n))throw std::runtime_error("Invalid golden stats");
        if(!std::getline(input,line))throw std::runtime_error("Missing golden rejections");
        std::istringstream rejections(line);rejections>>std::hex;for(auto& n:s.rejections)if(!(rejections>>n))throw std::runtime_error("Invalid golden rejections");
        bool ended=false;
        while(std::getline(input,line)) {
            if(line=="END"){ended=true;break;}
            std::istringstream row(line);std::array<std::uint64_t,10> fields{};row>>std::hex;bool pose=true;
            for(auto& value:fields)if(!(row>>value)){pose=false;break;}
            if(pose){if(!s.poses.emplace(fields[0],line).second)throw std::runtime_error("Duplicate golden placement");s.pose_order.push_back(fields[0]);}
            else s.warnings.push_back(line);
        }
        if(!ended)throw std::runtime_error("Unterminated golden scenario");out.push_back(std::move(s));
    }
    return out;
}
bool sampled_xy_member(const std::string& pose) {
    std::istringstream row(pose);std::array<std::uint64_t,10> f{};row>>std::hex;for(auto& n:f)row>>n;
    const double x=std::bit_cast<double>(f[4]),y=std::bit_cast<double>(f[5]);
    return (f[3]==2||f[3]==7)&&std::abs(x-(f[3]==7?600:0))<=200.01&&std::abs(y)<=150.01;
}

}
int main(int argc,char** argv) {try{
    const auto actual=capture();if(argc==2&&std::string(argv[1])=="--dump"){std::cout<<actual;return 0;}
    const auto path=std::filesystem::path(__FILE__).parent_path()/"data"/"geometry_feedback_032.golden";
    std::ifstream in(path,std::ios::binary);if(!in)throw std::runtime_error("Cannot read reviewed compound-collider baseline golden");std::ostringstream expected;expected<<in.rdbuf();
    if(actual!=expected.str())throw std::runtime_error("Geometry-driven baseline changed; review intent and physical witnesses before replacing it");
    const auto cases=snapshots(actual);const std::array<std::uint64_t,6> targets{12,14,13,6,6,5};
    if(cases.size()!=6)throw std::runtime_error("Expected six geometry-driven scenarios");
    for(std::size_t i=0;i<cases.size();++i){if(cases[i].stats[0]!=targets[i])throw std::runtime_error("Independent analytical target changed");
        for(const auto& entry:cases[i].poses)if(!sampled_xy_member(entry.second))throw std::runtime_error("Candidate anchor left its selected region");}
    if(capture()!=actual)throw std::runtime_error("Corrected six-scenario output is not bit-deterministic on repeat");
    std::cout<<"PASS six reviewed geometry-driven scenarios: exact deterministic output and independent analytical targets verified\n";return 0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
