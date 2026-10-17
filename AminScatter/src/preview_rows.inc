// Host-call-only reader. The arguments root the immutable input during parsing;
// no MAXScript Value, scene pointer or borrowed record reaches draw workers.
class PreviewRows {
    Array* rows_=nullptr;
    const cyrus::placements::View* native_=nullptr;
    Array* row(std::size_t i) const {
        type_check(rows_->data[i],Array,_T("preview placement"));
        auto* value=static_cast<Array*>(rows_->data[i]);cyrus::rows::current(value);return value;
    }
public:
    explicit PreviewRows(Value* value){
        if(cyrusIsPlacementValue(value))native_=&cyrusPlacementView(value);
        else{type_check(value,Array,_T("preview placements"));rows_=static_cast<Array*>(value);}
        if(size()>1000000)throw RuntimeError(_T("Preview input exceeds 1,000,000 placements"));
    }
    std::size_t size() const{return native_?native_->size():std::size_t(rows_->size);}
    unsigned source(std::size_t i) const{return native_?native_->at(i).source:unsigned(row(i)->data[1]->to_int());}
    std::uint64_t owner(std::size_t i) const{return native_?native_->at(i).band:std::uint64_t(row(i)->data[5]->to_int64());}
    Matrix3 matrix(std::size_t i) const{
        if(!native_)return row(i)->data[0]->to_matrix3();
        const auto& m=native_->at(i).transform;Matrix3 result(1);
        for(int j=0;j<4;++j)result.SetRow(j,Point3(m[std::size_t(j*3)],m[std::size_t(j*3+1)],m[std::size_t(j*3+2)]));
        return result;
    }
    std::uint8_t band(std::size_t i,const cyrus::PreviewPalette& palette) const{return previewBandSlot(owner(i),palette);}
    void validate(std::size_t sources,const cyrus::PreviewPalette& palette) const{
        for(std::size_t i=0;i<size();++i){const auto s=source(i);if(s<1||s>sources)throw RuntimeError(_T("Invalid preview source index"));band(i,palette);}
    }
};
