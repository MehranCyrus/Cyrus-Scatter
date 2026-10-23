// Complete accepted placements and identification colours are derived state.
// One final view/lookup is shared across the stack; each modifier keeps only its
// own authored rows and resolves final feedback by output identity and lineage.
static std::shared_ptr<const EditPalette> editPalette(Value* value,std::size_t sources,bool empty){
    type_check(value,Array,_T("Edit identification palette"));auto* data=static_cast<Array*>(value);
    if(data->size!=5||data->data[0]->to_int()!=1)throw RuntimeError(_T("Expected identification palette version 1"));
    auto result=ce::make<EditPalette>();result->mode=data->data[1]->to_int();
    if(result->mode<1||result->mode>4)throw RuntimeError(_T("Unknown Edit identification mode"));
    if(data->data[4]!=&true_value&&data->data[4]!=&false_value)throw RuntimeError(_T("Band ownership requirement must be Boolean"));
    result->requireBand=data->data[4]==&true_value;result->bandColors[0]=Point3(.5f,.5f,.5f);
    const auto color=[](Value* value){auto rgb=value->to_point3()/255.f;for(int i=0;i<3;++i)if(!std::isfinite(rgb[i])||rgb[i]<0||rgb[i]>1)throw RuntimeError(_T("Identification colors must be finite RGB values in 0..255"));return rgb;};
    type_check(data->data[2],Array,_T("source palette"));auto* colors=static_cast<Array*>(data->data[2]);
    if(colors->size<0||std::size_t(colors->size)>ep::maxSources||(std::size_t(colors->size)!=sources&&!(empty&&colors->size==0)))throw RuntimeError(_T("Edit palette source correspondence mismatch"));
    for(int i=0;i<colors->size;++i)result->sourceColors.push_back(color(colors->data[i]));
    type_check(data->data[3],Array,_T("Band palette"));auto* bands=static_cast<Array*>(data->data[3]);
    if(bands->size>64)throw RuntimeError(_T("Band palette exceeds 64 entries"));
    ce::Vector<std::pair<std::uint64_t,Point3>> sorted;
    for(int i=0;i<bands->size;++i){type_check(bands->data[i],Array,_T("Band palette entry"));auto* row=static_cast<Array*>(bands->data[i]);
        if(row->size!=2||row->data[0]->to_int64()<=0)throw RuntimeError(_T("Invalid Band palette identity"));sorted.emplace_back(std::uint64_t(row->data[0]->to_int64()),color(row->data[1]));}
    std::sort(sorted.begin(),sorted.end(),[](const auto& a,const auto& b){return a.first<b.first;});
    for(const auto& row:sorted){if(!result->bandIDs.empty()&&result->bandIDs.back()==row.first)throw RuntimeError(_T("Duplicate Band palette identity"));result->bandIDs.push_back(row.first);result->bandColors[result->bandIDs.size()]=row.second;}
    return result;
}
static bool sameEditPalette(const std::shared_ptr<const EditPalette>& a,const std::shared_ptr<const EditPalette>& b){
    return a==b||(a&&b&&a->mode==b->mode&&a->requireBand==b->requireBand&&a->sourceColors==b->sourceColors&&a->bandIDs==b->bandIDs&&a->bandColors==b->bandColors);
}
static void installEditPresentation(Array* mods,int key,std::shared_ptr<const EditPresentation> next,bool captureLocal=true){
    ce::Vector<std::pair<EditLayer*,std::shared_ptr<const EditPublishedLocal>>> targets;
    for(int i=0;i<mods->size;++i){auto* m=edit(mods->data[i]);const auto found=m->layers.find(key);if(found==m->layers.end())continue;
        auto local=found->second.publishedLocal;if(captureLocal){auto prepared=ce::make<EditPublishedLocal>();prepared->input=found->second.input;prepared->rows=found->second.rows;local=std::move(prepared);}
        targets.emplace_back(&found->second,std::move(local));}
    // All local snapshots allocate before any modifier is changed.
    for(auto& target:targets){target.first->presentation=next;target.first->publishedLocal=std::move(target.second);target.first->published=true;}
    for(int i=0;i<mods->size;++i)edit(mods->data[i])->status();
}
def_visible_primitive(cyrusEditVersion,"cyrusEditVersion");
Value* cyrusEditVersion_cf(Value**,int count){check_arg_count(cyrusEditVersion,0,count);return Integer::intern(2);}
def_visible_primitive(cyrusEditPublishPresentation,"cyrusEditPublishPresentation");
Value* cyrusEditPublishPresentation_cf(Value** a,int count){
    check_arg_count(cyrusEditPublishPresentation,4,count);type_check(a[0],Array,_T("Edit modifiers"));auto* mods=static_cast<Array*>(a[0]);
    if(!mods->size)return &ok;
    try{
        const auto& view=cyrusPlacementView(a[2]);if(view.stage()!=ep::Stage::Edited)throw std::invalid_argument("Edit presentation requires final edited placements");
        auto next=ce::make<EditPresentation>();next->final=nativeEditInput(view);next->palette=editPalette(a[3],view.sources(),view.size()==0);
        for(std::size_t i=0;i<view.size();++i){const auto band=view.at(i).band;
            if((!band&&next->palette->requireBand)||(band&&!std::binary_search(next->palette->bandIDs.begin(),next->palette->bandIDs.end(),band)))throw std::invalid_argument("Edit placement owner is missing from the published Band palette");}
        installEditPresentation(mods,a[1]->to_int(),std::move(next));return &ok;
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
def_visible_primitive(cyrusEditRecolor,"cyrusEditRecolor");
Value* cyrusEditRecolor_cf(Value** a,int count){
    check_arg_count(cyrusEditRecolor,3,count);type_check(a[0],Array,_T("Edit modifiers"));auto* mods=static_cast<Array*>(a[0]);const auto key=a[1]->to_int();
    try{
        std::shared_ptr<const EditPresentation> previous;for(int i=0;i<mods->size&&!previous;++i){const auto found=edit(mods->data[i])->layers.find(key);if(found!=edit(mods->data[i])->layers.end())previous=found->second.presentation;}
        if(!previous||!previous->final||!previous->final->native)return &ok;
        const auto& view=*previous->final->native;const auto palette=editPalette(a[2],view.sources(),view.size()==0);
        if(previous->palette&&(palette->bandIDs!=previous->palette->bandIDs||palette->requireBand!=previous->palette->requireBand))throw std::invalid_argument("Edit recolour cannot replace published Band correspondence");
        if(sameEditPalette(previous->palette,palette))return &ok;
        auto next=ce::make<EditPresentation>(*previous);next->palette=palette;installEditPresentation(mods,key,std::move(next),false);return &ok;
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
def_visible_primitive(cyrusEditInspect,"cyrusEditInspect");
Value* cyrusEditInspect_cf(Value** a,int count){
    check_arg_count(cyrusEditInspect,3,count);auto* m=edit(a[0]);const auto offset=a[1]->to_int64();const auto requested=a[2]->to_int();
    if(offset<0||requested<1||requested>500)throw RuntimeError(_T("Edit inspection requires a nonnegative offset and 1..500 rows"));
    std::uint64_t total=0;for(const auto& [key,l]:m->layers){(void)key;total+=l.rows.size();}
    three_typed_value_locals(Array* result,Array* rows,Array* row);vl.result=new Array(4);vl.rows=new Array(0);
    vl.result->append(Integer::intern(2));vl.result->append(Integer64::intern(INT64(total)));vl.result->append(Integer64::intern(offset));vl.result->append(vl.rows);
    std::uint64_t skipped=0;
    for(const auto& [key,l]:m->layers){
        if(skipped+l.rows.size()<=std::uint64_t(offset)){skipped+=l.rows.size();continue;}
        const auto begin=std::uint64_t(offset)>skipped?std::size_t(std::uint64_t(offset)-skipped):0;
        for(std::size_t i=begin;i<l.rows.size()&&vl.rows->size<requested;++i){const auto& row=l.rows.get(i);const auto source=l.source(row),at=l.presented(row);
            vl.row=new Array(15);vl.rows->append(vl.row);vl.row->append(Integer::intern(key));vl.row->append(Integer64::intern(INT64(i+1)));
            vl.row->append(new String(row.lineage&&l.lineages?l.lineages->ids.at(row.lineage-1).c_str():_T("")));
            vl.row->append(new String(row.inputId.text().c_str()));vl.row->append(new String(row.outputId.text().c_str()));
            vl.row->append(l.active&&!l.invalid&&l.input&&source<l.input->size()?&true_value:&false_value);
            vl.row->append(l.active&&!l.invalid&&l.shown(row)?&true_value:&false_value);vl.row->append(l.selection.get(i)?&true_value:&false_value);vl.row->append(row.deleted?&true_value:&false_value);
            vl.row->append(Integer64::intern(INT64(row.order)));vl.row->append(new Matrix3Value(row.delta));
            vl.row->append(l.input&&source<l.input->size()?static_cast<Value*>(new Matrix3Value(l.input->matrix(source))):&undefined);
            vl.row->append(at!=UINT_MAX?static_cast<Value*>(new Matrix3Value(l.feedback()->final->matrix(at))):&undefined);
            vl.row->append(new Point3Value(l.color(row)*255.f));vl.row->append(Integer64::intern(l.input&&l.input->native?INT64(l.input->native->token().owner):0));
        }
        skipped+=l.rows.size();if(vl.rows->size>=requested)break;
    }
    return_value(vl.result);
}
