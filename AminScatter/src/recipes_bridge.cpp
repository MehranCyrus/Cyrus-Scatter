#include "recipes.h" // Parse JSON before MAXScript type-test macros.
#include "recipe_library.h"
#include <max.h>
#include <iparamb2.h>
#include <notify.h>
#include <maxscript/maxscript.h>
#include <maxscript/foundation/arrays.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/foundation/strings.h>
#include <maxscript/foundation/name.h>
#include <maxscript/macros/define_instantiation_functions.h>
#include <cmath>

namespace {
namespace r=cyrus::recipes;
std::string recipeUTF8(Value* value,std::size_t limit=r::maxTotalPaintBytes*2){
    type_check(value,String,_T("recipe text"));const auto* text=value->to_string();
    if(wcslen(text)>limit)throw RuntimeError(_T("Recipe text exceeds bounds"));
    const int size=WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,text,-1,nullptr,0,nullptr,nullptr);if(size<=0)throw RuntimeError(_T("Invalid recipe Unicode"));
    std::string result(static_cast<std::size_t>(size),'\0');WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,text,-1,result.data(),size,nullptr,nullptr);result.pop_back();if(result.size()>limit)throw RuntimeError(_T("Recipe UTF-8 exceeds bounds"));return result;
}
Value* recipeString(const std::string& text){const int size=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,text.c_str(),-1,nullptr,0);if(size<=0)throw RuntimeError(_T("Invalid recipe UTF-8"));std::wstring result(static_cast<std::size_t>(size),L'\0');MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,text.c_str(),-1,result.data(),size);return new String(result.c_str());}
r::Json recipeTree(Value* value,int depth=0){
    if(depth>32)throw RuntimeError(_T("Recipe nesting exceeds 32"));
    if(value==&undefined)return nullptr;
    if(value==&true_value||value==&false_value)return value==&true_value;
    if(is_string(value))return recipeUTF8(value);
    if(Number::is_integer_number(value))return value->to_int64();
    if(Number::is_float_number(value)){const double n=value->to_double();if(!std::isfinite(n))throw RuntimeError(_T("Nonfinite recipe number"));return n;}
    type_check(value,Array,_T("recipe data array"));auto* input=static_cast<Array*>(value);if(input->size>65536)throw RuntimeError(_T("Recipe array exceeds bounds"));
    if(input->size==2&&input->data[0]==Name::intern(_T("recipeObject"))){
        type_check(input->data[1],Array,_T("recipe object fields"));auto* rows=static_cast<Array*>(input->data[1]);if(rows->size>4096)throw RuntimeError(_T("Recipe object field limit"));auto result=r::Json::object();
        for(int i=0;i<rows->size;++i){type_check(rows->data[i],Array,_T("recipe key/value"));auto* pair=static_cast<Array*>(rows->data[i]);if(pair->size!=2)throw RuntimeError(_T("Recipe field requires a key and value"));const auto key=recipeUTF8(pair->data[0],160);if(result.contains(key))throw RuntimeError(_T("Duplicate recipe field"));result[key]=recipeTree(pair->data[1],depth+1);}return result;
    }
    auto result=r::Json::array();for(int i=0;i<input->size;++i)result.push_back(recipeTree(input->data[i],depth+1));return result;
}
Value* recipeValue(const r::Json& value){
    if(value.is_null())return &undefined;if(value.is_boolean())return value.get<bool>()?&true_value:&false_value;
    if(value.type()==r::Json::value_t::string)return recipeString(value.get<std::string>());
    if(value.is_number_integer())return Integer64::intern(value.get<std::int64_t>());
    if(value.is_number())return Double::intern(value.get<double>());
    three_typed_value_locals(Array* result,Array* rows,Array* pair);
    if(value.is_object()){
        vl.result=new Array(2);vl.result->append(Name::intern(_T("recipeObject")));vl.rows=new Array(static_cast<int>(value.size()));vl.result->append(vl.rows);
        for(const auto& item:value.items()){vl.pair=new Array(2);vl.rows->append(vl.pair);vl.pair->append(recipeString(item.key()));vl.pair->append(recipeValue(item.value()));}
    }else{vl.result=new Array(static_cast<int>(value.size()));for(const auto& item:value)vl.result->append(recipeValue(item));}
    return_value(vl.result);
}
template<class F>Value* recipeAPI(F f){try{return f();}catch(const std::exception& e){throw RuntimeError(_T("Recipe: "),recipeString(e.what()));}}
}
def_visible_primitive(cyrusRecipeVersion,"cyrusRecipeVersion");
Value* cyrusRecipeVersion_cf(Value**,int n){check_arg_count(cyrusRecipeVersion,0,n);return Integer::intern(2);}
def_visible_primitive(cyrusRecipeCheckStatic,"cyrusRecipeCheckStatic");
Value* cyrusRecipeCheckStatic_cf(Value** a,int n){check_arg_count(cyrusRecipeCheckStatic,1,n);auto* owner=a[0]->to_reftarg();if(!owner)throw RuntimeError(_T("Recipe owner is missing"));
    for(int b=0;b<owner->NumParamBlocks();++b){auto* block=owner->GetParamBlock(b);if(!block)continue;for(int p=0;p<block->NumParams();++p){const auto id=block->IndextoID(p);const int entries=is_tab(block->GetParameterType(id))?block->Count(id):1;for(int i=0;i<entries;++i){auto* control=block->GetControllerByIndex(p,i);if(!control)continue;const auto type=control->ClassID();bool supported=false;if(type.PartB()==0&&control->NumKeys()==0)switch(type.PartA()){case LININTERP_FLOAT_CLASS_ID:case HYBRIDINTERP_FLOAT_CLASS_ID:case TCBINTERP_FLOAT_CLASS_ID:case HYBRIDINTERP_POINT3_CLASS_ID:case HYBRIDINTERP_COLOR_CLASS_ID:case TCBINTERP_POINT3_CLASS_ID:supported=true;break;default:break;}if(!supported){const auto* name=block->GetParamDef(id).int_name;throw RuntimeError(_T("Save Everything requires a supported static parameter controller: "),new String(name?name:_T("unnamed parameter")));}}}}
    return &ok;
}
def_visible_primitive(cyrusRecipeSchema,"cyrusRecipeSchema");
Value* cyrusRecipeSchema_cf(Value**,int n){check_arg_count(cyrusRecipeSchema,0,n);return recipeAPI([&]()->Value*{r::Json result=r::Json::array();for(const auto& f:r::fields())result.push_back({f.name,f.type,f.distance});return recipeValue(result);});}
def_visible_primitive(cyrusRecipeValidate,"cyrusRecipeValidate");
Value* cyrusRecipeValidate_cf(Value** a,int n){check_arg_count(cyrusRecipeValidate,1,n);return recipeAPI([&]()->Value*{r::validate(recipeTree(a[0]),true);return &ok;});}
def_visible_primitive(cyrusRecipeWrite,"cyrusRecipeWrite");
Value* cyrusRecipeWrite_cf(Value** a,int n){check_arg_count(cyrusRecipeWrite,2,n);return recipeAPI([&]()->Value*{type_check(a[0],String,_T("recipe filename"));r::writeNew(std::filesystem::path(a[0]->to_string()),recipeTree(a[1]));return &ok;});}
def_visible_primitive(cyrusRecipeRead,"cyrusRecipeRead");
Value* cyrusRecipeRead_cf(Value** a,int n){check_arg_count(cyrusRecipeRead,1,n);return recipeAPI([&]()->Value*{type_check(a[0],String,_T("recipe filename"));return recipeValue(r::read(std::filesystem::path(a[0]->to_string())));});}
def_visible_primitive(cyrusRecipeInfo,"cyrusRecipeInfo");
Value* cyrusRecipeInfo_cf(Value** a,int n){check_arg_count(cyrusRecipeInfo,1,n);return recipeAPI([&]()->Value*{type_check(a[0],String,_T("recipe filename"));return recipeValue(r::summary(std::filesystem::path(a[0]->to_string())));});}

namespace {
// Destroy the worker before Max unloads DLLs; joining a thread from a static
// destructor under the Windows loader lock can deadlock its thread teardown.
r::Library* libraryValue=nullptr;
bool libraryShuttingDown=false;
void libraryShutdown(void*,NotifyInfo*) {
    libraryShuttingDown=true;delete libraryValue;libraryValue=nullptr;
}
r::Library& recipeLibrary(){
    if(libraryShuttingDown)throw std::runtime_error("The library is shutting down.");
    if(!libraryValue){
        auto value=std::make_unique<r::Library>();
        if(!RegisterNotification(libraryShutdown,nullptr,NOTIFY_SYSTEM_SHUTDOWN))throw std::runtime_error("Cannot register library shutdown.");
        libraryValue=value.release();
    }
    return *libraryValue;
}
}
void cyrusRecipeLibraryShutdown(){
    libraryShutdown(nullptr,nullptr);
    UnRegisterNotification(libraryShutdown,nullptr,NOTIFY_SYSTEM_SHUTDOWN);
}
#ifndef CYRUS_TEAM_LICENSE
extern "C" __declspec(dllexport) int LibShutdown(){cyrusRecipeLibraryShutdown();return TRUE;}
#endif
def_visible_primitive(cyrusRecipeLibraryVersion,"cyrusRecipeLibraryVersion");
Value* cyrusRecipeLibraryVersion_cf(Value**,int n){check_arg_count(cyrusRecipeLibraryVersion,0,n);return Integer::intern(1);}
def_visible_primitive(cyrusRecipeLibraryStart,"cyrusRecipeLibraryStart");
Value* cyrusRecipeLibraryStart_cf(Value** a,int n){check_arg_count(cyrusRecipeLibraryStart,1,n);return recipeAPI([&]()->Value*{
    type_check(a[0],Array,_T("library folders"));auto* rows=static_cast<Array*>(a[0]);if(rows->size<1||rows->size>4)throw RuntimeError(_T("Choose one to four library folders"));
    std::vector<std::filesystem::path> paths;for(int i=0;i<rows->size;++i){type_check(rows->data[i],String,_T("library folder"));paths.emplace_back(rows->data[i]->to_string());}
    return Integer64::intern(recipeLibrary().start(std::move(paths)));});}
def_visible_primitive(cyrusRecipeLibraryPage,"cyrusRecipeLibraryPage");
Value* cyrusRecipeLibraryPage_cf(Value** a,int n){check_arg_count(cyrusRecipeLibraryPage,4,n);return recipeAPI([&]()->Value*{
    return recipeValue(recipeLibrary().page(a[0]->to_int64(),recipeUTF8(a[1],1024),recipeUTF8(a[2],96),a[3]->to_int()));});}
def_visible_primitive(cyrusRecipeLibraryCancel,"cyrusRecipeLibraryCancel");
Value* cyrusRecipeLibraryCancel_cf(Value** a,int n){check_arg_count(cyrusRecipeLibraryCancel,1,n);return recipeAPI([&]()->Value*{recipeLibrary().cancel(a[0]->to_int64());return &ok;});}
def_visible_primitive(cyrusRecipePresentationWrite,"cyrusRecipePresentationWrite");
Value* cyrusRecipePresentationWrite_cf(Value** a,int n){check_arg_count(cyrusRecipePresentationWrite,3,n);return recipeAPI([&]()->Value*{
    type_check(a[0],String,_T("recipe filename"));type_check(a[2],String,_T("thumbnail filename"));r::writePresentation(std::filesystem::path(a[0]->to_string()),recipeTree(a[1]),std::filesystem::path(a[2]->to_string()));return &ok;});}
def_visible_primitive(cyrusRecipeThumbnail,"cyrusRecipeThumbnail");
Value* cyrusRecipeThumbnail_cf(Value** a,int n){check_arg_count(cyrusRecipeThumbnail,1,n);return recipeAPI([&]()->Value*{
    type_check(a[0],String,_T("recipe filename"));return new String(r::thumbnail(std::filesystem::path(a[0]->to_string())).c_str());});}
