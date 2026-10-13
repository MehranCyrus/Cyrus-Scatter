// One immutable, GC-owned numeric field shared across receiver generation,
// constrained movement and display inspection. No retained host pointers.
#include "spline_field_value.h"
visible_class_debug_ok(CyrusSplineField)
class CyrusSplineField : public Value {
public:
    std::shared_ptr<const cyrus::bands::Field> field;
    explicit CyrusSplineField(std::shared_ptr<const cyrus::bands::Field> value):field(std::move(value)) {tag=class_tag(CyrusSplineField);}
    classof_methods(CyrusSplineField,Value);
    void collect() override {delete this;}
    void sprin1(CharStream* stream) override {stream->printf(_T("<CyrusSplineField>"));}
    Value* deep_copy(HashTable*) override {return this;}
};
visible_class_instance(CyrusSplineField,"CyrusSplineField");
const cyrus::bands::Field& cyrusPreparedSplineField(Value* value){
    type_check(value,CyrusSplineField,_T("prepared spline field"));
    return *static_cast<CyrusSplineField*>(value)->field;
}

def_visible_primitive(cyrusPrepareSplineField,"cyrusPrepareSplineField");
Value* cyrusPrepareSplineField_cf(Value** a,int n) {
    check_arg_count(cyrusPrepareSplineField,4,n);
    type_check(a[0],Array,_T("Bands"));type_check(a[1],Array,_T("source weights"));
    auto* rows=static_cast<Array*>(a[0]);auto* weights=static_cast<Array*>(a[1]);
    const int mode=a[2]->to_int();if(mode!=1&&mode!=2)throw RuntimeError(_T("Invalid Band arrangement."));
    cyrus::bands::Limits limits;limits.quantum=a[3]->to_float();
    if(rows->size>int(limits.bands))throw RuntimeError(_T("Spline fields support at most 64 Bands."));
    std::vector<cyrus::bands::Path> paths;std::vector<cyrus::bands::Band> bands;
    std::map<std::uint64_t,std::pair<INode*,std::size_t>> sampled;
    std::map<std::uint64_t,double> pathTolerance;
    std::size_t vertices=0,memberships=0;const auto time=GetCOREInterface()->GetTime();
    try {
        if(!std::isfinite(limits.quantum)||limits.quantum<=0)throw RuntimeError(_T("Invalid physical spline precision."));
        for(int i=0;i<rows->size;++i){
            type_check(rows->data[i],Array,_T("Band"));auto* row=static_cast<Array*>(rows->data[i]);
            if(row->size!=15)throw RuntimeError(_T("Expected the current 15-field Band record."));
            const auto id=row->data[1]->to_int64();const double start=row->data[4]->to_float(),end=row->data[5]->to_float();
            if(id<1||!std::isfinite(start)||!std::isfinite(end)||start<0||end<=start)throw RuntimeError(_T("Band range requires 0 <= Start < End."));
            // Error is relative to the narrowest affected interval; a fixed
            // physical ceiling oversamples otherwise simple large paths.
            const double tolerance=(end-start)/4096;
            auto [entry,added]=pathTolerance.emplace(id,tolerance);if(!added)entry->second=std::min(entry->second,tolerance);
        }
        for(int i=0;i<rows->size;++i){
            type_check(rows->data[i],Array,_T("Band"));auto* row=static_cast<Array*>(rows->data[i]);
            if(row->size!=15)throw RuntimeError(_T("Expected the current 15-field Band record."));
            cyrus::bands::Band band;
            for(int k:{1,2})if(!cyrus::rows::integer(row->data[k])||row->data[k]->to_int64()<1)throw RuntimeError(_T("Path and Band IDs must be positive integers."));
            band.path=row->data[1]->to_int64();band.id=row->data[2]->to_int64();
            if(row->data[3]!=&true_value&&row->data[3]!=&false_value)throw RuntimeError(_T("Band side must be Boolean."));
            band.inside=row->data[3]==&true_value;band.start=row->data[4]->to_float();band.end=row->data[5]->to_float();
            const int join=row->data[6]->to_int();if(join!=1&&join!=2)throw RuntimeError(_T("Unknown Path corner mode."));
            band.strength=row->data[7]->to_float();band.curve.clear();
            type_check(row->data[8],Array,_T("density samples"));auto* curve=static_cast<Array*>(row->data[8]);
            if(curve->size<2||curve->size>257)throw RuntimeError(_T("Band density requires 2 to 257 samples."));
            for(int j=0;j<curve->size;++j)band.curve.push_back(curve->data[j]->to_float());
            for(int k:{9,10,11})type_check(row->data[k],Array,_T("Band source metadata"));
            auto* choices=static_cast<Array*>(row->data[9]);auto* ids=static_cast<Array*>(row->data[10]);auto* empty=static_cast<Array*>(row->data[11]);
            if(choices->size!=ids->size||choices->size!=empty->size)throw RuntimeError(_T("Band source metadata must match memberships."));
            memberships+=choices->size;if(memberships>limits.memberships)throw RuntimeError(_T("Too many Band source memberships."));
            for(int j=0;j<choices->size;++j){
                const int source=choices->data[j]->to_int();if(source<1||source>weights->size)throw RuntimeError(_T("Band source is outside the current source table."));
                type_check(ids->data[j],String,_T("source row identity"));const std::wstring wide=ids->data[j]->to_string();std::string id;
                if(wide.empty()||wide.size()>128)throw RuntimeError(_T("Invalid source row identity."));
                for(auto c:wide){if(c<1||c>127)throw RuntimeError(_T("Source row identity must be ASCII."));id.push_back(char(c));}
                if(empty->data[j]!=&true_value&&empty->data[j]!=&false_value)throw RuntimeError(_T("Empty-source flag must be Boolean."));
                band.sources.push_back({id,unsigned(source-1),weights->data[source-1]->to_float(),empty->data[j]==&true_value});
            }
            band.scale={row->data[12]->to_float(),row->data[13]->to_float()};
            type_check(row->data[14],Array,_T("scale samples"));auto* scaleCurve=static_cast<Array*>(row->data[14]);
            if(scaleCurve->size<2||scaleCurve->size>257)throw RuntimeError(_T("Band scale requires 2 to 257 samples."));
            band.scaleCurve.clear();
            for(int j=0;j<scaleCurve->size;++j)band.scaleCurve.push_back(scaleCurve->data[j]->to_float());
            auto* node=row->data[0]->to_node();if(!node)throw RuntimeError(_T("Active Band has no Path node."));
            const auto existing=sampled.find(band.path);
            if(existing!=sampled.end()){
                const auto& previous=paths[existing->second.second];
                if(existing->second.first!=node||previous.join!=(join==1?cyrus::bands::Join::Rounded:cyrus::bands::Join::Sharp))throw RuntimeError(_T("One Path identity has conflicting nodes or corner settings."));
            }else{
                if(paths.size()>=limits.paths)throw RuntimeError(_T("Spline fields support at most 32 Paths."));
                auto* obj=node->EvalWorldState(time).obj;
                if(!obj||obj->SuperClassID()!=SHAPE_CLASS_ID)throw RuntimeError(_T("Band Paths require closed spline shapes."));
                auto* shape=static_cast<ShapeObject*>(obj);const auto tm=node->GetObjectTM(time);
                cyrus::bands::Path path;path.id=band.path;path.join=join==1?cyrus::bands::Join::Rounded:cyrus::bands::Join::Sharp;
                const int curves=shape->NumberOfCurves(time);
                if(curves<1||curves>int(limits.inputVertices/3))throw RuntimeError(_T("Path has no bounded closed curves."));
                std::size_t pieces=0;
                for(int curveIndex=0;curveIndex<curves;++curveIndex){
                    if(!shape->CurveClosed(time,curveIndex))throw RuntimeError(_T("Every spline in a Band Path must be closed."));
                    const int count=shape->NumberOfPieces(time,curveIndex);
                    if(count<1||std::size_t(count)>limits.inputVertices-pieces)throw RuntimeError(_T("Path is empty or too complex."));pieces+=count;
                }
                if(!shape->CanMakeBezier())throw RuntimeError(_T("This Path cannot provide bounded Bezier geometry. Convert a copy to Editable Spline."));
                BezierShape bezier;shape->MakeBezier(time,bezier);
                if(bezier.SplineCount()!=curves)throw RuntimeError(_T("Path Bezier conversion changed its curve topology."));
                const auto a=tm.GetRow(0),b=tm.GetRow(1),c=tm.GetRow(2),d=tm.GetTrans();
                const auto world=[&](Point3 p)->amin::Vec3{return {double(p.x)*a.x+double(p.y)*b.x+double(p.z)*c.x+d.x,double(p.x)*a.y+double(p.y)*b.y+double(p.z)*c.y+d.y,double(p.x)*a.z+double(p.y)*b.z+double(p.z)*c.z+d.z};};
                for(int curveIndex=0;curveIndex<curves;++curveIndex){
                    auto* spline=bezier.GetSpline(curveIndex);const int knots=spline?spline->KnotCount():0;
                    if(!spline||!spline->Closed()||knots<1||std::size_t(knots)>limits.inputVertices-vertices)throw RuntimeError(_T("Invalid or oversized closed Bezier Path."));
                    std::vector<cyrus::bands::Cubic> controls;controls.reserve(knots);
                    for(int k=0;k<knots;++k){
                        const int next=(k+1)%knots;const auto first=world(spline->GetKnotPoint(k)),last=world(spline->GetKnotPoint(next));
                        const bool linear=spline->GetLineType(k)==LTYPE_LINE;
                        controls.push_back({first,linear?first:world(spline->GetOutVec(k)),linear?last:world(spline->GetInVec(next)),last});
                    }
                    double lowX=INFINITY,lowY=INFINITY,highX=-INFINITY,highY=-INFINITY;
                    for(const auto& segment:controls)for(auto p:{segment.a,segment.b,segment.c,segment.d}){
                        lowX=std::min(lowX,p.x);lowY=std::min(lowY,p.y);highX=std::max(highX,p.x);highY=std::max(highY,p.y);
                    }
                    // Also resolve small curves inside very wide Bands. Both
                    // bounds scale with the same physical shape across units.
                    const auto tolerance=std::min(pathTolerance.at(band.path),std::max(highX-lowX,highY-lowY)/4096);
                    auto loop=cyrus::bands::tessellate(controls,tolerance,limits.inputVertices-vertices);vertices+=loop.size();
                    path.area.loops.push_back(std::move(loop));
                }
                sampled.emplace(band.path,std::make_pair(node,paths.size()));paths.push_back(std::move(path));
            }
            bands.push_back(std::move(band));
        }
        auto field=std::make_shared<cyrus::bands::Field>(std::move(paths),std::move(bands),mode==1?cyrus::bands::Arrangement::Consecutive:cyrus::bands::Arrangement::Independent,limits);
        return new CyrusSplineField(std::move(field));
    }catch(const std::exception& error){const std::string message=error.what();throw RuntimeError(MSTR(std::wstring(message.begin(),message.end()).c_str()));}
}

def_visible_primitive(cyrusSplineFieldStats,"cyrusSplineFieldStats");
Value* cyrusSplineFieldStats_cf(Value** a,int n){
    check_arg_count(cyrusSplineFieldStats,1,n);type_check(a[0],CyrusSplineField,_T("prepared spline field"));
    const auto& stats=static_cast<CyrusSplineField*>(a[0])->field->stats();
    one_typed_value_local(Array* result);vl.result=new Array(7);
    for(auto value:{stats.inputVertices,stats.levels,stats.vertices,stats.bytes,stats.constructionWork,stats.scratchAllowance,cyrus::bands::reservedFieldBytes()})vl.result->append(Integer64::intern(value));
    return_value(vl.result);
}
