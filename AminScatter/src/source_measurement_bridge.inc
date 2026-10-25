// Main-thread borrowed baked mesh. No mesh copy, triangle vector, or vertex/face
// MAXScript/Python arrays. Fixed buffers feed two streaming fingerprints.
namespace {
class SourceMeasurementHash {
    BCRYPT_ALG_HANDLE algorithm_=nullptr;BCRYPT_HASH_HANDLE hash_=nullptr;
    std::array<unsigned char,8192> buffer_{};std::size_t used_=0;
public:
    SourceMeasurementHash(){
        if(BCryptOpenAlgorithmProvider(&algorithm_,BCRYPT_SHA256_ALGORITHM,nullptr,0)<0)throw std::runtime_error("Source SHA-256 provider unavailable.");
        if(BCryptCreateHash(algorithm_,&hash_,nullptr,0,nullptr,0,0)<0){BCryptCloseAlgorithmProvider(algorithm_,0);algorithm_=nullptr;throw std::runtime_error("Source SHA-256 unavailable.");}
    }
    ~SourceMeasurementHash(){if(hash_)BCryptDestroyHash(hash_);if(algorithm_)BCryptCloseAlgorithmProvider(algorithm_,0);}
    void flush(){if(used_&&BCryptHashData(hash_,buffer_.data(),static_cast<ULONG>(used_),0)<0)throw std::runtime_error("Source fingerprint failed.");used_=0;}
    template<class T>void add(T value){
        static_assert(std::is_trivially_copyable_v<T>);
        if(used_+sizeof(T)>buffer_.size())flush();std::memcpy(buffer_.data()+used_,&value,sizeof(T));used_+=sizeof(T);
    }
    void point(cyrus::source_measurement::Point p){for(double value:p)add(value==0?0.:value);}
    std::string finish(){
        flush();std::array<unsigned char,32> bytes{};if(BCryptFinishHash(hash_,bytes.data(),32,0)<0)throw std::runtime_error("Source fingerprint could not finish.");
        constexpr char hex[]="0123456789abcdef";std::string result;result.reserve(64);for(auto b:bytes){result+=hex[b>>4];result+=hex[b&15];}return result;
    }
};
Array* sourceMeasurementPoint(const cyrus::source_measurement::Point& p){
    one_typed_value_local(Array* row);vl.row=new Array(3);for(auto value:p)vl.row->append(Double::intern(value));return_value(vl.row);
}
}
def_visible_primitive(cyrusSourceMeasurementVersion,"cyrusSourceMeasurementVersion");
Value* cyrusSourceMeasurementVersion_cf(Value**,int count){check_arg_count(cyrusSourceMeasurementVersion,0,count);return Integer::intern(1);}
def_visible_primitive(cyrusSourceMeasurement,"cyrusSourceMeasurement");
Value* cyrusSourceMeasurement_cf(Value** args,int count){check_arg_count(cyrusSourceMeasurement,4,count);
    try{
        auto* node=args[0]->to_node();if(!node)throw std::invalid_argument("Select a baked source mesh.");
        const auto metre=args[1]->to_double();const int facesLimit=args[2]->to_int(),verticesLimit=args[3]->to_int();
        if(!std::isfinite(metre)||metre<=0||facesLimit<1||verticesLimit<1)throw std::invalid_argument("Invalid source measurement admission or units.");
        const auto time=GetCOREInterface()->GetTime();auto* object=node->EvalWorldState(time).obj;
        if(!object||(object->ClassID()!=Class_ID(TRIOBJ_CLASS_ID,0)&&object->ClassID()!=Class_ID(EDITTRIOBJ_CLASS_ID,0)))
            throw std::invalid_argument("Native source measurement requires a baked Editable Mesh; no conversion or proxy evaluation is performed.");
        const Mesh& mesh=static_cast<TriObject*>(object)->GetMesh();const auto vertices=mesh.getNumVerts(),faces=mesh.getNumFaces();
        if(vertices<0||faces<0||!mesh.verts||!mesh.faces)throw std::invalid_argument("Source mesh storage is unavailable.");
        cyrus::source_measurement::storage(vertices,faces,verticesLimit,facesLimit);
        const auto nodeTM=node->GetNodeTM(time),worldTM=node->GetObjectTM(time);
        for(const auto* tm:{&nodeTM,&worldTM})for(int i=0;i<4;++i)for(int j=0;j<3;++j)
            if(!std::isfinite(tm->GetRow(i)[j]))throw std::invalid_argument("Source transform is nonfinite.");
        const auto determinant=DotProd(nodeTM.GetRow(0),CrossProd(nodeTM.GetRow(1),nodeTM.GetRow(2)));
        if(!std::isfinite(determinant)||std::abs(determinant)<1e-12)throw std::invalid_argument("Source node transform cannot be inverted.");
        // Same exact cancellation policy as the existing native asset capture:
        // a float matrix multiplied by its computed inverse can invent offsets.
        bool sameTransform=true;
        for(int i=0;i<4;++i)for(int j=0;j<3;++j)if(worldTM.GetRow(i)[j]!=nodeTM.GetRow(i)[j])sameTransform=false;
        const auto localTM=sameTransform?Matrix3(1):worldTM*Inverse(nodeTM);
        cyrus::source_measurement::Bounds local,world;SourceMeasurementHash localHash,worldHash;
        for(auto* hash:{&localHash,&worldHash}){hash->add(std::uint32_t(1));hash->add(std::uint64_t(vertices));hash->add(std::uint64_t(faces));}
        localHash.add(std::uint32_t(0));worldHash.add(std::uint32_t(1));
        for(int i=0;i<vertices;++i){
            const auto p=mesh.verts[i]*localTM,q=mesh.verts[i]*worldTM;
            cyrus::source_measurement::Point a{double(p.x)*metre,double(p.y)*metre,double(p.z)*metre},b{double(q.x)*metre,double(q.y)*metre,double(q.z)*metre};
            local.add(a);world.add(b);localHash.point(a);worldHash.point(b);
        }
        for(int i=0;i<faces;++i)for(int corner=0;corner<3;++corner){
            const auto index=mesh.faces[i].v[corner];cyrus::source_measurement::index(index,vertices);
            localHash.add(std::uint32_t(index));worldHash.add(std::uint32_t(index));
        }
        const auto localSHA=localHash.finish(),worldSHA=worldHash.finish();
        one_typed_value_local(Array* result);vl.result=new Array(11);
        vl.result->append(Integer::intern(faces));vl.result->append(Integer::intern(vertices));
        for(const auto* bounds:{&local,&world}){vl.result->append(sourceMeasurementPoint(bounds->minimum));vl.result->append(sourceMeasurementPoint(bounds->maximum));}
        vl.result->append(Double::intern(local.radiusXY));vl.result->append(Double::intern(local.radiusXYZ));
        vl.result->append(new String(MSTR::FromACP(localSHA.c_str())));vl.result->append(new String(MSTR::FromACP(worldSHA.c_str())));
        vl.result->append(new String(_T("cyrus.source-measurement/1.0")));return_value(vl.result);
    }catch(const std::exception& error){throw RuntimeError(MSTR::FromACP(error.what()));}
}
