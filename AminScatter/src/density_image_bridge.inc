// Bounded native image snapshots. The Max Bitmap is accessed only during capture;
// workers and stored generations retain copied scalar pixels, never host pointers.
visible_class_debug_ok(CyrusDensityImage)
class CyrusDensityImage : public Value {
public:
    std::shared_ptr<const cyrus::density::ImageData> image;
    explicit CyrusDensityImage(std::shared_ptr<const cyrus::density::ImageData> data):image(std::move(data)){tag=class_tag(CyrusDensityImage);}
    classof_methods(CyrusDensityImage,Value);
    void collect() override {delete this;}
    void sprin1(CharStream* stream) override {stream->printf(_T("<CyrusDensityImage>"));}
    Value* deep_copy(HashTable*) override {return this;}
};
visible_class_instance(CyrusDensityImage,"CyrusDensityImage");

namespace {
cyrus::density::Mapping densityMapping(Value* value) {
    type_check(value,Array,_T("image mapping"));auto* a=static_cast<Array*>(value);
    if(a->size!=11)throw RuntimeError(_T("Image mapping requires its current eleven fields"));
    cyrus::density::Mapping m;
    m.coordinates=static_cast<cyrus::density::Coordinates>(a->data[0]->to_int());
    m.wrapping=static_cast<cyrus::density::Wrapping>(a->data[1]->to_int());
    m.sizeX=a->data[2]->to_double();m.sizeY=a->data[3]->to_double();
    m.repeatX=a->data[4]->to_double();m.repeatY=a->data[5]->to_double();
    m.rotation=a->data[6]->to_double();m.offsetX=a->data[7]->to_double();m.offsetY=a->data[8]->to_double();
    const Matrix3 frame=a->data[9]->to_matrix3();
    for(int i=0;i<4;++i)for(int j=0;j<3;++j)m.worldToFrame[std::size_t(i*3+j)]=frame.GetRow(i)[j];
    type_check(a->data[10],Array,_T("image response curve"));const auto* curve=static_cast<Array*>(a->data[10]);
    if(curve->size>257)throw RuntimeError(_T("Image response curve exceeds 257 samples"));
    m.curve.clear();for(int i=0;i<curve->size;++i)m.curve.push_back(curve->data[i]->to_double());
    cyrus::density::validate(m);return m;
}
}
def_visible_primitive(cyrusDensityImageVersion,"cyrusDensityImageVersion");
Value* cyrusDensityImageVersion_cf(Value**,int n){check_arg_count(cyrusDensityImageVersion,0,n);return Integer::intern(2);}
def_visible_primitive(cyrusValidateDensityMapping,"cyrusValidateDensityMapping");
Value* cyrusValidateDensityMapping_cf(Value** a,int n){check_arg_count(cyrusValidateDensityMapping,1,n);
    try{densityMapping(a[0]);return &ok;}catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}}
def_visible_primitive(cyrusCaptureDensityImage,"cyrusCaptureDensityImage");
Value* cyrusCaptureDensityImage_cf(Value** a,int n){check_arg_count(cyrusCaptureDensityImage,1,n);type_check(a[0],MAXBitMap,_T("evaluated density bitmap"));
    auto* bitmap=static_cast<MAXBitMap*>(a[0])->bm;if(!bitmap)throw RuntimeError(_T("Density bitmap is closed"));
    const int w=bitmap->Width(),h=bitmap->Height();
    if(w<1||h<1||w>512||h>512)throw RuntimeError(_T("Density bitmap supports at most 512 x 512 samples"));
    auto image=std::make_shared<cyrus::density::ImageData>();image->width=std::size_t(w);image->height=std::size_t(h);image->pixels.reserve(std::size_t(w)*std::size_t(h));
    std::vector<BMM_Color_fl> row(std::size_t(w),BMM_Color_fl{});
    for(int y=0;y<h;++y){
        if(!bitmap->GetLinearPixels(0,y,w,row.data()))throw RuntimeError(_T("Cannot capture density pixels"));
        for(const auto& c:row){const double weight=c.r*.2126+c.g*.7152+c.b*.0722;
            if(!std::isfinite(weight))throw RuntimeError(_T("Density bitmap contains nonfinite data"));
            image->pixels.push_back(std::clamp(weight,0.0,1.0));}
    }
    return new CyrusDensityImage(std::move(image));
}
def_visible_primitive(cyrusDensityImageInvert,"cyrusDensityImageInvert");
Value* cyrusDensityImageInvert_cf(Value** a,int n){check_arg_count(cyrusDensityImageInvert,1,n);type_check(a[0],CyrusDensityImage,_T("native density image"));
    auto image=std::make_shared<cyrus::density::ImageData>(*static_cast<CyrusDensityImage*>(a[0])->image);
    for(auto& value:image->pixels)value=1-value;return new CyrusDensityImage(std::move(image));}
def_visible_primitive(cyrusDensityImageCount,"cyrusDensityImageCount");
Value* cyrusDensityImageCount_cf(Value** a,int n){check_arg_count(cyrusDensityImageCount,1,n);type_check(a[0],CyrusDensityImage,_T("native density image"));
    return Integer::intern(static_cast<int>(static_cast<CyrusDensityImage*>(a[0])->image->pixels.size()));}

def_visible_primitive(cyrusWriteDensityImage,"cyrusWriteDensityImage");
Value* cyrusWriteDensityImage_cf(Value** a,int n){check_arg_count(cyrusWriteDensityImage,2,n);type_check(a[0],CyrusDensityImage,_T("native density image"));type_check(a[1],String,_T("PNG destination"));
    try{
        const std::filesystem::path path(a[1]->to_string());if(!path.is_absolute())throw RuntimeError(_T("Density snapshot needs an absolute destination"));
        const auto bytes=cyrus::density::encodeLinearPNG(*static_cast<CyrusDensityImage*>(a[0])->image);
        const auto file=CreateFileW(path.c_str(),GENERIC_WRITE,0,nullptr,CREATE_NEW,FILE_ATTRIBUTE_NORMAL,nullptr);
        if(file==INVALID_HANDLE_VALUE)throw RuntimeError(_T("Cannot create density snapshot; the destination exists or is unavailable"));
        DWORD written=0;const bool success=WriteFile(file,bytes.data(),DWORD(bytes.size()),&written,nullptr)&&written==bytes.size()&&FlushFileBuffers(file);
        CloseHandle(file);if(!success){DeleteFileW(path.c_str());throw RuntimeError(_T("Density snapshot write failed; the previous map is retained"));}
        return &ok;
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
