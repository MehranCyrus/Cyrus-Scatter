#include "path_capture.h"
#include <shape.h>
#include <splshape.h>
#include <cmath>
#include <stdexcept>
namespace cyrus::arrange::host {
namespace {
ShapeObject* shape(INode* node,std::uint32_t index,TimeValue time){
    if(!node)throw std::runtime_error("The path was deleted. Pick a spline again or clear the path.");
    auto* object=node->EvalWorldState(time).obj;
    if(!object||object->SuperClassID()!=SHAPE_CLASS_ID)throw std::runtime_error("Pick an evaluated spline shape, not an extruded mesh.");
    auto* result=static_cast<ShapeObject*>(object);
    if(!result->CanMakeBezier())throw std::runtime_error("This path cannot provide Bezier curves. Convert a copy to an editable spline.");
    const auto count=result->NumberOfCurves(time);
    if(count<1||count>256||index>=static_cast<std::uint32_t>(count))throw std::runtime_error("Choose an existing curve within the 256-curve path limit.");
    std::size_t pieces=0;
    for(int i=0;i<count;++i){const int n=result->NumberOfPieces(time,i);if(n<1||static_cast<std::size_t>(n)>4096-pieces)throw std::runtime_error("Path shape exceeds 4096 total segments. Detach or simplify the selected curve.");pieces+=n;}
    return result;
}
}
void validate_path_node(INode* node,std::uint32_t index,TimeValue time){shape(node,index,time);}
CapturedPath capture_path(INode* node,std::uint32_t index,Vec3 origin,double unit,TimeValue time){
    if(!node||!std::isfinite(unit)||unit<=0)throw std::runtime_error("Missing path or invalid system units.");
    CapturedPath result;const auto transform=node->GetObjTMAfterWSM(time,&result.validity);
    const auto a=transform.GetRow(0),b=transform.GetRow(1),c=transform.GetRow(2),d=transform.GetRow(3);
    const auto world=[&](Point3 p){Vec3 value{(static_cast<double>(p.x)*a.x+static_cast<double>(p.y)*b.x+static_cast<double>(p.z)*c.x+d.x)*unit-origin.x,(static_cast<double>(p.x)*a.y+static_cast<double>(p.y)*b.y+static_cast<double>(p.z)*c.y+d.y)*unit-origin.y,(static_cast<double>(p.x)*a.z+static_cast<double>(p.y)*b.z+static_cast<double>(p.z)*c.z+d.z)*unit-origin.z};
        if(!std::isfinite(value.x)||!std::isfinite(value.y)||!std::isfinite(value.z))throw std::runtime_error("Path transform contains nonfinite coordinates.");return value;};
    auto* source=shape(node,index,time);result.validity&=source->ObjectValidity(time);BezierShape copied;source->MakeBezier(time,copied);
    if(copied.SplineCount()<1||copied.SplineCount()>256||index>=static_cast<std::uint32_t>(copied.SplineCount()))throw std::runtime_error("Evaluated Bezier curve count changed during capture.");
    std::size_t total=0;for(int i=0;i<copied.SplineCount();++i){auto* spline=copied.GetSpline(i);if(!spline||spline->Segments()<1||static_cast<std::size_t>(spline->Segments())>4096-total)throw std::runtime_error("Evaluated path exceeds segment admission.");total+=spline->Segments();}
    auto* spline=copied.GetSpline(static_cast<int>(index));const int knots=spline->KnotCount(),segments=spline->Segments();result.closed=spline->Closed()!=0;
    if(knots<2||knots>4097||segments!=(result.closed?knots:knots-1))throw std::runtime_error("Evaluated path knot/segment structure is invalid.");
    std::vector<Vec3> points;points.reserve(knots);for(int i=0;i<knots;++i)points.push_back(world(spline->GetKnotPoint(i)));
    result.curves.reserve(segments);
    for(int i=0;i<segments;++i){const int next=(i+1)%knots;CubicBezier curve;curve.control[0]=points[i];curve.control[3]=points[next];
        if(spline->GetLineType(i)==LTYPE_LINE){const auto& p=points[i];const auto& q=points[next];curve.control[1]={p.x+(q.x-p.x)/3,p.y+(q.y-p.y)/3,p.z+(q.z-p.z)/3};curve.control[2]={p.x+2*(q.x-p.x)/3,p.y+2*(q.y-p.y)/3,p.z+2*(q.z-p.z)/3};}
        else {curve.control[1]=world(spline->GetOutVec(i));curve.control[2]=world(spline->GetInVec(next));}
        result.curves.push_back(curve);
    }
    return result;
}
bool same_path(const CapturedPath& a,const CapturedPath& b)noexcept{
    if(a.closed!=b.closed||a.curves.size()!=b.curves.size())return false;
    for(std::size_t i=0;i<a.curves.size();++i)for(std::size_t j=0;j<4;++j){const auto& p=a.curves[i].control[j];const auto& q=b.curves[i].control[j];if(p.x!=q.x||p.y!=q.y||p.z!=q.z)return false;}return true;
}
}
