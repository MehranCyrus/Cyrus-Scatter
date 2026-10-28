#include "preparation_view.h"
#include <iostream>
#include <stdexcept>
using namespace cyrus::preparation_view;
void require(bool ok,const char* message){if(!ok)throw std::runtime_error(message);}
void close(double a,double b,const char* message){require(std::abs(a-b)<1e-8,message);}
int main(){try{
    Camera camera;const Vec lo{-.7,-.2,0},hi{.7,.2,2};
    for(const auto dimensions:{std::array{400,900},std::array{1100,500}}){const int width=dimensions[0],height=dimensions[1];camera.frame(lo,hi,width,height);
        for(unsigned mask=0;mask<8;++mask){const Vec corner{mask&1?hi.x:lo.x,mask&2?hi.y:lo.y,mask&4?hi.z:lo.z};const auto p=camera.screenPoint(corner,width,height);require(p[0]>0&&p[0]<width&&p[1]>0&&p[1]<height,"Frame must contain every box corner in portrait and landscape viewports");}
        const auto pivot=camera.centre;camera.panPixels(70,-35,height);const auto before=camera.screenPoint(pivot,width,height);close(before[0],width*.5+70,"Pan should move geometry with the pointer");close(before[1],height*.5-35,"Vertical pan should follow the pointer");
        camera.orbitPixels(90,40,height);const auto after=camera.screenPoint(pivot,width,height);close(after[0],before[0],"Orbit after panning must keep the framed pivot at the same screen point");close(after[1],before[1],"Orbit must not swing around the displaced pan centre");require(length(sub(camera.centre,pivot))<1e-12,"Navigation must not move the framed pivot");
        const double x=width*.7,y=height*.3;const auto underCursor=add(camera.viewCentre(),camera.pixelDelta(x-width*.5,y-height*.5,height));camera.zoom(2,x,y,width,height);const auto kept=camera.screenPoint(underCursor,width,height);close(kept[0],x,"Zoom must preserve the plane point under the cursor");close(kept[1],y,"Zoom under cursor must preserve vertical position");
        camera.orbitPixels(1e5,1e5,height);Vec right,up,forward;camera.axes(right,up,forward);require(up.z>0,"Orbit must retain world up without flipping");close(length(right),1,"Orthonormal camera right");close(dot(right,up),0,"Camera right and up stay perpendicular");
    }
    std::cout<<"PASS selected framing, portrait fit, pan/orbit pivot, cursor zoom and stable world up\n";return 0;
}catch(const std::exception& error){std::cerr<<error.what()<<'\n';return 1;}}
