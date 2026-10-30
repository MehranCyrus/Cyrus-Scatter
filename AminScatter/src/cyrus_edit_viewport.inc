// Selecting an already displayed instance does not evaluate its pending recipe.
// Bootstrap a new, detached Edit from the retained final views. Subsequent
// authoring uses the existing stable-identity reconciliation and transform path.
def_visible_primitive(cyrusEditAttachDisplayed,"cyrusEditAttachDisplayed");
Value* cyrusEditAttachDisplayed_cf(Value** a,int count){
    check_arg_count(cyrusEditAttachDisplayed,3,count);auto* m=edit(a[0]);auto* owner=a[1]->to_node();
    type_check(a[2],Array,_T("Displayed layers"));auto* data=static_cast<Array*>(a[2]);
    if(!owner||!m->layers.empty()||m->localRevision||data->size>4096)throw RuntimeError(_T("Viewport attachment requires a new empty Edit modifier"));
    try{
        std::map<int,EditLayer> next;
        for(int i=0;i<data->size;++i){type_check(data->data[i],Array,_T("Displayed layer"));auto* row=static_cast<Array*>(data->data[i]);
            if(row->size!=5)throw std::invalid_argument("Invalid displayed layer descriptor");const auto key=row->data[0]->to_int();
            const auto& view=cyrusPlacementView(row->data[1]);if(key<=0||view.stage()!=ep::Stage::Edited||next.count(key))throw std::invalid_argument("Invalid displayed layer identity");
            auto& layer=next[key];bindStable(layer,row->data[2]->to_string(),nativeEditInput(view));
            auto shown=ce::make<EditPresentation>();shown->final=layer.input;shown->palette=editPalette(row->data[3],view.sources(),view.size()==0);
            auto local=ce::make<EditPublishedLocal>();local->input=layer.input;local->rows=layer.rows;
            layer.presentation=std::move(shown);layer.publishedLocal=std::move(local);layer.published=true;layer.viewportVisible=row->data[4]->to_bool()!=FALSE;
        }
        m->layers.swap(next);m->feedbackOwner=Animatable::GetHandleByAnim(owner);m->selectionAttached=true;return &ok;
    }catch(const std::exception& e){throw RuntimeError(MSTR::FromACP(e.what()));}
}
def_visible_primitive(cyrusEditSelectionPassive,"cyrusEditSelectionPassive");
Value* cyrusEditSelectionPassive_cf(Value** a,int count){check_arg_count(cyrusEditSelectionPassive,1,count);auto* m=edit(a[0]);return m->selectionAttached&&!m->localRevision?&true_value:&false_value;}

// Match the publication's layer owner AND output identity, never a list index.
def_visible_primitive(cyrusEditSelectViewport,"cyrusEditSelectViewport");
Value* cyrusEditSelectViewport_cf(Value** a,int count){
    check_arg_count(cyrusEditSelectViewport,4,count);auto* m=edit(a[0]);auto* owner=a[1]->to_node();
    if(!owner||m->feedbackOwner!=Animatable::GetHandleByAnim(owner))return &undefined;
    const auto layerOwner=std::uint64_t(a[2]->to_int64());const EditKey id(a[3]->to_string());
    for(const auto& [key,layer]:m->layers){const auto shown=layer.feedback();
        if(!layer.active||layer.invalid||!shown||!shown->final||!shown->final->native||shown->final->native->token().owner!=layerOwner)continue;
        for(unsigned i=0;i<layer.rows.size();++i)if(layer.rows.get(i).outputId==id&&layer.shown(layer.rows.get(i))){
            m->author([&](auto& next){for(auto& [k,l]:next){(void)k;l.selection.clear();}next.at(key).selection.set(i,true);},false);
            return Integer::intern(key);
        }
    }return &undefined;
}
