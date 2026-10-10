// Standalone experimental adapter. No Cyrus headers, modules, globals or classes.
#include <max.h>
#include <triobj.h>
#include <IPainterInterface.h>
#include <notify.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include "lab.h"
#include "picker.h"
#include <map>
#include <fstream>
#include <chrono>
#include <algorithm>
#include <filesystem>
namespace {
using namespace paintlab;
using Clock=std::chrono::steady_clock;
V vec(Point3 p){return{p.x,p.y,p.z};}Point3 point(V p){return{float(p.x),float(p.y),float(p.z)};}
struct TriDelete{void operator()(TriObject* t)const{if(t)t->DeleteThis();}};
class Canvas;
std::map<int,std::unique_ptr<Canvas>>& documents(){static auto* p=new std::map<int,std::unique_ptr<Canvas>>;return *p;}
int nextId=1;bool registered=false;
class Canvas final:public ReferenceTarget,public IPainterCanvasInterface_V5,public IPainterCanvasInterface_V26_1 {
public:
 INode* target=nullptr;std::unique_ptr<TriObject,TriDelete> snapshot;std::unique_ptr<Session> session;std::unique_ptr<Picker> picker;
 IPainterInterface_V14* painter=nullptr;bool painting=false,ending=false,valid=true,connected=false;
 double radius=20,displayStep=25;Settings settings;bool showPoints=true,showFill=false,showBoundary=true;
 Preview cached;std::string error;std::uint64_t builds=0,draws=0,events=0;double editMs=0,feedbackMs=0;std::vector<double> eventMs;
 Clock::time_point lastRefresh{};
 struct Options{BOOL gather,normal,mirror,update,pressure,preSize,preStr,ring,drawNormal,trace,spline;float minSize,maxSize,minStr,maxStr;int lag;}old{};
 struct RightHandler:IPainterRightClickHandler{Canvas* owner;explicit RightHandler(Canvas* p):owner(p){}void RightClick()override{owner->stop();}}right{this};
 Canvas(INode* node,double res){if(!node||node->IsHidden()||node->IsFrozen())throw std::runtime_error("Choose a visible unfrozen receiver");auto t=GetCOREInterface()->GetTime();auto* obj=node->EvalWorldState(t).obj;if(!obj||!obj->CanConvertToType(triObjectClassID))throw std::runtime_error("Receiver cannot be triangulated");auto* tri=static_cast<TriObject*>(obj->ConvertToType(t,triObjectClassID));snapshot.reset(CreateNewTriObject());try{snapshot->GetMesh()=tri->GetMesh();}catch(...){if(tri!=obj)tri->DeleteThis();throw;}if(tri!=obj)tri->DeleteThis();auto& m=snapshot->GetMesh();Matrix3 tm=node->GetObjectTM(t);paintlab::Mesh copy;for(int i=0;i<m.numVerts;++i)copy.vertices.push_back(vec(m.verts[i]*tm));for(int i=0;i<m.numFaces;++i)copy.faces.push_back({m.faces[i].v[0],m.faces[i].v[1],m.faces[i].v[2]});session=std::make_unique<Session>(LAB_METHOD,std::move(copy),res);picker=std::make_unique<Picker>(session->mesh());ReplaceReference(0,node);}
 ~Canvas()override{stop();DeleteAllRefsFromMe();}
 void DeleteThis()override{delete this;}Class_ID ClassID()override{return Class_ID(0x6ad71000+LAB_METHOD,0x7123be19);}SClass_ID SuperClassID()override{return REF_TARGET_CLASS_ID;}
 void GetClassName(MSTR& s,bool)const override{s=_T("Paint Methods Lab Canvas");}int NumRefs()override{return 1;}
 RefTargetHandle GetReference(int i)override{return i==0?target:nullptr;}void SetReference(int i,RefTargetHandle r)override{if(i==0)target=static_cast<INode*>(r);}
 RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID& part,RefMessage message,BOOL)override{if(message==REFMSG_TARGET_DELETED||message==REFMSG_CHANGE&&(part&(PART_GEOM|PART_TOPO|PART_TM))){valid=false;error="Receiver changed: paint retained; restore or create a new lab region";if(session)session->cancel();}return REF_SUCCEED;}
 void* GetInterface(ULONG id)override{if(id==PAINTERCANVASINTERFACE_V5)return static_cast<IPainterCanvasInterface_V5*>(this);if(id==PAINTERCANVASINTERFACE_V26_1)return static_cast<IPainterCanvasInterface_V26_1*>(this);return ReferenceTarget::GetInterface(id);}
 bool IsGeometryConstant()override{return true;}
 void check(){if(!valid||!target)throw std::runtime_error("Receiver is inactive; paint retained");}
 void refresh(){check();auto start=Clock::now();auto next=preview(*session,showPoints,showFill,displayStep);cached=std::move(next);feedbackMs=std::chrono::duration<double,std::milli>(Clock::now()-start).count();++builds;lastRefresh=Clock::now();error.clear();GetCOREInterface()->RedrawViews(GetCOREInterface()->GetTime());}
 void restore(){if(!painter)return;painter->SetEnablePointGather(old.gather);painter->SetBuildNormalData(old.normal);painter->SetMirrorEnable(old.mirror);painter->SetUpdateOnMouseUp(old.update);painter->SetPressureEnable(old.pressure);painter->SetPredefinedSizeEnable(old.preSize);painter->SetPredefinedStrEnable(old.preStr);painter->SetDrawRing(old.ring);painter->SetDrawNormal(old.drawNormal);painter->SetDrawTrace(old.trace);painter->SetUseSplineConstraint(old.spline);painter->SetMinSize(old.minSize);painter->SetMaxSize(old.maxSize);painter->SetMinStr(old.minStr);painter->SetMaxStr(old.maxStr);painter->SetLagRate(old.lag);}
 void start(){check();if(painting)return;auto* ref=static_cast<ReferenceTarget*>(GetCOREInterface()->CreateInstance(REF_TARGET_CLASS_ID,PAINTERINTERFACE_CLASS_ID));painter=ref?static_cast<IPainterInterface_V14*>(ref->GetInterface(PAINTERINTERFACE_V14)):nullptr;if(!painter||painter->InPaintMode())throw std::runtime_error("Max Painter unavailable or already owned by another tool");old={painter->GetEnablePointGather(),painter->GetBuildNormalData(),painter->GetMirrorEnable(),painter->GetUpdateOnMouseUp(),painter->GetPressureEnable(),painter->GetPredefinedSizeEnable(),painter->GetPredefinedStrEnable(),painter->GetDrawRing(),painter->GetDrawNormal(),painter->GetDrawTrace(),painter->GetUseSplineConstraint(),painter->GetMinSize(),painter->GetMaxSize(),painter->GetMinStr(),painter->GetMaxStr(),painter->GetLagRate()};painting=true;
  // IPainterInterface Get/SetMin/MaxSize use radius, despite the "Size" name.
  try{painter->SetEnablePointGather(FALSE);painter->SetBuildNormalData(FALSE);painter->SetMirrorEnable(FALSE);painter->SetUpdateOnMouseUp(FALSE);painter->SetPressureEnable(FALSE);painter->SetPredefinedSizeEnable(FALSE);painter->SetPredefinedStrEnable(FALSE);painter->SetDrawRing(TRUE);painter->SetDrawNormal(FALSE);painter->SetDrawTrace(FALSE);painter->SetUseSplineConstraint(FALSE);painter->SetLagRate(0);painter->SetMinSize(float(radius));painter->SetMaxSize(float(radius));painter->SetMinStr(1);painter->SetMaxStr(1);if(!painter->InitializeCallback(this))throw std::runtime_error("Painter callback rejected");Tab<INode*> nodes;nodes.Append(1,&target);ObjectState os(snapshot.get());Tab<ObjectState> states;states.Append(1,&os);if(!painter->InitializeNodesByObjState(0,nodes,states)||!painter->StartPaintSession(&right))throw std::runtime_error("Painter could not start");refresh();}catch(...){stop();throw;}}
 void stop(){if(!painting||ending)return;ending=true;CancelStroke();if(painter){painter->EndPaintSession();painter->InitializeCallback(nullptr);Tab<INode*> none;painter->InitializeNodes(0,none);restore();}painting=false;ending=false;}
 BOOL StartStroke()override{try{check();session->begin(settings);connected=false;return TRUE;}catch(const std::exception& e){error=e.what();return FALSE;}}
 void dab(unsigned face,V bary,double r,bool join){check();if(face>=session->mesh().faces.size()||std::abs(bary.x+bary.y+bary.z-1)>1e-3||std::min({bary.x,bary.y,bary.z})<-1e-4)throw std::runtime_error("Invalid Painter anchor");Anchor a{face,bary};session->append({a,session->mesh().position(a),r,join});}
 BOOL PaintStroke(BOOL hit,IPoint2 mouse,Point3,Point3,Point3,Point3,Point3 bary,int face,BOOL,BOOL,BOOL,float r,float,float,INode* node,BOOL,Point3,Point3,Point3,Point3)override{
  auto start=Clock::now();try{if(!hit||node!=target){connected=false;return TRUE;}if(!session->active()&&!StartStroke())return FALSE;auto& view=GetCOREInterface()->GetActiveViewExp();::Ray ray;view.MapScreenToWorldRay(float(mouse.x),float(mouse.y),ray);Anchor canonical;if(!picker->hit(vec(ray.p),vec(ray.dir),canonical)){connected=false;return TRUE;}dab(canonical.face,canonical.bary,r,connected);connected=true;editMs=std::chrono::duration<double,std::milli>(Clock::now()-start).count();if(std::chrono::duration<double,std::milli>(Clock::now()-lastRefresh).count()>33)refresh();++events;eventMs.push_back(std::chrono::duration<double,std::milli>(Clock::now()-start).count());return TRUE;}catch(const std::exception& e){session->cancel();error=e.what();return FALSE;}}
 BOOL EndStroke()override{try{session->commit();refresh();return TRUE;}catch(const std::exception& e){session->cancel();error=e.what();return FALSE;}}
 BOOL EndStroke(int n,BOOL* hit,IPoint2* mouse,Point3* world,Point3* normal,Point3* local,Point3* ln,Point3* bary,int* face,BOOL* shift,BOOL* ctrl,BOOL* alt,float* r,float* str,float* pressure,INode** node,BOOL mirror,Point3*,Point3*,Point3*,Point3*)override{for(int i=0;i<n;++i)if(!PaintStroke(hit[i],mouse[i],world[i],normal[i],local[i],ln[i],bary[i],face[i],shift[i],ctrl[i],alt[i],r[i],str[i],pressure[i],node[i],mirror,{}, {}, {}, {}))return FALSE;return EndStroke();}
 BOOL CancelStroke()override{bool changed=session&&session->active();if(session)session->cancel();connected=false;if(changed&&valid&&target)try{refresh();}catch(const std::exception& e){error=e.what();}return TRUE;}
 BOOL SystemEndPaintSession()override{CancelStroke();if(!ending){restore();painting=false;}return TRUE;}
 void PainterDisplay(TimeValue,ViewExp*,int)override{}
 void draw(ViewExp* view){if(!valid||!view)return;auto* gw=view->getGW();if(!gw)return;++draws;auto limits=gw->getRndLimits();gw->setTransform(Matrix3(1));gw->setRndLimits(limits|GW_Z_BUFFER);gw->setColor(LINE_COLOR,Point3(.05f,.8f,.65f));
  if(showBoundary)for(auto line:cached.lines){Point3 p[2]={point(line[0]),point(line[1])};gw->polyline(2,p,nullptr,nullptr,FALSE,nullptr);}
  if(showPoints){gw->startMarkers();for(std::size_t i=0;i<cached.points.size();++i){gw->setColor(LINE_COLOR,Point3(.05f,.8f,.65f)*float(.2+.8*cached.pointWeights[i]));auto q=point(cached.points[i]);gw->marker(&q,DOT_MRKR);}gw->endMarkers();}
  if(showFill&&!cached.fill.empty()){Material previous=*gw->getMaterial(),material;material.Ka=material.Kd=Point3(.1f,.7f,.55f);material.Ks={0,0,0};material.selfIllum=1;material.dblSided=1;material.opacity=1;gw->setMaterial(material);gw->setRndLimits((limits|GW_Z_BUFFER|GW_COLOR_VERTS)&~(GW_ILLUM|GW_WIREFRAME|GW_BACKCULL|GW_TEXTURE));gw->startTriangles();for(std::size_t i=0;i<cached.fill.size();++i){auto face=cached.fill[i];Point3 shade=material.Kd*float(.2+.8*cached.fillWeights[i]);Point3 p[3]={point(face[0]),point(face[1]),point(face[2])},colors[3]={shade,shade,shade};gw->triangle(p,colors);}gw->endTriangles();gw->setMaterial(previous);}gw->setRndLimits(limits);
 }
};
class Display:public RedrawViewsCallback{void proc(Interface* ip)override{auto& view=ip->GetActiveViewExp();if(view.IsAlive())for(auto& [id,d]:documents())d->draw(&view);}}display;
void sceneEvent(void*,NotifyInfo*){for(auto& [id,d]:documents()){d->stop();d->valid=false;}}
void initialize(){if(registered)return;GetCOREInterface()->RegisterRedrawViewsCallback(&display);for(int c:{NOTIFY_SYSTEM_PRE_RESET,NOTIFY_FILE_PRE_OPEN})RegisterNotification(sceneEvent,nullptr,c);registered=true;}
Value* execute(Value** args,int count){if(count!=2)throw RuntimeError(_T("Expected command and payload array"));type_check(args[1],Array,_T("payload"));auto* a=static_cast<Array*>(args[1]);std::wstring cmd=args[0]->to_string();auto require=[&](int n){if(a->size!=n)throw std::runtime_error("Incorrect payload length");};
 try{initialize();if(cmd==L"create"){require(2);auto p=std::make_unique<Canvas>(a->data[0]->to_node(),a->data[1]->to_float());int id=nextId++;documents()[id]=std::move(p);return Integer::intern(id);}if(cmd==L"shutdown"){require(0);documents().clear();GetCOREInterface()->UnRegisterRedrawViewsCallback(&display);for(int c:{NOTIFY_SYSTEM_PRE_RESET,NOTIFY_FILE_PRE_OPEN})UnRegisterNotification(sceneEvent,nullptr,c);registered=false;return &ok;}require(a->size);if(a->size<1)throw std::runtime_error("Region id required");auto it=documents().find(a->data[0]->to_int());if(it==documents().end())throw std::runtime_error("Unknown lab region");auto& d=*it->second;
  if(cmd==L"begin"){require(4);d.check();d.session->begin({a->data[1]->to_bool()!=FALSE,a->data[2]->to_float(),a->data[3]->to_float()});}
  else if(cmd==L"dab"){require(5);d.dab(unsigned(a->data[1]->to_int()-1),vec(a->data[2]->to_point3()),a->data[3]->to_float(),a->data[4]->to_bool()!=FALSE);}
  else if(cmd==L"commit"){require(1);d.session->commit();}
  else if(cmd==L"cancel"){require(1);d.session->cancel();}
  else if(cmd==L"undo"){require(1);d.session->undo();d.refresh();}
  else if(cmd==L"redo"){require(1);d.session->redo();d.refresh();}
  else if(cmd==L"clear"){require(1);d.session->clear();d.refresh();}
  else if(cmd==L"refresh"){require(4);d.displayStep=a->data[1]->to_float();if(!std::isfinite(d.displayStep)||d.displayStep<=0)throw std::runtime_error("Display step must be positive");d.showPoints=a->data[2]->to_bool()!=FALSE;d.showFill=a->data[3]->to_bool()!=FALSE;d.refresh();}
  else if(cmd==L"boundary"){require(2);d.showBoundary=a->data[1]->to_bool()!=FALSE;}
  else if(cmd==L"start"){require(5);d.radius=a->data[1]->to_float();d.settings={a->data[2]->to_bool()!=FALSE,a->data[3]->to_float(),a->data[4]->to_float()};if(!std::isfinite(d.radius)||d.radius<=0)throw std::runtime_error("Radius must be positive");d.start();}
  else if(cmd==L"stop"){require(1);d.stop();}
  else if(cmd==L"painterRadius"){require(1);if(!d.painting||!d.painter)throw std::runtime_error("Painter is not active");return Float::intern(d.painter->GetMaxSize());}
  else if(cmd==L"replayScreen"){
   require(2);type_check(a->data[1],Array,_T("world path"));auto* path=static_cast<Array*>(a->data[1]);if(path->size>10000)throw std::runtime_error("Replay path limit");
   auto& view=GetCOREInterface()->GetActiveViewExp();auto* gw=view.getGW();if(!gw)throw std::runtime_error("No viewport");gw->setTransform(Matrix3(1));if(!d.StartStroke())throw std::runtime_error(d.error);
   for(int i=0;i<path->size;++i){Point3 p=path->data[i]->to_point3();IPoint3 screen;gw->wTransPoint(&p,&screen);float effectiveRadius=d.painting&&d.painter?d.painter->GetMaxSize():float(d.radius);if(!d.PaintStroke(TRUE,IPoint2(screen.x,screen.y),p,{0,0,1},p,{0,0,1},{1,0,0},0,FALSE,FALSE,FALSE,effectiveRadius,1,1,d.target,FALSE,{}, {}, {}, {}))throw std::runtime_error(d.error);}
   if(!d.EndStroke())throw std::runtime_error(d.error);
  }
  else if(cmd==L"eventTimes"){require(1);one_typed_value_local(Array* result);vl.result=new Array(int(d.eventMs.size()));for(double t:d.eventMs)vl.result->append(Float::intern(float(t)));return_value(vl.result);}
  else if(cmd==L"query"){require(3);d.check();Anchor h{unsigned(a->data[1]->to_int()-1),vec(a->data[2]->to_point3())};return Float::intern(float(d.session->view().query(h,d.session->mesh().position(h))));}
  else if(cmd==L"save"){require(2);auto bytes=d.session->save();std::filesystem::path path(a->data[1]->to_string()),temp=path;temp+=L".paintlab-"+std::to_wstring(GetCurrentProcessId())+L"-"+std::to_wstring(Clock::now().time_since_epoch().count())+L".tmp";{std::ofstream out(temp,std::ios::binary);out<<bytes;if(!out)throw std::runtime_error("Cannot save lab file");}if(!MoveFileExW(temp.c_str(),path.c_str(),MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH))throw std::runtime_error("Cannot publish saved lab file");}
  else if(cmd==L"load"){require(2);std::ifstream in(std::filesystem::path(a->data[1]->to_string()),std::ios::binary);if(!in)throw std::runtime_error("Cannot open lab file");in.seekg(0,std::ios::end);if(in.tellg()>128*1024*1024)throw std::runtime_error("File exceeds 128 MiB");in.seekg(0);std::string b((std::istreambuf_iterator<char>(in)),{});d.session->load(b);d.refresh();}
  else if(cmd==L"stats"){require(1);auto s=d.session->view().stats();one_typed_value_local(Array* result);vl.result=new Array(12);for(double v:{double(LAB_METHOD),double(s.items),double(s.bytes),double(d.session->historyBytes()),double(d.builds),double(d.draws),d.editMs,d.feedbackMs,double(d.cached.lines.size()),double(d.cached.fill.size()),double(d.cached.points.size()),double(d.events)})vl.result->append(Float::intern(float(v)));return_value(vl.result);}
  else if(cmd==L"error"){require(1);std::wstring w(d.error.begin(),d.error.end());return new String(w.c_str());}
  else if(cmd==L"delete"){require(1);documents().erase(it);}
  else throw std::runtime_error("Unknown lab command");return &ok;
 }catch(const std::exception& e){std::wstring w(e.what(),e.what()+std::char_traits<char>::length(e.what()));throw RuntimeError(w.c_str());}
}
}
extern "C" __declspec(dllexport) const MCHAR* LibDescription(){return _T("Independent Paint Methods Lab 0.1.0");}
extern "C" __declspec(dllexport) ULONG LibVersion(){return VERSION_3DSMAX;}
extern "C" __declspec(dllexport) int LibNumberClasses(){return 0;}
extern "C" __declspec(dllexport) ClassDesc* LibClassDesc(int){return nullptr;}
BOOL WINAPI DllMain(HINSTANCE,DWORD,LPVOID){return TRUE;}
#if LAB_METHOD==1
def_visible_primitive(paintLabA,"paintLabA");Value* paintLabA_cf(Value** a,int n){return execute(a,n);}
#elif LAB_METHOD==2
def_visible_primitive(paintLabB,"paintLabB");Value* paintLabB_cf(Value** a,int n){return execute(a,n);}
#elif LAB_METHOD==3
def_visible_primitive(paintLabC,"paintLabC");Value* paintLabC_cf(Value** a,int n){return execute(a,n);}
#else
def_visible_primitive(paintLabD,"paintLabD");Value* paintLabD_cf(Value** a,int n){return execute(a,n);}
#endif
