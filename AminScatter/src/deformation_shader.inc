// Public Nitrous typed buffers. This only draws an already accepted CPU pose;
// it never evaluates the scene or solves contacts on the graphics thread.
const char* deformationFunctions=R"fx(
Buffer<float4> CyrusBindings;
Buffer<float4> CyrusNodes;
Buffer<float4> CyrusChanges;
float CyrusChangeCapacity;
float CyrusChangeProbes;
float CyrusMetresPerUnit;
bool CyrusDeformFull;
float4 cyrusSlerp(float4 a,float4 b,float u){
    a=normalize(a);b=normalize(b);float d=dot(a,b);if(d<0){b=-b;d=-d;}d=clamp(d,0,1);
    if(d>=1)return normalize(lerp(a,b,u));
    float angle=acos(d);return normalize((sin((1-u)*angle)*a+sin(u*angle)*b)/sin(angle));
}
float3 cyrusRotate(float4 q,float3 v){return v+2*cross(q.xyz,cross(q.xyz,v)+q.w*v);}
float3 cyrusPoint(uint binding,uint pose){
    float4 rest=CyrusBindings[binding],m=CyrusBindings[binding+1];
    if(rest.w==0||CyrusNodes[pose+(uint)m.w].w<=0)return rest.xyz;
    uint a=pose+(uint)m.x,b=pose+(uint)m.y;
    float4 q=cyrusSlerp(CyrusNodes[a+1],CyrusNodes[b+1],m.z);
    return lerp(CyrusNodes[a].xyz,CyrusNodes[b].xyz,m.z)+cyrusRotate(q,CyrusBindings[binding+2].xyz);
}
float3 cyrusHost(float3 p){return float3(p.x,-p.z,p.y)/CyrusMetresPerUnit;}
bool cyrusDeform(inout Input i){
    uint key=(uint)i.sourceSlot,capacity=(uint)CyrusChangeCapacity;
    uint bucket=(key*2654435761u)&(capacity-1),pose=0;bool enabled=true;
    [loop] for(uint n=0;n<(uint)CyrusChangeProbes;++n){uint offset=bucket*5;float4 change=CyrusChanges[offset];
        if(change.x==0)break;
        if((uint)change.x==key+1){pose=(uint)change.y;enabled=change.z>0;
            i.r0=CyrusChanges[offset+1].xyz;i.r1=CyrusChanges[offset+2].xyz;i.r2=CyrusChanges[offset+3].xyz;i.r3=CyrusChanges[offset+4].xyz;break;}
        bucket=(bucket+1)&(capacity-1);
    }
    if(!enabled)return false;
    if(!CyrusDeformFull)return true;
    uint face=(i.vertex/3)*10,corner=i.vertex%3;float4 roots=CyrusBindings[face+9];
    bool visible=enabled&&CyrusNodes[pose+(uint)roots.x].w>=0&&CyrusNodes[pose+(uint)roots.y].w>=0&&CyrusNodes[pose+(uint)roots.z].w>=0;
    float3 a=cyrusHost(cyrusPoint(face,pose)),b=cyrusHost(cyrusPoint(face+3,pose)),c=cyrusHost(cyrusPoint(face+6,pose));
    i.p=corner==0?a:corner==1?b:c;i.a=b-a;i.b=c-a;return visible;
}
)fx";
std::string deformationShader(const char* source){
    std::string text(source);auto input=text.find("struct Input {");auto end=text.find("};",input);
    if(input==std::string::npos||end==std::string::npos)throw std::runtime_error("Missing deformation shader input");
    text.insert(end,"float sourceSlot:TEXCOORD9;uint vertex:SV_VertexID;\n");
    auto output=text.find("struct Output");text.insert(output,deformationFunctions);
    auto body=text.find("Output o;",output);text.insert(body+9,"bool visible=cyrusDeform(i);");
    auto finish=text.find("return o;",body);text.insert(finish,"if(!visible)o.p=float4(0,0,-1,1);");return text;
}
