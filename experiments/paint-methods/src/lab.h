#pragma once
#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>
#include <cmath>
#include <stdexcept>
#include <sstream>
namespace paintlab {
struct V { double x=0,y=0,z=0; V operator+(V b)const{return{x+b.x,y+b.y,z+b.z};} V operator-(V b)const{return{x-b.x,y-b.y,z-b.z};} V operator*(double s)const{return{x*s,y*s,z*s};} };
inline double dot(V a,V b){return a.x*b.x+a.y*b.y+a.z*b.z;}
inline V cross(V a,V b){return{a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x};}
inline double length(V a){return std::sqrt(dot(a,a));}
inline V unit(V a){double n=length(a);if(n<1e-12)throw std::runtime_error("Degenerate surface");return a*(1/n);}
struct Anchor {unsigned face=0; V bary{1,0,0};};
struct Mesh {std::vector<V> vertices;std::vector<std::array<unsigned,3>> faces;V position(Anchor a)const; std::uint64_t topology()const;std::uint64_t fingerprint()const;};
struct Hit {Anchor anchor;V p;double radius=1;bool connected=false;};
struct Settings {bool erase=false;double strength=1,softness=0;};
struct Segment {Hit a,b;Settings settings;unsigned gesture=0;};
double influence(V p,const Segment& s);
struct Frame {V origin,u,v,n; explicit Frame(const Mesh& m);V project(V p)const{return{dot(p-origin,u),dot(p-origin,v),0};}V lift(V p)const{return origin+u*p.x+v*p.y;}};
struct Stats {std::uint64_t edits=0,queries=0,tests=0,touched=0;std::size_t bytes=0,items=0;};
class Kernel {
public:
 virtual ~Kernel()=default;
 virtual std::unique_ptr<Kernel> clone()const=0;
 virtual void begin(Settings)=0;
 virtual void append(Hit)=0;
 virtual void end()=0;
 virtual double query(Anchor,V)const=0;
 virtual std::string save()const=0;
 virtual void load(const std::string&)=0;
 virtual Stats stats()const=0;
 virtual std::vector<std::array<V,2>> exactBoundary()const{return{};}
};
std::unique_ptr<Kernel> makeVector(const Mesh&,double);
std::unique_ptr<Kernel> makeMask(const Mesh&,double);
std::unique_ptr<Kernel> makeVolumes(const Mesh&,double);
std::unique_ptr<Kernel> makeField(const Mesh&,double);
std::unique_ptr<Kernel> make(int method,const Mesh&,double);
class Session {
 int method_;Mesh mesh_;double resolution_;std::unique_ptr<Kernel> state_,pending_;
 std::vector<std::unique_ptr<Kernel>> undo_,redo_;
public:
 Session(int method,Mesh mesh,double resolution);
 void begin(Settings);void append(Hit);void commit();void cancel();void undo();void redo();void clear();
 const Kernel& view()const{return pending_?*pending_:*state_;}
 bool active()const{return bool(pending_);}const Mesh& mesh()const{return mesh_;}double resolution()const{return resolution_;}
 std::string save()const;void load(const std::string&);std::size_t historyBytes()const;
};
struct Preview {std::vector<std::array<V,2>> lines;std::vector<std::array<V,3>> fill;std::vector<V> points;std::vector<double> fillWeights,pointWeights;double queryMs=0,boundaryMs=0;};
Preview preview(const Session&,bool points,bool fill,double step);
}
