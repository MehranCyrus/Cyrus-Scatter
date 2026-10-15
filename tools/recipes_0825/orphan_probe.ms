(
 local s=stringStream ""
 format "arraysEqual=%\n" (#(1,2)==#(1,2)) to:s
 local root=(getNodeByName "Orphan recipe").baseObject,a=root.layerObjects[1].paintAreas[1]
 local data=cyrusBrushRecipeExport a.paintDocument,d=CyrusRecipeCapture root #(root.layerObjects[1]) "probe"
 with printAllElements on (format "export=%\nareaTarget=% target=%\n" data a.areaTarget (cyrusBrushTarget a.paintDocument) to:s)
 local p=CyrusRecipeGet (CyrusRecipeGet (CyrusRecipeGet (CyrusRecipeGet d "layers")[1] "areas")[1] "paint") "receiverRole"
 format "role=%\n" p to:s
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"recipe-orphan-probe.txt") (s as string)
)
