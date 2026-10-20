// Transient field visualization. Only preparation reads the host mesh; redraw
// consumes immutable copied vertices/weights and never evaluates scene inputs.
namespace {std::uint64_t densityOverlayBuilds=0,densityOverlayVertices=0,densityOverlayDraws=0;}
visible_class_debug_ok(CyrusDensityOverlay)
class CyrusDensityOverlay : public Value {
public:
    struct Triangle { std::array<Point3,3> points,colors; };
    std::vector<Triangle> triangles;
    double minimum=1,maximum=0;
    CyrusDensityOverlay(){tag=class_tag(CyrusDensityOverlay);}
    classof_methods(CyrusDensityOverlay,Value);
    void collect() override {delete this;}
    void sprin1(CharStream* s) override {s->printf(_T("<CyrusDensityOverlay>"));}
    Value* deep_copy(HashTable*) override {return this;}
};
visible_class_instance(CyrusDensityOverlay,"CyrusDensityOverlay");

def_visible_primitive(cyrusPrepareDensityOverlay,"cyrusPrepareDensityOverlay");
Value* cyrusPrepareDensityOverlay_cf(Value** a,int n){check_arg_count(cyrusPrepareDensityOverlay,12,n);
    try{
        auto* nodes=groupArray(a[0]);if(nodes->size<1||nodes->size>128)throw RuntimeError(_T("Mask overlay requires 1..128 receivers"));
        const auto meshSettings=meshDensitySettings(a[1]);const auto mapping=densityMapping(a[3]);
        const int channel=a[4]->to_int(),mode=a[5]->to_int(),budget=a[6]->to_int();
        if(channel<1||channel>99||mode<0||mode>2||budget<256||budget>131072)throw RuntimeError(_T("Mask overlay settings exceed bounds"));
        const bool imageEnabled=a[2]!=&undefined&&mode!=1,meshEnabled=meshSettings.enabled&&mode!=0;
        const auto filters=surfaceFilterSettings(a[8]);
        std::optional<cyrus::density::ImageSampler> image;
        Texmap* texture=nullptr;bool invertTexture=false;
        if(imageEnabled&&mapping.coordinates==cyrus::density::Coordinates::Map){
            auto* spec=groupArray(a[2]);if(spec->size!=2)throw RuntimeError(_T("Map preview requires a texture and invert flag"));
            texture=spec->data[0]->to_texmap();invertTexture=spec->data[1]->to_bool()!=FALSE;
        }else if(imageEnabled){type_check(a[2],CyrusDensityImage,_T("density image"));const auto& data=*static_cast<CyrusDensityImage*>(a[2])->image;image.emplace(data.pixels,data.width,data.height,mapping);}
        const bool filtered=a[7]->to_bool()!=FALSE&&mode==2;
        const bool paintEnabled=filtered&&a[9]->to_bool()!=FALSE;
        auto* paint=groupArray(a[10]);if(paint->size>128)throw RuntimeError(_T("Mask overlay Paint Area limit exceeded"));
        auto* areaValues=groupArray(a[11]);if(areaValues->size!=2)throw RuntimeError(_T("Mask overlay requires area nodes and modes"));
        auto areas=filtered?densityAreas(areaValues->data[0],areaValues->data[1]):std::vector<amin::Area>{};
        std::vector<amin::AreaMask> masks;std::size_t edgeCount=0;bool hasInclude=false;
        for(const auto& area:areas){masks.emplace_back(area);hasInclude|=area.include;for(const auto& loop:area.loops)edgeCount+=loop.size();}
        struct Region {cyrus::brush::Field field;double density;};
        struct Receiver {std::vector<amin::Triangle> mesh;MeshDensitySnapshot data;std::vector<Region> regions;Matrix3 worldToLocal;std::unique_ptr<ReceiverMapContext> texture;};
        std::vector<Receiver> receivers;std::size_t faces=0;double totalArea=0;
        std::size_t paintBytes=0,textureMeshBytes=0;
        const auto cross=[](amin::Vec3 x,amin::Vec3 y){return amin::Vec3{x.y*y.z-x.z*y.y,x.z*y.x-x.x*y.z,x.x*y.y-x.y*y.x};};
        const auto area=[&](const amin::Triangle& t){return amin::length(cross(t.b-t.a,t.c-t.a))*.5;};
        for(int i=0;i<nodes->size;++i){
            auto* node=nodes->data[i]->to_node();Receiver r;
            r.mesh=meshOf(node,true,imageEnabled&&mapping.coordinates==cyrus::density::Coordinates::UV,std::size_t(budget),channel);
            faces+=r.mesh.size();if(faces>std::size_t(budget))throw RuntimeError(_T("Mask overlay detail is below the receiver face count. Increase detail or use marker diagnostics."));
            if(meshEnabled)r.data=meshDensitySnapshot(node,meshSettings);
            if(texture){r.texture=std::make_unique<ReceiverMapContext>(node,texture,std::size_t(budget)*3,256ULL*1024*1024-textureMeshBytes);textureMeshBytes+=r.texture->meshBytes();}
            if(paintEnabled){
                const auto time=GetCOREInterface()->GetTime();const auto tm=node->GetObjectTM(time);
                if(std::abs(DotProd(tm.GetRow(0),CrossProd(tm.GetRow(1),tm.GetRow(2))))<1e-12)throw RuntimeError(_T("Paint preview receiver frame is singular"));
                r.worldToLocal=Inverse(tm);
                std::optional<cyrus::brush::Surface> surface;
                for(int k=0;k<paint->size;++k){
                    auto* spec=groupArray(paint->data[k]);if(spec->size!=3)throw RuntimeError(_T("Paint preview requires receiver, document and density"));
                    if(spec->data[0]->to_node()!=node)continue;
                    if(!surface){
                        auto* object=node->EvalWorldState(time).obj;if(!object)throw RuntimeError(_T("Paint preview receiver disappeared"));
                        auto* tri=static_cast<TriObject*>(object->ConvertToType(time,Class_ID(TRIOBJ_CLASS_ID,0)));
                        if(!tri)throw RuntimeError(_T("Paint preview mesh evaluation failed"));
                        const auto cleanup=[object](TriObject* p){if(p!=object)p->DeleteThis();};std::unique_ptr<TriObject,decltype(cleanup)> holder(tri,cleanup);
                        const auto& mesh=tri->GetMesh();if(mesh.numVerts>2000000)throw RuntimeError(_T("Paint preview receiver vertex bound exceeded"));
                        cyrus::brush::Mesh copy;copy.vertices.reserve(std::size_t(mesh.numVerts));copy.faces.reserve(std::size_t(mesh.numFaces));
                        for(int v=0;v<mesh.numVerts;++v)copy.vertices.push_back(vec(mesh.verts[v]));
                        for(int f=0;f<mesh.numFaces;++f)copy.faces.push_back({mesh.faces[f].v[0],mesh.faces[f].v[1],mesh.faces[f].v[2]});
                        surface.emplace(std::move(copy));
                    }
                    const double strength=spec->data[2]->to_double();if(!std::isfinite(strength)||strength<0||strength>1)throw RuntimeError(_T("Paint preview density must be 0..1"));
                    type_check(spec->data[1],String,_T("Paint vector snapshot"));const auto* hex=spec->data[1]->to_string();const auto length=wcslen(hex);
                    if(length%2||length>2*64ULL*1024*1024||paintBytes+length/2>64ULL*1024*1024)throw RuntimeError(_T("Paint preview payload bound exceeded"));
                    paintBytes+=length/2;std::vector<std::uint8_t> bytes;bytes.reserve(length/2);
                    const auto digit=[](wchar_t c)->unsigned{if(c>=L'0'&&c<=L'9')return unsigned(c-L'0');if(c>=L'a'&&c<=L'f')return unsigned(c-L'a'+10);if(c>=L'A'&&c<=L'F')return unsigned(c-L'A'+10);throw RuntimeError(_T("Invalid Paint preview snapshot"));};
                    for(std::size_t j=0;j<length;j+=2)bytes.push_back(std::uint8_t(digit(hex[j])*16+digit(hex[j+1])));
                    const auto document=cyrus::brush::decode(bytes);
                    r.regions.push_back({cyrus::brush::Field(*surface,document,cyrus::brush::Metric::fromBasis(vec(tm.GetRow(0)),vec(tm.GetRow(1)))),strength});
                }
            }
            for(const auto& triangle:r.mesh)totalArea+=area(triangle);
            receivers.push_back(std::move(r));
        }
        if(!(totalArea>0))throw RuntimeError(_T("Mask receivers have no finite surface area"));
        auto result=std::make_unique<CyrusDensityOverlay>();result->triangles.reserve(std::size_t(budget));
        cyrus::brush::QueryStats paintWork;
        const double extra=double(std::size_t(budget)-faces);
        std::size_t queries=0;
        for(const auto& receiver:receivers)for(const auto& t:receiver.mesh){
            if(area(t)<=0)continue;
            const auto steps=std::size_t(std::clamp(int(std::sqrt(1.+extra*area(t)/totalArea)),1,256));
            queries+=(steps+1)*(steps+2)/2;
        }
        if(edgeCount>64000000ULL/std::max(std::size_t(1),queries))throw RuntimeError(_T("Mask preview area work exceeds its bound. Reduce detail or simplify the area curves."));
        for(const auto& receiver:receivers)for(std::size_t f=0;f<receiver.mesh.size();++f){
            const auto& t=receiver.mesh[f];const double faceArea=area(t);
            if(faceArea<=0)continue;
            const int steps=std::clamp(int(std::sqrt(1.+extra*faceArea/totalArea)),1,256);
            const auto normal=cross(t.b-t.a,t.c-t.a);const double normalLength=amin::length(normal);
            const auto lift=normalLength>0?normal*(std::sqrt(totalArea)*.00005/normalLength):amin::Vec3{};
            const double slope=filtered?cyrus::surface_filter::slopeDegrees(t):0.;
            const auto vertex=[&](double b,double c){
                const amin::Vec3 bary{1-b-c,b,c},position=t.a*bary.x+t.b*bary.y+t.c*bary.z;
                const auto uv=t.uvA*bary.x+t.uvB*bary.y+t.uvC*bary.z;double weight=1;
                if(image)weight*=image->sample(uv.x,uv.y,position.x,position.y,position.z);
                if(receiver.texture)weight*=receiver.texture->sample(int(f),Point3(float(bary.x),float(bary.y),float(bary.z)),invertTexture,mapping.curve);
                if(meshEnabled)weight*=cyrus::mesh_density::weight(cyrus::mesh_density::sample(receiver.data.corners[f],bary),meshSettings);
                if(filtered)weight*=cyrus::surface_filter::intervalWeight(slope,filters.slope)*cyrus::surface_filter::intervalWeight(position.z,filters.altitude);
                if(paintEnabled){
                    const auto local=point(position)*receiver.worldToLocal;double coverage=0;
                    for(const auto& region:receiver.regions)coverage=std::max(coverage,region.field.queryPoint({local.x,local.y},&paintWork).density*region.density);
                    if(paintWork.fieldQueries>4000000||paintWork.segments>16000000)throw RuntimeError(_T("Mask preview Paint work exceeds its bound. Reduce preview detail."));
                    weight*=coverage;
                }
                bool included=!hasInclude;
                for(const auto& mask:masks)if(mask.contains(position)){if(!mask.area.include){included=false;break;}included=true;}
                if(!included)weight=0;
                result->minimum=std::min(result->minimum,weight);result->maximum=std::max(result->maximum,weight);
                return std::pair{point(position+lift),Point3(float(weight),float(weight),float(weight))};
            };
            const auto append=[&](auto x,auto y,auto z){result->triangles.push_back({{x.first,y.first,z.first},{x.second,y.second,z.second}});};
            // Sample each lattice point once. Adjacent triangles share values;
            // expensive Paint queries do not repeat six times at interior points.
            using Sample=std::pair<Point3,Point3>;
            std::vector<Sample> samples; samples.reserve(std::size_t(steps+1)*(steps+2)/2);
            const double d=double(steps);
            for(int i=0;i<=steps;++i)for(int j=0;j<=steps-i;++j)samples.push_back(vertex(i/d,j/d));
            const auto at=[&](int i,int j)->const Sample&{return samples[std::size_t(i*(steps+1)-i*(i-1)/2+j)];};
            for(int i=0;i<steps;++i)for(int j=0;j<steps-i;++j){
                const auto& x=at(i,j);const auto& y=at(i+1,j);const auto& z=at(i,j+1);append(x,y,z);
                if(j<steps-i-1)append(y,at(i+1,j+1),z);
            }
        }
        ++densityOverlayBuilds;densityOverlayVertices+=result->triangles.size()*3;return result.release();
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}

def_visible_primitive(cyrusDrawDensityOverlay,"cyrusDrawDensityOverlay");
Value* cyrusDrawDensityOverlay_cf(Value** a,int n){check_arg_count(cyrusDrawDensityOverlay,4,n);type_check(a[0],CyrusDensityOverlay,_T("density overlay"));
    const double opacity=a[1]->to_double();if(!std::isfinite(opacity)||opacity<0||opacity>1)throw RuntimeError(_T("Mask opacity must be 0..1"));
    const int markerSize=a[3]->to_int();if(markerSize<1||markerSize>3)throw RuntimeError(_T("Mask marker size must be 1..3"));
    auto& view=GetCOREInterface()->GetActiveViewExp();if(!view.IsAlive())return &ok;auto* gw=view.getGW();if(!gw)return &ok;
    const auto& cache=*static_cast<CyrusDensityOverlay*>(a[0]);const auto limits=gw->getRndLimits();const Material saved=*gw->getMaterial();Material material;
    ++densityOverlayDraws;
    material.Ka=material.Kd=Point3(1,1,1);material.Ks=Point3(0,0,0);material.opacity=float(opacity);material.selfIllum=1;material.dblSided=1;
    gw->setTransform(Matrix3(1));
    if(a[2]->to_bool()!=FALSE){
        gw->setRndLimits(limits&~GW_Z_BUFFER);gw->startMarkers();const auto stride=std::max(std::size_t(1),cache.triangles.size()/2048);
        const MarkerType types[]={POINT_MRKR,SM_DOT_MRKR,DOT_MRKR};
        for(std::size_t i=0;i<cache.triangles.size();i+=stride){auto p=cache.triangles[i].points[0];gw->setColor(LINE_COLOR,cache.triangles[i].colors[0]);gw->marker(&p,types[markerSize-1]);}gw->endMarkers();
    }else{
        gw->setRndLimits((limits&~(GW_ILLUM|GW_WIREFRAME))|GW_Z_BUFFER|GW_COLOR_VERTS|GW_SHADE_CVERTS|GW_TRANSPARENCY|GW_TRANSPARENT_PASS);gw->setMaterial(material);
        gw->startTriangles();
        for(const auto& triangle:cache.triangles){auto xyz=triangle.points,rgb=triangle.colors;gw->triangle(xyz.data(),rgb.data());}
        gw->endTriangles();
    }
    gw->setRndLimits(limits);gw->setMaterial(saved);return &ok;
}

def_visible_primitive(cyrusDensityOverlayStats,"cyrusDensityOverlayStats");
Value* cyrusDensityOverlayStats_cf(Value**,int n){check_arg_count(cyrusDensityOverlayStats,0,n);one_typed_value_local(Array* result);vl.result=new Array(3);
    for(auto value:{densityOverlayBuilds,densityOverlayVertices,densityOverlayDraws})vl.result->append(Integer64::intern(value));return_value(vl.result);}

def_visible_primitive(cyrusDensityOverlayVertex,"cyrusDensityOverlayVertex");
Value* cyrusDensityOverlayVertex_cf(Value** a,int n){check_arg_count(cyrusDensityOverlayVertex,3,n);type_check(a[0],CyrusDensityOverlay,_T("density overlay"));const auto& cache=*static_cast<CyrusDensityOverlay*>(a[0]);
    const int triangle=a[1]->to_int(),corner=a[2]->to_int();if(triangle<1||std::size_t(triangle)>cache.triangles.size()||corner<1||corner>3)throw RuntimeError(_T("Mask vertex is outside cache"));
    const auto& t=cache.triangles[std::size_t(triangle-1)];one_typed_value_local(Array* result);vl.result=new Array(2);vl.result->append(new Point3Value(t.points[std::size_t(corner-1)]));vl.result->append(Float::intern(t.colors[std::size_t(corner-1)].x));return_value(vl.result);}

def_visible_primitive(cyrusDensityOverlayInfo,"cyrusDensityOverlayInfo");
Value* cyrusDensityOverlayInfo_cf(Value** a,int n){check_arg_count(cyrusDensityOverlayInfo,1,n);type_check(a[0],CyrusDensityOverlay,_T("density overlay"));
    const auto& cache=*static_cast<CyrusDensityOverlay*>(a[0]);one_typed_value_local(Array* result);vl.result=new Array(4);
    vl.result->append(Integer::intern(int(cache.triangles.size())));vl.result->append(Double::intern(cache.minimum));vl.result->append(Double::intern(cache.maximum));vl.result->append(Integer64::intern(cache.triangles.capacity()*sizeof(CyrusDensityOverlay::Triangle)));return_value(vl.result);
}
