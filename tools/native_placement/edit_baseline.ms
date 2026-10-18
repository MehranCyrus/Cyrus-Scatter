-- Persist the old Edit implementation's complete authored state and result.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeaccept-controller-*/" do throw "Owned Edit baseline required"
 NCRoot.updateMode=1;NCRoot.procNativeRoute=false
 with undo off (
  NCLeaf.amount=5000;NCRoot.refreshAll()
  local edit=CyrusScatterEdit();addModifier NCNode edit;NCRoot.refreshAll()
  cyrusEditSelect edit #(1,3,7,100,3000)
  cyrusEditTransform edit 0 [3,4,5] (matrix3 1) false;NCRoot.refreshAll()
  cyrusEditTransform edit 1 (quat 27 [0,0,1]) (matrix3 1) true;NCRoot.refreshAll()
  cyrusEditTransform edit 2 [0.7,1.2,1.8] (matrix3 1) true;NCRoot.refreshAll()
  cyrusEditSelect edit #(1,3,100);cyrusEditCommand edit 3 (matrix3 1);NCRoot.refreshAll()
  cyrusEditCommand edit 4 (transMatrix [9,2,0]);NCRoot.refreshAll()
  cyrusEditSelect edit #(5,8);cyrusEditCommand edit 2 (matrix3 1);NCRoot.refreshAll()
  local second=CyrusScatterEdit();addModifier NCNode second;NCRoot.refreshAll()
  cyrusEditSelect second #(2,10,22);cyrusEditCommand second 4 (transMatrix [-1,0,4]);NCRoot.refreshAll()
 )
 if NCLeaf.previewError!="" do throw NCLeaf.previewError
 local f=createFile(MCPFixtureDir+"edit-baseline-"+NCKind+".txt")
 format "%\n" (cyrusRecipePublicationFingerprint NCRoot.groupSnapshotRows) to:f;close f
 saveMaxFile (MCPFixtureDir+"edit-baseline-"+NCKind+".max") quiet:true
)
