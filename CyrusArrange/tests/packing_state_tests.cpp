#include "cyrus_arrange/document_state.h"
#include <iostream>
#include <stdexcept>
using namespace cyrus::arrange;
namespace {
std::size_t checks{};
void check(bool value,const char* message){++checks;if(!value)throw std::runtime_error(message);}
template<class F>void rejects(F action,const char* message){bool failed=false;try{action();}catch(const std::exception&){failed=true;}check(failed,message);}
host::DocumentState fixture(){host::DocumentState state;state.document_id="{12345678-1234-1234-1234-123456789abc}";Asset a;a.id=10;a.name="Required device";a.mesh.vertices={{-1,-1,0},{1,-1,0},{1,1,0},{-1,1,0},{-1,-1,2},{1,-1,2},{1,1,2},{-1,1,2}};a.mesh.triangles={{{0,2,1}},{{0,3,2}},{{4,5,6}},{{4,6,7}},{{0,1,5}},{{0,5,4}},{{1,2,6}},{{1,6,5}},{{2,3,7}},{{2,7,6}},{{3,0,4}},{{3,4,7}}};state.assets.push_back(prepare_asset(a));state.asset_capture.push_back({});state.arrangement.amount_mode=AmountMode::Quantity;state.arrangement.quantity=10;state.minimums={{10,4}};return state;}
void put(std::vector<std::uint8_t>& bytes,std::size_t at,std::uint64_t value){for(unsigned i=0;i<8;++i)bytes.at(at+i)=static_cast<std::uint8_t>(value>>(8*i));}
void run(){
    auto state=fixture();const auto bytes=host::encode_document_state(state,1);std::uint64_t high=77;const auto saved=host::decode_document_state(bytes,high);
    check(bytes[4]==7&&saved->minimums.size()==1&&saved->minimums[0].asset_id==10&&saved->minimums[0].quantity==4,"Schema7 retains exact per-source minimums");check(high==11,"Minimum references do not invent new monotonic identities");check(host::encode_document_state(*saved,1)==bytes,"Minimum codec is byte deterministic");
    auto earlier=bytes;earlier.resize(earlier.size()-24);earlier[4]=6;const auto old=host::decode_document_state(earlier,high);check(old->minimums.empty()&&old->assets.size()==1&&old->arrangement.quantity==10,"Development schema6 retains its exact fields with no invented minimums");
    const auto start=bytes.size()-24;
    for(auto [offset,value]:{std::pair{start,std::uint64_t{257}},std::pair{start+8,std::uint64_t{99}},std::pair{start+16,std::uint64_t{0}},std::pair{start+16,std::uint64_t{11}},std::pair{start+16,std::uint64_t{10001}}}){auto bad=bytes;put(bad,offset,value);high=77;rejects([&]{host::decode_document_state(bad,high);},"Malformed minimum count or source must reject");check(high==77,"Failed minimum decode cannot advance caller high-water");}
    for(std::size_t n=start;n<bytes.size();++n){auto cut=bytes;cut.resize(n);high=77;rejects([&]{host::decode_document_state(cut,high);},"Truncated minimum payload rejects");check(high==77,"Truncation cannot alter high-water");}
    auto duplicate=state;duplicate.minimums={{10,2},{10,3}};rejects([&]{host::validate_document_state(duplicate);},"Duplicate minimum source IDs reject");auto unknown=state;unknown.minimums={{99,1}};rejects([&]{host::validate_document_state(unknown);},"Minimum cannot outlive a removed source");
    state.path=host::PathLayout{};state.path->lane_count=2;state.arrangement.quantity=3;state.path->lanes[0].quantity=3;host::validate_document_state(state);check(true,"Path minimums are admitted against both lane quantities");state.minimums[0].quantity=7;rejects([&]{host::validate_document_state(state);},"Minimum cannot exceed combined two-way quantity");
    auto legacy=fixture();legacy.minimums.clear();legacy.composition.book_rows=true;const auto legacy_bytes=host::encode_document_state(legacy,1);
    high=0;const auto legacy_loaded=host::decode_document_state(legacy_bytes,high);check(legacy_loaded->composition.book_rows&&legacy_loaded->minimums.empty()&&host::encode_document_state(*legacy_loaded,1)==legacy_bytes,"Loading legacy mode alone does not silently rewrite saved settings");
    auto staged=*legacy_loaded;staged.minimums={{10,5}};rejects([&]{host::validate_document_state(staged);},"Raw row/minimum conflict remains strict rather than admitting ignored requirements");
    check(host::encode_document_state(legacy,1)==legacy_bytes,"Rejected successor validation leaves the encoded predecessor untouched");
    staged.composition.book_rows=false;const auto ordinary_bytes=host::encode_document_state(staged,1);high=0;const auto ordinary=host::decode_document_state(ordinary_bytes,high);
    check(!ordinary->composition.book_rows&&ordinary->minimums.size()==1&&ordinary->minimums[0].quantity==5&&host::encode_document_state(*ordinary,1)==ordinary_bytes,"Existing schema round-trips explicitly selected ordinary mode and required copies");
}
}
int main(){try{run();std::cout<<checks<<" minimum persistence/admission checks passed\n";return 0;}catch(const std::exception& e){std::cerr<<"FAIL after "<<checks<<": "<<e.what()<<'\n';return 1;}}
