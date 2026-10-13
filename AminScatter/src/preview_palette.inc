// Main-thread parsing only. Each cache keeps its publication dictionary and
// source correspondence while color edits replace this small immutable value.
std::shared_ptr<const cyrus::PreviewPalette> previewPalette(Value* value,std::size_t sourceCount) {
    if(sourceCount>4096)throw RuntimeError(_T("A preview supports at most 4,096 source groups"));
    type_check(value,Array,_T("preview palette"));auto* data=static_cast<Array*>(value);
    if(data->size!=5||!cyrus::rows::integer(data->data[0])||data->data[0]->to_int64()!=1)
        throw RuntimeError(_T("Expected preview palette version 1 with five fields"));
    auto palette=std::make_shared<cyrus::PreviewPalette>();
    palette->mode=data->data[1]->to_int();
    if(palette->mode<1||palette->mode>3)throw RuntimeError(_T("Unknown identification mode"));
    if(data->data[4]!=&true_value&&data->data[4]!=&false_value)
        throw RuntimeError(_T("Band ownership requirement must be Boolean"));
    palette->requireBand=data->data[4]==&true_value;
    const auto color=[](Value* value) {
        auto result=value->to_point3()/255.f;
        for(int axis=0;axis<3;++axis)if(!std::isfinite(result[axis])||result[axis]<0||result[axis]>1)
            throw RuntimeError(_T("Identification colors must be finite RGB values in 0..255"));
        return result;
    };
    type_check(data->data[2],Array,_T("source palette"));auto* sources=static_cast<Array*>(data->data[2]);
    if(std::size_t(sources->size)!=sourceCount)throw RuntimeError(_T("Palette source count mismatch"));
    for(int i=0;i<sources->size;++i)palette->sourceColors.push_back(color(sources->data[i]));
    type_check(data->data[3],Array,_T("Band palette"));auto* bands=static_cast<Array*>(data->data[3]);
    if(bands->size>64)throw RuntimeError(_T("Band palette exceeds 64 entries"));
    std::vector<std::pair<std::uint64_t,Point3>> sorted;
    for(int i=0;i<bands->size;++i) {
        type_check(bands->data[i],Array,_T("Band palette entry"));auto* entry=static_cast<Array*>(bands->data[i]);
        if(entry->size!=2||!cyrus::rows::integer(entry->data[0])||entry->data[0]->to_int64()<=0)
            throw RuntimeError(_T("Invalid Band palette identity"));
        sorted.emplace_back(std::uint64_t(entry->data[0]->to_int64()),color(entry->data[1]));
    }
    std::sort(sorted.begin(),sorted.end(),[](const auto& a,const auto& b){return a.first<b.first;});
    palette->bandColors[0]=Point3(.5f,.5f,.5f);
    for(const auto& entry:sorted) {
        if(!palette->bandIDs.empty()&&palette->bandIDs.back()==entry.first)
            throw RuntimeError(_T("Duplicate Band palette identity"));
        palette->bandIDs.push_back(entry.first);palette->bandColors[palette->bandIDs.size()]=entry.second;
    }
    palette->memory=cyrus::reservePreviewMemory(cyrus::pointPreviewBudget,sizeof(cyrus::PreviewPalette)+
        palette->sourceColors.capacity()*sizeof(Point3)+palette->bandIDs.capacity()*sizeof(std::uint64_t));
    return palette;
}
std::uint8_t previewBandSlot(Array* row,const cyrus::PreviewPalette& palette) {
    cyrus::rows::current(row);
    const auto id=cyrus::rows::owner(row);
    if(id==0) {
        if(palette.requireBand)throw RuntimeError(_T("An ordinary Band placement lost its owner"));
        return 0;
    }
    const auto found=std::lower_bound(palette.bandIDs.begin(),palette.bandIDs.end(),id);
    if(found==palette.bandIDs.end()||*found!=id)throw RuntimeError(_T("Placement owner is missing from the published Band palette"));
    return std::uint8_t(1+std::distance(palette.bandIDs.begin(),found));
}
