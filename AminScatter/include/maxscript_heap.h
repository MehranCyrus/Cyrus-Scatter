#pragma once
// Host-thread admission. Never change heap preferences or flush Undo.
#include <maxscript/foundation/hashtable.h>
#include <maxscript/foundation/name.h>
#include <maxscript/foundation/numbers.h>
#include <maxscript/compiler/thunks.h>
#include <cstdint>

namespace cyrus::host {
inline std::uint64_t scriptHeapFree() {
    auto* value=static_cast<Value*>(globals->get(Name::intern(_T("heapfree"))));
    if(!value||!is_systemglobalthunk(value))throw RuntimeError(_T("MAXScript heap admission is unavailable. The scene is unchanged."));
    const auto bytes=value->eval()->to_int64();
    return bytes>0?static_cast<std::uint64_t>(bytes):0;
}
inline void admitScriptHeap(std::uint64_t bytes) {
    // Small summaries do not become a new idle/selection constraint. Large
    // hydration is explicit, bounded and rejected before allocating its values.
    if(bytes<65536)return;
    constexpr std::uint64_t reserve=8*1024*1024;
    auto available=scriptHeapFree();
    if(bytes>available||available-bytes<reserve) {
        // At this boundary no output MAXScript values have been constructed.
        // Reclaim ordinary temporary arrays/strings before rejecting; light
        // collection retains MAXWrapper values and the complete Undo history.
        // The fixed literal is our code, never package/document content.
        ExecuteMAXScriptScript(_T("gc light:true"),MAXScript::ScriptSource::Dynamic,TRUE);
    }
    if(bytes>scriptHeapFree()||scriptHeapFree()-bytes<reserve)
        throw RuntimeError(_T("This recipe needs more free MAXScript working memory to preserve Undo. Reduce its layer/Paint content or use a less loaded scene. Recipe data allocation was stopped."));
}
}
