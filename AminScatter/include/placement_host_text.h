#pragma once
// Host-only bounded UTF-8 capture. Preserve full MSTR length and reject embedded
// NUL instead of silently truncating an identity/signature at a C string boundary.
#include <maxscript/foundation/strings.h>
#include <string>

namespace cyrus::placements::host {
inline std::string text(Value* value,std::size_t maximumUnits,std::size_t maximumBytes){
    type_check(value,String,_T("publication text"));const MSTR captured=value->to_mstr();
    const auto length=captured.Length();
    if(length<0||std::size_t(length)>maximumUnits)throw RuntimeError(_T("Publication text exceeds its character bound"));
    const std::wstring wide(captured.data(),std::size_t(length));
    if(wide.find(L'\0')!=std::wstring::npos)throw RuntimeError(_T("Publication text contains an embedded NUL"));
    if(wide.empty())return {};
    const auto size=WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,wide.data(),length,nullptr,0,nullptr,nullptr);
    if(size<=0||std::size_t(size)>maximumBytes)throw RuntimeError(_T("Invalid or oversized UTF-8 publication text"));
    std::string result(std::size_t(size),'\0');WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,wide.data(),length,result.data(),size,nullptr,nullptr);return result;
}
inline Value* string(const std::string& value){
    if(value.empty())return new String(_T(""));
    const auto size=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,value.data(),int(value.size()),nullptr,0);
    if(size<=0)throw RuntimeError(_T("Invalid UTF-8 publication text"));std::wstring result(std::size_t(size),L'\0');
    MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,value.data(),int(value.size()),result.data(),size);return new String(result.c_str());
}
}
