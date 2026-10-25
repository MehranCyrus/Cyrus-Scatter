#include <max.h>
#include "license_boundary.h"
#include "receiver_plan.h"
#include "receiver_binding_host.h"
#include <iparamb2.h>
#include <istdplug.h>
#include <modstack.h>
#include <simpmod.h>
#include <evuser.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/3dmath.h>
#include "placement_transport.h"
#include "placement_value.h"
#include "placement_materialization.h"
#include "edit_blocks.h"
#include "edit_binding.h"
#include "edit_feedback.h"
#include "interactions_edit.h"
#include <optional>
#include <cmath>
#include <algorithm>
#include <climits>
#include <string_view>
#include <maxscript/maxwrapper/mxsobjects.h>
#include <map>
#include <vector>
#include <array>
#include <string>
#include <cstdint>
#include <unordered_map>
#include <unordered_set>
#include <objbase.h>
#include <limits>
#include <memory>
#include <maxscript/macros/define_instantiation_functions.h>
#define CS_EDIT_ID Class_ID(0x43b612e9,0x578124cd)
static unsigned editRevision=0;
static constexpr UINT editFeedbackMessage=WM_APP+0x2c3;
static UINT editFrameReadyMessage=0;
static UINT frameReadyMessage(){if(!editFrameReadyMessage){editFrameReadyMessage=RegisterWindowMessageW(L"CyrusScatter.FrameReady.43B612E9.578124CD");if(!editFrameReadyMessage)throw std::runtime_error("Cannot register the native viewport readiness message");}return editFrameReadyMessage;}
static std::uint64_t editRestoresLive=0,editRestoresCreated=0,editRestoreCalls=0,editRedoCalls=0,editSizeCalls=0;
static std::wstring pointId(){GUID id{};if(FAILED(CoCreateGuid(&id)))throw RuntimeError(_T("Cannot allocate instance identity"));wchar_t text[40];StringFromGUID2(id,text,40);return text;}
static bool hasEditTransform(const Matrix3& m){const Matrix3 identity(1);for(int i=0;i<4;++i)if(m.GetRow(i)!=identity.GetRow(i))return true;return false;}
static bool finiteEditMatrix(const Matrix3& m){for(int i=0;i<4;++i)for(int j=0;j<3;++j)if(!std::isfinite(m.GetRow(i)[j]))return false;return true;}
static Matrix3 inverseEditMatrix(const Matrix3& m){
 if(!finiteEditMatrix(m))throw std::invalid_argument("Cannot edit a non-finite published transform");
 const auto a=m.GetRow(0),b=m.GetRow(1),c=m.GetRow(2);
 const double det=double(a.x)*(double(b.y)*c.z-double(b.z)*c.y)-double(a.y)*(double(b.x)*c.z-double(b.z)*c.x)+double(a.z)*(double(b.x)*c.y-double(b.y)*c.x);
 const double scale=std::sqrt(double(LengthSquared(a))*LengthSquared(b)*LengthSquared(c));
 if(!std::isfinite(det)||!std::isfinite(scale)||scale==0||std::abs(det)<=scale*1e-10)throw std::invalid_argument("Cannot edit through a singular downstream transform; restore an invertible stack");
 auto result=Inverse(m);if(!finiteEditMatrix(result))throw std::invalid_argument("Cannot invert the published Edit transform");return result;
}
#include "cyrus_edit_data.inc"
class CSEdit;
class EditRestore:public RestoreObj { CSEdit* mod;std::map<int,EditLayer> before,after;bool sealed=false;public:EditRestore(CSEdit*);~EditRestore()override{--editRestoresLive;}void Restore(int)override;void Redo()override;void EndHold()override;int Size()override;MSTR Description()override{return _T("CS Edit");}};
class CSEdit:public Modifier,public EventUser {
public:
 std::map<int,EditLayer> layers;
 unsigned localRevision=0;
 // Gesture feedback is derived from committed input plus current authored
 // deltas. It owns no extra placement array and never changes renderer state.
 bool transformPreview=false,feedbackRefreshPending=false;
 // A native pointer gesture is admitted against one complete displayed frame.
 // Retain only shared feedback/COW blocks while asynchronous frames catch up.
 bool pointerGesture=false,pointerAllowed=false;
 std::map<int,EditLayer> pointerFeedback;
 AnimHandle feedbackOwner=0;std::uint64_t feedbackStage=0;
 IObjParam* ip=nullptr;HWND panel=nullptr;bool holding=false;int level=0;std::wstring lastStatus;
 MoveModBoxCMode* move=nullptr;RotateModBoxCMode* rotate=nullptr;UScaleModBoxCMode* scale=nullptr;NUScaleModBoxCMode* nscale=nullptr;SelectModBoxCMode* select=nullptr;
 CreateMouseCallBack* GetCreateMouseCallBack()override{return nullptr;}
 void DeleteThis()override{delete this;}
 Class_ID ClassID()override{return CS_EDIT_ID;}
 SClass_ID SuperClassID()override{return OSM_CLASS_ID;}
 void GetClassName(MSTR& s,bool)const override{s=_T("Cyrus Scatter Edit");}
 const MCHAR* GetObjectName(bool)const override{return _T("Cyrus Scatter Edit");}
 ChannelMask ChannelsUsed()override{return GEOM_CHANNEL;}
 ChannelMask ChannelsChanged()override{return GEOM_CHANNEL;}
 Class_ID InputType()override{return defObjectClassID;}
 Interval LocalValidity(TimeValue)override{return TestAFlag(A_MOD_BEING_EDITED)?NEVER:FOREVER;}
 void ModifyObject(TimeValue,ModContext&,ObjectState*,INode*)override{}
 RefResult NotifyRefChanged(const Interval&,RefTargetHandle,PartID&,RefMessage,BOOL)override{return REF_SUCCEED;}
 RefTargetHandle Clone(RemapDir& remap)override{auto m=std::make_unique<CSEdit>();m->layers=editAuthoredState(layers);for(auto& [k,l]:m->layers){l.published=false;for(std::size_t i=0;i<l.rows.size();++i)if(l.rows.get(i).outputId!=l.rows.get(i).inputId){auto next=l.rows.get(i);next.outputId=EditKey(pointId());l.textBytes-=EditLayer::keyBytes(l.rows.get(i));l.textBytes+=EditLayer::keyBytes(next);l.rows.write(i)=std::move(next);}}BaseClone(this,m.get(),remap);return m.release();}
 int NumSubObjTypes()override{return 1;}
 ISubObjType* GetSubObjType(int i)override{static GenSubObjType type(1);type.SetName(_T("Instances"));return i==-1||i==0?&type:nullptr;}
 void status(){
  if(!panel)return;bool invalid=false;unsigned selected=0,total=0,suspended=0;
  for(auto& [k,l]:layers){if(!l.active)continue;invalid|=l.invalid;
   for(std::size_t i=0;i<l.rows.size();++i){const auto& r=l.rows.get(i);if(l.shown(r)){++total;if(l.selection.get(i))++selected;}else if(authoredEdit(r)&&(!l.input||l.source(r)>=l.input->size()))++suspended;}}
  std::wstring text=invalid?L"Generation changed. Restore its matching setup or Reset all edits.":std::to_wstring(selected)+L" selected / "+std::to_wstring(total)+L" instances; "+std::to_wstring(suspended)+L" edits inactive (source or candidate unavailable)";
  if(text!=lastStatus){lastStatus=text;SetDlgItemText(panel,1001,text.c_str());}
 }
 void interactionChanged()noexcept{try{
  if(!feedbackOwner)return;std::vector<cyrus::InteractionEditPatch> patches;
  for(const auto& [key,l]:layers)if(l.active&&!l.invalid&&cyrus::interactionLayer(feedbackOwner,key)){
   const bool obstacle=cyrus::interactionObstacleLayer(feedbackOwner,key);
   for(unsigned i=0;i<l.rows.size();++i){const auto& row=l.rows.get(i);const auto wide=row.outputId.text();std::string id(wide.begin(),wide.end());if(!row.deleted&&!l.shown(row)&&!cyrus::interactionHasOverride(feedbackOwner,key,id))continue;
    if(!row.deleted&&!obstacle&&!l.selection.get(i)&&!cyrus::interactionHasOverride(feedbackOwner,key,id))continue;
    patches.push_back({key,std::move(id),authoredFeedbackMatrix(l,i,key),row.deleted});}}
  if(!patches.empty())cyrus::interactionEdit(feedbackOwner,patches);
 }catch(const std::exception& e){cyrus::interactionFailure(feedbackOwner,e.what());}catch(...){cyrus::interactionFailure(feedbackOwner,"Edit contact preparation failed; previous contact publication retained");}}
 void changed(bool geometry=true,bool preview=false){transformPreview=preview;if(geometry){++editRevision;++localRevision;interactionChanged();}NotifyDependents(FOREVER,geometry?PART_GEOM:PART_SELECT,REFMSG_CHANGE);status();if(ip)ip->RedrawViews(ip->GetTime());}
 // Renderer publication can occur inside a display update. Invalidate Max's
 // cached axes on the next owned UI dispatch, never recursively from rendering.
 void refreshFeedback()noexcept{
  if(panel&&ip&&!feedbackRefreshPending&&PostMessage(panel,editFeedbackMessage,
      static_cast<WPARAM>(Animatable::GetHandleByAnim(this)),0))feedbackRefreshPending=true;
 }
 bool valid(){for(auto& [k,l]:layers)if(l.active&&l.invalid)return false;return true;}
 void requireEditableFeedback()const{for(const auto& [k,l]:layers){(void)k;if(l.active&&l.feedbackPending())throw RuntimeError(_T("The viewport still shows the previous scatter. Refresh display or restore its matching setup before editing instances; saved edits are retained."));}}
 void hold(){if(theHold.Holding()&&!holding){theHold.Put(new EditRestore(this));holding=true;}}
 // Allocate/detach every changed block before publishing authored state.
 // Allocation failure cannot leave a partially selected/transformed population.
 template<class F> void author(F&& f,bool geometry=true,bool preview=false){try{auto next=layers;f(next);hold();layers.swap(next);changed(geometry,preview);}catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}}
 void reset(){if(!cyrusBoundaryAllows(this))return;theHold.Begin();hold();layers.clear();changed();theHold.Accept(_T("Reset CS Edit"));holding=false;}
 void Notify()override{if(level==0||!cyrusBoundaryAllows(this))return;requireEditableFeedback();theHold.Begin();try{author([](auto& next){for(auto& [k,l]:next)if(l.active&&!l.invalid)for(std::size_t i=0;i<l.rows.size();++i)if(l.selection.get(i)&&l.shown(l.rows.get(i)))l.rows.write(i).deleted=true;});theHold.Accept(_T("Delete scatter instances"));}catch(...){theHold.Cancel();throw;}}
 static INT_PTR CALLBACK dlg(HWND h,UINT msg,WPARAM w,LPARAM l){auto* m=reinterpret_cast<CSEdit*>(GetWindowLongPtr(h,GWLP_USERDATA));if(msg==WM_INITDIALOG){m=reinterpret_cast<CSEdit*>(l);SetWindowLongPtr(h,GWLP_USERDATA,(LONG_PTR)m);m->panel=h;m->lastStatus.clear();m->status();return TRUE;}
  if(msg==editFeedbackMessage&&m&&w==static_cast<WPARAM>(Animatable::GetHandleByAnim(m))){
   m->feedbackRefreshPending=false;
   if(m->ip)try{m->NotifyDependents(FOREVER,PART_SELECT,REFMSG_CHANGE);m->ip->RedrawViews(m->ip->GetTime());}catch(...){/* Optional display refresh; authored data is intact. */}
   return TRUE;
  }
  if(editFrameReadyMessage&&msg==editFrameReadyMessage&&m&&w==static_cast<WPARAM>(Animatable::GetHandleByAnim(m))){
   // A GPU worker never calls Max. A registered message cannot be confused
   // with an unrelated recycled window's private WM_APP protocol.
   if(cyrusRequestReadyPointDisplay(std::uint64_t(l),m->feedbackOwner)&&m->ip)try{m->ip->RedrawViews(m->ip->GetTime());}catch(...){}
   return TRUE;
  }
  if(msg==WM_COMMAND&&m){if(LOWORD(w)==1002)m->reset();if(LOWORD(w)==1003)m->Notify();if(LOWORD(w)==1004&&m->ip)m->ip->SetSubObjectLevel(1);return TRUE;}return FALSE;}
 void BeginEditParams(IObjParam* p,ULONG,Animatable*)override;
 void EndEditParams(IObjParam*,ULONG,Animatable*)override;
 void ActivateSubobjSel(int l,XFormModes& modes)override{if(ip){if(l&&!level)ip->RegisterDeleteUser(this);if(!l&&level)ip->UnRegisterDeleteUser(this);}level=l;if(l)modes=XFormModes(move,rotate,nscale,scale,nullptr,select);changed(false);}
 struct Visible {int layer;unsigned row;Point3 p,color;};
 const EditLayer& gestureFeedback(const EditLayer& l,int key)const{if(pointerGesture&&pointerAllowed){auto found=pointerFeedback.find(key);if(found!=pointerFeedback.end())return found->second;}return l;}
 Matrix3 authoredFeedbackMatrix(const EditLayer& l,unsigned i,int key)const{
  const auto& row=l.rows.get(i);const auto& frame=gestureFeedback(l,key);const auto final=frame.displayMatrix(row);const auto& local=frame.feedbackLocal();
  if(!local||i>=local->rows.size())return final;const auto& committed=local->rows.get(i);const auto source=l.sourceIn(committed,local->input);
  if(committed.inputId!=row.inputId||committed.outputId!=row.outputId||committed.lineage!=row.lineage||source==UINT_MAX)return final;
  try{const auto input=local->input->matrix(source);const auto suffix=inverseEditMatrix(input*committed.delta)*final;const auto matrix=input*row.delta*suffix;return finiteEditMatrix(matrix)?matrix:final;}catch(const std::exception&){return final;}
 }
 Matrix3 handleMatrix(const EditLayer& l,unsigned i,int key)const{
  const auto& row=l.rows.get(i);const auto final=l.displayMatrix(row);
  if(pointerGesture&&pointerAllowed&&l.selection.get(i))return authoredFeedbackMatrix(l,i,key);
  if(!transformPreview||!l.selection.get(i)||!l.published)return final;
  const auto& local=l.feedbackLocal();if(!local||i>=local->rows.size())return final;
  const auto& committed=local->rows.get(i);const auto source=l.sourceIn(committed,local->input);
  if(committed.inputId!=row.inputId||committed.outputId!=row.outputId||committed.lineage!=row.lineage||source==UINT_MAX)return final;
  try{
   const auto input=local->input->matrix(source);
   const auto suffix=inverseEditMatrix(input*committed.delta)*final;
   const auto preview=input*row.delta*suffix;
   return finiteEditMatrix(preview)?preview:final;
  }catch(const std::exception&){return final;}
 }
 ce::Vector<Visible> visible(){ce::Vector<Visible> out;for(auto& [k,l]:layers)if(l.active&&!l.invalid){const auto begin=out.size();for(unsigned i=0;i<l.rows.size();++i){const auto& r=l.rows.get(i);if(l.shown(r))out.push_back({k,i,handleMatrix(l,i,k).GetTrans(),l.color(r)});}
  const auto less=[&](const Visible& a,const Visible& b){return l.rows.get(a.row).order<l.rows.get(b.row).order;};if(!std::is_sorted(out.begin()+begin,out.end(),less))std::sort(out.begin()+begin,out.end(),less);}return out;}
 int Display(TimeValue,INode*,ViewExp* v,int,ModContext*)override{if(!level)return 0;auto* g=v->getGW();g->setTransform(Matrix3(1));for(auto item:visible()){
  g->setColor(LINE_COLOR,item.color);g->marker(&item.p,HOLLOW_BOX_MRKR);
  if(layers[item.layer].selection.get(item.row)){g->setColor(LINE_COLOR,Point3(0,0,0));g->marker(&item.p,X_MRKR);g->setColor(LINE_COLOR,Point3(1,1,1));g->marker(&item.p,PLUS_SIGN_MRKR);}}
  return 1;}
 void GetWorldBoundBox(TimeValue,INode*,ViewExp*,Box3& box,ModContext*)override{box.Init();for(auto v:visible())box+=v.p;}
 int HitTest(TimeValue,INode* node,int type,int crossing,int flags,IPoint2* p,ViewExp* v,ModContext* mc)override{
  if(!level)return 0;HitRegion hr;MakeHitRegion(hr,type,crossing,4,p);auto* g=v->getGW();auto limits=g->getRndLimits();g->setRndLimits((limits|GW_PICK)&~GW_ILLUM);g->setHitRegion(&hr);g->setTransform(Matrix3(1));int hit=0;auto items=visible();
  for(unsigned i=0;i<items.size();++i){auto item=items[i];bool selected=layers[item.layer].selection.get(item.row);if((flags&HIT_SELONLY)&&!selected)continue;if((flags&HIT_UNSELONLY)&&selected)continue;g->clearHitCode();g->marker(&item.p,HOLLOW_BOX_MRKR);if(g->checkHitCode()){v->LogHit(node,mc,g->getHitDistance(),i,nullptr);hit=1;}}
  g->setRndLimits(limits);return hit;
 }
 void SelectSubComponent(HitRecord* h,BOOL selected,BOOL all,BOOL invert=FALSE)override{auto items=visible();author([&](auto& next){for(;h;h=h->Next()){if(h->hitInfo<items.size()){auto v=items[h->hitInfo];auto& selection=next[v.layer].selection;selection.set(v.row,invert?!selection.get(v.row):!!selected);}if(!all)break;}},false);}
 void ClearSelection(int)override{author([](auto& next){for(auto& [k,l]:next)l.selection.clear();},false);}
 void SelectAll(int)override{author([](auto& next){for(auto& [k,l]:next)for(std::size_t i=0;i<l.rows.size();++i)l.selection.set(i,l.active&&!l.invalid&&l.shown(l.rows.get(i)));},false);}
 void InvertSelection(int)override{author([](auto& next){for(auto& [k,l]:next)for(std::size_t i=0;i<l.rows.size();++i)if(l.shown(l.rows.get(i)))l.selection.set(i,!l.selection.get(i));},false);}
 void transform(const Matrix3& tm,bool localOrigin=false,bool pointer=false){if(!valid()||!cyrusBoundaryAllows(this))return;if(!pointer)requireEditableFeedback();else if(!pointerGesture||!pointerAllowed)return;author([&](auto& next){
  if(!finiteEditMatrix(tm))throw std::invalid_argument("Edit gesture must have a finite transform");
  for(auto& [k,l]:next)if(l.active)for(std::size_t i=0;i<l.rows.size();++i)if(l.selection.get(i)&&l.shown(l.rows.get(i))&&!l.rows.get(i).deleted){
   const auto& saved=l.rows.get(i);const auto& frame=pointer?gestureFeedback(l,k):l;Matrix3 suffix(1);const auto final=frame.displayMatrix(saved);
   if(l.published){
    const auto& local=frame.feedbackLocal();if(!local||i>=local->rows.size())throw std::invalid_argument("Update the scatter before editing its changed instance history");
    const auto& committed=local->rows.get(i);const auto source=l.sourceIn(committed,local->input);
    if(committed.inputId!=saved.inputId||committed.outputId!=saved.outputId||committed.lineage!=saved.lineage||source==UINT_MAX)throw std::invalid_argument("Update the scatter before editing its changed source history");
    const auto intermediate=local->input->matrix(source)*committed.delta;
    bool same=true;for(int r=0;r<4;++r)if(intermediate.GetRow(r)!=final.GetRow(r))same=false;
    if(!same)suffix=inverseEditMatrix(intermediate)*final;
   }
   auto gesture=tm;if(localOrigin){const auto pivot=handleMatrix(l,unsigned(i),k).GetTrans();gesture.SetTrans(gesture.GetTrans()+pivot-pivot*gesture);}
   const auto delta=saved.delta*suffix*gesture*inverseEditMatrix(suffix);
   if(!finiteEditMatrix(delta))throw std::invalid_argument("Edit gesture produced a non-finite transform");l.rows.write(i).delta=delta;
  }},true,true);}
 void pointerFailure(const char* reason)noexcept{pointerAllowed=false;cyrus::interactionFailure(feedbackOwner,reason);try{lastStatus=L"Gesture stopped safely. Refresh the viewport before editing; saved edits are retained.";if(panel)SetDlgItemText(panel,1001,lastStatus.c_str());}catch(...){} }
 void pointerTransform(const Matrix3& tm,bool localOrigin=false)noexcept{try{transform(tm,localOrigin,true);}catch(const std::exception& e){pointerFailure(e.what());}catch(...){pointerFailure("Native Edit gesture rejected; previous complete contact result retained");}}
 void Move(TimeValue,Matrix3&,Matrix3& axis,Point3& v,BOOL)override{
  // Translation changes the displayed center, not the axis orientation.
  // Keep rotation/scale's start pivot locked, but let Move's gizmo follow the
  // same live center as its selected handles throughout the gesture.
  if(ip)ip->LockAxisTripods(FALSE);
  pointerTransform(TransMatrix(VectorTransform(axis,v)));
 }
 void Rotate(TimeValue,Matrix3&,Matrix3& axis,Quat& v,BOOL localOrigin)override{Matrix3 r;v.MakeMatrix(r);pointerTransform(Inverse(axis)*r*axis,!!localOrigin);}
 void Scale(TimeValue,Matrix3&,Matrix3& axis,Point3& v,BOOL localOrigin)override{pointerTransform(Inverse(axis)*ScaleMatrix(v)*axis,!!localOrigin);}
 void TransformStart(TimeValue)override{pointerFeedback.clear();pointerGesture=true;pointerAllowed=false;try{if(!valid()||!cyrusBoundaryAllows(this))return;requireEditableFeedback();for(const auto& [key,layer]:layers)if(layer.active){if(pointerFeedback.size()>=4096)throw std::length_error("Native Edit gesture layer limit exceeded");pointerFeedback.emplace(key,layer);}pointerAllowed=true;if(ip)ip->LockAxisTripods(TRUE);}catch(const std::exception& e){pointerFailure(e.what());}catch(...){pointerFailure("The viewport still shows a previous scatter; refresh it before starting a new gesture");}}
 void finishPointer(bool cancel)noexcept{pointerGesture=false;pointerAllowed=false;pointerFeedback.clear();transformPreview=!cancel;if(ip)ip->LockAxisTripods(FALSE);refreshFeedback();}
 void TransformFinish(TimeValue)override{finishPointer(false);}
 void TransformCancel(TimeValue)override{finishPointer(true);}
 void CloneSelSubComponents(TimeValue)override{if(!valid()||!cyrusBoundaryAllows(this))return;requireEditableFeedback();theHold.Begin();try{author([](auto& next){for(auto& [k,l]:next)if(l.active){auto n=l.rows.size();for(std::size_t i=0;i<n;++i)if(l.selection.get(i)&&l.shown(l.rows.get(i))&&!l.rows.get(i).deleted){auto copy=l.rows.get(i);copy.outputId=EditKey(pointId());copy.order=l.allocateOrder();l.selection.set(i,false);l.append(copy);l.selection.set(l.rows.size()-1,true);}}});theHold.Accept(_T("Copy scatter instances"));}catch(...){theHold.Cancel();throw;}}
 std::pair<Point3,unsigned> selectedCenter()const{Point3 p(0,0,0);unsigned n=0;for(const auto& [key,l]:layers){if(l.active&&!l.invalid)for(unsigned i=0;i<l.rows.size();++i)if(l.selection.get(i)&&l.shown(l.rows.get(i))){p+=handleMatrix(l,i,key).GetTrans();++n;}}return {n?p/float(n):p,n};}
 void GetSubObjectCenters(SubObjAxisCallback* cb,TimeValue,INode*,ModContext*)override{const auto [p,n]=selectedCenter();if(n)cb->Center(p,0);}
 void GetSubObjectTMs(SubObjAxisCallback* cb,TimeValue,INode*,ModContext*)override{Matrix3 tm(1);const auto [p,n]=selectedCenter();if(n)tm.SetTrans(p);cb->TM(tm,0);}
 IOResult Save(ISave* save)override;
 IOResult Load(ILoad* load)override;
};
EditRestore::EditRestore(CSEdit* m):mod(m),before(editAuthoredState(m->layers)){++editRestoresLive;++editRestoresCreated;}
void EditRestore::Restore(int isUndo){++editRestoreCalls;if(isUndo&&!sealed){after=editAuthoredState(mod->layers);sealed=true;}auto next=editRestoreState(before,mod->layers);mod->layers.swap(next);mod->changed();}
void EditRestore::EndHold(){mod->holding=false;}
int EditRestore::Size(){++editSizeCalls;const auto bytes=sizeof(*this)+editHistoryBytes(before,sealed?after:mod->layers);return int(std::min<std::size_t>(bytes,INT_MAX));}
void EditRestore::Redo(){++editRedoCalls;auto next=editRestoreState(after,mod->layers);mod->layers.swap(next);mod->changed();}
extern HINSTANCE CyrusEditInstance;
void CSEdit::BeginEditParams(IObjParam* p,ULONG,Animatable*){ip=p;feedbackRefreshPending=false;SetAFlag(A_MOD_BEING_EDITED);NotifyDependents(FOREVER,PART_ALL,REFMSG_MOD_DISPLAY_ON);move=new MoveModBoxCMode(this,p);rotate=new RotateModBoxCMode(this,p);scale=new UScaleModBoxCMode(this,p);nscale=new NUScaleModBoxCMode(this,p);select=new SelectModBoxCMode(this,p);panel=p->AddRollupPage(CyrusEditInstance,MAKEINTRESOURCE(101),dlg,_T("CS Edit"),(LPARAM)this);}
void CSEdit::EndEditParams(IObjParam* p,ULONG,Animatable*){pointerGesture=false;pointerAllowed=false;pointerFeedback.clear();feedbackRefreshPending=false;ClearAFlag(A_MOD_BEING_EDITED);NotifyDependents(FOREVER,PART_ALL,REFMSG_MOD_DISPLAY_OFF);if(level)p->UnRegisterDeleteUser(this);for(auto* mode:std::vector<CommandMode*>{move,rotate,scale,nscale,select}){p->DeleteMode(mode);delete mode;}move=nullptr;rotate=nullptr;scale=nullptr;nscale=nullptr;select=nullptr;if(panel)p->DeleteRollupPage(panel);panel=nullptr;ip=nullptr;level=0;}
#include "cyrus_edit_storage.inc"
namespace cyrus {
std::vector<InteractionEditPatch> interactionAuthoredEdits(INode* node,const std::vector<int>& historyLayers,bool collect){
 std::vector<InteractionEditPatch> result;CSEdit* owner=nullptr;auto* object=node?node->GetObjectRef():nullptr;unsigned depth=0;
 while(object&&object->SuperClassID()==GEN_DERIVOB_CLASS_ID){if(++depth>256)throw std::runtime_error("Interaction Edit stack exceeds 256 levels");auto* derived=static_cast<IDerivedObject*>(object);
  for(int i=0;i<derived->NumModifiers();++i){auto* modifier=derived->GetModifier(i);if(modifier&&modifier->ClassID()==CS_EDIT_ID){if(owner)throw std::runtime_error("Interactions currently require one Cyrus Edit modifier per controller");owner=static_cast<CSEdit*>(modifier);}}object=derived->GetObjRef();}
 if(owner&&owner->feedbackOwner&&owner->feedbackOwner!=Animatable::GetHandleByAnim(node))throw std::runtime_error("Interactions require a separate Cyrus Edit modifier for each controller");
 if(!owner||!collect)return result;
 for(const auto& [key,layer]:owner->layers){if(layer.invalid)continue;const bool history=std::find(historyLayers.begin(),historyLayers.end(),key)!=historyLayers.end();
  for(unsigned i=0;i<layer.rows.size();++i){const auto& row=layer.rows.get(i);if(!authoredEdit(row)&&!history)continue;const auto wide=row.outputId.text();std::string id(wide.begin(),wide.end());
   if(!authoredEdit(row)&&!interactionHasOverride(Animatable::GetHandleByAnim(node),key,id))continue;
   if(result.size()>=4096)throw std::runtime_error("More than 4096 uncommitted instance edits; Update scatter before restaging interactions");result.push_back({key,std::move(id),owner->authoredFeedbackMatrix(layer,i,key),row.deleted});}}
 return result;
}
}
class EditDesc:public ClassDesc2 {public:int IsPublic()override{return TRUE;}void* Create(BOOL)override{return new CSEdit;}const MCHAR* ClassName()override{return _T("Cyrus Scatter Edit");}const MCHAR* NonLocalizedClassName()override{return _T("Cyrus Scatter Edit");}SClass_ID SuperClassID()override{return OSM_CLASS_ID;}Class_ID ClassID()override{return CS_EDIT_ID;}const MCHAR* Category()override{return _T("Cyrus");}const MCHAR* InternalName()override{return _T("CyrusScatterEdit");}HINSTANCE HInstance()override{return CyrusEditInstance;}};
extern "C" __declspec(dllexport) ClassDesc* CyrusEditDesc(){static EditDesc desc;return &desc;}
static CSEdit* edit(Value* v){auto* p=v->to_reftarg();if(!p||p->ClassID()!=CS_EDIT_ID)throw RuntimeError(_T("Expected Cyrus Scatter Edit"));return static_cast<CSEdit*>(p);}
def_visible_primitive(cyrusEditRevision,"cyrusEditRevision");Value* cyrusEditRevision_cf(Value**,int){return Integer::intern(editRevision);}
def_visible_primitive(cyrusEditFingerprint,"cyrusEditFingerprint");Value* cyrusEditFingerprint_cf(Value** a,int count){check_arg_count(cyrusEditFingerprint,2,count);type_check(a[0],Array,_T("rows"));auto* rows=static_cast<Array*>(a[0]);std::uint64_t h=1469598103934665603ULL;auto add=[&](const void* p,std::size_t n){auto* b=static_cast<const unsigned char*>(p);for(std::size_t i=0;i<n;++i){h^=b[i];h*=1099511628211ULL;}};for(int i=0;i<rows->size;++i){type_check(rows->data[i],Array,_T("instance row"));auto* r=static_cast<Array*>(rows->data[i]);cyrus::rows::current(r);Point3 p=r->data[0]->to_matrix3().GetTrans();add(&p,sizeof(p));int src=r->data[1]->to_int();add(&src,sizeof(src));}std::wstring text=a[1]->to_string();add(text.data(),text.size()*sizeof(wchar_t));return new String(std::to_wstring(h).c_str());}
#include "cyrus_edit_stack.inc"
#include "cyrus_edit_feedback.inc"

// Bounded diagnostics. Allocator bytes include tracked native blocks/tables,
// derived maps and authored key strings; native input Views use their own ledger.
// Per-owner attribution is conservative and must not be added to unique bytes.
def_visible_primitive(cyrusEditMemoryStats,"cyrusEditMemoryStats");
Value* cyrusEditMemoryStats_cf(Value** a,int count){
    if(count<0||count>1)throw RuntimeError(_T("Edit memory takes an optional modifier"));
    const auto memory=ce::memory();const auto attributed=count?editAttributedBytes(edit(a[0])->layers):0;
    one_typed_value_local(Array* result);vl.result=new Array(10);
    for(auto value:{memory.live,memory.peak,memory.total,memory.allocations,std::uint64_t(attributed),editRestoresLive,editRestoresCreated,editRestoreCalls,editRedoCalls,editSizeCalls})vl.result->append(Integer64::intern(INT64(value)));
    return_value(vl.result);
}

#ifdef CYRUS_NATIVE_LICENSE_EXPERIMENT
// Test the actual SDK callback independently of the public script wrapper.
def_visible_primitive(cyrusOwnedLabSDKMove,"cyrusOwnedLabSDKMove");
Value* cyrusOwnedLabSDKMove_cf(Value** a,int count){
    check_arg_count(cyrusOwnedLabSDKMove,2,count);auto* m=edit(a[0]);
    Matrix3 part(1),axis(1);auto delta=a[1]->to_point3();
    m->TransformStart(0);m->Move(0,part,axis,delta,FALSE);m->TransformFinish(0);
    return &ok;
}
#endif
def_visible_primitive(cyrusEditCommand,"cyrusEditCommand");Value* cyrusEditCommand_cf(Value** a,int count){check_arg_count(cyrusEditCommand,3,count);auto* m=edit(a[0]);int cmd=a[1]->to_int();if((cmd==0||cmd==2||cmd==3||cmd==4)&&!cyrusBoundaryAllows(m))throw RuntimeError(_T("Cyrus authoring denied; edits retained"));if(cmd==0){m->reset();return &ok;}if(cmd==1){m->SelectAll(1);return &ok;}if(cmd==2){int level=m->level;m->level=1;m->Notify();m->level=level;return &ok;}if(cmd==3){m->CloneSelSubComponents(0);return &ok;}if(cmd==4){m->transform(a[2]->to_matrix3());return &ok;}return m->valid()?&true_value:&false_value;}

 def_visible_primitive(cyrusEditRecipeHasData,"cyrusEditRecipeHasData");Value* cyrusEditRecipeHasData_cf(Value** a,int count){check_arg_count(cyrusEditRecipeHasData,1,count);auto* m=edit(a[0]);const Matrix3 identity(1);for(const auto& [key,l]:m->layers){(void)key;for(std::size_t i=0;i<l.rows.size();++i){const auto& row=l.rows.get(i);if(row.deleted||row.inputId!=row.outputId)return &true_value;for(int i=0;i<4;++i)if(row.delta.GetRow(i)!=identity.GetRow(i))return &true_value;}}return &false_value;}
 def_visible_primitive(cyrusEditTopology,"cyrusEditTopology");Value* cyrusEditTopology_cf(Value** a,int count){check_arg_count(cyrusEditTopology,2,count);auto* m=edit(a[0]);auto it=m->layers.find(a[1]->to_int());if(it==m->layers.end()||it->second.invalid)return new String(_T("pass"));std::uint64_t h=1469598103934665603ULL;for(unsigned i=0;i<it->second.rows.size();++i){const auto& r=it->second.rows.get(i);if(!r.deleted){h=(h^i)*1099511628211ULL;h=(h^it->second.source(r))*1099511628211ULL;}}return new String(std::to_wstring(h).c_str());}

def_visible_primitive(cyrusEditActiveLayers,"cyrusEditActiveLayers");Value* cyrusEditActiveLayers_cf(Value** a,int count){check_arg_count(cyrusEditActiveLayers,2,count);auto* m=edit(a[0]);type_check(a[1],Array,_T("layer indices"));auto* keys=static_cast<Array*>(a[1]);for(auto& [key,l]:m->layers){l.active=false;for(int i=0;i<keys->size;++i)if(keys->data[i]->to_int()==key)l.active=true;}m->status();return &ok;}
// Structural layer commands and their native authored Edit map share one hold.
// Without this, Undo can recycle a scripted layer key while native rows from its
// previous owner survive. Removed maps belong to Undo, not the live modifier.
def_visible_primitive(cyrusEditOwnerLayers,"cyrusEditOwnerLayers");
Value* cyrusEditOwnerLayers_cf(Value** a,int count){
    check_arg_count(cyrusEditOwnerLayers,2,count);type_check(a[0],Array,_T("Edit modifiers"));type_check(a[1],Array,_T("present layer keys"));
    auto* mods=static_cast<Array*>(a[0]);auto* keys=static_cast<Array*>(a[1]);
    if(keys->size>10)throw RuntimeError(_T("Edit ownership exceeds the population bound"));
    std::array<int,10> present{};for(int i=0;i<keys->size;++i){present[i]=keys->data[i]->to_int();if(present[i]<=0)throw RuntimeError(_T("Invalid Edit owner key"));}
    if(mods->size&&!theHold.Holding())throw RuntimeError(_T("Edit ownership changes require the layer command's Undo hold"));
    try{
        // Register every restore before any map mutation; Cancel is safe if a
        // later registration cannot allocate. Snapshots share authored blocks.
        for(int i=0;i<mods->size;++i)edit(mods->data[i])->hold();
        for(int i=0;i<mods->size;++i){auto* m=edit(mods->data[i]);for(auto it=m->layers.begin();it!=m->layers.end();){
            bool keep=false;for(int j=0;j<keys->size;++j)if(present[j]==it->first)keep=true;
            if(keep)++it;else it=m->layers.erase(it);
        }}return &ok;
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}

def_visible_primitive(cyrusEditSelect,"cyrusEditSelect");Value* cyrusEditSelect_cf(Value** a,int count){check_arg_count(cyrusEditSelect,2,count);auto* m=edit(a[0]);type_check(a[1],Array,_T("selection indices"));auto* ids=static_cast<Array*>(a[1]);auto visible=m->visible();m->author([&](auto& next){for(auto& [k,l]:next)l.selection.clear();for(int i=0;i<ids->size;++i){int id=ids->data[i]->to_int()-1;if(id>=0&&id<int(visible.size())){auto v=visible[id];next[v.layer].selection.set(v.row,true);}}},false);return &ok;}

def_visible_primitive(cyrusEditTransform,"cyrusEditTransform");Value* cyrusEditTransform_cf(Value** a,int count){check_arg_count(cyrusEditTransform,5,count);auto* m=edit(a[0]);if(!cyrusBoundaryAllows(m))throw RuntimeError(_T("Cyrus authoring denied; edits retained"));int op=a[1]->to_int();Matrix3 axis=a[3]->to_matrix3(),tm(1);BOOL local=a[4]->to_bool();if(op==0)tm=TransMatrix(VectorTransform(axis,a[2]->to_point3()));else if(op==1){auto q=a[2]->to_quat();Matrix3 r;q.MakeMatrix(r);tm=Inverse(axis)*r*axis;}else if(op==2)tm=Inverse(axis)*ScaleMatrix(a[2]->to_point3())*axis;else throw RuntimeError(_T("Unknown Cyrus Edit transform operation"));m->transform(tm,op!=0&&local);return &ok;}
