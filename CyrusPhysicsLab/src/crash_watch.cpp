#include "diagnostics.h"
#include <dbghelp.h>
#include <filesystem>
#include <fstream>
#include <string>

// Separate process; does not attach as a debugger or change Max's exception policy.
int wmain(int count,wchar_t** args) {
    if(count!=5)return 2;
    const DWORD pid=wcstoul(args[1],nullptr,10);
    const std::wstring base=args[2];
    const std::filesystem::path folder=args[3];
    const auto expectedCreation=_wcstoui64(args[4],nullptr,10);
    HANDLE parent=OpenProcess(PROCESS_QUERY_INFORMATION|PROCESS_VM_READ|SYNCHRONIZE,FALSE,pid);
    if(!parent)return 3;
    FILETIME created,exited,kernel,user;
    if(!GetProcessTimes(parent,&created,&exited,&kernel,&user)||
       (ULONGLONG(created.dwHighDateTime)<<32|created.dwLowDateTime)!=expectedCreation)return 4;
    HANDLE event=OpenEventW(SYNCHRONIZE,FALSE,(base+L"-exception").c_str());
    HANDLE ready=OpenEventW(EVENT_MODIFY_STATE,FALSE,(base+L"-ready").c_str());
    HANDLE mapping=OpenFileMappingW(FILE_MAP_ALL_ACCESS,FALSE,(base+L"-packet").c_str());
    auto* shared=mapping?static_cast<cpl::diag::CrashPacket*>(MapViewOfFile(mapping,FILE_MAP_ALL_ACCESS,0,0,sizeof(cpl::diag::CrashPacket))):nullptr;
    if(!event||!ready||!shared)return 5;
    SetEvent(ready);
    unsigned dumps=0;
    HANDLE waiting[]{event,parent};
    for(;;){
        DWORD signalled=WaitForMultipleObjects(2,waiting,FALSE,INFINITE);
        if(signalled==WAIT_OBJECT_0+1){
            DWORD code=0;GetExitCodeProcess(parent,&code);
            std::ofstream out(folder/L"process-exit.json",std::ios::binary);
            out<<"{\"pid\":"<<pid<<",\"exit_code\":"<<code<<",\"exception_notifications\":"<<dumps<<"}\n";
            break;
        }
        if(signalled!=WAIT_OBJECT_0)break;
        cpl::diag::CrashPacket local;
        memcpy(&local,shared,sizeof(local));
        // Keep the first successful fault context and the newest later one.
        const unsigned slot=dumps++==0?1:2;
        const std::wstring name=L"exception-"+std::to_wstring(slot)+L".dmp";
        const auto target=folder/name;
        auto temporary=target;temporary+=L".tmp";
        bool ok=false;DWORD failure=0;
        {
            HANDLE file=CreateFileW(temporary.c_str(),GENERIC_WRITE,FILE_SHARE_READ,nullptr,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL|FILE_FLAG_WRITE_THROUGH,nullptr);
            if(file!=INVALID_HANDLE_VALUE){
                EXCEPTION_POINTERS pointers{&local.record,&local.context};
                MINIDUMP_EXCEPTION_INFORMATION info{local.thread,&pointers,FALSE};
                auto flags=MINIDUMP_TYPE(MiniDumpNormal|MiniDumpWithThreadInfo|MiniDumpWithUnloadedModules|MiniDumpWithProcessThreadData);
                ok=MiniDumpWriteDump(parent,pid,file,flags,&info,nullptr,nullptr)!=FALSE;
                if(!ok)failure=GetLastError();
                FlushFileBuffers(file);CloseHandle(file);
                if(ok&&!MoveFileExW(temporary.c_str(),target.c_str(),MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH)){ok=false;failure=GetLastError();}
                if(!ok)DeleteFileW(temporary.c_str());
            }else failure=GetLastError();
        }
        std::string status="{\"notification\":"+std::to_string(dumps)+",\"thread\":"+std::to_string(local.thread)+",\"exception_code\":"+std::to_string(local.record.ExceptionCode)
           +",\"address\":"+std::to_string(reinterpret_cast<ULONG_PTR>(local.record.ExceptionAddress))+",\"dump_written\":"+(ok?"true":"false")
           +",\"error\":"+std::to_string(failure)+",\"file\":\"exception-"+std::to_string(slot)+".dmp\",\"previous_complete_dump_retained\":"+(!ok&&std::filesystem::exists(target)?"true":"false")+"}\n";
        {std::ofstream out(folder/L"dump-status.json",std::ios::binary);out<<status;}
        {std::ofstream out(folder/L"dump-attempts.jsonl",std::ios::binary|std::ios::app);out<<status;}
        if(ok){std::ofstream out(folder/(name+L".json"),std::ios::binary);out<<status;}
        InterlockedExchange(&shared->busy,0);
    }
    UnmapViewOfFile(shared);CloseHandle(mapping);CloseHandle(ready);CloseHandle(event);CloseHandle(parent);
    return 0;
}
