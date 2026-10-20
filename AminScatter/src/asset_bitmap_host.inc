// Graph-3 host bitmap creation. MAXScript openBitmap ignores gamma: in OCIO
// modes, but CoronaNormal also uses the retained legacy gamma annotation.
// Supply both the explicit colour-space request and input annotation BEFORE
// loading. Never patch an existing shared BitmapStorage or change scene CM.
def_visible_primitive(cyrusAssetOpenImage,"cyrusAssetOpenImage");
Value* cyrusAssetOpenImage_cf(Value** a,int n){check_arg_count(cyrusAssetOpenImage,3,n);return recipeAPI([&]()->Value*{
    type_check(a[0],String,_T("asset image filename"));
    const auto spaceUTF8=recipeUTF8(a[1],160);
    if(spaceUTF8.empty())throw RuntimeError(_T("Portable image needs an explicit colour space"));
    const MSTR space(a[1]->to_string());bool automatic=false;float gamma=1.f;
    if(is_string(a[2])){
        if(recipeUTF8(a[2],8)!="auto")throw RuntimeError(_T("Portable image gamma must be auto or a finite number from 0.1 to 10"));
        automatic=true;
    }else {
        if(!cyrus::host::integerNumber(a[2])&&!cyrus::host::floatNumber(a[2]))throw RuntimeError(_T("Portable image gamma must be auto or a finite number from 0.1 to 10"));
        const double value=a[2]->to_double();
        if(!std::isfinite(value)||value<.1||value>10.)throw RuntimeError(_T("Portable image gamma is outside 0.1 to 10"));
        gamma=static_cast<float>(value);
    }
    using namespace MaxSDK::ColorManagement;
    auto* pipeline=IColorPipelineMgr::GetInstance();
    if(!pipeline||pipeline->GetColorPipelineMode()!=ColorPipelineMode::kOCIO_DEFAULT||!pipeline->Settings()||pipeline->Settings()->GetStatus()!=ModeStatus::kNORMAL)
        throw RuntimeError(_T("Plant image loading requires the normal default OCIO pipeline"));
    const std::filesystem::path path(a[0]->to_string());
    // Full bounded codec verification precedes the SDK decoder. Aggregate
    // map-instance/physical/commit admission belongs to the caller's complete
    // capture/staging plan, not a claim based on this one bitmap allocation.
    const auto file=cyrus::assets::imageFileInfo(path);
    const int width=file.at(2).get<int>(),height=file.at(3).get<int>();
    BitmapInfo info;info.SetName(path.c_str());info.SetCurrentFrame(0);
    if(TheManager->GetImageInfo(&info)!=BMMRES_SUCCESS||info.Width()!=width||info.Height()!=height||info.NumberFrames()!=1)
        throw RuntimeError(_T("SDK image metadata differs from the verified single-frame image"));
    info.ResetCustomFlag(BMM_CUSTOM_GAMMA|BMM_CUSTOM_FILEGAMMA|BMM_CUSTOM_INFERREDGAMMA);
    if(automatic)info.SetCustomFlag(BMM_CUSTOM_FILEGAMMA);
    else {info.SetCustomGamma(gamma);info.SetCustomFlag(BMM_CUSTOM_GAMMA);}
    if(info.SetRequestedColorSpace(space,ColSpaceSource::User)!=ColSpaceStatus::Normal||info.ColorSpace()!=space)
        throw RuntimeError(_T("The requested image colour space is unavailable; no fallback was accepted"));
    BMMRES status=BMMRES_SUCCESS;auto* bitmap=TheManager->Load(&info,&status);
    const auto cleanup=[](Bitmap* value){if(value)value->DeleteThis();};
    std::unique_ptr<Bitmap,decltype(cleanup)> owned(bitmap,cleanup);
    if(!bitmap||status!=BMMRES_SUCCESS)throw RuntimeError(_T("SDK portable image loading failed"));
    auto check=[&](const BitmapInfo& actual){
        if(actual.Width()!=width||actual.Height()!=height||actual.NumberFrames()!=1||actual.ColorSpaceStatus()!=ColSpaceStatus::Normal||actual.ColorSpace()!=space||actual.GetRequestedColorSpace()!=space)
            throw RuntimeError(_T("Loaded image dimensions or colour interpretation changed"));
        const bool custom=(actual.GetCustomFlags()&BMM_CUSTOM_GAMMA)!=0;
        const bool fromFile=(actual.GetCustomFlags()&BMM_CUSTOM_FILEGAMMA)!=0;
        if(automatic?(custom||!fromFile):(!custom||fromFile||actual.GetCustomGamma()!=gamma||std::abs(actual.Gamma()-gamma)>2e-6f))
            throw RuntimeError(_T("The SDK did not preserve the requested image gamma annotation"));
        if(!std::isfinite(actual.Gamma())||actual.Gamma()<.1f||actual.Gamma()>10.f)
            throw RuntimeError(_T("Loaded image effective gamma is unsupported"));
    };
    check(info);check(bitmap->GetBitmapInfo());
    if(bitmap->Width()!=width||bitmap->Height()!=height)throw RuntimeError(_T("Loaded bitmap storage dimensions changed"));
    auto* result=new MAXBitMap(info,bitmap);owned.release();
    result->flags|=BM_READONLY|BM_FILEBACKED;
    return result;
});}

// Fixed class cache evaluation only. The bounded graph adapter performs image
// admission and renderer identity checks before this host-thread call. No class
// string, filename, constructor or global colour setting is accepted here.
def_visible_primitive(cyrusAssetRefreshCoronaBitmap,"cyrusAssetRefreshCoronaBitmap");
Value* cyrusAssetRefreshCoronaBitmap_cf(Value** a,int n){check_arg_count(cyrusAssetRefreshCoronaBitmap,1,n);return recipeAPI([&]()->Value*{
    auto* map=a[0]->to_texmap();
    if(!map||map->SuperClassID()!=TEXMAP_CLASS_ID||map->ClassID()!=Class_ID(2881116036u,1699234372u))
        throw RuntimeError(_T("The portable image cache adapter requires a fixed CoronaBitmap"));
    Interval valid=FOREVER;
    map->Update(GetCOREInterface()->GetTime(),valid);
    return &true_value;
});}
