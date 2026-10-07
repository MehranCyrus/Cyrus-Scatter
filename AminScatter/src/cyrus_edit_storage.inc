// Unpublished 0.73 scene schema: stable identities only, no index migration.
IOResult CSEdit::Save(ISave* s) {
    auto write=[&](const void* p,ULONG n){ULONG done=0;return s->Write(static_cast<const char*>(p),n,&done)==IO_OK&&done==n;};
    auto str=[&](const std::wstring& v){unsigned n=unsigned(v.size());return write(&n,sizeof(n))&&write(v.data(),n*sizeof(wchar_t));};
    s->BeginChunk(0x7301);
    unsigned count=unsigned(layers.size());
    if(!write(&count,sizeof(count)))return IO_ERROR;
    for(auto& [key,l]:layers) {
        count=unsigned(l.rows.size());
        if(!write(&key,sizeof(key))||!str(l.signature)||!write(&l.invalid,sizeof(bool))||!write(&count,sizeof(count)))return IO_ERROR;
        for(auto& r:l.rows) if(!write(&r.source,sizeof(r.source))||!write(&r.delta,sizeof(r.delta))||!write(&r.deleted,sizeof(bool))||!write(&r.selected,sizeof(bool))||!str(r.inputId)||!str(r.outputId))return IO_ERROR;
    }
    s->EndChunk();return IO_OK;
}
IOResult CSEdit::Load(ILoad* s) {
    auto read=[&](void* p,ULONG n){ULONG done=0;return s->Read(static_cast<char*>(p),n,&done)==IO_OK&&done==n;};
    auto str=[&](std::wstring& v){unsigned n=0;if(!read(&n,sizeof(n))||n>100000)return false;v.resize(n);return read(v.data(),n*sizeof(wchar_t));};
    IOResult result;
    while((result=s->OpenChunk())==IO_OK) {
        const auto id=s->CurChunkID();
        if(id==0x3901||id==0x4001)return IO_ERROR; // Explicitly retired development data.
        if(id==0x7301) {
            unsigned count=0;
            if(!read(&count,sizeof(count))||count>1000)return IO_ERROR;
            for(unsigned i=0;i<count;++i) {
                int key=0;unsigned size=0;EditLayer l;
                if(!read(&key,sizeof(key))||!str(l.signature)||!read(&l.invalid,sizeof(bool)))return IO_ERROR;
                if(!read(&size,sizeof(size))||size>10000000)return IO_ERROR;
                l.rows.resize(size);
                for(auto& r:l.rows) {
                    if(!read(&r.source,sizeof(r.source))||!read(&r.delta,sizeof(r.delta))||!read(&r.deleted,sizeof(bool))||!read(&r.selected,sizeof(bool)))return IO_ERROR;
                    if(!str(r.inputId)||!str(r.outputId))return IO_ERROR;
                }
                layers[key]=std::move(l);
            }
        }
        s->CloseChunk();
    }
    return result==IO_END?IO_OK:result;
}
