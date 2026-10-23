fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
global QSchemaFixture
(
 resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1
 local legacy=if QSchemaFixture!=undefined then QSchemaFixture else @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/update08671-test-clearance-baseline-2027/schema58.max"
 QRequire (loadMaxFile legacy quiet:true) "Owned schema 58 fixture failed to load"
 local owners=for node in objects where classof node==AminScatterObject collect node
 QRequire (owners.count==1) "Owned schema 58 fixture did not retain one controller"
 QNode=owners[1];QRoot=QNode.baseObject;QLayer=QRoot.selectedLayer();QRoot.updateMode=1
 local identities=for leaf in QRoot.layerObjects collect #(leaf.layerID,leaf.sourceRowIDs as array)
 QRequire (QRoot.needsClearanceUpgrade()) "Legacy scene silently upgraded"
 local rejected=false;try(QRoot.procAssertSchema())catch(rejected=true)
 QRequire rejected "Legacy calculation was allowed before the explicit upgrade"
 QMount();QClick QRoot.mainUI.upgradeButton
 QRequire (not QRoot.needsClearanceUpgrade()) "Actual Upgrade control failed"
 max undo;QRequire (QRoot.needsClearanceUpgrade()) "Upgrade Undo failed"
 max redo;QRequire (not QRoot.needsClearanceUpgrade()) "Upgrade Redo failed"
 QRequire ((for leaf in QRoot.layerObjects collect #(leaf.layerID,leaf.sourceRowIDs as array)) as string==identities as string) "Upgrade changed logical identities"
 QCalculate()
 local scene=MCPFixtureDir+"upgraded-schema59.max",original=QFingerprint(),originalOwner=QRoot
 saveMaxFile scene quiet:true
 QRequire (mergeMaxFile scene #autoRenameDups #renameMtlDups quiet:true) "Owned schema 59 merge failed"
 owners=for node in objects where classof node==AminScatterObject collect node
 QRequire (owners.count==2) "Merge did not create a separate controller"
 for node in owners do (
     local root=node.baseObject;QRequire (not root.needsClearanceUpgrade()) "Merged schema 59 became legacy"
     root.evaluateProcedural();for leaf in root.layerObjects do QRequire (leaf.previewError=="") leaf.previewError
 )
 QRequire (QFingerprint()==original and QRoot==originalOwner) "Merge changed the original controller's complete result"
 saveMaxFile (MCPFixtureDir+"merged-schema59.max") quiet:true
 QAssert true (QScenarioID+"-01") "Actual schema58 upgrade/Undo/Redo preserves identities; schema59 save and same-name merge preserve independent owners"
)
