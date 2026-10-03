#include <max.h>
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
#include <maxscript/maxwrapper/mxsobjects.h>
#include <map>
#include <vector>
#include <string>
#include <cstdint>
#include <unordered_map>
#include <unordered_set>
#include <objbase.h>
#include <limits>
#include <maxscript/macros/define_instantiation_functions.h>
#define CS_EDIT_ID Class_ID(0x43b612e9,0x578124cd)
static unsigned editRevision=0;
static std::wstring pointId(){GUID id{};if(FAILED(CoCreateGuid(&id)))throw RuntimeError(_T("Cannot allocate instance identity"));wchar_t text[40];StringFromGUID2(id,text,40);return text;}
struct EditRow { std::wstring inputId,outputId;unsigned source=0; Matrix3 delta{1}; bool deleted=false,selected=false; };
struct EditLayer { std::wstring signature; bool invalid=false,active=true,legacy=false,pending=false;std::vector<EditRow> rows;std::vector<Matrix3> input;std::vector<int> sources;bool published=false,viewportVisible=true;std::unordered_set<std::wstring> publishedIDs;bool shown(const EditRow& r)const{return viewportVisible&&!r.deleted&&r.source<input.size()&&(!published||publishedIDs.count(r.outputId)>0);} };
class CSEdit;
class EditRestore:public RestoreObj { CSEdit* mod;std::map<int,EditLayer> before,after;public:EditRestore(CSEdit*);void Restore(int)override;void Redo()override;void EndHold()override;MSTR Description()override{return _T("CS Edit");}};
class CSEdit:public Modifier,public EventUser {
public:
 std::map<int,EditLayer> layers;
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
 RefTargetHandle Clone(RemapDir& remap)override{auto* m=new CSEdit;m->layers=layers;for(auto& [k,l]:m->layers)for(auto& r:l.rows)if(r.outputId!=r.inputId)r.outputId=pointId();BaseClone(this,m,remap);return m;}
 int NumSubObjTypes()override{return 1;}
 ISubObjType* GetSubObjType(int i)override{static GenSubObjType type(1);type.SetName(_T("Instances"));return i==-1||i==0?&type:nullptr;}
 void status(){
  if(!panel)return;bool invalid=false,pending=false;unsigned selected=0,total=0,suspended=0;
  for(auto& [k,l]:layers){if(!l.active)continue;invalid|=l.invalid;pending|=l.pending;
   for(auto& r:l.rows)if(!r.deleted){if(r.source>=l.input.size()){++suspended;continue;}if(l.shown(r)){++total;if(r.selected)++selected;}}}
  std::wstring text=pending?L"Legacy edits: restore lower modifier states to recover.":invalid?L"Layout / Seed changed. Reset Edits required.":std::to_wstring(selected)+L" selected / "+std::to_wstring(total)+L" instances; "+std::to_wstring(suspended)+L" suspended";
  if(text!=lastStatus){lastStatus=text;SetDlgItemText(panel,1001,text.c_str());}
 }
 void changed(bool geometry=true){if(geometry)++editRevision;NotifyDependents(FOREVER,geometry?PART_GEOM:PART_SELECT,REFMSG_CHANGE);status();if(ip)ip->RedrawViews(ip->GetTime());}
 bool valid(){for(auto& [k,l]:layers)if(l.active&&l.invalid)return false;return true;}
 void hold(){if(theHold.Holding()&&!holding){theHold.Put(new EditRestore(this));holding=true;}}
 void reset(){theHold.Begin();hold();layers.clear();changed();theHold.Accept(_T("Reset CS Edit"));holding=false;}
 void Notify()override{if(level==0)return;theHold.Begin();hold();for(auto& [k,l]:layers)if(l.active&&!l.invalid)for(auto& r:l.rows)if(r.selected&&l.shown(r))r.deleted=true;changed();theHold.Accept(_T("Delete scatter instances"));holding=false;}
 static INT_PTR CALLBACK dlg(HWND h,UINT msg,WPARAM w,LPARAM l){auto* m=reinterpret_cast<CSEdit*>(GetWindowLongPtr(h,GWLP_USERDATA));if(msg==WM_INITDIALOG){m=reinterpret_cast<CSEdit*>(l);SetWindowLongPtr(h,GWLP_USERDATA,(LONG_PTR)m);m->panel=h;m->lastStatus.clear();m->status();return TRUE;}if(msg==WM_COMMAND&&m){if(LOWORD(w)==1002)m->reset();if(LOWORD(w)==1003)m->Notify();if(LOWORD(w)==1004&&m->ip)m->ip->SetSubObjectLevel(1);return TRUE;}return FALSE;}
 void BeginEditParams(IObjParam* p,ULONG,Animatable*)override;
 void EndEditParams(IObjParam*,ULONG,Animatable*)override;
 void ActivateSubobjSel(int l,XFormModes& modes)override{if(ip){if(l&&!level)ip->RegisterDeleteUser(this);if(!l&&level)ip->UnRegisterDeleteUser(this);}level=l;if(l)modes=XFormModes(move,rotate,nscale,scale,nullptr,select);changed(false);}
 struct Visible {int layer;unsigned row;Point3 p;};
 std::vector<Visible> visible(){std::vector<Visible> out;for(auto& [k,l]:layers)if(l.active&&!l.invalid)for(unsigned i=0;i<l.rows.size();++i){auto& r=l.rows[i];if(l.shown(r))out.push_back({k,i,(l.input[r.source]*r.delta).GetTrans()});}return out;}
 int Display(TimeValue,INode*,ViewExp* v,int,ModContext*)override{if(!level)return 0;auto* g=v->getGW();g->setTransform(Matrix3(1));for(auto item:visible()){g->setColor(LINE_COLOR,layers[item.layer].rows[item.row].selected?Point3(1,1,1):Point3(1.f,.55f,0.f));g->marker(&item.p,HOLLOW_BOX_MRKR);}return 1;}
 void GetWorldBoundBox(TimeValue,INode*,ViewExp*,Box3& box,ModContext*)override{box.Init();for(auto v:visible())box+=v.p;}
 int HitTest(TimeValue,INode* node,int type,int crossing,int flags,IPoint2* p,ViewExp* v,ModContext* mc)override{
  if(!level)return 0;HitRegion hr;MakeHitRegion(hr,type,crossing,4,p);auto* g=v->getGW();auto limits=g->getRndLimits();g->setRndLimits((limits|GW_PICK)&~GW_ILLUM);g->setHitRegion(&hr);g->setTransform(Matrix3(1));int hit=0;auto items=visible();
  for(unsigned i=0;i<items.size();++i){auto item=items[i];bool selected=layers[item.layer].rows[item.row].selected;if((flags&HIT_SELONLY)&&!selected)continue;if((flags&HIT_UNSELONLY)&&selected)continue;g->clearHitCode();g->marker(&item.p,HOLLOW_BOX_MRKR);if(g->checkHitCode()){v->LogHit(node,mc,g->getHitDistance(),i,nullptr);hit=1;}}
  g->setRndLimits(limits);return hit;
 }
 void SelectSubComponent(HitRecord* h,BOOL selected,BOOL all,BOOL invert=FALSE)override{hold();auto items=visible();for(;h;h=h->Next()){if(h->hitInfo<items.size()){auto v=items[h->hitInfo];auto& r=layers[v.layer].rows[v.row];r.selected=invert?!r.selected:!!selected;}if(!all)break;}holding=false;changed(false);}
 void ClearSelection(int)override{hold();for(auto& [k,l]:layers)for(auto& r:l.rows)r.selected=false;holding=false;changed(false);}
 void SelectAll(int)override{hold();for(auto& [k,l]:layers)for(auto& r:l.rows)r.selected=l.active&&!l.invalid&&l.shown(r);holding=false;changed(false);}
 void InvertSelection(int)override{hold();for(auto& [k,l]:layers)for(auto& r:l.rows)if(l.shown(r))r.selected=!r.selected;holding=false;changed(false);}
 void transform(const Matrix3& tm,bool localOrigin=false){if(!valid())return;hold();for(auto& [k,l]:layers)if(l.active)for(auto& r:l.rows)if(r.selected&&l.shown(r)){Point3 original=(l.input[r.source]*r.delta).GetTrans();r.delta=r.delta*tm;if(localOrigin)r.delta.SetTrans(r.delta.GetTrans()+original-(l.input[r.source]*r.delta).GetTrans());}changed();}
 void Move(TimeValue,Matrix3&,Matrix3& axis,Point3& v,BOOL)override{transform(TransMatrix(VectorTransform(axis,v)));}
 void Rotate(TimeValue,Matrix3&,Matrix3& axis,Quat& v,BOOL localOrigin)override{Matrix3 r;v.MakeMatrix(r);transform(Inverse(axis)*r*axis,!!localOrigin);}
 void Scale(TimeValue,Matrix3&,Matrix3& axis,Point3& v,BOOL localOrigin)override{transform(Inverse(axis)*ScaleMatrix(v)*axis,!!localOrigin);}
 void TransformStart(TimeValue)override{holding=false;if(ip)ip->LockAxisTripods(TRUE);}
 void TransformFinish(TimeValue)override{holding=false;if(ip)ip->LockAxisTripods(FALSE);}
 void TransformCancel(TimeValue)override{holding=false;if(ip)ip->LockAxisTripods(FALSE);}
 void CloneSelSubComponents(TimeValue)override{if(!valid())return;theHold.Begin();holding=false;hold();for(auto& [k,l]:layers)if(l.active){auto n=l.rows.size();for(std::size_t i=0;i<n;++i)if(l.rows[i].selected&&l.shown(l.rows[i])){auto copy=l.rows[i];copy.outputId=pointId();l.rows[i].selected=false;l.rows.push_back(copy);}}changed();theHold.Accept(_T("Copy scatter instances"));holding=false;}
 void GetSubObjectCenters(SubObjAxisCallback* cb,TimeValue,INode*,ModContext*)override{Point3 p(0,0,0);int n=0;for(auto item:visible())if(layers[item.layer].rows[item.row].selected){p+=item.p;++n;}if(n)cb->Center(p/float(n),0);}
 void GetSubObjectTMs(SubObjAxisCallback* cb,TimeValue,INode*,ModContext*)override{Matrix3 tm(1);Point3 p(0,0,0);int n=0;for(auto item:visible())if(layers[item.layer].rows[item.row].selected){p+=item.p;++n;}if(n)tm.SetTrans(p/float(n));cb->TM(tm,0);}
 IOResult Save(ISave* save)override;
 IOResult Load(ILoad* load)override;
};
EditRestore::EditRestore(CSEdit* m):mod(m),before(m->layers){}
void EditRestore::Restore(int isUndo){if(isUndo)after=mod->layers;mod->layers=before;mod->changed();}
void EditRestore::EndHold(){mod->holding=false;}
void EditRestore::Redo(){mod->layers=after;mod->changed();}
extern HINSTANCE CyrusEditInstance;
void CSEdit::BeginEditParams(IObjParam* p,ULONG,Animatable*){ip=p;SetAFlag(A_MOD_BEING_EDITED);NotifyDependents(FOREVER,PART_ALL,REFMSG_MOD_DISPLAY_ON);move=new MoveModBoxCMode(this,p);rotate=new RotateModBoxCMode(this,p);scale=new UScaleModBoxCMode(this,p);nscale=new NUScaleModBoxCMode(this,p);select=new SelectModBoxCMode(this,p);panel=p->AddRollupPage(CyrusEditInstance,MAKEINTRESOURCE(101),dlg,_T("CS Edit"),(LPARAM)this);}
void CSEdit::EndEditParams(IObjParam* p,ULONG,Animatable*){ClearAFlag(A_MOD_BEING_EDITED);NotifyDependents(FOREVER,PART_ALL,REFMSG_MOD_DISPLAY_OFF);if(level)p->UnRegisterDeleteUser(this);for(auto* mode:std::vector<CommandMode*>{move,rotate,scale,nscale,select}){p->DeleteMode(mode);delete mode;}move=nullptr;rotate=nullptr;scale=nullptr;nscale=nullptr;select=nullptr;if(panel)p->DeleteRollupPage(panel);panel=nullptr;ip=nullptr;level=0;}
#include "cyrus_edit_storage.inc"
class EditDesc:public ClassDesc2 {public:int IsPublic()override{return TRUE;}void* Create(BOOL)override{return new CSEdit;}const MCHAR* ClassName()override{return _T("Cyrus Scatter Edit");}const MCHAR* NonLocalizedClassName()override{return _T("Cyrus Scatter Edit");}SClass_ID SuperClassID()override{return OSM_CLASS_ID;}Class_ID ClassID()override{return CS_EDIT_ID;}const MCHAR* Category()override{return _T("Cyrus");}const MCHAR* InternalName()override{return _T("CyrusScatterEdit");}HINSTANCE HInstance()override{return CyrusEditInstance;}};
extern "C" __declspec(dllexport) ClassDesc* CyrusEditDesc(){static EditDesc desc;return &desc;}
static CSEdit* edit(Value* v){auto* p=v->to_reftarg();if(!p||p->ClassID()!=CS_EDIT_ID)throw RuntimeError(_T("Expected Cyrus Scatter Edit"));return static_cast<CSEdit*>(p);}
def_visible_primitive(cyrusEditRevision,"cyrusEditRevision");Value* cyrusEditRevision_cf(Value**,int){return Integer::intern(editRevision);}
def_visible_primitive(cyrusEditFingerprint,"cyrusEditFingerprint");Value* cyrusEditFingerprint_cf(Value** a,int count){check_arg_count(cyrusEditFingerprint,2,count);type_check(a[0],Array,_T("rows"));auto* rows=static_cast<Array*>(a[0]);std::uint64_t h=1469598103934665603ULL;auto add=[&](const void* p,std::size_t n){auto* b=static_cast<const unsigned char*>(p);for(std::size_t i=0;i<n;++i){h^=b[i];h*=1099511628211ULL;}};for(int i=0;i<rows->size;++i){type_check(rows->data[i],Array,_T("instance row"));auto* r=static_cast<Array*>(rows->data[i]);if(r->size<2)throw RuntimeError(_T("Expected transform and source index"));Point3 p=r->data[0]->to_matrix3().GetTrans();add(&p,sizeof(p));int src=r->data[1]->to_int();add(&src,sizeof(src));}std::wstring text=a[1]->to_string();add(text.data(),text.size()*sizeof(wchar_t));return new String(std::to_wstring(h).c_str());}
#include "cyrus_edit_stack.inc"
def_visible_primitive(cyrusEditCommand,"cyrusEditCommand");Value* cyrusEditCommand_cf(Value** a,int count){check_arg_count(cyrusEditCommand,3,count);auto* m=edit(a[0]);int cmd=a[1]->to_int();if(cmd==0){m->reset();return &ok;}if(cmd==1){m->SelectAll(1);return &ok;}if(cmd==2){int level=m->level;m->level=1;m->Notify();m->level=level;return &ok;}if(cmd==3){m->holding=false;m->CloneSelSubComponents(0);m->holding=false;return &ok;}if(cmd==4){m->holding=false;m->transform(a[2]->to_matrix3());m->holding=false;return &ok;}return m->valid()?&true_value:&false_value;}

def_visible_primitive(cyrusEditTopology,"cyrusEditTopology");Value* cyrusEditTopology_cf(Value** a,int count){check_arg_count(cyrusEditTopology,2,count);auto* m=edit(a[0]);auto it=m->layers.find(a[1]->to_int());if(it==m->layers.end()||it->second.invalid)return new String(_T("pass"));std::uint64_t h=1469598103934665603ULL;for(unsigned i=0;i<it->second.rows.size();++i){auto& r=it->second.rows[i];if(!r.deleted){h=(h^i)*1099511628211ULL;h=(h^r.source)*1099511628211ULL;}}return new String(std::to_wstring(h).c_str());}

def_visible_primitive(cyrusEditActiveLayers,"cyrusEditActiveLayers");Value* cyrusEditActiveLayers_cf(Value** a,int count){check_arg_count(cyrusEditActiveLayers,2,count);auto* m=edit(a[0]);type_check(a[1],Array,_T("layer indices"));auto* keys=static_cast<Array*>(a[1]);for(auto& [key,l]:m->layers){l.active=false;for(int i=0;i<keys->size;++i)if(keys->data[i]->to_int()==key)l.active=true;}m->status();return &ok;}

def_visible_primitive(cyrusEditSelect,"cyrusEditSelect");Value* cyrusEditSelect_cf(Value** a,int count){check_arg_count(cyrusEditSelect,2,count);auto* m=edit(a[0]);type_check(a[1],Array,_T("selection indices"));auto* ids=static_cast<Array*>(a[1]);m->holding=false;m->hold();for(auto& [k,l]:m->layers)for(auto& r:l.rows)r.selected=false;auto visible=m->visible();for(int i=0;i<ids->size;++i){int id=ids->data[i]->to_int()-1;if(id>=0&&id<int(visible.size())){auto v=visible[id];m->layers[v.layer].rows[v.row].selected=true;}}m->holding=false;m->changed(false);return &ok;}

def_visible_primitive(cyrusEditTransform,"cyrusEditTransform");Value* cyrusEditTransform_cf(Value** a,int count){check_arg_count(cyrusEditTransform,5,count);auto* m=edit(a[0]);int op=a[1]->to_int();Matrix3 part(1),axis=a[3]->to_matrix3();BOOL local=a[4]->to_bool();m->TransformStart(0);if(op==0){Point3 v=a[2]->to_point3();m->Move(0,part,axis,v,local);}else if(op==1){Quat v=a[2]->to_quat();m->Rotate(0,part,axis,v,local);}else if(op==2){Point3 v=a[2]->to_point3();m->Scale(0,part,axis,v,local);}m->TransformFinish(0);return &ok;}
