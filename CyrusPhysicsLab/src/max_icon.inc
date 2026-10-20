// Included in Document. A bounded viewport marker; never part of physics recipes.
bool iconDisplay=true;ULONG iconOwner=0;double iconSize=.25;
std::uint64_t iconDraws=0;
static const std::vector<cpl::CollisionLine>& iconLines(){
 static const auto lines=[](){std::vector<cpl::CollisionLine> out;constexpr double pi=3.141592653589793;
  auto add=[&](Vec a,Vec b){out.push_back({a,b});};
  for(unsigned axis=0;axis<3;++axis){unsigned count=axis==0?48:24;for(unsigned i=0;i<count;++i){double a=2*pi*i/count,b=2*pi*(i+1)/count;auto p=[&](double r)->Vec{if(axis==0)return{std::cos(r),std::sin(r),0};if(axis==1)return{std::cos(r),0,std::sin(r)};return{0,std::cos(r),std::sin(r)};};add(p(a),p(b));}}
  add({-.35,-.5,0},{-.35,.5,0});add({-.35,.5,0},{-.05,.5,0});
  for(unsigned i=0;i<12;++i){double a=pi*.5-pi*i/12,b=pi*.5-pi*(i+1)/12;add({-.05+.25*std::cos(a),.25+.25*std::sin(a),0},{-.05+.25*std::cos(b),.25+.25*std::sin(b),0});}
  add({-.05,0,0},{-.35,0,0});
  auto cube=cpl::boxMesh({.17,.17,.17},{.4,-.35,0});for(auto e:std::array<std::array<unsigned,2>,12>{{{0,1},{0,2},{1,3},{2,3},{4,5},{4,6},{5,7},{6,7},{0,4},{1,5},{2,6},{3,7}}})add(cube.vertices[e[0]],cube.vertices[e[1]]);
  return out;
 }();return lines;
}
void setViewportIcon(bool enabled,INode* owner,double size){
 if(!std::isfinite(size)||size<.0001||size>1000)throw std::runtime_error("Icon radius must be between 0.0001 and 1000 metres");
 iconDisplay=enabled;iconSize=size;if(owner)iconOwner=owner->GetHandle();
 if(enabled&&iconOwner)iconDisplays.insert(this);else iconDisplays.erase(this);
}
std::unique_ptr<::Mesh> viewportMesh(bool enabled,double size){
 setViewportIcon(enabled,nullptr,size);if(!enabled)return mesh(true);
 // Match the Scatter controller's zero-area picking edges. Visible lines are
 // drawn separately. These triangles have no renderable surface or collider.
 double unit=GetSystemUnitScale(UNITS_METERS);if(!std::isfinite(unit)||unit<=0)throw std::runtime_error("Invalid icon units");
 const auto& lines=iconLines();auto out=mesh(true,lines.size()*2,lines.size());int firstVertex=out->numVerts-int(lines.size()*2),firstFace=out->numFaces-int(lines.size());
 // Allocate final body+marker buffers once, before copying physical geometry.
 // Appending via setNumVerts/Faces(keep=true) would copy a large preview again.
 if(firstFace==0)out->mapVerts(1)[0]=Point3(0,0,0);
 for(unsigned i=0;i<lines.size();++i){int v=firstVertex+int(i*2),f=firstFace+int(i);out->verts[v]=point(lines[i][0]*(size/unit));out->verts[v+1]=point(lines[i][1]*(size/unit));out->faces[f].setVerts(v,v+1,v+1);out->faces[f].setEdgeVisFlags(1,0,0);out->faces[f].setSmGroup(0);out->faces[f].setMatID(0);out->mapFaces(1)[f].setTVerts(0,0,0);}
 out->InvalidateGeomCache();out->buildBoundingBox();return out;
}
void drawViewportIcon(ViewExp* view,std::size_t& remaining)noexcept{
 if(!iconDisplay||!view||!view->IsAlive())return;auto* owner=GetCOREInterface()->GetINodeByHandle(iconOwner);if(!owner||owner->IsHidden())return;auto* gw=view->getGW();if(!gw)return;
 auto limits=gw->getRndLimits();try{double unit=GetSystemUnitScale(UNITS_METERS);if(!std::isfinite(unit)||unit<=0)return;
  Matrix3 tm=owner->GetNodeTM(GetCOREInterface()->GetTime());for(int i=0;i<3;++i)tm.SetRow(i,tm.GetRow(i)*float(iconSize/unit));gw->setTransform(tm);gw->setRndLimits(limits&~(GW_ILLUM|GW_Z_BUFFER));gw->setColor(LINE_COLOR,owner->Selected()?Point3(1,1,1):Point3(1.f,.2f,.12f));
  for(auto line:iconLines()){if(!remaining)break;Point3 p[3]={point(line[0]),point(line[1]),point(line[1])};gw->polyline(2,p,nullptr,nullptr,FALSE,nullptr);--remaining;}++iconDraws;
 }catch(...){}gw->setTransform(Matrix3(1));gw->setRndLimits(limits);
}
Json viewportIconInfo()const{return{{"enabled",iconDisplay},{"owner",iconOwner},{"radius_m",iconSize},{"segments",iconLines().size()},{"draws",iconDraws}};}
