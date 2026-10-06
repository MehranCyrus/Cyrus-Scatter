global RSAssert,RSRows,RSEqual,RSBind,RSReload
fn RSBind = (
 RSNode=getNodeByName "CYRUS 0.7.1 | Courtyard - Edit layer";RSRoot=RSNode.baseObject
 -- Preserve fixture indices while the artist-facing procedural order can change.
 RSOwners=for leaf in RSRoot.layerObjects where leaf.logicalParentID=="" collect leaf
 RSFlowers=RSOwners[4]
 local sets=RSRoot.layerSets RSFlowers;RSClover=sets[2];RSGrass=sets[3]
 RSSurface=RSRoot.surfaceNodes[1]
)
fn RSReload = (
 loadMaxFile (RSOut+"Cyrus_071_Garden_Pavilion.max") quiet:true useFileUnits:true
 RSBind();RSRoot.refreshAll();RSRoot.evaluateGroups()
)
fn RSAssert condition description = (if not condition do throw description;true)
fn RSRows = (for leaf in RSRoot.layerObjects collect (leaf.placements (leaf.outputSources())))
fn RSEqual aa bb tolerance:0.0001 = (
 if aa.count!=bb.count do return false
 for i=1 to aa.count do (
  if aa[i].count!=bb[i].count do return false
  for j=1 to aa[i].count do (
   if aa[i][j][2]!=bb[i][j][2] or aa[i][j][3]!=bb[i][j][3] do return false
   for k=1 to 4 where distance aa[i][j][1][k] bb[i][j][1][k]>tolerance do return false
  )
 );true
)
