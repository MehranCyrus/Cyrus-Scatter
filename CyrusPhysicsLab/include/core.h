#pragma once
#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <stdexcept>
#include <vector>
#include <nlohmann/json.hpp>

namespace cpl {
using Json = nlohmann::json;
struct Vec { double x=0,y=0,z=0; Vec operator+(Vec b)const{return{x+b.x,y+b.y,z+b.z};}
 Vec operator-(Vec b)const{return{x-b.x,y-b.y,z-b.z};} Vec operator*(double s)const{return{x*s,y*s,z*s};} };
double dot(Vec,Vec); double length(Vec); Vec cross(Vec,Vec); Vec normalized(Vec);
struct Quat { double x=0,y=0,z=0,w=1; };
Vec rotate(Quat,Vec);
struct Mesh {std::vector<Vec> vertices;std::vector<std::array<unsigned,3>> faces;
 std::vector<Vec> uv;std::vector<std::array<unsigned,3>> uvFaces;std::vector<unsigned> smoothing;};
struct Source {Mesh render;std::vector<std::vector<Vec>> hulls;double weight=1;};
struct Row {std::uint64_t id=0,gesture=0;unsigned source=0;Vec position;Quat rotation;double scale=1;};
struct Birth:Row {unsigned step=0;Vec velocity,spin;};
struct Settings {
 double dt=1./120,friction=.6,bounce=.05,damping=.2,gravity=9.81,quietLinear=.002,quietAngular=.05;
 double radius=.25,spacing=.08,height=.4,thickness=.002,scaleMin=.8,scaleMax=1.2,stickiness=0;
 unsigned maxBodies=5000,maxPairs=65536,maxContacts=65536,maxSteps=3600,quietSteps=60,seed=42;
 unsigned collisionSteps=4;
 bool ccd=true;
 bool operator==(const Settings&)const = default;
};
struct Input {Settings settings;std::vector<Source> sources;std::vector<Mesh> colliders;std::vector<Row> frozen;};
using CollisionLine=std::array<Vec,2>;
struct CollisionGeometry {
 std::vector<std::vector<CollisionLine>> sources;
 std::vector<CollisionLine> colliders;
 std::size_t segments=0;bool limited=false;
};
// Explicit inspection preparation only. Never called by viewport redraw.
std::shared_ptr<const CollisionGeometry> joltCollisionGeometry(const Input&);
// Builds the same static shape as the worker; reports admission/cooking detail.
Json joltColliderInfo(const Mesh&);
void joltValidateSource(const Source&,double thickness);
double joltSimulationScale(const Input&);
double joltContactDistance(const Input&);
struct BodyState {Row row;Vec velocity,spin;bool sleeping=false;};
// In-memory only. Persist canonical births/steps, never trust a file as Jolt state.
struct WorldCheckpoint {std::string data;std::vector<std::pair<Birth,std::uint32_t>> bodies;};
struct World {
 virtual ~World()=default;
 virtual void add(const Birth&)=0;
 virtual void addBatch(const std::vector<Birth>& values){for(const auto& b:values)add(b);}
 virtual void step()=0;
 virtual std::vector<BodyState> states()const=0;
 virtual void remove(std::uint64_t){throw std::runtime_error("World removal unsupported");}
 virtual std::shared_ptr<const WorldCheckpoint> checkpoint()const{throw std::runtime_error("World checkpoints unsupported");}
 virtual void restore(const WorldCheckpoint&){throw std::runtime_error("World restore unsupported");}
};
std::unique_ptr<World> joltWorld(const Input&);
std::unique_ptr<World> physxWorld(const Input&);
void validate(const Input&);
Source boxSource(Vec half);
Mesh boxMesh(Vec half,Vec center={});
bool exactBox(const Mesh&,Vec& half,Vec& center);
bool flatRectangle(const Mesh&,Vec& half,Vec& center);
Source proxySource(Mesh render,Mesh proxy,double thickness,bool automatic=false);
// Explicit copied-data preparation; quality 0 preserves the old single hull.
Source qualitySource(Mesh render,double thickness,unsigned quality,unsigned pieces,double volumeError);
Json encodeRow(const Row&);Row decodeRow(const Json&);
Json encodeBirth(const Birth&);Birth decodeBirth(const Json&);
Json encodeInput(const Input&);Input decodeInput(const Json&);

struct Hit {Vec point,normal;double distance=0;unsigned face=0;};
bool rayHit(const Mesh&,Vec origin,Vec direction,Hit&);
class Surface {
 struct Node {Vec lo,hi;unsigned begin=0,count=0,left=0,right=0;};
 Mesh mesh;std::vector<unsigned> order;std::vector<Node> nodes;
 unsigned build(unsigned,unsigned);
public:
 explicit Surface(Mesh);
 bool hit(Vec origin,Vec direction,Hit&)const;
 // Conservative upper height of triangles whose XY bounds overlap this footprint.
 bool heightBound(Vec lo,Vec hi,double&)const;
};
class Emitter {
 Settings settings;std::uint64_t gesture,next;bool connected=false;Vec last;double remainder=0;
 std::vector<double> weights;
 Birth birth(Vec,Vec,unsigned);
public:
 Emitter(const Settings&,std::uint64_t gesture,std::uint64_t first,const std::vector<Source>&);
 std::vector<Birth> sample(Vec point,Vec normal,bool hit,unsigned step);
 std::uint64_t nextId()const{return next;}
};
class Session {
 Input input;std::unique_ptr<World> world;std::vector<Birth> births;
 unsigned steps=0,quiet=0;bool released=false,completed=false,cancelled=false;
 Json motion=Json::object();
public:
 Session(Input,std::unique_ptr<World> (*factory)(const Input&)=joltWorld);
 void emit(const std::vector<Birth>&);
 bool tick(unsigned maximumSteps);
 void release(){released=true;}
 void acceptUnsettled(){released=true;completed=true;}
 void cancel(){cancelled=true;world.reset();}
 bool done()const{return completed;}
 unsigned stepCount()const{return steps;}
 const Json& diagnostics()const{return motion;}
 std::vector<Row> rows()const;
 const std::vector<Birth>& recipe()const{return births;}
};
}
