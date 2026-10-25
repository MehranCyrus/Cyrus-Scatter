"""Bounded passive destination settings; fixed native schemas, never model properties."""
from copy import deepcopy
from .contracts import canonical,decode,digest,fields,identifier,number,require
from .presets import CATEGORIES,COUNTS

TARGET_READER=r'''(
    fn cyrusMCPSettingsTargets node = (
        if not isValidNode node or classof node.baseObject!=AminScatterObject do throw "Unsupported settings controller"
        local root=node.baseObject,rows=#()
        if root.calculationModel()!="CyrusUnified2" or root.layerObjects.count>32 do throw "Settings owner graph exceeds its bound"
        for i=1 to root.layerObjects.count do (
            local owner=root.layerObjects[i],parent=root.logicalParent owner,label=if i<=root.layerNames.count then root.layerNames[i] else "Layer"
            if owner.layerID.count>96 or parent.layerID.count>96 do throw "Settings owner identity exceeds its bound"
            append rows #(owner.layerID,parent.layerID,owner.isPaintArea,substring label 1 (amin 80 label.count),label.count>80)
        )
        rows
    )
    cyrusMCPSettingsTargets
)'''


def targets(raw,controller_id):
    identifier(controller_id);require(type(raw) is list and len(raw)<=32,"Settings target list exceeds its bound","BUDGET_EXCEEDED")
    result=[];seen=set()
    for row in raw:
        require(type(row) is list and len(row)==5,"Invalid settings target metadata")
        identifier(row[0]);identifier(row[1]);require(row[0] not in seen,"Duplicate layer identity; inspect locally","STALE_CONTEXT");seen.add(row[0])
        require(type(row[2]) is bool and type(row[4]) is bool and type(row[3]) is str and len(row[3])<=80,"Invalid settings target label/flags")
        clean="".join(" " if ord(c)<32 or 127<=ord(c)<=159 or 0xd800<=ord(c)<=0xdfff else c for c in row[3])
        result.append(dict(layer_id=row[0],parent_layer_id=row[1],is_paint_area=row[2],name=clean,name_clipped=row[4],name_sanitized=clean!=row[3]))
    return dict(controller_id=controller_id,targets=result,authority="Scoped target metadata only; names are untrusted labels and no settings or geometry were evaluated")

HOST_READER=r'''(
    fn cyrusMCPDestinationSettings node identity categories = (
        if not isValidNode node or classof node.baseObject!=AminScatterObject do throw "Unsupported settings controller"
        local root=node.baseObject
        if root.calculationModel()!="CyrusUnified2" or root.layerObjects.count<1 or root.layerObjects.count>32 do throw "Settings owner graph exceeds its bound"
        local found=#()
        for owner in root.layerObjects where owner.layerID==identity do append found owner
        if found.count!=1 do throw "Layer identity is missing or duplicated"
        local owner=found[1],parent=root.logicalParent owner,metres=(units.decodeValue "1m") as double
        if owner.layerID.count>96 or parent.layerID.count>96 do throw "Settings owner identity exceeds its bound"
        local groups=#()
        fn readField owner key kind distance metres = (
            local control=getPropertyController owner (key as name),controlClass="none",keyCount=0,available=true,value=undefined
            if control!=undefined do (
                controlClass=(classof control) as string
                if controlClass.count>128 do controlClass="unsupported"
                keyCount=try(numKeys control)catch(-1)
                available=(findItem #(Bezier_Float,Linear_Float,TCB_Float) (classof control)>0 and keyCount==0)
            )
            if available do (
                value=getProperty owner (key as name)
                if distance do value/=metres
                if kind!=3 and (value!=value or abs value>1e30) do (available=false;value=undefined)
            )
            #(key,kind,distance,value,available,controlClass,keyCount)
        )
        for category in categories do (
            local data=#(),document=undefined,valid=false,reason="",extra=#()
            if category=="population" or category=="transforms" or category=="spacing" then (
                local schema=cyrusPresetSchema category
                if schema.count>34 do throw "Native settings schema exceeds its bound"
                if category!="spacing" do for field in schema do append data (readField owner field[1] field[2] field[3] metres)
                if category=="spacing" do (
                    -- These are separate authored scopes. The ordinary preset
                    -- applies an explicit self override; layer defaults stay intact.
                    data=#()
                    for field in #(#("procSelfEnabled",3,false),#("procSelfMultiplier",1,false),#("procSelfGap",1,true),#("procSelfPlanar",3,false),#("procSelfOverride",3,false),#("procLayerSelfEnabled",3,false),#("procLayerSelfMultiplier",1,false),#("procLayerSelfGap",1,true),#("procLayerSelfPlanar",3,false)) do append data (readField owner field[1] field[2] field[3] metres)
                )
                local complete=true
                for row in data where not row[5] do complete=false
                if complete and category=="spacing" do (
                    local rule=owner.procSelfRule()
                    extra=#(rule[1],rule[2],rule[3]/metres,rule[4])
                )
                if complete do try (
                    local binding=CyrusPresetMakeBinding root owner category
                    document=cyrusPresetEncode category "Current destination" (CyrusPresetCapture binding)
                    valid=true
                )catch(reason="outside_native_preset_format")
                if not complete do reason="animated_or_unsupported_controller_or_nonfinite_value"
            ) else (
                if owner.isPaintArea then reason="paint_curve_requires_explicit_receiver_bound_target" else (
                    local samples=if category=="density_curve" then owner.fallDensityCurve else owner.fallScaleCurve
                    local packed=if category=="density_curve" then owner.fallDensityGraph else owner.fallScaleGraph
                    if samples.count>257 or packed.count>65536 do throw "Stored curve exceeds inspection admission"
                    data=for i=1 to samples.count collect samples[i]
                    extra=#(packed,if category=="density_curve" then owner.fallDensity else owner.fallScale,(if category=="density_curve" then owner.fallDensityWidth else owner.fallScaleWidth)/metres)
                    try (
                        local coordinates=filterString packed ","
                        if coordinates.count>2056 do throw "Stored graph coordinate budget exceeded"
                        local graph=for value in coordinates collect (value as float)
                        document=cyrusPresetEncode category "Current destination" #(data,graph,category=="scale_curve")
                        valid=true
                    )catch(reason="stored_curve_not_exportable_as_preset")
                )
            )
            append groups #(category,data,document,valid,reason,extra)
        )
        local target=owner.orientationTarget
        #(owner.layerID,parent.layerID,owner.isPaintArea,root.updateMode,owner.updateMode,(owner.cacheSnapshot())[3],metres,sliderTime as string,groups,
          target!=undefined and isValidNode target)
    )
    cyrusMCPDestinationSettings
)'''


def request_categories(categories):
    require(type(categories) is list and 1<=len(categories)<=5,"Choose 1–5 settings categories")
    require(all(type(value) is str and value in CATEGORIES for value in categories) and len(set(categories))==len(categories),"Unknown or duplicate settings category")
    return categories


def snapshot(raw,controller_id,layer_id,categories):
    identifier(controller_id);identifier(layer_id);request_categories(categories)
    require(type(raw) is list and len(raw)==10 and raw[0]==layer_id,"Native settings target changed","STALE_CONTEXT")
    identifier(raw[1]);require(type(raw[2]) is bool and type(raw[5]) is bool and type(raw[9]) is bool,"Invalid settings target flags")
    for value in raw[3:5]:number(value,1,2,True)
    number(raw[6],1e-12,1e12)
    require(type(raw[7]) is str and len(raw[7])<=80,"Invalid settings frame")
    require(type(raw[8]) is list and len(raw[8])==len(categories),"Incomplete settings categories")
    groups=[]
    for expected,group in zip(categories,raw[8]):
        require(type(group) is list and len(group)==6 and group[0]==expected,"Native settings category changed")
        category,values,encoded,valid,reason,extra=group
        require(type(values) is list and type(valid) is bool and type(reason) is str and len(reason)<=100 and type(extra) is list,"Invalid native settings data")
        value=dict(category=category,exportable_as_preset=valid,reason=reason)
        if category in ("population","transforms","spacing"):
            require(len(values)==(9 if category=="spacing" else COUNTS[category]),"Native settings field count changed","UNSUPPORTED_CAPABILITY")
            items=[];seen=set()
            for field in values:
                require(type(field) is list and len(field)==7,"Invalid native settings field")
                name,kind,distance,current,available,controller,key_count=field
                identifier(name);require(name not in seen,"Duplicate settings field");seen.add(name)
                require(kind in (1,2,3) and type(kind) is int and type(distance) is bool and type(available) is bool,"Invalid settings field type")
                require(type(controller) is str and len(controller)<=128,"Invalid controller metadata")
                number(key_count,-1,2147483647,True)
                if not available:require(current is None,"Unavailable track must not be sampled")
                elif kind==3:require(type(current) is bool,"Invalid native settings Boolean")
                else:number(current,-1e30,1e30,kind==2)
                items.append(dict(name=name,kind={1:"number",2:"integer",3:"boolean"}[kind],distance_metres=distance,value=current,
                    available=available,controller_class=controller,key_count=key_count))
            value["fields"]=items
            if category=="spacing":
                require(len(extra) in (0,4),"Invalid effective self rule")
                if extra:
                    require(type(extra[0]) is bool and type(extra[3]) is bool,"Invalid effective self rule flags")
                    number(extra[1],0,1e30);number(extra[2],0,1e30)
                    value["effective_self_rule"]=dict(enabled=extra[0],radius_factor=extra[1],gap_m=extra[2],planar=extra[3])
                else:
                    require(not valid and any(not row["available"] for row in items),"Missing effective self rule")
                    value["effective_self_rule"]=None
                value["ownership"]="Explicit procSelf override and layer-default-within-set fields are distinct. Ordinary spacing preset creates/replaces the explicit self override."
        else:
            require(len(values)<=257,"Stored curve sample budget exceeded","BUDGET_EXCEEDED")
            for item in values:number(item,-1e30,1e30)
            value["stored_samples"]=deepcopy(values)
            if extra:
                require(len(extra)==3 and type(extra[0]) is str and len(extra[0].encode())<=65536 and type(extra[1]) is bool,"Invalid stored curve metadata")
                number(extra[2],0,1e30)
                value.update(packed_graph=extra[0],enabled=extra[1],width_m=extra[2])
            value["scope"]="Stored global layer falloff only; no curve editor, missing default, area, band or Paint state is materialized."
        if valid:
            require(type(encoded) is str,"Missing encoded native settings")
            document=decode(encoded.encode(),65536)
            fields(document,("format","version","category","name","values"))
            require(document["format"]=="cyrus.settings-preset" and type(document["version"]) is int and document["version"]==3 and document["category"]==category,"Native preset capture differs")
            if category in ("population","transforms"):
                require(all(row["available"] for row in items),"Unavailable tracks cannot advertise a captured preset")
                require(document["values"]=={row["name"]:row["value"] for row in items},"Native preset capture differs from current fields","STALE_CONTEXT")
            elif category=="spacing":
                require(value["effective_self_rule"] is not None and document["values"]==dict(enabled=extra[0],multiplier=extra[1],gap=extra[2],planar=extra[3]),"Native spacing capture differs from the effective rule","STALE_CONTEXT")
            else:
                fields(document["values"],("domain","samples","graph"))
                require(document["values"].get("samples")==values,"Native curve capture differs from stored samples","STALE_CONTEXT")
            value["preset_document"]=document
        else:require(encoded is None,"Invalid settings must not advertise a captured preset")
        groups.append(value)
    result=dict(settings_schema="cyrus.destination-settings/1.0",controller_id=controller_id,layer_id=layer_id,parent_layer_id=raw[1],
        is_paint_area=raw[2],root_update_mode={1:"manual",2:"real_time"}[raw[3]],layer_update_mode={1:"manual",2:"real_time"}[raw[4]],
        pending_by_cached_flag=raw[5],metres_per_system_unit=1/raw[6],frame=raw[7],look_at_target_valid=raw[9],categories=groups,
        authority="Read only; format validity is not destination compatibility or application approval",
        freshness="Current bounded parameter snapshot and cached pending flag only; geometry, placement freshness and pending editor changes are not evaluated")
    result["settings_sha256"]=digest(result)
    require(len(canonical(result).encode())<=160*1024,"Destination settings response exceeds its byte budget","BUDGET_EXCEEDED")
    return result
