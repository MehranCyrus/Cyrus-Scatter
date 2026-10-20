#include "cyrus_arrange/document_state.h"
#include "cyrus_arrange/placement_queries.h"
#include "cyrus_arrange/geometry_cache.h"
#include <iostream>
#include <stdexcept>
using namespace cyrus::arrange;
namespace {
std::size_t checks{};
void check(bool v,const char* text){++checks;if(!v)throw std::runtime_error(text);}
template<class F>void rejects(F f,const char* text){bool threw=false;try{f();}catch(const std::exception&){threw=true;}check(threw,text);}
void roundtrip_and_corruption(){
    host::DocumentState s;s.document_id="{12345678-1234-1234-1234-123456789abc}";s.arrangement.amount_mode=AmountMode::Quantity;s.arrangement.quantity=3;s.path=host::PathLayout{};
    auto& p=*s.path;p.curve_index=2;p.lane_count=2;p.lanes[0].id=11;p.lanes[1].id=12;p.lanes[0].quantity=3;p.settings.source_forward_degrees=37.5;p.settings.lateral_jitter_mm=300;p.settings.longitudinal_jitter_mm=500;p.lanes[0].offset_mm=1750;p.lanes[0].limit_width=true;p.lanes[1].quantity=4;
    const auto bytes=host::encode_document_state(s,1);std::uint64_t high=1;const auto saved=host::decode_document_state(bytes,high);
    check(bytes[4]==7&&saved->path.has_value(),"Schema7 explicitly persists a typed path");
    check(saved->path->curve_index==2&&saved->path->lane_count==2&&saved->path->lanes[1].quantity==4&&saved->path->lanes[0].quantity==3,"Both quantities and selected curve survive roundtrip");
    check(saved->path->settings.source_forward_degrees==37.5&&saved->path->settings.lateral_jitter_mm==300&&saved->path->settings.longitudinal_jitter_mm==500,"Direction and local variation survive roundtrip");
    check(high==13,"Lane IDs contribute to recovered monotonic high-water");check(host::encode_document_state(*saved,1)==bytes,"Schema7 payload is byte deterministic");
    auto plain=s;plain.path.reset();auto old=host::encode_document_state(plain,1);const auto start=old.size()-9;
    check(bytes.size()==start+146&&bytes[start]==1,"Path footer has the specified bounded size");old.resize(old.size()-9);old[4]=5;const auto legacy=host::decode_document_state(old,high);check(!legacy->path&&legacy->arrangement.quantity==3,"Existing schema5 receives no invented path");
    const auto invalid=[&](std::size_t offset,std::uint8_t value){auto bad=bytes;bad[offset]=value;std::uint64_t retained=99;rejects([&]{host::decode_document_state(bad,retained);},"Corrupt typed path payload must reject");check(retained==99,"Failed typed path decode retains caller high-water");};
    invalid(start,2);invalid(start+5,3);invalid(start+9,99);invalid(start+13,2);invalid(start+66,4);invalid(start+100,11);
    auto cut=bytes;cut.pop_back();rejects([&]{host::decode_document_state(cut,high);},"Truncated path payload rejected");cut=bytes;cut.push_back(0);rejects([&]{host::decode_document_state(cut,high);},"Trailing path payload rejected");
    auto mismatch=s;mismatch.path->lanes[0].quantity=1;rejects([&]{host::validate_document_state(mismatch);},"Main and first-lane quantities cannot disagree");
    mismatch=s;mismatch.path->lanes[1].id=mismatch.path->lanes[0].id;rejects([&]{host::validate_document_state(mismatch);},"Lane IDs cannot alias");mismatch=s;mismatch.path->lanes[1].quantity=2000;rejects([&]{host::validate_document_state(mismatch);},"Combined lane target respects output admission");
}
void collision_only_query(){
    QuerySettings q;q.require_support=false;q.require_front_access=false;FurniturePlacementQuery empty({},q);
    const std::vector<Vec3> footprint{{-1,-1,0},{1,-1,0},{1,1,0},{-1,1,0}};PlacementProbe probe{footprint,{{0,0,5},{1,1,5},0},0,1,{},0,{},0,0,10000};
    check(empty.validate(probe).reason==Rejection::None,"Authored path height does not invent a supporting mesh");
    const std::vector<PlacedObstacle> other{{4,{{0,0,5},{1,1,5},0},0}};probe.accepted=other;check(empty.validate(probe).reason==Rejection::Obstacle,"Collision-only mode still validates generated output collisions");
    QuerySettings ordinary;rejects([&]{FurniturePlacementQuery invalid({},ordinary);},"Ordinary surface mode cannot silently lose required support");
    check(cache::QueryKey::from(q)!=cache::QueryKey::from(ordinary),"Physical support mode participates in the exact cache key");
}
}
int main(){try{roundtrip_and_corruption();collision_only_query();std::cout<<checks<<" path persistence/query checks passed\n";return 0;}catch(const std::exception& e){std::cerr<<"FAIL after "<<checks<<": "<<e.what()<<'\n';return 1;}}
