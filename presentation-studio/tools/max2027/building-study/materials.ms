-- Scene-specific artistic PBR adapter for the owned Big building derivative.
-- Missing Corona graphs are not claimed to be renderer-equivalent.
global CyrusBuildingMaterialCache=#(),CyrusBuildingMaterialLog
global CyrusBuildingTextureDir
fn CyrusBuildingLinearColour value = (
    local components=#(value.r,value.g,value.b)
    for i=1 to 3 do (
        local channel=components[i]/255.0
        components[i]=255.0*(if channel<=0.04045 then channel/12.92 else ((channel+0.055)/1.055)^2.4)
    )
    color components[1] components[2] components[3]
)
fn CyrusBuildingProperty source key fallback = (
    if source!=undefined and isProperty source key then getProperty source key else fallback
)
fn CyrusBuildingPBR source depth:0 = (
    if depth>8 do throw "Material graph exceeds adapter depth."
    for item in CyrusBuildingMaterialCache where item[1]==source do return item[2]
    local label=if source==undefined then "Unassigned" else source.name
    local kind=if source==undefined then "Undefined" else ((classOf source) as string)
    local result=undefined,decision="Scalar PBR approximation; unsupported maps omitted"
    if kind=="Multimaterial" then (
        result=MultiMaterial numsubs:source.numsubs name:("Cyrus PBR "+label)
        result.materialIDList=source.materialIDList
        for i=1 to source.numsubs do result.materialList[i]=CyrusBuildingPBR (getSubMtl source i) depth:(depth+1)
        decision="Material IDs retained; empty slots filled explicitly"
    ) else if kind=="CoronaLayeredMtl" then (
        result=CyrusBuildingPBR (getSubMtl source 1) depth:(depth+1)
        decision="Artistic approximation using layered material base; unavailable masks omitted"
    ) else (
        local nameLower=toLower label
        local base=CyrusBuildingProperty source #colorDiffuse (CyrusBuildingProperty source #baseColor (CyrusBuildingProperty source #Generic_Color (color 155 151 140)))
        local rough=if kind=="_CoronaPhysicalMtl" then CyrusBuildingProperty source #baseRoughness 0.7 else sqrt (amax 0.03 (1.0-(CyrusBuildingProperty source #reflectGlossiness 0.5)))
        local metal=if kind=="_CoronaPhysicalMtl" then CyrusBuildingProperty source #metalnessMode 0 else 0
        local refract=CyrusBuildingProperty source #levelRefract (CyrusBuildingProperty source #refractionAmount 0)
        local glass=(refract>0.3 or matchPattern nameLower pattern:"*glas*") and not (matchPattern nameLower pattern:"*metall*" or matchPattern nameLower pattern:"*shadowbox*")
        local texture=undefined,alpha=1.0
        if matchPattern nameLower pattern:"*baksteen*" then (
            base=color 255 255 255;rough=0.85;metal=0;texture="brick-generated.png"
            decision="Generated orange-red running-bond brick albedo; artistic replacement"
        ) else if matchPattern nameLower pattern:"*fibre cement*" then (
            base=color 232 221 200;rough=0.82;metal=0;texture="fiber-cement-generated.png"
            decision="Generated fibre-cement albedo tinted light brown; artistic replacement"
        ) else if matchPattern nameLower pattern:"*painted_wooden_facade*" then (
            base=color 255 255 255;rough=0.76;metal=0;texture="painted-timber-generated.png"
            decision="Generated greige painted-timber facade albedo; artistic replacement"
        ) else if matchPattern nameLower pattern:"*concerete*" or matchPattern nameLower pattern:"*concrete*" then (
            base=color 235 228 216;rough=0.85;metal=0;texture="fiber-cement-generated.png"
            decision="Generated neutral mineral surface grain used on concrete; artistic replacement"
        ) else if glass then (
            base=color 154 183 189;rough=0.14;metal=0.05;alpha=0.32
            decision="Tinted alpha-blended PBR glazing approximation; no Corona refraction"
        ) else if matchPattern nameLower pattern:"*asphalt*" then (
            base=color 50 52 55;rough=0.96;metal=0;decision="Artistic dark asphalt; missing source maps"
        ) else if matchPattern nameLower pattern:"*stone_pavement*" then (
            base=color 162 157 143;rough=0.92;metal=0;decision="Artistic warm stone pavement; missing source maps"
        ) else if matchPattern nameLower pattern:"*soil*" then (
            base=color 74 64 49;rough=1;metal=0;decision="Artistic garden soil; missing source maps"
        ) else if matchPattern nameLower pattern:"*hout*" then (
            base=if matchPattern nameLower pattern:"*licht*" then color 161 133 94 else color 113 79 54
            rough=0.7;metal=0;decision="Artistic timber color; missing source maps"
        ) else if matchPattern nameLower pattern:"*ral*8022*" then (base=color 47 42 38;rough=0.55;metal=0.12;decision="Approximate named RAL8022 coating")
        else if matchPattern nameLower pattern:"*ral*7021*" then (base=color 48 52 53;rough=0.55;metal=0.12;decision="Approximate named RAL7021 coating")
        else if matchPattern nameLower pattern:"*ral*7039*" then (base=color 108 105 95;rough=0.58;metal=0.1;decision="Approximate named RAL7039 coating")
        else if matchPattern nameLower pattern:"*ral*7033*" then (base=color 128 133 118;rough=0.6;metal=0.1;decision="Approximate named RAL7033 coating")
        else if matchPattern nameLower pattern:"*ral*7032*" then (base=color 184 180 163;rough=0.7;metal=0;decision="Approximate named RAL7032 coating")
        else if matchPattern nameLower pattern:"*ral*7047*" then (base=color 209 208 207;rough=0.75;metal=0;decision="Approximate named RAL7047 coating")
        else if matchPattern nameLower pattern:"*wit*" or matchPattern nameLower pattern:"*white*" then (base=color 222 218 209;rough=0.6;metal=0;decision="Artistic warm white coating")
        else if matchPattern nameLower pattern:"*steel*" or matchPattern nameLower pattern:"*metaal*" or matchPattern nameLower pattern:"*metal*" then (rough=0.45;metal=0.55;decision="Scalar metallic approximation")
        -- Explicit artistic palette inputs are sRGB; glTF factors are linear.
        -- Preserve the source renderer's already-linear scalar colours unchanged.
        if decision!="Scalar PBR approximation; unsupported maps omitted" and decision!="Scalar metallic approximation" do base=CyrusBuildingLinearColour base
        -- Long source labels reproduced a native black fallback in an owned probe.
        -- Keep short shader names; the audit retains the full original label.
        result=glTFMaterial name:("CyrusPBR_"+(CyrusBuildingMaterialCache.count as string)) baseColor:base roughness:(amax 0.08 (amin 1.0 rough)) metalness:(amin 1.0 metal)
        if texture!=undefined do result.baseColorMap=BitmapTexture filename:(CyrusBuildingTextureDir+texture)
        if alpha<1.0 do (
            result.alphaMode=3
            result.AlphaMap=BitmapTexture filename:(CyrusBuildingTextureDir+"glass-opacity-v2.png")
            result.DoubleSided=true
        )
    )
    append CyrusBuildingMaterialCache #(source,result)
    format "{\"sourceName\":%,\"sourceClass\":%,\"destinationName\":%,\"decision\":%}\n" (CyrusBuildingJsonString label) (CyrusBuildingJsonString kind) (CyrusBuildingJsonString result.name) (CyrusBuildingJsonString decision) to:CyrusBuildingMaterialLog
    result
)
(
    if MCPFixtureDir==undefined or CyrusBuildingTextureDir==undefined do throw "Owned scene and explicit texture directory required."
    for filename in #("brick-generated.png","fiber-cement-generated.png","painted-timber-generated.png","glass-opacity-v2.png") where not doesFileExist (CyrusBuildingTextureDir+filename) do throw ("Missing prepared texture: "+filename)
    CyrusBuildingMaterialLog=createFile (MCPFixtureDir+"material-conversion-v3.jsonl") encoding:#utf8 writeBOM:false
    local oldPropagation=InstanceMgr.autoMtlPropagation
    InstanceMgr.autoMtlPropagation=false
    try (
        local assignments=(for n in geometry collect #(n,n.material))
        for item in assignments do item[1].material=CyrusBuildingPBR item[2]
        close CyrusBuildingMaterialLog;InstanceMgr.autoMtlPropagation=oldPropagation
        (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"material-conversion-v3-complete.txt") "PASS"
    ) catch (try(close CyrusBuildingMaterialLog)catch();InstanceMgr.autoMtlPropagation=oldPropagation;throw())
)
