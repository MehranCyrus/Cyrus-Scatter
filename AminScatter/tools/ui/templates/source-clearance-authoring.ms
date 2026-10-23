    fn setSourceClearance rows field value = (
        if findItem #(#clearanceCopies,#clearanceOthers,#clearanceExternal,#clearanceTargets,#clearancePreferred,#clearanceFactors,#clearanceGapsWU,#clearancePlanar) field==0 do throw "Unknown model clearance field."
        local selectedIDs=for row in rows where row>0 and row<=sourceRowIDs.count collect sourceRowIDs[row]
        this.validateClearance()
        undo "Cyrus model clearance" on (
            for id in selectedIDs do (
                local index=findItem clearanceSourceIDs id
                if index==0 do (
                    append clearanceSourceIDs id;append clearanceCopies 0;append clearanceOthers 0;append clearanceExternal 0
                    append clearanceTargets "";append clearancePreferred false;append clearanceFactors 1.0;append clearanceGapsWU 0.0;append clearancePlanar false
                    index=clearanceSourceIDs.count
                )
                (getProperty this field)[index]=value
            )
        )
        this.markInputDirty();true
    )
    fn removeSourceClearance id = (
        local index=findItem clearanceSourceIDs id
        if index>0 do for key in #(#clearanceSourceIDs,#clearanceCopies,#clearanceOthers,#clearanceExternal,#clearanceTargets,#clearancePreferred,#clearanceFactors,#clearanceGapsWU,#clearancePlanar) do deleteItem (getProperty this key) index
    )
    fn procClearanceSpecs plants = (
        this.validateClearance()
        if plants.count==0 do return #(#("unassigned:1","unassigned:1",0,0,0,#(),false,#(true,1.0,0.0,false)))
        for plant in plants collect (
            local row=this.sourceRow plant,policy=this.clearanceRow row
            if row<1 or row>sourceRowIDs.count or row>procSourceSlots.count do throw "Clearance source correspondence is incomplete."
            #(sourceRowIDs[row],procSourceSlots[row],policy[1],policy[2],policy[3],filterString policy[4] "|",policy[5],#(true,policy[6],policy[7],policy[8]))
        )
    )
