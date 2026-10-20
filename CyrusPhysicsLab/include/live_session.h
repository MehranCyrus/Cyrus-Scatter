#pragma once
#include "core.h"
#include <atomic>
#include <condition_variable>
#include <deque>
#include <functional>
#include <mutex>
#include <map>
#include <thread>

namespace cpl {
using LiveTrace = std::function<void(const char*, const Json&)>;
struct LiveView {
 std::vector<BodyState> bodies;
 unsigned step=0,active=0,lost=0,skipped=0,blocked=0,undo=0,redo=0;
 std::uint64_t revision=0,sequence=0,nextId=1,nextGesture=1;
 bool paused=false,gesture=false,finishing=false,done=false,settled=false,ready=false;
 double lostZ=0,lastStepMs=0,debtSeconds=0;
 std::size_t historyBytes=0,queued=0;
 std::string error;
};

// Deterministic numeric owner. No Max objects, UI calls, wall clock or threads.
class ContinuousCore {
 struct Point {
  std::shared_ptr<const WorldCheckpoint> world;
  std::vector<Birth> births;
  std::vector<std::pair<std::uint64_t,unsigned>> lost;
  unsigned step=0,quiet=0,skipped=0,blocked=0;
 };
 struct History {std::shared_ptr<const Point> before,after;};
 Input input;Mesh receiver;Surface surface;std::unique_ptr<World> world;
 std::vector<Birth> births;
 std::vector<std::pair<std::uint64_t,unsigned>> lost;
 std::vector<History> undo,redo;
 std::shared_ptr<const Point> gestureStart;
 std::unique_ptr<Emitter> emitter;
 unsigned step=0,quiet=0,finishStep=0,skipped=0,blocked=0;
 std::uint64_t nextId=1,nextGesture=1,revision=1;
 bool finishing=false,done=false,settled=false;
 double lostZ=0;
 std::size_t historyLimit=64*1024*1024;
 LiveTrace trace;
 std::function<bool()> cancelled;
 std::shared_ptr<const Point> checkpoint()const;
 void restore(const Point&);
 void cull(World&,unsigned,std::vector<std::pair<std::uint64_t,unsigned>>&)const;
 void emit(std::vector<Birth>);
 Json encodePoint(const Point&,bool identitiesOnly=false)const;
 std::shared_ptr<const Point> decodePoint(const Json&,const std::map<std::uint64_t,Birth>* catalog=nullptr)const;
 void event(const char*,Json=Json::object())const;
public:
 ContinuousCore(Input,Mesh,std::uint64_t firstId=1,std::uint64_t firstGesture=1,
                LiveTrace={},std::function<bool()> cancelled={});
 void beginGesture();
 void sample(Vec,Vec,bool);
 void endGesture();
 void cancelGesture();
 void undoGesture();
 void redoGesture();
 void advance(unsigned count=1);
 void finish();
 void freeze();
 void continueAuthoring();
 LiveView view()const;
 bool isDone()const{return done;}
 unsigned stepCount()const{return step;}
 const std::vector<Birth>& recipe()const{return births;}
 Json archive()const;
 void recover(const Json&);
 std::size_t historyBytes()const;
 void setHistoryLimit(std::size_t bytes){historyLimit=bytes;}
 static const char* solverIdentity();
};

enum class LiveCommandKind {Begin,Sample,End,CancelGesture,Pause,Resume,Finish,Freeze,Undo,Redo,Barrier,Archive,Result};
struct LiveCommand {
 LiveCommandKind kind=LiveCommandKind::Barrier;
 Vec point,normal;bool hit=false;
 std::uint64_t sequence=0;
};

// The worker is the sole caller of ContinuousCore. Host reads immutable snapshots.
class LiveSession {
 std::mutex mutex;std::condition_variable wake;
 std::deque<LiveCommand> commands;
 std::shared_ptr<const LiveView> published=std::make_shared<LiveView>();
 Json savedArchive;
 std::uint64_t archiveSequence=0;
 std::atomic<bool> stopping=false;
 std::thread worker;
 std::uint64_t submitted=0,completed=0;
 LiveTrace trace;
 std::function<void(const Json&)> recoverySink;
 void run(Input,Mesh,std::uint64_t,std::uint64_t,Json)noexcept;
public:
 LiveSession(Input,Mesh,std::uint64_t,std::uint64_t,LiveTrace={},
             std::function<void(const Json&)> recoverySink={},Json recovery=Json());
 ~LiveSession();
 LiveSession(const LiveSession&)=delete;
 LiveSession& operator=(const LiveSession&)=delete;
 std::uint64_t send(LiveCommandKind,Vec={},Vec={},bool=false);
 bool wait(std::uint64_t,unsigned milliseconds=5000);
 std::shared_ptr<const LiveView> view();
 Json archive(bool resultOnly=false); // Explicit synchronization; never called by PaintStroke.
 void stop();
};
}
