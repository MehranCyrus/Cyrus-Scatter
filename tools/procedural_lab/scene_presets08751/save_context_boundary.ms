global SPContext="before="+((theHold.Holding()) as string)
for i=1 to 64 while theHold.Holding() do theHold.Accept "Owned fixture command"
SPContext+=" after="+((theHold.Holding()) as string)
CyrusRequireAuthor()
SPContext+=" require="+((theHold.Holding()) as string)
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"save-context-boundary.txt") SPContext
SPJob=CyrusScenePresetSave SPRoot "Owned native preset" (CyrusRecipeObject #(#("category","Scene preset qualification"),#("tags",#("native","test")),#("description","Complete saved setup"))) ""
