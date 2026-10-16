(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
 local root=GalleryTestRoot,log=createFile (MCPFixtureDir+"heavy-publish-"+(timeStamp() as string)+".txt"),start=timeStamp()
 local count=((dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"heavy-count.txt")) as integer
 undo off root.refreshAll()
 format "Initial Update % ms; heap=% free=%; rows=%\n" (timeStamp()-start) heapSize heapFree (for rows in root.groupSnapshotRows collect rows.count) to:log
 if not CyrusPresetSameValues (for rows in root.groupSnapshotRows collect rows.count) #(count,count) do (close log;throw "Heavy publication count")
 for leaf in root.layerObjects do if leaf.previewError!="" do (format "FAIL %\n" leaf.previewError to:log;close log;throw "Heavy initial publication error")
 root.mainUI.updateRadio.changed 2
 saveMaxFile (MCPFixtureDir+"variation-heavy.max") quiet:true
 format "PASS prepared; later request must check settled errors and keys\n" to:log;close log
)
