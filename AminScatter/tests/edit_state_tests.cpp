// Actual Edit data/reconciliation/storage bodies with small host value and I/O
// doubles. Real .7 scene migration and SDK gestures remain owned-host checks.
#include "edit_blocks.h"
#include "edit_binding.h"
#include "placement_store.h"
#include "receiver_plan.h"
#include <algorithm>
#include <array>
#include <climits>
#include <cmath>
#include <cstring>
#include <iostream>
#include <map>
#include <optional>
#include <string_view>
#include <unordered_map>
#include <unordered_set>

struct Point3 {
    float x=0,y=0,z=0;Point3()=default;Point3(float a,float b,float c):x(a),y(b),z(c){}
    float& operator[](int i){return (&x)[i];}float operator[](int i)const{return (&x)[i];}
    bool operator==(const Point3& b)const{return x==b.x&&y==b.y&&z==b.z;}bool operator!=(const Point3& b)const{return !(*this==b);}
};
struct Matrix3 {
    std::array<Point3,4> rows{};explicit Matrix3(int identity=0){if(identity){rows[0].x=1;rows[1].y=1;rows[2].z=1;}}
    Point3 GetRow(int i)const{return rows.at(i);}void SetRow(int i,Point3 p){rows.at(i)=p;}Point3 GetTrans()const{return rows[3];}
    void SetTrans(Point3 p){rows[3]=p;}
};
static Matrix3 operator*(const Matrix3& a,const Matrix3& b){Matrix3 result;for(int i=0;i<4;++i)for(int j=0;j<3;++j){result.rows[i][j]=i==3?b.rows[3][j]:0;for(int k=0;k<3;++k)result.rows[i][j]+=a.rows[i][k]*b.rows[k][j];}return result;}
static bool hasEditTransform(const Matrix3& a){Matrix3 identity(1);return a.rows!=identity.rows;}
static bool finiteEditMatrix(const Matrix3& a){for(const auto& row:a.rows)for(int j=0;j<3;++j)if(!std::isfinite(row[j]))return false;return true;}
// Fixtures here use ASCII identities. Production uses strict Windows UTF-8
// conversion, whose Unicode path is independently covered by binding tests.
static std::string receiverUTF8(const std::wstring& value){return {value.begin(),value.end()};}
static std::wstring receiverWide(const std::string& value){return {value.begin(),value.end()};}
#include "../src/cyrus_edit_data.inc"
#include "../src/cyrus_edit_binding.inc"

using ULONG=unsigned long;
enum IOResult {IO_OK,IO_ERROR,IO_END};
struct Chunk {unsigned id=0;std::vector<char> bytes;};
struct ISave {
    std::vector<Chunk> chunks;
    void BeginChunk(unsigned id){chunks.push_back({id,{}});}void EndChunk(){}
    IOResult Write(const char* p,ULONG n,ULONG* done){chunks.back().bytes.insert(chunks.back().bytes.end(),p,p+n);*done=n;return IO_OK;}
};
struct ILoad {
    const std::vector<Chunk>& chunks;int at=-1;std::size_t cursor=0;explicit ILoad(const std::vector<Chunk>& source):chunks(source){}
    IOResult OpenChunk(){cursor=0;return ++at<int(chunks.size())?IO_OK:IO_END;}void CloseChunk(){}
    unsigned CurChunkID()const{return chunks.at(at).id;}std::size_t CurChunkLength()const{return chunks.at(at).bytes.size();}
    IOResult Read(char* p,ULONG n,ULONG* done){const auto& bytes=chunks.at(at).bytes;if(n>bytes.size()-cursor){*done=0;return IO_ERROR;}std::memcpy(p,bytes.data()+cursor,n);cursor+=n;*done=n;return IO_OK;}
};
struct CSEdit {std::map<int,EditLayer> layers;IOResult Save(ISave*);IOResult Load(ILoad*);};
#include "../src/cyrus_edit_storage.inc"

namespace {
unsigned checks=0;
void check(bool result,const char* message){++checks;if(!result)throw std::runtime_error(message);}
template<class F>void rejects(F&& f,const char* message){bool caught=false;try{f();}catch(const std::exception&){caught=true;}check(caught,message);}
const std::string receiver="\nCyrusReceivers2\nreceiver=geometry\n";
std::string legacy(const std::string& sources="A|B"){return "CyrusBinding2:17|"+sources+"|"+receiver;}
std::wstring binding(const std::vector<std::string>& sources={"A","B"},const std::string& seed="17"){
    std::vector<cyrus::editbinding::SourceSpec> specs;std::string names;
    for(const auto& id:sources){if(!names.empty())names+='|';names+=id;specs.push_back({id,"scale:1;weight:1"});}
    return receiverWide(cyrus::editbinding::make(legacy(names),"CyrusBinding2:"+seed+"|Owner:L|"+receiver,specs));
}
ep::View input(const std::vector<std::string>& sources,const std::vector<std::pair<unsigned,unsigned>>& rows){
    const auto owner=ep::newOwner();std::vector<ep::SourceBinding> sourceIDs;for(unsigned i=0;i<sources.size();++i)sourceIDs.push_back({sources[i],i+1,ep::RenderSource});
    if(sourceIDs.empty())sourceIDs.push_back({"unassigned:1",0,ep::PointSource});
    const auto cohort=ep::SourceCohort::create(owner,"L",sourceIDs);ep::Builder builder(owner,ep::Stage::Edited,unsigned(sourceIDs.size()),rows.size(),cohort);
    for(const auto& [id,source]:rows){ep::Record row;row.identity=id;row.source=source;row.transform={1,0,0,0,1,0,0,0,1,float(id),0,0};builder.appendGenerated(row);}return builder.freeze();
}
ep::View four(){return input({"A","B"},{{10,1},{20,2},{30,1},{40,2}});}
unsigned find(const EditLayer& layer,unsigned id,const std::wstring& source){for(unsigned i=0;i<layer.rows.size();++i){const auto& row=layer.rows.get(i);if(row.inputId==EditKey(id)&&row.inputId==row.outputId&&row.lineage&&layer.lineages->ids.at(row.lineage-1)==EditText(source.begin(),source.end()))return i;}throw std::runtime_error("Missing fixture variant");}
void move(EditLayer& layer,unsigned row,float x){auto m=layer.rows.get(row).delta;m.SetTrans({x,0,0});layer.rows.write(row).delta=m;}
std::shared_ptr<const EditPresentation> publication(const EditLayer& layer){
    const auto& view=*layer.input->native;ep::Builder output(view.token().owner,ep::Stage::Edited,view.sources(),view.size(),view.sourceCohort());
    for(auto index:activeEditOrder(layer)){const auto& saved=layer.rows.get(index);auto row=view.at(layer.source(saved));const auto matrix=layer.matrix(saved);for(int r=0;r<4;++r)for(int c=0;c<3;++c)row.transform[r*3+c]=matrix.GetRow(r)[c];
        if(saved.outputId.authored)output.appendAuthored(row,receiverUTF8(saved.outputId.text()));else{row.identity=saved.outputId.candidate;output.appendGenerated(row);}}
    auto result=ce::make<EditPresentation>();result->final=nativeEditInput(output.freeze());return result;
}
void equalRows(const EditLayer& a,const EditLayer& b){
    check(a.signature==b.signature&&a.legacyProof==b.legacyProof&&a.sourceAware==b.sourceAware&&a.rows.size()==b.rows.size()&&a.nextOrder==b.nextOrder,"Storage preserves binding and extent");
    for(std::size_t i=0;i<a.rows.size();++i){const auto& x=a.rows.get(i);const auto& y=b.rows.get(i);check(x.inputId==y.inputId&&x.outputId==y.outputId&&x.lineage==y.lineage&&x.order==y.order&&x.deleted==y.deleted&&x.delta.rows==y.delta.rows&&a.selection.get(i)==b.selection.get(i),"Storage preserves authored source variant exactly");}
}
void historyAndFeedback(){
    EditLayer layer;bindStable(layer,binding(),nativeEditInput(four()));move(layer,0,3);move(layer,1,7);layer.rows.write(2).deleted=true;layer.selection.set(0,true);
    auto clone=layer.rows.get(0);clone.outputId=EditKey(L"copy-A");clone.order=layer.allocateOrder();layer.append(clone);
    const auto original=layer;const auto oldPublication=publication(layer);const auto before=ce::memory();auto authored=editAuthoredState({{7,layer}});
    check(ce::memory().allocations==before.allocations,"Authored snapshot shares COW blocks and bounded lineage table");
    check(!authored.at(7).input&&!authored.at(7).presentation,"Undo excludes derived native views and presentation");
    bindStable(layer,binding({"B"}),nativeEditInput(input({"B"},{{10,1},{20,1},{30,1},{40,1}})));
    const auto replacement=find(layer,10,L"B"),survivor=find(layer,20,L"B");
    check(layer.source(layer.rows.get(0))==UINT_MAX&&layer.rows.get(0).delta.GetTrans().x==3,"Removed source move remains dormant and intact");
    check(!hasEditTransform(layer.rows.get(replacement).delta)&&!layer.rows.get(replacement).deleted,"Replacement model starts untouched");
    check(layer.source(layer.rows.get(survivor))==1&&layer.rows.get(survivor).delta.GetTrans().x==7,"Surviving candidate and source retain their move");
    check(activeEditOrder(layer).size()==4&&layer.selection.get(0),"Removed delete and clone do not affect replacement; selection retained");
    layer.presentation=publication(layer);layer.published=true;layer.rendererManaged=true;layer.displayedPresentation=oldPublication;
    check(layer.shown(layer.rows.get(0))&&!layer.shown(layer.rows.get(replacement))&&layer.feedbackPending(),"Late renderer failure keeps old source feedback and blocks mismatched authoring");
    check(layer.displayMatrix(layer.rows.get(0)).GetTrans().x==13,"Shown position uses old final matrix, not rebound candidate ordinal");
    layer.displayedPresentation=layer.presentation;check(!layer.shown(layer.rows.get(0))&&layer.shown(layer.rows.get(replacement))&&!layer.feedbackPending(),"Host commit atomically selects replacement feedback");
    const auto absent=layer;bindStable(layer,binding({}),nativeEditInput(input({},{})));check(activeEditOrder(layer).empty()&&layer.hasAuthored(),"Empty source inventory suspends without pruning");
    bindStable(layer,binding(),nativeEditInput(four()));const auto order=activeEditOrder(layer);
    check(order.size()==4&&layer.rows.get(order[0]).outputId==EditKey(10)&&layer.rows.get(order[1]).outputId==EditKey(20)&&layer.rows.get(order[2]).outputId==EditKey(40)&&layer.rows.get(order[3]).outputId==EditKey(L"copy-A"),"Restored source recovers deterministic base/clone order and deletion");
    check(layer.rows.get(0).delta.rows==original.rows.get(0).delta.rows,"Restored source recovers exact authored delta");
    const auto safe=layer;rejects([&]{bindStable(layer,binding({"A","B"},"18"),nativeEditInput(four()));},"Seed remains guarded");check(layer.signature==safe.signature&&layer.input==safe.input,"Failed bind retains complete previous maps");
    auto restored=editRestoreState(authored,{{7,absent}});check(restored.at(7).rows.size()==original.rows.size()&&restored.at(7).input==absent.input,"Undo restores authored rows while sharing current derived publication");
    CSEdit saved;saved.layers.emplace(7,absent);ISave stream;check(saved.Save(&stream)==IO_OK,"Save absent source history");
    unsigned sentinel=0;std::memcpy(&sentinel,stream.chunks.at(0).bytes.data(),sizeof(sentinel));check(stream.chunks[0].id==0x7301&&sentinel>1000,"Recognized old chunk refuses downgrade before extension can be ignored");
    CSEdit loaded;ILoad load(stream.chunks);check(loaded.Load(&load)==IO_OK,"Versioned source history load");equalRows(absent,loaded.layers.at(7));
    bindStable(loaded.layers.at(7),binding(),nativeEditInput(four()));check(activeEditOrder(loaded.layers.at(7)).size()==4,"Saved inactive history recovers original source");
    auto bad=stream.chunks;unsigned future=4;std::memcpy(bad[1].bytes.data(),&future,sizeof(future));ILoad futureLoad(bad);const auto old=loaded.layers.at(7);check(loaded.Load(&futureLoad)==IO_ERROR,"Unknown storage version rejected");equalRows(old,loaded.layers.at(7));
    bad=stream.chunks;bad[1].bytes.pop_back();ILoad truncated(bad);check(loaded.Load(&truncated)==IO_ERROR,"Truncated storage rejected atomically");equalRows(old,loaded.layers.at(7));
}
void corruptSavedOrder(ISave& stream,unsigned row,std::uint64_t order){
    // Locate the order field in one valid production-written layer. Mutating
    // only that field exercises the real load validator and atomic install.
    auto& bytes=stream.chunks.at(1).bytes;std::size_t at=0;
    const auto skip=[&](std::size_t n){if(at>bytes.size()||n>bytes.size()-at)throw std::runtime_error("Invalid order fixture extent");at+=n;};
    const auto number=[&](){unsigned value=0;const auto start=at;skip(sizeof(value));std::memcpy(&value,bytes.data()+start,sizeof(value));return value;};
    const auto text=[&](){const auto n=number();skip(n);};
    if(number()!=editStorageVersion||number()!=1)throw std::runtime_error("Expected one source-aware fixture layer");
    skip(sizeof(int));text();text();skip(3*sizeof(std::uint8_t)+sizeof(std::uint64_t));
    const auto sources=number();for(unsigned i=0;i<sources;++i)text();
    const auto rows=number();if(row>=rows)throw std::runtime_error("Missing order fixture row");
    for(unsigned i=0;i<rows;++i){skip(2*sizeof(unsigned));const auto position=at;skip(sizeof(std::uint64_t));
        if(i==row)std::memcpy(bytes.data()+position,&order,sizeof(order));
        skip(12*sizeof(float)+3*sizeof(std::uint8_t));text();text();}
}
void orderSafety(){
    EditLayer layer;bindStable(layer,binding(),nativeEditInput(four()));move(layer,0,2);
    bindStable(layer,binding({"B"}),nativeEditInput(input({"B"},{{10,1},{20,1},{30,1},{40,1}})));
    const auto variant=find(layer,10,L"B");
    check(layer.rows.get(0).order==layer.rows.get(variant).order,"Dormant source variants keep one stable output order");
    CSEdit saved;saved.layers.emplace(7,layer);ISave valid;check(saved.Save(&valid)==IO_OK,"Valid shared variant order saves");
    CSEdit loaded;ILoad good(valid.chunks);check(loaded.Load(&good)==IO_OK,"Valid shared variant order loads");
    // Leave order->identity unambiguous, but give one identity two orders.
    const auto newOrder=layer.allocateOrder();
    saved.layers.at(7).nextOrder=layer.nextOrder;ISave malformed;check(saved.Save(&malformed)==IO_OK,"Prepare valid spare-order fixture");
    corruptSavedOrder(malformed,variant,newOrder);
    const auto retained=loaded.layers.at(7);ILoad corrupt(malformed.chunks);
    check(loaded.Load(&corrupt)==IO_ERROR,"One output identity with conflicting source-variant orders is rejected during load");equalRows(retained,loaded.layers.at(7));
    auto invalid=saved.layers.at(7);invalid.rows.write(variant).order=newOrder;saved.layers.at(7)=invalid;ISave invalidSave;
    check(saved.Save(&invalidSave)==IO_ERROR,"Conflicting source-variant order cannot be saved");

    EditLayer edge;edge.nextOrder=std::uint64_t(INT64_MAX)-1;
    check(edge.allocateOrder()==std::uint64_t(INT64_MAX)-1&&edge.nextOrder==std::uint64_t(INT64_MAX),"Last representable order advances to the exhausted sentinel");
    rejects([&]{edge.allocateOrder();},"Order allocation rejects the exhausted sentinel");
    check(edge.nextOrder==std::uint64_t(INT64_MAX),"Rejected order allocation leaves the counter unchanged");
    rejects([&]{edge.observeOrder(std::uint64_t(INT64_MAX));},"Reconstruction rejects an order without a representable successor");
    rejects([&]{edge.observeOrder(~std::uint64_t(0));},"Reconstruction cannot wrap an unsigned order");
    check(edge.nextOrder==std::uint64_t(INT64_MAX),"Rejected order reconstruction leaves the counter unchanged");

    EditLayer exhausted;bindStable(exhausted,binding(),nativeEditInput(four()));move(exhausted,0,3);exhausted.nextOrder=std::uint64_t(INT64_MAX);
    const auto before=exhausted;
    rejects([&]{bindStable(exhausted,binding(),nativeEditInput(input({"A","B"},{{10,1},{20,2},{30,1},{40,2},{50,1}})));},"Reconciliation rejects new candidates after order exhaustion");
    equalRows(before,exhausted);check(exhausted.input==before.input&&exhausted.originals==before.originals,"Order-exhausted reconciliation retains previous derived state");
    bindStable(exhausted,binding({"B"}),nativeEditInput(input({"B"},{{10,1},{20,1},{30,1},{40,1}})));
    check(exhausted.nextOrder==std::uint64_t(INT64_MAX)&&activeEditOrder(exhausted).size()==4,"Existing candidates may add source variants without allocating new order");
}
ISave oldStorage(const EditLayer& layer){
    ISave result;result.BeginChunk(0x7301);const auto write=[&](const auto& value){ULONG done=0;result.Write(reinterpret_cast<const char*>(&value),ULONG(sizeof(value)),&done);};
    const auto text=[&](const std::wstring& value){const auto size=unsigned(value.size());write(size);ULONG done=0;result.Write(reinterpret_cast<const char*>(value.data()),ULONG(size*sizeof(wchar_t)),&done);};
    unsigned count=1;int key=7;write(count);write(key);text(layer.signature);write(layer.invalid);count=unsigned(layer.rows.size());write(count);
    for(std::size_t i=0;i<layer.rows.size();++i){const auto& row=layer.rows.get(i);write(row.savedSource);write(row.delta);write(row.deleted);write(layer.selection.get(i));text(row.inputId.text());text(row.outputId.text());}result.EndChunk();return result;
}
void legacyHydration(){
    EditLayer old;bindStable(old,receiverWide(legacy()),nativeEditInput(four()));move(old,0,9);old.selection.set(0,true);auto bytes=oldStorage(old);CSEdit restored;ILoad read(bytes.chunks);
    check(restored.Load(&read)==IO_OK&&!restored.layers.at(7).sourceAware,"Supported legacy payload remains loadable without inventing source identity");
    auto& layer=restored.layers.at(7);bindStable(layer,binding(),nativeEditInput(input({"A","B"},{{20,2}})));
    check(!layer.rows.get(0).lineage&&!layer.legacyProof.empty(),"Missing legacy edited candidate retains unresolved proof");
    bindStable(layer,binding({"B"}),nativeEditInput(input({"B"},{{10,1},{20,1}})));
    check(!layer.rows.get(0).lineage&&!hasEditTransform(layer.rows.get(find(layer,10,L"B")).delta),"Source membership cannot hydrate missing legacy row from replacement");
    bindStable(layer,binding(),nativeEditInput(four()));check(layer.rows.get(0).lineage&&layer.rows.get(0).delta.GetTrans().x==9&&layer.legacyProof.empty(),"Exact original legacy proof recovers old source and delta");
    auto incompatible=old;rejects([&]{bindStable(incompatible,binding({"B"}),nativeEditInput(input({"B"},{{10,1}})));},"Legacy mismatch refuses positional migration");
    check(incompatible.signature==old.signature&&!incompatible.sourceAware,"Rejected legacy conversion preserves its original bytes");
    EditLayer untouched;bindStable(untouched,binding(),nativeEditInput(four()));untouched.selection.set(1,true);bindStable(untouched,binding({"A","B"},"99"),nativeEditInput(four()));check(untouched.selection.get(1),"Untouched Edit can rebind while retaining valid selection");
}
void recipeReplay(){
    EditLayer saved;saved.signature=binding();saved.sourceAware=true;saved.recipeUnbound=true;auto ids=ce::make<EditLineages>();ids->ids.emplace_back(L"A");ids->ids.emplace_back(L"B");saved.lineages=ids;
    EditRow moved;moved.inputId=moved.outputId=EditKey(10);moved.lineage=1;moved.order=0;moved.delta.SetTrans({2,0,0});moved.recipeLocal=true;saved.append(moved);
    auto clone=moved;clone.outputId=EditKey(L"recipe-clone");clone.order=4;saved.append(clone);
    EditRow removed;removed.inputId=removed.outputId=EditKey(20);removed.lineage=2;removed.order=1;removed.deleted=true;saved.append(removed);saved.nextOrder=5;
    CSEdit disk;disk.layers.emplace(7,saved);ISave output;check(disk.Save(&output)==IO_OK,"Unbound recipe history can be saved before a disabled layer evaluates");CSEdit loaded;ILoad file(output.chunks);check(loaded.Load(&file)==IO_OK&&loaded.layers.at(7).recipeUnbound&&loaded.layers.at(7).rows.get(0).recipeLocal,"Recipe-local flags survive native storage");
    auto layer=loaded.layers.at(7);auto incoming=nativeEditInput(input({"B","A"},{{10,2},{20,1},{30,2},{40,1}}));bindStable(layer,binding({"B","A"}),incoming);
    check(!layer.recipeUnbound&&activeEditOrder(layer).size()==4,"Recipe restores move, deletion and clone with remapped source order");const auto original=find(layer,10,L"A");check(!layer.rows.get(original).recipeLocal&&std::abs(layer.matrix(layer.rows.get(original)).GetTrans().x-12)<1e-5,"Local recipe offset restores on the correct original");
    auto reordered=nativeEditInput(input({"A","B"},{{10,1},{20,2},{30,1},{40,2}}));bindStable(layer,binding(),reordered);check(std::abs(layer.matrix(layer.rows.get(find(layer,10,L"A"))).GetTrans().x-12)<1e-5,"Source reordering does not migrate the restored move");
    auto rotated=nativeEditInput(input({"A","B"},{{10,1},{20,2},{30,1},{40,2}}));auto matrices=ce::make<EditDerived>(*rotated);auto view=*rotated->native;ep::Builder builder(view.token().owner,ep::Stage::Edited,view.sources(),view.size(),view.sourceCohort());for(unsigned i=0;i<view.size();++i){auto row=view.at(i);if(i==0)row.transform={0,2,0,-2,0,0,0,0,2,1000,2000,0};builder.appendGenerated(row);}matrices=nativeEditInput(builder.freeze());auto turn=saved;bindStable(turn,binding(),matrices);auto position=turn.matrix(turn.rows.get(find(turn,10,L"A"))).GetTrans();check(std::abs(position.x-1000)<.001&&std::abs(position.y-2004)<.001,"Local override follows rotated/scaled target base without world-space guessing");
}
void palette(){
    EditPalette colors;colors.sourceColors={{1,0,0},{0,1,0}};colors.bandIDs={4,9};colors.bandColors[0]={.5f,.5f,.5f};colors.bandColors[1]={0,0,1};colors.bandColors[2]={1,0,1};
    check(colors.color(2,0)==Point3(0,1,0),"Model identification addresses source ordinal, not candidate row");colors.mode=3;
    check(colors.color(1,9)==Point3(1,0,1)&&colors.color(1,0)==Point3(.5f,.5f,.5f),"Band lookup uses stable identity and grey fallback");colors.mode=4;
    check(colors.color(1,0)==Point3(1,0,0),"Material mode falls back to model identification for handles");
}
void sourceScaleReplay(){
    auto signature=[](double scale,bool typed){std::vector<cyrus::editbinding::SourceSpec> specs;
        for(const auto& id:{std::string("A"),std::string("B")}){const double value=id=="A"?scale:1.;auto raw="1.0|(color 100 200 100)|false|false|"+std::to_string(value)+"|0.0|1|";
            specs.push_back({id,typed?cyrus::editbinding::editableScaleSettings(raw,value):raw});}
        return receiverWide(cyrus::editbinding::make(legacy(),"CyrusBinding2:17|Owner:L|"+receiver,specs));};
    auto rows=[](float scale){const auto base=four();ep::Builder next(base.token().owner,ep::Stage::Edited,base.sources(),base.size(),base.sourceCohort());
        for(unsigned i=0;i<base.size();++i){auto row=base.at(i);if(row.source==1)for(unsigned axis=0;axis<3;++axis)row.transform[axis*3+axis]=scale;next.appendGenerated(row);}return next.freeze();};
    EditLayer layer;bindStable(layer,signature(1,false),nativeEditInput(rows(1)));move(layer,0,3);move(layer,1,7);layer.rows.write(2).deleted=true;layer.selection.set(0,true);
    auto clone=layer.rows.get(0);clone.outputId=EditKey(L"scaled-clone");clone.order=layer.allocateOrder();layer.append(clone);const auto before=layer;
    bindStable(layer,signature(2,true),nativeEditInput(rows(2)));
    check(layer.rows.size()==before.rows.size()&&activeEditOrder(layer).size()==4,"Source Scale revision retains base/clone/deleted history extent");
    for(unsigned i=0;i<layer.rows.size();++i){const auto& a=before.rows.get(i);const auto& b=layer.rows.get(i);
        check(a.inputId==b.inputId&&a.outputId==b.outputId&&a.lineage==b.lineage&&a.order==b.order&&a.deleted==b.deleted&&a.delta.rows==b.delta.rows,"Source Scale revision keeps exact authored identities/deltas and ordering");}
    const auto a=find(layer,10,L"A"),b=find(layer,20,L"B");
    check(layer.matrix(layer.rows.get(a)).GetRow(0).x==2&&layer.matrix(layer.rows.get(a)).GetTrans().x==13,"Resized moved source inherits the new base scale once while retaining world displacement");
    check(layer.matrix(layer.rows.get(b)).GetRow(0).x==1&&layer.matrix(layer.rows.get(b)).GetTrans().x==27,"Other source scale and authored move remain unchanged");
    check(layer.matrix(layer.rows.get(unsigned(layer.rows.size()-1))).GetRow(0).x==2,"Source clone inherits the revised base scale without identity remapping");
    CSEdit saved;saved.layers.emplace(7,layer);ISave bytes;check(saved.Save(&bytes)==IO_OK,"Save resized authored source history");CSEdit loaded;ILoad input(bytes.chunks);check(loaded.Load(&input)==IO_OK,"Load resized authored source history");equalRows(layer,loaded.layers.at(7));
    bindStable(loaded.layers.at(7),signature(.25,true),nativeEditInput(rows(.25f)));
    check(loaded.layers.at(7).matrix(loaded.layers.at(7).rows.get(a)).GetRow(0).x==.25f&&loaded.layers.at(7).rows.get(a).delta.GetTrans().x==3,"Reloaded source accepts another Scale revision with its original authored delta");
}
}
int main(){try{const auto baseline=ce::memory().live;historyAndFeedback();orderSafety();legacyHydration();recipeReplay();palette();sourceScaleReplay();check(ce::memory().live==baseline,"All tracked source, row and feedback allocations release");std::cout<<checks<<" native Edit state assertions passed\n";return 0;}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
