#pragma once
#include <string>
#include <stdexcept>
// Binding settings can contain artist node labels. Preserve Unicode exactly.
inline std::string receiverUTF8(const std::wstring& value){
    if(value.empty())return {};
    const int count=WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,value.data(),int(value.size()),nullptr,0,nullptr,nullptr);
    if(count<=0)throw std::invalid_argument("Invalid receiver binding text");
    std::string out(std::size_t(count),'\0');WideCharToMultiByte(CP_UTF8,WC_ERR_INVALID_CHARS,value.data(),int(value.size()),out.data(),count,nullptr,nullptr);return out;
}
inline std::wstring receiverWide(const std::string& value){
    if(value.empty())return {};
    const int count=MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,value.data(),int(value.size()),nullptr,0);
    if(count<=0)throw std::invalid_argument("Invalid receiver binding text");
    std::wstring out(std::size_t(count),L'\0');MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,value.data(),int(value.size()),out.data(),count);return out;
}
