(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-grid0850-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"integration-"+(timeStamp() as string)+".txt")
 fn check value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do for j=1 to 8 where a[i][j]!=b[i][j] do return false;true)
 fn apply root = (root.refreshAll();for leaf in root.layerObjects where leaf.previewError!="" do throw leaf.previewError)
 try (
  if theHold.Holding() do theHold.Cancel()
  CyrusPerfHeadless=true;resetMaxFile #noPrompt
  local root,leaf,terrain,node
  undo off (
   units.SystemType=#meters;units.SystemScale=1
   terrain=plane name:"Grid integration terrain" width:20 length:20 widthsegs:4 lengthsegs:4
   node=AminScatterObject name:"Grid integration";root=node.baseObject;root.updateMode=1;root.autoRender=false
   root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces leaf #(terrain);leaf.addPointSource()
   leaf.placementMode=2;leaf.gridColumnWU=5;leaf.gridRowWU=5;leaf.scaleMinimum=1;leaf.scaleMaximum=1;leaf.yawMinimum=0;leaf.yawMaximum=0;leaf.tiltDegrees=0
   leaf.sourceRadiiWU=#(0.0);leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
   apply root
  )
  check (root.groupSnapshotRows[1].count==25) "Point sources use the complete regular lattice" log
  local base=deepCopy root.groupSnapshotRows[1],projection=(cyrusGridStats())[1]
  local includedArea=rectangle name:"Grid include" width:11 length:11,excludedArea=rectangle name:"Grid exclude" width:1 length:1
  leaf.areaNodes=#(includedArea,excludedArea);leaf.areaModes=#(1,2);apply root
  check (root.groupSnapshotRows[1].count==8) "Independent Include/exclude oracle keeps nine inner cells minus the center" log
  for row in root.groupSnapshotRows[1] do (
   local found=false
   for old in base where old[3]==row[3] do (check (equalRows #(old) #(row)) "Area masks preserve all fields of surviving unrelaxed cells" log;found=true)
   check found "Area masks retain injective original cell identities" log
  )
  check ((cyrusGridStats())[1]==projection) "Area masks reuse the same projected grid" log
  leaf.areaNodes=#();leaf.areaModes=#();leaf.distributionMode=3;leaf.densityMap=checker color1:white color2:white;apply root
  check (equalRows base root.groupSnapshotRows[1]) "White UV density map preserves complete grid rows" log
  leaf.densityMap.color1=black;leaf.densityMap.color2=black;apply root
  check (root.groupSnapshotRows[1].count==0) "Black UV density mask excludes every grid cell without refill" log
  leaf.densityMap.color1=white;leaf.densityMap.color2=white;apply root
  check (equalRows base root.groupSnapshotRows[1]) "Restored UV density restores exact stable cell rows" log
  local edit=CyrusScatterEdit();addModifier node edit;apply root
  cyrusEditSelect edit #(1,2);cyrusEditCommand edit 4 (transMatrix [0,0,10]);apply root
  local edited=deepCopy root.groupSnapshotRows[1],binding=leaf.procBindingKey
  check ((for row in edited where row[7] collect row).count==2) "Authored Edit protects two grid cell transforms using complete 64-bit IDs" log
  leaf.densityMap.color1=black;leaf.densityMap.color2=black;apply root
  check (root.groupSnapshotRows[1].count==0 and leaf.procBindingKey==binding) "Ineligible authored grid cells remain dormant with unchanged binding" log
  leaf.densityMap.color1=white;leaf.densityMap.color2=white;apply root
  check (equalRows edited root.groupSnapshotRows[1]) "Returning eligibility restores authored grid Edit transforms" log
  local epoch=root.procEpoch
  leaf.gridHeading=15;root.refreshAll()
  check (leaf.previewError!="" and root.procEpoch==epoch and equalRows edited root.groupSnapshotRows[1]) "Changing bound grid frame fails atomically without discarding Edit data" log
  leaf.gridHeading=0;apply root;check (equalRows edited root.groupSnapshotRows[1]) "Restored grid frame recovers Edit binding" log
  deleteModifier node edit;leaf.distributionMode=1;apply root
  leaf.addEmptySource();leaf.sourceWeights=#(0.0,1.0);apply root
  check (root.groupSnapshotRows[1].count==0) "All-Empty source selection leaves explicit grid gaps" log
  leaf.sourceWeights=#(1.0,0.0);apply root;check (equalRows base root.groupSnapshotRows[1]) "Restoring Point choice restores full grid without identity loss" log
  rotate terrain (eulerAngles 30 0 0);leaf.alignNormal=true;leaf.orientationBlend=100;apply root
  check (root.groupSnapshotRows[1].count==15) "Tilted plane uses world-XY lattice coverage" log
  for row in root.groupSnapshotRows[1] do (
   local p=row[1].row4,z=normalize row[1].row3
   check (abs(p.z-p.y*(tan 30))<0.001 and distance z [0,-0.5,0.8660254]<0.001) "Projected height and full surface normal match the analytic tilted plane" log
  )
  leaf.alignNormal=false;apply root
  for row in root.groupSnapshotRows[1] do check (distance (normalize row[1].row3) [0,0,1]<0.001) "Normal-disabled grid objects stay upright" log
  leaf.advancedAxes=true;leaf.movXMinWU=1;leaf.movXMaxWU=1;leaf.projectMove=true;apply root
  for row in root.groupSnapshotRows[1] do check (abs(row[1].row4.z-row[1].row4.y*(tan 30))<0.001) "Final projected movement remains on the receiving plane" log
  leaf.movXMinWU=0;leaf.movXMaxWU=0;leaf.sourceRadiiWU=#(4.0,0.0);leaf.procSelfEnabled=true;apply root
  local spaced=root.groupSnapshotRows[1]
  check (spaced.count>0 and spaced.count<15) "Final radius spacing thins the lattice" log
  for i=1 to spaced.count do for j=i+1 to spaced.count do check (distance spaced[i][1].row4 spaced[j][1].row4>=7.999) "Independent final-radius distance oracle" log
  check (not theHold.Holding()) "No stranded integration transaction" log
  format "PASS: complete\n" to:log;close log;CyrusPerfHeadless=false
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log;flush log;close log;throw())
)
