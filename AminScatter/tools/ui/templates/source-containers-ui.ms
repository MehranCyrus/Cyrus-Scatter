    rollout sourceContainersUI "Source containers" width:146 (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,binding=false,setSpecific=true,modes=#()
        dropdownlist modeList "Source pool" items:#() pos:[4,8] width:132
        listbox containersList "Rectangles" items:#() pos:[4,60] width:132 height:4
        button createContainer "Create rectangle" pos:[4,154] width:132
        pickbutton pickContainer "Pick rectangle" filter:CyrusSourceContainerFilter pos:[4,184] width:132
        button removeContainer "Unlink selected rectangle" pos:[4,214] width:132
        label membershipInfo "Manual source list." pos:[4,248] width:132 height:48
        label helpInfo "Pivot inside = active. Height is ignored. Moving out keeps source settings. Manual needs Update." pos:[4,302] width:132 height:78
        fn currentSet = root.selectedPaintSet owner
        fn bind layer = (
            binding=true
            local leaf=currentSet(),active=root.groupPolicy==3,own=leaf.logicalParentID==""
            modes=if own then #(1,3,4) else #(1,2,3,4)
            modeList.items=if own then #("Manual sources","Global containers","Layer containers") else #("Manual sources","Layer default","Global containers","This set's containers")
            modeList.selection=amax 1 (findItem modes leaf.containerMode)
            local nodes=leaf.effectiveContainers()
            containersList.items=for node in nodes collect (if isValidNode node then node.name else "<deleted rectangle>")
            modeList.enabled=active;containersList.enabled=active
            for control in #(createContainer,pickContainer,removeContainer) do control.enabled=active and leaf.containerMode==4
            local registered=leaf.sources.count,count=0
            for value in leaf.containerActive where value do count+=1
            membershipInfo.text=if leaf.containerProvider()==undefined then "Manual source list." else (count as string)+" active / "+(registered as string)+" registered\nGlobal rectangles: Surface Scatter."
            controlsReady=true;binding=false
        )
        on sourceContainersUI open do bind owner
        on sourceContainersUI close do controlsReady=false
        on modeList selected index do if not binding do try((currentSet()).containerSetMode modes[index];bind owner)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on createContainer pressed do try((currentSet()).containerCreate();bind owner)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on pickContainer picked node do try((currentSet()).containerAdd node;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on removeContainer pressed do try((currentSet()).containerRemove containersList.selection;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
    )
