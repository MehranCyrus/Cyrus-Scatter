namespace {
constexpr unsigned editLegacyChunk=0x7301,editSourceChunk=0x7302,editStorageVersion=4;
constexpr unsigned editStorageGuard=0xffffffffu,editLayerLimit=1000,editSavedRowLimit=10000000;
constexpr std::size_t editLegacyKeyBytes=400000; // preserves bounded old UTF-16 keys
static void validateStoredEditLayer(const EditLayer& l){
    if(l.rows.size()>editSavedRowLimit||l.nextOrder>std::uint64_t(INT64_MAX))throw std::invalid_argument("Invalid saved Edit extent");
    std::optional<cyrus::editbinding::Descriptor> descriptor;
    if(l.sourceAware)descriptor=cyrus::editbinding::parse(receiverUTF8(l.signature));
    else if(cyrus::editbinding::isSourceAware(receiverUTF8(l.signature)))throw std::invalid_argument("Saved Edit source feature mismatch");
    const auto lineages=l.lineages?l.lineages->ids.size():0;
    if(lineages>cyrus::editbinding::maxSources||(!l.sourceAware&&lineages))throw std::invalid_argument("Invalid saved Edit source inventory");
    std::unordered_set<std::wstring> sourceIDs;
    if(l.lineages)for(const auto& id:l.lineages->ids){const std::wstring text(id.begin(),id.end());const auto utf8=receiverUTF8(text);
        if(utf8.empty()||utf8.size()>cyrus::editbinding::maxIdentityBytes||!sourceIDs.insert(text).second)throw std::invalid_argument("Invalid saved Edit source identity");}
    EditKeySet clones;
    std::unordered_set<EditVariant,EditVariantHash,std::equal_to<EditVariant>,ce::Allocator<EditVariant>> variants;
    std::unordered_map<std::uint64_t,EditKey,std::hash<std::uint64_t>,std::equal_to<std::uint64_t>,ce::Allocator<std::pair<const std::uint64_t,EditKey>>> orders;
    std::unordered_map<EditKey,std::uint64_t,EditKeyHash,std::equal_to<EditKey>,ce::Allocator<std::pair<const EditKey,std::uint64_t>>> outputOrders;
    for(std::size_t i=0;i<l.rows.size();++i){const auto& row=l.rows.get(i);
        if(!finiteEditMatrix(row.delta)||row.lineage>lineages||row.order>=l.nextOrder)throw std::invalid_argument("Invalid saved Edit row");
        if(row.pin){const auto& p=row.pin->base;
            if(!l.sourceAware||!row.lineage||row.recipeLocal||row.recipePinned||!p.face||p.face>INT_MAX||p.receiver>=128||p.band>std::uint64_t(INT64_MAX))throw std::invalid_argument("Invalid saved Edit pin");
            for(auto v:p.transform)if(!std::isfinite(v))throw std::invalid_argument("Nonfinite saved pin transform");
            for(auto v:p.bary)if(!std::isfinite(v))throw std::invalid_argument("Nonfinite saved pin anchor");
        }
        if(!variants.insert({row.outputId,row.lineage}).second)throw std::invalid_argument("Duplicate saved Edit identity and source");
        if(row.inputId!=row.outputId&&!clones.insert(row.outputId).second)throw std::invalid_argument("Duplicate saved Edit clone");
        const auto order=orders.emplace(row.order,row.outputId);if(!order.second&&order.first->second!=row.outputId)throw std::invalid_argument("Ambiguous saved Edit order");
        const auto outputOrder=outputOrders.emplace(row.outputId,row.order);if(!outputOrder.second&&outputOrder.first->second!=row.order)throw std::invalid_argument("Inconsistent saved Edit identity order");
        if(l.sourceAware&&authoredEdit(row)){
            if(!row.lineage&&l.legacyProof.empty())throw std::invalid_argument("Legacy Edit lineage lacks recovery evidence");
            if(row.lineage){const auto& id=l.lineages->ids[row.lineage-1];if(!cyrus::editbinding::sourceRevision(*descriptor,receiverUTF8(std::wstring(id.begin(),id.end()))))throw std::invalid_argument("Saved Edit source lacks its generation settings");}
        }
    }
}
}

IOResult CSEdit::Save(ISave* s){
    try{
        if(layers.size()>editLayerLimit)return IO_ERROR;
        std::size_t total=0;for(const auto& [key,l]:layers){(void)key;total+=l.rows.size();if(total>editSavedRowLimit)return IO_ERROR;validateStoredEditLayer(l);}
        const auto write=[&](const void* p,ULONG n){ULONG done=0;return s->Write(static_cast<const char*>(p),n,&done)==IO_OK&&done==n;};
        const auto str=[&](const std::wstring& v,std::size_t maximum){const auto utf8=receiverUTF8(v);if(utf8.size()>maximum||utf8.find('\0')!=std::string::npos)return false;const auto n=unsigned(utf8.size());return write(&n,sizeof(n))&&(!n||write(utf8.data(),n));};
        const auto boolean=[&](bool value){const std::uint8_t byte=value?1:0;return write(&byte,sizeof(byte));};
        const auto matrix=[&](const Matrix3& value){std::array<float,12> numbers{};for(int r=0;r<4;++r)for(int c=0;c<3;++c)numbers[r*3+c]=value.GetRow(r)[c];return write(numbers.data(),ULONG(sizeof(numbers)));};
        // Old readers encounter their recognized chunk and explicitly reject
        // the impossible count. They cannot ignore our source-aware extension.
        s->BeginChunk(editLegacyChunk);if(!write(&editStorageGuard,sizeof(editStorageGuard))||!write(&editStorageVersion,sizeof(editStorageVersion)))return IO_ERROR;s->EndChunk();
        s->BeginChunk(editSourceChunk);const auto count=unsigned(layers.size());if(!write(&editStorageVersion,sizeof(editStorageVersion))||!write(&count,sizeof(count)))return IO_ERROR;
        for(const auto& [key,l]:layers){const auto size=unsigned(l.rows.size()),sources=unsigned(l.lineages?l.lineages->ids.size():0);
            if(!write(&key,sizeof(key))||!str(l.signature,cyrus::editbinding::maxDescriptorBytes)||!str(l.legacyProof,cyrus::editbinding::maxSignatureBytes)||!boolean(l.invalid)||!boolean(l.sourceAware)||!boolean(l.recipeUnbound)||!write(&l.nextOrder,sizeof(l.nextOrder))||!write(&sources,sizeof(sources)))return IO_ERROR;
            if(l.lineages)for(const auto& id:l.lineages->ids)if(!str(std::wstring(id.begin(),id.end()),cyrus::editbinding::maxIdentityBytes))return IO_ERROR;
            if(!write(&size,sizeof(size)))return IO_ERROR;
            for(std::size_t i=0;i<l.rows.size();++i){const auto& row=l.rows.get(i);if(!write(&row.savedSource,sizeof(row.savedSource))||!write(&row.lineage,sizeof(row.lineage))||!write(&row.order,sizeof(row.order))||!matrix(row.delta)||!boolean(row.deleted)||!boolean(row.recipeLocal)||!boolean(l.selection.get(i))||!str(row.inputId.text(),editLegacyKeyBytes)||!str(row.outputId.text(),editLegacyKeyBytes)||!boolean(row.recipePinned)||!boolean(bool(row.pin)))return IO_ERROR;if(row.pin){const auto& p=*row.pin;if(!write(p.base.transform.data(),48)||!write(p.base.bary.data(),12)||!write(&p.base.face,4)||!write(&p.base.receiver,4)||!write(&p.base.band,8)||!boolean(p.receiverBound))return IO_ERROR;}}
        }
        s->EndChunk();return IO_OK;
    }catch(...){return IO_ERROR;}
}

IOResult CSEdit::Load(ILoad* s){
    try{
        std::map<int,EditLayer> next;bool guard=false,payload=false,legacy=false;unsigned guardVersion=0;std::size_t total=0,consumed=0;
        const auto read=[&](void* p,ULONG n){ULONG done=0;if(s->Read(static_cast<char*>(p),n,&done)!=IO_OK||done!=n)return false;consumed+=n;return true;};
        const auto str=[&](std::wstring& value,std::size_t maximum){unsigned n=0;if(!read(&n,sizeof(n))||n>maximum)return false;std::string text(n,'\0');if(n&&!read(text.data(),n))return false;if(text.find('\0')!=std::string::npos)return false;value=receiverWide(text);return true;};
        const auto oldstr=[&](std::wstring& value){unsigned n=0;if(!read(&n,sizeof(n))||n>100000)return false;value.resize(n);return (!n||read(value.data(),ULONG(n*sizeof(wchar_t))))&&value.find(L'\0')==std::wstring::npos;};
        const auto boolean=[&](bool& value){static_assert(sizeof(bool)==1);std::uint8_t byte=0;if(!read(&byte,sizeof(byte))||byte>1)return false;value=byte!=0;return true;};
        const auto matrix=[&](Matrix3& value){std::array<float,12> numbers{};if(!read(numbers.data(),ULONG(sizeof(numbers))))return false;for(int r=0;r<4;++r)value.SetRow(r,Point3(numbers[r*3],numbers[r*3+1],numbers[r*3+2]));return finiteEditMatrix(value);};
        IOResult result;
        while((result=s->OpenChunk())==IO_OK){const auto chunk=s->CurChunkID();consumed=0;
            if(chunk==0x3901||chunk==0x4001)return IO_ERROR; // retired development records
            if(chunk==editLegacyChunk){
                if(guard||legacy||payload)return IO_ERROR;unsigned count=0;if(!read(&count,sizeof(count)))return IO_ERROR;
                if(count==editStorageGuard){unsigned version=0;if(!read(&version,sizeof(version))||(version<2||version>editStorageVersion))return IO_ERROR;guard=true;guardVersion=version;}
                else{
                    if(count>editLayerLimit)return IO_ERROR;legacy=true;
                    for(unsigned i=0;i<count;++i){int key=0;unsigned size=0;EditLayer layer;
                        if(!read(&key,sizeof(key))||!oldstr(layer.signature)||!boolean(layer.invalid)||!read(&size,sizeof(size))||size>editSavedRowLimit-total)return IO_ERROR;total+=size;
                        for(unsigned j=0;j<size;++j){EditRow row;bool selected=false;std::wstring input,output;
                            if(!read(&row.savedSource,sizeof(row.savedSource))||!read(&row.delta,sizeof(row.delta))||!finiteEditMatrix(row.delta)||!boolean(row.deleted)||!boolean(selected)||!oldstr(input)||!oldstr(output)||input.empty()||output.empty())return IO_ERROR;
                            row.inputId=EditKey(input);row.outputId=EditKey(output);row.order=j;layer.append(row);layer.selection.set(j,selected);
                        }
                        layer.nextOrder=size;validateStoredEditLayer(layer);if(!next.emplace(key,std::move(layer)).second)return IO_ERROR;
                    }
                }
                if(consumed!=s->CurChunkLength())return IO_ERROR;
            }else if(chunk==editSourceChunk){
                if(!guard||legacy||payload)return IO_ERROR;unsigned version=0,count=0;if(!read(&version,sizeof(version))||version!=guardVersion||!read(&count,sizeof(count))||count>editLayerLimit)return IO_ERROR;payload=true;
                for(unsigned i=0;i<count;++i){int key=0;unsigned sources=0,size=0;EditLayer layer;
                    if(!read(&key,sizeof(key))||!str(layer.signature,cyrus::editbinding::maxDescriptorBytes)||!str(layer.legacyProof,cyrus::editbinding::maxSignatureBytes)||!boolean(layer.invalid)||!boolean(layer.sourceAware)||(version>=3&&!boolean(layer.recipeUnbound))||!read(&layer.nextOrder,sizeof(layer.nextOrder))||!read(&sources,sizeof(sources))||sources>cyrus::editbinding::maxSources)return IO_ERROR;
                    auto ids=ce::make<EditLineages>();for(unsigned j=0;j<sources;++j){std::wstring id;if(!str(id,cyrus::editbinding::maxIdentityBytes))return IO_ERROR;ids->ids.emplace_back(id.begin(),id.end());}if(sources)layer.lineages=std::move(ids);
                    if(!read(&size,sizeof(size))||size>editSavedRowLimit-total)return IO_ERROR;total+=size;
                    for(unsigned j=0;j<size;++j){EditRow row;bool selected=false;std::wstring input,output;
                        if(!read(&row.savedSource,sizeof(row.savedSource))||!read(&row.lineage,sizeof(row.lineage))||!read(&row.order,sizeof(row.order))||!matrix(row.delta)||!boolean(row.deleted)||(version>=3&&!boolean(row.recipeLocal))||!boolean(selected)||!str(input,editLegacyKeyBytes)||!str(output,editLegacyKeyBytes)||input.empty()||output.empty())return IO_ERROR;
                        row.inputId=EditKey(input);row.outputId=EditKey(output);
                        if(version>=4){bool pinned=false;if(!boolean(row.recipePinned)||!boolean(pinned))return IO_ERROR;if(pinned){auto pin=ce::make<EditPin>();if(!read(pin->base.transform.data(),48)||!read(pin->base.bary.data(),12)||!read(&pin->base.face,4)||!read(&pin->base.receiver,4)||!read(&pin->base.band,8)||!boolean(pin->receiverBound))return IO_ERROR;row.pin=std::move(pin);}}
                        layer.append(row);layer.selection.set(j,selected);
                    }
                    validateStoredEditLayer(layer);if(!next.emplace(key,std::move(layer)).second)return IO_ERROR;
                }
                if(consumed!=s->CurChunkLength())return IO_ERROR;
            }else if(chunk>=0x7300&&chunk<=0x73ff)return IO_ERROR; // unknown future Edit feature
            s->CloseChunk();
        }
        if(result!=IO_END||guard!=payload)return IO_ERROR;layers.swap(next);return IO_OK;
    }catch(...){return IO_ERROR;}
}
