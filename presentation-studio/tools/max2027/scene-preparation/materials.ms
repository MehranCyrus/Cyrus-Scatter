global CyrusPrepareMaterialCache,CyrusPrepareMaterialLog,CyrusPrepareMaterialRules,CyrusPreparePBR,CyrusPrepareRuleValue,CyrusPrepareRuleMatch
fn CyrusPrepareRuleValue rule key fallback = (
    for pair in rule where pair[1]==key do return pair[2]
    fallback
)
fn CyrusPrepareRuleMatch rule label = (
    local exact=CyrusPrepareRuleValue rule "sourceName" undefined
    if exact!=undefined then exact==label else matchPattern label pattern:(CyrusPrepareRuleValue rule "pattern" "") ignoreCase:true
)
fn CyrusPrepareScalar source key fallback = (
    if source!=undefined and isProperty source key then getProperty source key else fallback
)
fn CyrusPrepareLinearColour value = (
    local result=#(value.r,value.g,value.b)
    for i=1 to 3 do (
        local v=result[i]/255.0
        result[i]=255.0*(if v<=0.04045 then v/12.92 else ((v+0.055)/1.055)^2.4)
    )
    color result[1] result[2] result[3]
)
fn CyrusPreparePBR source depth:0 = (
    if depth>8 do throw "Material graph exceeds preparation depth."
    for item in CyrusPrepareMaterialCache where item[1]==source do return item[2]
    local label=if source==undefined then "Unassigned" else source.name
    local kind=if source==undefined then "Undefined" else (classOf source) as string
    local rule=undefined,result=undefined,decision="Scalar PBR approximation; unsupported maps omitted"
    for item in CyrusPrepareMaterialRules where rule==undefined and CyrusPrepareRuleMatch item label do rule=item
    if kind=="Multimaterial" then (
        -- numsubs is the highest subAnim/ID, not the number of material slots.
        local count=source.materialList.count
        result=MultiMaterial numsubs:count name:("CPMulti"+(CyrusPrepareMaterialCache.count as string))
        for i=1 to count do result.materialList[i]=CyrusPreparePBR source.materialList[i] depth:(depth+1)
        result.materialIDList=source.materialIDList;result.names=source.names;result.mapEnabled=source.mapEnabled
        if result.materialList.count!=count do throw "MultiMaterial slot count changed."
        for i=1 to count where result.materialIDList[i]!=source.materialIDList[i] do throw "MultiMaterial ID changed."
        decision="Material IDs retained; empty slots filled explicitly"
    ) else if kind=="CoronaLayeredMtl" then (
        result=CyrusPreparePBR (getSubMtl source 1) depth:(depth+1)
        decision="Layered base approximation; unsupported masks omitted"
    ) else if kind=="glTFMaterial" and rule==undefined then (
        result=source;decision="Existing glTF material retained"
    ) else (
        local base=CyrusPrepareScalar source #colorDiffuse (CyrusPrepareScalar source #baseColor (CyrusPrepareScalar source #Generic_Color (color 155 151 140)))
        local rough=if kind=="_CoronaPhysicalMtl" then CyrusPrepareScalar source #baseRoughness 0.7 else sqrt (amax 0.03 (1.0-(CyrusPrepareScalar source #reflectGlossiness 0.5)))
        local metal=if kind=="_CoronaPhysicalMtl" then CyrusPrepareScalar source #metalnessMode 0 else 0
        local baseMap=undefined,opacityMap=undefined,doubleSided=false
        if rule!=undefined do (
            local rgb=CyrusPrepareRuleValue rule "baseColor" undefined
            if rgb!=undefined do (
                base=color (rgb[1]*255) (rgb[2]*255) (rgb[3]*255)
                if (CyrusPrepareRuleValue rule "colorSpace" "linear")=="srgb" do base=CyrusPrepareLinearColour base
            )
            rough=CyrusPrepareRuleValue rule "roughness" rough;metal=CyrusPrepareRuleValue rule "metalness" metal
            baseMap=CyrusPrepareRuleValue rule "baseColorTexture" undefined
            opacityMap=CyrusPrepareRuleValue rule "opacityTexture" undefined
            doubleSided=CyrusPrepareRuleValue rule "doubleSided" false
            decision=CyrusPrepareRuleValue rule "label" "Explicit material replacement"
        )
        result=glTFMaterial name:("CPPBR"+(CyrusPrepareMaterialCache.count as string)) baseColor:base roughness:(amax 0 (amin 1 rough)) metalness:(amax 0 (amin 1 metal))
        result.DoubleSided=doubleSided
        if baseMap!=undefined do result.baseColorMap=BitmapTexture filename:baseMap
        if opacityMap!=undefined do (result.alphaMode=3;result.AlphaMap=BitmapTexture filename:opacityMap)
    )
    append CyrusPrepareMaterialCache #(source,result)
    format "{\"sourceName\":%,\"sourceClass\":%,\"destinationName\":%,\"decision\":%}\n" (CyrusPrepareJsonString label) (CyrusPrepareJsonString kind) (CyrusPrepareJsonString result.name) (CyrusPrepareJsonString decision) to:CyrusPrepareMaterialLog
    flush CyrusPrepareMaterialLog
    result
)

fn CyrusPrepareMaterials directory mode rules = (
    if mode=="retain" do return false
    CyrusPrepareMaterialCache=#();CyrusPrepareMaterialRules=rules
    CyrusPrepareMaterialLog=createFile (directory+"material-audit.jsonl") encoding:#utf8 writeBOM:false
    local propagation=InstanceMgr.autoMtlPropagation
    InstanceMgr.autoMtlPropagation=false
    try (
        local assignments=(for n in geometry collect #(n,n.material))
        for item in assignments do item[1].material=CyrusPreparePBR item[2]
        close CyrusPrepareMaterialLog;InstanceMgr.autoMtlPropagation=propagation;true
    ) catch (try(close CyrusPrepareMaterialLog)catch();InstanceMgr.autoMtlPropagation=propagation;throw())
)
