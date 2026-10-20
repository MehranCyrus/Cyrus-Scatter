#include "diagnostics.h"
#include <tlhelp32.h>
#include <psapi.h>
#include <filesystem>
#include <mutex>
#include <fstream>
#include <cstdio>
#include "core.h"

namespace cpl::diag {
namespace {
std::mutex mutex;
std::filesystem::path folder;
HANDLE events=INVALID_HANDLE_VALUE,exceptionFile=INVALID_HANDLE_VALUE;
HANDLE crashEvent=nullptr,readyEvent=nullptr,mapping=nullptr,watcherHandle=nullptr;
CrashPacket* packet=nullptr;
std::uint64_t sequence=0,bytes=0;
unsigned segment=0,snapshotSlot=0;
DWORD watcherPid=0,lastError=0;
bool attempted=false,watcherReady=false;
PVOID exceptionHandler=nullptr;
constexpr std::uint64_t maxSegment=8*1024*1024;
LONG WINAPI exceptionNotice(EXCEPTION_POINTERS* info){
    if(!info||!info->ExceptionRecord)return EXCEPTION_CONTINUE_SEARCH;
    const DWORD code=info->ExceptionRecord->ExceptionCode;
    switch(code){case EXCEPTION_ACCESS_VIOLATION:case EXCEPTION_IN_PAGE_ERROR:case EXCEPTION_ILLEGAL_INSTRUCTION:
        case EXCEPTION_INT_DIVIDE_BY_ZERO:case EXCEPTION_STACK_OVERFLOW:case 0xc0000374:case 0xc0000409:break;
        default:return EXCEPTION_CONTINUE_SEARCH;}
    char line[192];
    int length=_snprintf_s(line,sizeof(line),_TRUNCATE,"fatal-code notification code=0x%08lx thread=%lu address=0x%llx\r\n",code,GetCurrentThreadId(),static_cast<unsigned long long>(reinterpret_cast<ULONG_PTR>(info->ExceptionRecord->ExceptionAddress)));
    if(exceptionFile!=INVALID_HANDLE_VALUE&&length>0){DWORD written=0;WriteFile(exceptionFile,line,DWORD(length),&written,nullptr);FlushFileBuffers(exceptionFile);}
    if(packet&&InterlockedCompareExchange(&packet->busy,1,0)==0){
        packet->thread=GetCurrentThreadId();
        memcpy(&packet->record,info->ExceptionRecord,sizeof(EXCEPTION_RECORD));
        packet->record.ExceptionRecord=nullptr;
        memcpy(&packet->context,info->ContextRecord,sizeof(CONTEXT));
        MemoryBarrier();SetEvent(crashEvent);
    }
    // Never swallow the exception, wait for the watcher, or replace Max's handler.
    return EXCEPTION_CONTINUE_SEARCH;
}
void openSegment(){
    events=CreateFileW((folder/(L"events-"+std::to_wstring(segment)+L".jsonl")).c_str(),GENERIC_WRITE,FILE_SHARE_READ,nullptr,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL|FILE_FLAG_WRITE_THROUGH,nullptr);
    bytes=0;if(events==INVALID_HANDLE_VALUE)lastError=GetLastError();
}
std::string utf8(const std::wstring& s){int count=WideCharToMultiByte(CP_UTF8,0,s.data(),int(s.size()),nullptr,0,nullptr,nullptr);std::string out(count,'\0');WideCharToMultiByte(CP_UTF8,0,s.data(),int(s.size()),out.data(),count,nullptr,nullptr);return out;}
}
void start(HMODULE module) noexcept {
 try{
    {std::lock_guard lock(mutex);if(attempted)return;attempted=true;
     wchar_t root[32768]{};DWORD count=GetEnvironmentVariableW(L"CYRUS_PHYSICS_LOG_DIR",root,32768);
     if(!count||count>=32768){count=GetEnvironmentVariableW(L"LOCALAPPDATA",root,32768);if(!count||count>=32768){lastError=ERROR_PATH_NOT_FOUND;return;}folder=std::filesystem::path(root)/L"Cyrus/PhysicsLab/Diagnostics";}else folder=root;
     SYSTEMTIME time;GetSystemTime(&time);wchar_t stamp[128];swprintf_s(stamp,L"%04u%02u%02u-%02u%02u%02u-%03u-pid%lu",time.wYear,time.wMonth,time.wDay,time.wHour,time.wMinute,time.wSecond,time.wMilliseconds,GetCurrentProcessId());
     folder/=stamp;std::filesystem::create_directories(folder);openSegment();
     exceptionFile=CreateFileW((folder/L"exception.txt").c_str(),FILE_APPEND_DATA,FILE_SHARE_READ,nullptr,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL|FILE_FLAG_WRITE_THROUGH,nullptr);
     std::wstring base=L"Local\\CyrusPhysics-"+std::wstring(stamp);
     crashEvent=CreateEventW(nullptr,FALSE,FALSE,(base+L"-exception").c_str());readyEvent=CreateEventW(nullptr,TRUE,FALSE,(base+L"-ready").c_str());
     mapping=CreateFileMappingW(INVALID_HANDLE_VALUE,nullptr,PAGE_READWRITE,0,sizeof(CrashPacket),(base+L"-packet").c_str());
     packet=mapping?static_cast<CrashPacket*>(MapViewOfFile(mapping,FILE_MAP_ALL_ACCESS,0,0,sizeof(CrashPacket))):nullptr;
     if(!crashEvent||!readyEvent||!packet)lastError=GetLastError();
     exceptionHandler=AddVectoredExceptionHandler(1,exceptionNotice);
     wchar_t modulePath[32768];GetModuleFileNameW(module,modulePath,32768);
     auto helper=std::filesystem::path(modulePath).parent_path()/L"CyrusPhysicsCrashWatch.exe";
     FILETIME created,exit,kernel,user;GetProcessTimes(GetCurrentProcess(),&created,&exit,&kernel,&user);
     ULONGLONG identity=ULONGLONG(created.dwHighDateTime)<<32|created.dwLowDateTime;
     std::wstring command=L"\""+helper.wstring()+L"\" "+std::to_wstring(GetCurrentProcessId())+L" \""+base+L"\" \""+folder.wstring()+L"\" "+std::to_wstring(identity);
     STARTUPINFOW startup{};startup.cb=sizeof(startup);startup.dwFlags=STARTF_USESHOWWINDOW;startup.wShowWindow=SW_HIDE;PROCESS_INFORMATION process{};
     if(packet&&CreateProcessW(helper.c_str(),command.data(),nullptr,nullptr,FALSE,CREATE_NO_WINDOW,nullptr,nullptr,&startup,&process)){
         watcherPid=process.dwProcessId;CloseHandle(process.hThread);watcherHandle=process.hProcess;watcherReady=WaitForSingleObject(readyEvent,3000)==WAIT_OBJECT_0;
         if(!watcherReady)lastError=WAIT_TIMEOUT;
     }else lastError=GetLastError();
    }
    Json modules=Json::array();HANDLE snap=CreateToolhelp32Snapshot(TH32CS_SNAPMODULE,GetCurrentProcessId());MODULEENTRY32W item{};item.dwSize=sizeof(item);
    if(snap!=INVALID_HANDLE_VALUE){if(Module32FirstW(snap,&item))do{modules.push_back({{"name",utf8(item.szModule)},{"path",utf8(item.szExePath)},{"base",reinterpret_cast<ULONG_PTR>(item.modBaseAddr)},{"size",item.modBaseSize}});}while(Module32NextW(snap,&item));CloseHandle(snap);}
    snapshot("modules",modules.dump());
    wchar_t modulePath[32768];GetModuleFileNameW(module,modulePath,32768);
    auto identity=std::filesystem::path(modulePath).parent_path()/L"build-identity.json";
    if(std::filesystem::exists(identity)){std::ifstream in(identity,std::ios::binary);std::string value((std::istreambuf_iterator<char>(in)),{});snapshot("build-identity",value);}
    record("diagnostics.start",status());
 }catch(...){lastError=ERROR_WRITE_FAULT;}
}
void record(const char* event,const std::string& data) noexcept {
 try{std::lock_guard lock(mutex);if(events==INVALID_HANDLE_VALUE)return;
    if(bytes>=maxSegment){CloseHandle(events);segment=(segment+1)%4;openSegment();}
    FILETIME now;GetSystemTimeAsFileTime(&now);LARGE_INTEGER counter;QueryPerformanceCounter(&counter);
    Json line={{"seq",++sequence},{"utc_filetime",ULONGLONG(now.dwHighDateTime)<<32|now.dwLowDateTime},{"qpc",counter.QuadPart},{"thread",GetCurrentThreadId()},{"event",event},{"data",Json::parse(data)}};
    auto value=line.dump()+"\n";DWORD written=0;
    if(!WriteFile(events,value.data(),DWORD(value.size()),&written,nullptr)||written!=value.size()||!FlushFileBuffers(events))lastError=GetLastError();bytes+=written;
 }catch(...){lastError=ERROR_WRITE_FAULT;}
}
void snapshot(const char* name,const std::string& value) noexcept {
 try{if(folder.empty())return;if(value.size()>32*1024*1024){record("snapshot.limit",Json({{"name",name},{"bytes",value.size()}}).dump());return;}
    const std::string key=std::string(name);
    const std::string fileName=(key=="modules"||key=="build-identity")?key:("context-"+std::to_string(snapshotSlot++%8));
    auto target=folder/(fileName+".json"),temp=target;temp+=L".tmp";
    HANDLE file=CreateFileW(temp.c_str(),GENERIC_WRITE,FILE_SHARE_READ,nullptr,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL|FILE_FLAG_WRITE_THROUGH,nullptr);
    if(file==INVALID_HANDLE_VALUE){lastError=GetLastError();return;}DWORD written=0;
    BOOL ok=WriteFile(file,value.data(),DWORD(value.size()),&written,nullptr);FlushFileBuffers(file);CloseHandle(file);
    if(!ok||written!=value.size()||!MoveFileExW(temp.c_str(),target.c_str(),MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH))lastError=GetLastError();
    record("snapshot.written",Json({{"name",name},{"file",fileName+".json"},{"bytes",value.size()}}).dump());
 }catch(...){lastError=ERROR_WRITE_FAULT;}
}
std::wstring directory() noexcept {try{return folder.wstring();}catch(...){return{};}}
void detach() noexcept {if(exceptionHandler){RemoveVectoredExceptionHandler(exceptionHandler);exceptionHandler=nullptr;}}
std::string status() noexcept {try{DWORD exit=0;bool alive=watcherHandle&&GetExitCodeProcess(watcherHandle,&exit)&&exit==STILL_ACTIVE;if(watcherReady&&!alive){watcherReady=false;lastError=ERROR_PROCESS_ABORTED;}PROCESS_MEMORY_COUNTERS_EX memory{};memory.cb=sizeof(memory);bool measured=GetProcessMemoryInfo(GetCurrentProcess(),reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&memory),sizeof(memory))!=FALSE;return Json({{"version","0.2.1"},{"folder",utf8(folder.wstring())},{"recording",events!=INVALID_HANDLE_VALUE},{"watcher_ready",watcherReady},{"watcher_alive",alive},{"watcher_pid",watcherPid},{"error",lastError},{"event_segment_bytes",maxSegment},{"event_segments",4},{"max_dumps",2},{"memory",{{"available",measured},{"working_set_bytes",memory.WorkingSetSize},{"private_bytes",memory.PrivateUsage},{"peak_working_set_bytes",memory.PeakWorkingSetSize}}}}).dump();}catch(...){return"{}";}}
}
