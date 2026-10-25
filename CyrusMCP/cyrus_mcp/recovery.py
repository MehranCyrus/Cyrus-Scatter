"""Fixed host-side metadata admission, never a model-supplied script.

The native publication reader already bounds its temporary manifest (including
its input signature). This reader additionally bounds values before pymxs
marshals strings/arrays into Python. It never visits geometry or placements.
"""

HOST_READER = r'''(
    fn cyrusMCPRecoveryRead owner key budget mode = (
        local initial=case mode of (
            1: getProperty owner key
            2: getUserProp owner (key as string)
            3: owner.procPublicationInfo()
            default: throw "Unsupported recovery read"
        )
        local root=#(undefined),pending=#(#(initial,root,1,0))
        while pending.count>0 do (
            local task=pending[pending.count]
            deleteItem pending pending.count
            local value=task[1],parent=task[2],slot=task[3],depth=task[4],result=undefined
            if depth>8 or budget[1]<1 do throw "Cyrus recovery budget exceeded"
            budget[1]-=1
            local kind=classof value
            if value==undefined then result=undefined
            else if kind==String or kind==Name then (
                local text=value as string
                if text.count>262144 or text.count>budget[2] do throw "Cyrus recovery budget exceeded"
                budget[2]-=text.count
                result=text
            )
            else if kind==Array or kind==ArrayParameter or kind==MAXModifierArray then (
                if value.count>4096 or value.count>(budget[1]-pending.count) do throw "Cyrus recovery budget exceeded"
                result=for i=1 to value.count collect undefined
                for i=value.count to 1 by -1 do append pending #(value[i],result,i,depth+1)
            )
            else if kind==Integer or kind==Integer64 or kind==IntegerPtr or kind==Float or kind==Double or kind==BooleanClass then result=value
            else if kind==Point3 then result=#("point3",value.x,value.y,value.z)
            else if kind==Color then result=#("color",value.r,value.g,value.b)
            else if kind==Matrix3 then result=(for row=1 to 4 collect #("point3",value[row].x,value[row].y,value[row].z))
            else (
                local handle=try(getHandleByAnim value)catch(undefined)
                if handle==undefined do throw "Unsupported recovery reference"
                result=#("anim_reference",handle)
            )
            parent[slot]=result
        )
        root[1]
    )
)'''

MAX_CELLS = 16_384
MAX_TEXT_UNITS = 262_144
